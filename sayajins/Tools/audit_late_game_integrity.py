"""Audit Sayajin database, Lua, localization and late-era progression."""

from __future__ import annotations

import argparse
import math
import re
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path


MSBUILD_NAMESPACE = "http://schemas.microsoft.com/developer/msbuild/2003"
NS = {"m": MSBUILD_NAMESPACE}

HEROES = {
    "Vegeta": {"combat": 14, "ranged": 0, "is_ranged": False},
    "Goku": {"combat": 10, "ranged": 16, "is_ranged": True},
    "Gohan": {"combat": 12, "ranged": 19, "is_ranged": True},
    "Piccolo": {"combat": 14, "ranged": 20, "is_ranged": True},
    "Broly": {"combat": 18, "ranged": 0, "is_ranged": False},
}

EXPECTED_SQL_ORDER = [
    "Text/Sayajin_Text.xml",
    "Gameplay/00_Sayajin_Core.sql",
    "Gameplay/10_Sayajin_Monument.sql",
    "Gameplay/20_Sayajin_Heroes.sql",
    "Gameplay/30_Sayajin_HeroForms.sql",
    "Gameplay/40_Sayajin_ArtDefines.sql",
    "Gameplay/50_Sayajin_EvolutionsAndAttacks.sql",
]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def parse_project(project_path: Path, mod_root: Path) -> None:
    root = ET.parse(project_path).getroot()

    def property_text(name: str) -> str:
        value = root.findtext(f"m:PropertyGroup/m:{name}", default="", namespaces=NS)
        return value.strip()

    require(property_text("ModVersion") == "13", "Project must package ModVersion 13.")
    require(property_text("ReloadUnitSystem").lower() == "true", "ReloadUnitSystem must remain enabled for custom animated units.")
    require(property_text("SupportsSinglePlayer").lower() == "true", "Single-player support is disabled.")
    require(property_text("SupportsMultiplayer").lower() == "false", "Gameplay Lua is not network-synchronized; multiplayer must not be advertised.")

    actions = [
        action.findtext("m:FileName", default="", namespaces=NS).replace("\\", "/")
        for action in root.findall("m:PropertyGroup/m:ModActions/m:Action", NS)
    ]
    require(actions == EXPECTED_SQL_ORDER, f"Database action order changed: {actions}")

    project_files: dict[str, bool] = {}
    for content in root.findall(".//m:Content", NS):
        relative = content.attrib.get("Include")
        if not relative:
            continue
        path = mod_root / relative
        require(path.is_file(), f"Project references a missing file: {relative}")
        imported = content.findtext("m:ImportIntoVFS", default="False", namespaces=NS)
        project_files[relative.replace("\\", "/")] = imported.lower() == "true"

    required_vfs = [
        "Lua/Sayajin_Config.lua",
        "Lua/Sayajin_Utils.lua",
        "Lua/Sayajin_HeroService.lua",
        "Lua/Sayajin_MonumentService.lua",
        "Lua/Sayajin_NuclearService.lua",
    ]
    for relative in required_vfs:
        require(project_files.get(relative) is True, f"Lua dependency is absent from VFS: {relative}")
    require(project_files.get("Lua/Sayajin_HeroControl.lua") is False, "The InGameUIAddin entry point must not be imported into VFS.")

    print(
        f"PROJECT_AUDIT_OK version={property_text('ModVersion')} "
        f"files={len(project_files)} multiplayer=false"
    )


def audit_localization(mod_root: Path) -> None:
    text_path = mod_root / "Text" / "Sayajin_Text.xml"
    root = ET.parse(text_path).getroot()
    rows = root.findall("./Language_en_US/Row")
    tags = [row.attrib.get("Tag", "") for row in rows]
    require(len(tags) == len(set(tags)), "Localization contains duplicate tags.")

    empty = [
        row.attrib.get("Tag", "")
        for row in rows
        if not (row.findtext("Text") or "").strip()
    ]
    require(not empty, "Localization has empty text entries: " + ", ".join(empty))

    referenced: set[str] = set()
    key_pattern = re.compile(r"TXT_KEY_[A-Z0-9_]+")
    for folder, patterns in (("Gameplay", ("*.sql",)), ("Lua", ("*.lua",))):
        for pattern in patterns:
            for path in (mod_root / folder).glob(pattern):
                referenced.update(key_pattern.findall(path.read_text(encoding="utf-8-sig")))

    custom_references = {
        key for key in referenced if "SAYAJIN" in key or key.startswith("TXT_KEY_LEADER_VEGETA")
    }
    missing = sorted(
        key
        for key in custom_references
        if key not in tags
        and not (key.endswith("_") and any(tag.startswith(key) for tag in tags))
    )
    require(not missing, "Missing localization tags: " + ", ".join(missing))
    print(f"LOCALIZATION_AUDIT_OK tags={len(tags)} referenced_custom_tags={len(custom_references)}")


def audit_lua(mod_root: Path) -> tuple[float, int, int]:
    config = (mod_root / "Lua" / "Sayajin_Config.lua").read_text(encoding="utf-8-sig")
    utils = (mod_root / "Lua" / "Sayajin_Utils.lua").read_text(encoding="utf-8-sig")
    heroes = (mod_root / "Lua" / "Sayajin_HeroService.lua").read_text(encoding="utf-8-sig")
    monuments = (mod_root / "Lua" / "Sayajin_MonumentService.lua").read_text(encoding="utf-8-sig")
    nuclear = (mod_root / "Lua" / "Sayajin_NuclearService.lua").read_text(encoding="utf-8-sig")
    control = (mod_root / "Lua" / "Sayajin_HeroControl.lua").read_text(encoding="utf-8-sig")

    require("Config.Debug = false" in config, "Release debug logging is still enabled.")
    require("function Utils.Clamp" in utils and "function Utils.Error" in utils, "Lua safety helpers are missing.")
    require("pcall(SyncPlayerInternal, playerID)" in heroes, "Hero synchronization lock is not exception-safe.")
    require("isSyncing = false" in heroes, "Hero synchronization lock cannot be released.")
    require("SetBaseRangedCombatStrength(newRanged)" in heroes, "Existing-save ranged-role migration is missing.")
    require("ApplyHeroFormPromotions(pUnit, iEra)" in heroes, "Form-exclusive promotion normalization is missing.")
    require("SafeCall(\"Hero service\"" in control and "SafeCall(\"Monument service\"" in control, "Subsystem error isolation is missing.")
    require(monuments.count("for pCity in pPlayer:Cities() do") == 1, "Monument synchronization performs more than one full city scan.")
    require('include("Sayajin_NuclearService.lua")' in control, "Nuclear service is not loaded by the entry point.")
    require("applyingEffect" in nuclear and "pcall(function()" in nuclear, "Nuclear damage is not protected against re-entrancy or runtime errors.")
    require("Events.RunCombatSim.Add" in nuclear and "Events.EndCombatSim.Add" in nuclear, "Nuclear attacks are not tied to completed combat simulations.")
    require("Map.GetPlot(defenderX, defenderY)" in nuclear, "Nuclear attacks do not use the combat event's authoritative target coordinates.")
    require("pCity:ChangeDamage(appliedDamage)" in nuclear and "pUnit:ChangeDamage(damage, context.attackerPlayerID)" in nuclear, "Nuclear unit/city damage is incomplete.")
    require("maxHitPoints - currentDamage - 1" in nuclear, "Nuclear splash can bypass native city conquest rules.")
    require('include("Lua/' not in control, "Lua includes use physical paths instead of VFS basenames.")

    scale_match = re.search(r"Config\.HeroEraScale\s*=\s*([0-9.]+)", config)
    step_match = re.search(r"Config\.MaxEraStep\s*=\s*(\d+)", config)
    cap_match = re.search(r"Config\.MaxHeroStrength\s*=\s*(\d+)", config)
    require(scale_match is not None and step_match is not None and cap_match is not None, "Progression constants cannot be read.")
    scale = float(scale_match.group(1))
    max_step = int(step_match.group(1))
    cap = int(cap_match.group(1))
    require(1.0 < scale <= 2.0 and max_step == 7 and 100 <= cap <= 1000, "Unsafe progression constants.")

    expected_role_fragments = {
        "Vegeta": ("isRanged = false", "baseRangedCombat = 0"),
        "Goku": ("isRanged = true", "baseRangedCombat = 16"),
        "Gohan": ("isRanged = true", "baseRangedCombat = 19"),
        "Piccolo": ("isRanged = true", "baseRangedCombat = 20"),
        "Broly": ("isRanged = false", "baseRangedCombat = 0"),
    }
    group_positions = {
        name: config.index(f"    {name} = {{") for name in expected_role_fragments
    }
    ordered = sorted(group_positions.items(), key=lambda item: item[1])
    for index, (name, start) in enumerate(ordered):
        end = ordered[index + 1][1] if index + 1 < len(ordered) else config.index("Config.HeroTypeToGroupKey")
        block = config[start:end]
        for fragment in expected_role_fragments[name]:
            require(fragment in block, f"Lua role mismatch for {name}: {fragment}")

    print(f"LUA_AUDIT_OK scale={scale} max_step={max_step} strength_cap={cap}")
    return scale, max_step, cap


def audit_progression(scale: float, max_step: int, cap: int) -> None:
    future_values: list[str] = []
    for name, stats in HEROES.items():
        combat_values = [min(cap, math.floor(stats["combat"] * scale**step + 0.5)) for step in range(max_step + 1)]
        require(all(a <= b for a, b in zip(combat_values, combat_values[1:])), f"Combat progression regresses for {name}.")
        require(combat_values[-1] < cap, f"{name} hits the configured combat cap before the Future Era.")

        ranged_values = [
            min(cap, math.floor(stats["ranged"] * scale**step + 0.5))
            if stats["is_ranged"]
            else 0
            for step in range(max_step + 1)
        ]
        if stats["is_ranged"]:
            require(all(a <= b for a, b in zip(ranged_values, ranged_values[1:])), f"Ranged progression regresses for {name}.")
            require(ranged_values[-1] < cap, f"{name} hits the ranged cap before the Future Era.")
        else:
            require(set(ranged_values) == {0}, f"Melee hero {name} gains ranged strength.")

        # Even with the strongest simultaneous generic/signature modifiers,
        # values remain far below Civ V's practical integer/UI danger zone.
        conservative_effective = math.ceil(max(combat_values[-1], ranged_values[-1]) * 2.0)
        require(conservative_effective <= 1000, f"Unsafe worst-case effective strength for {name}: {conservative_effective}")
        future_values.append(f"{name}:{combat_values[-1]}/{ranged_values[-1]}")

    print("PROGRESSION_AUDIT_OK future_combat_ranged=" + ",".join(future_values))


def audit_database(database: Path) -> None:
    connection = sqlite3.connect(f"file:{database.as_posix()}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    cursor = connection.cursor()

    integrity = cursor.execute("PRAGMA integrity_check").fetchone()[0]
    require(integrity == "ok", f"SQLite integrity check failed: {integrity}")

    duplicate_queries = {
        "hero_ai": "SELECT COUNT(*) FROM (SELECT UnitType,UnitAIType,COUNT(*) n FROM Unit_AITypes WHERE UnitType LIKE 'UNIT_SAYAJIN_HERO%' GROUP BY UnitType,UnitAIType HAVING n>1)",
        "hero_promotions": "SELECT COUNT(*) FROM (SELECT UnitType,PromotionType,COUNT(*) n FROM Unit_FreePromotions WHERE UnitType LIKE 'UNIT_SAYAJIN_HERO%' GROUP BY UnitType,PromotionType HAVING n>1)",
        "hero_flavors": "SELECT COUNT(*) FROM (SELECT UnitType,FlavorType,COUNT(*) n FROM Unit_Flavors WHERE UnitType LIKE 'UNIT_SAYAJIN_HERO%' GROUP BY UnitType,FlavorType HAVING n>1)",
        "building_yields": "SELECT COUNT(*) FROM (SELECT BuildingType,YieldType,COUNT(*) n FROM Building_YieldChanges WHERE BuildingType LIKE 'BUILDING_SAYAJIN%' GROUP BY BuildingType,YieldType HAVING n>1)",
        "building_flavors": "SELECT COUNT(*) FROM (SELECT BuildingType,FlavorType,COUNT(*) n FROM Building_Flavors WHERE BuildingType LIKE 'BUILDING_SAYAJIN%' GROUP BY BuildingType,FlavorType HAVING n>1)",
    }
    for label, query in duplicate_queries.items():
        count = cursor.execute(query).fetchone()[0]
        require(count == 0, f"Duplicate rows detected in {label}: {count}")

    require(cursor.execute("SELECT COUNT(*) FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO%' AND Combat<=0").fetchone()[0] == 0, "A hero form has no melee/defensive combat strength.")
    require(cursor.execute("SELECT COUNT(*) FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO%' AND Moves<=0").fetchone()[0] == 0, "A hero form has invalid movement.")
    require(cursor.execute("SELECT COUNT(*) FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO%' AND Domain='DOMAIN_SEA' AND MinAreaSize<>1").fetchone()[0] == 0, "A naval hero can be blocked by minimum water-area size.")
    require(cursor.execute("SELECT COUNT(*) FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO%' AND Domain='DOMAIN_LAND' AND MoveRate<>'BIPED'").fetchone()[0] == 0, "A land hero has a naval movement profile.")
    require(cursor.execute("SELECT COUNT(*) FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO%' AND Domain='DOMAIN_SEA' AND MoveRate<>'BOAT'").fetchone()[0] == 0, "A naval hero has a land movement profile.")
    require(cursor.execute("SELECT COUNT(*) FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO%' AND NukeDamageLevel>=0").fetchone()[0] == 0, "A hero was converted into an unsafe native nuclear/suicide unit.")
    require(cursor.execute("SELECT COUNT(*) FROM ArtDefine_UnitInfos WHERE Type LIKE 'ART_DEF_UNIT_SAYAJIN_%'").fetchone()[0] == 40, "Transformation art infos are incomplete.")
    require(cursor.execute("SELECT COUNT(*) FROM ArtDefine_UnitMemberInfos WHERE Type LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%'").fetchone()[0] == 40, "Transformation member models are incomplete.")
    require(cursor.execute("SELECT COUNT(*) FROM Units u LEFT JOIN ArtDefine_UnitInfos a ON a.Type=u.UnitArtInfo WHERE u.Type LIKE 'UNIT_SAYAJIN_HERO%' AND a.Type IS NULL").fetchone()[0] == 0, "A hero transformation references missing art.")
    require(cursor.execute("SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_POSTMODERN' AND [Index]=0 AND HitEffect='ART_DEF_VEFFECT_NUCLEAR_BOMB_01'").fetchone()[0] == 2, "Melee atomic impact VFX are incomplete.")
    require(cursor.execute("SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_FUTURE' AND [Index]=0 AND HitEffect='ART_DEF_VEFFECT_NUCLEAR_BOMB_01'").fetchone()[0] == 2, "Melee nuclear-missile impact VFX are incomplete.")
    require(cursor.execute("SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_POSTMODERN' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_FUTURE') AND [Index]=0 AND (UnitMemberType LIKE '%_GOKU_%' OR UnitMemberType LIKE '%_GOHAN_%' OR UnitMemberType LIKE '%_PICCOLO_%') AND ID='ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ' AND ProjectileSpeed>0 AND COALESCE(HitEffect,'')='' AND WaitForEffectCompletion=0 AND TargetGround=0").fetchone()[0] == 6, "A ranged late-form trigger carrier is invalid.")
    require(cursor.execute("SELECT COUNT(*) FROM UnitPromotions WHERE Type='PROMOTION_SAYAJIN_ATTACK_BROLY' AND (Blitz<>0 OR ExtraAttacks<>0)").fetchone()[0] == 0, "Broly's signature promotion grants unintended extra attacks.")
    require(cursor.execute("SELECT COUNT(DISTINCT fp.UnitType) FROM Unit_FreePromotions fp JOIN UnitPromotions p ON p.Type=fp.PromotionType WHERE (fp.UnitType='UNIT_SAYAJIN_HERO_BROWLY' OR fp.UnitType LIKE 'UNIT_SAYAJIN_HERO_BROWLY_%') AND fp.UnitType NOT LIKE '%_FUTURE' AND (p.Blitz<>0 OR p.ExtraAttacks<>0)").fetchone()[0] == 0, "A non-final Broly form can attack more than once per turn.")

    class_counts = cursor.execute(
        "SELECT Class,COUNT(*) n FROM Units WHERE Type='UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_%' GROUP BY Class ORDER BY Class"
    ).fetchall()
    require(len(class_counts) == 5 and all(row["n"] == 8 for row in class_counts), f"Hero family/form distribution is invalid: {[dict(row) for row in class_counts]}")

    connection.close()
    print("DATABASE_LATE_GAME_AUDIT_OK integrity=ok families=5 forms_per_family=8 duplicates=0")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", required=True)
    parser.add_argument("--mod-root", required=True)
    parser.add_argument("--project", required=True)
    args = parser.parse_args()

    database = Path(args.database).resolve()
    mod_root = Path(args.mod_root).resolve()
    project = Path(args.project).resolve()

    parse_project(project, mod_root)
    audit_localization(mod_root)
    scale, max_step, cap = audit_lua(mod_root)
    audit_progression(scale, max_step, cap)
    audit_database(database)
    print("LATE_GAME_INTEGRITY_OK")


if __name__ == "__main__":
    main()
