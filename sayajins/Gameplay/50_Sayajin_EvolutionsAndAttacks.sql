-- ==========================================================================
-- SAYAJINS: signature attacks and meaningful late-era evolutions
-- Ranged combat uses the AttackB animation and the ki projectile configured
-- in 40_Sayajin_ArtDefines.sql. Physical combat uses AttackA.
-- ==========================================================================

INSERT INTO UnitPromotions
        (Type, Description, Help, Sound, CannotBeChosen, LostWithUpgrade,
         PortraitIndex, IconAtlas, PediaType, PediaEntry,
         AlwaysHeal, AttackWoundedMod, FriendlyHealChange)
VALUES  ('PROMOTION_SAYAJIN_ZENKAI',
         'TXT_KEY_PROMOTION_SAYAJIN_ZENKAI', 'TXT_KEY_PROMOTION_SAYAJIN_ZENKAI_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 58, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ZENKAI',
         1, 25, 5);

INSERT INTO UnitPromotions
        (Type, Description, Help, Sound, CannotBeChosen, LostWithUpgrade,
         PortraitIndex, IconAtlas, PediaType, PediaEntry,
         RangedAttackModifier, CityAttack, RangeChange, RangeAttackIgnoreLOS,
         AttackMod, DefenseMod, HPHealedIfDestroyEnemy, Blitz)
VALUES  ('PROMOTION_SAYAJIN_ATTACK_VEGETA',
         'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_VEGETA', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_VEGETA_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 40, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_VEGETA',
         0, 25, 0, 0, 10, 0, 0, 0),
        ('PROMOTION_SAYAJIN_ATTACK_GOKU',
         'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_GOKU', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_GOKU_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 41, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_GOKU',
         25, 10, 1, 1, 0, 0, 10, 0),
        ('PROMOTION_SAYAJIN_ATTACK_GOHAN',
         'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_GOHAN', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_GOHAN_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 42, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_GOHAN',
         20, 15, 0, 0, 15, 0, 10, 0),
        ('PROMOTION_SAYAJIN_ATTACK_PICCOLO',
         'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_PICCOLO', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_PICCOLO_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 43, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_PICCOLO',
         25, 15, 1, 1, 0, 15, 0, 0),
        ('PROMOTION_SAYAJIN_ATTACK_BROLY',
         'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_BROLY', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_BROLY_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 44, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_ATTACK_BROLY',
         0, 30, 0, 0, 20, 0, 15, 1);

INSERT INTO UnitPromotions
        (Type, Description, Help, Sound, CannotBeChosen, LostWithUpgrade,
         PortraitIndex, IconAtlas, PediaType, PediaEntry,
         CombatPercent, RangedAttackModifier, MovesChange, CanMoveAfterAttacking,
         IgnoreZOC, ExtraAttacks, HPHealedIfDestroyEnemy)
VALUES  ('PROMOTION_SAYAJIN_TRANSCENDENT_AURA',
         'TXT_KEY_PROMOTION_SAYAJIN_TRANSCENDENT_AURA', 'TXT_KEY_PROMOTION_SAYAJIN_TRANSCENDENT_AURA_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 55, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_TRANSCENDENT_AURA',
         20, 20, 1, 1, 0, 0, 15),
        ('PROMOTION_SAYAJIN_FINAL_FORM',
         'TXT_KEY_PROMOTION_SAYAJIN_FINAL_FORM', 'TXT_KEY_PROMOTION_SAYAJIN_FINAL_FORM_HELP', 'AS2D_IF_LEVELUP',
         1, 0, 56, 'PROMOTION_ATLAS', 'PEDIA_ATTRIBUTES', 'TXT_KEY_PROMOTION_SAYAJIN_FINAL_FORM',
         25, 25, 1, 1, 1, 1, 25);

-- Roles are normalized again after every form has been created. This also
-- protects existing saves upgraded from versions where every hero had a
-- ranged strength in the database.
UPDATE Units SET RangedCombat = 0, Range = 0
WHERE Type = 'UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_VEGETA_%';

UPDATE Units SET RangedCombat = 16, Range = 3
WHERE Type = 'UNIT_SAYAJIN_HERO_GOKU' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOKU_%';

UPDATE Units SET RangedCombat = 19, Range = 2
WHERE Type = 'UNIT_SAYAJIN_HERO_GOHAN' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOHAN_%';

UPDATE Units SET RangedCombat = 20, Range = 4
WHERE Type = 'UNIT_SAYAJIN_HERO_PICCOLO' OR Type LIKE 'UNIT_SAYAJIN_HERO_PICCOLO_%';

UPDATE Units SET RangedCombat = 0, Range = 0
WHERE Type = 'UNIT_SAYAJIN_HERO_BROWLY' OR Type LIKE 'UNIT_SAYAJIN_HERO_BROWLY_%';

-- Universal biology/flight identity.
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_ZENKAI'
FROM Units
WHERE Type = 'UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_%';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_HOVERING_UNIT'
FROM Units
WHERE Domain = 'DOMAIN_LAND'
  AND (Type = 'UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_%');

-- Signature attacks remain with the hero through every transformation.
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_ATTACK_VEGETA'
FROM Units
WHERE Type = 'UNIT_SAYAJIN_HERO' OR Type LIKE 'UNIT_SAYAJIN_HERO_VEGETA_%';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_ATTACK_GOKU'
FROM Units
WHERE Type = 'UNIT_SAYAJIN_HERO_GOKU' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOKU_%';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_ATTACK_GOHAN'
FROM Units
WHERE Type = 'UNIT_SAYAJIN_HERO_GOHAN' OR Type LIKE 'UNIT_SAYAJIN_HERO_GOHAN_%';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_ATTACK_PICCOLO'
FROM Units
WHERE Type = 'UNIT_SAYAJIN_HERO_PICCOLO' OR Type LIKE 'UNIT_SAYAJIN_HERO_PICCOLO_%';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_ATTACK_BROLY'
FROM Units
WHERE Type = 'UNIT_SAYAJIN_HERO_BROWLY' OR Type LIKE 'UNIT_SAYAJIN_HERO_BROWLY_%';

-- The last two forms alter mobility and attack cadence, not only strength.
INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_TRANSCENDENT_AURA'
FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO_%_POSTMODERN';

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
SELECT Type, 'PROMOTION_SAYAJIN_FINAL_FORM'
FROM Units WHERE Type LIKE 'UNIT_SAYAJIN_HERO_%_FUTURE';
