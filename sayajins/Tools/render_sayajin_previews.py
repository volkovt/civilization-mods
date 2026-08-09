"""Render neutral-pose previews of the generated Blender character sources."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import bpy
from mathutils import Vector


HEROES = ("Vegeta", "Goku", "Gohan", "Piccolo", "Broly")


def args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--units-root", required=True)
    return parser.parse_args(os.sys.argv[os.sys.argv.index("--") + 1 :])


def point_at(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render(hero: str, units_root: Path):
    hero_root = units_root / hero
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

    bpy.ops.object.camera_add(location=(3.35, -6.4, 2.65))
    camera = bpy.context.object
    camera.data.lens = 58
    point_at(camera, (0, 0, 1.10))
    bpy.context.scene.camera = camera

    for location, energy, size, color in (
        ((3.2, -3.5, 5.0), 950, 4.0, (0.72, 0.84, 1.0)),
        ((-3.0, -1.0, 3.1), 700, 3.0, (1.0, 0.58, 0.25)),
        ((0.0, 3.0, 4.0), 800, 3.0, (0.40, 0.58, 1.0)),
    ):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        light.data.color = color
        point_at(light, (0, 0, 1.0))

    bpy.ops.mesh.primitive_plane_add(size=12, location=(0, 0, -0.04))
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
    scene.render.filepath = str(hero_root / f"Sayajin_{hero}_preview.png")
    scene.world.color = (0.008, 0.012, 0.025)
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)
    print(f"SAYAJIN_PREVIEW_OK hero={hero} file={scene.render.filepath}")


def main():
    root = Path(args().units_root).resolve()
    for hero in HEROES:
        render(hero, root)


if __name__ == "__main__":
    main()
