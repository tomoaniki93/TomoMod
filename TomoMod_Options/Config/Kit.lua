-- =====================================================================
-- Config/Kit.lua -- TomoMod GUI v2 toolkit
--
-- Everything the new pages share, so each page file only describes WHAT
-- it offers and never HOW it is wired:
--
--   * T(fr, en)          bilingual labels written inline (frFR + English)
--   * path bindings      "unitFrames.player.width" reads/writes the DB and
--                        knows its default (Ctrl+click on a slider resets)
--   * K.Apply(key)       live apply, coalesced, deferred out of combat for
--                        anything that touches protected frames
--   * K.Locate(target)   golden pulse around the real frame on screen
--   * previews           party / raid / castbar previews while a page is open
--   * K.Page(...)        card-based page builder with a simple / expert mode
--
-- Replaces the four LoadOnDemand Studios: nothing here opens another
-- window, every setting is applied to the live UI immediately.
-- =====================================================================

TomoMod_Kit = TomoMod_Kit or {}
local K = TomoMod_Kit
local W = TomoMod_Widgets
local TH = W.Theme

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE     = "Interface\\Buttons\\WHITE8x8"
K.FONT, K.FONT_BOLD, K.WHITE = FONT, FONT_BOLD, WHITE

-- ---------------------------------------------------------------------
-- Language
-- ---------------------------------------------------------------------
K.IS_FR = (GetLocale and GetLocale() == "frFR") and true or false
function K.T(fr, en)
    if TomoMod_GUIT then return TomoMod_GUIT(fr, en) end
    if K.IS_FR then return fr end
    return en or fr
end
local T = K.T

-- ---------------------------------------------------------------------
-- Path bindings
-- ---------------------------------------------------------------------
local splitCache = {}
local function Split(path)
    local parts = splitCache[path]
    if parts then return parts end
    parts = {}
    for seg in string.gmatch(path, "[^%.]+") do
        parts[#parts + 1] = seg
    end
    splitCache[path] = parts
    return parts
end

-- A digit segment names a string key ("raidSizeOverrides.10") in
-- TomoMod's tables, or an array index: take whichever the table has.
local function Key(node, seg)
    if node[seg] ~= nil then return seg end
    local n = tonumber(seg)
    if n and node[n] ~= nil then return n end
    return seg
end

local function Walk(root, path, create)
    if type(root) ~= "table" then return nil end
    local parts = Split(path)
    local node = root
    for i = 1, #parts - 1 do
        local k = Key(node, parts[i])
        local nxt = node[k]
        if type(nxt) ~= "table" then
            if not create then return nil end
            nxt = {}
            node[k] = nxt
        end
        node = nxt
    end
    return node, Key(node, parts[#parts])
end

function K.Get(path, root)
    local node, key = Walk(root or TomoModDB, path, false)
    if node == nil then return nil end
    return node[key]
end

function K.Set(path, value, root)
    local node, key = Walk(root or TomoModDB, path, true)
    if node then node[key] = value end
end

function K.Default(path)
    return K.Get(path, TomoMod_Defaults)
end

-- A binding is either a dotted path or { get = fn, set = fn, default = v }.
local function Bind(b)
    if type(b) == "table" then
        return b.get, b.set, b.default
    end
    return function() return K.Get(b) end,
           function(v) K.Set(b, v) end,
           K.Default(b)
end
K.Bind = Bind

function K.GuiDB()
    if not TomoModDB then return {} end
    TomoModDB.configGUI = TomoModDB.configGUI or {}
    return TomoModDB.configGUI
end

-- Window animations (page glide, toast, tiles). On unless turned off.
function K.Animated() return K.GuiDB().animations ~= false end

-- ---------------------------------------------------------------------
-- Toast (the shell gives us a host FontString)
-- ---------------------------------------------------------------------
local toastHost
function K.SetToastHost(fs) toastHost = fs end

function K.Toast(text, r, g, b)
    if not toastHost then return end
    local wasShown = toastHost:IsShown()
    toastHost:SetText(text or "")
    toastHost:SetTextColor(r or TH.accent[1], g or TH.accent[2], b or TH.accent[3], 1)
    toastHost:SetAlpha(1)
    toastHost:Show()
    toastHost._until = GetTime() + 1.6
    -- Slides in once; a burst of slider steps only refreshes the text.
    if not wasShown and K.Animated() and TomoMod_Utils.SlideIn then TomoMod_Utils.SlideIn(toastHost, 0, -8, 0.22) end
    if not toastHost._ticking then
        toastHost._ticking = true
        local parent = toastHost:GetParent()
        parent:SetScript("OnUpdate", function(self)
            local left = (toastHost._until or 0) - GetTime()
            if left <= 0 then
                toastHost:Hide()
                toastHost._ticking = false
                self:SetScript("OnUpdate", nil)
            elseif left < 0.5 then
                toastHost:SetAlpha(left / 0.5)
            end
        end)
    end
end

-- ---------------------------------------------------------------------
-- Live apply
-- ---------------------------------------------------------------------
-- Keys are "name" or "name:arg" (uf:player). Sliders fire on every step:
-- requests are coalesced and flushed on the next frame. Anything flagged
-- `secure` resizes protected frames, which the client refuses in combat,
-- so it waits for PLAYER_REGEN_ENABLED instead of half-applying.
local appliers = {}
local queued, deferred = {}, {}
local flushScheduled = false

function K.RegisterApplier(name, fn, secure)
    appliers[name] = { fn = fn, secure = secure and true or false }
end

local function Run(key)
    local name, arg = key:match("^([^:]+):?(.*)$")
    local a = appliers[name]
    if not a then return true end
    if a.secure and InCombatLockdown() then
        deferred[key] = true
        return false
    end
    local ok, err = pcall(a.fn, arg ~= "" and arg or nil)
    if not ok and TomoModDB and TomoModDB.diagnostics and TomoModDB.diagnostics.debug then
        print("|cff2e9dd8TomoMod|r apply " .. key .. " : " .. tostring(err))
    end
    return true
end

local function Flush()
    flushScheduled = false
    local allNow = true
    for key in pairs(queued) do
        queued[key] = nil
        if not Run(key) then allNow = false end
    end
    if allNow then
        K.Toast(T("Appliqué", "Applied"))
    else
        K.Toast(T("En combat : appliqué à la sortie du combat", "In combat: applied when combat ends"), 1, 0.55, 0.3)
    end
end

function K.Apply(what)
    if what == nil then return end
    local tw = type(what)
    if tw == "function" then
        local ok = pcall(what)
        if ok then K.Toast(T("Appliqué", "Applied")) end
        return
    elseif tw == "table" then
        for _, k in ipairs(what) do K.Apply(k) end
        return
    end
    queued[what] = true
    if not flushScheduled then
        flushScheduled = true
        C_Timer.After(0.03, Flush)
    end
end

local regen = CreateFrame("Frame")
regen:RegisterEvent("PLAYER_REGEN_ENABLED")
regen:SetScript("OnEvent", function()
    local any = false
    for key in pairs(deferred) do
        deferred[key] = nil
        Run(key)
        any = true
    end
    if any then K.Toast(T("Réglages appliqués", "Settings applied")) end
end)

-- Module glue. Every call is guarded: a module the player turned off has
-- no frames, and its apply function must then be a no-op, not an error.
local function Reanchor()
    local CB = TomoMod_Castbar
    if CB and CB.ReanchorAllToUF then CB.ReanchorAllToUF() end
end

-- TomoMod's unit frames refresh in place (UF.RefreshUnit); the open
-- page's preview follows the same request.
local function RefreshUFPreviews()
    if K.RefreshUFPreview then K.RefreshUFPreview() end
end

K.RegisterApplier("uf", function(unit)
    local UF = TomoMod_UnitFrames
    if not UF then return end
    local one = UF.RebuildUnit or UF.RefreshUnit
    if unit and one then one(unit) elseif UF.RefreshAllUnits then UF.RefreshAllUnits() end
    Reanchor()
    RefreshUFPreviews()
end, true)

K.RegisterApplier("ufall", function()
    local UF = TomoMod_UnitFrames
    if UF then
        local one = UF.RebuildUnit or UF.RefreshUnit
        for _, u in ipairs({ "player", "target", "targettarget", "focus", "pet" }) do
            if one then pcall(one, u) end
        end
    end
    local BF = TomoMod_BossFrames
    if BF and BF.RefreshAll then BF.RefreshAll() end
    Reanchor()
    RefreshUFPreviews()
end, true)

K.RegisterApplier("boss", function()
    local BF = TomoMod_BossFrames
    if BF and BF.RefreshAll then BF.RefreshAll() end
end, true)

K.RegisterApplier("cast", function()
    local CB = TomoMod_Castbar
    if CB and CB.ApplySettings then CB.ApplySettings() end
    if K._castPreview and CB and CB.SetPreview then CB.SetPreview(true) end
end, false)

K.RegisterApplier("res", function()
    local RB = TomoMod_ResourceBars
    if RB and RB.ApplySettings then RB.ApplySettings() end
    local UF = TomoMod_UnitFrames
    local one = UF and (UF.RebuildUnit or UF.RefreshUnit)
    if one then one("player") end
    Reanchor()
    RefreshUFPreviews()
end, true)

K.RegisterApplier("np", function()
    local NP = TomoMod_Nameplates
    if NP and NP.ApplySettings then NP.ApplySettings() end
    if NP and NP.RefreshAll then NP.RefreshAll() end
end, true)

K.RegisterApplier("baf", function()
    local BAF = TomoMod_BlizzardAuraFrames
    if BAF and BAF.ApplySettings then BAF.ApplySettings() end
end, true)

K.RegisterApplier("party", function()
    local PF = TomoMod_PartyFrames
    if PF and PF.ApplySettings then PF.ApplySettings() end
    if K.RefreshPartyPreview then K.RefreshPartyPreview() end
end, true)

K.RegisterApplier("raid", function()
    local RF = TomoMod_RaidFrames
    if RF and RF.ApplySettings then RF.ApplySettings() end
    if RF and RF._previewActive and RF.RefreshPreview then RF.RefreshPreview() end
    local RFP = TomoMod_RFPreview
    if RFP and RFP.ForceRefresh then RFP.ForceRefresh() end
end, true)

K.RegisterApplier("rez", function()
    local RT = TomoMod_ResurrectTracker
    if RT and RT.ApplySettings then RT.ApplySettings() end
end, false)

K.RegisterApplier("cdf", function()
    local CDF = TomoMod_CooldownForge
    if CDF and CDF.RefreshAll then CDF.RefreshAll() end
end, false)

-- Turn a whole module on or off through the lifecycle, which knows which
-- modules can change live and which need a /reload.
function K.SetModule(key, value)
    local LC = TomoMod_Lifecycle
    if LC and LC.SetEnabled then
        local report = LC.SetEnabled(key, value)
        if report and report.needsReload then
            K.Toast(T("Rechargement nécessaire (/rl)", "Reload needed (/rl)"), 1, 0.55, 0.3)
            if StaticPopup_Show and StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] then
                StaticPopup_Show("TOMOMOD_MODULE_RELOAD")
            end
        elseif report and report.deferred then
            K.Toast(T("Appliqué après le combat", "Applied after combat"), 1, 0.55, 0.3)
        else
            K.Toast(T("Appliqué", "Applied"))
        end
        return report
    end
end

-- For the few settings only read when the frames are created.
function K.NeedReload()
    K.Toast(T("Pris en compte au prochain /rl", "Takes effect after /rl"), 1, 0.55, 0.3)
    if StaticPopup_Show and StaticPopupDialogs["TOMOMOD_MODULE_RELOAD"] then
        StaticPopup_Show("TOMOMOD_MODULE_RELOAD")
    end
end

-- ---------------------------------------------------------------------
-- Page registry: page files register, the shell builds the navigation.
-- def = { key, section, label, kw, build(parent) -> frame,
--         onShow(), onHide(), noCombat }
-- ---------------------------------------------------------------------
-- Rebuild the open page after a structural change (bar added, list
-- reordered...). Deferred one frame so the click handler finishes first.
function K.RefreshPage()
    C_Timer.After(0, function()
        local C = TomoMod_Config
        if C and C.RebuildCurrentPage then C.RebuildCurrentPage() end
    end)
end

K.PAGES = K.PAGES or {}
function K.RegisterPage(def)
    if type(def) == "table" and def.key and def.build then
        K.PAGES[#K.PAGES + 1] = def
    end
end

function K.IsModuleOn(key)
    local R = TomoMod_Registry
    if R and R.IsEnabled then return R.IsEnabled(key) and true or false end
    return false
end

-- ---------------------------------------------------------------------
-- Locate: a golden pulse around the real frame
-- ---------------------------------------------------------------------
local locator
local locateGen = 0

local function Resolve(target)
    if type(target) == "function" then
        local ok, f = pcall(target)
        return ok and f or nil
    elseif type(target) == "string" then
        return _G[target]
    end
    return target
end

local function EnsureLocator()
    if locator then return locator end
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:Hide()
    local r, g, b = TH.accent[1], TH.accent[2], TH.accent[3]
    local fill = f:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(r, g, b, 0.14)
    local function Edge(p1, p2, horiz)
        local t = f:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(TH.accent[1], TH.accent[2], TH.accent[3], 1)
        t:SetPoint(p1)
        t:SetPoint(p2)
        if horiz then t:SetHeight(2) else t:SetWidth(2) end
    end
    Edge("TOPLEFT", "TOPRIGHT", true)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    Edge("TOPLEFT", "BOTTOMLEFT", false)
    Edge("TOPRIGHT", "BOTTOMRIGHT", false)
    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_BOLD, 12, "OUTLINE")
    label:SetPoint("BOTTOM", f, "TOP", 0, 4)
    label:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
    f.label = label
    locator = f
    return f
end

-- Returns true when something was shown. `silent` skips the "not
-- visible" hint (used when a page opens and pulses its frame by itself).
function K.Locate(target, labelText, silent)
    local frame = Resolve(target)
    if not (frame and frame.IsVisible and frame:IsVisible()) then
        if not silent then
            K.Toast(T("Pas affiché pour le moment (pas de cible, pas de groupe...)",
                      "Not on screen right now (no target, no group...)"), 1, 0.55, 0.3)
        end
        return false
    end
    local f = EnsureLocator()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
    f:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
    f.label:SetText(labelText or "")
    f:SetAlpha(1)
    f:Show()
    locateGen = locateGen + 1
    local gen, t0 = locateGen, GetTime()
    f:SetScript("OnUpdate", function(self)
        if gen ~= locateGen then return end
        local e = GetTime() - t0
        if e > 2.2 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            return
        end
        if e < 1.6 then
            self:SetAlpha(0.55 + 0.45 * math.cos(e * 9))
        else
            self:SetAlpha(math.max(0, 1 - (e - 1.6) / 0.6))
        end
    end)
    return true
end

-- ---------------------------------------------------------------------
-- Previews
-- ---------------------------------------------------------------------
-- Party: five stand-in frames drawn on the party anchor while the page
-- is open and the player is not in a group. They follow width, height,
-- spacing, direction, texture and power bar live, which is the whole
-- point: no group needed to see what a slider does.
local partyPreview = { frames = {}, active = false }
local DEMO = {
    { class = nil,      name = nil,      hp = 1.00, role = "TANK" },
    { class = "PRIEST", name = "Elyna",  hp = 0.72, role = "HEALER" },
    { class = "MAGE",   name = "Torvin", hp = 0.45, role = "DAMAGER" },
    { class = "ROGUE",  name = "Sel",    hp = 0.88, role = "DAMAGER" },
    { class = "HUNTER", name = "Garrak", hp = 0.20, role = "DAMAGER" },
}

local function ClassRGB(token)
    local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then return c.r, c.g, c.b end
    return 0.3, 0.8, 0.3
end

local function PartyPreviewFrame(i)
    local f = partyPreview.frames[i]
    if f then return f end
    f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(0.045, 0.045, 0.060, 0.92)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f.hp = f:CreateTexture(nil, "ARTWORK")
    f.hp:SetPoint("TOPLEFT", 1, -1)
    f.pw = f:CreateTexture(nil, "ARTWORK")
    f.pw:SetPoint("BOTTOMLEFT", 1, 1)
    f.name = f:CreateFontString(nil, "OVERLAY")
    f.name:SetPoint("LEFT", 6, 2)
    f.pct = f:CreateFontString(nil, "OVERLAY")
    f.pct:SetPoint("RIGHT", -6, 2)
    f.tag = f:CreateFontString(nil, "OVERLAY")
    f.tag:SetFont(FONT, 8, "OUTLINE")
    f.tag:SetPoint("TOPRIGHT", -3, -2)
    f.tag:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 0.9)
    f.tag:SetText(T("APERÇU", "PREVIEW"))
    partyPreview.frames[i] = f
    return f
end

function K.RefreshPartyPreview()
    if not partyPreview.active then return end
    local db = TomoModDB and TomoModDB.partyFrames
    local anchor = _G.TomoMod_PartyAnchor
    local show = db and db.enabled and anchor and not IsInGroup()
    for i = 1, #DEMO do
        local f = PartyPreviewFrame(i)
        if not show then f:Hide() else
            local w, h = db.width or 160, db.height or 40
            local sp = db.spacing or 2
            local dir = db.growDirection or "DOWN"
            f:ClearAllPoints()
            local o = (i - 1)
            if dir == "UP" then
                f:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, o * (h + sp))
            elseif dir == "RIGHT" then
                f:SetPoint("TOPLEFT", anchor, "TOPLEFT", o * (w + sp), 0)
            elseif dir == "LEFT" then
                f:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -o * (w + sp), 0)
            else
                f:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -o * (h + sp))
            end
            f:SetSize(w, h)
            local d = DEMO[i]
            local cls = d.class or select(2, UnitClass("player"))
            local r, g, b = ClassRGB(cls)
            if db.healthColor == "green" then r, g, b = 0.15, 0.75, 0.30 end
            local tex = db.texture or WHITE
            local pH = (db.showPower ~= false) and (db.powerHeight or 3) or 0
            f.hp:SetTexture(tex)
            f.hp:SetVertexColor(r, g, b, 1)
            f.hp:SetSize(math.max(1, (w - 2) * d.hp), math.max(1, h - 2 - pH))
            f.pw:SetShown(pH > 0)
            if pH > 0 then
                f.pw:SetTexture(tex)
                f.pw:SetVertexColor(0.2, 0.45, 1, 1)
                f.pw:SetSize(math.max(1, (w - 2) * 0.8), pH)
            end
            local font = db.font or FONT
            local fs = db.fontSize or 11
            f.name:SetFont(font, fs, db.fontOutline or "OUTLINE")
            f.pct:SetFont(font, fs, db.fontOutline or "OUTLINE")
            local nm = d.name or UnitName("player") or "Tomo"
            local maxLen = db.nameMaxLength or 0
            if maxLen > 0 and #nm > maxLen then nm = nm:sub(1, maxLen) end
            f.name:SetText(db.showName ~= false and nm or "")
            f.pct:SetText(db.showHealthText ~= false and (math.floor(d.hp * 100) .. "%") or "")
            f:Show()
        end
    end
end

function K.PartyPreview(on)
    partyPreview.active = on and true or false
    if on then
        K.RefreshPartyPreview()
    else
        for _, f in pairs(partyPreview.frames) do f:Hide() end
    end
end

function K.RaidPreview(on)
    local RF = TomoMod_RaidFrames
    if not RF then return end
    if on then
        if not IsInRaid() and RF.ShowPreview then pcall(RF.ShowPreview, 20) end
    elseif RF._previewActive and RF.HidePreview then
        pcall(RF.HidePreview)
    end
end

function K.CastPreview(on)
    K._castPreview = on and true or false
    local CB = TomoMod_Castbar
    if CB and CB.SetPreview then pcall(CB.SetPreview, K._castPreview) end
end

-- Event: entering a group swaps the party stand-ins for the real frames.
local groupWatch = CreateFrame("Frame")
groupWatch:RegisterEvent("GROUP_ROSTER_UPDATE")
groupWatch:SetScript("OnEvent", function() K.RefreshPartyPreview() end)

-- ---------------------------------------------------------------------
-- Simple / expert mode
-- ---------------------------------------------------------------------
function K.Expert() return K.GuiDB().expert == true end
function K.SetExpert(v)
    K.GuiDB().expert = v and true or false
    if TomoMod_Config and TomoMod_Config.InvalidatePanels then TomoMod_Config.InvalidatePanels() end
end

-- ---------------------------------------------------------------------
-- Page builder
-- ---------------------------------------------------------------------
-- Every widget method takes the same shape: label, binding, then what to
-- apply. Builders are reused for card bodies and for the two columns of
-- a Pair, so a column is just a smaller card.
local B = {}
B.__index = B

local function NewBuilder(parent, y)
    return setmetatable({ parent = parent, y = y or 0, n = 0 }, B)
end

-- A dotted path that neither the live DB nor TomoMod_Defaults knows is a
-- setting this build does not have: the control is skipped instead of
-- writing a key no module will ever read.
local function Absent(binding)
    return type(binding) == "string" and K.Get(binding) == nil and K.Default(binding) == nil
end
K.Absent = Absent

local function Tip(frame, tip)
    if frame and tip and W.SetTooltip then W.SetTooltip(frame, tip) end
    return frame
end

function B:Info(text)
    local _, ny = W.CreateInfoText(self.parent, text, self.y)
    self.y = ny
    self.n = self.n + 1
    return self
end

function B:Label(text)
    local _, ny = W.CreateSubLabel(self.parent, text, self.y)
    self.y = ny
    self.n = self.n + 1
    return self
end

function B:Toggle(label, binding, apply, tip, onChange)
    if Absent(binding) then return nil end
    self.n = self.n + 1
    local get, set = Bind(binding)
    local f, ny = W.CreateCheckbox(self.parent, label, get() and true or false, self.y, function(v)
        set(v and true or false)
        if onChange then onChange(v) end
        K.Apply(apply)
    end)
    Tip(f, tip)
    self.y = ny
    return f
end

function B:Slider(label, binding, minV, maxV, step, apply, fmt, tip)
    if Absent(binding) then return nil end
    self.n = self.n + 1
    local get, set, def = Bind(binding)
    local v = tonumber(get()) or def or minV
    local f, ny = W.CreateSlider(self.parent, label, v, minV, maxV, step or 1, self.y, function(nv)
        set(nv)
        K.Apply(apply)
    end, fmt or ((step or 1) < 1 and "%.2f" or "%.0f"), def)
    Tip(f, tip)
    self.y = ny
    return f
end

function B:Select(label, binding, options, apply, tip, onChange)
    if Absent(binding) then return nil end
    self.n = self.n + 1
    local get, set = Bind(binding)
    local f, ny = W.CreateDropdown(self.parent, label, options, get(), self.y, function(v)
        set(v)
        if onChange then onChange(v) end
        K.Apply(apply)
    end)
    Tip(f, tip)
    self.y = ny
    return f
end

function B:Seg(label, binding, options, apply, cols, tip)
    if Absent(binding) then return nil end
    self.n = self.n + 1
    local get, set = Bind(binding)
    local f, ny = W.CreateSegmentedControl(self.parent, label, options, get(), self.y, function(v)
        set(v)
        K.Apply(apply)
    end, cols)
    Tip(f, tip)
    self.y = ny
    return f
end

function B:Color(label, binding, apply, tip)
    local get = Bind(binding)
    local c = get()
    if type(c) ~= "table" then return nil end
    self.n = self.n + 1
    local f, ny = W.CreateColorPicker(self.parent, label, c, self.y, function()
        K.Apply(apply)
    end)
    Tip(f, tip)
    self.y = ny
    return f
end

function B:Button(label, fn, width, tip)
    self.n = self.n + 1
    local f, ny = W.CreateButton(self.parent, label, width or 200, self.y, fn)
    Tip(f, tip)
    self.y = ny
    return f
end

function B:Danger(label, fn, width, tip)
    self.n = self.n + 1
    local f, ny = W.CreateDangerButton(self.parent, label, width or 200, self.y, fn)
    Tip(f, tip)
    self.y = ny
    return f
end

-- One-line text field with an action button. onSubmit(text) returns true
-- to clear the field.
function B:Input(label, placeholder, buttonLabel, onSubmit, initial)
    self.n = self.n + 1
    local parent = self.parent
    local f = CreateFrame("Frame", nil, parent)
    local labelH = (label and label ~= "") and 18 or 0
    f:SetHeight(labelH + 28)
    f:SetPoint("TOPLEFT", 16, self.y)
    f:SetPoint("TOPRIGHT", -16, self.y)
    if labelH > 0 then
        local l = f:CreateFontString(nil, "OVERLAY")
        l:SetFont(FONT, 11, "")
        l:SetPoint("TOPLEFT", 0, 0)
        l:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 1)
        l:SetText(label)
    end
    local btnW = buttonLabel and 110 or 0
    local box = CreateFrame("EditBox", nil, f, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 0, -labelH)
    box:SetPoint("TOPRIGHT", -(btnW > 0 and btnW + 8 or 0), -labelH)
    box:SetHeight(26)
    box:SetAutoFocus(false)
    box:SetFont(FONT, 11, "")
    box:SetTextInsets(8, 8, 0, 0)
    box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    box:SetBackdropColor(TH.bgDark[1], TH.bgDark[2], TH.bgDark[3], 1)
    box:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1)
    box:SetTextColor(TH.text[1], TH.text[2], TH.text[3], 1)
    if initial then box:SetText(initial) end
    local ph = box:CreateFontString(nil, "OVERLAY")
    ph:SetFont(FONT, 11, "")
    ph:SetPoint("LEFT", 8, 0)
    ph:SetTextColor(TH.textFaint[1], TH.textFaint[2], TH.textFaint[3], 1)
    ph:SetText(placeholder or "")
    ph:SetShown((box:GetText() or "") == "")
    local function Submit()
        local txt = (box:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if txt == "" then return end
        if onSubmit(txt) then box:SetText("") end
        box:ClearFocus()
    end
    box:SetScript("OnTextChanged", function(s) ph:SetShown((s:GetText() or "") == "") end)
    box:SetScript("OnEnterPressed", Submit)
    box:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(s) s:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 1) end)
    box:SetScript("OnEditFocusLost", function(s) s:SetBackdropBorderColor(TH.border[1], TH.border[2], TH.border[3], 1) end)
    if buttonLabel then
        local btn = W.CreateButton(f, buttonLabel, btnW, -labelH, Submit)
        btn:ClearAllPoints()
        btn:SetPoint("TOPRIGHT", 0, -labelH + 1)
    end
    if W._RegisterSearchEntry and label then W._RegisterSearchEntry(label, f, "option") end
    self.y = self.y - labelH - 34
    f.box = box
    return f
end

-- Two half-width columns. Each side gets its own builder.
function B:Pair(left, right)
    local added = 0
    local row, ny = W.CreateTwoColumnRow(self.parent, self.y,
        function(col)
            if not left then return 0 end
            local sub = NewBuilder(col, 0)
            left(sub)
            added = added + sub.n
            return sub.y
        end,
        function(col)
            if not right then return 0 end
            local sub = NewBuilder(col, 0)
            right(sub)
            added = added + sub.n
            return sub.y
        end)
    -- Both halves skipped (settings this build does not have): no row.
    if added == 0 then
        if row and row.Hide then row:Hide() end
        return self
    end
    self.n = self.n + added
    self.y = ny
    return self
end

-- Escape hatch: fn(parent, y) -> newY
function B:Custom(fn)
    self.n = self.n + 1
    self.y = fn(self.parent, self.y) or self.y
    return self
end

function B:Space(px)
    self.y = self.y - (px or 8)
    return self
end

-- A card that is not built (expert-only in simple mode) swallows every
-- call, so page code never has to test for it.
local Null = setmetatable({}, { __index = function() return function() return nil end end })

local P = {}
P.__index = P

function P:Intro(text)
    local _, ny = W.CreateInfoText(self.c, text, self.y)
    self.y = ny - 4
end

-- opts.adv: expert-only. opts.tip: shown on the card title.
function P:Card(title, opts)
    opts = opts or {}
    if opts.adv and not K.Expert() then
        self.hidden = self.hidden + 1
        return Null
    end
    local card, cy = W.CreateCard(self.c, title, self.y)
    if opts.tip then Tip(card, opts.tip) end
    local b = NewBuilder(card.inner, cy)
    local page = self
    b.Done = function(me)
        -- Every control skipped: drop the card rather than show a title
        -- over nothing.
        if me.n == 0 then
            card:Hide()
            return
        end
        page.y = W.FinalizeCard(card, me.y)
    end
    b.card = card
    return b
end

-- Big friendly header: title, one line of help and a "show me" button
-- that pulses the real frame on screen.
function P:Hero(title, text, locate, locateLabel)
    local c = self.c
    local f = CreateFrame("Frame", nil, c, "BackdropTemplate")
    f:SetPoint("TOPLEFT", 8, self.y)
    f:SetPoint("TOPRIGHT", -8, self.y)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(TH.accent[1] * 0.10, TH.accent[2] * 0.09, TH.accent[3] * 0.07, 0.95)
    f:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 0.35)

    local h = f:CreateFontString(nil, "OVERLAY")
    h:SetFont(FONT_BOLD, 15, "")
    h:SetPoint("TOPLEFT", 12, -10)
    h:SetTextColor(TH.textHeader[1], TH.textHeader[2], TH.textHeader[3], 1)
    h:SetText(title)

    local d = f:CreateFontString(nil, "OVERLAY")
    d:SetFont(FONT, 11, "")
    d:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
    d:SetPoint("RIGHT", f, "RIGHT", locate and -132 or -12, 0)
    d:SetJustifyH("LEFT")
    d:SetTextColor(TH.textDim[1], TH.textDim[2], TH.textDim[3], 1)
    d:SetText(text or "")

    if locate then
        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        btn:SetSize(112, 26)
        btn:SetPoint("TOPRIGHT", -10, -10)
        btn:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        btn:SetBackdropColor(TH.accent[1] * 0.16, TH.accent[2] * 0.16, TH.accent[3] * 0.16, 1)
        btn:SetBackdropBorderColor(TH.accent[1], TH.accent[2], TH.accent[3], 0.8)
        local bt = btn:CreateFontString(nil, "OVERLAY")
        bt:SetFont(FONT_BOLD, 11, "")
        bt:SetPoint("CENTER")
        bt:SetTextColor(TH.accent[1], TH.accent[2], TH.accent[3], 1)
        bt:SetText(T("Montre-moi", "Show me"))
        btn:SetScript("OnEnter", function(s) s:SetBackdropColor(TH.accent[1] * 0.30, TH.accent[2] * 0.30, TH.accent[3] * 0.30, 1) end)
        btn:SetScript("OnLeave", function(s) s:SetBackdropColor(TH.accent[1] * 0.16, TH.accent[2] * 0.16, TH.accent[3] * 0.16, 1) end)
        btn:SetScript("OnClick", function() K.Locate(locate, locateLabel or title) end)
        W.SetTooltip(btn, T("Fait clignoter l'élément réel à l'écran.", "Pulses the real element on screen."))
    end

    local dh = d:GetStringHeight() or 13
    local height = math.max(54, 30 + dh + 12)
    f:SetHeight(height)
    self.y = self.y - height - 10
    return f
end

function P:Finish()
    if self.hidden > 0 then
        local card, cy = W.CreateCard(self.c, nil, self.y)
        local _, ny = W.CreateInfoText(card.inner, string.format(T(
            "%d groupe(s) de réglages avancés sont masqués pour garder la page simple.",
            "%d advanced setting group(s) are hidden to keep this page simple."), self.hidden), cy)
        local _, ny2 = W.CreateButton(card.inner, T("Afficher les réglages avancés", "Show advanced settings"), 240, ny, function()
            K.SetExpert(true)
        end)
        self.y = W.FinalizeCard(card, ny2)
    end
    self.c:SetHeight(math.abs(self.y) + 24)
    if self.scroll.UpdateScroll then self.scroll.UpdateScroll() end
end

-- ---------------------------------------------------------------------
-- Live previews kept from the 4.x GUI (Config/Panels/UFPreview.lua and
-- RFPreview.lua): a detached copy of the real frame, rebuilt with the
-- game's own factories, sitting at the top of the page it belongs to.
-- ---------------------------------------------------------------------
local ufHosts = setmetatable({}, { __mode = "k" })

local function FitUFPreview(host)
    local f = host.frame
    if not f then return end
    local fw, fh = f:GetWidth() or 0, f:GetHeight() or 0
    local aw = (host:GetWidth() or 0) - 24
    local ah = (host:GetHeight() or 0) - 16
    local s = 1
    if fw > 0 and aw > 0 then s = math.min(s, aw / fw) end
    if fh > 0 and ah > 0 then s = math.min(s, ah / fh) end
    if s < 0.3 then s = 0.3 end
    f:SetScale(s)
    f:ClearAllPoints()
    f:SetPoint("CENTER", host, "CENTER", 0, 0)
end

local function BuildUFPreview(host)
    local UFP = TomoMod_UFPreview
    if not (UFP and UFP.CreateStandalone) then return end
    local ok, f = pcall(UFP.CreateStandalone, host, host.unit, { recycle = host.frame })
    if ok and f then
        host.frame = f
        f:SetParent(host)
        f:Show()
        FitUFPreview(host)
    end
end

function K.RefreshUFPreview()
    for host in pairs(ufHosts) do
        if host:IsVisible() then BuildUFPreview(host) end
    end
end

function P:UFPreview(unitKey)
    if not (TomoMod_UFPreview and TomoMod_UFPreview.CreateStandalone) then return end
    local s = TomoModDB.unitFrames and TomoModDB.unitFrames[unitKey]
    if type(s) ~= "table" then return end
    local card, cy = W.CreateCard(self.c, T("Aperçu", "Preview"), self.y)
    local host = CreateFrame("Frame", nil, card.inner)
    host:SetPoint("TOPLEFT", 8, cy)
    host:SetPoint("TOPRIGHT", -8, cy)
    -- Height reserved once, from the frame as it is now plus room for an
    -- aura row: resizing on every slider step would shift the whole page.
    local fh = (tonumber(s.healthHeight) or 30) + (tonumber(s.powerHeight) or 0)
        + (tonumber(s.infoBarHeight) or 0)
    local auraRow = (type(s.auras) == "table" and s.auras.enabled ~= false) and ((tonumber(s.auras.size) or 24) + 8) or 0
    host:SetHeight(math.max(70, math.min(220, fh + auraRow + 40)))
    if host.SetClipsChildren then host:SetClipsChildren(true) end
    host.unit = unitKey
    host:SetScript("OnShow", BuildUFPreview)
    host:SetScript("OnSizeChanged", FitUFPreview)
    ufHosts[host] = true
    C_Timer.After(0, function() if host:IsVisible() then BuildUFPreview(host) end end)
    self.y = W.FinalizeCard(card, cy - host:GetHeight() - 6)
    return host
end

-- The Studio this page replaces stays installed: a last card points to
-- it for the settings the page does not carry.
function P:StudioLink(studioKey, arg, studioLabel)
    local C = TomoMod_Config
    if not (C and C.LaunchStudio) then return end
    local card, cy = W.CreateCard(self.c, T("Plus de réglages", "More settings"), self.y)
    local _, ny = W.CreateInfoText(card.inner, string.format(T(
        "Les réglages qui ne sont pas sur cette page restent dans %s.",
        "Settings that are not on this page are still in %s."), studioLabel), cy)
    local _, ny2 = W.CreateButton(card.inner, string.format(T("Ouvrir %s", "Open %s"), studioLabel), 260, ny, function()
        C.LaunchStudio(studioKey, arg)
    end)
    self.y = W.FinalizeCard(card, ny2)
end

function P:RaidPreview()
    local RFP = TomoMod_RFPreview
    if not (RFP and RFP.Create) then return end
    local card, cy = W.CreateCard(self.c, T("Aperçu", "Preview"), self.y)
    local host = CreateFrame("Frame", nil, card.inner)
    host:SetPoint("TOPLEFT", 4, cy)
    host:SetPoint("TOPRIGHT", -4, cy)
    host:SetHeight(260)
    if host.SetClipsChildren then host:SetClipsChildren(true) end
    local ok, strip = pcall(RFP.Create, host)
    if ok and strip then host.strip = strip end
    self.y = W.FinalizeCard(card, cy - host:GetHeight() - 6)
    return host
end

-- build(page) fills the page; returns the scroll container the shell shows.
function K.Page(parent, build)
    local scroll = W.CreateScrollPanel(parent)
    local page = setmetatable({ c = scroll.child, y = -10, hidden = 0, scroll = scroll }, P)
    local ok, err = pcall(build, page)
    if not ok then
        local h = geterrorhandler and geterrorhandler()
        if h then pcall(h, "TomoMod GUI: " .. tostring(err)) end
        local _, ny = W.CreateInfoText(page.c, "|cffff5555" .. T("Erreur de construction de la page : ", "Page build error: ") .. tostring(err) .. "|r", page.y)
        page.y = ny
    end
    page:Finish()
    return scroll
end

-- ---------------------------------------------------------------------
-- Shared option lists
-- ---------------------------------------------------------------------
local FP = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\"
K.FONTS = {
    { text = "Poppins Medium",   value = FP .. "Poppins-Medium.ttf" },
    { text = "Poppins SemiBold", value = FP .. "Poppins-SemiBold.ttf" },
    { text = "Poppins Bold",     value = FP .. "Poppins-Bold.ttf" },
    { text = "Expressway",       value = FP .. "Expressway.TTF" },
    { text = "Tomo",             value = FP .. "Tomo.ttf" },
    { text = "Friz Quadrata",    value = "Fonts\\FRIZQT__.TTF" },
    { text = "Arial Narrow",     value = "Fonts\\ARIALN.TTF" },
}

K.TEXTURES = {
    { text = "TomoMod",           value = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki" },
    { text = T("Plat", "Flat"),   value = WHITE },
    { text = "Blizzard",          value = "Interface\\TargetingFrame\\UI-StatusBar" },
    { text = T("Lisse", "Smooth"), value = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

K.OUTLINES = {
    { text = T("Contour", "Outline"),          value = "OUTLINE" },
    { text = T("Contour épais", "Thick"),      value = "THICKOUTLINE" },
    { text = T("Aucun", "None"),               value = "" },
}

K.HP_FORMATS = {
    { text = T("Pourcentage", "Percent"),               value = "percent" },
    { text = T("Valeur", "Current"),                    value = "current" },
    { text = T("Valeur + %", "Current + %"),            value = "current_percent" },
    { text = T("Valeur / max", "Current / max"),        value = "current_max" },
    { text = T("Points manquants", "Deficit"),          value = "deficit" },
}
