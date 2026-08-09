-- =====================================================
-- Sayajin Utils
-- Small reusable helpers shared by Lua services.
-- =====================================================

Sayajin = Sayajin or {}
Sayajin.Utils = Sayajin.Utils or {}

local Utils = Sayajin.Utils
local Config = Sayajin.Config

function Utils.Log(message)
    if Config and Config.Debug then
        print("[Sayajin] " .. tostring(message))
    end
end

function Utils.Round(value)
    return math.floor(value + 0.5)
end

function Utils.Clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function Utils.Error(message)
    print("[Sayajin][ERROR] " .. tostring(message))
end

function Utils.IsValidPlayer(pPlayer)
    return pPlayer
        and pPlayer:IsAlive()
        and not pPlayer:IsBarbarian()
        and not pPlayer:IsMinorCiv()
end

function Utils.IsSayajinPlayer(pPlayer)
    return pPlayer
        and Config
        and pPlayer:GetCivilizationType() == Config.CivSayajin
end

function Utils.GetPlayer(playerID)
    if playerID == nil then
        return nil
    end
    return Players[playerID]
end

function Utils.GetEraStep(iEra)
    if Config.EraSteps[iEra] ~= nil then
        return Config.EraSteps[iEra]
    end
    if Config.Eras.Future and iEra and iEra >= Config.Eras.Future then
        return Config.MaxEraStep
    end
    return 0
end

function Utils.GetEraPromotion(iEra)
    if Config.EraPromotions[iEra] then
        return Config.EraPromotions[iEra]
    end
    if Config.Eras.Future and iEra and iEra >= Config.Eras.Future then
        return Config.EraPromotions[Config.Eras.Future]
    end
    return Config.EraPromotions[Config.Eras.Ancient]
end

function Utils.GetEraMultiplier(iEra)
    return Config.HeroEraScale ^ Utils.GetEraStep(iEra)
end

function Utils.CallIfExists(target, methodName, ...)
    if not target then
        return nil
    end
    local fn = target[methodName]
    if fn then
        return fn(target, ...)
    end
    return nil
end
