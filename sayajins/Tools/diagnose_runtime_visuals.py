"""Compare Sayajin runtime art rows with installed custom units that render."""

from __future__ import annotations

import sqlite3
import sys


def rows(connection: sqlite3.Connection, sql: str, params=()):
    connection.row_factory = sqlite3.Row
    return [dict(row) for row in connection.execute(sql, params)]


def print_section(name: str, values):
    print(name)
    for value in values:
        print(value)


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: diagnose_runtime_visuals.py <Civ5DebugDatabase.db>")

    connection = sqlite3.connect(sys.argv[1])
    print_section(
        "CUSTOM_MODELS",
        rows(
            connection,
            """
            SELECT Type, Scale, ZOffset, Domain, Model,
                   MaterialTypeTag, MaterialTypeSoundOverrideTag
            FROM ArtDefine_UnitMemberInfos
            WHERE lower(Model) LIKE '%t810%'
               OR lower(Model) LIKE '%termin%'
               OR Type LIKE '%T_800%'
               OR Type LIKE '%ARNOLD%'
               OR Type LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN_%'
            ORDER BY Type
            """,
        ),
    )
    print_section(
        "CUSTOM_ART_INFOS",
        rows(
            connection,
            """
            SELECT i.*
            FROM ArtDefine_UnitInfos i
            WHERE i.Type LIKE '%T_800%'
               OR i.Type LIKE '%ARNOLD%'
               OR i.Type LIKE 'ART_DEF_UNIT_SAYAJIN_%'
            ORDER BY i.Type
            """,
        ),
    )
    print_section(
        "CUSTOM_MEMBER_LINKS",
        rows(
            connection,
            """
            SELECT *
            FROM ArtDefine_UnitInfoMemberInfos
            WHERE UnitInfoType LIKE '%T_800%'
               OR UnitInfoType LIKE '%ARNOLD%'
               OR UnitInfoType LIKE 'ART_DEF_UNIT_SAYAJIN_%'
            ORDER BY UnitInfoType, UnitMemberInfoType
            """,
        ),
    )
    print_section(
        "UNITS_USING_CUSTOM_ART",
        rows(
            connection,
            """
            SELECT Type, Class, Domain, MoveRate, UnitArtInfo,
                   UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
                   PortraitIndex, IconAtlas
            FROM Units
            WHERE UnitArtInfo LIKE '%T_800%'
               OR UnitArtInfo LIKE '%ARNOLD%'
               OR UnitArtInfo LIKE 'ART_DEF_UNIT_SAYAJIN_%'
            ORDER BY Type
            """,
        ),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
