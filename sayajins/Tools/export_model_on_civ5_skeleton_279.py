"""Retarget a generated Sayajin mesh onto a proven Civ V human skeleton.

The target skeleton is imported from a CN6 dump of a model that is already
known to render in Civ V.  Only the visible mesh is replaced; the final GR2
keeps the game's native skeleton/container and uses stock Infantry animation.
"""

from __future__ import print_function

import importlib.util
import os
import sys

import bpy
from mathutils import Matrix, Vector


BONE_MAP = {
    "Root": "CHARACTER_REORIENT",
    "Pelvis": "Base HumanPelvis",
    "Spine": "Base HumanSpine1",
    "Chest": "Base HumanRibcage",
    "Neck": "Base HumanNeck1",
    "Head": "Base HumanNeck2",
    "UpperArm_L": "Base HumanLUpperarm",
    "Forearm_L": "Base HumanLForearm",
    "Hand_L": "Base HumanLPalm",
    "UpperArm_R": "Base HumanRUpperarm",
    "Forearm_R": "Base HumanRForearm",
    "Hand_R": "Base HumanRPalm",
    "Thigh_L": "Base HumanLThigh",
    "Shin_L": "Base HumanLCalf",
    "Foot_L": "Base HumanLFoot",
    "Thigh_R": "Base HumanRThigh",
    "Shin_R": "Base HumanRCalf",
    "Foot_R": "Base HumanRFoot",
}

# The generated meshes are roughly 225 cm high, while the proven Infantry
# skeleton and mesh occupy about 130 Granny units. Hair remains deliberately
# taller than the stock helmet silhouette.
RETARGET_SCALE = 0.58


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def mesh_bounds(mesh):
    points = [mesh.matrix_world * vertex.co for vertex in mesh.data.vertices]
    return tuple(
        (min(point[axis] for point in points), max(point[axis] for point in points))
        for axis in range(3)
    )


def point_camera(camera, target):
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_preview(mesh, output_path):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_RENDER"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    if scene.world is None:
        scene.world = bpy.data.worlds.new("PreviewWorld")
    scene.world.horizon_color = (0.055, 0.075, 0.11)
    scene.world.ambient_color = (0.28, 0.28, 0.28)

    mesh.hide = False
    mesh.hide_render = False
    for modifier in mesh.modifiers:
        if modifier.type == "ARMATURE":
            modifier.show_render = False
    preview_material = bpy.data.materials.new("RetargetPreview")
    preview_material.diffuse_color = (0.08, 0.24, 0.72)
    preview_material.specular_intensity = 0.25
    mesh.data.materials.clear()
    mesh.data.materials.append(preview_material)

    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    scene.objects.link(camera)
    camera.location = (190.0, -245.0, 130.0)
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 185.0
    camera.data.clip_end = 1000.0
    point_camera(camera, (0.0, 0.0, 72.0))
    scene.camera = camera

    lamp_data = bpy.data.lamps.new("PreviewKey", type="SUN")
    lamp_data.energy = 1.4
    lamp = bpy.data.objects.new("PreviewKey", lamp_data)
    scene.objects.link(lamp)
    lamp.rotation_euler = (0.55, -0.35, -0.75)

    scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)
    if not os.path.isfile(output_path):
        raise RuntimeError("Preview render was not created: " + output_path)


def main():
    marker = sys.argv.index("--")
    stock_cn6 = os.path.abspath(sys.argv[marker + 1])
    source_fbx = os.path.abspath(sys.argv[marker + 2])
    output_br2 = os.path.abspath(sys.argv[marker + 3])
    cn6_importer_path = os.path.abspath(sys.argv[marker + 4])
    br2_exporter_path = os.path.abspath(sys.argv[marker + 5])
    preview_path = os.path.abspath(sys.argv[marker + 6]) if len(sys.argv) > marker + 6 else None

    bpy.ops.wm.read_factory_settings(use_empty=True)

    cn6_importer = load_module("sayajin_cn6_importer", cn6_importer_path)
    error = cn6_importer.do_import(stock_cn6, DELETE_TOP_BONE=True)
    if error:
        raise RuntimeError(error)

    target_armatures = [obj for obj in bpy.data.objects if obj.type == "ARMATURE"]
    if len(target_armatures) != 1:
        raise RuntimeError("Expected exactly one Civ V target armature")
    target_armature = target_armatures[0]
    stock_meshes = [obj for obj in bpy.data.objects if obj.type == "MESH"]
    for stock_mesh in stock_meshes:
        bpy.data.objects.remove(stock_mesh, do_unlink=True)

    objects_before_fbx = set(bpy.data.objects)
    result = bpy.ops.import_scene.fbx(filepath=source_fbx, use_anim=False)
    if "FINISHED" not in result:
        raise RuntimeError("Failed to import Sayajin FBX: " + source_fbx)
    imported_objects = [obj for obj in bpy.data.objects if obj not in objects_before_fbx]
    source_armatures = [obj for obj in imported_objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in imported_objects if obj.type == "MESH"]
    if len(source_armatures) != 1 or len(meshes) != 1:
        raise RuntimeError("Expected one source armature and one Sayajin mesh")
    source_armature = source_armatures[0]
    mesh = meshes[0]

    missing_source = sorted(name for name in BONE_MAP if name not in source_armature.data.bones)
    missing_target = sorted(name for name in BONE_MAP.values() if name not in target_armature.data.bones)
    if missing_source or missing_target:
        raise RuntimeError("Retarget bones missing: source={0}, target={1}".format(
            missing_source, missing_target))

    scale_matrix = Matrix.Scale(RETARGET_SCALE, 4)
    transforms = {}
    for source_name, target_name in BONE_MAP.items():
        source_matrix = source_armature.data.bones[source_name].matrix_local.copy()
        target_matrix = target_armature.data.bones[target_name].matrix_local.copy()
        transforms[source_name] = target_matrix * scale_matrix * source_matrix.inverted()

    group_names = {group.index: group.name for group in mesh.vertex_groups}
    source_world_inverse = source_armature.matrix_world.inverted()
    mesh_to_source = source_world_inverse * mesh.matrix_world
    unweighted = []
    unmapped = set()
    for vertex in mesh.data.vertices:
        source_point = mesh_to_source * vertex.co
        weighted_point = Vector((0.0, 0.0, 0.0))
        total_weight = 0.0
        for assignment in vertex.groups:
            source_name = group_names[assignment.group]
            transform = transforms.get(source_name)
            if transform is None:
                unmapped.add(source_name)
                continue
            weighted_point += (transform * source_point) * assignment.weight
            total_weight += assignment.weight
        if total_weight <= 0.0:
            unweighted.append(vertex.index)
        else:
            vertex.co = weighted_point / total_weight
    if unweighted or unmapped:
        raise RuntimeError("Unsafe vertex binding: unweighted={0}, unmapped={1}".format(
            len(unweighted), sorted(unmapped)))

    for group in mesh.vertex_groups:
        group.name = BONE_MAP[group.name]

    for modifier in list(mesh.modifiers):
        mesh.modifiers.remove(modifier)
    modifier = mesh.modifiers.new(name="Civ V Base Human", type="ARMATURE")
    modifier.object = target_armature
    modifier.use_bone_envelopes = False
    modifier.use_vertex_groups = True
    mesh.parent = target_armature
    mesh.matrix_parent_inverse = Matrix.Identity(4)
    mesh.matrix_local = Matrix.Identity(4)

    bpy.data.objects.remove(source_armature, do_unlink=True)

    bpy.ops.object.select_all(action="DESELECT")
    mesh.select = True
    bpy.context.scene.objects.active = mesh
    triangulate = mesh.modifiers.new(name="Civ V Triangulation", type="TRIANGULATE")
    while mesh.modifiers[0] != triangulate:
        bpy.ops.object.modifier_move_up(modifier=triangulate.name)
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    for polygon in mesh.data.polygons:
        polygon.use_smooth = True
    if not mesh.data.uv_layers:
        raise RuntimeError("Retargeted mesh has no UV map")

    br2_exporter = load_module("sayajin_br2_exporter", br2_exporter_path)
    br2_exporter.do_export(output_br2)
    if not os.path.isfile(output_br2) or os.path.getsize(output_br2) == 0:
        raise RuntimeError("BR2 output was not created: " + output_br2)
    if preview_path:
        render_preview(mesh, preview_path)

    print("CIV5_SKELETON_RETARGET_OK source={0} output={1} vertices={2} bones={3} bounds={4}".format(
        os.path.basename(source_fbx), os.path.basename(output_br2),
        len(mesh.data.vertices), len(target_armature.data.bones) + 1, mesh_bounds(mesh)))


if __name__ == "__main__":
    main()
