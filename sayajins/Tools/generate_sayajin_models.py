"""Generate original low-poly Sayajin hero models and combat animations in Blender.

Run with Blender 4.2 in background mode:
    blender.exe --background --python generate_sayajin_models.py -- --output-root <path>

The exported FBX files are intermediate sources. Civ V consumes the GR2/FXSXML
files produced by the second stage of the pipeline.
"""

from __future__ import annotations

import argparse
import math
import os
from pathlib import Path

import bpy
from mathutils import Vector


HEROES = {
    "Vegeta": {
        "height": 1.00,
        "bulk": 1.00,
        "skin": (0.87, 0.61, 0.43, 1.0),
        "suit": (0.035, 0.08, 0.34, 1.0),
        "accent": (0.96, 0.96, 0.93, 1.0),
        "secondary": (0.95, 0.70, 0.10, 1.0),
        "hair": (0.008, 0.008, 0.012, 1.0),
        "eye": (0.02, 0.04, 0.05, 1.0),
        "style": "armor",
    },
    "Goku": {
        "height": 1.05,
        "bulk": 1.04,
        "skin": (0.88, 0.62, 0.44, 1.0),
        "suit": (0.95, 0.25, 0.025, 1.0),
        "accent": (0.025, 0.10, 0.28, 1.0),
        "secondary": (0.13, 0.38, 0.75, 1.0),
        "hair": (0.008, 0.008, 0.012, 1.0),
        "eye": (0.02, 0.04, 0.05, 1.0),
        "style": "gi",
    },
    "Gohan": {
        "height": 1.00,
        "bulk": 0.94,
        "skin": (0.88, 0.62, 0.44, 1.0),
        "suit": (0.25, 0.05, 0.39, 1.0),
        "accent": (0.74, 0.10, 0.08, 1.0),
        "secondary": (0.82, 0.50, 0.10, 1.0),
        "hair": (0.008, 0.008, 0.012, 1.0),
        "eye": (0.02, 0.04, 0.05, 1.0),
        "style": "gi",
    },
    "Piccolo": {
        "height": 1.08,
        "bulk": 1.02,
        "skin": (0.19, 0.58, 0.18, 1.0),
        "suit": (0.24, 0.05, 0.39, 1.0),
        "accent": (0.94, 0.94, 0.90, 1.0),
        "secondary": (0.72, 0.11, 0.09, 1.0),
        "hair": (0.19, 0.58, 0.18, 1.0),
        "eye": (0.04, 0.08, 0.04, 1.0),
        "style": "namek",
    },
    "Broly": {
        "height": 1.13,
        "bulk": 1.28,
        "skin": (0.85, 0.58, 0.40, 1.0),
        "suit": (0.035, 0.045, 0.04, 1.0),
        "accent": (0.16, 0.62, 0.18, 1.0),
        "secondary": (0.94, 0.68, 0.08, 1.0),
        "hair": (0.008, 0.008, 0.012, 1.0),
        "eye": (0.04, 0.10, 0.025, 1.0),
        "style": "berserker",
    },
}


PALETTE_KEYS = ("skin", "suit", "accent", "secondary", "hair", "eye")
ANIMATIONS = (
    ("IdleA", 40),
    ("Run", 20),
    ("AttackA", 24),
    ("AttackB", 32),
    ("Fortify", 20),
    ("Combat_Ready", 20),
    ("Victory", 40),
    ("Death_A", 38),
)
CIV5_UNIT_SCALE = 100.0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--hero", choices=tuple(HEROES), help="Generate only one hero (diagnostic/incremental build).")
    return parser.parse_args(os.sys.argv[os.sys.argv.index("--") + 1 :])


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.armatures, bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.actions):
        for block in list(datablocks):
            datablocks.remove(block)


def create_palette_image(hero: str, cfg: dict, output_dir: Path):
    size = 256
    image = bpy.data.images.new(f"Sayajin_{hero}_DIFF", width=size, height=size, alpha=True)
    colors = [cfg[key] for key in PALETTE_KEYS]
    colors += [colors[-1]] * (16 - len(colors))
    pixels = [0.0] * (size * size * 4)
    cell = size // 4
    for y in range(size):
        for x in range(size):
            swatch = min(15, (y // cell) * 4 + (x // cell))
            rgba = colors[swatch]
            index = (y * size + x) * 4
            pixels[index : index + 4] = rgba
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(output_dir / f"Sayajin_{hero}_DIFF.png")
    image.file_format = "PNG"
    image.save()
    return image


def create_material(hero: str, image):
    material = bpy.data.materials.new(f"Sayajin_{hero}_Material")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = 0.72
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Closest"
    material.node_tree.links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    return material


def apply_palette_uv(obj, palette_index: int) -> None:
    uv_layer = obj.data.uv_layers.active or obj.data.uv_layers.new(name="UVMap")
    col = palette_index % 4
    row = palette_index // 4
    uv = ((col + 0.5) / 4.0, (row + 0.5) / 4.0)
    for loop in uv_layer.data:
        loop.uv = uv


def finish_piece(obj, name: str, material, palette_index: int, bone_name: str, pieces: list) -> None:
    obj.name = name
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    apply_palette_uv(obj, palette_index)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    pieces.append(obj)


def add_uv_sphere(name, location, scale, material, palette_index, bone_name, pieces, segments=12, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.object
    obj.scale = scale
    finish_piece(obj, name, material, palette_index, bone_name, pieces)
    return obj


def add_cube(name, location, scale, material, palette_index, bone_name, pieces):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.scale = scale
    finish_piece(obj, name, material, palette_index, bone_name, pieces)
    return obj


def add_segment(name, start, end, radius, material, palette_index, bone_name, pieces, vertices=10):
    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v
    midpoint = (start_v + end_v) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=direction.length, location=midpoint)
    obj = bpy.context.object
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    finish_piece(obj, name, material, palette_index, bone_name, pieces)
    obj.rotation_mode = "XYZ"
    return obj


def add_cone(name, base, tip, radius, material, palette_index, bone_name, pieces, vertices=7):
    base_v = Vector(base)
    tip_v = Vector(tip)
    direction = tip_v - base_v
    midpoint = (base_v + tip_v) * 0.5
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0.015, depth=direction.length, location=midpoint)
    obj = bpy.context.object
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    finish_piece(obj, name, material, palette_index, bone_name, pieces)
    obj.rotation_mode = "XYZ"
    return obj


def create_armature(height: float):
    data = bpy.data.armatures.new("Sayajin_Rig")
    rig = bpy.data.objects.new("Sayajin_Rig", data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    h = height
    bones = {
        "Root": ((0, 0, 0), (0, 0, 0.18 * h), None),
        "Pelvis": ((0, 0, 0.18 * h), (0, 0, 0.72 * h), "Root"),
        "Spine": ((0, 0, 0.72 * h), (0, 0, 1.08 * h), "Pelvis"),
        "Chest": ((0, 0, 1.08 * h), (0, 0, 1.42 * h), "Spine"),
        "Neck": ((0, 0, 1.42 * h), (0, 0, 1.54 * h), "Chest"),
        "Head": ((0, 0, 1.54 * h), (0, 0, 1.82 * h), "Neck"),
        "UpperArm_L": ((-0.26 * h, 0, 1.36 * h), (-0.52 * h, 0, 1.12 * h), "Chest"),
        "Forearm_L": ((-0.52 * h, 0, 1.12 * h), (-0.62 * h, 0, 0.84 * h), "UpperArm_L"),
        "Hand_L": ((-0.62 * h, 0, 0.84 * h), (-0.64 * h, 0, 0.69 * h), "Forearm_L"),
        "UpperArm_R": ((0.26 * h, 0, 1.36 * h), (0.52 * h, 0, 1.12 * h), "Chest"),
        "Forearm_R": ((0.52 * h, 0, 1.12 * h), (0.62 * h, 0, 0.84 * h), "UpperArm_R"),
        "Hand_R": ((0.62 * h, 0, 0.84 * h), (0.64 * h, 0, 0.69 * h), "Forearm_R"),
        "Thigh_L": ((-0.14 * h, 0, 0.72 * h), (-0.15 * h, 0, 0.37 * h), "Pelvis"),
        "Shin_L": ((-0.15 * h, 0, 0.37 * h), (-0.15 * h, 0, 0.08 * h), "Thigh_L"),
        "Foot_L": ((-0.15 * h, 0, 0.08 * h), (-0.15 * h, -0.19 * h, 0.04 * h), "Shin_L"),
        "Thigh_R": ((0.14 * h, 0, 0.72 * h), (0.15 * h, 0, 0.37 * h), "Pelvis"),
        "Shin_R": ((0.15 * h, 0, 0.37 * h), (0.15 * h, 0, 0.08 * h), "Thigh_R"),
        "Foot_R": ((0.15 * h, 0, 0.08 * h), (0.15 * h, -0.19 * h, 0.04 * h), "Shin_R"),
    }
    edit_bones = {}
    for name, (head, tail, parent) in bones.items():
        bone = data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        bone.use_deform = True
        edit_bones[name] = bone
        if parent:
            bone.parent = edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.rotation_mode = "XYZ"
    return rig


def build_character(hero: str, cfg: dict, output_dir: Path):
    h = cfg["height"]
    bulk = cfg["bulk"]
    image = create_palette_image(hero, cfg, output_dir)
    material = create_material(hero, image)
    rig = create_armature(h)
    pieces = []

    # Anatomy and clothing are deliberately chunky so the silhouette survives Civ V's camera distance.
    add_uv_sphere("Pelvis", (0, 0, 0.72 * h), (0.22 * bulk, 0.15 * bulk, 0.20 * h), material, 1, "Pelvis", pieces)
    add_uv_sphere("Torso", (0, 0, 1.17 * h), (0.31 * bulk, 0.17 * bulk, 0.37 * h), material, 1, "Chest", pieces)
    add_segment("Neck", (0, 0, 1.39 * h), (0, 0, 1.56 * h), 0.095 * bulk, material, 0, "Neck", pieces)
    add_uv_sphere("Head", (0, -0.005, 1.69 * h), (0.17 * bulk, 0.145 * bulk, 0.21 * h), material, 0, "Head", pieces)
    face_front = -0.148 * bulk
    add_uv_sphere("Eye_L", (-0.056 * bulk, face_front, 1.72 * h), (0.027 * bulk, 0.012, 0.022 * h), material, 5, "Head", pieces, segments=8, rings=6)
    add_uv_sphere("Eye_R", (0.056 * bulk, face_front, 1.72 * h), (0.027 * bulk, 0.012, 0.022 * h), material, 5, "Head", pieces, segments=8, rings=6)
    add_segment("Brow_L", (-0.091 * bulk, face_front - 0.002, 1.765 * h), (-0.025 * bulk, face_front - 0.002, 1.752 * h), 0.009, material, 4, "Head", pieces, vertices=6)
    add_segment("Brow_R", (0.025 * bulk, face_front - 0.002, 1.752 * h), (0.091 * bulk, face_front - 0.002, 1.765 * h), 0.009, material, 4, "Head", pieces, vertices=6)
    add_uv_sphere("Nose", (0, face_front - 0.006, 1.675 * h), (0.024 * bulk, 0.018, 0.029 * h), material, 0, "Head", pieces, segments=8, rings=6)
    add_segment("Mouth", (-0.043 * bulk, face_front - 0.008, 1.625 * h), (0.043 * bulk, face_front - 0.008, 1.625 * h), 0.008, material, 5, "Head", pieces, vertices=6)

    shoulders = 0.29 * h * bulk
    arm_radius = 0.095 * bulk
    for suffix, sign in (("L", -1), ("R", 1)):
        upper_start = (sign * shoulders, 0, 1.34 * h)
        elbow = (sign * 0.52 * h * bulk, 0, 1.10 * h)
        wrist = (sign * 0.62 * h * bulk, 0, 0.83 * h)
        hand = (sign * 0.64 * h * bulk, -0.005, 0.72 * h)
        add_segment(f"UpperArm_{suffix}", upper_start, elbow, arm_radius, material, 0, f"UpperArm_{suffix}", pieces)
        add_segment(f"Forearm_{suffix}", elbow, wrist, arm_radius * 0.88, material, 0, f"Forearm_{suffix}", pieces)
        add_uv_sphere(f"Hand_{suffix}", hand, (0.09 * bulk, 0.075 * bulk, 0.105 * h), material, 0, f"Hand_{suffix}", pieces)

    leg_radius = 0.13 * bulk
    for suffix, sign in (("L", -1), ("R", 1)):
        hip = (sign * 0.14 * h * bulk, 0, 0.70 * h)
        knee = (sign * 0.15 * h * bulk, 0, 0.37 * h)
        ankle = (sign * 0.15 * h * bulk, 0, 0.09 * h)
        add_segment(f"Thigh_{suffix}", hip, knee, leg_radius, material, 1, f"Thigh_{suffix}", pieces)
        add_segment(f"Shin_{suffix}", knee, ankle, leg_radius * 0.86, material, 1, f"Shin_{suffix}", pieces)
        add_uv_sphere(f"Boot_{suffix}", (sign * 0.15 * h * bulk, -0.07 * h, 0.07 * h), (0.14 * bulk, 0.22 * h, 0.10 * h), material, 2, f"Foot_{suffix}", pieces)

    style = cfg["style"]
    if style == "armor":
        add_cube("ChestArmor", (0, -0.13 * bulk, 1.22 * h), (0.285 * bulk, 0.055, 0.24 * h), material, 2, "Chest", pieces)
        add_cube("ArmorCore", (0, -0.193 * bulk, 1.17 * h), (0.16 * bulk, 0.018, 0.15 * h), material, 3, "Chest", pieces)
        add_uv_sphere("Pauldron_L", (-0.31 * bulk, 0, 1.34 * h), (0.15 * bulk, 0.17 * bulk, 0.10 * h), material, 2, "UpperArm_L", pieces)
        add_uv_sphere("Pauldron_R", (0.31 * bulk, 0, 1.34 * h), (0.15 * bulk, 0.17 * bulk, 0.10 * h), material, 2, "UpperArm_R", pieces)
    elif style == "gi":
        add_cube("GiOverlap", (-0.05, -0.155 * bulk, 1.18 * h), (0.08 * bulk, 0.025, 0.26 * h), material, 2, "Chest", pieces)
        add_segment("Belt", (-0.22 * bulk, -0.01, 0.86 * h), (0.22 * bulk, -0.01, 0.86 * h), 0.055, material, 2, "Pelvis", pieces)
        add_segment("Wrist_L", (-0.58 * h * bulk, 0, 0.93 * h), (-0.62 * h * bulk, 0, 0.84 * h), 0.10, material, 2, "Forearm_L", pieces)
        add_segment("Wrist_R", (0.58 * h * bulk, 0, 0.93 * h), (0.62 * h * bulk, 0, 0.84 * h), 0.10, material, 2, "Forearm_R", pieces)
    elif style == "namek":
        add_cube("Cape", (0, 0.12, 1.17 * h), (0.39 * bulk, 0.045, 0.52 * h), material, 2, "Chest", pieces)
        add_uv_sphere("CapeShoulder_L", (-0.32 * bulk, 0, 1.37 * h), (0.20 * bulk, 0.21 * bulk, 0.14 * h), material, 2, "UpperArm_L", pieces)
        add_uv_sphere("CapeShoulder_R", (0.32 * bulk, 0, 1.37 * h), (0.20 * bulk, 0.21 * bulk, 0.14 * h), material, 2, "UpperArm_R", pieces)
        add_cone("Antenna_L", (-0.06, -0.11, 1.82 * h), (-0.10, -0.18, 2.00 * h), 0.022, material, 0, "Head", pieces)
        add_cone("Antenna_R", (0.06, -0.11, 1.82 * h), (0.10, -0.18, 2.00 * h), 0.022, material, 0, "Head", pieces)
        add_cone("Ear_L", (-0.15 * bulk, -0.01, 1.69 * h), (-0.29 * bulk, -0.015, 1.72 * h), 0.055, material, 0, "Head", pieces)
        add_cone("Ear_R", (0.15 * bulk, -0.01, 1.69 * h), (0.29 * bulk, -0.015, 1.72 * h), 0.055, material, 0, "Head", pieces)
    elif style == "berserker":
        add_segment("GoldCollar", (-0.20 * bulk, -0.03, 1.43 * h), (0.20 * bulk, -0.03, 1.43 * h), 0.065, material, 3, "Chest", pieces)
        add_segment("GreenSash", (-0.28 * bulk, -0.02, 0.83 * h), (0.28 * bulk, -0.02, 0.83 * h), 0.085, material, 2, "Pelvis", pieces)
        add_segment("GoldWrist_L", (-0.56 * h * bulk, 0, 0.97 * h), (-0.61 * h * bulk, 0, 0.84 * h), 0.115, material, 3, "Forearm_L", pieces)
        add_segment("GoldWrist_R", (0.56 * h * bulk, 0, 0.97 * h), (0.61 * h * bulk, 0, 0.84 * h), 0.115, material, 3, "Forearm_R", pieces)

    if style != "namek":
        spike_count = 8 if style == "berserker" else 6
        for i in range(spike_count):
            angle = (i / spike_count) * math.tau
            base = (0.09 * math.sin(angle), 0.08 * math.cos(angle), 1.79 * h)
            spread = 0.24 if style == "berserker" else 0.16
            if hero == "Goku":
                tip = (spread * 1.35 * math.sin(angle + 0.22), spread * 1.55 * math.cos(angle), (2.08 + 0.11 * (i % 3)) * h)
            elif hero == "Gohan":
                tip = (spread * 1.15 * math.sin(angle - 0.18), spread * math.cos(angle), (2.04 + 0.07 * (i % 2)) * h)
            else:
                tip = (spread * math.sin(angle), spread * math.cos(angle), (2.10 + 0.09 * (i % 2)) * h)
            add_cone(f"Hair_{i:02d}", base, tip, 0.115 * bulk, material, 4, "Head", pieces)
        add_cone("HairCrown", (0, 0.03, 1.82 * h), (0, 0.02, (2.25 if style == "armor" else 2.17) * h), 0.14 * bulk, material, 4, "Head", pieces)
        if hero == "Vegeta":
            add_cone("WidowsPeak", (0, -0.145 * bulk, 1.88 * h), (0, -0.158 * bulk, 1.77 * h), 0.060 * bulk, material, 4, "Head", pieces)

    # Join all pieces into one skinned mesh while retaining the rigid vertex groups.
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = f"Sayajin_{hero}_Mesh"
    modifier = mesh.modifiers.new(name="Sayajin_Rig", type="ARMATURE")
    modifier.object = rig
    mesh.parent = rig
    for polygon in mesh.data.polygons:
        polygon.use_smooth = True

    # Firaxis' Civ V assets are authored in centimetre-sized coordinates.
    # Scale the actual mesh and bind skeleton data (not an object/container
    # transform) so Granny calculates useful bounds and the game does not cull
    # the model before applying ArtDefine fScale.
    select_only([mesh])
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for vertex in mesh.data.vertices:
        vertex.co *= CIV5_UNIT_SCALE

    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for bone in rig.data.edit_bones:
        bone.head *= CIV5_UNIT_SCALE
        bone.tail *= CIV5_UNIT_SCALE
    bpy.ops.object.mode_set(mode="OBJECT")

    return rig, mesh


def pose_bone(rig, bone_name: str, rotation=(0, 0, 0), location=(0, 0, 0), frame=1):
    bone = rig.pose.bones[bone_name]
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = rotation
    bone.location = tuple(value * CIV5_UNIT_SCALE for value in location)
    bone.keyframe_insert(data_path="rotation_euler", frame=frame)
    bone.keyframe_insert(data_path="location", frame=frame)


def clear_pose(rig):
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0, 0, 0)
        bone.location = (0, 0, 0)


def create_action(rig, name: str, end_frame: int):
    action = bpy.data.actions.new(name=name)
    rig.animation_data_create()
    rig.animation_data.action = action
    clear_pose(rig)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = end_frame
    bpy.context.scene.render.fps = 30

    if name == "IdleA":
        for frame, sway in ((1, -0.035), (20, 0.045), (40, -0.035)):
            pose_bone(rig, "Chest", rotation=(0, sway, 0), frame=frame)
            pose_bone(rig, "UpperArm_L", rotation=(0.04, 0, -0.05 + sway), frame=frame)
            pose_bone(rig, "UpperArm_R", rotation=(-0.04, 0, 0.05 + sway), frame=frame)
    elif name == "Run":
        for frame, swing in ((1, 0.70), (6, 0.0), (11, -0.70), (16, 0.0), (20, 0.70)):
            pose_bone(rig, "Thigh_L", rotation=(swing, 0, 0), frame=frame)
            pose_bone(rig, "Thigh_R", rotation=(-swing, 0, 0), frame=frame)
            pose_bone(rig, "UpperArm_L", rotation=(-swing * 0.75, 0, 0), frame=frame)
            pose_bone(rig, "UpperArm_R", rotation=(swing * 0.75, 0, 0), frame=frame)
            pose_bone(rig, "Root", location=(0, 0, 0.025 if frame in (6, 16) else 0), frame=frame)
    elif name == "AttackA":
        keys = ((1, 0.0, 0.0), (8, -1.05, 0.35), (13, 1.25, -0.15), (18, 0.55, 0.0), (24, 0.0, 0.0))
        for frame, arm, chest in keys:
            pose_bone(rig, "UpperArm_R", rotation=(arm, 0, 0.12), frame=frame)
            pose_bone(rig, "Forearm_R", rotation=(max(0.0, -arm * 0.65), 0, 0), frame=frame)
            pose_bone(rig, "Chest", rotation=(0, 0, chest), frame=frame)
    elif name == "AttackB":
        for frame, arm, spread in ((1, 0.0, 0.0), (10, -0.85, 0.38), (17, 1.42, 0.05), (25, 1.20, 0.0), (32, 0.0, 0.0)):
            pose_bone(rig, "UpperArm_L", rotation=(arm, spread, -0.20), frame=frame)
            pose_bone(rig, "UpperArm_R", rotation=(arm, -spread, 0.20), frame=frame)
            pose_bone(rig, "Forearm_L", rotation=(0.25, 0, 0), frame=frame)
            pose_bone(rig, "Forearm_R", rotation=(0.25, 0, 0), frame=frame)
            pose_bone(rig, "Chest", rotation=(-0.10 if frame >= 17 else 0, 0, 0), frame=frame)
    elif name in ("Fortify", "Combat_Ready"):
        for frame, guard in ((1, 0.0), (10, 0.90), (20, 0.72 if name == "Combat_Ready" else 0.90)):
            pose_bone(rig, "UpperArm_L", rotation=(guard, 0.15, -0.35), frame=frame)
            pose_bone(rig, "UpperArm_R", rotation=(guard, -0.15, 0.35), frame=frame)
            pose_bone(rig, "Forearm_L", rotation=(0.85, 0, 0), frame=frame)
            pose_bone(rig, "Forearm_R", rotation=(0.85, 0, 0), frame=frame)
    elif name == "Victory":
        for frame, lift, bounce in ((1, 0.0, 0.0), (14, -1.55, 0.02), (27, -1.35, 0.0), (40, -1.55, 0.02)):
            pose_bone(rig, "UpperArm_L", rotation=(lift, 0, -0.30), frame=frame)
            pose_bone(rig, "UpperArm_R", rotation=(lift, 0, 0.30), frame=frame)
            pose_bone(rig, "Root", location=(0, 0, bounce), frame=frame)
    elif name == "Death_A":
        for frame, fall, drop in ((1, 0.0, 0.0), (12, -0.35, 0.0), (25, -1.15, -0.16), (38, -1.52, -0.38)):
            pose_bone(rig, "Root", rotation=(fall, 0, 0), location=(0, 0.10 * abs(fall), drop), frame=frame)
            pose_bone(rig, "UpperArm_L", rotation=(0.25, 0, -0.40), frame=frame)
            pose_bone(rig, "UpperArm_R", rotation=(-0.25, 0, 0.40), frame=frame)

    for curve in action.fcurves:
        for point in curve.keyframe_points:
            point.interpolation = "BEZIER" if name in ("IdleA", "Victory") else "LINEAR"
    rig.animation_data.action = None
    return action


def select_only(objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


def export_fbx(path: Path, rig, mesh=None, action=None, bake=False):
    rig.animation_data_create()
    rig.animation_data.action = action
    objects = [rig] + ([mesh] if mesh else [])
    select_only(objects)
    bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={"ARMATURE", "MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        use_space_transform=True,
        axis_forward="-Z",
        axis_up="Y",
        add_leaf_bones=False,
        use_armature_deform_only=True,
        armature_nodetype="ROOT",
        bake_anim=bake,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False,
        bake_anim_force_startend_keying=True,
        bake_anim_simplify_factor=0.0,
        path_mode="STRIP",
        embed_textures=False,
    )
    rig.animation_data.action = None


def export_hero(hero: str, cfg: dict, root: Path) -> None:
    reset_scene()
    output_dir = root / hero
    source_dir = output_dir / "Source"
    source_dir.mkdir(parents=True, exist_ok=True)
    rig, mesh = build_character(hero, cfg, output_dir)
    actions = {name: create_action(rig, name, frames) for name, frames in ANIMATIONS}

    # create_action leaves the rig in the last keyed pose even after detaching
    # the action.  Exporting that as the model's bind pose made the base mesh
    # inherit the final death pose and no longer match the animation files.
    clear_pose(rig)
    bpy.context.scene.frame_set(1)
    export_fbx(source_dir / f"Sayajin_{hero}_Model.fbx", rig, mesh=mesh, action=None, bake=False)
    for name, _ in ANIMATIONS:
        action = actions[name]
        bpy.context.scene.frame_set(1)
        bpy.context.scene.frame_end = int(action.frame_range[1])
        # The legacy Firaxis FBX importer only preserves animation tracks when
        # a skinned mesh accompanies the armature in the animation FBX.
        export_fbx(source_dir / f"Sayajin_{hero}_{name}.fbx", rig, mesh=mesh, action=action, bake=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(source_dir / f"Sayajin_{hero}.blend"))
    print(f"SAYAJIN_EXPORT_OK hero={hero} meshes=1 bones={len(rig.data.bones)} animations={len(actions)}")


def main() -> None:
    args = parse_args()
    root = Path(args.output_root).resolve()
    root.mkdir(parents=True, exist_ok=True)
    heroes = {args.hero: HEROES[args.hero]} if args.hero else HEROES
    for hero, cfg in heroes.items():
        export_hero(hero, cfg, root)


if __name__ == "__main__":
    main()
