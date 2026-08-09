"""Re-export one animated FBX through Blender 2.79 for Civ V's FBX 2010 SDK."""

from __future__ import print_function

import os
import sys

import bpy


def main():
    marker = sys.argv.index("--")
    source = os.path.abspath(sys.argv[marker + 1])
    output = os.path.abspath(sys.argv[marker + 2])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=source, use_anim=True)

    actions = list(bpy.data.actions)
    if not actions:
        raise RuntimeError("No animation action was imported from " + source)
    action = actions[0]
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            obj.animation_data_create()
            obj.animation_data.action = action
    bpy.context.scene.frame_start = int(action.frame_range[0])
    bpy.context.scene.frame_end = int(action.frame_range[1])

    bpy.ops.export_scene.fbx(
        filepath=output,
        axis_forward="-Z",
        axis_up="Y",
        use_selection=False,
        object_types={"ARMATURE", "MESH"},
        add_leaf_bones=False,
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False,
        bake_anim_force_startend_keying=True,
        bake_anim_simplify_factor=0.0,
        path_mode="STRIP",
        embed_textures=False,
    )
    print("FBX279_OK source={0} output={1} action={2} frames={3}-{4}".format(
        os.path.basename(source), os.path.basename(output), action.name,
        int(action.frame_range[0]), int(action.frame_range[1])))


if __name__ == "__main__":
    main()
