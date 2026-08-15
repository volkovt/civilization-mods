-- =====================================================
-- Sayajin Config
-- Centralizes database IDs, era definitions and hero form maps.
-- =====================================================

Sayajin = Sayajin or {}
Sayajin.Config = Sayajin.Config or {}

local Config = Sayajin.Config
local Type = GameInfoTypes

Config.Debug = false
Config.HeroEraScale = 1.5
Config.MaxEraStep = 7
Config.MaxHeroStrength = 500

Config.CivSayajin = Type.CIVILIZATION_SAYAJIN
Config.BuildingSayajinMonument = Type.BUILDING_SAYAJIN_MONUMENT
Config.BuildingSayajinMonumentEmpire = Type.BUILDING_SAYAJIN_MONUMENT_EMPIRE

Config.PromotionHeroMarker = Type.PROMOTION_SAYAJIN_HERO_MARK
Config.PromotionTranscendentAura = Type.PROMOTION_SAYAJIN_TRANSCENDENT_AURA
Config.PromotionFinalForm = Type.PROMOTION_SAYAJIN_FINAL_FORM
Config.PromotionInstantTransmission = Type.PROMOTION_SAYAJIN_INSTANT_TRANSMISSION
Config.PromotionFinalExplosion = Type.PROMOTION_SAYAJIN_FINAL_EXPLOSION

-- Active powers unlock on the second transformation (Super Saiyan), which
-- corresponds to the Medieval form in the era-driven transformation table.
-- Both powers consume the unit's turn and are protected by a persistent
-- once-per-turn cooldown in Sayajin_PowerService.lua.
Config.PowerUnlockEraStep = 2
Config.FinalExplosionRadius = 1
Config.FinalExplosionHealthCostNumerator = 2
Config.FinalExplosionHealthCostDenominator = 3
Config.FinalExplosionDamageMultiplier = 2
Config.FinalExplosionExperiencePerTarget = 2
Config.FinalExplosionMaxExperience = 10

-- Controlled late-form blast damage.  These values intentionally reproduce
-- the battlefield scale of the two nuclear tiers without turning heroes into
-- native suicide weapons or invoking global nuclear-diplomacy state.
Config.NuclearAttackTiers = {
    Atomic = {
        promotion = Config.PromotionTranscendentAura,
        radius = 1,
        unitDamagePercent = 50,
        cityDamagePercent = 50,
        messageKey = "TXT_KEY_SAYAJIN_ATOMIC_IMPACT"
    },
    Missile = {
        promotion = Config.PromotionFinalForm,
        radius = 2,
        unitDamagePercent = 100,
        cityDamagePercent = 90,
        messageKey = "TXT_KEY_SAYAJIN_NUCLEAR_IMPACT"
    }
}

Config.Eras = {
    Ancient     = Type.ERA_ANCIENT,
    Classical   = Type.ERA_CLASSICAL,
    Medieval    = Type.ERA_MEDIEVAL,
    Renaissance = Type.ERA_RENAISSANCE,
    Industrial  = Type.ERA_INDUSTRIAL,
    Modern      = Type.ERA_MODERN,
    PostModern  = Type.ERA_POSTMODERN,
    Future      = Type.ERA_FUTURE
}

Config.EraSteps = {
    [Type.ERA_ANCIENT]     = 0,
    [Type.ERA_CLASSICAL]   = 1,
    [Type.ERA_MEDIEVAL]    = 2,
    [Type.ERA_RENAISSANCE] = 3,
    [Type.ERA_INDUSTRIAL]  = 4,
    [Type.ERA_MODERN]      = 5,
    [Type.ERA_POSTMODERN]  = 6,
    [Type.ERA_FUTURE]      = 7
}

Config.EraPromotions = {
    [Type.ERA_ANCIENT]     = Type.PROMOTION_SAYAJIN_ERA_ANCIENT,
    [Type.ERA_CLASSICAL]   = Type.PROMOTION_SAYAJIN_ERA_CLASSICAL,
    [Type.ERA_MEDIEVAL]    = Type.PROMOTION_SAYAJIN_ERA_MEDIEVAL,
    [Type.ERA_RENAISSANCE] = Type.PROMOTION_SAYAJIN_ERA_RENAISSANCE,
    [Type.ERA_INDUSTRIAL]  = Type.PROMOTION_SAYAJIN_ERA_INDUSTRIAL,
    [Type.ERA_MODERN]      = Type.PROMOTION_SAYAJIN_ERA_MODERN,
    [Type.ERA_POSTMODERN]  = Type.PROMOTION_SAYAJIN_ERA_POSTMODERN,
    [Type.ERA_FUTURE]      = Type.PROMOTION_SAYAJIN_ERA_FUTURE
}

Config.AllEraPromotions = {
    Type.PROMOTION_SAYAJIN_ERA_ANCIENT,
    Type.PROMOTION_SAYAJIN_ERA_CLASSICAL,
    Type.PROMOTION_SAYAJIN_ERA_MEDIEVAL,
    Type.PROMOTION_SAYAJIN_ERA_RENAISSANCE,
    Type.PROMOTION_SAYAJIN_ERA_INDUSTRIAL,
    Type.PROMOTION_SAYAJIN_ERA_MODERN,
    Type.PROMOTION_SAYAJIN_ERA_POSTMODERN,
    Type.PROMOTION_SAYAJIN_ERA_FUTURE
}

Config.FormOnlyPromotions = {
    Type.PROMOTION_SAYAJIN_TRANSCENDENT_AURA,
    Type.PROMOTION_SAYAJIN_FINAL_FORM,
    Type.PROMOTION_SAYAJIN_INSTANT_TRANSMISSION,
    Type.PROMOTION_SAYAJIN_FINAL_EXPLOSION
}

Config.HeroGroups = {
    Vegeta = {
        debugName = "Vegeta",
        rootUnitType = Type.UNIT_SAYAJIN_HERO,
        isRanged = false,
        baseCombat = 14,
        baseRangedCombat = 0,
        forms = {
            [Type.ERA_ANCIENT]     = { unitType = Type.UNIT_SAYAJIN_HERO,                       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO" },
            [Type.ERA_CLASSICAL]   = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_CLASSICAL,       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_CLASSICAL" },
            [Type.ERA_MEDIEVAL]    = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_MEDIEVAL,        nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_MEDIEVAL" },
            [Type.ERA_RENAISSANCE] = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_RENAISSANCE,     nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_RENAISSANCE" },
            [Type.ERA_INDUSTRIAL]  = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_INDUSTRIAL,      nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_INDUSTRIAL" },
            [Type.ERA_MODERN]      = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_MODERN,          nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_MODERN" },
            [Type.ERA_POSTMODERN]  = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_POSTMODERN,      nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_POSTMODERN" },
            [Type.ERA_FUTURE]      = { unitType = Type.UNIT_SAYAJIN_HERO_VEGETA_FUTURE,          nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_VEGETA_FUTURE" }
        }
    },
    Goku = {
        debugName = "Goku",
        rootUnitType = Type.UNIT_SAYAJIN_HERO_GOKU,
        isRanged = true,
        baseCombat = 10,
        baseRangedCombat = 16,
        forms = {
            [Type.ERA_ANCIENT]     = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU,                   nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU" },
            [Type.ERA_CLASSICAL]   = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_CLASSICAL,         nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_CLASSICAL" },
            [Type.ERA_MEDIEVAL]    = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_MEDIEVAL,          nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_MEDIEVAL" },
            [Type.ERA_RENAISSANCE] = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_RENAISSANCE,       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_RENAISSANCE" },
            [Type.ERA_INDUSTRIAL]  = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_INDUSTRIAL,        nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_INDUSTRIAL" },
            [Type.ERA_MODERN]      = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_MODERN,            nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_MODERN" },
            [Type.ERA_POSTMODERN]  = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_POSTMODERN,        nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_POSTMODERN" },
            [Type.ERA_FUTURE]      = { unitType = Type.UNIT_SAYAJIN_HERO_GOKU_FUTURE,            nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOKU_FUTURE" }
        }
    },
    Piccolo = {
        debugName = "Piccolo",
        rootUnitType = Type.UNIT_SAYAJIN_HERO_PICCOLO,
        isRanged = true,
        baseCombat = 14,
        baseRangedCombat = 20,
        forms = {
            [Type.ERA_ANCIENT]     = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO,                nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO" },
            [Type.ERA_CLASSICAL]   = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_CLASSICAL,      nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_CLASSICAL" },
            [Type.ERA_MEDIEVAL]    = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_MEDIEVAL,       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_MEDIEVAL" },
            [Type.ERA_RENAISSANCE] = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_RENAISSANCE,    nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_RENAISSANCE" },
            [Type.ERA_INDUSTRIAL]  = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_INDUSTRIAL,     nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_INDUSTRIAL" },
            [Type.ERA_MODERN]      = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_MODERN,         nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_MODERN" },
            [Type.ERA_POSTMODERN]  = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_POSTMODERN,     nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_POSTMODERN" },
            [Type.ERA_FUTURE]      = { unitType = Type.UNIT_SAYAJIN_HERO_PICCOLO_FUTURE,         nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_PICCOLO_FUTURE" }
        }
    },
    Gohan = {
        debugName = "Gohan",
        rootUnitType = Type.UNIT_SAYAJIN_HERO_GOHAN,
        isRanged = true,
        baseCombat = 12,
        baseRangedCombat = 19,
        forms = {
            [Type.ERA_ANCIENT]     = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN,                  nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN" },
            [Type.ERA_CLASSICAL]   = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_CLASSICAL,        nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_CLASSICAL" },
            [Type.ERA_MEDIEVAL]    = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_MEDIEVAL,         nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_MEDIEVAL" },
            [Type.ERA_RENAISSANCE] = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_RENAISSANCE,      nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_RENAISSANCE" },
            [Type.ERA_INDUSTRIAL]  = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_INDUSTRIAL,       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_INDUSTRIAL" },
            [Type.ERA_MODERN]      = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_MODERN,           nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_MODERN" },
            [Type.ERA_POSTMODERN]  = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_POSTMODERN,       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_POSTMODERN" },
            [Type.ERA_FUTURE]      = { unitType = Type.UNIT_SAYAJIN_HERO_GOHAN_FUTURE,           nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_GOHAN_FUTURE" }
        }
    },
    Broly = {
        debugName = "Broly",
        rootUnitType = Type.UNIT_SAYAJIN_HERO_BROWLY,
        isRanged = false,
        baseCombat = 18,
        baseRangedCombat = 0,
        forms = {
            [Type.ERA_ANCIENT]     = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY,                 nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY" },
            [Type.ERA_CLASSICAL]   = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_CLASSICAL,       nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_CLASSICAL" },
            [Type.ERA_MEDIEVAL]    = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_MEDIEVAL,        nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_MEDIEVAL" },
            [Type.ERA_RENAISSANCE] = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_RENAISSANCE,     nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_RENAISSANCE" },
            [Type.ERA_INDUSTRIAL]  = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_INDUSTRIAL,      nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_INDUSTRIAL" },
            [Type.ERA_MODERN]      = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_MODERN,          nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_MODERN" },
            [Type.ERA_POSTMODERN]  = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_POSTMODERN,      nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_POSTMODERN" },
            [Type.ERA_FUTURE]      = { unitType = Type.UNIT_SAYAJIN_HERO_BROWLY_FUTURE,          nameKey = "TXT_KEY_UNIT_SAYAJIN_HERO_BROWLY_FUTURE" }
        }
    }
}

Config.HeroTypeToGroupKey = {}
Config.RootHeroTypes = {}

for groupKey, group in pairs(Config.HeroGroups) do
    Config.RootHeroTypes[group.rootUnitType] = true
    for _, form in pairs(group.forms) do
        if form.unitType and form.unitType ~= -1 then
            Config.HeroTypeToGroupKey[form.unitType] = groupKey
        end
    end
end
