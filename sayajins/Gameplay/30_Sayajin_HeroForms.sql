-- =====================================================
-- Sayajin Hero Era Forms
-- Runtime-only unit variants used by Lua when each hero
-- advances to a new era. Each family keeps its own animated
-- character model while its name, strengths and abilities evolve.
-- =====================================================

DROP TABLE IF EXISTS SayajinHeroForms;

CREATE TEMP TABLE SayajinHeroForms
(
    BaseUnitType    TEXT NOT NULL,
    NewUnitType     TEXT NOT NULL,
    DescriptionKey  TEXT NOT NULL
);

INSERT INTO SayajinHeroForms
        (BaseUnitType, NewUnitType, DescriptionKey)
VALUES
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_CLASSICAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_CLASSICAL'),
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_MEDIEVAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_MEDIEVAL'),
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_RENAISSANCE', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_RENAISSANCE'),
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_INDUSTRIAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_INDUSTRIAL'),
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_MODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_MODERN'),
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_POSTMODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_POSTMODERN'),
        ('UNIT_SAYAJIN_HERO', 'UNIT_SAYAJIN_HERO_VEGETA_FUTURE', 'TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_FUTURE'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_CLASSICAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_CLASSICAL'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_MEDIEVAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_MEDIEVAL'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_RENAISSANCE', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_RENAISSANCE'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_INDUSTRIAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_INDUSTRIAL'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_MODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_MODERN'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_POSTMODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_POSTMODERN'),
        ('UNIT_SAYAJIN_HERO_GOKU', 'UNIT_SAYAJIN_HERO_GOKU_FUTURE', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_FUTURE'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_CLASSICAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_CLASSICAL'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_MEDIEVAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_MEDIEVAL'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_RENAISSANCE', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_RENAISSANCE'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_INDUSTRIAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_INDUSTRIAL'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_MODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_MODERN'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_POSTMODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_POSTMODERN'),
        ('UNIT_SAYAJIN_HERO_PICCOLO', 'UNIT_SAYAJIN_HERO_PICCOLO_FUTURE', 'TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_FUTURE'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_CLASSICAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_CLASSICAL'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_MEDIEVAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_MEDIEVAL'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_RENAISSANCE', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_RENAISSANCE'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_INDUSTRIAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_INDUSTRIAL'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_MODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_MODERN'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_POSTMODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_POSTMODERN'),
        ('UNIT_SAYAJIN_HERO_GOHAN', 'UNIT_SAYAJIN_HERO_GOHAN_FUTURE', 'TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_FUTURE'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_CLASSICAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_CLASSICAL'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_MEDIEVAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_MEDIEVAL'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_RENAISSANCE', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_RENAISSANCE'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_INDUSTRIAL', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_INDUSTRIAL'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_MODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_MODERN'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_POSTMODERN', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_POSTMODERN'),
        ('UNIT_SAYAJIN_HERO_BROWLY', 'UNIT_SAYAJIN_HERO_BROWLY_FUTURE', 'TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_FUTURE');

-- Copy the complete practical unit definition from the trainable root.
-- Runtime forms are intentionally non-trainable: Cost = -1,
-- PrereqTech = NULL and ShowInPedia = 0. They exist only for
-- Lua era transformations and must never appear in city production.
INSERT INTO Units
        (Type, Description, Civilopedia, Help,
         Combat, Cost, Moves, BaseSightRange,
         Class, CombatClass, Domain, DefaultUnitAI,
         MilitarySupport, MilitaryProduction, Pillage, PrereqTech,
         ObsoleteTech, GoodyHutUpgradeUnitClass, HurryCostModifier, AdvancedStartCost,
         XPValueAttack, XPValueDefense, Conscription, UnitArtInfo,
         UnitArtInfoCulturalVariation, UnitArtInfoEraVariation,
         MoveRate, PortraitIndex, IconAtlas, UnitFlagAtlas, UnitFlagIconOffset,
         ShowInPedia, RangedCombat, Range, MinAreaSize)
SELECT  f.NewUnitType, f.DescriptionKey, u.Civilopedia, u.Help,
        u.Combat, -1, u.Moves, u.BaseSightRange,
        u.Class, u.CombatClass, u.Domain, u.DefaultUnitAI,
        u.MilitarySupport, u.MilitaryProduction, u.Pillage, NULL,
        NULL, NULL, -1, -1,
        u.XPValueAttack, u.XPValueDefense, u.Conscription, u.UnitArtInfo,
        u.UnitArtInfoCulturalVariation, u.UnitArtInfoEraVariation,
        u.MoveRate, u.PortraitIndex, u.IconAtlas, u.UnitFlagAtlas, u.UnitFlagIconOffset,
        0, u.RangedCombat, u.Range, u.MinAreaSize
FROM Units u
JOIN SayajinHeroForms f ON f.BaseUnitType = u.Type;

-- Copy AI behavior, free promotions, AI flavoring and selection sounds.
INSERT INTO Unit_AITypes
        (UnitType, UnitAIType)
SELECT  f.NewUnitType, a.UnitAIType
FROM SayajinHeroForms f
JOIN Unit_AITypes a ON a.UnitType = f.BaseUnitType;

INSERT INTO Unit_FreePromotions
        (UnitType, PromotionType)
SELECT  f.NewUnitType, p.PromotionType
FROM SayajinHeroForms f
JOIN Unit_FreePromotions p ON p.UnitType = f.BaseUnitType;

INSERT INTO Unit_Flavors
        (UnitType, FlavorType, Flavor)
SELECT  f.NewUnitType, fl.FlavorType, fl.Flavor
FROM SayajinHeroForms f
JOIN Unit_Flavors fl ON fl.UnitType = f.BaseUnitType;

INSERT INTO UnitGameplay2DScripts
        (UnitType, SelectionSound, FirstSelectionSound)
SELECT  f.NewUnitType, s.SelectionSound, s.FirstSelectionSound
FROM SayajinHeroForms f
JOIN UnitGameplay2DScripts s ON s.UnitType = f.BaseUnitType;
