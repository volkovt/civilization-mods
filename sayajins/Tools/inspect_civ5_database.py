"""Print Civ V art-definition schemas and useful reference rows."""

from __future__ import annotations

import argparse
import sqlite3


TABLES = (
    "ArtDefine_UnitInfos",
    "ArtDefine_UnitInfoMemberInfos",
    "ArtDefine_UnitMemberInfos",
    "ArtDefine_UnitMemberCombats",
    "ArtDefine_UnitMemberCombatWeapons",
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("database")
    args = parser.parse_args()
    connection = sqlite3.connect(args.database)
    connection.row_factory = sqlite3.Row
    cursor = connection.cursor()

    promotion_columns = [row[1] for row in cursor.execute("PRAGMA table_info(UnitPromotions)")]
    print(f"UNIT_PROMOTION_COLUMNS {promotion_columns}")

    for table in TABLES:
        columns = [row[1] for row in cursor.execute(f"PRAGMA table_info({table})")]
        print(f"\nTABLE {table}\nCOLUMNS {columns}")
        for row in cursor.execute(f"SELECT * FROM {table} LIMIT 2"):
            print(dict(row))

    for member in ("ART_DEF_UNIT_MEMBER_WARRIOR", "ART_DEF_UNIT_MEMBER_XCOM_SQUAD", "ART_DEF_UNIT_MEMBER_MECH"):
        print(f"\nREFERENCE {member}")
        for table in TABLES[2:]:
            key = "Type" if table == "ArtDefine_UnitMemberInfos" else "UnitMemberType"
            rows = cursor.execute(f"SELECT * FROM {table} WHERE {key} = ?", (member,)).fetchall()
            for row in rows:
                print(table, dict(row))

    print("\nMATCHING MEMBER TYPES")
    for row in cursor.execute("SELECT Type FROM ArtDefine_UnitMemberInfos WHERE Type LIKE '%WARRIOR%' OR Type LIKE '%XCOM%' OR Type LIKE '%MECH%'"):
        print(row[0])

    print("\nENERGY VISUAL EFFECTS")
    effect_tables = [row[0] for row in cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'ArtDefine%'")]
    for table in effect_tables:
        columns = [row[1] for row in cursor.execute(f"PRAGMA table_info({table})")]
        searchable = next((name for name in ("Type", "ID", "EffectType") if name in columns), None)
        if searchable:
            query = f"SELECT * FROM {table} WHERE {searchable} LIKE '%PLASMA%' OR {searchable} LIKE '%ENERGY%' OR {searchable} LIKE '%ALIEN%' LIMIT 30"
            rows = cursor.execute(query).fetchall()
            for row in rows:
                print(table, dict(row))


if __name__ == "__main__":
    main()
