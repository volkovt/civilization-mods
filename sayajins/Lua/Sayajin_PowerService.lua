-- =====================================================
-- Sayajin Power Service
-- Safe, deterministic active powers for Goku and Vegeta.
-- =====================================================

Sayajin = Sayajin or {}
Sayajin.Powers = Sayajin.Powers or {}

local Powers = Sayajin.Powers
local Config = Sayajin.Config
local Utils = Sayajin.Utils

Powers.Ability = {
    Teleport = "GOKU_TELEPORT",
    FinalExplosion = "VEGETA_FINAL_EXPLOSION"
}

Powers.Reason = {
    Ready = "TXT_KEY_SAYAJIN_POWER_READY",
    Locked = "TXT_KEY_SAYAJIN_POWER_LOCKED",
    WrongUnit = "TXT_KEY_SAYAJIN_POWER_WRONG_UNIT",
    NotTurn = "TXT_KEY_SAYAJIN_POWER_NOT_TURN",
    NoMoves = "TXT_KEY_SAYAJIN_POWER_NO_MOVES",
    Used = "TXT_KEY_SAYAJIN_POWER_ALREADY_USED",
    InCombat = "TXT_KEY_SAYAJIN_POWER_IN_COMBAT",
    NoPlot = "TXT_KEY_SAYAJIN_TELEPORT_NO_PLOT",
    Fog = "TXT_KEY_SAYAJIN_TELEPORT_FOG",
    SamePlot = "TXT_KEY_SAYAJIN_TELEPORT_SAME_PLOT",
    BadTerrain = "TXT_KEY_SAYAJIN_TELEPORT_BAD_TERRAIN",
    Occupied = "TXT_KEY_SAYAJIN_TELEPORT_OCCUPIED",
    ForeignCity = "TXT_KEY_SAYAJIN_TELEPORT_FOREIGN_CITY",
    LowHealth = "TXT_KEY_SAYAJIN_FINAL_EXPLOSION_LOW_HEALTH",
    NoEnemies = "TXT_KEY_SAYAJIN_FINAL_EXPLOSION_NO_ENEMIES",
    Failed = "TXT_KEY_SAYAJIN_POWER_FAILED"
}

local cooldownMemory = {}
local saveData = nil

if Modding and Modding.OpenSaveData then
    local ok, value = pcall(Modding.OpenSaveData)
    if ok then
        saveData = value
    end
end

local function GetTurn()
    if Game and Game.GetGameTurn then
        local ok, turn = pcall(Game.GetGameTurn)
        if ok and turn ~= nil then
            return turn
        end
    end
    return -1
end

local function GetCooldownKey(playerID, ability)
    return string.format("SAYAJIN_POWER_V1_%s_P%d", tostring(ability), playerID)
end

local function WasUsedThisTurn(playerID, ability)
    local key = GetCooldownKey(playerID, ability)
    local turn = GetTurn()
    local value = cooldownMemory[key]
    if saveData and saveData.GetValue then
        local ok, saved = pcall(function() return saveData.GetValue(key) end)
        if ok and saved ~= nil then
            value = tonumber(saved)
        end
    end
    return value == turn
end

local function MarkUsedThisTurn(playerID, ability)
    local key = GetCooldownKey(playerID, ability)
    local turn = GetTurn()
    cooldownMemory[key] = turn
    if saveData and saveData.SetValue then
        pcall(function() saveData.SetValue(key, turn) end)
    end
end

local function IsUnitBusy(pUnit)
    if not pUnit then
        return true
    end
    if pUnit.IsFighting and pUnit:IsFighting() then
        return true
    end
    if pUnit.IsInCombat and pUnit:IsInCombat() then
        return true
    end
    return false
end

local function HasMoves(pUnit)
    return pUnit and pUnit.GetMoves and pUnit:GetMoves() > 0
end

local function FinishMoves(pUnit)
    if pUnit.FinishMoves then
        pUnit:FinishMoves()
    elseif pUnit.SetMoves then
        pUnit:SetMoves(0)
    end
end

local function GetMaxHitPoints(pUnit)
    if pUnit and pUnit.GetMaxHitPoints then
        local ok, value = pcall(function() return pUnit:GetMaxHitPoints() end)
        if ok and value and value > 0 then
            return value
        end
    end
    return (GameDefines and GameDefines.MAX_HIT_POINTS) or 100
end

local function GetGroupKey(pUnit)
    if not pUnit or pUnit:IsDead() then
        return nil
    end
    return Config.HeroTypeToGroupKey[pUnit:GetUnitType()]
end

local function ValidateActor(pUnit, requiredGroup, promotionID, ability)
    if not pUnit or pUnit:IsDead() or GetGroupKey(pUnit) ~= requiredGroup then
        return false, Powers.Reason.WrongUnit
    end

    local playerID = pUnit:GetOwner()
    if not Game or not Game.GetActivePlayer or playerID ~= Game.GetActivePlayer() then
        return false, Powers.Reason.NotTurn
    end

    local pPlayer = Players[playerID]
    if not Utils.IsSayajinPlayer(pPlayer)
        or (pPlayer.IsHuman and not pPlayer:IsHuman())
        or (pPlayer.IsTurnActive and not pPlayer:IsTurnActive()) then
        return false, Powers.Reason.NotTurn
    end

    if not promotionID or promotionID == -1 or not pUnit:IsHasPromotion(promotionID) then
        return false, Powers.Reason.Locked
    end
    if IsUnitBusy(pUnit) then
        return false, Powers.Reason.InCombat
    end
    if not HasMoves(pUnit) then
        return false, Powers.Reason.NoMoves
    end
    if WasUsedThisTurn(playerID, ability) then
        return false, Powers.Reason.Used
    end

    return true, Powers.Reason.Ready
end

local function IsPlotVisibleToUnitOwner(pUnit, pPlot)
    local pPlayer = pUnit and Players[pUnit:GetOwner()]
    if not pPlayer or not pPlot or not pPlot.IsVisible then
        return false
    end
    local ok, visible = pcall(function()
        return pPlot:IsVisible(pPlayer:GetTeam(), false)
    end)
    return ok and visible == true
end

local function IsUnsafeTerrain(pPlot)
    return not pPlot
        or (pPlot.IsWater and pPlot:IsWater())
        or (pPlot.IsMountain and pPlot:IsMountain())
        or (pPlot.IsImpassable and pPlot:IsImpassable())
end

local function IsForeignCity(pUnit, pPlot)
    if not pPlot or not pPlot.IsCity or not pPlot:IsCity() then
        return false
    end
    local pCity = pPlot.GetPlotCity and pPlot:GetPlotCity() or nil
    return not pCity or pCity:GetOwner() ~= pUnit:GetOwner()
end

function Powers.GetGroupKey(pUnit)
    return GetGroupKey(pUnit)
end

function Powers.CanStartTeleport(pUnit)
    return ValidateActor(
        pUnit,
        "Goku",
        Config.PromotionInstantTransmission,
        Powers.Ability.Teleport
    )
end

function Powers.CanTeleportToPlot(pUnit, pPlot)
    local canStart, reason = Powers.CanStartTeleport(pUnit)
    if not canStart then
        return false, reason
    end
    if not pPlot then
        return false, Powers.Reason.NoPlot
    end
    if not IsPlotVisibleToUnitOwner(pUnit, pPlot) then
        return false, Powers.Reason.Fog
    end
    if pUnit:GetX() == pPlot:GetX() and pUnit:GetY() == pPlot:GetY() then
        return false, Powers.Reason.SamePlot
    end
    if IsUnsafeTerrain(pPlot) then
        return false, Powers.Reason.BadTerrain
    end
    if IsForeignCity(pUnit, pPlot) then
        return false, Powers.Reason.ForeignCity
    end
    if not pPlot.GetNumUnits or pPlot:GetNumUnits() > 0 then
        return false, Powers.Reason.Occupied
    end
    return true, Powers.Reason.Ready
end

function Powers.Teleport(pUnit, pPlot)
    local canUse, reason = Powers.CanTeleportToPlot(pUnit, pPlot)
    if not canUse then
        return false, reason
    end

    local playerID = pUnit:GetOwner()
    local oldX = pUnit:GetX()
    local oldY = pUnit:GetY()
    local oldMoves = pUnit:GetMoves()
    local newX = pPlot:GetX()
    local newY = pPlot:GetY()

    local moved = false
    local ok, err = pcall(function()
        pUnit:SetXY(newX, newY)
        moved = pUnit:GetX() == newX and pUnit:GetY() == newY
    end)

    if not ok or not moved then
        Utils.Log("Instant Transmission failed: " .. tostring(err))
        if pUnit and not pUnit:IsDead() then
            pcall(function() pUnit:SetXY(oldX, oldY) end)
            if pUnit.SetMoves then
                pcall(function() pUnit:SetMoves(oldMoves) end)
            end
        end
        return false, Powers.Reason.Failed
    end

    MarkUsedThisTurn(playerID, Powers.Ability.Teleport)
    FinishMoves(pUnit)
    return true, Powers.Reason.Ready, {
        oldX = oldX,
        oldY = oldY,
        newX = newX,
        newY = newY
    }
end

local function IsEnemyUnit(pActor, pOther)
    if not pActor or not pOther or pOther:IsDead() then
        return false
    end
    local actorOwner = pActor:GetOwner()
    local otherOwner = pOther:GetOwner()
    if actorOwner == otherOwner or not Players[otherOwner] then
        return false
    end
    local actorTeamID = Players[actorOwner]:GetTeam()
    local otherTeamID = Players[otherOwner]:GetTeam()
    local actorTeam = Teams and Teams[actorTeamID]
    return actorTeam and actorTeam.IsAtWar and actorTeam:IsAtWar(otherTeamID)
end

local function GetAdjacentPlots(pUnit)
    local plots = {}
    if not pUnit or not Map or not Map.PlotDirection then
        return plots
    end
    local x = pUnit:GetX()
    local y = pUnit:GetY()
    for direction = 0, 5 do
        local pPlot = Map.PlotDirection(x, y, direction)
        if pPlot then
            table.insert(plots, pPlot)
        end
    end
    return plots
end

local function CollectAdjacentEnemies(pUnit)
    local enemies = {}
    for _, pPlot in ipairs(GetAdjacentPlots(pUnit)) do
        local count = pPlot.GetNumUnits and pPlot:GetNumUnits() or 0
        for index = 0, count - 1 do
            local pOther = pPlot:GetUnit(index)
            if IsEnemyUnit(pUnit, pOther) then
                table.insert(enemies, pOther)
            end
        end
    end
    table.sort(enemies, function(a, b)
        if a:GetOwner() ~= b:GetOwner() then
            return a:GetOwner() < b:GetOwner()
        end
        return a:GetID() < b:GetID()
    end)
    return enemies
end

local function GetFinalExplosionExperience(targetCount)
    local perTarget = math.max(
        0,
        tonumber(Config.FinalExplosionExperiencePerTarget) or 0
    )
    local maximum = math.max(
        0,
        tonumber(Config.FinalExplosionMaxExperience) or 0
    )
    return math.min(maximum, math.max(0, targetCount or 0) * perTarget)
end

local function GrantExperience(pUnit, experienceGained)
    if not pUnit or pUnit:IsDead() or experienceGained <= 0
        or not pUnit.ChangeExperience then
        return 0
    end
    local ok = pcall(function()
        pUnit:ChangeExperience(experienceGained)
    end)
    return ok and experienceGained or 0
end

function Powers.GetFinalExplosionPreview(pUnit)
    local canStart, reason = ValidateActor(
        pUnit,
        "Vegeta",
        Config.PromotionFinalExplosion,
        Powers.Ability.FinalExplosion
    )
    if not canStart then
        return false, reason, nil
    end

    local maxHitPoints = GetMaxHitPoints(pUnit)
    local currentHitPoints = math.max(0, maxHitPoints - pUnit:GetDamage())
    if currentHitPoints < 3 then
        return false, Powers.Reason.LowHealth, nil
    end

    local healthCost = math.floor(
        currentHitPoints
        * Config.FinalExplosionHealthCostNumerator
        / Config.FinalExplosionHealthCostDenominator
    )
    healthCost = math.max(1, math.min(currentHitPoints - 1, healthCost))
    local damage = math.min(
        maxHitPoints,
        healthCost * Config.FinalExplosionDamageMultiplier
    )
    local enemies = CollectAdjacentEnemies(pUnit)
    if #enemies == 0 then
        return false, Powers.Reason.NoEnemies, {
            healthCost = healthCost,
            damage = damage,
            enemies = enemies,
            experience = 0
        }
    end

    return true, Powers.Reason.Ready, {
        healthCost = healthCost,
        damage = damage,
        enemies = enemies,
        experience = GetFinalExplosionExperience(#enemies)
    }
end

function Powers.UseFinalExplosion(pUnit)
    local canUse, reason, preview = Powers.GetFinalExplosionPreview(pUnit)
    if not canUse or not preview then
        return false, reason
    end

    local playerID = pUnit:GetOwner()
    local centerX = pUnit:GetX()
    local centerY = pUnit:GetY()

    -- Commit the cost/cooldown before mutating enemy units. This prevents a
    -- save-reload or another mod's kill callback from duplicating the blast.
    MarkUsedThisTurn(playerID, Powers.Ability.FinalExplosion)
    FinishMoves(pUnit)
    pUnit:ChangeDamage(preview.healthCost)

    local hitCount = 0
    for _, pEnemy in ipairs(preview.enemies) do
        if pEnemy and not pEnemy:IsDead() then
            local ok = pcall(function()
                pEnemy:ChangeDamage(preview.damage, playerID)
            end)
            if ok then
                hitCount = hitCount + 1
            end
        end
    end

    -- Native combat normally awards XP after resolving an attack. Final
    -- Explosion is a scripted area action, so it grants the equivalent here:
    -- two XP per successfully affected unit, capped to prevent XP farming.
    local experienceGained = GrantExperience(
        pUnit,
        GetFinalExplosionExperience(hitCount)
    )

    return true, Powers.Reason.Ready, {
        x = centerX,
        y = centerY,
        healthCost = preview.healthCost,
        damage = preview.damage,
        hitCount = hitCount,
        experienceGained = experienceGained
    }
end

function Powers.GetExplosionPlots(pUnit)
    return GetAdjacentPlots(pUnit)
end
