"""Validate Civ V VFS, icon-atlas and animated unit-art integration."""

from __future__ import annotations

import argparse
import sqlite3
import struct
import xml.etree.ElementTree as ET
from pathlib import Path


MSBUILD_NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}


def dds_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(20)
    if len(header) != 20 or header[:4] != b"DDS ":
        raise RuntimeError(f"Invalid DDS header: {path.name}")
    height, width = struct.unpack_from("<II", header, 12)
    return width, height


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", required=True)
    parser.add_argument("--mod-root", required=True)
    parser.add_argument("--project", required=True)
    args = parser.parse_args()

    mod_root = Path(args.mod_root).resolve()
    project = ET.parse(args.project).getroot()
    project_files: dict[str, tuple[Path, bool]] = {}
    for content in project.findall(".//m:Content", MSBUILD_NS):
        relative = Path(content.attrib["Include"])
        imported = (content.findtext("m:ImportIntoVFS", "False", MSBUILD_NS).lower() == "true")
        project_files[relative.name.lower()] = (mod_root / relative, imported)

    connection = sqlite3.connect(args.database)
    connection.row_factory = sqlite3.Row
    cursor = connection.cursor()

    atlases = cursor.execute(
        "SELECT * FROM IconTextureAtlases WHERE Atlas LIKE 'SAYAJIN%'"
    ).fetchall()
    if not atlases:
        raise RuntimeError("No Sayajin icon atlases were created.")
    for atlas in atlases:
        filename = atlas["Filename"]
        if "/" in filename or "\\" in filename:
            raise RuntimeError(f"Atlas {atlas['Atlas']} uses a non-VFS filename: {filename}")
        project_file = project_files.get(filename.lower())
        if not project_file or not project_file[0].is_file() or not project_file[1]:
            raise RuntimeError(f"Atlas texture is absent from VFS: {filename}")
        width, height = dds_dimensions(project_file[0])
        logical_width = atlas["IconSize"] * int(atlas["IconsPerRow"])
        logical_height = atlas["IconSize"] * int(atlas["IconsPerColumn"])
        expected_width = (logical_width + 3) // 4 * 4
        expected_height = (logical_height + 3) // 4 * 4
        if width != expected_width or height != expected_height:
            raise RuntimeError(
                f"BC3 atlas has unsafe dimensions: {filename} is {width}x{height}, "
                f"expected {expected_width}x{expected_height}"
            )

    unit_rows = cursor.execute(
        """
        SELECT Type, UnitArtInfo, UnitArtInfoCulturalVariation,
               UnitArtInfoEraVariation
        FROM Units
        WHERE Type LIKE 'UNIT_SAYAJIN_HERO%'
        """
    ).fetchall()
    if len(unit_rows) != 40:
        raise RuntimeError(f"Expected 40 hero/form units, found {len(unit_rows)}.")
    for unit in unit_rows:
        if not unit["UnitArtInfo"].startswith("ART_DEF_UNIT_SAYAJIN_"):
            raise RuntimeError(f"Unit has no custom art: {unit['Type']}")
        if unit["UnitArtInfoCulturalVariation"] or unit["UnitArtInfoEraVariation"]:
            raise RuntimeError(f"Unit art variation would hide custom art: {unit['Type']}")

    infos = cursor.execute(
        "SELECT * FROM ArtDefine_UnitInfos WHERE Type LIKE 'ART_DEF_UNIT_SAYAJIN_%'"
    ).fetchall()
    if len(infos) != 5:
        raise RuntimeError(f"Expected 5 Sayajin art infos, found {len(infos)}.")
    for info in infos:
        if info["UnitFlagAtlas"] != "SAYAJIN_HERO_FLAG_ATLAS":
            raise RuntimeError(f"Unknown unit flag atlas on {info['Type']}")

    members = cursor.execute(
        "SELECT * FROM ArtDefine_UnitMemberInfos WHERE Type LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%'"
    ).fetchall()
    if len(members) != 5:
        raise RuntimeError(f"Expected 5 Sayajin member arts, found {len(members)}.")
    for member in members:
        model = member["Model"]
        if "/" in model or "\\" in model:
            raise RuntimeError(f"Unit model uses a non-VFS filename: {model}")
        project_file = project_files.get(model.lower())
        if not project_file or not project_file[0].is_file() or not project_file[1]:
            raise RuntimeError(f"Unit FXSXML is absent from VFS: {model}")
        if not 0.08 <= member["Scale"] <= 0.30:
            raise RuntimeError(f"Suspicious unit scale on {member['Type']}: {member['Scale']}")

        asset = ET.parse(project_file[0]).getroot()
        if asset.find("StateMachine") is None or len(asset.findall("AnimGraph")) < 15:
            raise RuntimeError(f"FXSXML has no complete animation state machine: {model}")
        animations = asset.findall("Animation")
        if len(animations) < 20:
            raise RuntimeError(f"FXSXML event coverage is incomplete: {model}")

        stock_animations = []
        for animation in animations:
            animation_file = animation.attrib["file"]
            if animation_file.lower().startswith("infantry_"):
                stock_animations.append(animation_file)
            elif not animation_file.lower().startswith("sayajin_"):
                raise RuntimeError(
                    f"FXSXML references an unapproved animation family: {animation_file}"
                )
        if len(stock_animations) != len(animations):
            raise RuntimeError(
                f"FXSXML does not exclusively use the proven Civ V Infantry skeleton: {model}"
            )
        bone_usage = {
            bone.attrib["name"] for bone in asset.findall("./BoneUsage/Bone")
        }
        required_bones = {"gun_bone", "Base HumanSpine1", "Base HumanSpine2"}
        if not required_bones.issubset(bone_usage):
            raise RuntimeError(f"FXSXML has incomplete native bone usage: {model}")
        if asset.find("TimedTrigger") is None:
            raise RuntimeError(f"FXSXML has no native Infantry effect triggers: {model}")

        local_files = [asset.find("Mesh").attrib["file"]]
        local_files.extend(
            texture.attrib["file"]
            for texture in asset.findall("Texture")
            if texture.attrib["file"].lower().startswith("sayajin_")
        )
        for filename in set(local_files):
            item = project_files.get(filename.lower())
            if not item or not item[0].is_file() or not item[1]:
                raise RuntimeError(f"FXSXML dependency is absent from VFS: {filename}")

    control = (mod_root / "Lua" / "Sayajin_HeroControl.lua").read_text(encoding="utf-8")
    if 'include("Lua/' in control:
        raise RuntimeError("Lua includes still use physical source paths.")

    print(
        "VISUAL_PIPELINE_OK "
        f"atlases={len(atlases)} units={len(unit_rows)} artInfos={len(infos)} "
        f"artMembers={len(members)} fxsxml={len(members)}"
    )


if __name__ == "__main__":
    main()
