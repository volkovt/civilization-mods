-- =====================================================
-- Sayajin Monument
-- Unique Monument replacement + non-stacking empire-wide
-- Worker speed bonus implemented through a hidden building.
-- =====================================================

-- -----------------------------------------------------
-- Unique Building: Sayajin Monument
-- IMPORTANT: a unique building replacement must keep the
-- generic BuildingClass it replaces: BUILDINGCLASS_MONUMENT.
-- -----------------------------------------------------
INSERT INTO IconTextureAtlases
        (Atlas,                    IconSize, Filename,                       IconsPerRow, IconsPerColumn)
VALUES  ('SAYAJIN_MONUMENT_ATLAS', 256,      'SayajinMonument_256.dds',  1,           1),
        ('SAYAJIN_MONUMENT_ATLAS', 128,      'SayajinMonument_128.dds',  1,           1),
        ('SAYAJIN_MONUMENT_ATLAS', 80,       'SayajinMonument_80.dds',   1,           1),
        ('SAYAJIN_MONUMENT_ATLAS', 64,       'SayajinMonument_64.dds',   1,           1),
        ('SAYAJIN_MONUMENT_ATLAS', 45,       'SayajinMonument_45.dds',   1,           1),
        ('SAYAJIN_MONUMENT_ATLAS', 32,       'SayajinMonument_32.dds',   1,           1);

INSERT INTO Buildings
        (Type,                        BuildingClass,              Cost, GoldMaintenance, PrereqTech,
         Description,                 Civilopedia,                Help, Strategy,
         ArtDefineTag,                MinAreaSize,                NeverCapture, NukeImmune,
         HurryCostModifier,           WorkerSpeedModifier,        PortraitIndex, IconAtlas)
SELECT  'BUILDING_SAYAJIN_MONUMENT',  'BUILDINGCLASS_MONUMENT',   Cost, GoldMaintenance, PrereqTech,
        'TXT_KEY_BUILDING_SAYAJIN_MONUMENT', 'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_PEDIA',
        'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_HELP', 'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_STRATEGY',
        ArtDefineTag,                 MinAreaSize,                NeverCapture, NukeImmune,
        HurryCostModifier,            0,                          0, 'SAYAJIN_MONUMENT_ATLAS'
FROM Buildings
WHERE Type = 'BUILDING_MONUMENT';

INSERT OR IGNORE INTO Building_YieldChanges
        (BuildingType,                 YieldType,        Yield)
SELECT  'BUILDING_SAYAJIN_MONUMENT',   YieldType,        Yield
FROM Building_YieldChanges
WHERE BuildingType = 'BUILDING_MONUMENT';

-- Vox Populi and other overhauls may already give the base Monument Faith.
-- Seed a zero row when absent and then add exactly +1 without risking a
-- duplicate-key failure that would cancel the whole database action.
INSERT OR IGNORE INTO Building_YieldChanges
        (BuildingType,                 YieldType,        Yield)
VALUES  ('BUILDING_SAYAJIN_MONUMENT',  'YIELD_FAITH',    0);

UPDATE Building_YieldChanges
SET Yield = Yield + 1
WHERE BuildingType = 'BUILDING_SAYAJIN_MONUMENT'
  AND YieldType = 'YIELD_FAITH';

INSERT OR IGNORE INTO Building_Flavors
        (BuildingType,                 FlavorType,       Flavor)
SELECT  'BUILDING_SAYAJIN_MONUMENT',   FlavorType,       Flavor
FROM Building_Flavors
WHERE BuildingType = 'BUILDING_MONUMENT';

INSERT OR IGNORE INTO Building_Flavors
        (BuildingType,                 FlavorType,                Flavor)
VALUES  ('BUILDING_SAYAJIN_MONUMENT',  'FLAVOR_RELIGION',         6),
        ('BUILDING_SAYAJIN_MONUMENT',  'FLAVOR_TILE_IMPROVEMENT', 8);

UPDATE Building_Flavors
SET Flavor = CASE
    WHEN FlavorType = 'FLAVOR_RELIGION' AND Flavor < 6 THEN 6
    WHEN FlavorType = 'FLAVOR_TILE_IMPROVEMENT' AND Flavor < 8 THEN 8
    ELSE Flavor
END
WHERE BuildingType = 'BUILDING_SAYAJIN_MONUMENT'
  AND FlavorType IN ('FLAVOR_RELIGION', 'FLAVOR_TILE_IMPROVEMENT');

INSERT INTO Civilization_BuildingClassOverrides
        (CivilizationType,        BuildingClassType,         BuildingType)
VALUES  ('CIVILIZATION_SAYAJIN',  'BUILDINGCLASS_MONUMENT',  'BUILDING_SAYAJIN_MONUMENT');

-- -----------------------------------------------------
-- Hidden empire-wide building
-- Applied by Lua to exactly one city in the empire once
-- the player owns at least one Sayajin Monument. This avoids
-- stacking WorkerSpeedModifier per city.
-- -----------------------------------------------------
INSERT INTO IconTextureAtlases
        (Atlas,                 IconSize, Filename,                      IconsPerRow, IconsPerColumn)
VALUES  ('SAYAJIN_EMPIRE_ATLAS', 256,     'SayajinEmpire_256.dds',   1,           1),
        ('SAYAJIN_EMPIRE_ATLAS', 128,     'SayajinEmpire_128.dds',   1,           1),
        ('SAYAJIN_EMPIRE_ATLAS', 80,      'SayajinEmpire_80.dds',    1,           1),
        ('SAYAJIN_EMPIRE_ATLAS', 64,      'SayajinEmpire_64.dds',    1,           1),
        ('SAYAJIN_EMPIRE_ATLAS', 45,      'SayajinEmpire_45.dds',    1,           1),
        ('SAYAJIN_EMPIRE_ATLAS', 32,      'SayajinEmpire_32.dds',    1,           1);

INSERT INTO BuildingClasses
        (Type,                                    DefaultBuilding,                      Description,                                MaxPlayerInstances)
VALUES  ('BUILDINGCLASS_SAYAJIN_MONUMENT_EMPIRE', 'BUILDING_SAYAJIN_MONUMENT_EMPIRE', 'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_EMPIRE', 1);

INSERT INTO Buildings
        (Type,                               BuildingClass,                              Cost, FaithCost, PrereqTech, GreatWorkCount,
         ArtDefineTag,                       MinAreaSize, NeverCapture, HurryCostModifier, NukeImmune,
         Description,                        Civilopedia,                                Help,
         PortraitIndex,                      IconAtlas,                                  WorkerSpeedModifier)
VALUES  ('BUILDING_SAYAJIN_MONUMENT_EMPIRE', 'BUILDINGCLASS_SAYAJIN_MONUMENT_EMPIRE',    -1,   -1,        NULL,      -1,
         'NONE',                             -1,          1,            -1,               1,
         'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_EMPIRE', 'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_EMPIRE_PEDIA', 'TXT_KEY_BUILDING_SAYAJIN_MONUMENT_EMPIRE_HELP',
         0,                                  'SAYAJIN_EMPIRE_ATLAS',                     25);
