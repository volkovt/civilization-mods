"""Inspect the Sayajin rows from an active Civ V cache database."""

from __future__ import annotations

import argparse
import sqlite3


def print_rows(cursor: sqlite3.Cursor, title: str, query: str) -> None:
    print(title)
    for row in cursor.execute(query):
        print(dict(row))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("database")
    args = parser.parse_args()

    connection = sqlite3.connect(args.database)
    connection.row_factory = sqlite3.Row
    cursor = connection.cursor()

    print_rows(
        cursor,
        "UNITS",
        """
        SELECT Type, UnitArtInfo, UnitArtInfoCulturalVariation,
               UnitArtInfoEraVariation, IconAtlas, UnitFlagAtlas,
               UnitFlagIconOffset
        FROM Units
        WHERE Type LIKE 'UNIT_SAYAJIN_HERO%'
        ORDER BY Type
        """,
    )
    print_rows(
        cursor,
        "ART_MEMBERS",
        """
        SELECT *
        FROM ArtDefine_UnitMemberInfos
        WHERE Type LIKE 'ART_DEF_UNIT_MEMBER_SAYAJIN%'
        ORDER BY Type
        """,
    )
    print_rows(
        cursor,
        "ART_INFOS",
        """
        SELECT *
        FROM ArtDefine_UnitInfos
        WHERE Type LIKE 'ART_DEF_UNIT_SAYAJIN%'
        ORDER BY Type
        """,
    )
    print_rows(
        cursor,
        "ATLASES",
        """
        SELECT *
        FROM IconTextureAtlases
        WHERE Atlas LIKE 'SAYAJIN%'
        ORDER BY Atlas, IconSize DESC
        """,
    )


if __name__ == "__main__":
    main()
