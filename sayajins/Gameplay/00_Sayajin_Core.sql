-- =====================================================
-- Sayajin Civilization - Core data
-- Civilization, colors, trait, all-terrain hidden bonus,
-- leader, city names, spy names and diplomacy hooks.
-- =====================================================

-- -----------------------------------------------------
-- Civilization icon atlases
-- Keep all existing art references. The actual DDS/PNG
-- files are expected to remain in the ART folder locally.
-- -----------------------------------------------------
INSERT INTO IconTextureAtlases
        (Atlas,                IconSize, Filename,                    IconsPerRow, IconsPerColumn)
VALUES  ('SAYAJIN_ICON_ATLAS', 256,      'SayajinIcon_256.dds',   1,           1),
        ('SAYAJIN_ICON_ATLAS', 128,      'SayajinIcon_128.dds',   1,           1),
        ('SAYAJIN_ICON_ATLAS', 80,       'SayajinIcon_80.dds',    1,           1),
        ('SAYAJIN_ICON_ATLAS', 64,       'SayajinIcon_64.dds',    1,           1),
        ('SAYAJIN_ICON_ATLAS', 45,       'SayajinIcon_45.dds',    1,           1),
        ('SAYAJIN_ICON_ATLAS', 32,       'SayajinIcon_32.dds',    1,           1),
        ('SAYAJIN_ALPHA_ATLAS',128,      'SayajinAlpha_128.dds',  1,           1),
        ('SAYAJIN_ALPHA_ATLAS',80,       'SayajinAlpha_80.dds',   1,           1),
        ('SAYAJIN_ALPHA_ATLAS',64,       'SayajinAlpha_64.dds',   1,           1),
        ('SAYAJIN_ALPHA_ATLAS',45,       'SayajinAlpha_45.dds',   1,           1),
        ('SAYAJIN_ALPHA_ATLAS',32,       'SayajinAlpha_32.dds',   1,           1);

-- -----------------------------------------------------
-- Colors
-- Inspired by Vegeta's classic Saiyan armor: dark royal
-- blue, battle white and golden accents.
-- -----------------------------------------------------
INSERT INTO Colors
        (Type,                            Red,   Green, Blue,  Alpha)
VALUES  ('COLOR_PLAYER_SAYAJIN_PRIMARY',   0.055, 0.365, 0.920, 1.0),
        ('COLOR_PLAYER_SAYAJIN_SECONDARY', 1.000, 0.790, 0.095, 1.0),
        ('COLOR_PLAYER_SAYAJIN_TEXT',      0.980, 0.820, 0.280, 1.0);

INSERT INTO PlayerColors
        (Type,                 PrimaryColor,                   SecondaryColor,                    TextColor)
VALUES  ('PLAYERCOLOR_SAYAJIN','COLOR_PLAYER_SAYAJIN_PRIMARY','COLOR_PLAYER_SAYAJIN_SECONDARY', 'COLOR_PLAYER_SAYAJIN_TEXT');

-- -----------------------------------------------------
-- Hidden building used by the trait
-- -----------------------------------------------------
INSERT INTO IconTextureAtlases
        (Atlas,                  IconSize, Filename,                    IconsPerRow, IconsPerColumn)
VALUES  ('SAYAJIN_TRAIT_ATLAS',  256,      'SayajinTrait_256.dds',  1,           1),
        ('SAYAJIN_TRAIT_ATLAS',  128,      'SayajinTrait_128.dds',  1,           1),
        ('SAYAJIN_TRAIT_ATLAS',  80,       'SayajinTrait_80.dds',   1,           1),
        ('SAYAJIN_TRAIT_ATLAS',  64,       'SayajinTrait_64.dds',   1,           1),
        ('SAYAJIN_TRAIT_ATLAS',  45,       'SayajinTrait_45.dds',   1,           1),
        ('SAYAJIN_TRAIT_ATLAS',  32,       'SayajinTrait_32.dds',   1,           1);

INSERT INTO BuildingClasses
        (Type,                                  DefaultBuilding,                  Description)
VALUES  ('BUILDINGCLASS_SAYAJIN_HIDDEN_TRAIT',  'BUILDING_SAYAJIN_HIDDEN_TRAIT', 'TXT_KEY_BUILDING_SAYAJIN_HIDDEN_TRAIT');

INSERT INTO Buildings
        (Type,                           BuildingClass,                        Cost, FaithCost, PrereqTech, GreatWorkCount,
         ArtDefineTag, MinAreaSize, NeverCapture, HurryCostModifier, NukeImmune,
         Description, Civilopedia, Help, PortraitIndex, IconAtlas)
VALUES  ('BUILDING_SAYAJIN_HIDDEN_TRAIT', 'BUILDINGCLASS_SAYAJIN_HIDDEN_TRAIT', -1,   -1,        NULL,      -1,
         'NONE',       -1,          1,            -1,                1,
         'TXT_KEY_BUILDING_SAYAJIN_HIDDEN_TRAIT', 'TXT_KEY_BUILDING_SAYAJIN_HIDDEN_TRAIT_PEDIA', 'TXT_KEY_BUILDING_SAYAJIN_HIDDEN_TRAIT_HELP', 0, 'SAYAJIN_TRAIT_ATLAS');

-- -----------------------------------------------------
-- All-terrain Sayajin trait
-- Before: the project listed terrain/yield pairs manually,
-- which made the bonus incomplete and easy to break.
-- Now: every terrain present in the active database receives
-- the same +1 Food, +1 Production, +1 Culture and +1 Faith.
-- This also stays compatible with terrain additions from mods.
-- -----------------------------------------------------
DELETE FROM Building_TerrainYieldChanges
WHERE BuildingType = 'BUILDING_SAYAJIN_HIDDEN_TRAIT';

INSERT INTO Building_TerrainYieldChanges
        (BuildingType,                    TerrainType, YieldType, Yield)
SELECT  'BUILDING_SAYAJIN_HIDDEN_TRAIT',  t.Type,      y.Type,    1
FROM Terrains t
CROSS JOIN Yields y
WHERE y.Type IN ('YIELD_FOOD', 'YIELD_PRODUCTION', 'YIELD_CULTURE', 'YIELD_FAITH');

-- -----------------------------------------------------
-- Trait
-- -----------------------------------------------------
INSERT INTO Traits
        (Type,                  Description,                    ShortDescription,                    FreeBuilding)
VALUES  ('TRAIT_SAYAJIN_PRIDE', 'TXT_KEY_TRAIT_SAYAJIN_PRIDE', 'TXT_KEY_TRAIT_SAYAJIN_PRIDE_SHORT', 'BUILDING_SAYAJIN_HIDDEN_TRAIT');

-- -----------------------------------------------------
-- Leader
-- Uses a base-game leader scene as placeholder art only.
-- -----------------------------------------------------
INSERT INTO Leaders
        (Type,            Description,            Civilopedia,                  CivilopediaTag,                         ArtDefineTag,
         VictoryCompetitiveness, WonderCompetitiveness, MinorCivCompetitiveness, Boldness, DiploBalance, WarmongerHate,
         WorkAgainstWillingness, WorkWithWillingness, DenounceWillingness, DoFWillingness, Loyalty, Neediness, Forgiveness,
         Chattiness, Meanness, PortraitIndex, IconAtlas)
VALUES  ('LEADER_VEGETA', 'TXT_KEY_LEADER_VEGETA', 'TXT_KEY_LEADER_VEGETA_PEDIA', 'TXT_KEY_CIVILOPEDIA_LEADERS_VEGETA', 'OdaNobunaga_Scene.xml',
         10,                   4,                     2,                         10,      2,            1,
         1,                    0,                    9,                    1,             8,       5,        1,
         4,          10,       0,             'SAYAJIN_ICON_ATLAS');

INSERT INTO Leader_Traits
        (LeaderType,      TraitType)
VALUES  ('LEADER_VEGETA', 'TRAIT_SAYAJIN_PRIDE');

INSERT INTO Leader_Flavors
        (LeaderType,      FlavorType,                 Flavor)
VALUES  ('LEADER_VEGETA', 'FLAVOR_OFFENSE',           10),
        ('LEADER_VEGETA', 'FLAVOR_DEFENSE',           6),
        ('LEADER_VEGETA', 'FLAVOR_CITY_DEFENSE',      4),
        ('LEADER_VEGETA', 'FLAVOR_MILITARY_TRAINING', 10),
        ('LEADER_VEGETA', 'FLAVOR_PRODUCTION',        8),
        ('LEADER_VEGETA', 'FLAVOR_GROWTH',            7),
        ('LEADER_VEGETA', 'FLAVOR_RELIGION',          4),
        ('LEADER_VEGETA', 'FLAVOR_CULTURE',           5),
        ('LEADER_VEGETA', 'FLAVOR_TILE_IMPROVEMENT',  8),
        ('LEADER_VEGETA', 'FLAVOR_EXPANSION',         7),
        ('LEADER_VEGETA', 'FLAVOR_NAVAL',             2),
        ('LEADER_VEGETA', 'FLAVOR_RECON',             4),
        ('LEADER_VEGETA', 'FLAVOR_SCIENCE',           6);

-- -----------------------------------------------------
-- Civilization
-- Stable approach: copy a base civ row and override identity/art hooks.
-- -----------------------------------------------------
INSERT INTO Civilizations
        (Type,                  Description,               Civilopedia, CivilopediaTag,             Strategy,
         Playable, AIPlayable, ShortDescription,          Adjective,                 DefaultPlayerColor,
         ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
         PortraitIndex, IconAtlas,            AlphaIconAtlas,          MapImage,
         DawnOfManQuote,              DawnOfManImage,            DawnOfManAudio, SoundtrackTag)
SELECT  'CIVILIZATION_SAYAJIN', 'TXT_KEY_CIV_SAYAJIN_DESC', NULL,       'TXT_KEY_CIV5_SAYAJIN_TEXT', 'TXT_KEY_CIV_SAYAJIN_STRATEGY',
        1,        1,          'TXT_KEY_CIV_SAYAJIN_SHORT_DESC', 'TXT_KEY_CIV_SAYAJIN_ADJECTIVE', 'PLAYERCOLOR_SAYAJIN',
        ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
        0,             'SAYAJIN_ICON_ATLAS', 'SAYAJIN_ALPHA_ATLAS', 'Art/SayajinMap_512.dds',
        'TXT_KEY_CIV5_DOM_SAYAJIN_TEXT', 'Art/SayajinDawn_768.dds', DawnOfManAudio, SoundtrackTag
FROM Civilizations
WHERE Type = 'CIVILIZATION_ARABIA';

INSERT INTO Civilization_Leaders
        (CivilizationType,       LeaderheadType)
VALUES  ('CIVILIZATION_SAYAJIN', 'LEADER_VEGETA');

INSERT INTO Civilization_FreeBuildingClasses
        (CivilizationType,       BuildingClassType)
VALUES  ('CIVILIZATION_SAYAJIN', 'BUILDINGCLASS_PALACE');

INSERT INTO Civilization_FreeTechs
        (CivilizationType,       TechType)
VALUES  ('CIVILIZATION_SAYAJIN', 'TECH_AGRICULTURE');

INSERT INTO Civilization_FreeUnits
        (CivilizationType,       UnitClassType,      UnitAIType,       Count)
VALUES  ('CIVILIZATION_SAYAJIN', 'UNITCLASS_SETTLER', 'UNITAI_SETTLE', 1),
        ('CIVILIZATION_SAYAJIN', 'UNITCLASS_WARRIOR', 'UNITAI_ATTACK', 1);

-- No forced start region: the trait is intentionally valid on all terrains.

-- -----------------------------------------------------
-- City list
-- -----------------------------------------------------
INSERT INTO Civilization_CityNames
        (CivilizationType,       CityName)
VALUES  ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_1'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_2'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_3'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_4'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_5'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_6'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_7'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_8'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_9'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_10'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_11'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_12'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_13'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_14'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_15'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_16'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_17'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_18'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_19'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_20'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_21'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_22'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_23'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_CITY_NAME_SAYAJIN_24');

-- -----------------------------------------------------
-- Spy names
-- -----------------------------------------------------
INSERT INTO Civilization_SpyNames
        (CivilizationType,       SpyName)
VALUES  ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_0'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_1'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_2'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_3'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_4'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_5'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_6'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_7'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_8'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_9'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_10'),
        ('CIVILIZATION_SAYAJIN', 'TXT_KEY_SPY_NAME_SAYAJIN_11');

-- -----------------------------------------------------
-- Custom diplomacy hooks
-- -----------------------------------------------------
INSERT INTO Diplomacy_Responses
        (LeaderType,      ResponseType,               Response)
VALUES  ('LEADER_VEGETA', 'RESPONSE_FIRST_GREETING',  'TXT_KEY_LEADER_VEGETA_FIRSTGREETING_%'),
        ('LEADER_VEGETA', 'RESPONSE_DEFEATED',        'TXT_KEY_LEADER_VEGETA_DEFEATED_%');
