-- =====================================================================
-- ModuleReloadUI.lua — Prompt and banner for pending reloads (v4 Lot 1)
-- ---------------------------------------------------------------------
-- Kept apart from Core/ModuleLifecycle.lua on purpose. The engine owns
-- what is waiting; this file owns how it is shown, and lot 7 rewrites
-- how things are shown. Splitting them now means the rewrite touches
-- one file rather than picking presentation out of an engine.
--
-- Two surfaces, answering two different questions:
--
--   The dialog  asks "now or later?" once per batch, raised above the
--               rest of the interface and anchored near the top of the
--               screen so it cannot be lost behind the config window
--               the player was just clicking in.
--   The banner  answers "what did I put off?" It lists the modules that
--               are waiting, so a player who chose "later" is never
--               looking at a checkbox that quietly disagrees with what
--               is actually running.
--
-- The banner reads the engine through a callback rather than polling:
-- nothing here runs on a timer.
-- =====================================================================

local LC = TomoMod_Lifecycle
if not LC then return end

TomoMod_ReloadUI = TomoMod_ReloadUI or {}
local UI = TomoMod_ReloadUI

local POPUP = "TOMOMOD_LIFECYCLE_RELOAD"

-- ---------------------------------------------------------------------
-- LABELS
-- ---------------------------------------------------------------------

local function L(key, fallback)
    local t = TomoMod_L
    if not t then return fallback end
    local v = t[key]
    -- The localisation metatable hands back the raw key when it does not
    -- know one, so an unresolved key looks like "mod_reload_title" on
    -- screen. Catch that here rather than show it.
    if v == nil or v == key then return fallback end
    return v
end

--- Human-readable list of what is waiting, truncated so a player who
--- toggled twenty things does not get a dialog taller than the screen.
local function PendingText(limit)
    local keys = LC.PendingReload()
    if #keys == 0 then return "" end
    limit = limit or 6
    local names, R = {}, TomoMod_Registry
    for i = 1, math.min(#keys, limit) do
        local m = R and R.Get(keys[i])
        names[i] = (m and L(m.label, m.key)) or keys[i]
    end
    local text = table.concat(names, ", ")
    if #keys > limit then
        text = text .. (" (+%d)"):format(#keys - limit)
    end
    return text
end

-- ---------------------------------------------------------------------
-- DIALOG
-- ---------------------------------------------------------------------
-- Registered under its own key rather than reusing TOMOMOD_MODULE_RELOAD
-- so the older popup keeps working untouched for anything still calling
-- it directly.
-- ---------------------------------------------------------------------

StaticPopupDialogs[POPUP] = {
    text = "|cff2ed884TomoMod|r\n%s\n\n|cff888888%s|r",
    button1 = L("mod_reload_now", "Reload now"),
    button2 = L("mod_reload_later", "Later"),
    OnShow = function(self)
        -- Raised above the config window the player was clicking in.
        -- FULLSCREEN_DIALOG rather than TOOLTIP: TOOLTIP is the higher
        -- strata but it is where tooltips live, and a dialog drawn over
        -- them reads as a rendering fault rather than as emphasis.
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:SetToplevel(true)
        self:Raise()

        -- Blizzard positions popups in a stack from the top of the
        -- screen downward, and re-runs that placement after OnShow when
        -- several are open. Re-asserting on the next frame wins that
        -- race without hooking anything of Blizzard's.
        local function Place()
            if not self:IsShown() then return end
            self:ClearAllPoints()
            self:SetPoint("TOP", UIParent, "TOP", 0, -140)
        end
        Place()
        if C_Timer and C_Timer.After then C_Timer.After(0, Place) end
    end,
    OnAccept = function()
        LC.ClearReload()
        ReloadUI()
    end,
    OnCancel = function()
        -- Deliberately keeps the queue: "later" is not "never", and the
        -- banner is what remembers it.
        UI.RefreshBanner()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--- Feeds the dialog its two lines at show time. StaticPopup_Show's
--- arg1/arg2 fill the %s placeholders.
local function ShowDialog()
    if LC.PendingReloadCount() == 0 then return end
    StaticPopup_Show(POPUP,
        L("mod_reload_prompt", "This change needs a UI reload to take effect."),
        PendingText(6))
end
UI.ShowDialog = ShowDialog

-- ---------------------------------------------------------------------
-- BANNER
-- ---------------------------------------------------------------------

local banner
local dismissed = false   -- hidden by the player, queue untouched

local function BuildBanner()
    if banner then return banner end

    local f = CreateFrame("Frame", "TomoModReloadBanner", UIParent, "BackdropTemplate")
    f:SetSize(460, 40)
    f:SetPoint("TOP", UIParent, "TOP", 0, -8)
    f:SetFrameStrata("HIGH")
    f:Hide()

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.06, 0.06, 0.07, 0.94)
        f:SetBackdropBorderColor(0.18, 0.85, 0.52, 0.85)
    end

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", f, "LEFT", 12, 0)
    text:SetPoint("RIGHT", f, "RIGHT", -170, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    f.text = text

    local reload = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reload:SetSize(96, 22)
    reload:SetPoint("RIGHT", f, "RIGHT", -34, 0)
    reload:SetText(L("mod_reload_now", "Reload now"))
    reload:SetScript("OnClick", function()
        LC.ClearReload()
        ReloadUI()
    end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetPoint("RIGHT", f, "RIGHT", -4, 0)
    close:SetScript("OnClick", function()
        dismissed = true
        f:Hide()
    end)

    banner = f
    return f
end

--- Redraws from the engine's current state. Cheap enough to call on
--- every change; it does nothing at all while nothing is waiting.
function UI.RefreshBanner()
    local n = LC.PendingReloadCount()
    if n == 0 then
        dismissed = false          -- a fresh batch deserves a fresh banner
        if banner then banner:Hide() end
        return
    end
    if dismissed then return end

    local f = BuildBanner()
    local label = (n == 1)
        and L("mod_pending_one",  "1 module is waiting for a reload:")
        or  L("mod_pending_many", "%d modules are waiting for a reload:"):format(n)
    f.text:SetText("|cff2ed884TomoMod|r  " .. label .. " |cffaaaaaa" .. PendingText(4) .. "|r")
    f:Show()
end

--- Re-parents the banner, for the config window to host it instead of
--- UIParent once lot 7 has somewhere sensible to put it.
function UI.AttachBanner(parent, point, relPoint, x, y)
    local f = BuildBanner()
    f:SetParent(parent or UIParent)
    f:ClearAllPoints()
    f:SetPoint(point or "TOP", parent or UIParent, relPoint or "TOP", x or 0, y or -8)
    return f
end

-- ---------------------------------------------------------------------
-- WIRING
-- ---------------------------------------------------------------------
-- The engine owns the debounce and the combat hold; by the time it calls
-- back, showing is the only thing left to decide.

LC.OnPendingChanged(function()
    UI.RefreshBanner()
end)

LC.SetPromptHandler(ShowDialog)
