"""Render neutral-pose previews of the generated Blender character sources."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import bpy
from mathutils import Vector


HEROES = ("Vegeta", "Goku", "Gohan", "Piccolo", "Broly")
FORMS = ("Classical", "Medieval", "Renaissance", "Industrial", "Modern", "PostModern", "Future")


def args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--units-root", required=True)
    parser.add_argument("--hero", choices=HEROES)
    parser.add_argument("--form", choices=FORMS)
    return parser.parse_args(os.sys.argv[os.sys.argv.index("--") + 1 :])


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render(hero: str, units_root: Path, form: str | None = None):
    hero_root = units_root / hero
    asset_name = f"Sayajin_{hero}" + (f"_{form}" if form else "")
    if form:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        result = bpy.ops.import_scene.fbx(
            filepath=str(hero_root / "Source" / f"{asset_name}_Model.fbx"),
            use_anim=False,
        )
        if "FINISHED" not in result:
            raise RuntimeError(f"Could not import transformation source: {asset_name}")
        texture_path = hero_root / f"{asset_name}_DIFF.png"
        texture_image = bpy.data.images.load(str(texture_path), check_existing=True)
        for imported_material in bpy.data.materials:
            imported_material.use_nodes = True
            nodes = imported_material.node_tree.nodes
            principled = nodes.get("Principled BSDF")
            texture_nodes = [node for node in nodes if node.type == "TEX_IMAGE"]
            texture_node = texture_nodes[0] if texture_nodes else nodes.new("ShaderNodeTexImage")
            texture_node.image = texture_image
            texture_node.interpolation = "Closest"
            if principled:
                imported_material.node_tree.links.new(
                    texture_node.outputs["Color"], principled.inputs["Base Color"]
                )
    else:
        bpy.ops.wm.open_mainfile(filepath=str(hero_root / "Source" / f"Sayajin_{hero}.blend"))

    rig = bpy.data.objects.get("Sayajin_Rig")
    if rig and rig.animation_data:
        rig.animation_data.action = None
    if rig:
        for bone in rig.pose.bones:
            bone.rotation_mode = "XYZ"
            bone.rotation_euler = (0, 0, 0)
            bone.location = (0, 0, 0)
    bpy.context.scene.frame_set(1)

    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    max_dimension = max((max(obj.dimensions) for obj in mesh_objects), default=1.0)
    preview_scale = 100.0 if max_dimension > 20.0 else 1.0

    bpy.ops.object.camera_add(location=tuple(value * preview_scale for value in (3.35, -6.4, 2.65)))
    camera = bpy.context.object
    camera.data.lens = 58
    point_at(camera, (0, 0, 1.10 * preview_scale))
    bpy.context.scene.camera = camera

    for location, energy, size, color in (
        ((3.2, -3.5, 5.0), 950, 4.0, (0.72, 0.84, 1.0)),
        ((-3.0, -1.0, 3.1), 700, 3.0, (1.0, 0.58, 0.25)),
        ((0.0, 3.0, 4.0), 800, 3.0, (0.40, 0.58, 1.0)),
    ):
        bpy.ops.object.light_add(type="AREA", location=tuple(value * preview_scale for value in location))
        light = bpy.context.object
        light.data.energy = energy * (preview_scale ** 2)
        light.data.shape = "DISK"
        light.data.size = size * preview_scale
        light.data.color = color
        point_at(light, (0, 0, 1.0 * preview_scale))

    bpy.ops.mesh.primitive_plane_add(size=12 * preview_scale, location=(0, 0, -0.04 * preview_scale))
    ground = bpy.context.object
    material = bpy.data.materials.new("PreviewGround")
    material.diffuse_color = (0.015, 0.025, 0.055, 1.0)
    material.metallic = 0.15
    material.roughness = 0.52
    ground.data.materials.append(material)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.filepath = str(hero_root / f"{asset_name}_preview.png")
    if scene.world is None:
        scene.world = bpy.data.worlds.new("SayajinPreviewWorld")
    scene.world.color = (0.008, 0.012, 0.025)
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)
    print(f"SAYAJIN_PREVIEW_OK hero={hero} form={form or 'Base'} file={scene.render.filepath}")


def main():
    arguments = args()
    root = Path(arguments.units_root).resolve()
    if arguments.form and not arguments.hero:
        raise ValueError("--form requires --hero")
    heroes = (arguments.hero,) if arguments.hero else HEROES
    for hero in heroes:
        render(hero, root, form=arguments.form)


if __name__ == "__main__":
    main()
