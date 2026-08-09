-- =====================================================
-- Sayajin Monument Service
-- Keeps the non-stacking empire-wide Worker speed bonus in
-- exactly one city while at least one Sayajin Monument exists.
-- =====================================================

Sayajin = Sayajin or {}
Sayajin.Monuments = Sayajin.Monuments or {}

local Monuments = Sayajin.Monuments
local Config = Sayajin.Config
local Utils = Sayajin.Utils

function Monuments.SyncPlayer(playerID)
    local pPlayer = Utils.GetPlayer(playerID)
    if not Utils.IsValidPlayer(pPlayer) or not Utils.IsSayajinPlayer(pPlayer) then
        return
    end

    local cities = {}
    local firstCity = nil
    local hasMonument = false

    -- One city scan is enough even in very large late-game empires.
    for pCity in pPlayer:Cities() do
        table.insert(cities, pCity)
        firstCity = firstCity or pCity
        if pCity:GetNumRealBuilding(Config.BuildingSayajinMonument) > 0 then
            hasMonument = true
        end
    end

    local pHostCity = nil
    if hasMonument then
        pHostCity = pPlayer:GetCapitalCity() or firstCity
    end

    local changed = false
    for _, pCity in ipairs(cities) do
        local shouldHost = pHostCity and pCity:GetID() == pHostCity:GetID()
        local currentCount = pCity:GetNumRealBuilding(Config.BuildingSayajinMonumentEmpire)
        local targetCount = shouldHost and 1 or 0
        if currentCount ~= targetCount then
            pCity:SetNumRealBuilding(Config.BuildingSayajinMonumentEmpire, targetCount)
            changed = true
        end
    end

    if changed and pHostCity then
        Utils.Log(string.format(
            "Empire worker bonus synced. Player=%d HostCityID=%d",
            playerID,
            pHostCity:GetID()
        ))
    end
end

function Monuments.SyncAllSayajinPlayers()
    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        Monuments.SyncPlayer(iPlayer)
    end
end
