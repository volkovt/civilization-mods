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


def dds_fourcc(path: Path) -> bytes:
    with path.open("rb") as stream:
        header = stream.read(88)
    if len(header) != 88 or header[:4] != b"DDS ":
        raise RuntimeError(f"Invalid DDS header: {path.name}")
    return header[84:88]


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

    attack_events = {"1100", "1140", "1160", "1180", "2100"}
    trigger_specs = {
        "FX_Triggers_Sayajin_Ranged.ftsxml": [
            "ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ",
        ],
        "FX_Triggers_Sayajin_Atomic.ftsxml": [
            "ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ",
            "ART_DEF_VEFFECT_ATOMIC_BOMB_01",
        ],
        "FX_Triggers_Sayajin_Nuclear.ftsxml": [
            "ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ",
            "ART_DEF_VEFFECT_NUCLEAR_BOMB_01",
        ],
    }
    for trigger_name, expected_effects in trigger_specs.items():
        project_file = project_files.get(trigger_name.lower())
        if not project_file or not project_file[0].is_file() or not project_file[1]:
            raise RuntimeError(f"Sayajin attack trigger is absent from VFS: {trigger_name}")

        trigger_root = ET.parse(project_file[0]).getroot()
        event_tracks = {
            track.attrib["ec"] for track in trigger_root.findall("./event_tracks/event_track")
        }
        if event_tracks != attack_events:
            raise RuntimeError(f"Attack event coverage is invalid: {trigger_name}")

        triggers = trigger_root.findall("./triggers/trigger")
        ids = [trigger.attrib["id"] for trigger in triggers]
        if len(ids) != len(set(ids)):
            raise RuntimeError(f"Duplicate trigger id in {trigger_name}")
        effects_by_id = {
            trigger.attrib["id"]: trigger
            for trigger in triggers
            if trigger.attrib.get("type") == "FTimedTriggerEffect"
        }
        transfers = [
            trigger
            for trigger in triggers
            if trigger.attrib.get("type") == "FTimedTriggerTransfer"
        ]
        for transfer in transfers:
            effect = effects_by_id.get(transfer.attrib.get("refid", ""))
            if effect is None or effect.attrib.get("ec") != transfer.attrib.get("ec"):
                raise RuntimeError(f"Orphan effect transfer in {trigger_name}")

        for event_code in attack_events:
            event_effects = [
                trigger.attrib.get("event")
                for trigger in effects_by_id.values()
                if trigger.attrib.get("ec") == event_code
            ]
            if sorted(event_effects) != sorted(expected_effects):
                raise RuntimeError(
                    f"Wrong effects for attack event {event_code}: {trigger_name}"
                )
            effect_ids = {
                trigger.attrib["id"]
                for trigger in effects_by_id.values()
                if trigger.attrib.get("ec") == event_code
            }
            transferred_ids = {
                trigger.attrib["refid"]
                for trigger in transfers
                if trigger.attrib.get("ec") == event_code
            }
            if effect_ids != transferred_ids:
                raise RuntimeError(
                    f"An attack effect is not transferred to its target: {trigger_name}"
                )
        if "RIFLE" in ET.tostring(trigger_root, encoding="unicode").upper():
            raise RuntimeError(f"Rifle effect leaked into Sayajin trigger: {trigger_name}")

    connection = sqlite3.connect(args.database)
    connection.row_factory = sqlite3.Row
    cursor = connection.cursor()

    civilization_art = cursor.execute(
        "SELECT DawnOfManImage, MapImage FROM Civilizations "
        "WHERE Type = 'CIVILIZATION_SAYAJIN'"
    ).fetchone()
    if civilization_art is None:
        raise RuntimeError("Sayajin civilization has no Dawn of Man configuration.")
    dawn_filename = Path(civilization_art["DawnOfManImage"].replace("\\", "/")).name
    dawn_file = project_files.get(dawn_filename.lower())
    if not dawn_file or not dawn_file[0].is_file() or not dawn_file[1]:
        raise RuntimeError(f"Dawn of Man texture is absent from VFS: {dawn_filename}")
    if dds_dimensions(dawn_file[0]) != (1024, 768):
        raise RuntimeError(
            f"Dawn of Man texture must be 1024x768: {dawn_filename} is "
            f"{dds_dimensions(dawn_file[0])[0]}x{dds_dimensions(dawn_file[0])[1]}"
        )
    if dds_fourcc(dawn_file[0]) != b"DXT5":
        raise RuntimeError(f"Dawn of Man texture is not legacy DXT5: {dawn_filename}")

    map_filename = Path(civilization_art["MapImage"].replace("\\", "/")).name
    map_file = project_files.get(map_filename.lower())
    if not map_file or not map_file[0].is_file() or not map_file[1]:
        raise RuntimeError(f"Civilization selection texture is absent from VFS: {map_filename}")
    if dds_dimensions(map_file[0]) != (360, 412):
        raise RuntimeError(
            f"Civilization selection texture must be 360x412: {map_filename} is "
            f"{dds_dimensions(map_file[0])[0]}x{dds_dimensions(map_file[0])[1]}"
        )
    if dds_fourcc(map_file[0]) != b"DXT5":
        raise RuntimeError(
            f"Civilization selection texture is not legacy DXT5: {map_filename}"
        )

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
    if len(infos) != 40:
        raise RuntimeError(f"Expected 40 Sayajin art infos, found {len(infos)}.")
    for info in infos:
        if info["UnitFlagAtlas"] != "SAYAJIN_HERO_FLAG_ATLAS":
            raise RuntimeError(f"Unknown unit flag atlas on {info['Type']}")

    members = cursor.execute(
        "SELECT * FROM ArtDefine_UnitMemberInfos WHERE Type LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%'"
    ).fetchall()
    if len(members) != 40:
        raise RuntimeError(f"Expected 40 Sayajin member arts, found {len(members)}.")
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
        is_ranged = any(
            hero in member["Type"] for hero in ("_GOKU", "_GOHAN", "_PICCOLO")
        )
        if is_ranged:
            required_bones.add("Base HumanRPalm")
        if not required_bones.issubset(bone_usage):
            raise RuntimeError(f"FXSXML has incomplete native bone usage: {model}")
        timed_trigger = asset.find("TimedTrigger")
        if timed_trigger is None:
            raise RuntimeError(f"FXSXML has no timed attack trigger: {model}")
        if is_ranged:
            if member["Type"].endswith("_POSTMODERN"):
                expected_trigger = "FX_Triggers_Sayajin_Atomic.ftsxml"
            elif member["Type"].endswith("_FUTURE"):
                expected_trigger = "FX_Triggers_Sayajin_Nuclear.ftsxml"
            else:
                expected_trigger = "FX_Triggers_Sayajin_Ranged.ftsxml"
            if timed_trigger.attrib.get("file") != expected_trigger:
                raise RuntimeError(
                    f"Ranged form uses the wrong attack trigger: {member['Type']}"
                )
            attack_animation = asset.find("./Animation[@file='Infantry_Attack_City.gr2']")
            if attack_animation is None or set(
                part.strip() for part in attack_animation.attrib.get("ec", "").split(",")
            ) != attack_events:
                raise RuntimeError(f"Ranged form has no hand-cast attack pose: {model}")
            forbidden_rifle_poses = {
                "infantry_charge_attack.gr2",
                "infantry_attacka.gr2",
                "infantry_attackb.gr2",
            }
            if forbidden_rifle_poses.intersection(
                animation.attrib["file"].lower() for animation in animations
            ):
                raise RuntimeError(f"Rifle attack pose leaked into ranged form: {model}")

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
        f"artMembers={len(members)} fxsxml={len(members)} triggers={len(trigger_specs)} "
        "dawn=1024x768-DXT5 map=360x412-DXT5"
    )


if __name__ == "__main__":
    main()
