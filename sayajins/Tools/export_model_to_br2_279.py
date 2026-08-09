"""Import a generated hero model FBX in Blender 2.79 and export Civ V BR2.

The Civ V tooling is substantially more reliable when a unit mesh reaches
Nexus Buddy through BR2 instead of its direct FBX-to-GR2 path.
"""

from __future__ import print_function

import importlib.util
import os
import sys

import bpy


def main():
    marker = sys.argv.index("--")
    source = os.path.abspath(sys.argv[marker + 1])
    output = os.path.abspath(sys.argv[marker + 2])
    exporter_path = os.path.abspath(sys.argv[marker + 3])

    bpy.ops.wm.read_factory_settings(use_empty=True)
    result = bpy.ops.import_scene.fbx(filepath=source, use_anim=False)
    if "FINISHED" not in result:
        raise RuntimeError("Failed to import model FBX: " + source)

    armatures = [obj for obj in bpy.data.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    if len(armatures) != 1 or not meshes:
        raise RuntimeError("Expected one armature and at least one mesh")

    armature = armatures[0]
    for mesh in meshes:
        bpy.ops.object.select_all(action="DESELECT")
        mesh.select = True
        bpy.context.scene.objects.active = mesh
        triangulate = mesh.modifiers.new(name="Civ5 Triangulation", type="TRIANGULATE")
        bpy.ops.object.modifier_apply(modifier=triangulate.name)
        modifiers = [modifier for modifier in mesh.modifiers if modifier.type == "ARMATURE"]
        if not modifiers:
            modifier = mesh.modifiers.new(name="Armature", type="ARMATURE")
            modifier.object = armature
        else:
            modifiers[0].object = armature
            if mesh.modifiers[0] != modifiers[0]:
                bpy.context.scene.objects.active = mesh
                while mesh.modifiers[0] != modifiers[0]:
                    bpy.ops.object.modifier_move_up(modifier=modifiers[0].name)
        mesh.parent = armature
        if not mesh.data.uv_layers:
            raise RuntimeError("Mesh has no UV layer: " + mesh.name)

    spec = importlib.util.spec_from_file_location("sayajin_br2_exporter", exporter_path)
    exporter = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(exporter)
    exporter.do_export(output)

    if not os.path.isfile(output) or os.path.getsize(output) == 0:
        raise RuntimeError("BR2 export was not created: " + output)
    print("BR2_EXPORT_OK source={0} output={1} meshes={2} bones={3}".format(
        os.path.basename(source), os.path.basename(output), len(meshes), len(armature.data.bones)))


if __name__ == "__main__":
    main()
