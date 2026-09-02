-- =====================================================================
-- BlizzardAuraFrames.lua — optional Blizzard buff/debuff frame visibility
-- v4.0.1
--
-- TomoMod unit-frame auras are completely independent from these frames.
-- We use alpha + mouse input rather than reparenting or unregistering
-- Blizzard frames, so the change is live, reversible and does not require
-- a /reload. Blizzard occasionally restores alpha itself; the secure hook
-- only re-asserts zero while the corresponding frame is configured hidden.
-- =====================================================================

TomoMod_BlizzardAuraFrames = TomoMod_BlizzardAuraFrames or {}
local BAF = TomoMod_BlizzardAuraFrames

local applyingAlpha = false
local hooked = setmetatable({}, { __mode = "k" })
local savedAlpha = setmetatable({}, { __mode = "k" })
local savedMouse = setmetatable({}, { __mode = "k" })
local eventFrame

local function DB()
    if not TomoModDB then return nil end
    TomoModDB.blizzardAuraFrames = TomoModDB.blizzardAuraFrames or {
        enabled = true,
        showBuffs = true,
        showDebuffs = true,
    }
    return TomoModDB.blizzardAuraFrames
end

local function ShouldShow(key)
    local db = DB()
    -- Disabling the module means "leave Blizzard alone" and restores both
    -- native frames. The two per-frame choices are kept for the next enable.
    if not db or db.enabled == false then return true end
    return db[key] ~= false
end

local function HookAlpha(frame, key)
    if not frame or hooked[frame] or type(frame.SetAlpha) ~= "function" then return end
    hooked[frame] = key
    hooksecurefunc(frame, "SetAlpha", function(self, alpha)
        if applyingAlpha or ShouldShow(key) or alpha == 0 then return end
        applyingAlpha = true
        self:SetAlpha(0)
        applyingAlpha = false
    end)
end

local function ReadBool(frame, method)
    local fn = frame and frame[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, frame)
    if not ok then return nil end
    return value and true or false
end

local function ReadAlpha(frame)
    if not frame or type(frame.GetAlpha) ~= "function" then return nil end
    local ok, value = pcall(frame.GetAlpha, frame)
    if not ok or type(value) ~= "number" then return nil end
    return value
end

local function ApplyOne(frame, key)
    if not frame then return end
    HookAlpha(frame, key)

    local visible = ShouldShow(key)
    if not visible then
        if savedAlpha[frame] == nil then savedAlpha[frame] = ReadAlpha(frame) or 1 end
        if savedMouse[frame] == nil then savedMouse[frame] = ReadBool(frame, "IsMouseEnabled") end

        if type(frame.SetAlpha) == "function" then
            applyingAlpha = true
            frame:SetAlpha(0)
            applyingAlpha = false
        end
        if type(frame.EnableMouse) == "function" then frame:EnableMouse(false) end
        return
    end

    -- Restore only values TomoMod changed. When the frame was never hidden,
    -- leave Blizzard's current alpha/mouse state untouched.
    if savedAlpha[frame] ~= nil and type(frame.SetAlpha) == "function" then
        local alpha = savedAlpha[frame]
        savedAlpha[frame] = nil
        applyingAlpha = true
        frame:SetAlpha(alpha)
        applyingAlpha = false
    end
    if savedMouse[frame] ~= nil and type(frame.EnableMouse) == "function" then
        local mouse = savedMouse[frame]
        savedMouse[frame] = nil
        frame:EnableMouse(mouse)
    end
end

function BAF.ApplySettings()
    ApplyOne(_G.BuffFrame, "showBuffs")
    ApplyOne(_G.DebuffFrame, "showDebuffs")
end

function BAF.Initialize()
    if eventFrame then
        BAF.ApplySettings()
        return
    end

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName ~= "Blizzard_BuffFrame" then return end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, BAF.ApplySettings)
        else
            BAF.ApplySettings()
        end
    end)

    if C_Timer and C_Timer.After then
        C_Timer.After(0, BAF.ApplySettings)
    else
        BAF.ApplySettings()
    end
end
