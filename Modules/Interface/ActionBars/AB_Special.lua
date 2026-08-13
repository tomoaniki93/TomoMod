-- =====================================================================
-- AB_Special.lua v1.0.0 -- ActionBars special bars & state decoration (Lot A5)
--
-- The engine has tracked "active", "equipped", "autoCastAllowed" and
-- "autoCastEnabled" since Lot A1, but nothing ever drew them: the skin
-- kills button.Border (Blizzard's equipped marker) and flattens the checked
-- texture to a barely visible white wash. So on a skinned bar you currently
-- cannot see which stance you are in, which weapon-enchant item is equipped,
-- or which pet ability is on autocast. This module draws all of it.
--
--   ACCENT RING   active (current stance / channelled action / autorepeat)
--                 and equipped, on one ring with a priority so two states
--                 never stack into visual noise.
--   AUTOCAST      LibCustomGlow shine on its own key, so it coexists with
--                 the proc and rotation glows from Lot A3.
--   PET AUTO-HIDE optional; extends the container's EXISTING visibility
--                 driver condition rather than registering a second driver,
--                 because two drivers calling Show/Hide on the same frame
--                 fight each other.
--
-- No stance auto-hide: no macro conditional expresses "this class has no
-- forms" ([stance:0] means "no form active", which a druid in caster form
-- legitimately is). Blizzard's own stance buttons already hide themselves
-- when there is nothing to show, so the container is simply empty.
-- =====================================================================

TomoMod_ABSpecial = TomoMod_ABSpecial or {}
local S = TomoMod_ABSpecial

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local U   = TomoMod_Utils

local AUTOCAST_KEY = "_TomoABAutoCast"
local BRAND = (U and U.BRAND) or { 0.18, 0.847, 0.518 }

-- =====================================================================
-- SETTINGS
-- =====================================================================

local DEFAULTS = {
    activeEnabled    = true,
    activeColor      = { 1, 0.82, 0.25, 1 },
    equippedEnabled  = true,
    equippedColor    = { BRAND[1], BRAND[2], BRAND[3], 1 },
    accentThickness  = 2,

    autoCastShine    = true,
    autoCastColor    = { 0.95, 0.95, 0.32, 1 },
    autoCastParticles = 4,
    autoCastFrequency = 0.125,

    petAutoHide      = false,
}

S.DEFAULTS = DEFAULTS

local function GetSettings()
    if not TomoModDB then return DEFAULTS end
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    local db = TomoModDB.actionBars.special
    if not db then db = {}; TomoModDB.actionBars.special = db end
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

S.GetSettings = GetSettings

-- =====================================================================
-- ACCENT RING
-- =====================================================================

local rings = {}   -- entry -> { top, bottom, left, right }

local function EnsureRing(entry)
    local ring = rings[entry]
    if ring then return ring end
    local button = entry.frame
    if not button or not button.CreateTexture then return nil end

    -- Sublevel 7 sits above the skin's border parts (ARTWORK/OVERLAY 6) and
    -- above its pushed overlay (OVERLAY 5).
    local function part()
        local t = button:CreateTexture(nil, "OVERLAY", nil, 7)
        t:Hide()
        return t
    end

    ring = { top = part(), bottom = part(), left = part(), right = part() }
    rings[entry] = ring
    return ring
end

local function LayoutRing(ring, button, thickness)
    thickness = tonumber(thickness) or 2
    if thickness < 1 then thickness = 1 end

    ring.top:ClearAllPoints()
    ring.top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    ring.top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    ring.top:SetHeight(thickness)

    ring.bottom:ClearAllPoints()
    ring.bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    ring.bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    ring.bottom:SetHeight(thickness)

    ring.left:ClearAllPoints()
    ring.left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -thickness)
    ring.left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, thickness)
    ring.left:SetWidth(thickness)

    ring.right:ClearAllPoints()
    ring.right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -thickness)
    ring.right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, thickness)
    ring.right:SetWidth(thickness)
end

local function ShowRing(ring, c)
    for _, part in pairs(ring) do
        part:SetColorTexture(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
        part:Show()
    end
end

local function HideRing(ring)
    for _, part in pairs(ring) do part:Hide() end
end

-- =====================================================================
-- AUTOCAST
-- =====================================================================

local autoCastOn = {}   -- entry -> true

-- Blizzard's autocastable swirl is left in place but realigned onto the
-- inset icon; only the animated shine is replaced.
local function RealignBlizzardAutoCast(entry)
    local button = entry.frame
    if not button then return end
    local name = (button.GetName and button:GetName()) or ""
    local border = button.AutoCastable or _G[name .. "AutoCastable"]
    if border and border.SetPoint then
        pcall(border.ClearAllPoints, border)
        pcall(border.SetPoint, border, "TOPLEFT", button, "TOPLEFT", -2, 2)
        pcall(border.SetPoint, border, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    end
    local shine = button.AutoCastShine or _G[name .. "AutoCastShine"]
    if shine and shine.Hide then pcall(shine.Hide, shine) end
    entry._blizzShine = shine
end

local function SetAutoCast(entry, on)
    local db = GetSettings()
    local frame = entry.frame
    if not frame then return end

    if on and db.autoCastShine and LCG then
        if autoCastOn[entry] then return end
        autoCastOn[entry] = true
        local c = db.autoCastColor or DEFAULTS.autoCastColor
        pcall(LCG.AutoCastGlow_Start, frame,
            { c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 },
            math.floor(db.autoCastParticles or DEFAULTS.autoCastParticles),
            db.autoCastFrequency or DEFAULTS.autoCastFrequency,
            1, 0, 0, AUTOCAST_KEY)
    else
        if not autoCastOn[entry] then return end
        autoCastOn[entry] = nil
        if LCG then pcall(LCG.AutoCastGlow_Stop, frame, AUTOCAST_KEY) end
    end
end

-- =====================================================================
-- RENDER
-- =====================================================================

local function Apply(entry)
    if not entry or not entry.frame then return end
    local db = GetSettings()
    local state = entry.state or {}

    local ring = EnsureRing(entry)
    if ring then
        LayoutRing(ring, entry.frame, db.accentThickness)
        -- Priority: "this is what you are doing right now" beats "this is
        -- what you are wearing".
        if db.activeEnabled and state.active == true then
            ShowRing(ring, db.activeColor or DEFAULTS.activeColor)
        elseif db.equippedEnabled and state.equipped == true then
            ShowRing(ring, db.equippedColor or DEFAULTS.equippedColor)
        else
            HideRing(ring)
        end
    end

    if entry.kind == "pet" then
        RealignBlizzardAutoCast(entry)
        if entry._blizzShine then pcall(entry._blizzShine.Hide, entry._blizzShine) end
        SetAutoCast(entry, state.autoCastEnabled == true)
    end
end

function S.Apply(entry) Apply(entry) end

function S.ApplyAll()
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end
    for entry in ABE.Entries() do Apply(entry) end
end

function S.ApplySettings()
    -- Styles may have changed: tear the shines down before rebuilding, or a
    -- colour change would leave the previous animation running.
    local ABE = TomoMod_ABEngine
    if ABE and ABE.Entries then
        for entry in ABE.Entries() do
            if autoCastOn[entry] then
                autoCastOn[entry] = nil
                if LCG then pcall(LCG.AutoCastGlow_Stop, entry.frame, AUTOCAST_KEY) end
            end
        end
    end
    S.ApplyAll()
end

-- =====================================================================
-- PET BAR AUTO-HIDE
-- =====================================================================

function S.RefreshPetVisibility()
    local AB = TomoMod_ActionBars
    if AB and AB.RefreshVisibilityDriver then
        AB.RefreshVisibilityDriver("pet")
    end
end

-- =====================================================================
-- ENGINE BINDING
-- =====================================================================

local bound = false

local function OnEntry(entry) Apply(entry) end

local function OnUnregister(entry)
    local ring = rings[entry]
    if ring then HideRing(ring); rings[entry] = nil end
    if autoCastOn[entry] then
        autoCastOn[entry] = nil
        if LCG then pcall(LCG.AutoCastGlow_Stop, entry.frame, AUTOCAST_KEY) end
    end
end

function S.Bind()
    if bound then return end
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.RegisterCallback then return end
    bound = true
    ABE.RegisterCallback("ABSpecial", "register",   OnEntry)
    ABE.RegisterCallback("ABSpecial", "state",      OnEntry)
    ABE.RegisterCallback("ABSpecial", "action",     OnEntry)
    ABE.RegisterCallback("ABSpecial", "unregister", OnUnregister)
end

function S.IsBound() return bound end

-- =====================================================================
-- BOOT
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(0.9, function()
        S.Bind()
        C_Timer.After(0.5, function()
            S.ApplyAll()
            S.RefreshPetVisibility()
        end)
    end)
end)
