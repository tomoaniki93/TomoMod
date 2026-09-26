-- Regression bench for Midnight 12.1 Area-POI tooltip widgets.
-- Blizzard attaches the widget set only after GameTooltip:Show() returns, so
-- the skin pass must be deferred and must re-check the completed tooltip.

local total = 0
local function check(label, condition)
    total = total + 1
    assert(condition, label)
end

local timers = {}
C_Timer = {
    After = function(_, callback)
        timers[#timers + 1] = callback
    end,
}

local function RunTimers()
    local queued = timers
    timers = {}
    for i = 1, #queued do queued[i]() end
end

local backdropCalls = 0
local tooltip = {
    shown = true,
    NumLines = function() return 0 end,
    GetName = function() return "GameTooltip" end,
    GetUnit = function() return nil, nil end,
    GetOwner = function() return nil end,
    IsShown = function(self) return self.shown end,
    IsForbidden = function() return false end,
    SetBackdrop = function() backdropCalls = backdropCalls + 1 end,
    SetBackdropColor = function() end,
    SetBackdropBorderColor = function() end,
    CreateTexture = function()
        return {
            SetHeight = function() end,
            SetPoint = function() end,
            SetColorTexture = function() end,
        }
    end,
    Show = function() end,
    SetUnit = function() end,
}

GameTooltip = tooltip
UIParent = {}
TomoModDB = { tooltipSkin = { enabled = true } }
TomoMod_Utils = nil
TomoMod_TooltipInfo = nil
ShoppingTooltip1, ShoppingTooltip2, ItemRefTooltip = nil, nil, nil

GameTooltip_SetDefaultAnchor = function() end
hooksecurefunc = function(target, method, callback)
    if type(target) == "string" then return end
    local original = target[method]
    target[method] = function(self, ...)
        local results = { original(self, ...) }
        callback(self, ...)
        return unpack(results)
    end
end

dofile("Core/Utils.lua")
dofile("Modules/QOL/Skins/TooltipSkin.lua")
TomoMod_TooltipSkin.Initialize()

-- This is the real Blizzard order: Show first, widget attachment second.
tooltip:Show()
check("skin is not applied inside Show", backdropCalls == 0)
check("one deferred skin pass is queued", #timers == 1)
tooltip.widgetContainer = { widgetSetID = 2044 }
RunTimers()
check("late-attached widget tooltip remains untouched", backdropCalls == 0)

-- Ordinary tooltips still receive the skin on the following frame.
tooltip.widgetContainer = nil
tooltip:Show()
tooltip:Show()
check("repeated Show calls are coalesced", #timers == 1)
RunTimers()
check("ordinary tooltip is styled", backdropCalls == 1)

print("PASS: " .. total .. " tooltip widget taint assertions")
