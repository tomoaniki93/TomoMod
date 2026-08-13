-- =====================================================================
-- AB_Glow.lua v1.0.0 -- ActionBars glow layer (Lot A3)
--
-- Two independent glow sources, each with its own style, colour and
-- LibCustomGlow key so they can coexist on the same button:
--
--   PROC      SPELL_ACTIVATION_OVERLAY_GLOW_SHOW / _HIDE. The classic
--             "your proc is up" highlight.
--   ASSISTED  C_AssistedCombat.GetNextCastSpell(), the Midnight rotation
--             recommendation. Blizzard highlights its own buttons for this;
--             TomoMod-owned buttons (Lot A6) will not get that for free, so
--             the glow is driven here instead.
--
-- Matching is done on spell ID through the engine's cached content, so a
-- macro that resolves to a spell glows exactly like the bare spell does,
-- and talent-morphed spells are matched through their override ID too.
--
-- LibCustomGlow call conventions and the Blizzard-overlay suppression are
-- deliberately identical to Modules/QOL/CooldownManager/CDMProcGlow.lua.
-- When ForgeLib lands, both should collapse into one shared helper.
-- =====================================================================

TomoMod_ABGlow = TomoMod_ABGlow or {}
local G = TomoMod_ABGlow

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local U   = TomoMod_Utils

local PROC_KEY   = "_TomoABProc"
local ASSIST_KEY = "_TomoABAssist"

G.GlowTypes = {
    "Pixel Glow",
    "Autocast Shine",
    "Action Button Glow",
    "Proc Glow",
    "Blizzard Glow",
}

-- =====================================================================
-- SETTINGS
-- =====================================================================

local BRAND = (U and U.BRAND) or { 0.18, 0.847, 0.518 }

local DEFAULTS = {
    procEnabled     = true,
    procType        = "Pixel Glow",
    procColor       = { 0.95, 0.95, 0.32, 1 },

    assistEnabled   = false,
    assistType      = "Proc Glow",
    assistColor     = { BRAND[1], BRAND[2], BRAND[3], 1 },
    assistInterval  = 0.15,

    pixelLines      = 8,
    pixelFrequency  = 0.25,
    pixelThickness  = 2,
    autoParticles   = 4,
    autoFrequency   = 0.125,
    autoScale       = 1.0,
    buttonFrequency = 0.125,
}

G.DEFAULTS = DEFAULTS

local function GetSettings()
    if not TomoModDB then return DEFAULTS end
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    local db = TomoModDB.actionBars.glow
    if not db then db = {}; TomoModDB.actionBars.glow = db end
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

G.GetSettings = GetSettings

-- =====================================================================
-- STATE
-- =====================================================================

local procSpells  = {}   -- spellID -> true (an overlay is currently up)
local assistSpell = nil  -- spellID recommended right now, or nil

local spellIndex  = {}   -- spellID -> { entry, entry, ... }
local indexDirty  = true

local activeProc   = {}  -- entry -> true
local activeAssist = {}  -- entry -> true

local bound        = false
local persistTicker = nil
local assistTicker  = nil
local PERSIST_RATE  = 0.3

-- =====================================================================
-- SECRET-SAFE SPELL ID
-- =====================================================================

local function PlainSpellID(v)
    if v == nil then return nil end
    if issecretvalue and issecretvalue(v) then return nil end
    if type(v) ~= "number" then return nil end
    if v <= 0 then return nil end
    return v
end

-- =====================================================================
-- SPELL -> ENTRY INDEX
-- =====================================================================

local function AddToIndex(spellID, entry)
    spellID = PlainSpellID(spellID)
    if not spellID then return end
    local list = spellIndex[spellID]
    if not list then list = {}; spellIndex[spellID] = list end
    list[#list + 1] = entry
end

local function RebuildIndex()
    indexDirty = false
    for k in pairs(spellIndex) do spellIndex[k] = nil end

    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.Entries then return end

    for entry in ABE.Entries() do
        local content = ABE.GetContentCached and ABE.GetContentCached(entry) or nil
        local sid = content and PlainSpellID(content.spellID)
        if sid then
            AddToIndex(sid, entry)
            -- Talent-morphed spells glow under their override ID.
            if C_Spell and C_Spell.GetOverrideSpell then
                local ok, override = pcall(C_Spell.GetOverrideSpell, sid)
                if ok then
                    override = PlainSpellID(override)
                    if override and override ~= sid then AddToIndex(override, entry) end
                end
            end
        end
    end
end

local function Index()
    if indexDirty then RebuildIndex() end
    return spellIndex
end

function G.MarkIndexDirty() indexDirty = true end

-- =====================================================================
-- BLIZZARD OVERLAY SUPPRESSION
-- Our own glow replaces it, so the stock one must not double up.
-- =====================================================================

local function HideBlizzardGlow(frame)
    if not frame then return end
    local alert = frame.SpellActivationAlert
    if alert then
        pcall(alert.Hide, alert)
        if alert.ProcLoopFlipbook  then pcall(alert.ProcLoopFlipbook.Hide,  alert.ProcLoopFlipbook)  end
        if alert.ProcStartFlipbook then pcall(alert.ProcStartFlipbook.Hide, alert.ProcStartFlipbook) end
    end
    if frame.overlay then pcall(frame.overlay.Hide, frame.overlay) end
    if frame.Overlay then pcall(frame.Overlay.Hide, frame.Overlay) end
end

-- =====================================================================
-- LIBCUSTOMGLOW DISPATCH
-- =====================================================================

local function StopType(frame, glowType, key)
    if not LCG then return end
    if     glowType == "Pixel Glow"         then pcall(LCG.PixelGlow_Stop, frame, key)
    elseif glowType == "Autocast Shine"     then pcall(LCG.AutoCastGlow_Stop, frame, key)
    elseif glowType == "Proc Glow"          then pcall(LCG.ProcGlow_Stop, frame, key)
    elseif glowType == "Action Button Glow" then pcall(LCG.ButtonGlow_Stop, frame)
    end
end

local function StopAll(frame, key)
    if LCG then
        pcall(LCG.PixelGlow_Stop, frame, key)
        pcall(LCG.AutoCastGlow_Stop, frame, key)
        pcall(LCG.ProcGlow_Stop, frame, key)
    end
end

local function StartType(frame, glowType, color, key, db)
    if glowType == "Blizzard Glow" then
        if ActionButton_ShowOverlayGlow then
            pcall(ActionButton_ShowOverlayGlow, frame)
        end
        return
    end
    if not LCG then return end

    if glowType == "Pixel Glow" then
        pcall(LCG.PixelGlow_Start, frame, color,
            math.floor(db.pixelLines or DEFAULTS.pixelLines),
            db.pixelFrequency or DEFAULTS.pixelFrequency,
            nil,
            db.pixelThickness or DEFAULTS.pixelThickness,
            0, 0, false, key)
    elseif glowType == "Autocast Shine" then
        pcall(LCG.AutoCastGlow_Start, frame, color,
            math.floor(db.autoParticles or DEFAULTS.autoParticles),
            db.autoFrequency or DEFAULTS.autoFrequency,
            db.autoScale or DEFAULTS.autoScale,
            0, 0, key)
    elseif glowType == "Action Button Glow" then
        pcall(LCG.ButtonGlow_Start, frame, color,
            db.buttonFrequency or DEFAULTS.buttonFrequency)
    elseif glowType == "Proc Glow" then
        pcall(LCG.ProcGlow_Start, frame, {
            color = color, startAnim = false, xOffset = 0, yOffset = 0, key = key,
        })
    end
end

local function NormaliseColor(c, fallback)
    if type(c) ~= "table" then c = fallback end
    return { c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 }
end

-- =====================================================================
-- APPLY / CLEAR PER SOURCE
-- =====================================================================

local function SetProcGlow(entry, on)
    local frame = entry and entry.frame
    if not frame then return end
    local db = GetSettings()

    if on and db.procEnabled then
        if activeProc[entry] then return end
        activeProc[entry] = db.procType
        if db.procType ~= "Blizzard Glow" then HideBlizzardGlow(frame) end
        StartType(frame, db.procType, NormaliseColor(db.procColor, DEFAULTS.procColor), PROC_KEY, db)
    else
        local was = activeProc[entry]
        if not was then return end
        activeProc[entry] = nil
        StopType(frame, was, PROC_KEY)
        if was == "Blizzard Glow" and ActionButton_HideOverlayGlow then
            pcall(ActionButton_HideOverlayGlow, frame)
        end
    end
end

local function SetAssistGlow(entry, on)
    local frame = entry and entry.frame
    if not frame then return end
    local db = GetSettings()

    -- ButtonGlow has no key, so only one of the two sources can own it.
    -- Proc is the more urgent signal and wins the slot.
    if on and db.assistEnabled
       and not (db.assistType == "Action Button Glow" and activeProc[entry]) then
        if activeAssist[entry] then return end
        activeAssist[entry] = db.assistType
        if db.assistType ~= "Blizzard Glow" then HideBlizzardGlow(frame) end
        StartType(frame, db.assistType, NormaliseColor(db.assistColor, DEFAULTS.assistColor), ASSIST_KEY, db)
    else
        local was = activeAssist[entry]
        if not was then return end
        activeAssist[entry] = nil
        StopType(frame, was, ASSIST_KEY)
        if was == "Blizzard Glow" and ActionButton_HideOverlayGlow then
            pcall(ActionButton_HideOverlayGlow, frame)
        end
    end
end

-- =====================================================================
-- RESOLUTION PASSES
-- =====================================================================

local function EntriesForSpell(spellID)
    spellID = PlainSpellID(spellID)
    if not spellID then return nil end
    return Index()[spellID]
end

local function EnsurePersistTicker()
    if persistTicker then return end
    persistTicker = C_Timer.NewTicker(PERSIST_RATE, function()
        if not next(activeProc) and not next(activeAssist) then
            persistTicker:Cancel()
            persistTicker = nil
            return
        end
        -- Blizzard's own overlay can come back on its next button update.
        for entry, kind in pairs(activeProc) do
            if kind ~= "Blizzard Glow" then HideBlizzardGlow(entry.frame) end
        end
        for entry, kind in pairs(activeAssist) do
            if kind ~= "Blizzard Glow" then HideBlizzardGlow(entry.frame) end
        end
    end)
end

function G.RefreshProc()
    local db = GetSettings()

    -- Clear everything that should no longer glow.
    for entry in pairs(activeProc) do
        local content = TomoMod_ABEngine and TomoMod_ABEngine.GetContentCached(entry)
        local sid = content and PlainSpellID(content.spellID)
        if not db.procEnabled or not sid or not procSpells[sid] then
            SetProcGlow(entry, false)
        end
    end

    if not db.procEnabled then return end
    for spellID in pairs(procSpells) do
        local list = EntriesForSpell(spellID)
        if list then
            for i = 1, #list do SetProcGlow(list[i], true) end
        end
    end
    if next(activeProc) then EnsurePersistTicker() end
end

function G.RefreshAssist()
    local db = GetSettings()

    for entry in pairs(activeAssist) do
        local content = TomoMod_ABEngine and TomoMod_ABEngine.GetContentCached(entry)
        local sid = content and PlainSpellID(content.spellID)
        if not db.assistEnabled or not sid or sid ~= assistSpell then
            SetAssistGlow(entry, false)
        end
    end

    if not db.assistEnabled or not assistSpell then return end
    local list = EntriesForSpell(assistSpell)
    if list then
        for i = 1, #list do SetAssistGlow(list[i], true) end
    end
    if next(activeAssist) then EnsurePersistTicker() end
end

function G.RefreshAll()
    indexDirty = true
    G.RefreshProc()
    G.RefreshAssist()
end

-- Called by the config panel: styles may have changed, so tear every glow
-- down with its previous type before rebuilding.
function G.ApplySettings()
    for entry in pairs(activeProc) do
        StopAll(entry.frame, PROC_KEY)
        if LCG then pcall(LCG.ButtonGlow_Stop, entry.frame) end
        activeProc[entry] = nil
    end
    for entry in pairs(activeAssist) do
        StopAll(entry.frame, ASSIST_KEY)
        activeAssist[entry] = nil
    end
    G.RefreshAll()
end

-- =====================================================================
-- ASSISTED COMBAT POLLING
-- No event exists for "the recommendation changed", so this polls. It is
-- gated the same way the engine's range ticker is: only while it can
-- matter, and only when the feature is enabled and available.
-- =====================================================================

local function AssistAvailable()
    if not C_AssistedCombat then return false end
    if C_AssistedCombat.IsAvailable then
        local ok, res = pcall(C_AssistedCombat.IsAvailable)
        if ok and res == false then return false end
    end
    return C_AssistedCombat.GetNextCastSpell ~= nil
end

local function PollAssist()
    local db = GetSettings()
    if not db.assistEnabled or not AssistAvailable() then
        if assistSpell ~= nil then assistSpell = nil; G.RefreshAssist() end
        return
    end

    local ok, sid = pcall(C_AssistedCombat.GetNextCastSpell)
    sid = ok and PlainSpellID(sid) or nil
    if sid ~= assistSpell then
        assistSpell = sid
        G.RefreshAssist()
    end
end

local function ShouldPollAssist()
    local db = GetSettings()
    if not db.assistEnabled then return false end
    if UnitAffectingCombat("player") then return true end
    if UnitExists("target") then return true end
    return false
end

local function UpdateAssistTicker()
    if ShouldPollAssist() then
        if not assistTicker then
            local db = GetSettings()
            local interval = tonumber(db.assistInterval) or DEFAULTS.assistInterval
            if interval < 0.05 then interval = 0.05 end
            assistTicker = C_Timer.NewTicker(interval, PollAssist)
            PollAssist()
        end
    elseif assistTicker then
        assistTicker:Cancel()
        assistTicker = nil
        if assistSpell ~= nil then assistSpell = nil; G.RefreshAssist() end
    end
end

G.UpdateAssistTicker = UpdateAssistTicker

-- =====================================================================
-- EVENTS
-- =====================================================================

local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        local sid = PlainSpellID(arg1)
        if sid and not procSpells[sid] then
            procSpells[sid] = true
            G.RefreshProc()
        end

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        local sid = PlainSpellID(arg1)
        if sid and procSpells[sid] then
            procSpells[sid] = nil
            G.RefreshProc()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        indexDirty = true
        -- Overlays already up before we loaded do not re-fire their event.
        if IsSpellOverlayed then
            for spellID in pairs(Index()) do
                local ok, res = pcall(IsSpellOverlayed, spellID)
                if ok and res == true then procSpells[spellID] = true end
            end
        end
        G.RefreshAll()
        UpdateAssistTicker()

    else -- combat / target changes: only the assist ticker gate cares
        UpdateAssistTicker()
    end
end)

local function RegisterEvents()
    for _, ev in ipairs({
        "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW",
        "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "PLAYER_TARGET_CHANGED",
    }) do
        pcall(eventFrame.RegisterEvent, eventFrame, ev)
    end
end

-- =====================================================================
-- ENGINE BINDING
-- =====================================================================

local function OnEntryChanged(entry)
    indexDirty = true
    -- The slot may now hold a different spell: drop stale glows on it.
    if activeProc[entry] then SetProcGlow(entry, false) end
    if activeAssist[entry] then SetAssistGlow(entry, false) end
    G.RefreshProc()
    G.RefreshAssist()
end

local function OnUnregister(entry)
    indexDirty = true
    if activeProc[entry] then SetProcGlow(entry, false) end
    if activeAssist[entry] then SetAssistGlow(entry, false) end
end

function G.Bind()
    if bound then return end
    local ABE = TomoMod_ABEngine
    if not ABE or not ABE.RegisterCallback then return end
    bound = true
    ABE.RegisterCallback("ABGlow", "register",   OnEntryChanged)
    ABE.RegisterCallback("ABGlow", "action",     OnEntryChanged)
    ABE.RegisterCallback("ABGlow", "unregister", OnUnregister)
    RegisterEvents()
end

function G.IsBound() return bound end

-- =====================================================================
-- BOOT
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(0.9, function()
        G.Bind()
        C_Timer.After(0.5, function()
            G.RefreshAll()
            UpdateAssistTicker()
        end)
    end)
end)
