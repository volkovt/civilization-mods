-- =====================================================
-- Sayajin Heroes
-- Five trainable hero roots + visible era promotions.
-- Runtime scaling and era transformations are handled in Lua.
-- =====================================================

-- -----------------------------------------------------
-- Hero icon atlases
-- Each hero uses an original portrait atlas generated for this project.
-- -----------------------------------------------------
INSERT INTO IconTextureAtlases
        (Atlas,                             IconSize, Filename,                  IconsPerRow, IconsPerColumn)
VALUES  ('SAYAJIN_HERO_VEGETA_ATLAS',       256,      'SayajinHeroVegeta_256.dds', 1,           1),
        ('SAYAJIN_HERO_VEGETA_ATLAS',       128,      'SayajinHeroVegeta_128.dds', 1,           1),
        ('SAYAJIN_HERO_VEGETA_ATLAS',       80,       'SayajinHeroVegeta_80.dds',  1,           1),
        ('SAYAJIN_HERO_VEGETA_ATLAS',       64,       'SayajinHeroVegeta_64.dds',  1,           1),
        ('SAYAJIN_HERO_VEGETA_ATLAS',       45,       'SayajinHeroVegeta_45.dds',  1,           1),
        ('SAYAJIN_HERO_VEGETA_ATLAS',       32,       'SayajinHeroVegeta_32.dds',  1,           1),
        ('SAYAJIN_HERO_GOKU_ATLAS',         256,      'SayajinHeroGoku_256.dds', 1,           1),
        ('SAYAJIN_HERO_GOKU_ATLAS',         128,      'SayajinHeroGoku_128.dds', 1,           1),
        ('SAYAJIN_HERO_GOKU_ATLAS',         80,       'SayajinHeroGoku_80.dds',  1,           1),
        ('SAYAJIN_HERO_GOKU_ATLAS',         64,       'SayajinHeroGoku_64.dds',  1,           1),
        ('SAYAJIN_HERO_GOKU_ATLAS',         45,       'SayajinHeroGoku_45.dds',  1,           1),
        ('SAYAJIN_HERO_GOKU_ATLAS',         32,       'SayajinHeroGoku_32.dds',  1,           1),
        ('SAYAJIN_HERO_PICCOLO_ATLAS',      256,      'SayajinHeroPiccolo_256.dds', 1,           1),
        ('SAYAJIN_HERO_PICCOLO_ATLAS',      128,      'SayajinHeroPiccolo_128.dds', 1,           1),
        ('SAYAJIN_HERO_PICCOLO_ATLAS',      80,       'SayajinHeroPiccolo_80.dds',  1,           1),
        ('SAYAJIN_HERO_PICCOLO_ATLAS',      64,       'SayajinHeroPiccolo_64.dds',  1,           1),
        ('SAYAJIN_HERO_PICCOLO_ATLAS',      45,       'SayajinHeroPiccolo_45.dds',  1,           1),
        ('SAYAJIN_HERO_PICCOLO_ATLAS',      32,       'SayajinHeroPiccolo_32.dds',  1,           1),
        ('SAYAJIN_HERO_GOHAN_ATLAS',        256,      'SayajinHeroGohan_256.dds', 1,           1),
        ('SAYAJIN_HERO_GOHAN_ATLAS',        128,      'SayajinHeroGohan_128.dds', 1,           1),
        ('SAYAJIN_HERO_GOHAN_ATLAS',        80,       'SayajinHeroGohan_80.dds',  1,           1),
        ('SAYAJIN_HERO_GOHAN_ATLAS',        64,       'SayajinHeroGohan_64.dds',  1,           1),
        ('SAYAJIN_HERO_GOHAN_ATLAS',        45,       'SayajinHeroGohan_45.dds',  1,           1),
        ('SAYAJIN_HERO_GOHAN_ATLAS',        32,       'SayajinHeroGohan_32.dds',  1,           1),
        ('SAYAJIN_HERO_BROWLY_ATLAS',       256,      'SayajinHeroBroly_256.dds', 1,           1),
        ('SAYAJIN_HERO_BROWLY_ATLAS',       128,      'SayajinHeroBroly_128.dds', 1,           1),
        ('SAYAJIN_HERO_BROWLY_ATLAS',       80,       'SayajinHeroBroly_80.dds',  1,           1),
        ('SAYAJIN_HERO_BROWLY_ATLAS',       64,       'SayajinHeroBroly_64.dds',  1,           1),
        ('SAYAJIN_HERO_BROWLY_ATLAS',       45,       'SayajinHeroBroly_45.dds',  1,           1),
        ('SAYAJIN_HERO_BROWLY_ATLAS',       32,       'SayajinHeroBroly_32.dds',  1,           1),
        ('SAYAJIN_HERO_FLAG_ATLAS',         32,       'SayajinHero_32.dds',  1,           1);

-- -----------------------------------------------------
-- Hidden marker promotion for all heroes
-- -----------------------------------------------------
INSERT INTO UnitPromotions
        (Type,                           Description,                          Help,                                    Sound,
         CannotBeChosen,                 PortraitIndex,                        IconAtlas,                               PediaType, PediaEntry)
VALUES  ('PROMOTION_SAYAJIN_HERO_MARK',  'TXT_KEY_PROMOTION_SAYAJIN_HERO_MARK','TXT_KEY_PROMOTION_SAYAJIN_HERO_MARK_HELP','AS2D_IF_LEVELUP',
         1,                              59,                                   'PROMOTION_ATLAS',                       'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_HERO_MARK');

-- -----------------------------------------------------
-- Era promotions
-- Real hero scaling is performed by Lua by changing base
-- combat/ranged strength during era sync. Promotions also keep
-- the current form clearly visible in the unit interface.
-- -----------------------------------------------------
INSERT INTO UnitPromotions
        (Type,                                   Description,                                   Help,                                            Sound,
         CannotBeChosen,                         PortraitIndex,                                 IconAtlas,                                       PediaType, PediaEntry,
         CombatPercent,                          RangedAttackModifier)
VALUES  ('PROMOTION_SAYAJIN_ERA_ANCIENT',        'TXT_KEY_PROMOTION_SAYAJIN_ERA_ANCIENT',      'TXT_KEY_PROMOTION_SAYAJIN_ERA_ANCIENT_HELP',     'AS2D_IF_LEVELUP',
         1,                                      0,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_ANCIENT',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_CLASSICAL',      'TXT_KEY_PROMOTION_SAYAJIN_ERA_CLASSICAL',    'TXT_KEY_PROMOTION_SAYAJIN_ERA_CLASSICAL_HELP',   'AS2D_IF_LEVELUP',
         1,                                      1,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_CLASSICAL',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_MEDIEVAL',       'TXT_KEY_PROMOTION_SAYAJIN_ERA_MEDIEVAL',     'TXT_KEY_PROMOTION_SAYAJIN_ERA_MEDIEVAL_HELP',    'AS2D_IF_LEVELUP',
         1,                                      2,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_MEDIEVAL',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_RENAISSANCE',    'TXT_KEY_PROMOTION_SAYAJIN_ERA_RENAISSANCE',  'TXT_KEY_PROMOTION_SAYAJIN_ERA_RENAISSANCE_HELP', 'AS2D_IF_LEVELUP',
         1,                                      3,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_RENAISSANCE',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_INDUSTRIAL',     'TXT_KEY_PROMOTION_SAYAJIN_ERA_INDUSTRIAL',   'TXT_KEY_PROMOTION_SAYAJIN_ERA_INDUSTRIAL_HELP',  'AS2D_IF_LEVELUP',
         1,                                      4,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_INDUSTRIAL',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_MODERN',         'TXT_KEY_PROMOTION_SAYAJIN_ERA_MODERN',       'TXT_KEY_PROMOTION_SAYAJIN_ERA_MODERN_HELP',      'AS2D_IF_LEVELUP',
         1,                                      5,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_MODERN',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_POSTMODERN',     'TXT_KEY_PROMOTION_SAYAJIN_ERA_POSTMODERN',   'TXT_KEY_PROMOTION_SAYAJIN_ERA_POSTMODERN_HELP',  'AS2D_IF_LEVELUP',
         1,                                      6,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_POSTMODERN',
         0,                                      0),
        ('PROMOTION_SAYAJIN_ERA_FUTURE',         'TXT_KEY_PROMOTION_SAYAJIN_ERA_FUTURE',       'TXT_KEY_PROMOTION_SAYAJIN_ERA_FUTURE_HELP',      'AS2D_IF_LEVELUP',
         1,                                      7,                                             'PROMOTION_ATLAS',                                'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ERA_FUTURE',
         0,                                      0);

-- -----------------------------------------------------
-- Hero classes
-- IMPORTANT: DefaultUnit is intentionally NULL. If a custom
-- UnitClass has a DefaultUnit, Civilization V can expose that
-- unit to every civilization. The Sayajin civilization receives
-- the trainable root unit through Civilization_UnitClassOverrides
-- below, while all non-Sayajin civilizations receive no unit for
-- these classes.
-- -----------------------------------------------------
INSERT INTO UnitClasses
        (Type,                              Description,                          DefaultUnit, MaxPlayerInstances)
VALUES  ('UNITCLASS_SAYAJIN_HERO',          'TXT_KEY_UNIT_SAYAJIN_HERO',         NULL,        1),
        ('UNITCLASS_SAYAJIN_HERO_GOKU',     'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU',    NULL,        1),
        ('UNITCLASS_SAYAJIN_HERO_PICCOLO',  'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO', NULL,        1),
        ('UNITCLASS_SAYAJIN_HERO_GOHAN',    'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN',   NULL,        1),
        ('UNITCLASS_SAYAJIN_HERO_BROWLY',   'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY',  NULL,        1);

-- -----------------------------------------------------
-- Trainable hero roots
-- -----------------------------------------------------
INSERT INTO Units
        (Type,                      Description,                       Civilopedia,                            Help,
         Combat,                    Cost,                              Moves,                                  BaseSightRange,
         Class,                     CombatClass,                       Domain,                                 DefaultUnitAI,
         MilitarySupport,           MilitaryProduction,                Pillage,                                PrereqTech,
         ObsoleteTech,              GoodyHutUpgradeUnitClass,          HurryCostModifier,                      AdvancedStartCost,
         XPValueAttack,             XPValueDefense,                    Conscription,                           UnitArtInfo,
         UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
         MoveRate,                  PortraitIndex,                     IconAtlas,                              UnitFlagAtlas,              UnitFlagIconOffset,
         ShowInPedia)
VALUES  ('UNIT_SAYAJIN_HERO',       'TXT_KEY_UNIT_SAYAJIN_HERO',       'TXT_KEY_UNIT_SAYAJIN_HERO_PEDIA',      'TXT_KEY_UNIT_SAYAJIN_HERO_HELP',
         14,                        75,                                6,                                      2,
         'UNITCLASS_SAYAJIN_HERO',  'UNITCOMBAT_MELEE',                'DOMAIN_LAND',                          'UNITAI_ATTACK',
         1,                         1,                                 1,                                      'TECH_BRONZE_WORKING',
         NULL,                      NULL,                              0,                                      75,
         3,                         3,                                 1,                                      'ART_DEF_UNIT_WARRIOR',
         1,                         0,
         'BIPED',                   0,                                 'SAYAJIN_HERO_VEGETA_ATLAS',            'SAYAJIN_HERO_FLAG_ATLAS',  0,
         1),
        ('UNIT_SAYAJIN_HERO_GOKU',      'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU',      'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_PEDIA',      'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_HELP',
         10,                             90,                                   3,                                           4,
         'UNITCLASS_SAYAJIN_HERO_GOKU',  'UNITCOMBAT_ARCHER',                  'DOMAIN_LAND',                               'UNITAI_RANGED',
         1,                              1,                                    1,                                           'TECH_BRONZE_WORKING',
         NULL,                           NULL,                                 0,                                           90,
         3,                              3,                                    1,                                           'ART_DEF_UNIT_ARCHER',
         1,                              0,
         'BIPED',                        0,                                    'SAYAJIN_HERO_GOKU_ATLAS',                   'SAYAJIN_HERO_FLAG_ATLAS',  0,
         1),
        ('UNIT_SAYAJIN_HERO_PICCOLO',   'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO',   'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_PEDIA',   'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_HELP',
         14,                             110,                                  6,                                           5,
         'UNITCLASS_SAYAJIN_HERO_PICCOLO','UNITCOMBAT_NAVALRANGED',            'DOMAIN_SEA',                                'UNITAI_ASSAULT_SEA',
         1,                              1,                                    1,                                           'TECH_BRONZE_WORKING',
         NULL,                           NULL,                                 0,                                           110,
         3,                              3,                                    1,                                           'ART_DEF_UNIT_GALLEASS',
         1,                              0,
         'BOAT',                         0,                                    'SAYAJIN_HERO_PICCOLO_ATLAS',                'SAYAJIN_HERO_FLAG_ATLAS',  0,
         1),
        ('UNIT_SAYAJIN_HERO_GOHAN',     'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN',     'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_PEDIA',     'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_HELP',
         12,                             95,                                   5,                                           2,
         'UNITCLASS_SAYAJIN_HERO_GOHAN', 'UNITCOMBAT_ARCHER',                  'DOMAIN_LAND',                               'UNITAI_RANGED',
         1,                              1,                                    1,                                           'TECH_BRONZE_WORKING',
         NULL,                           NULL,                                 0,                                           95,
         3,                              3,                                    1,                                           'ART_DEF_UNIT_ARCHER',
         1,                              0,
         'BIPED',                        0,                                    'SAYAJIN_HERO_GOHAN_ATLAS',                  'SAYAJIN_HERO_FLAG_ATLAS',  0,
         1),
        ('UNIT_SAYAJIN_HERO_BROWLY',    'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY',    'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_PEDIA',    'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_HELP',
         18,                             125,                                  7,                                           3,
         'UNITCLASS_SAYAJIN_HERO_BROWLY','UNITCOMBAT_NAVALMELEE',              'DOMAIN_SEA',                                'UNITAI_ATTACK_SEA',
         1,                              1,                                    1,                                           'TECH_BRONZE_WORKING',
         NULL,                           NULL,                                 0,                                           125,
         3,                              3,                                    1,                                           'ART_DEF_UNIT_TRIREME',
         1,                              0,
         'BOAT',                         0,                                    'SAYAJIN_HERO_BROWLY_ATLAS',                 'SAYAJIN_HERO_FLAG_ATLAS',  0,
         1);

-- -----------------------------------------------------
-- Hero ranged stats and naval setup
-- -----------------------------------------------------
UPDATE Units
SET RangedCombat = 16,
    Range = 3
WHERE Type = 'UNIT_SAYAJIN_HERO_GOKU';

UPDATE Units
SET RangedCombat = 20,
    Range = 4,
    MinAreaSize = 1
WHERE Type = 'UNIT_SAYAJIN_HERO_PICCOLO';

UPDATE Units
SET RangedCombat = 19,
    Range = 2
WHERE Type = 'UNIT_SAYAJIN_HERO_GOHAN';

UPDATE Units
SET MinAreaSize = 1
WHERE Type = 'UNIT_SAYAJIN_HERO_BROWLY';

-- -----------------------------------------------------
-- Hero AI types
-- -----------------------------------------------------
INSERT INTO Unit_AITypes
        (UnitType,                    UnitAIType)
VALUES  ('UNIT_SAYAJIN_HERO',         'UNITAI_ATTACK'),
        ('UNIT_SAYAJIN_HERO',         'UNITAI_DEFENSE'),
        ('UNIT_SAYAJIN_HERO',         'UNITAI_COUNTER'),
        ('UNIT_SAYAJIN_HERO_GOKU',    'UNITAI_RANGED'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNITAI_ASSAULT_SEA'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNITAI_RESERVE_SEA'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNITAI_ESCORT_SEA'),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'UNITAI_RANGED'),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'UNITAI_ATTACK_SEA'),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'UNITAI_RESERVE_SEA'),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'UNITAI_ESCORT_SEA');

-- -----------------------------------------------------
-- Hero free promotions
-- Ranged heroes receive PROMOTION_INDIRECT_FIRE so they can
-- attack without direct line of sight over terrain obstacles.
-- -----------------------------------------------------
INSERT INTO Unit_FreePromotions
        (UnitType,                    PromotionType)
VALUES  ('UNIT_SAYAJIN_HERO',         'PROMOTION_SHOCK_1'),
        ('UNIT_SAYAJIN_HERO',         'PROMOTION_MORALE'),
        ('UNIT_SAYAJIN_HERO',         'PROMOTION_SAYAJIN_HERO_MARK'),
        ('UNIT_SAYAJIN_HERO',         'PROMOTION_SAYAJIN_ERA_ANCIENT'),
        ('UNIT_SAYAJIN_HERO_GOKU',    'PROMOTION_MORALE'),
        ('UNIT_SAYAJIN_HERO_GOKU',    'PROMOTION_INDIRECT_FIRE'),
        ('UNIT_SAYAJIN_HERO_GOKU',    'PROMOTION_SAYAJIN_HERO_MARK'),
        ('UNIT_SAYAJIN_HERO_GOKU',    'PROMOTION_SAYAJIN_ERA_ANCIENT'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'PROMOTION_MORALE'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'PROMOTION_INDIRECT_FIRE'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'PROMOTION_SAYAJIN_HERO_MARK'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'PROMOTION_SAYAJIN_ERA_ANCIENT'),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'PROMOTION_INDIRECT_FIRE'),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'PROMOTION_MORALE'),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'PROMOTION_SAYAJIN_HERO_MARK'),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'PROMOTION_SAYAJIN_ERA_ANCIENT'),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'PROMOTION_MORALE'),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'PROMOTION_SAYAJIN_HERO_MARK'),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'PROMOTION_SAYAJIN_ERA_ANCIENT');

-- -----------------------------------------------------
-- Hero flavors
-- -----------------------------------------------------
INSERT INTO Unit_Flavors
        (UnitType,                    FlavorType,                  Flavor)
VALUES  ('UNIT_SAYAJIN_HERO',         'FLAVOR_OFFENSE',            12),
        ('UNIT_SAYAJIN_HERO',         'FLAVOR_DEFENSE',            8),
        ('UNIT_SAYAJIN_HERO',         'FLAVOR_MILITARY_TRAINING',  12),
        ('UNIT_SAYAJIN_HERO',         'FLAVOR_RECON',              6),
        ('UNIT_SAYAJIN_HERO_GOKU',    'FLAVOR_OFFENSE',            10),
        ('UNIT_SAYAJIN_HERO_GOKU',    'FLAVOR_RANGED',             14),
        ('UNIT_SAYAJIN_HERO_GOKU',    'FLAVOR_MILITARY_TRAINING',  12),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'FLAVOR_OFFENSE',            10),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'FLAVOR_NAVAL',              14),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'FLAVOR_RECON',              8),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'FLAVOR_OFFENSE',            11),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'FLAVOR_RANGED',             14),
        ('UNIT_SAYAJIN_HERO_GOHAN',   'FLAVOR_MILITARY_TRAINING',  11),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'FLAVOR_OFFENSE',            14),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'FLAVOR_NAVAL',              13),
        ('UNIT_SAYAJIN_HERO_BROWLY',  'FLAVOR_DEFENSE',            6);

-- -----------------------------------------------------
-- Civ override records: only trainable root units are exposed.
-- Era forms are runtime-only transformation units.
-- -----------------------------------------------------
INSERT INTO Civilization_UnitClassOverrides
        (CivilizationType,        UnitClassType,                      UnitType)
VALUES  ('CIVILIZATION_SAYAJIN',  'UNITCLASS_SAYAJIN_HERO',           'UNIT_SAYAJIN_HERO'),
        ('CIVILIZATION_SAYAJIN',  'UNITCLASS_SAYAJIN_HERO_GOKU',      'UNIT_SAYAJIN_HERO_GOKU'),
        ('CIVILIZATION_SAYAJIN',  'UNITCLASS_SAYAJIN_HERO_PICCOLO',   'UNIT_SAYAJIN_HERO_PICCOLO'),
        ('CIVILIZATION_SAYAJIN',  'UNITCLASS_SAYAJIN_HERO_GOHAN',     'UNIT_SAYAJIN_HERO_GOHAN'),
        ('CIVILIZATION_SAYAJIN',  'UNITCLASS_SAYAJIN_HERO_BROWLY',    'UNIT_SAYAJIN_HERO_BROWLY');

-- -----------------------------------------------------
-- Selection sounds
-- -----------------------------------------------------
INSERT INTO UnitGameplay2DScripts
        (UnitType,                    SelectionSound,       FirstSelectionSound)
SELECT  'UNIT_SAYAJIN_HERO',          SelectionSound,       FirstSelectionSound
FROM UnitGameplay2DScripts
WHERE UnitType = 'UNIT_WARRIOR';

INSERT INTO UnitGameplay2DScripts
        (UnitType,                    SelectionSound,       FirstSelectionSound)
SELECT  'UNIT_SAYAJIN_HERO_GOKU',     SelectionSound,       FirstSelectionSound
FROM UnitGameplay2DScripts
WHERE UnitType = 'UNIT_ARCHER';

INSERT INTO UnitGameplay2DScripts
        (UnitType,                    SelectionSound,       FirstSelectionSound)
SELECT  'UNIT_SAYAJIN_HERO_PICCOLO',  SelectionSound,       FirstSelectionSound
FROM UnitGameplay2DScripts
WHERE UnitType = 'UNIT_GALLEASS';

INSERT INTO UnitGameplay2DScripts
        (UnitType,                    SelectionSound,       FirstSelectionSound)
SELECT  'UNIT_SAYAJIN_HERO_GOHAN',    SelectionSound,       FirstSelectionSound
FROM UnitGameplay2DScripts
WHERE UnitType = 'UNIT_ARCHER';

INSERT INTO UnitGameplay2DScripts
        (UnitType,                    SelectionSound,       FirstSelectionSound)
SELECT  'UNIT_SAYAJIN_HERO_BROWLY',   SelectionSound,       FirstSelectionSound
FROM UnitGameplay2DScripts
WHERE UnitType = 'UNIT_TRIREME';
