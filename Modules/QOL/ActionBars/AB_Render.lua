-- =====================================================================
-- AB_Render.lua v1.0.0 -- ActionBars render layer (Lot A2)
--
-- Owns the CONTENT of an action button: icon texture and zoom, cooldown,
-- charge / stack count, macro name. The chrome (background, border, insets)
-- stays with ActionBarSkin; the state (usable, range, active) stays with
-- AB_Engine. This module never reads state itself, it only reacts.
--
-- COOLDOWN BACKENDS
--   "native"  (default) -- adopt the Cooldown widget the button already has
--             and restyle it. Blizzard keeps feeding it, so nothing can
--             break. This is the safe default while we still ride on
--             Blizzard buttons.
--   "managed" -- TomoMod owns a Cooldown widget and feeds it itself, using
--             the same secret-safe duration-object path as CooldownForge.
--             This is the backend TomoMod-owned buttons will need (Lot A6);
--             it is opt-in now so it can be proven before we depend on it.
--
-- 12.x SAFETY
--   Cooldown durations and charge counts are secret values in Midnight.
--   They are never compared, never used in arithmetic, and only ever handed
--   to a C-side sink: Cooldown:SetCooldownFromDurationObject() for spells
--   and FontString:SetText() for counts. Whether a cooldown is running is
--   determined by "detect-don't-test": feed the duration object, then read
--   the widget's own IsShown() back.
-- =====================================================================

TomoMod_ABRender = TomoMod_ABRender or {}
local R = TomoMod_ABRender

local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- =====================================================================
-- SETTINGS
-- =====================================================================

local DEFAULTS = {
    cooldownBackend    = "native",   -- "native" | "managed"
    countdownNumbers   = true,
    countdownFontSize  = 16,
    swipeColor         = { 0, 0, 0, 0.65 },
    drawEdge           = false,
    drawBling          = true,
    showCount          = true,
    countFontSize      = 12,
    showMacroText      = false,
    macroFontSize      = 8,
    desaturateUnusable = false,
    iconZoom           = 0.07,       -- 0 = no crop, 0.07 = default TomoMod crop
}

R.DEFAULTS = DEFAULTS

local function GetRenderDB()
    if not TomoModDB then return DEFAULTS end
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    local db = TomoModDB.actionBars.render
    if not db then db = {}; TomoModDB.actionBars.render = db end
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then
            if type(v) == "table" then
                local copy = {}
                for i = 1, #v do copy[i] = v[i] end
                db[k] = copy
            else
                db[k] = v
            end
        end
    end
    return db
end

R.GetSettings = GetRenderDB

local function GetBarSettings(barId)
    local AB = TomoMod_ActionBars
    if AB and AB.GetBarDB and barId then
        local ok, res = pcall(AB.GetBarDB, barId)
        if ok and type(res) == "table" then return res end
    end
    return nil
end

-- =====================================================================
-- VISUAL SET
-- =====================================================================

local visuals = {}   -- entry -> vset

-- Neutralises the Blizzard Cooldown widget without hiding it: Blizzard's
-- own code calls Show() on it, so hiding would just start a fight. Alpha 0
-- plus every draw flag off leaves it running but invisible.
local function SuppressWidget(cd)
    if not cd then return end
    pcall(cd.SetAlpha, cd, 0)
    pcall(cd.SetDrawSwipe, cd, false)
    pcall(cd.SetDrawEdge, cd, false)
    pcall(cd.SetDrawBling, cd, false)
    pcall(cd.SetHideCountdownNumbers, cd, true)
end

local function RestoreWidget(cd)
    if not cd then return end
    pcall(cd.SetAlpha, cd, 1)
    pcall(cd.SetDrawSwipe, cd, true)
end

-- The countdown FontString is created lazily by the Cooldown widget itself,
-- so it is restyled opportunistically rather than once at creation.
local function StyleCountdownText(cd, size)
    if not cd or not cd.GetRegions then return end
    local ok, r1, r2, r3 = pcall(cd.GetRegions, cd)
    if not ok then return end
    local regions = { r1, r2, r3 }
    for i = 1, 3 do
        local region = regions[i]
        if region and region.GetObjectType then
            local okType, kind = pcall(region.GetObjectType, region)
            if okType and kind == "FontString" then
                pcall(region.SetFont, region, FONT, size, "OUTLINE")
                return
            end
        end
    end
end

local function EnsureVisuals(entry)
    local vset = visuals[entry]
    if vset then return vset end

    local button = entry.frame
    local icon   = button._tmIcon or button.icon or button.Icon
    if not icon then return nil end

    vset = {
        button   = button,
        icon     = icon,
        blizzCD  = button.cooldown or (button.GetName and _G[(button:GetName() or "") .. "Cooldown"]) or nil,
        blizzCount = button.Count or (button.GetName and _G[(button:GetName() or "") .. "Count"]) or nil,
        blizzName  = button.Name  or (button.GetName and _G[(button:GetName() or "") .. "Name"])  or nil,
    }

    -- Our own count / macro-name text. Owned by TomoMod so that a future
    -- TomoMod button gets them for free without any Blizzard region.
    vset.count = button:CreateFontString(nil, "OVERLAY")
    vset.count:SetFont(FONT, DEFAULTS.countFontSize, "OUTLINE")
    vset.count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    vset.count:SetJustifyH("RIGHT")

    vset.name = button:CreateFontString(nil, "OVERLAY")
    vset.name:SetFont(FONT, DEFAULTS.macroFontSize, "OUTLINE")
    vset.name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
    vset.name:SetJustifyH("CENTER")

    visuals[entry] = vset
    return vset
end

-- Created on demand: only the managed backend needs a Cooldown of our own.
local function EnsureManagedCooldown(vset)
    if vset.cd then return vset.cd end
    local cd = CreateFrame("Cooldown", nil, vset.button, "CooldownFrameTemplate")
    cd:SetAllPoints(vset.icon)
    cd:SetDrawBling(false)
    vset.cd = cd
    return cd
end

-- =====================================================================
-- CONTENT CACHE
-- GetActionInfo + the C_Spell lookups are only redone when the slot's
-- action actually changes, not on every cooldown event.
-- =====================================================================

local function GetContent(entry)
    local ABE = TomoMod_ABEngine
    if ABE and ABE.GetContentCached then return ABE.GetContentCached(entry) end
    return nil
end

local function InvalidateContent(entry)
    local ABE = TomoMod_ABEngine
    if ABE and ABE.InvalidateContent then ABE.InvalidateContent(entry) end
end

-- =====================================================================
-- RENDER PASSES
-- =====================================================================

local function RenderIcon(entry, vset, db)
    local ABE = TomoMod_ABEngine
    local texture = ABE and ABE.GetTexture and ABE.GetTexture(entry) or nil
    if type(texture) ~= "string" or texture == "" then
        local slot = entry and entry.slot
        if type(slot) == "number" and GetActionTexture then
            local direct = GetActionTexture(slot)
            if type(direct) == "string" and direct ~= "" then
                texture = direct
            end
        end
    end

    if type(texture) == "string" and texture ~= "" then
        pcall(vset.icon.SetTexture, vset.icon, texture)
        vset.icon:Show()
    else
        pcall(vset.icon.SetTexture, vset.icon, nil)
        vset.icon:Hide()
    end

    local zoom = db.iconZoom or 0
    if type(zoom) ~= "number" or zoom < 0 or zoom >= 0.5 then zoom = 0 end
    pcall(vset.icon.SetTexCoord, vset.icon, zoom, 1 - zoom, zoom, 1 - zoom)
end

local function RenderCooldown(entry, vset, db)
    local backend = db.cooldownBackend

    if backend ~= "managed" then
        -- Native: Blizzard keeps feeding its own widget, we only restyle it.
        local cd = vset.blizzCD
        if not cd then return end
        if vset.cd then vset.cd:Hide() end
        RestoreWidget(cd)
        pcall(cd.SetDrawEdge, cd, db.drawEdge and true or false)
        pcall(cd.SetDrawBling, cd, db.drawBling and true or false)
        pcall(cd.SetHideCountdownNumbers, cd, not db.countdownNumbers)
        local c = db.swipeColor
        if type(c) == "table" then
            pcall(cd.SetSwipeColor, cd, c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.65)
        end
        if db.countdownNumbers then
            StyleCountdownText(cd, db.countdownFontSize or 16)
        end
        return
    end

    -- Managed: TomoMod owns the widget and feeds it itself.
    SuppressWidget(vset.blizzCD)
    local cd = EnsureManagedCooldown(vset)
    cd:Show()
    pcall(cd.SetDrawEdge, cd, db.drawEdge and true or false)
    pcall(cd.SetDrawBling, cd, db.drawBling and true or false)
    pcall(cd.SetHideCountdownNumbers, cd, not db.countdownNumbers)
    local c = db.swipeColor
    if type(c) == "table" then
        pcall(cd.SetSwipeColor, cd, c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0.65)
    end

    local ABE = TomoMod_ABEngine
    local state = ABE and ABE.GetCooldown and ABE.GetCooldown(entry, GetContent(entry)) or nil

    if not state then
        pcall(cd.Clear, cd)
    elseif state.isSpell then
        -- maxCharges is a plain number, safe to compare. The duration
        -- objects themselves are never inspected, only handed over.
        local durObj = state.durObj
        if state.maxCharges and state.maxCharges > 1 and state.chargeDurObj then
            durObj = state.chargeDurObj
        end
        if durObj then
            pcall(cd.SetCooldownFromDurationObject, cd, durObj)
        else
            pcall(cd.Clear, cd)
        end
    else
        -- Items and pet / stance actions return plain numbers.
        pcall(cd.SetCooldown, cd, state.start or 0, state.duration or 0)
    end

    if db.countdownNumbers then
        StyleCountdownText(cd, db.countdownFontSize or 16)
    end

    -- Detect-don't-test: the widget's own shown flag is the only legal way
    -- to know whether a secret cooldown is running.
    vset.onCooldown = cd:IsShown() and true or false
end

local function RenderCount(entry, vset, db)
    local barDB = GetBarSettings(entry.barId)
    local wanted = db.showCount and (not barDB or barDB.showCountText ~= false)

    if vset.blizzCount then pcall(vset.blizzCount.SetAlpha, vset.blizzCount, 0) end

    if not wanted then
        vset.count:SetText("")
        vset.count:Hide()
        return
    end

    vset.count:SetFont(FONT, db.countFontSize or 12, "OUTLINE")

    local ABE = TomoMod_ABEngine
    local info = ABE and ABE.GetCount and ABE.GetCount(entry, GetContent(entry)) or nil

    -- info.show is derived from GetActionInfo (never secret). info.value may
    -- be a secret and is only ever passed to SetText, which is a C-side sink.
    if info and info.show then
        pcall(vset.count.SetText, vset.count, info.value)
        vset.count:Show()
    else
        vset.count:SetText("")
        vset.count:Hide()
    end
end

local function RenderName(entry, vset, db)
    if vset.blizzName then pcall(vset.blizzName.SetAlpha, vset.blizzName, 0) end

    if not db.showMacroText then
        vset.name:SetText("")
        vset.name:Hide()
        return
    end

    vset.name:SetFont(FONT, db.macroFontSize or 8, "OUTLINE")
    local content = GetContent(entry)
    local text = content and content.macroText
    if type(text) == "string" and text ~= "" then
        vset.name:SetText(text)
        vset.name:Show()
    else
        vset.name:SetText("")
        vset.name:Hide()
    end
end

local function RenderDesaturation(entry, vset, db)
    if not db.desaturateUnusable then
        pcall(vset.icon.SetDesaturated, vset.icon, false)
        return
    end
    -- state.usable is already resolved to a plain boolean by the engine;
    -- nil means "unknown", which must not desaturate.
    local unusable = (entry.state.usable == false)
    pcall(vset.icon.SetDesaturated, vset.icon, unusable)
end

-- =====================================================================
-- PUBLIC
-- =====================================================================

function R.Render(entry, what)
    if not entry then return end
    local vset = EnsureVisuals(entry)
    if not vset then return end
    local db = GetRenderDB()

    if what == nil or what == "all" then
        RenderIcon(entry, vset, db)
        RenderCooldown(entry, vset, db)
        RenderCount(entry, vset, db)
        RenderName(entry, vset, db)
        RenderDesaturation(entry, vset, db)
    elseif what == "cooldown" then
        RenderCooldown(entry, vset, db)
    elseif what == "count" then
        RenderCount(entry, vset, db)
    elseif what == "usable" then
        RenderDesaturation(entry, vset, db)
    end
end

function R.RenderAll(what)
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end
    for entry in ABE.Entries() do
        R.Render(entry, what)
    end
end

-- Called by the config panel after any render setting changes.
function R.ApplySettings()
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end
    for entry in ABE.Entries() do
        InvalidateContent(entry)
        R.Render(entry, "all")
    end
end

function R.GetVisuals(entry) return visuals[entry] end
function R.IsOnCooldown(entry)
    local vset = visuals[entry]
    if not vset then return false end
    if vset.cd then return vset.cd:IsShown() and true or false end
    if vset.blizzCD then return vset.blizzCD:IsShown() and true or false end
    return false
end

-- =====================================================================
-- ENGINE BINDING
-- =====================================================================

local bound = false

local function OnRegister(entry)
    InvalidateContent(entry)
    R.Render(entry, "all")
end

local function OnAction(entry)
    -- The slot's action changed: everything derived from it is now stale.
    InvalidateContent(entry)
    R.Render(entry, "all")
end

local function OnCooldown(entry)
    R.Render(entry, "cooldown")
end

local function OnCount(entry)
    R.Render(entry, "count")
end

local function OnUsable(entry)
    R.Render(entry, "usable")
end

local function OnUnregister(entry)
    local vset = visuals[entry]
    if not vset then return end
    if vset.cd then vset.cd:Hide() end
    if vset.count then vset.count:Hide() end
    if vset.name then vset.name:Hide() end
    RestoreWidget(vset.blizzCD)
    if vset.blizzCount then pcall(vset.blizzCount.SetAlpha, vset.blizzCount, 1) end
    if vset.blizzName then pcall(vset.blizzName.SetAlpha, vset.blizzName, 1) end
    visuals[entry] = nil
end

function R.Bind()
    if bound then return end
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.RegisterCallback then return end
    bound = true
    ABE.RegisterCallback("ABRender", "register",   OnRegister)
    ABE.RegisterCallback("ABRender", "unregister", OnUnregister)
    ABE.RegisterCallback("ABRender", "action",     OnAction)
    ABE.RegisterCallback("ABRender", "cooldown",   OnCooldown)
    ABE.RegisterCallback("ABRender", "count",      OnCount)
    ABE.RegisterCallback("ABRender", "usable",     OnUsable)
end

function R.IsBound() return bound end

-- =====================================================================
-- BOOT
-- Binds before AB_Engine enables itself (engine boots at login + 1.0s),
-- so the initial "register" burst is already rendered.
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(0.9, function()
        R.Bind()
    end)
end)
