-- =====================================================
-- Sayajin Hero Control - entry point
-- Wires gameplay events to decoupled services.
-- =====================================================

print("[Sayajin] Hero and monument control entry loaded")

-- VFS imports are addressed by their virtual basename. Supplying the source
-- directory here makes Civ V silently skip the dependency and leaves the
-- shared Sayajin table undefined.
include("Sayajin_Config.lua")
include("Sayajin_Utils.lua")
include("Sayajin_HeroService.lua")
include("Sayajin_MonumentService.lua")

local Heroes = Sayajin.Heroes
local Monuments = Sayajin.Monuments

local function SafeCall(label, fn, ...)
    local succeeded, errorMessage = pcall(fn, ...)
    if not succeeded then
        Sayajin.Utils.Error(label .. ": " .. tostring(errorMessage))
    end
end

local function SyncPlayer(playerID)
    -- A problem in one subsystem must not disable the other for the rest of
    -- a long-running save.
    SafeCall("Hero service", Heroes.SyncPlayer, playerID)
    SafeCall("Monument service", Monuments.SyncPlayer, playerID)
end

local function SyncAllSayajins()
    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        SyncPlayer(iPlayer)
    end
end

local function OnTeamSetEra(teamID, eraID)
    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local pPlayer = Players[iPlayer]
        if Sayajin.Utils.IsValidPlayer(pPlayer) and pPlayer:GetTeam() == teamID then
            SyncPlayer(iPlayer)
        end
    end
end

local function OnPlayerDoTurn(playerID)
    SyncPlayer(playerID)
end

local function OnUnitCreated(playerID, unitID)
    local pPlayer = Players[playerID]
    if not Sayajin.Utils.IsValidPlayer(pPlayer) then
        return
    end

    local pUnit = pPlayer:GetUnitByID(unitID)
    if Heroes.IsHeroUnit(pUnit) then
        SyncPlayer(playerID)
    end
end

local function OnPlayerCityFounded(playerID, cityX, cityY)
    SyncPlayer(playerID)
end

local function BlockExtraHeroInCity(playerID, cityID, unitType)
    return Heroes.CanTrain(playerID, unitType)
end

local function BlockExtraHeroForPlayer(playerID, unitType)
    return Heroes.CanTrain(playerID, unitType)
end

GameEvents.CityCanTrain.Add(BlockExtraHeroInCity)
GameEvents.PlayerCanTrain.Add(BlockExtraHeroForPlayer)

-- Some DLL/mod combinations expose PlayerCanEverTrain. When present,
-- registering the same rule here helps the production UI remove blocked
-- heroes from the build list earlier instead of merely disabling them.
if GameEvents.PlayerCanEverTrain then
    GameEvents.PlayerCanEverTrain.Add(BlockExtraHeroForPlayer)
end

GameEvents.PlayerDoTurn.Add(OnPlayerDoTurn)
GameEvents.PlayerCityFounded.Add(OnPlayerCityFounded)
GameEvents.TeamSetEra.Add(OnTeamSetEra)
Events.SerialEventUnitCreated.Add(OnUnitCreated)
Events.LoadScreenClose.Add(SyncAllSayajins)
