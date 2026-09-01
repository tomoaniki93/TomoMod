-- =====================================
-- Utils.lua — Utility Functions
-- Backward compatible with all QOL modules
-- =====================================

-- [PERF] Local caching of stdlib functions used in hot paths
local pairs, type, tostring, select = pairs, type, tostring, select
local format = string.format
local gsub = string.gsub
local floor = math.floor

-- Keep global namespace for QOL backward compat
TomoMod_Utils = TomoMod_Utils or {}
local U = TomoMod_Utils

-- =====================================
-- BRAND COLOR  (single source of truth)
-- =====================================
-- TomoMod brand accent. To recolor the whole UI, change these three values.
-- BRAND_HEX feeds the |cff color codes; BRAND / BRAND_DARK feed all float
-- (r, g, b) accents across the suite.
U.BRAND_HEX   = "2ed884"                    -- #2ED884
U.BRAND       = { 0.180, 0.847, 0.518 }     -- #2ED884  (mint accent)
U.BRAND_HOVER = { 0.322, 0.941, 0.651 }     -- lighter shade for hover states
U.BRAND_DARK  = { 0.110, 0.541, 0.333 }     -- darker shade for pressed states

-- =====================================
-- STATIC POPUP COMPAT  (11.2 rewrite)
-- =====================================
-- Blizzard rebuilt StaticPopup on a mixin in 11.2: the dialog's direct
-- fields (.editBox, .button1, ...) were replaced by accessors
-- (:GetEditBox(), :GetButton1()). Reading `dialog.editBox` now returns
-- nil, so every OnAccept that fetched the typed text silently did
-- nothing (or threw). These helpers resolve the edit box on both the old
-- and the new shape, plus the global-name fallback that still works.

-- =====================================
-- MIDNIGHT SECRET-SAFE GROUP ROLE
-- =====================================
-- UnitGroupRolesAssigned() may return a secret string in restricted content.
-- Any Lua comparison or table lookup on that value can throw. Keep the entire
-- read + validation inside pcall so even a value not flagged by issecretvalue()
-- fails closed instead of escaping into callers.
function U.SafeGroupRole(unit)
    if type(UnitGroupRolesAssigned) ~= "function" then return nil end

    local ok, role = pcall(function()
        local value = UnitGroupRolesAssigned(unit)
        if type(issecretvalue) == "function" and issecretvalue(value) then
            return nil
        end
        if value == "TANK" or value == "HEALER" or value == "DAMAGER" or value == "NONE" then
            return value
        end
        return nil
    end)

    if not ok then return nil end
    return role
end

--- Close a window on Escape WITHOUT UISpecialFrames.
---
--- Registering a frame in UISpecialFrames routes Escape through Blizzard's
--- ToggleGameMenu, which then calls the protected SpellStopCasting(),
--- SpellStopTargeting() and ClearTarget(). If any addon has tainted the
--- execution by then, all three are refused with ADDON_ACTION_FORBIDDEN and
--- the game menu never opens -- the player simply cannot quit with Escape.
---
--- ForgeStudio.lua already solved this; this is the same fix, factored out so
--- every window shares one implementation instead of nine copies.
---
--- Escape is consumed, every other key propagates so game shortcuts keep
--- working. SetPropagateKeyboardInput is itself protected, hence the combat
--- guard: in combat all keys propagate and the window stays open.
function U.CloseOnEscape(frame, onEscape)
    if type(frame) ~= "table" or not frame.EnableKeyboard then return end

    -- [FIX] A frame with EnableKeyboard(true) swallows every key unless it
    -- explicitly propagates, and propagation defaults to false. The old
    -- handler only propagated as a side effect of handling a key, and
    -- returned early in combat without propagating at all -- so while one
    -- of these windows was open the player could not move, and closing
    -- with Escape left propagation off for the next time it opened.
    --
    -- The rule now: propagate first, always. Escape is the only key this
    -- helper consumes, and only outside combat, where hiding is safe.
    -- [FIX] SetPropagateKeyboardInput is itself protected, so the combat check
    -- has to come FIRST. It used to sit after the call, which meant every
    -- keypress with one of these windows open in combat produced an
    -- ADDON_ACTION_BLOCKED -- one per key, so holding a movement key filled
    -- the error log.
    --
    -- Returning early is safe because propagation is a persistent frame state,
    -- not something re-established per keypress: it is set true below and only
    -- ever flipped to false to swallow an Escape, which cannot happen in
    -- combat. So in combat the frame is already propagating and there is
    -- nothing to do.
    frame:SetScript("OnKeyDown", function(self, key)
        if InCombatLockdown() then return end
        self:SetPropagateKeyboardInput(true)
        if key ~= "ESCAPE" then return end
        self:SetPropagateKeyboardInput(false)
        if onEscape then onEscape(self) else self:Hide() end
    end)

    -- Hold the keyboard only while visible. A hidden frame that still
    -- claims keyboard input is how a closed window keeps eating keys.
    --
    -- Propagation is reset on show, not on hide. OnHide runs synchronously
    -- inside the Escape keypress that closed the window, so re-opening
    -- propagation there would hand that same Escape on to the game menu.
    frame:HookScript("OnShow", function(self)
        self:EnableKeyboard(true)
        -- Same protection applies here. A window opened mid-combat keeps the
        -- propagation it already had, which the line below guarantees is true.
        if not InCombatLockdown() then
            self:SetPropagateKeyboardInput(true)
        end
    end)
    frame:HookScript("OnHide", function(self) self:EnableKeyboard(false) end)

    -- Establish propagation once, here, while the window is being built --
    -- which is out of combat for every caller. Without this a frame whose
    -- first ever Show happens in combat would swallow every key, since both
    -- guarded paths above would decline to set it.
    if not InCombatLockdown() then
        frame:SetPropagateKeyboardInput(true)
    end
    frame:EnableKeyboard(frame:IsShown() and true or false)
end

--- Returns the edit box of a StaticPopup dialog, or nil.
function U.PopupEditBox(dialog)
    if not dialog then return nil end
    if dialog.GetEditBox then
        local ok, box = pcall(dialog.GetEditBox, dialog)
        if ok and box then return box end
    end
    if dialog.editBox then return dialog.editBox end
    local name = dialog.GetName and dialog:GetName()
    if name then return _G[name .. "EditBox"] end
    return nil
end

--- Text currently typed in a StaticPopup edit box ("" when unavailable).
function U.PopupText(dialog)
    local box = U.PopupEditBox(dialog)
    if not (box and box.GetText) then return "" end
    local ok, txt = pcall(box.GetText, box)
    if not ok or type(txt) ~= "string" then return "" end
    return txt
end

--- Dialog owning an edit box. Since 11.2 the edit box carries
--- `owningDialog`; the parent chain is no longer a reliable route.
function U.PopupDialogOf(editBox)
    if not editBox then return nil end
    if editBox.owningDialog then return editBox.owningDialog end
    if editBox.GetParent then return editBox:GetParent() end
    return nil
end

--- Runs the OnAccept of `which` against `dialog`, then closes it. Used by
--- EditBoxOnEnterPressed so Enter behaves exactly like the accept button.
function U.PopupAccept(which, dialog)
    if not dialog then return end
    local info = StaticPopupDialogs and StaticPopupDialogs[which]
    if info and info.OnAccept then
        info.OnAccept(dialog, dialog.data, dialog.data2)
    end
    if dialog.Hide then dialog:Hide() end
end

-- =====================================
-- WINDOW LAYERING
-- =====================================
-- The config GUI and the Cooldown Studio both sit at FULLSCREEN_DIALOG
-- with a high frame level, so anything using the default popup layer
-- renders *behind* them and looks like nothing happened. Lifts `frame`
-- above whichever TomoMod window is currently open.
local RAISE_ABOVE = { "TomoModConfigFrame", "TomoModCDStudioFrame" }

function U.RaiseAboveTomoUI(frame)
    if not (frame and frame.SetFrameStrata and frame.SetFrameLevel) then return end
    if frame._tomomodPrevStrata == nil then
        frame._tomomodPrevStrata   = frame:GetFrameStrata()
        frame._tomomodPrevLevel    = frame:GetFrameLevel()
        frame._tomomodPrevToplevel = frame.IsToplevel and frame:IsToplevel() or false
    end
    local level = 0
    for i = 1, #RAISE_ABOVE do
        local f = _G[RAISE_ABOVE[i]]
        if f and f.IsShown and f:IsShown() and f.GetFrameLevel then
            local l = f:GetFrameLevel() or 0
            if l > level then level = l end
        end
    end
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(level + 40)
    if frame.SetToplevel then frame:SetToplevel(true) end
    if frame.Raise then frame:Raise() end
end

--- Puts a recycled frame (StaticPopup1..4 are shared with Blizzard) back
--- on the layer it had before U.RaiseAboveTomoUI touched it.
function U.RestoreTomoUILayer(frame)
    if not (frame and frame._tomomodPrevStrata) then return end
    frame:SetFrameStrata(frame._tomomodPrevStrata)
    frame:SetFrameLevel(frame._tomomodPrevLevel or 1)
    if frame.SetToplevel then frame:SetToplevel(frame._tomomodPrevToplevel and true or false) end
    frame._tomomodPrevStrata, frame._tomomodPrevLevel, frame._tomomodPrevToplevel = nil, nil, nil
end

-- =====================================
-- TABLE UTILITIES
-- =====================================

function TomoMod_MergeTables(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then
                dest[k] = {}
            end
            TomoMod_MergeTables(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

function U.DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = U.DeepCopy(v)
    end
    return copy
end

-- =====================================
-- COLOR UTILITIES
-- =====================================

-- =====================================================================
-- SECRET VALUES
--
-- [12.1] The client hands out more and more values an addon may not read.
-- A secret is not nil: it is a live value that throws the moment Lua
-- compares it, indexes with it, concatenates it or tests it as a boolean.
-- The guard therefore has to run BEFORE the operation, never after.
-- =====================================================================

-- True when the client refuses to let us read this value.
function U.IsSecret(v)
    -- `v == nil` is a comparison, and comparing a secret is exactly what
    -- throws -- so the guard was sabotaging itself on the one input it
    -- exists for. type() is the only presence test safe on a secret.
    if type(v) == "nil" then return false end
    local builtin = rawget(_G, "issecretvalue")
    if type(builtin) ~= "function" then return false end
    local ok, secret = pcall(builtin, v)
    return ok and secret and true or false
end

-- Returns the value only if it is a readable string, else nil. Callers
-- must treat nil as "cannot know", not as "absent".
function U.SafeStr(v)
    if type(v) == "nil" or U.IsSecret(v) then return nil end
    return type(v) == "string" and v or nil
end

-- The unit's class token, or nil when the client will not say.
--
-- UnitClassBase is preferred: it returns the token directly, so there is
-- no select() dance, and it is the call the nameplate and health colour
-- paths already used.
function U.UnitClassToken(unit)
    if not unit then return nil end
    local token
    if UnitClassBase then
        token = U.SafeStr(UnitClassBase(unit))
    end
    if not token and UnitClass then
        token = U.SafeStr(select(2, UnitClass(unit)))
    end
    return token
end

-- Class colour for a unit, or nil when the class is unreadable.
--
-- Returning nil rather than grey is deliberate: grey is a real colour a
-- caller may legitimately want, and callers differ on what to do when the
-- class is unknown -- the health bar falls back to a faction colour, which
-- is far more useful than a grey bar.
function U.TryClassColor(unit)
    local class = U.UnitClassToken(unit or "player")
    if not class then return nil end
    -- Only index the table once the key is known readable: indexing with a
    -- secret key throws inside Blizzard's own table, not here.
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not c then return nil end
    return c.r, c.g, c.b, 1
end

function U.GetClassColor(unit)
    local r, g, b, a = U.TryClassColor(unit or "player")
    if r then return r, g, b, a end
    return 0.5, 0.5, 0.5, 1
end

-- =====================================================================
-- AURA ACCESS PROBE
--
-- [12.1] Aura reads do not return nil when the client is withholding
-- them: they throw. Wrapping each read in pcall stops the error but keeps
-- paying for it -- dozens of protected calls per frame in a dungeon, and
-- a half-filled aura row when some reads land and others do not.
--
-- Asking once per frame is cheaper, and it removes the half-filled row: a
-- refused frame is skipped whole rather than scanned until the first read
-- that fails, so what is drawn is complete or empty, never a mixture. It
-- does not preserve the previous frame -- an indicator whose scan read
-- nothing still goes dark, exactly as it did before the probe existed.
--
-- InCombatLockdown alone is not the same question: auras are also
-- withheld between pulls in protected instances, which is exactly where
-- the scans were failing.
-- =====================================================================

local _auraProbeStamp, _auraProbeResult = nil, false

-- True when the client will refuse aura reads right now.
--
-- The answer is cached for the current frame. Restriction does not change
-- within a frame, and the probe itself is an aura read -- the one we are
-- willing to spend.
function U.AurasRestricted()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return true end

    local now = GetTime and GetTime() or nil
    if now and now == _auraProbeStamp then return _auraProbeResult end

    -- Index 1 on the player: the cheapest read that exercises the same
    -- restriction as every scan below.
    local ok = pcall(C_UnitAuras.GetAuraDataByIndex, "player", 1, "HELPFUL")
    _auraProbeStamp  = now
    _auraProbeResult = not ok
    return _auraProbeResult
end

-- Convenience for the common shape: `if U.AurasReadable() then ... end`.
function U.AurasReadable()
    return not U.AurasRestricted()
end

-- =====================================================================
-- CLASS COLOUR THAT SURVIVES A SECRET CLASS
--
-- TryClassColor above returns nil when the client hides the class, and the
-- caller falls back to a faction colour. That is correct but lossy: the
-- class colour is simply gone on exactly the units a dungeon is full of.
--
-- C_ClassColor.GetClassColor is C-side and accepts a secret token. What it
-- gives back is a colour object whose GetRGB is also C-side, so the numbers
-- can be handed straight to another C-side setter -- SetStatusBarColor,
-- SetTextColor, SetVertexColor -- without ever being read in Lua.
--
-- That is the whole trick, and its limit: this works only where the colour
-- goes directly into a setter. Anything that wants to darken, blend or
-- compare has to read the numbers, and there is no way around the fallback.
-- =====================================================================

-- Presence test that is safe on a secret value.
--
-- `if x` is a boolean test and throws on a secret; type(x) does not. Every
-- guard on a possibly-secret value has to be written this way.
function U.Exists(v)
    return type(v) ~= "nil"
end

-- Colour object for a unit's class, or nil.
--
-- Unlike TryClassColor this succeeds on a secret class: the token is never
-- read, only forwarded. The returned object's channels may themselves be
-- secret, which is why the result is meant for ApplyClassColor below rather
-- than for arithmetic.
function U.ClassColorObject(unit)
    if not unit or not C_ClassColor or not C_ClassColor.GetClassColor then return nil end

    local token
    if UnitClassBase then token = UnitClassBase(unit) end
    if not U.Exists(token) and UnitClass then token = select(2, UnitClass(unit)) end
    if not U.Exists(token) then return nil end

    local ok, colour = pcall(C_ClassColor.GetClassColor, token)
    if not ok or not colour or not colour.GetRGB then return nil end
    return colour
end

-- Paints `region` with the unit's class colour, passing the channels
-- straight from one C function to the other.
--
-- `setter` is the method name: "SetStatusBarColor", "SetTextColor",
-- "SetVertexColor". Returns true when the colour was applied, so the caller
-- can fall back on false rather than guessing.
function U.ApplyClassColor(region, unit, setter)
    if not region or not setter then return false end
    local fn = region[setter]
    if type(fn) ~= "function" then return false end

    local colour = U.ClassColorObject(unit)
    if not colour then return false end

    -- Both calls are protected, and neither allocates: a closure per call
    -- would be real GC pressure on forty raid frames refreshing constantly,
    -- in a module that carries [PERF] notes about reusing tables.
    local ok, r, g, b = pcall(colour.GetRGB, colour)
    if not ok then return false end
    return (pcall(fn, region, r, g, b)) and true or false
end

function U.GetPowerColor(powerType)
    local info = PowerBarColor[powerType]
    if info then
        return info.r, info.g, info.b
    end
    return 0.5, 0.5, 0.5
end

function U.GetReactionColor(unit)
    local reaction = UnitReaction(unit, "player")
    if not reaction then return 0.5, 0.5, 0.5 end
    if reaction >= 5 then return 0.11, 0.82, 0.11 end
    if reaction == 4 then return 0.98, 0.82, 0.11 end
    return 0.78, 0.04, 0.04
end

function U.HexColor(r, g, b)
    return format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function U.ColorText(text, r, g, b)
    return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

function U.ClassColorText(text, unit)
    local r, g, b = U.GetClassColor(unit or "player")
    return U.ColorText(text, r, g, b)
end

-- =====================================
-- NUMBER FORMATTING
-- =====================================

function U.FormatNumber(num)
    if not num then return "0" end
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

function U.AbbreviateNumber(num)
    if not num then return "0" end
    if num >= 1000000000 then
        return format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return format("%.1fK", num / 1000)
    else
        return tostring(floor(num))
    end
end

function U.FormatTime(seconds)
    if not seconds or seconds <= 0 then return "" end
    if seconds >= 86400 then
        return format("%dd", floor(seconds / 86400))
    elseif seconds >= 3600 then
        return format("%dh", floor(seconds / 3600))
    elseif seconds >= 60 then
        return format("%dm", floor(seconds / 60))
    elseif seconds >= 10 then
        return format("%d", floor(seconds))
    else
        return format("%.1f", seconds)
    end
end

-- =====================================
-- FRAME POSITION UTILITIES
-- =====================================

function U.SaveFramePosition(frame, dbTable)
    if not frame or not dbTable then return end
    local point, _, relativePoint, x, y = frame:GetPoint()
    dbTable.point = point or "CENTER"
    dbTable.relativePoint = relativePoint or "CENTER"
    dbTable.x = x or 0
    dbTable.y = y or 0
end

function U.ApplyFramePosition(frame, dbTable)
    if not frame or not dbTable then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        dbTable.point or "CENTER",
        UIParent,
        dbTable.relativePoint or "CENTER",
        dbTable.x or 0,
        dbTable.y or 0
    )
end

function U.ResetFramePosition(frame, defaultPoint, defaultRelativePoint, defaultX, defaultY)
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint(
        defaultPoint or "CENTER",
        UIParent,
        defaultRelativePoint or "CENTER",
        defaultX or 0,
        defaultY or 0
    )
end

-- =====================================
-- LOCK/UNLOCK DRAG SYSTEM
-- =====================================

-- [PERF] Constant color tables — shared by all draggable frames
local DRAG_ACCENT = { U.BRAND[1], U.BRAND[2], U.BRAND[3] }
local DRAG_BG_COL = { 0.02, 0.07, 0.05, 0.80 }
local DRAG_BD_COL = { U.BRAND[1], U.BRAND[2], U.BRAND[3], 0.60 }

function U.SetupDraggable(frame, savePositionCallback, labelText)
    if not frame then return end
    frame.isLocked = true
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local ACCENT = DRAG_ACCENT
    local BG_COL = DRAG_BG_COL
    local BD_COL = DRAG_BD_COL

    local dragFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    dragFrame:SetAllPoints(frame)
    dragFrame:SetFrameLevel(frame:GetFrameLevel() + 20)
    dragFrame:EnableMouse(false)
    dragFrame:Hide()

    dragFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dragFrame:SetBackdropColor(BG_COL[1], BG_COL[2], BG_COL[3], BG_COL[4])
    dragFrame:SetBackdropBorderColor(BD_COL[1], BD_COL[2], BD_COL[3], BD_COL[4])

    local accentLine = dragFrame:CreateTexture(nil, "OVERLAY")
    accentLine:SetHeight(1)
    accentLine:SetPoint("TOPLEFT",  dragFrame, "TOPLEFT",  0, 0)
    accentLine:SetPoint("TOPRIGHT", dragFrame, "TOPRIGHT", 0, 0)
    accentLine:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)

    local dragLabel = dragFrame:CreateFontString(nil, "OVERLAY")
    dragLabel:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 11, "OUTLINE")
    dragLabel:SetPoint("CENTER", dragFrame, "CENTER")
    dragLabel:SetTextColor(1, 1, 1, 0.90)
    -- The fallback used to be a hardcoded French "Déplacer", which every
    -- unit frame and the resource bar container got because they passed
    -- no label: six overlays on screen at once, all reading the same
    -- word, none of them saying which frame was under the cursor. Callers
    -- now pass a name from TomoMod_Layout.Label(); the remaining fallback
    -- is the generic verb in the player's own language.
    dragLabel:SetText(labelText or (TomoMod_L and TomoMod_L["mover_generic"]) or "Move")
    frame.dragLabel = dragLabel

    --- Lets a caller rename the overlay after creation -- boss frames are
    --- spawned from one factory and only learn their index afterwards.
    frame.SetDragLabel = function(_, text)
        if text then dragLabel:SetText(text) end
    end

    dragFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartMoving()
            self:SetBackdropBorderColor(1, 1, 1, 1)
        end
    end)
    dragFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
            self:SetBackdropBorderColor(BD_COL[1], BD_COL[2], BD_COL[3], BD_COL[4])
            if savePositionCallback then savePositionCallback() end
        end
    end)
    dragFrame:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        dragLabel:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3], 1)
    end)
    dragFrame:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(BD_COL[1], BD_COL[2], BD_COL[3], BD_COL[4])
        dragLabel:SetTextColor(1, 1, 1, 0.90)
    end)

    frame.dragFrame = dragFrame

    frame.SetLocked = function(self, locked)
        self.isLocked = locked
        if locked then
            dragFrame:EnableMouse(false)
            dragFrame:Hide()
        else
            dragFrame:EnableMouse(true)
            dragFrame:Show()
            self:SetAlpha(1)
            self:Show()
        end
    end

    frame.IsLocked = function(self)
        return self.isLocked
    end

    frame:SetLocked(true)
    return frame
end

-- =====================================
-- TOOLTIP TAINT GUARD (Midnight 12.x secret-money safety)
-- =====================================
-- In 12.x an item's sell price is a *secret* number. Blizzard's
-- MoneyFrame_Update does arithmetic on it, which is only legal while the
-- execution is untainted. Item-comparison tooltips (EncounterJournal,
-- ShoppingTooltip1/2, ...) render that secret money frame, so any TomoMod
-- injection or restyle that runs on them taints the arithmetic and throws
-- ("attempt to perform arithmetic on a secret number value … tainted by
-- 'TomoMod'"). Tooltip modules call this to skip those tooltips while
-- keeping their features on normal item tooltips. Single extension point:
-- add other compare/money sources here if they surface.
function TomoMod_IsCompareOrMoneyTooltip(tt)
    if not tt then return false end

    -- Dedicated item-comparison (shopping) tooltips
    if tt == _G.ShoppingTooltip1 or tt == _G.ShoppingTooltip2 then
        return true
    end

    -- Owner inside the Encounter Journal (compare tooltip w/ secret sell price)
    local ok, owner = pcall(tt.GetOwner, tt)
    if ok and owner then
        local frame = owner
        for _ = 1, 6 do
            if not frame then break end
            local okn, name = pcall(frame.GetName, frame)
            if okn and type(name) == "string"
                and name:find("EncounterJournal", 1, true) then
                return true
            end
            local okp, parent = pcall(frame.GetParent, frame)
            if not okp then break end
            frame = parent
        end
    end

    return false
end

-- =====================================
-- BACKWARD COMPAT: CreateSlider / CreateCheckbox
-- (used by old Config.lua and some QOL modules)
-- =====================================

function U.CreateSlider(parent, name, point, x, y, minVal, maxVal, step, width, label, callback)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint(point, x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(width)
    _G[name .. "Low"]:SetText(minVal)
    _G[name .. "High"]:SetText(maxVal)
    _G[name .. "Text"]:SetText(label)
    if callback then
        slider:SetScript("OnValueChanged", callback)
    end
    return slider
end

function U.CreateCheckbox(parent, point, x, y, text, checked, callback)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint(point, x, y)
    checkbox:SetChecked(checked)
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText(text)
    if callback then
        checkbox:SetScript("OnClick", callback)
    end
    return checkbox
end

-- =====================================
-- DEBUG
-- =====================================

function U.Debug(...)
    if TomoModDB and TomoModDB.debug then
        print("|cff00ff00[TomoMod Debug]|r", ...)
    end
end

function U.DumpTable(tbl, indent)
    indent = indent or 0
    local formatting = string.rep("  ", indent)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(formatting .. tostring(k) .. ":")
            U.DumpTable(v, indent + 1)
        else
            print(formatting .. tostring(k) .. " = " .. tostring(v))
        end
    end
end
