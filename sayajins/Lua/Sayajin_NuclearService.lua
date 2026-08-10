-- =====================================================
-- Sayajin Nuclear Service
-- Applies one controlled area blast after a late-form hero attack.
-- It never creates a native nuclear unit, so heroes cannot be consumed by
-- MISSION_NUKE and the AI is not given an invalid air-unit mission.
-- =====================================================

Sayajin = Sayajin or {}
Sayajin.Nuclear = Sayajin.Nuclear or {}

local Nuclear = Sayajin.Nuclear
local Config = Sayajin.Config
local Utils = Sayajin.Utils
local Heroes = Sayajin.Heroes

local activeCombat = nil
local applyingEffect = false
local registered = false

local function GetMaxHitPoints(target, fallback)
    local value = Utils.CallIfExists(target, "GetMaxHitPoints")
    if value and value > 0 then
        return value
    end
    return fallback
end

local function GetAttackTier(pUnit)
    if not pUnit or pUnit:IsDead() or not Heroes.IsHeroUnit(pUnit) then
        return nil
    end

    local tiers = Config.NuclearAttackTiers
    -- Always test the final tier first in case an old save temporarily carries
    -- both form promotions during its first synchronization frame.
    if tiers.Missile.promotion and tiers.Missile.promotion ~= -1
        and pUnit:IsHasPromotion(tiers.Missile.promotion) then
        return tiers.Missile
    end
    if tiers.Atomic.promotion and tiers.Atomic.promotion ~= -1
        and pUnit:IsHasPromotion(tiers.Atomic.promotion) then
        return tiers.Atomic
    end
    return nil
end

local function ResolveDefenderPlot(playerID, objectID, expectedMaxHitPoints)
    local pPlayer = Players[playerID]
    if not pPlayer or objectID == nil or objectID < 0 then
        return nil
    end

    local pUnit = pPlayer:GetUnitByID(objectID)
    local pCity = pPlayer:GetCityByID(objectID)
    local unitMatches = pUnit and GetMaxHitPoints(pUnit, GameDefines.MAX_HIT_POINTS or 100) == expectedMaxHitPoints
    local cityMatches = pCity and GetMaxHitPoints(pCity, GameDefines.MAX_CITY_HIT_POINTS or 200) == expectedMaxHitPoints

    if cityMatches and not unitMatches then
        return pCity:Plot()
    end
    if unitMatches then
        return pUnit:GetPlot()
    end
    if pUnit then
        return pUnit:GetPlot()
    end
    if pCity then
        return pCity:Plot()
    end
    return nil
end

local function IsEnemy(attackerTeamID, victimPlayerID)
    local pVictim = Players[victimPlayerID]
    if not pVictim or not pVictim:IsAlive() then
        return false
    end
    return Teams[attackerTeamID]:IsAtWar(pVictim:GetTeam())
end

local function CollectAffectedPlots(centerX, centerY, radius)
    local plots = {}
    local seen = {}
    for deltaX = -radius, radius do
        for deltaY = -radius, radius do
            local pPlot = Map.PlotXYWithRangeCheck(centerX, centerY, deltaX, deltaY, radius)
            if pPlot then
                local index = pPlot:GetPlotIndex()
                if not seen[index] then
                    seen[index] = true
                    table.insert(plots, pPlot)
                end
            end
        end
    end
    return plots
end

local function DamageEnemyUnits(pPlot, context)
    local victims = {}
    for index = 0, pPlot:GetNumUnits() - 1 do
        local pUnit = pPlot:GetUnit(index)
        if pUnit
            and not pUnit:IsDead()
            and not (pUnit:GetOwner() == context.attackerPlayerID and pUnit:GetID() == context.attackerUnitID)
            and IsEnemy(context.attackerTeamID, pUnit:GetOwner())
            and not Utils.CallIfExists(pUnit, "IsNukeImmune") then
            table.insert(victims, pUnit)
        end
    end

    -- Damage after collection: killing a unit mutates the plot's unit array.
    for _, pUnit in ipairs(victims) do
        if pUnit and not pUnit:IsDead() then
            local maxHitPoints = GetMaxHitPoints(pUnit, GameDefines.MAX_HIT_POINTS or 100)
            local damage = math.max(1, math.floor(maxHitPoints * context.tier.unitDamagePercent / 100 + 0.5))
            pUnit:ChangeDamage(damage, context.attackerPlayerID)
        end
    end
end

local function DamageEnemyCity(pPlot, context)
    local pCity = pPlot:GetPlotCity()
    if not pCity or not IsEnemy(context.attackerTeamID, pCity:GetOwner()) then
        return
    end

    local maxHitPoints = GetMaxHitPoints(pCity, GameDefines.MAX_CITY_HIT_POINTS or 200)
    local currentDamage = pCity:GetDamage()
    -- Leave one hit point.  Civ V expects conquest, razing and ownership
    -- changes to happen through its native city-combat path.
    local availableDamage = math.max(0, maxHitPoints - currentDamage - 1)
    local requestedDamage = math.max(1, math.floor(maxHitPoints * context.tier.cityDamagePercent / 100 + 0.5))
    local appliedDamage = math.min(availableDamage, requestedDamage)
    if appliedDamage > 0 then
        pCity:ChangeDamage(appliedDamage)
    end
end

local function ApplyBlast(context)
    if applyingEffect or not context then
        return
    end
    applyingEffect = true

    local succeeded, errorMessage = pcall(function()
        for _, pPlot in ipairs(CollectAffectedPlots(context.targetX, context.targetY, context.tier.radius)) do
            DamageEnemyUnits(pPlot, context)
            DamageEnemyCity(pPlot, context)
        end

        if context.attackerPlayerID == Game.GetActivePlayer()
            and Events and Events.GameplayAlertMessage then
            Events.GameplayAlertMessage(Locale.ConvertTextKey(context.tier.messageKey))
        end
        Utils.Log(string.format(
            "Nuclear strike applied. Player=%d Unit=%d Target=(%d,%d) Radius=%d",
            context.attackerPlayerID,
            context.attackerUnitID,
            context.targetX,
            context.targetY,
            context.tier.radius
        ))
    end)

    applyingEffect = false
    if not succeeded then
        Utils.Error("Nuclear attack failed safely: " .. tostring(errorMessage))
    end
end

local function OnCombatStarted(
    attackerPlayerID,
    attackerUnitID,
    attackerUnitDamage,
    attackerFinalUnitDamage,
    attackerMaxHitPoints,
    defenderPlayerID,
    defenderUnitID,
    defenderUnitDamage,
    defenderFinalUnitDamage,
    defenderMaxHitPoints,
    attackerX,
    attackerY,
    defenderX,
    defenderY,
    isContinuation
)
    if isContinuation and activeCombat then
        return
    end
    activeCombat = nil

    local pAttacker = Players[attackerPlayerID]
    if not pAttacker or not Utils.IsSayajinPlayer(pAttacker) then
        return
    end

    local pUnit = pAttacker:GetUnitByID(attackerUnitID)
    local tier = GetAttackTier(pUnit)
    if not tier then
        return
    end

    local pTargetPlot = nil
    if defenderX ~= nil and defenderY ~= nil and defenderX >= 0 and defenderY >= 0 then
        pTargetPlot = Map.GetPlot(defenderX, defenderY)
    end
    if not pTargetPlot then
        pTargetPlot = ResolveDefenderPlot(defenderPlayerID, defenderUnitID, defenderMaxHitPoints)
    end
    if not pTargetPlot then
        Utils.Log("Nuclear attack skipped: defender plot could not be resolved.")
        return
    end

    activeCombat = {
        attackerPlayerID = attackerPlayerID,
        attackerUnitID = attackerUnitID,
        attackerTeamID = pAttacker:GetTeam(),
        defenderPlayerID = defenderPlayerID,
        defenderUnitID = defenderUnitID,
        targetX = pTargetPlot:GetX(),
        targetY = pTargetPlot:GetY(),
        tier = tier
    }
end

local function OnCombatEnded(
    attackerPlayerID,
    attackerUnitID,
    attackerUnitDamage,
    attackerFinalUnitDamage,
    attackerMaxHitPoints,
    defenderPlayerID,
    defenderUnitID
)
    local context = activeCombat
    activeCombat = nil
    if not context
        or context.attackerPlayerID ~= attackerPlayerID
        or context.attackerUnitID ~= attackerUnitID
        or context.defenderPlayerID ~= defenderPlayerID
        or context.defenderUnitID ~= defenderUnitID then
        return
    end
    ApplyBlast(context)
end

function Nuclear.Register()
    if registered then
        return
    end
    if not Events or not Events.RunCombatSim or not Events.EndCombatSim then
        Utils.Error("Nuclear combat events are unavailable; late-form blast effects are disabled.")
        return
    end
    Events.RunCombatSim.Add(OnCombatStarted)
    Events.EndCombatSim.Add(OnCombatEnded)
    registered = true
end

function Nuclear.GetAttackTier(pUnit)
    return GetAttackTier(pUnit)
end
