"""Apply every gameplay SQL file to a disposable copy of Civ V's database."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


def quote_identifier(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def reset_existing_sayajin_data(connection: sqlite3.Connection) -> int:
    """Remove a previously loaded Sayajin version from a disposable DB copy."""
    cursor = connection.cursor()
    removed = 0
    tables = [
        row[0]
        for row in cursor.execute(
            "SELECT name FROM sqlite_master "
            "WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        )
    ]
    for table in tables:
        text_columns = [
            row[1]
            for row in cursor.execute(f"PRAGMA table_info({quote_identifier(table)})")
            if "CHAR" in (row[2] or "").upper()
            or "CLOB" in (row[2] or "").upper()
            or "TEXT" in (row[2] or "").upper()
        ]
        if not text_columns:
            continue
        markers = ("%SAYAJIN%", "%LEADER_VEGETA%")
        where = " OR ".join(
            f"UPPER({quote_identifier(column)}) LIKE ?"
            for column in text_columns
            for _ in markers
        )
        parameters = []
        for _ in text_columns:
            parameters.extend(markers)
        before = connection.total_changes
        cursor.execute(f"DELETE FROM {quote_identifier(table)} WHERE {where}", parameters)
        removed += connection.total_changes - before
    connection.commit()
    return removed


def require_count(
    cursor: sqlite3.Cursor,
    label: str,
    query: str,
    expected: int,
    parameters: tuple[object, ...] = (),
) -> None:
    actual = cursor.execute(query, parameters).fetchone()[0]
    print(f"DB_CHECK {label}={actual}")
    if actual != expected:
        raise RuntimeError(f"{label}: expected {expected}, found {actual}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-database", required=True)
    parser.add_argument("--mod-root", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--reset-existing-sayajin",
        action="store_true",
        help="Remove v1-v7 Sayajin rows from the disposable copy before applying SQL.",
    )
    args = parser.parse_args()

    base_database = Path(args.base_database).resolve()
    mod_root = Path(args.mod_root).resolve()
    output = Path(args.output).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()

    source = sqlite3.connect(f"file:{base_database.as_posix()}?mode=ro", uri=True)
    destination = sqlite3.connect(output)
    source.backup(destination)
    source.close()
    destination.execute("PRAGMA foreign_keys = OFF")

    if args.reset_existing_sayajin:
        removed = reset_existing_sayajin_data(destination)
        print(f"DATABASE_RESET removed_rows={removed}")

    sql_files = sorted((mod_root / "Gameplay").glob("*.sql"))
    for sql_file in sql_files:
        try:
            destination.executescript(sql_file.read_text(encoding="utf-8-sig"))
            destination.commit()
            print(f"SQL_OK {sql_file.name}")
        except sqlite3.Error as error:
            raise RuntimeError(f"{sql_file.name}: {error}") from error

    cursor = destination.cursor()
    require_count(cursor, "civilization", "SELECT COUNT(*) FROM Civilizations WHERE Type='CIVILIZATION_SAYAJIN'", 1)
    require_count(cursor, "leader", "SELECT COUNT(*) FROM Leaders WHERE Type='LEADER_VEGETA'", 1)
    require_count(cursor, "trait", "SELECT COUNT(*) FROM Traits WHERE Type='TRAIT_SAYAJIN_PRIDE' AND FreeBuilding='BUILDING_SAYAJIN_HIDDEN_TRAIT'", 1)
    require_count(cursor, "custom_buildings", "SELECT COUNT(*) FROM Buildings WHERE Type IN ('BUILDING_SAYAJIN_HIDDEN_TRAIT','BUILDING_SAYAJIN_MONUMENT','BUILDING_SAYAJIN_MONUMENT_EMPIRE')", 3)
    require_count(cursor, "city_names", "SELECT COUNT(*) FROM Civilization_CityNames WHERE CivilizationType='CIVILIZATION_SAYAJIN'", 24)
    require_count(cursor, "spy_names", "SELECT COUNT(*) FROM Civilization_SpyNames WHERE CivilizationType='CIVILIZATION_SAYAJIN'", 12)
    require_count(cursor, "all_hero_units", "SELECT COUNT(*) FROM Units WHERE Type='UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_%'", 40)
    require_count(cursor, "hero_roots", "SELECT COUNT(*) FROM Units WHERE Type IN ('UNIT_SAYAJIN_HERO','UNIT_SAYAJIN_HERO_GOKU','UNIT_SAYAJIN_HERO_GOHAN','UNIT_SAYAJIN_HERO_PICCOLO','UNIT_SAYAJIN_HERO_BROWLY') AND Cost > 0 AND PrereqTech IS NOT NULL AND ShowInPedia=1", 5)
    require_count(cursor, "runtime_forms", "SELECT COUNT(*) FROM Units WHERE (Type LIKE 'UNIT_SAYAJIN_HERO_%_CLASSICAL' OR Type LIKE 'UNIT_SAYAJIN_HERO_%_MEDIEVAL' OR Type LIKE 'UNIT_SAYAJIN_HERO_%_RENAISSANCE' OR Type LIKE 'UNIT_SAYAJIN_HERO_%_INDUSTRIAL' OR Type LIKE 'UNIT_SAYAJIN_HERO_%_MODERN' OR Type LIKE 'UNIT_SAYAJIN_HERO_%_POSTMODERN' OR Type LIKE 'UNIT_SAYAJIN_HERO_%_FUTURE') AND Cost=-1 AND PrereqTech IS NULL AND ShowInPedia=0", 35)
    require_count(cursor, "hero_art_infos", "SELECT COUNT(*) FROM ArtDefine_UnitInfos WHERE Type LIKE 'ART_DEF_UNIT_SAYAJIN_%'", 40)
    require_count(cursor, "hero_art_members", "SELECT COUNT(*) FROM ArtDefine_UnitMemberInfos WHERE Type LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%'", 40)
    require_count(cursor, "hero_class_limits", "SELECT COUNT(*) FROM UnitClasses WHERE Type LIKE 'UNITCLASS_SAYAJIN_HERO%' AND MaxPlayerInstances=1 AND DefaultUnit IS NULL", 5)
    require_count(cursor, "civilization_hero_overrides", "SELECT COUNT(*) FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_SAYAJIN' AND UnitClassType LIKE 'UNITCLASS_SAYAJIN_HERO%'", 5)

    role_checks = {
        "vegeta_melee_land": ("Type='UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_VEGETA_%'", "DOMAIN_LAND", "UNITCOMBAT_MELEE", "UNITAI_ATTACK", 0, 0),
        "goku_ranged_land": ("Type='UNIT_SAYAJIN_HERO_GOKU' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOKU_%'", "DOMAIN_LAND", "UNITCOMBAT_ARCHER", "UNITAI_RANGED", 16, 3),
        "gohan_ranged_land": ("Type='UNIT_SAYAJIN_HERO_GOHAN' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOHAN_%'", "DOMAIN_LAND", "UNITCOMBAT_ARCHER", "UNITAI_RANGED", 19, 2),
        "piccolo_ranged_sea": ("Type='UNIT_SAYAJIN_HERO_PICCOLO' OR Type LIKE 'UNIT_SAYAJIN_HERO_PICCOLO_%'", "DOMAIN_SEA", "UNITCOMBAT_NAVALRANGED", "UNITAI_ASSAULT_SEA", 20, 4),
        "broly_melee_sea": ("Type='UNIT_SAYAJIN_HERO_BROWLY' OR Type LIKE 'UNIT_SAYAJIN_HERO_BROWLY_%'", "DOMAIN_SEA", "UNITCOMBAT_NAVALMELEE", "UNITAI_ATTACK_SEA", 0, 0),
    }
    for label, (family_where, domain, combat_class, default_ai, ranged, attack_range) in role_checks.items():
        require_count(
            cursor,
            label,
            f"SELECT COUNT(*) FROM Units WHERE ({family_where}) AND Domain=? AND CombatClass=? AND DefaultUnitAI=? AND RangedCombat=? AND Range=?",
            8,
            (domain, combat_class, default_ai, ranged, attack_range),
        )

    require_count(cursor, "hero_marker_promotions", "SELECT COUNT(*) FROM Unit_FreePromotions WHERE PromotionType='PROMOTION_SAYAJIN_HERO_MARK' AND (UnitType='UNIT_SAYAJIN_HERO' OR UnitType LIKE 'UNIT_SAYAJIN_HERO_%')", 40)
    require_count(cursor, "zenkai_promotions", "SELECT COUNT(*) FROM Unit_FreePromotions WHERE PromotionType='PROMOTION_SAYAJIN_ZENKAI' AND (UnitType='UNIT_SAYAJIN_HERO' OR UnitType LIKE 'UNIT_SAYAJIN_HERO_%')", 40)
    require_count(cursor, "land_hovering_promotions", "SELECT COUNT(*) FROM Unit_FreePromotions fp JOIN Units u ON u.Type=fp.UnitType WHERE fp.PromotionType='PROMOTION_HOVERING_UNIT' AND u.Domain='DOMAIN_LAND' AND (u.Type='UNIT_SAYAJIN_HERO' OR u.Type LIKE 'UNIT_SAYAJIN_HERO_%')", 24)
    require_count(cursor, "sea_hovering_promotions", "SELECT COUNT(*) FROM Unit_FreePromotions fp JOIN Units u ON u.Type=fp.UnitType WHERE fp.PromotionType='PROMOTION_HOVERING_UNIT' AND u.Domain='DOMAIN_SEA' AND u.Type LIKE 'UNIT_SAYAJIN_HERO%'", 0)
    require_count(cursor, "postmodern_finality", "SELECT COUNT(*) FROM Unit_FreePromotions WHERE PromotionType='PROMOTION_SAYAJIN_TRANSCENDENT_AURA' AND UnitType LIKE 'UNIT_SAYAJIN_HERO_%_POSTMODERN'", 5)
    require_count(cursor, "future_finality", "SELECT COUNT(*) FROM Unit_FreePromotions WHERE PromotionType='PROMOTION_SAYAJIN_FINAL_FORM' AND UnitType LIKE 'UNIT_SAYAJIN_HERO_%_FUTURE'", 5)
    require_count(cursor, "hero_native_nuke_units", "SELECT COUNT(*) FROM Units WHERE (Type='UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_%') AND NukeDamageLevel>=0", 0)
    require_count(cursor, "broly_signature_single_attack", "SELECT COUNT(*) FROM UnitPromotions WHERE Type='PROMOTION_SAYAJIN_ATTACK_BROLY' AND Blitz=0 AND ExtraAttacks=0", 1)
    require_count(cursor, "broly_nonfinal_extra_attacks", "SELECT COUNT(DISTINCT fp.UnitType) FROM Unit_FreePromotions fp JOIN UnitPromotions p ON p.Type=fp.PromotionType WHERE (fp.UnitType='UNIT_SAYAJIN_HERO_BROWLY' OR fp.UnitType LIKE 'UNIT_SAYAJIN_HERO_BROWLY_%') AND fp.UnitType NOT LIKE '%_FUTURE' AND (p.Blitz<>0 OR p.ExtraAttacks<>0)", 0)

    require_count(cursor, "melee_art_profiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY_%') AND HasShortRangedAttack=0 AND HasLongRangedAttack=0 AND HasStationaryMelee=1 AND HasStationaryRangedAttack=0", 16)
    require_count(cursor, "ranged_art_profiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombats WHERE (UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO_%') AND HasShortRangedAttack=1 AND HasLongRangedAttack=1 AND HasStationaryMelee=1 AND HasStationaryRangedAttack=1", 24)
    require_count(cursor, "melee_weapon_profiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY_%') AND [Index]=0", 16)
    require_count(cursor, "melee_projectiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY_%') AND [Index]<>0", 0)
    require_count(cursor, "ranged_laser_projectiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO_%') AND [Index]=0 AND ID='ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ' AND ProjectileSpeed>0", 24)
    require_count(cursor, "ranged_unused_weapon_slots", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN_%' OR UnitMemberType='ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO_%') AND [Index]<>0", 0)
    require_count(cursor, "melee_atomic_impact_profiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_POSTMODERN' AND [Index]=0 AND HitEffect='ART_DEF_VEFFECT_NUCLEAR_BOMB_01' AND ABS(HitEffectScale-0.65)<0.001", 2)
    require_count(cursor, "melee_nuclear_impact_profiles", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_FUTURE' AND [Index]=0 AND HitEffect='ART_DEF_VEFFECT_NUCLEAR_BOMB_01' AND ABS(HitEffectScale-1.25)<0.001", 2)
    require_count(cursor, "late_form_ranged_trigger_carriers", "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons WHERE (UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_POSTMODERN' OR UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%_FUTURE') AND [Index]=0 AND (UnitMemberType LIKE '%_GOKU_%' OR UnitMemberType LIKE '%_GOHAN_%' OR UnitMemberType LIKE '%_PICCOLO_%') AND ID='ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ' AND ProjectileSpeed>0 AND COALESCE(HitEffect,'')='' AND WaitForEffectCompletion=0 AND TargetGround=0", 6)

    require_count(cursor, "monument_faith_rows", "SELECT COUNT(*) FROM Building_YieldChanges WHERE BuildingType='BUILDING_SAYAJIN_MONUMENT' AND YieldType='YIELD_FAITH' AND Yield>=1", 1)
    require_count(cursor, "empire_bonus_building", "SELECT COUNT(*) FROM Buildings b JOIN BuildingClasses bc ON bc.Type=b.BuildingClass WHERE b.Type='BUILDING_SAYAJIN_MONUMENT_EMPIRE' AND b.Cost=-1 AND b.WorkerSpeedModifier=25 AND bc.MaxPlayerInstances=1", 1)
    require_count(cursor, "trait_terrain_yields", "SELECT COUNT(*) FROM Building_TerrainYieldChanges WHERE BuildingType='BUILDING_SAYAJIN_HIDDEN_TRAIT'", cursor.execute("SELECT COUNT(*) * 4 FROM Terrains").fetchone()[0])

    reference_checks = {
        "missing_civilization_color": "SELECT COUNT(*) FROM Civilizations c LEFT JOIN PlayerColors p ON p.Type=c.DefaultPlayerColor WHERE c.Type='CIVILIZATION_SAYAJIN' AND p.Type IS NULL",
        "missing_civilization_leaders": "SELECT COUNT(*) FROM Civilization_Leaders cl LEFT JOIN Civilizations c ON c.Type=cl.CivilizationType LEFT JOIN Leaders l ON l.Type=cl.LeaderheadType WHERE cl.CivilizationType='CIVILIZATION_SAYAJIN' AND (c.Type IS NULL OR l.Type IS NULL)",
        "missing_leader_traits": "SELECT COUNT(*) FROM Leader_Traits lt LEFT JOIN Leaders l ON l.Type=lt.LeaderType LEFT JOIN Traits t ON t.Type=lt.TraitType WHERE lt.LeaderType='LEADER_VEGETA' AND (l.Type IS NULL OR t.Type IS NULL)",
        "missing_leader_flavors": "SELECT COUNT(*) FROM Leader_Flavors lf LEFT JOIN Flavors f ON f.Type=lf.FlavorType WHERE lf.LeaderType='LEADER_VEGETA' AND f.Type IS NULL",
        "missing_trait_building": "SELECT COUNT(*) FROM Traits t LEFT JOIN Buildings b ON b.Type=t.FreeBuilding WHERE t.Type='TRAIT_SAYAJIN_PRIDE' AND b.Type IS NULL",
        "missing_building_classes": "SELECT COUNT(*) FROM Buildings b LEFT JOIN BuildingClasses bc ON bc.Type=b.BuildingClass WHERE b.Type LIKE 'BUILDING_SAYAJIN%' AND bc.Type IS NULL",
        "missing_building_class_defaults": "SELECT COUNT(*) FROM BuildingClasses bc LEFT JOIN Buildings b ON b.Type=bc.DefaultBuilding WHERE bc.Type LIKE 'BUILDINGCLASS_SAYAJIN%' AND bc.DefaultBuilding IS NOT NULL AND b.Type IS NULL",
        "missing_building_yields": "SELECT COUNT(*) FROM Building_YieldChanges byc LEFT JOIN Yields y ON y.Type=byc.YieldType WHERE byc.BuildingType LIKE 'BUILDING_SAYAJIN%' AND y.Type IS NULL",
        "missing_building_terrain_yields": "SELECT COUNT(*) FROM Building_TerrainYieldChanges btc LEFT JOIN Terrains t ON t.Type=btc.TerrainType LEFT JOIN Yields y ON y.Type=btc.YieldType WHERE btc.BuildingType LIKE 'BUILDING_SAYAJIN%' AND (t.Type IS NULL OR y.Type IS NULL)",
        "missing_building_flavors": "SELECT COUNT(*) FROM Building_Flavors bf LEFT JOIN Flavors f ON f.Type=bf.FlavorType WHERE bf.BuildingType LIKE 'BUILDING_SAYAJIN%' AND f.Type IS NULL",
        "missing_civilization_buildings": "SELECT COUNT(*) FROM Civilization_BuildingClassOverrides cbo LEFT JOIN BuildingClasses bc ON bc.Type=cbo.BuildingClassType LEFT JOIN Buildings b ON b.Type=cbo.BuildingType WHERE cbo.CivilizationType='CIVILIZATION_SAYAJIN' AND (bc.Type IS NULL OR b.Type IS NULL)",
        "missing_free_building_classes": "SELECT COUNT(*) FROM Civilization_FreeBuildingClasses f LEFT JOIN BuildingClasses bc ON bc.Type=f.BuildingClassType WHERE f.CivilizationType='CIVILIZATION_SAYAJIN' AND bc.Type IS NULL",
        "missing_free_techs": "SELECT COUNT(*) FROM Civilization_FreeTechs f LEFT JOIN Technologies t ON t.Type=f.TechType WHERE f.CivilizationType='CIVILIZATION_SAYAJIN' AND t.Type IS NULL",
        "missing_free_units": "SELECT COUNT(*) FROM Civilization_FreeUnits f LEFT JOIN UnitClasses uc ON uc.Type=f.UnitClassType LEFT JOIN UnitAIInfos ai ON ai.Type=f.UnitAIType WHERE f.CivilizationType='CIVILIZATION_SAYAJIN' AND (uc.Type IS NULL OR ai.Type IS NULL)",
        "missing_unit_classes": "SELECT COUNT(*) FROM Units u LEFT JOIN UnitClasses c ON c.Type=u.Class WHERE (u.Type='UNIT_SAYAJIN_HERO' OR u.Type LIKE 'UNIT_SAYAJIN_HERO_%') AND c.Type IS NULL",
        "missing_combat_classes": "SELECT COUNT(*) FROM Units u LEFT JOIN UnitCombatInfos c ON c.Type=u.CombatClass WHERE (u.Type='UNIT_SAYAJIN_HERO' OR u.Type LIKE 'UNIT_SAYAJIN_HERO_%') AND c.Type IS NULL",
        "missing_domains": "SELECT COUNT(*) FROM Units u LEFT JOIN Domains d ON d.Type=u.Domain WHERE (u.Type='UNIT_SAYAJIN_HERO' OR u.Type LIKE 'UNIT_SAYAJIN_HERO_%') AND d.Type IS NULL",
        "missing_unit_ai": "SELECT COUNT(*) FROM Units u LEFT JOIN UnitAIInfos a ON a.Type=u.DefaultUnitAI WHERE (u.Type='UNIT_SAYAJIN_HERO' OR u.Type LIKE 'UNIT_SAYAJIN_HERO_%') AND a.Type IS NULL",
        "missing_unit_ai_rows": "SELECT COUNT(*) FROM Unit_AITypes a LEFT JOIN UnitAIInfos ai ON ai.Type=a.UnitAIType WHERE a.UnitType LIKE 'UNIT_SAYAJIN_HERO%' AND ai.Type IS NULL",
        "missing_unit_flavors": "SELECT COUNT(*) FROM Unit_Flavors uf LEFT JOIN Flavors f ON f.Type=uf.FlavorType WHERE uf.UnitType LIKE 'UNIT_SAYAJIN_HERO%' AND f.Type IS NULL",
        "missing_unit_art": "SELECT COUNT(*) FROM Units u LEFT JOIN ArtDefine_UnitInfos a ON a.Type=u.UnitArtInfo WHERE (u.Type='UNIT_SAYAJIN_HERO' OR u.Type LIKE 'UNIT_SAYAJIN_HERO_%') AND a.Type IS NULL",
        "missing_free_promotions": "SELECT COUNT(*) FROM Unit_FreePromotions fp LEFT JOIN UnitPromotions p ON p.Type=fp.PromotionType WHERE (fp.UnitType='UNIT_SAYAJIN_HERO' OR fp.UnitType LIKE 'UNIT_SAYAJIN_HERO_%') AND p.Type IS NULL",
        "missing_unit_overrides": "SELECT COUNT(*) FROM Civilization_UnitClassOverrides uo LEFT JOIN UnitClasses uc ON uc.Type=uo.UnitClassType LEFT JOIN Units u ON u.Type=uo.UnitType WHERE uo.CivilizationType='CIVILIZATION_SAYAJIN' AND (uc.Type IS NULL OR u.Type IS NULL)",
        "missing_art_info_members": "SELECT COUNT(*) FROM ArtDefine_UnitInfoMemberInfos m LEFT JOIN ArtDefine_UnitInfos i ON i.Type=m.UnitInfoType LEFT JOIN ArtDefine_UnitMemberInfos mi ON mi.Type=m.UnitMemberInfoType WHERE m.UnitInfoType LIKE 'ART_DEF_UNIT_SAYAJIN_%' AND (i.Type IS NULL OR mi.Type IS NULL)",
        "missing_art_combats": "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombats c LEFT JOIN ArtDefine_UnitMemberInfos m ON m.Type=c.UnitMemberType WHERE c.UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%' AND m.Type IS NULL",
        "missing_art_weapons": "SELECT COUNT(*) FROM ArtDefine_UnitMemberCombatWeapons w LEFT JOIN ArtDefine_UnitMemberInfos m ON m.Type=w.UnitMemberType WHERE w.UnitMemberType LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%' AND m.Type IS NULL",
    }
    for label, query in reference_checks.items():
        require_count(cursor, label, query, 0)

    for unit_type, unit_art_info in cursor.execute(
        "SELECT Type, UnitArtInfo FROM Units WHERE Type='UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_%'"
    ):
        if not unit_art_info.startswith("ART_DEF_UNIT_SAYAJIN_"):
            raise RuntimeError(f"{unit_type} has invalid UnitArtInfo: {unit_art_info}")

    destination.close()
    print(f"DATABASE_VALIDATION_OK sql_files={len(sql_files)} database={output}")


if __name__ == "__main__":
    main()
