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

-- Weapon 0 drives the physical AttackA animation for every hero. Weapon 1 is
-- present only on ranged heroes, drives AttackB and reuses Civ V's plasma
-- projectile as a compact ki-blast visual.
INSERT INTO ArtDefine_UnitMemberCombatWeapons
        (UnitMemberType, "Index", SubIndex, ID, VisKillStrengthMin, VisKillStrengthMax,
         ProjectileSpeed, HitEffect, HitEffectScale, HitRadius, ProjectileChildEffectScale,
         AreaDamageDelay, ContinuousFire, WaitForEffectCompletion, TargetGround, IsDropped,
         WeaponTypeTag, WeaponTypeSoundOverrideTag, MissTargetSlopRadius)
VALUES  ('ART_DEF_UNIT_MEMBER_SAYAJIN_VEGETA', 0, 0, '', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 0, 0, 0, 0, 'BLUNT',     'BLUNT',   8),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU', 0, 0, '', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 0, 0, 0, 0, 'BLUNT',       'BLUNT',   8),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOKU', 1, 0, 'ART_DEF_VEFFECT_PLASMA_RIFLE_PROJ', 10, 20, 8.3, '', 1.55, 22, 1.55, 0.15, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN', 0, 0, '', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 0, 0, 0, 0, 'BLUNT',      'BLUNT',   8),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_GOHAN', 1, 0, 'ART_DEF_VEFFECT_PLASMA_RIFLE_PROJ', 10, 20, 8.3, '', 1.25, 18, 1.25, 0.10, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO', 0, 0, '', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 0, 0, 0, 0, 'BLUNT',    'BLUNT',   8),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_PICCOLO', 1, 0, 'ART_DEF_VEFFECT_PLASMA_RIFLE_PROJ', 10, 20, 8.3, '', 1.45, 20, 1.45, 0.12, 0, 0, 0, 0, 'EXPLOSIVE', 'RAILGUN', 10),
        ('ART_DEF_UNIT_MEMBER_SAYAJIN_BROLY', 0, 0, '', NULL, NULL, NULL, '', NULL, NULL, NULL, NULL, 0, 0, 0, 0, 'BLUNT',      'BLUNT',   8);

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
