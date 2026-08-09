-- =====================================================
-- Sayajin Hero Service
-- Owns hero identification, one-living-hero enforcement,
-- era promotion sync, strength scaling and era transformations.
-- =====================================================

Sayajin = Sayajin or {}
Sayajin.Heroes = Sayajin.Heroes or {}

local Heroes = Sayajin.Heroes
local Config = Sayajin.Config
local Utils = Sayajin.Utils

local isSyncing = false

local function GetGroupKeyFromUnitType(iUnitType)
    return Config.HeroTypeToGroupKey[iUnitType]
end

local function GetGroupFromUnitType(iUnitType)
    local groupKey = GetGroupKeyFromUnitType(iUnitType)
    if groupKey then
        return groupKey, Config.HeroGroups[groupKey]
    end
    return nil, nil
end

local function GetGroupFromUnit(pUnit)
    if not pUnit then
        return nil, nil
    end
    return GetGroupFromUnitType(pUnit:GetUnitType())
end

local function GetTargetForm(group, iEra)
    if not group then
        return nil
    end
    if group.forms[iEra] then
        return group.forms[iEra]
    end
    if Config.Eras.Future and iEra and iEra >= Config.Eras.Future then
        return group.forms[Config.Eras.Future]
    end
    return group.forms[Config.Eras.Ancient]
end

local function ApplyHeroEraPromotion(pUnit, iEra)
    local iTargetPromo = Utils.GetEraPromotion(iEra)
    for _, iPromo in ipairs(Config.AllEraPromotions) do
        if iPromo and iPromo ~= -1 then
            pUnit:SetHasPromotion(iPromo, iPromo == iTargetPromo)
        end
    end
end

local function ApplyHeroFormPromotions(pUnit, iEra)
    local isPostModern = iEra == Config.Eras.PostModern
    local isFuture = Config.Eras.Future and iEra and iEra >= Config.Eras.Future

    if Config.PromotionTranscendentAura and Config.PromotionTranscendentAura ~= -1 then
        pUnit:SetHasPromotion(Config.PromotionTranscendentAura, isPostModern)
    end
    if Config.PromotionFinalForm and Config.PromotionFinalForm ~= -1 then
        pUnit:SetHasPromotion(Config.PromotionFinalForm, isFuture)
    end
end

local function ApplyHeroEraStats(pUnit, group, iEra)
    if not pUnit or not group then
        return
    end

    local multiplier = Utils.GetEraMultiplier(iEra)
    local maxStrength = Config.MaxHeroStrength or 500
    local newCombat = Utils.Clamp(
        Utils.Round(group.baseCombat * multiplier),
        1,
        maxStrength
    )
    pUnit:SetBaseCombatStrength(newCombat)

    -- Always write ranged strength, including zero. This migrates units from
    -- older saves where Vegeta and Broly may still carry a ranged value.
    local rangedBase = group.isRanged and (group.baseRangedCombat or 0) or 0
    local newRanged = 0
    if rangedBase > 0 then
        newRanged = Utils.Clamp(
            Utils.Round(rangedBase * multiplier),
            1,
            maxStrength
        )
    end

    if pUnit.SetBaseRangedCombatStrength then
        pUnit:SetBaseRangedCombatStrength(newRanged)
    end

    if group.isRanged then
        Utils.Log(string.format(
            "%s synced. Era=%d Step=%d Scale=%.3f Combat=%d Ranged=%d UnitID=%d",
            group.debugName,
            iEra,
            Utils.GetEraStep(iEra),
            multiplier,
            newCombat,
            newRanged,
            pUnit:GetID()
        ))
    else
        Utils.Log(string.format(
            "%s synced. Era=%d Step=%d Scale=%.3f Combat=%d UnitID=%d",
            group.debugName,
            iEra,
            Utils.GetEraStep(iEra),
            multiplier,
            newCombat,
            pUnit:GetID()
        ))
    end
end

local function CopyFallbackState(pOldUnit, pNewUnit)
    if not pOldUnit or not pNewUnit then
        return
    end

    local damage = Utils.CallIfExists(pOldUnit, "GetDamage")
    local moves = Utils.CallIfExists(pOldUnit, "GetMoves")
    local experience = Utils.CallIfExists(pOldUnit, "GetExperience")
    local level = Utils.CallIfExists(pOldUnit, "GetLevel")

    if damage ~= nil then Utils.CallIfExists(pNewUnit, "SetDamage", damage) end
    if moves ~= nil then Utils.CallIfExists(pNewUnit, "SetMoves", moves) end
    if experience ~= nil then Utils.CallIfExists(pNewUnit, "SetExperience", experience) end
    if level ~= nil then Utils.CallIfExists(pNewUnit, "SetLevel", level) end

    -- Convert is available in the standard BNW runtime. If another DLL
    -- removes it, preserve every promotion instead of only the era markers.
    if GameInfo and GameInfo.UnitPromotions then
        for promotion in GameInfo.UnitPromotions() do
            local iPromo = promotion.ID
            if iPromo and iPromo ~= -1 and pOldUnit:IsHasPromotion(iPromo) then
                pNewUnit:SetHasPromotion(iPromo, true)
            end
        end
    end

    if Config.PromotionHeroMarker and Config.PromotionHeroMarker ~= -1 then
        pNewUnit:SetHasPromotion(Config.PromotionHeroMarker, true)
    end
end

local function TransformHeroIfNeeded(pPlayer, pUnit, group, iEra)
    local targetForm = GetTargetForm(group, iEra)
    if not targetForm or not targetForm.unitType or targetForm.unitType == -1 then
        return pUnit
    end

    if pUnit:GetUnitType() == targetForm.unitType then
        return pUnit
    end

    local oldUnitType = pUnit:GetUnitType()
    local x = pUnit:GetX()
    local y = pUnit:GetY()
    local pNewUnit = pPlayer:InitUnit(targetForm.unitType, x, y)

    if not pNewUnit then
        Utils.Log("Failed to transform hero: InitUnit returned nil.")
        return pUnit
    end

    if pNewUnit.Convert then
        pNewUnit:Convert(pUnit)
    else
        CopyFallbackState(pUnit, pNewUnit)
        pUnit:Kill(true, -1)
    end

    Utils.Log(string.format(
        "%s transformed. FromUnitType=%d ToUnitType=%d Era=%d NewUnitID=%d",
        group.debugName,
        oldUnitType,
        targetForm.unitType,
        iEra,
        pNewUnit:GetID()
    ))

    return pNewUnit
end

local function ApplyHeroName(pUnit, group, iEra)
    if not pUnit or not group then
        return
    end
    local targetForm = GetTargetForm(group, iEra)
    if targetForm and targetForm.nameKey then
        pUnit:SetName(Locale.ConvertTextKey(targetForm.nameKey))
    end
end

local function SyncHeroUnit(pPlayer, pUnit, iEra)
    local _, group = GetGroupFromUnit(pUnit)
    if not group then
        return
    end

    pUnit = TransformHeroIfNeeded(pPlayer, pUnit, group, iEra)
    ApplyHeroName(pUnit, group, iEra)
    ApplyHeroEraPromotion(pUnit, iEra)
    -- Convert carries promotions from the old form. Normalize the two
    -- form-exclusive bonuses so Post-Modern and Future never stack forever.
    ApplyHeroFormPromotions(pUnit, iEra)
    ApplyHeroEraStats(pUnit, group, iEra)
end

function Heroes.IsHeroUnit(pUnit)
    if not pUnit or pUnit:IsDead() then
        return false
    end
    if GetGroupFromUnitType(pUnit:GetUnitType()) then
        return true
    end
    return Config.PromotionHeroMarker and pUnit:IsHasPromotion(Config.PromotionHeroMarker)
end

function Heroes.HasLivingHeroInGroup(pPlayer, groupKey)
    if not pPlayer or not groupKey then
        return false
    end
    for pUnit in pPlayer:Units() do
        if not pUnit:IsDead() and GetGroupKeyFromUnitType(pUnit:GetUnitType()) == groupKey then
            return true
        end
    end
    return false
end

function Heroes.EnforceSingleHeroPerGroup(playerID)
    local pPlayer = Utils.GetPlayer(playerID)
    if not Utils.IsValidPlayer(pPlayer) or not Utils.IsSayajinPlayer(pPlayer) then
        return
    end

    for groupKey, group in pairs(Config.HeroGroups) do
        local units = {}
        for pUnit in pPlayer:Units() do
            if not pUnit:IsDead() and GetGroupKeyFromUnitType(pUnit:GetUnitType()) == groupKey then
                table.insert(units, pUnit)
            end
        end

        if #units > 1 then
            table.sort(units, function(a, b)
                return a:GetID() < b:GetID()
            end)

            for i = 2, #units do
                local pExtraHero = units[i]
                Utils.Log(string.format(
                    "Removing extra %s hero. Player=%d Unit=%d",
                    group.debugName,
                    playerID,
                    pExtraHero:GetID()
                ))
                pExtraHero:Kill(true, -1)
            end
        end
    end
end

local function SyncPlayerInternal(playerID)
    local pPlayer = Utils.GetPlayer(playerID)
    if not Utils.IsValidPlayer(pPlayer) or not Utils.IsSayajinPlayer(pPlayer) then
        return
    end

    Heroes.EnforceSingleHeroPerGroup(playerID)

    local iEra = pPlayer:GetCurrentEra()
    local heroUnits = {}

    -- Collect first, then transform. Transforming creates/kills units,
    -- so doing it inside the player unit iterator can skip units or break
    -- iteration in some Civ V Lua runtimes.
    for pUnit in pPlayer:Units() do
        if Heroes.IsHeroUnit(pUnit) then
            table.insert(heroUnits, pUnit)
        end
    end

    for _, pUnit in ipairs(heroUnits) do
        if pUnit and not pUnit:IsDead() then
            SyncHeroUnit(pPlayer, pUnit, iEra)
        end
    end
end

function Heroes.SyncPlayer(playerID)
    if isSyncing then
        return
    end

    local pPlayer = Utils.GetPlayer(playerID)
    if not Utils.IsValidPlayer(pPlayer) or not Utils.IsSayajinPlayer(pPlayer) then
        return
    end

    isSyncing = true
    local succeeded, errorMessage = pcall(SyncPlayerInternal, playerID)
    -- Never leave the service locked after a runtime error. A permanent lock
    -- would stop every transformation and stat update for the rest of a save.
    isSyncing = false

    if not succeeded then
        Utils.Error(string.format(
            "Hero synchronization failed for player %d: %s",
            playerID,
            tostring(errorMessage)
        ))
    end
end

function Heroes.SyncAllSayajinPlayers()
    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        Heroes.SyncPlayer(iPlayer)
    end
end

function Heroes.CanTrain(playerID, iUnitType)
    local groupKey = GetGroupKeyFromUnitType(iUnitType)

    -- Non-hero units are not controlled by this service.
    if not groupKey then
        return true
    end

    local pPlayer = Utils.GetPlayer(playerID)

    -- Hero units are exclusive to the Sayajin civilization. This also
    -- protects the mod if another mod, UI panel or cached production list
    -- tries to evaluate the unit directly instead of through UnitClass rules.
    if not Utils.IsValidPlayer(pPlayer) or not Utils.IsSayajinPlayer(pPlayer) then
        return false
    end

    -- Only the root/Ancient form is trainable. All transformed era forms
    -- are runtime-only units created by Lua and must never be buildable.
    if not Config.RootHeroTypes[iUnitType] then
        return false
    end

    -- One living hero per family: Vegeta, Goku, Piccolo, Gohan and Broly
    -- are checked across every era form, not only the trainable root type.
    if Heroes.HasLivingHeroInGroup(pPlayer, groupKey) then
        return false
    end

    return true
end
