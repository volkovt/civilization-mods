-- ==========================================================================
-- SAYAJINS: original animated unit art
-- One visible member per hero keeps the characters readable at Civ V scale.
-- ==========================================================================

INSERT INTO ArtDefine_UnitInfos
        (Type,                           DamageStates, Formation,  UnitFlagAtlas,          UnitFlagIconOffset, IconAtlas,                     PortraitIndex)
VALUES  ('ART_DEF_UNIT_SAYAJIN_VEGETA', 1,            'UnFormed', 'SAYAJIN_HERO_FLAG_ATLAS', 0,              'SAYAJIN_HERO_VEGETA_ATLAS', 0),
        ('ART_DEF_UNIT_SAYAJIN_GOKU',    1,            'UnFormed', 'SAYAJIN_HERO_FLAG_ATLAS', 0,              'SAYAJIN_HERO_GOKU_ATLAS',    0),
        ('ART_DEF_UNIT_SAYAJIN_GOHAN',   1,            'UnFormed', 'SAYAJIN_HERO_FLAG_ATLAS', 0,              'SAYAJIN_HERO_GOHAN_ATLAS',   0),
        ('ART_DEF_UNIT_SAYAJIN_PICCOLO', 1,            'UnFormed', 'SAYAJIN_HERO_FLAG_ATLAS', 0,              'SAYAJIN_HERO_PICCOLO_ATLAS', 0),
        ('ART_DEF_UNIT_SAYAJIN_BROLY',   1,            'UnFormed', 'SAYAJIN_HERO_FLAG_ATLAS', 0,              'SAYAJIN_HERO_BROWLY_ATLAS',  0);

INSERT INTO ArtDefine_UnitInfoMemberInfos
        (UnitInfoType,                    UnitMemberInfoType,                    NumMembers)
VALUES  ('ART_DEF_UNIT_SAYAJIN_VEGETA',  'ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA',  1),
        ('ART_DEF_UNIT_SAYAJIN_GOKU',     'ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU',    1),
        ('ART_DEF_UNIT_SAYAJIN_GOHAN',    'ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN',   1),
        ('ART_DEF_UNIT_SAYAJIN_PICCOLO',  'ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO', 1),
        ('ART_DEF_UNIT_SAYAJIN_BROLY',    'ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY',   1);

INSERT INTO ArtDefine_UnitMemberInfos
        (Type,                                     Scale, ZOffset, Domain, Model,                                           MaterialTypeTag, MaterialTypeSoundOverrideTag)
VALUES  ('ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA',     0.14,  0,       '',     'Sayajin_Vegeta.fxsxml',         'CLOTH',         'FLESH'),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU',       0.14,  0,       '',     'Sayajin_Goku.fxsxml',           'CLOTH',         'FLESH'),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN',      0.14,  0,       '',     'Sayajin_Gohan.fxsxml',          'CLOTH',         'FLESH'),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO',    0.135, 0,       '',     'Sayajin_Piccolo.fxsxml',        'CLOTH',         'FLESH'),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY',      0.13,  0,       '',     'Sayajin_Broly.fxsxml',          'CLOTH',         'FLESH');

INSERT INTO ArtDefine_UnitMemberCombats
        (UnitMemberType, EnableActions, DisableActions,
         MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, ShortMoveRate,
         LOSRadiusScale, TargetRadius, TargetHeight,
         HasShortRangedAttack, HasLongRangedAttack, HasStationaryMelee, HasStationaryRangedAttack,
         HasRefaceAfterCombat, ReformBeforeCombat, RushAttackFormation)
VALUES  ('ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA',  'Idle Attack Death Run Fortify CombatReady', '',
         5, 12, 18, 32, 32, 0.35, 1, 12, 10, 0, 0, 1, 0, 1, 1, ''),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU',     'Idle Attack Death Run Fortify CombatReady', '',
         5, 12, 18, 32, 72, 0.35, 1, 12, 10, 1, 1, 1, 1, 1, 1, ''),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN',    'Idle Attack Death Run Fortify CombatReady', '',
         5, 12, 18, 32, 72, 0.35, 1, 12, 10, 1, 1, 1, 1, 1, 1, ''),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO',  'Idle Attack Death Run Fortify CombatReady', '',
         5, 12, 18, 32, 72, 0.35, 1, 12, 10, 1, 1, 1, 1, 1, 1, ''),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY',    'Idle Attack Death Run Fortify CombatReady', '',
         5, 12, 18, 32, 32, 0.35, 1, 12, 10, 0, 0, 1, 0, 1, 1, '');

-- Infantry's timed attack trigger always dispatches weapon slot 0. Every hero
-- therefore uses the Giant Death Robot railgun trail as a clean ki/laser beam;
-- melee gameplay roles remain unchanged because this is an art-only profile.
INSERT INTO ArtDefine_UnitMemberCombatWeapons
        (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax,
         ProjectileSpeed, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale,
         AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped,
         WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius)
VALUES  ('ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA', 0, 0, 'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ', 10, 20, 5.3, '', 1.35, 20, 1.35, 0.12, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU', 0, 0, 'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ', 10, 20, 5.3, '', 1.55, 22, 1.55, 0.15, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN', 0, 0, 'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ', 10, 20, 5.3, '', 1.25, 18, 1.25, 0.10, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO', 0, 0, 'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ', 10, 20, 5.3, '', 1.45, 20, 1.45, 0.12, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY', 0, 0, 'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ', 10, 20, 5.3, '', 1.65, 24, 1.65, 0.15, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10);

UPDATE Units SET UnitArtInfo = 'ART_DEF_UNIT_SAYAJIN_VEGETA',
                 UnitArtInfoCulturalVariation = 0,
                 UnitArtInfoEraVariation = 0
WHERE Type = 'UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_VEGETA_%';

UPDATE Units SET UnitArtInfo = 'ART_DEF_UNIT_SAYAJIN_GOKU',
                 UnitArtInfoCulturalVariation = 0,
                 UnitArtInfoEraVariation = 0
WHERE Type = 'UNIT_SAYAJIN_HERO_GOKU' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOKU_%';

UPDATE Units SET UnitArtInfo = 'ART_DEF_UNIT_SAYAJIN_GOHAN',
                 UnitArtInfoCulturalVariation = 0,
                 UnitArtInfoEraVariation = 0
WHERE Type = 'UNIT_SAYAJIN_HERO_GOHAN' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOHAN_%';

UPDATE Units SET UnitArtInfo = 'ART_DEF_UNIT_SAYAJIN_PICCOLO',
                 UnitArtInfoCulturalVariation = 0,
                 UnitArtInfoEraVariation = 0
WHERE Type = 'UNIT_SAYAJIN_HERO_PICCOLO' OR Type LIKE 'UNIT_SAYAJIN_HERO_PICCOLO_%';

UPDATE Units SET UnitArtInfo = 'ART_DEF_UNIT_SAYAJIN_BROLY',
                 UnitArtInfoCulturalVariation = 0,
                 UnitArtInfoEraVariation = 0
WHERE Type = 'UNIT_SAYAJIN_HERO_BROWLY' OR Type LIKE 'UNIT_SAYAJIN_HERO_BROWLY_%';

-- ======================================================================
-- Transformation art profiles
-- Every runtime form receives its own model/material so hair geometry and
-- colour evolve with the named transformation. Piccolo deliberately keeps
-- the same hairless model, but still gets per-form combat VFX definitions.
-- ======================================================================

DROP TABLE IF EXISTS SayajinArtHeroes;
DROP TABLE IF EXISTS SayajinArtForms;

CREATE TEMP TABLE SayajinArtHeroes
(
    ArtKey      TEXT NOT NULL,
    UnitStem    TEXT NOT NULL,
    ModelStem   TEXT NOT NULL,
    Scale       REAL NOT NULL,
    IsRanged    INTEGER NOT NULL,
    IconAtlas   TEXT NOT NULL
);

CREATE TEMP TABLE SayajinArtForms
(
    FormKey TEXT NOT NULL
);

INSERT INTO SayajinArtHeroes
        (ArtKey, UnitStem, ModelStem, Scale, IsRanged, IconAtlas)
VALUES  ('VEGETA', 'UNIT_SAYAJIN_HERO_VEGETA', 'Vegeta', 0.14,  0, 'SAYAJIN_HERO_VEGETA_ATLAS'),
        ('GOKU',   'UNIT_SAYAJIN_HERO_GOKU',    'Goku',   0.14,  1, 'SAYAJIN_HERO_GOKU_ATLAS'),
        ('GOHAN',  'UNIT_SAYAJIN_HERO_GOHAN',   'Gohan',  0.14,  1, 'SAYAJIN_HERO_GOHAN_ATLAS'),
        ('PICCOLO','UNIT_SAYAJIN_HERO_PICCOLO', 'Piccolo',0.135, 1, 'SAYAJIN_HERO_PICCOLO_ATLAS'),
        ('BROLY',  'UNIT_SAYAJIN_HERO_BROWLY',  'Broly',  0.13,  0, 'SAYAJIN_HERO_BROWLY_ATLAS');

INSERT INTO SayajinArtForms
        (FormKey)
VALUES  ('CLASSICAL'), ('MEDIEVAL'), ('RENAISSANCE'), ('INDUSTRIAL'),
        ('MODERN'), ('POSTMODERN'), ('FUTURE');

INSERT INTO ArtDefine_UnitInfos
        (Type, DamageStates, Formation, UnitFlagAtlas, UnitFlagIconOffset, IconAtlas, PortraitIndex)
SELECT  'ART_DEF_UNIT_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        1, 'UnFormed', 'SAYAJIN_HERO_FLAG_ATLAS', 0, h.IconAtlas, 0
FROM SayajinArtHeroes h
CROSS JOIN SayajinArtForms f;

INSERT INTO ArtDefine_UnitInfoMemberInfos
        (UnitInfoType, UnitMemberInfoType, NumMembers)
SELECT  'ART_DEF_UNIT_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        'ART_DEF_UNIT_MEMBER_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        1
FROM SayajinArtHeroes h
CROSS JOIN SayajinArtForms f;

INSERT INTO ArtDefine_UnitMemberInfos
        (Type, Scale, ZOffset, Domain, Model, MaterialTypeTag, MaterialTypeSoundOverrideTag)
SELECT  'ART_DEF_UNIT_MEMBER_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        h.Scale, 0, '',
        CASE WHEN h.ArtKey = 'PICCOLO' AND f.FormKey = 'POSTMODERN'
             THEN 'Sayajin_Piccolo_PostModern.fxsxml'
             WHEN h.ArtKey = 'PICCOLO' AND f.FormKey = 'FUTURE'
             THEN 'Sayajin_Piccolo_Future.fxsxml'
             WHEN h.ArtKey = 'PICCOLO'
             THEN 'Sayajin_Piccolo.fxsxml'
             ELSE 'Sayajin_' || h.ModelStem || '_' ||
                  CASE f.FormKey
                      WHEN 'POSTMODERN' THEN 'PostModern'
                      ELSE UPPER(SUBSTR(f.FormKey, 1, 1)) || LOWER(SUBSTR(f.FormKey, 2))
                  END || '.fxsxml'
        END,
        'CLOTH', 'FLESH'
FROM SayajinArtHeroes h
CROSS JOIN SayajinArtForms f;

INSERT INTO ArtDefine_UnitMemberCombats
        (UnitMemberType, EnableActions, DisableActions,
         MoveRadius, ShortMoveRadius, ChargeRadius, AttackRadius, RangedAttackRadius, ShortMoveRate,
         LOSRadiusScale, TargetRadius, TargetHeight,
         HasShortRangedAttack, HasLongRangedAttack, HasStationaryMelee, HasStationaryRangedAttack,
         HasRefaceAfterCombat, ReformBeforeCombat, RushAttackFormation)
SELECT  'ART_DEF_UNIT_MEMBER_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        'Idle Attack Death Run Fortify CombatReady', '',
        5, 12, 18, 32, CASE WHEN h.IsRanged = 1 THEN 72 ELSE 32 END, 0.35,
        1, 12, 10,
        h.IsRanged, h.IsRanged, 1, h.IsRanged,
        1, 1, ''
FROM SayajinArtHeroes h
CROSS JOIN SayajinArtForms f;

-- Vegeta and Broly keep melee combat rules but weapon 0 now renders the same
-- railgun/ki laser used by ranged heroes. Their last two forms add Civ V's
-- mushroom-cloud impact without enabling native nuke or suicide behaviour.
INSERT INTO ArtDefine_UnitMemberCombatWeapons
        (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax,
         ProjectileSpeed, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale,
         AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped,
         WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius)
SELECT  'ART_DEF_UNIT_MEMBER_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        0, 0, 'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ',
        CASE WHEN f.FormKey IN ('POSTMODERN','FUTURE') THEN 100 ELSE 10 END,
        CASE WHEN f.FormKey IN ('POSTMODERN','FUTURE') THEN 100 ELSE 20 END,
        5.3,
        CASE WHEN h.IsRanged = 0 AND f.FormKey IN ('POSTMODERN','FUTURE')
             THEN 'ART_DEF_VEFFECT_NUCLEAR_BOMB_01' ELSE '' END,
        CASE WHEN f.FormKey = 'POSTMODERN' THEN 0.65
             WHEN f.FormKey = 'FUTURE' THEN 1.25
             WHEN h.ArtKey = 'BROLY' THEN 1.65 ELSE 1.35 END,
        CASE WHEN f.FormKey = 'POSTMODERN' THEN 30
             WHEN f.FormKey = 'FUTURE' THEN 48
             WHEN h.ArtKey = 'BROLY' THEN 24 ELSE 20 END,
        CASE WHEN h.ArtKey = 'BROLY' THEN 1.65 ELSE 1.35 END,
        CASE WHEN f.FormKey IN ('POSTMODERN','FUTURE') THEN 0.5
             WHEN h.ArtKey = 'BROLY' THEN 0.15 ELSE 0.12 END,
        0,
        CASE WHEN f.FormKey IN ('POSTMODERN','FUTURE') THEN 1 ELSE 0 END,
        CASE WHEN f.FormKey IN ('POSTMODERN','FUTURE') THEN 1 ELSE 0 END,
        0,
        'EXPLOSIVE',
        CASE WHEN f.FormKey = 'POSTMODERN' THEN 'ATOMICBOMB'
             WHEN f.FormKey = 'FUTURE' THEN 'EXPLOSION1TON'
             ELSE 'RAILGUN' END,
        10
FROM SayajinArtHeroes h
CROSS JOIN SayajinArtForms f
WHERE h.IsRanged = 0;

-- Ranged attacks use the primary weapon slot fired by our dedicated timed
-- triggers.  Those triggers explicitly transfer the Giant Death Robot railgun
-- projectile and, on the last two forms, the native atomic/nuclear explosion
-- to the combat target.  HitEffect stays empty here so the engine cannot play
-- a second mushroom cloud after the trigger-delivered impact.
INSERT INTO ArtDefine_UnitMemberCombatWeapons
        (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax,
         ProjectileSpeed, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale,
         AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped,
         WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius)
SELECT  'ART_DEF_UNIT_MEMBER_SAYAJIN_' || h.ArtKey || '_' || f.FormKey,
        0, 0,
        'ART_DEF_VEFFECT_TRAIL_RAILGUN_PROJ',
        10,
        20,
        5.3,
        '',
        CASE WHEN h.ArtKey = 'GOKU' THEN 1.55
             WHEN h.ArtKey = 'GOHAN' THEN 1.25 ELSE 1.45 END,
        CASE WHEN h.ArtKey = 'GOKU' THEN 22
             WHEN h.ArtKey = 'GOHAN' THEN 18 ELSE 20 END,
        CASE WHEN h.ArtKey = 'GOKU' THEN 1.55
             WHEN h.ArtKey = 'GOHAN' THEN 1.25 ELSE 1.45 END,
        CASE WHEN h.ArtKey = 'GOKU' THEN 0.15
             WHEN h.ArtKey = 'GOHAN' THEN 0.10 ELSE 0.12 END,
        0,
        0,
        0,
        0,
        'EXPLOSIVE',
        'RAILGUN',
        10
FROM SayajinArtHeroes h
CROSS JOIN SayajinArtForms f
WHERE h.IsRanged = 1;

UPDATE Units
SET UnitArtInfo = (
        SELECT 'ART_DEF_UNIT_SAYAJIN_' || h.ArtKey || '_' || f.FormKey
        FROM SayajinArtHeroes h
        CROSS JOIN SayajinArtForms f
        WHERE Units.Type = h.UnitStem || '_' || f.FormKey
    ),
    UnitArtInfoCulturalVariation = 0,
    UnitArtInfoEraVariation = 0
WHERE EXISTS (
        SELECT 1
        FROM SayajinArtHeroes h
        CROSS JOIN SayajinArtForms f
        WHERE Units.Type = h.UnitStem || '_' || f.FormKey
    );

DROP TABLE SayajinArtHeroes;
DROP TABLE SayajinArtForms;
