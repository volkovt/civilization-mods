-- =====================================================
-- Sayajin Power Panel - isolated InGameUIAddin
-- =====================================================

print("[Sayajin] Power panel loaded")

include("IconSupport")
include("InstanceManager")
include("Sayajin_Config.lua")
include("Sayajin_Utils.lua")
include("Sayajin_HeroService.lua")
include("Sayajin_PowerService.lua")

local Powers = Sayajin.Powers
local Config = Sayajin.Config

local targetingTeleport = false
local targetingPlayerID = -1
local targetingUnitID = -1
local hoverPlot = nil
local selectedPlot = nil
local hoverHighlights = {}
local selectedHighlights = {}
local pulseHighlights = {}
local pulse = nil
local callbacks = {}
local currentPowerName = ""
local currentPowerTooltip = ""
local currentStatus = ""
local currentActionVerb = ""
local currentActionButton = nil
local currentActionIcon = nil
local panelMinimized = false
local powerActionManager = nil
local powerActionInstances = {}
local activePowerDefinitions = {}
local RefreshPanel = nil
local OnPowerActionButton = nil
local StopTeleportTargeting = nil

local PANEL_EXPANDED_WIDTH = 66
local PANEL_HEADER_HEIGHT = 30
local PANEL_ACTION_HEIGHT = 50
local PANEL_ACTION_PADDING = 4
local PANEL_BOTTOM_PADDING = 4
local PANEL_CANCEL_AREA_HEIGHT = 26

-- Adding a future power starts here. The rail discovers matching definitions,
-- creates one native action button for each and grows vertically on its own.
local POWER_DEFINITIONS = {
    {
        id = "Teleport",
        groupKey = "Goku",
        atlas = "SAYAJIN_HERO_GOKU_ATLAS",
        nameKey = "TXT_KEY_SAYAJIN_POWER_GOKU_NAME",
        tooltipKey = "TXT_KEY_SAYAJIN_POWER_GOKU_TOOLTIP"
    },
    {
        id = "FinalExplosion",
        groupKey = "Vegeta",
        atlas = "SAYAJIN_HERO_VEGETA_ATLAS",
        nameKey = "TXT_KEY_SAYAJIN_POWER_VEGETA_NAME",
        tooltipKey = "TXT_KEY_SAYAJIN_POWER_VEGETA_TOOLTIP"
    }
}

local COLOR_TELEPORT = Vector4(0.15, 0.85, 1.0, 1.0)
local COLOR_VALID = Vector4(0.15, 1.0, 0.45, 1.0)
local COLOR_SELECTED = Vector4(1.0, 0.82, 0.12, 1.0)
local COLOR_INVALID = Vector4(1.0, 0.2, 0.15, 1.0)
local COLOR_EXPLOSION = Vector4(1.0, 0.72, 0.05, 1.0)
local COLOR_BLAST = Vector4(1.0, 0.18, 0.05, 1.0)

local function Localize(key, ...)
    if Locale and Locale.ConvertTextKey then
        local ok, value = pcall(Locale.ConvertTextKey, key, ...)
        if ok and value then
            return value
        end
    end
    return tostring(key or "")
end

local function SetText(control, value)
    if control and control.SetText then
        control:SetText(value or "")
    end
end

local function UpdatePowerTooltip()
    local parts = {}
    if currentPowerName ~= "" then
        table.insert(parts, "[COLOR_POSITIVE_TEXT]" .. currentPowerName .. "[ENDCOLOR]")
    end
    if currentStatus ~= "" then table.insert(parts, currentStatus) end
    if currentPowerTooltip ~= "" then table.insert(parts, currentPowerTooltip) end
    if currentActionVerb ~= "" then
        table.insert(parts, "[COLOR_CYAN]" .. currentActionVerb .. "[ENDCOLOR]")
    end
    local tooltip = table.concat(parts, "[NEWLINE]")

    if currentActionButton and currentActionButton.SetToolTipString then
        currentActionButton:SetToolTipString(tooltip)
    end
    if currentActionIcon and currentActionIcon.SetToolTipString then
        currentActionIcon:SetToolTipString(tooltip)
    end
end

local function SetPowerDetails(nameKey, tooltipKey)
    currentPowerName = Localize(nameKey)
    currentPowerTooltip = Localize(tooltipKey)
    currentStatus = ""
    currentActionVerb = ""
    SetText(Controls and Controls.PowerName, currentPowerName)
    UpdatePowerTooltip()
end

local function SetStatus(key, ...)
    currentStatus = Localize(key, ...)
    SetText(Controls and Controls.PowerStatus, currentStatus)
    UpdatePowerTooltip()
end

local function SetCompactStatus(key, ...)
    SetText(Controls and Controls.TargetCoordinates, Localize(key, ...))
end

local function Notify(key, ...)
    if Events and Events.GameplayAlertMessage then
        Events.GameplayAlertMessage(Localize(key, ...))
    end
end

local function GetPlot(x, y)
    if Map and Map.GetPlot then
        return Map.GetPlot(x, y)
    end
    return nil
end

local function ToHex(pPlot)
    if not pPlot or not ToHexFromGrid or not Vector2 then
        return nil
    end
    return ToHexFromGrid(Vector2(pPlot:GetX(), pPlot:GetY()))
end

local function FireGameplayFX(pPlot)
    local hex = ToHex(pPlot)
    if hex and Events and Events.GameplayFX then
        pcall(function() Events.GameplayFX(hex.x, hex.y, -1) end)
    end
end

local function AddHighlight(list, pPlot, color, style)
    local hex = ToHex(pPlot)
    if not hex or not Events or not Events.SerialEventHexHighlight then
        return
    end
    Events.SerialEventHexHighlight(hex, true, color, style)
    table.insert(list, { plot = pPlot, color = color, style = style })
end

local function ClearHighlightList(list)
    if Events and Events.SerialEventHexHighlight then
        for _, entry in ipairs(list) do
            local hex = ToHex(entry.plot)
            if hex then
                Events.SerialEventHexHighlight(hex, false, entry.color, entry.style)
            end
        end
    end
    for index = #list, 1, -1 do
        list[index] = nil
    end
end

local function GetSelectedUnit()
    if not UI or not UI.GetHeadSelectedUnit then
        return nil
    end
    local pUnit = UI.GetHeadSelectedUnit()
    if not pUnit or pUnit:IsDead() then
        return nil
    end
    return pUnit
end

local function GetTargetingUnit()
    if not targetingTeleport or targetingPlayerID < 0 or targetingUnitID < 0 then
        return nil
    end
    local pPlayer = Players[targetingPlayerID]
    if not pPlayer then
        return nil
    end
    local pUnit = pPlayer:GetUnitByID(targetingUnitID)
    if not pUnit or pUnit:IsDead() then
        return nil
    end
    return pUnit
end

local function IsCityScreenOpen()
    if UI and UI.IsCityScreenUp then
        local ok, value = pcall(UI.IsCityScreenUp)
        return ok and value == true
    end
    return false
end

local function PositionPanel()
    if not Controls or not Controls.PowerPanel
        or not Controls.PowerPanel.SetOffsetVal then
        return
    end

    local bottomOffset = 180
    if UIManager and UIManager.GetScreenSizeVal then
        local ok, _, screenHeight = pcall(function()
            local width, height = UIManager:GetScreenSizeVal()
            return width, height
        end)
        if ok and screenHeight then
            -- The stock/VP unit panel occupies roughly 22% of the screen.
            -- Following that ratio keeps this strip beside its action column
            -- at both 1366x768 and 1920x1080 without touching UnitPanel.xml.
            bottomOffset = math.max(176, math.min(300, math.floor(screenHeight * 0.22) + 8))
        end
    end
    Controls.PowerPanel:SetOffsetVal(52, bottomOffset)
    if Controls.CollapsedButton and Controls.CollapsedButton.SetOffsetVal then
        Controls.CollapsedButton:SetOffsetVal(52, bottomOffset)
    end
    if Controls.PowerPanel.ReprocessAnchoring then
        Controls.PowerPanel:ReprocessAnchoring()
    end
    if Controls.CollapsedButton and Controls.CollapsedButton.ReprocessAnchoring then
        Controls.CollapsedButton:ReprocessAnchoring()
    end
end

local function ApplyPanelLayout(actionCount, cancelVisible)
    if not Controls or not Controls.PowerPanel then
        return
    end

    if panelMinimized then
        Controls.PowerPanel:SetHide(true)
        if Controls.CollapsedButton then Controls.CollapsedButton:SetHide(false) end
        if Controls.CancelButton then Controls.CancelButton:SetHide(true) end
        return
    end

    Controls.PowerPanel:SetHide(false)
    if Controls.CollapsedButton then Controls.CollapsedButton:SetHide(true) end
    if Controls.PanelTitle then Controls.PanelTitle:SetHide(false) end
    if Controls.PowerActionStack then Controls.PowerActionStack:SetHide(false) end

    local count = math.max(1, tonumber(actionCount) or 1)
    local actionsHeight = count * PANEL_ACTION_HEIGHT
        + math.max(0, count - 1) * PANEL_ACTION_PADDING
    local bottomHeight = cancelVisible
        and PANEL_CANCEL_AREA_HEIGHT
        or PANEL_BOTTOM_PADDING
    local expandedHeight = PANEL_HEADER_HEIGHT + actionsHeight + bottomHeight

    if Controls.CancelButton then
        Controls.CancelButton:SetHide(not cancelVisible)
    end
    if Controls.PowerPanel.SetSizeVal then
        Controls.PowerPanel:SetSizeVal(PANEL_EXPANDED_WIDTH, expandedHeight)
    end
    SetText(Controls.MinimizeLabel, "-")
    if Controls.MinimizeButton and Controls.MinimizeButton.SetToolTipString then
        Controls.MinimizeButton:SetToolTipString(
            Localize("TXT_KEY_SAYAJIN_POWER_PANEL_MINIMIZE_TOOLTIP")
        )
    end

    if Controls.PowerPanel.ReprocessAnchoring then
        Controls.PowerPanel:ReprocessAnchoring()
    end
end

local function SetPowerIcon(control, atlas)
    if not control or not IconHookup then
        return
    end
    local ok = pcall(IconHookup, 0, 45, atlas, control)
    control:SetHide(not ok)
end

local function GetPowerDefinitions(groupKey)
    local definitions = {}
    for _, definition in ipairs(POWER_DEFINITIONS) do
        if definition.groupKey == groupKey then
            table.insert(definitions, definition)
        end
    end
    return definitions
end

local function OnPowerActionButtonSafe(actionIndex)
    local ok, err = pcall(function()
        if OnPowerActionButton then
            OnPowerActionButton(tonumber(actionIndex) or 1)
        end
    end)
    if not ok then
        print("[Sayajin][ERROR] Power action: " .. tostring(err))
        if StopTeleportTargeting then StopTeleportTargeting() end
        if RefreshPanel then RefreshPanel() end
    end
end

local function RebuildPowerActionInstances(definitions)
    if not powerActionManager or not Controls or not Controls.PowerActionStack then
        return false
    end

    powerActionManager:ResetInstances()
    for index = #powerActionInstances, 1, -1 do
        powerActionInstances[index] = nil
    end
    activePowerDefinitions = definitions

    for index, definition in ipairs(definitions) do
        local instance = powerActionManager:GetInstance()
        powerActionInstances[index] = instance
        SetPowerIcon(instance.PowerActionIcon, definition.atlas)
        if instance.PowerActionButton then
            instance.PowerActionButton:SetVoid1(index)
            instance.PowerActionButton:SetDisabled(false)
            if instance.PowerActionButton.SetAlpha then
                instance.PowerActionButton:SetAlpha(1.0)
            end
            if instance.PowerActionButton.RegisterCallback and Mouse then
                instance.PowerActionButton:RegisterCallback(
                    Mouse.eLClick,
                    OnPowerActionButtonSafe
                )
            end
        end
    end

    Controls.PowerActionStack:CalculateSize()
    Controls.PowerActionStack:ReprocessAnchoring()
    return true
end

local function StopPulse()
    ClearHighlightList(pulseHighlights)
    pulse = nil
    if ContextPtr and ContextPtr.ClearUpdate then
        ContextPtr:ClearUpdate()
    end
end

local function PulseUpdate(deltaTime)
    if not pulse then
        StopPulse()
        return
    end
    pulse.elapsed = pulse.elapsed + deltaTime
    if pulse.kind == "explosion" and not pulse.secondWave and pulse.elapsed >= 0.38 then
        pulse.secondWave = true
        FireGameplayFX(pulse.center)
        for _, pPlot in ipairs(pulse.adjacent or {}) do
            FireGameplayFX(pPlot)
        end
    end
    if pulse.elapsed >= pulse.duration then
        StopPulse()
    end
end

local function StartPulse(kind, center, adjacent, duration)
    StopPulse()
    pulse = {
        kind = kind,
        center = center,
        adjacent = adjacent or {},
        elapsed = 0,
        duration = duration,
        secondWave = false
    }
    if ContextPtr and ContextPtr.SetUpdate then
        ContextPtr:SetUpdate(PulseUpdate)
    end
end

local function PlayTeleportVisual(oldPlot, newPlot)
    StartPulse("teleport", newPlot, { oldPlot }, 1.15)
    AddHighlight(pulseHighlights, oldPlot, COLOR_TELEPORT, "MovementRangeBorder")
    AddHighlight(pulseHighlights, newPlot, COLOR_VALID, "MovementRangeBorder")
    FireGameplayFX(oldPlot)
    FireGameplayFX(newPlot)
    if Events and Events.AudioPlay2DSound then
        Events.AudioPlay2DSound("AS2D_SELECT_PARATROOPER")
    end
    if UI and UI.LookAt and newPlot then
        UI.LookAt(newPlot, 0)
    end
end

local function PlayExplosionVisual(centerPlot, adjacentPlots)
    if UI and UI.LookAt and centerPlot then
        UI.LookAt(centerPlot, 0)
    end
    if Events and Events.AudioPlay2DSound then
        Events.AudioPlay2DSound("AS2D_BIRTH_ATOMIC_BOMB")
    end
    FireGameplayFX(centerPlot)
    for _, pPlot in ipairs(adjacentPlots) do
        FireGameplayFX(pPlot)
    end
    StartPulse("explosion", centerPlot, adjacentPlots, 1.55)
    AddHighlight(pulseHighlights, centerPlot, COLOR_EXPLOSION, "FireRangeBorder")
    for _, pPlot in ipairs(adjacentPlots) do
        AddHighlight(pulseHighlights, pPlot, COLOR_BLAST, "ValidFireTargetBorder")
    end
end

StopTeleportTargeting = function()
    targetingTeleport = false
    targetingPlayerID = -1
    targetingUnitID = -1
    hoverPlot = nil
    selectedPlot = nil
    ClearHighlightList(hoverHighlights)
    ClearHighlightList(selectedHighlights)
end

local function LatchTeleportTarget(pUnit, pPlot)
    local canTeleport, reason = Powers.CanTeleportToPlot(pUnit, pPlot)
    if not canTeleport then
        SetStatus(reason)
        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_INVALID")
        return false
    end

    selectedPlot = pPlot
    ClearHighlightList(selectedHighlights)
    ClearHighlightList(hoverHighlights)
    AddHighlight(
        selectedHighlights,
        selectedPlot,
        COLOR_SELECTED,
        "MovementRangeBorder"
    )
    SetStatus(
        "TXT_KEY_SAYAJIN_TELEPORT_DESTINATION_READY",
        selectedPlot:GetX(),
        selectedPlot:GetY()
    )
    SetCompactStatus(
        "TXT_KEY_SAYAJIN_POWER_COMPACT_COORDINATES",
        selectedPlot:GetX(),
        selectedPlot:GetY()
    )
    return true
end

local function ConfigureButtons(primaryKey, primaryEnabled, cancelVisible)
    currentActionVerb = Localize(primaryKey)
    if currentActionButton then
        currentActionButton:SetDisabled(not primaryEnabled)
        if currentActionButton.SetAlpha then
            currentActionButton:SetAlpha(primaryEnabled and 1.0 or 0.42)
        end
    end
    if Controls and Controls.CancelButton then
        Controls.CancelButton:SetHide(not cancelVisible)
    end
    UpdatePowerTooltip()
end

local function SetCompactAvailability(canUse, reason)
    if canUse then
        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_READY")
    elseif reason == Powers.Reason.Locked then
        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_LOCKED")
    elseif reason == Powers.Reason.NoEnemies then
        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_NO_TARGETS")
    elseif reason == Powers.Reason.NoMoves or reason == Powers.Reason.Used then
        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_SPENT")
    else
        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_UNAVAILABLE")
    end
end

RefreshPanel = function()
    if not Controls or not Controls.PowerPanel then
        return
    end

    local pUnit = GetSelectedUnit()
    local activePlayerID = Game and Game.GetActivePlayer and Game.GetActivePlayer() or -1
    local groupKey = pUnit and Powers.GetGroupKey(pUnit) or nil
    local definitions = GetPowerDefinitions(groupKey)
    local shouldShow = pUnit
        and pUnit:GetOwner() == activePlayerID
        and #definitions > 0
        and pUnit.GetMoves
        and pUnit:GetMoves() > 0
        and not IsCityScreenOpen()

    if not shouldShow then
        StopTeleportTargeting()
        if powerActionManager then powerActionManager:ResetInstances() end
        activePowerDefinitions = {}
        currentActionButton = nil
        currentActionIcon = nil
        Controls.PowerPanel:SetHide(true)
        if Controls.CollapsedButton then Controls.CollapsedButton:SetHide(true) end
        return
    end

    if targetingTeleport
        and (pUnit:GetOwner() ~= targetingPlayerID or pUnit:GetID() ~= targetingUnitID) then
        StopTeleportTargeting()
    end

    PositionPanel()

    if panelMinimized then
        ApplyPanelLayout(#definitions, false)
        return
    end

    if not RebuildPowerActionInstances(definitions) then
        Controls.PowerPanel:SetHide(true)
        if Controls.CollapsedButton then Controls.CollapsedButton:SetHide(true) end
        return
    end

    for index, definition in ipairs(definitions) do
        local instance = powerActionInstances[index]
        currentActionButton = instance and instance.PowerActionButton or nil
        currentActionIcon = instance and instance.PowerActionIcon or nil
        SetPowerDetails(definition.nameKey, definition.tooltipKey)

        if definition.id == "Teleport" then
            if targetingTeleport then
                if selectedPlot then
                    local canTeleport, reason = Powers.CanTeleportToPlot(pUnit, selectedPlot)
                    ConfigureButtons("TXT_KEY_SAYAJIN_POWER_GOKU_CONFIRM", canTeleport, true)
                    if canTeleport then
                        SetStatus(
                            "TXT_KEY_SAYAJIN_TELEPORT_DESTINATION_READY",
                            selectedPlot:GetX(),
                            selectedPlot:GetY()
                        )
                        SetCompactStatus(
                            "TXT_KEY_SAYAJIN_POWER_COMPACT_COORDINATES",
                            selectedPlot:GetX(),
                            selectedPlot:GetY()
                        )
                    else
                        SetStatus(reason)
                        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_INVALID")
                    end
                else
                    ConfigureButtons("TXT_KEY_SAYAJIN_POWER_GOKU_CONFIRM", false, true)
                    local hoverValid, hoverReason = Powers.CanTeleportToPlot(pUnit, hoverPlot)
                    if hoverPlot and hoverValid then
                        SetStatus(
                            "TXT_KEY_SAYAJIN_TELEPORT_HOVER_READY",
                            hoverPlot:GetX(),
                            hoverPlot:GetY()
                        )
                        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_CLICK_TILE")
                    elseif hoverPlot then
                        SetStatus(hoverReason)
                        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_INVALID")
                    else
                        SetStatus("TXT_KEY_SAYAJIN_TELEPORT_CHOOSE_DESTINATION")
                        SetCompactStatus("TXT_KEY_SAYAJIN_POWER_COMPACT_CLICK_TILE")
                    end
                end
            else
                local canStart, reason = Powers.CanStartTeleport(pUnit)
                ConfigureButtons("TXT_KEY_SAYAJIN_POWER_GOKU_BUTTON", canStart, false)
                SetStatus(canStart and "TXT_KEY_SAYAJIN_POWER_READY" or reason)
                SetCompactAvailability(canStart, reason)
            end
        elseif definition.id == "FinalExplosion" then
            local canUse, reason, preview = Powers.GetFinalExplosionPreview(pUnit)
            ConfigureButtons("TXT_KEY_SAYAJIN_POWER_VEGETA_BUTTON", canUse, false)
            if canUse and preview then
                SetStatus(
                    "TXT_KEY_SAYAJIN_FINAL_EXPLOSION_PREVIEW",
                    preview.healthCost,
                    preview.damage,
                    #preview.enemies,
                    preview.experience
                )
                SetCompactStatus(
                    "TXT_KEY_SAYAJIN_POWER_COMPACT_TARGETS",
                    #preview.enemies,
                    preview.damage
                )
            else
                SetStatus(reason)
                SetCompactAvailability(canUse, reason)
            end
        end
    end

    ApplyPanelLayout(#definitions, targetingTeleport)
    PositionPanel()
end

local function OnMinimizeButton()
    if not panelMinimized and targetingTeleport then
        -- Do not leave the map input captured while the player is choosing
        -- a promotion behind the collapsed power strip.
        StopTeleportTargeting()
    end

    panelMinimized = not panelMinimized
    RefreshPanel()
end

OnPowerActionButton = function(actionIndex)
    local definition = activePowerDefinitions[actionIndex]
    local instance = powerActionInstances[actionIndex]
    local pUnit = GetSelectedUnit()
    local groupKey = pUnit and Powers.GetGroupKey(pUnit) or nil
    if not definition or not pUnit or definition.groupKey ~= groupKey then
        return
    end

    currentActionButton = instance and instance.PowerActionButton or nil
    currentActionIcon = instance and instance.PowerActionIcon or nil
    SetPowerDetails(definition.nameKey, definition.tooltipKey)

    if definition.id == "Teleport" then
        if not targetingTeleport then
            local canStart, reason = Powers.CanStartTeleport(pUnit)
            if not canStart then
                SetStatus(reason)
                return
            end
            targetingTeleport = true
            targetingPlayerID = pUnit:GetOwner()
            targetingUnitID = pUnit:GetID()
            hoverPlot = nil
            selectedPlot = nil
            ClearHighlightList(hoverHighlights)
            ClearHighlightList(selectedHighlights)
            RefreshPanel()
            return
        end

        local oldPlot = GetPlot(pUnit:GetX(), pUnit:GetY())
        local success, reason, result = Powers.Teleport(pUnit, selectedPlot)
        if success and result then
            local newPlot = GetPlot(result.newX, result.newY)
            StopTeleportTargeting()
            PlayTeleportVisual(oldPlot, newPlot)
            Notify("TXT_KEY_SAYAJIN_TELEPORT_SUCCESS", result.newX, result.newY)
        else
            SetStatus(reason or Powers.Reason.Failed)
        end
        RefreshPanel()
        return
    end

    if definition.id == "FinalExplosion" then
        local adjacentPlots = Powers.GetExplosionPlots(pUnit)
        local success, reason, result = Powers.UseFinalExplosion(pUnit)
        if success and result then
            local centerPlot = GetPlot(result.x, result.y)
            PlayExplosionVisual(centerPlot, adjacentPlots)
            Notify(
                "TXT_KEY_SAYAJIN_FINAL_EXPLOSION_SUCCESS",
                result.healthCost,
                result.damage,
                result.hitCount,
                result.experienceGained
            )
        else
            SetStatus(reason or Powers.Reason.Failed)
        end
        RefreshPanel()
    end
end

local function OnCancelButton()
    StopTeleportTargeting()
    RefreshPanel()
end

local function OnMouseOverHex(x, y)
    if not targetingTeleport then
        return
    end
    local pUnit = GetTargetingUnit()
    if not pUnit then
        StopTeleportTargeting()
        RefreshPanel()
        return
    end

    hoverPlot = GetPlot(x, y)
    ClearHighlightList(hoverHighlights)
    local canTeleport, reason = Powers.CanTeleportToPlot(pUnit, hoverPlot)
    local isSelectedPlot = hoverPlot and selectedPlot
        and hoverPlot:GetX() == selectedPlot:GetX()
        and hoverPlot:GetY() == selectedPlot:GetY()
    if hoverPlot and canTeleport and not isSelectedPlot then
        AddHighlight(hoverHighlights, hoverPlot, COLOR_VALID, "MovementRangeBorder")
    elseif hoverPlot and not isSelectedPlot and reason ~= Powers.Reason.Fog then
        AddHighlight(hoverHighlights, hoverPlot, COLOR_INVALID, "ValidFireTargetBorder")
    end
    RefreshPanel()
end

local function OnInput(uiMsg, key)
    if not targetingTeleport then
        return false
    end

    if KeyEvents and uiMsg == KeyEvents.KeyDown
        and Keys and key == Keys.VK_ESCAPE then
        OnCancelButton()
        return true
    end

    if not MouseEvents then
        return false
    end

    local panelHasMouse = Controls and Controls.PowerPanel
        and Controls.PowerPanel.HasMouseOver
        and Controls.PowerPanel:HasMouseOver()
    if panelHasMouse then
        -- Let the normal button callbacks handle confirmation and cancel.
        return false
    end

    local isLeftDown = uiMsg == MouseEvents.LButtonDown
        or (MouseEvents.PointerDown and uiMsg == MouseEvents.PointerDown)
    local isLeftUp = uiMsg == MouseEvents.LButtonUp
        or (MouseEvents.PointerUp and uiMsg == MouseEvents.PointerUp)
    local isRightDown = uiMsg == MouseEvents.RButtonDown
    local isRightUp = uiMsg == MouseEvents.RButtonUp

    if isRightDown or isRightUp then
        if isRightUp then
            OnCancelButton()
        end
        return true
    end

    if isLeftDown then
        -- Consume the press so the map does not change unit selection while
        -- Instant Transmission is choosing a destination.
        return true
    end

    if isLeftUp then
        local pUnit = GetTargetingUnit()
        if not pUnit then
            StopTeleportTargeting()
            RefreshPanel()
            return true
        end

        local x, y = nil, nil
        if UI and UI.GetMouseOverHex then
            local ok, mouseX, mouseY = pcall(UI.GetMouseOverHex)
            if ok then
                x, y = mouseX, mouseY
            end
        end
        hoverPlot = GetPlot(x, y)
        LatchTeleportTarget(pUnit, hoverPlot)
        RefreshPanel()
        return true
    end

    return false
end

local function Keep(callback)
    table.insert(callbacks, callback)
    return callback
end

local function RegisterButton(control, callback)
    if not control or not control.RegisterCallback or not Mouse then
        return false
    end
    control:RegisterCallback(Mouse.eLClick, Keep(function()
        local ok, err = pcall(callback)
        if not ok then
            print("[Sayajin][ERROR] Power button: " .. tostring(err))
            StopTeleportTargeting()
            RefreshPanel()
        end
    end))
    return true
end

local function RegisterEvents()
    if Events.UnitSelectionChanged then Events.UnitSelectionChanged.Add(RefreshPanel) end
    if Events.SerialEventUnitInfoDirty then Events.SerialEventUnitInfoDirty.Add(RefreshPanel) end
    if Events.SerialEventMouseOverHex then Events.SerialEventMouseOverHex.Add(OnMouseOverHex) end
    if Events.GameplaySetActivePlayer then Events.GameplaySetActivePlayer.Add(RefreshPanel) end
    if Events.LoadScreenClose then Events.LoadScreenClose.Add(RefreshPanel) end
    if Events.ActivePlayerTurnStart then Events.ActivePlayerTurnStart.Add(RefreshPanel) end
    if Events.ActivePlayerTurnEnd then Events.ActivePlayerTurnEnd.Add(RefreshPanel) end
end

local function Initialize()
    if not Controls or not Controls.PowerPanel or not Controls.PowerActionStack
        or not Controls.CollapsedButton then
        print("[Sayajin][ERROR] Power panel XML controls are unavailable")
        return
    end
    if not InstanceManager then
        print("[Sayajin][ERROR] InstanceManager is unavailable")
        return
    end
    powerActionManager = InstanceManager:new(
        "PowerActionInstance",
        "PowerActionButton",
        Controls.PowerActionStack
    )
    RegisterButton(Controls.CancelButton, OnCancelButton)
    RegisterButton(Controls.MinimizeButton, OnMinimizeButton)
    RegisterButton(Controls.CollapsedButton, OnMinimizeButton)
    RegisterEvents()
    if ContextPtr and ContextPtr.SetInputHandler then
        ContextPtr:SetInputHandler(OnInput)
    end
    RefreshPanel()
end

local ok, err = pcall(Initialize)
if not ok then
    print("[Sayajin][ERROR] Power panel initialization: " .. tostring(err))
end
