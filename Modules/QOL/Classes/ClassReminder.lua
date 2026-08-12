-- =====================================
-- ClassReminder.lua — Missing Buff / Form / Stance / Aura Reminder
--
-- Detection notes (Midnight 12.x):
--   * Forms and stances are matched by SPELL ID through GetShapeshiftFormInfo,
--     never by bar index. The index of a form on the stance bar depends on
--     which talents are picked, so hardcoded indices silently point at the
--     wrong form (or at nothing) as soon as a build changes.
--   * A form that is absent from the stance bar is not "missing", it is not
--     learned. Those entries are suppressed rather than reported.
--   * Paladin auras are player buffs, not shapeshift forms.
--   * Aura data for spell IDs outside NON_SECRET_SPELL_IDS becomes secret once
--     the player enters combat. A "missing" verdict on such an ID during
--     combat would be a guess, so those checks are skipped instead.
--
-- Display notes:
--   * Reminders are icons, and out of combat each icon is a
--     SecureActionButton: left-click casts the missing buff or form directly.
--     Middle-click dismisses that reminder until the next loading screen.
--   * Secure buttons cannot be shown, hidden or reconfigured under combat
--     lockdown, so combat is served by a parallel pool of plain frames while
--     the secure row is faded to alpha 0. Nothing is clickable in combat --
--     the same row would otherwise be a lie about what pressing it does.
-- =====================================

TomoMod_ClassReminder = TomoMod_ClassReminder or {}
local CR = TomoMod_ClassReminder

local L = TomoMod_L

local issecretvalue = issecretvalue
local InCombatLockdown = InCombatLockdown

-- ── Helpers ──────────────────────────────────────────────────

local function GetDB()
    return TomoModDB and TomoModDB.classReminder
end

-- issecretvalue() runs before ANY comparison on the argument.
local function SafeBool(v)
    if issecretvalue(v) then return nil end
    if type(v) ~= "boolean" then return nil end
    return v
end

local function SafeNum(v)
    if issecretvalue(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

local function CurrentSpecID()
    local getIdx = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
    local idx = getIdx and getIdx()
    if not idx then return 0 end
    local id = GetSpecializationInfo and GetSpecializationInfo(idx)
    return id or 0
end

local function IsKnown(spellID)
    if not spellID then return true end
    return (IsPlayerSpell and IsPlayerSpell(spellID)) or (IsSpellKnown and IsSpellKnown(spellID)) or false
end

local function InPvPInstance()
    local _, iType = IsInInstance()
    return iType == "pvp" or iType == "arena"
end

-- ── Context ──────────────────────────────────────────────────

local INSTANCED_TYPES = {
    party = true, raid = true, scenario = true, arena = true, pvp = true,
}

local function InInstancedContent()
    local inside, iType = IsInInstance()
    return (inside and INSTANCED_TYPES[iType]) and true or false
end

-- States where a reminder is pure noise: the player cannot act on it, or is
-- about to be handed a fresh set of buffs anyway. Every one of these is
-- event-driven, so nothing here needs polling.
local function InSuppressedState()
    local db = GetDB()
    if UnitIsDeadOrGhost("player") then return true end
    if UnitInVehicle("player") then return true end
    if IsMounted() and IsFlying() then return true end
    if db and db.hideWhenResting ~= false and IsResting() then return true end
    return false
end

-- ── Secret-value whitelist ───────────────────────────────────
-- Spell IDs whose aura data stays readable through combat lockdown in 12.x.
-- Devotion Aura (465) is deliberately absent: it is contextually secret in
-- Midnight, so its entry carries oocOnly instead.

local NON_SECRET_SPELL_IDS = {
    [1126]   = true, [432661] = true,   -- Mark of the Wild (+ talent variant)
    [1459]   = true, [432778] = true,   -- Arcane Intellect (+ talent variant)
    [6673]   = true,                    -- Battle Shout
    [21562]  = true,                    -- Power Word: Fortitude
    [462854] = true,                    -- Skyfury
    -- Blessing of the Bronze: one buff ID per receiving class
    [381732] = true, [381741] = true, [381746] = true, [381748] = true,
    [381749] = true, [381750] = true, [381751] = true, [381752] = true,
    [381753] = true, [381754] = true, [381756] = true, [381757] = true,
    [381758] = true,
    -- Earth Shield's self component: castable and readable in combat, unlike
    -- Lightning/Water Shield, which stay out-of-combat only.
    [974]    = true, [383648] = true,
}

-- ── Class Data ──────────────────────────────────────────────
-- Every entry:
--   nameKey   locale fallback when the spell name cannot be resolved
--   castSpell the spell the player would press; also the "do I know this?" gate
--             and the source of the displayed (client-localised) name
--   kind      "buff"    -> player aura lookup by ID
--             "form"    -> stance bar lookup by spell ID
--             "enchant" -> temporary weapon enchant lookup by enchant ID
--             "poison"  -> Rogue poison slot, counted per category
--   buffIDs   ("buff") every aura ID that satisfies the entry, talent variants
--             included -- a missing variant is a permanent false reminder
--   formIDs   ("form") every form spell ID that satisfies the entry; defaults
--             to { castSpell } when omitted
--   enchantIDs ("enchant") every temporary enchant ID that satisfies the entry,
--             on either weapon; a list because mutually exclusive imbues (the
--             Paladin rites) share one reminder
--   poisons   ("poison") the spells that can fill this category's slots
--   castSpellFn optional, resolves castSpell at read time when it depends on
--             spec or on what the player has learned
--   labelFromKey optional, label comes from the locale key rather than the
--             spell name -- for entries that stand for a category
--   specID / specIDs  optional, entry only applies to those specialisations
--   requireTalent / excludeTalent  optional, gate on a known spell
--   group     optional, "all" | "intellect" | "attackPower": this is a group
--             buff, and with Show Others Missing on it also fires when an
--             in-range beneficiary lacks it
--   oocOnly   optional, never evaluated while in combat
--   noPvP     optional, never evaluated inside an arena or battleground

-- Elemental Orbit (383010) turns Earth Shield into a self buff and frees the
-- other shield slot, so which shield the player should press depends on spec.
local function ShieldCastSpell()
    return (CurrentSpecID() == 264) and 52127 or 192106   -- Water / Lightning
end

-- The two Lightsmith rites are mutually exclusive weapon enchants; point the
-- reminder at whichever one the player actually has.
local function RiteCastSpell()
    if IsKnown(433583) then return 433583 end   -- Rite of Adjuration
    return 433568                                -- Rite of Sanctification
end

-- Poison categories: show the first poison the player knows, so the click
-- casts something real even when several are talented.
local function FirstKnown(list)
    for i = 1, #list do
        if IsKnown(list[i]) then return list[i] end
    end
    return list[1]
end

local LETHAL_POISONS    = { 2823, 381664, 315584, 8679 }
local NONLETHAL_POISONS = { 5761, 381637, 3408 }
local DRAGON_TEMPERED_BLADES = 381801   -- allows a second poison per category

local CLASS_DATA = {
    PRIEST = {
        { nameKey = "cr_fortitude",  kind = "buff", castSpell = 21562,
          buffIDs = { 21562 }, group = "all" },
        { nameKey = "cr_shadowform", kind = "form", castSpell = 232698,
          formIDs = { 232698, 15473 }, specID = 258 },
    },
    MAGE = {
        { nameKey = "cr_arcane_intellect", kind = "buff", castSpell = 1459,
          buffIDs = { 1459, 432778 }, group = "intellect" },
    },
    ROGUE = {
        -- One reminder per category, not per poison: the slots are what matter.
        -- Poisons cannot be applied in combat, so both are out-of-combat only.
        { nameKey = "cr_lethal_poison", kind = "poison", labelFromKey = true,
          poisons = LETHAL_POISONS, oocOnly = true,
          castSpellFn = function() return FirstKnown(LETHAL_POISONS) end },
        { nameKey = "cr_nonlethal_poison", kind = "poison", labelFromKey = true,
          poisons = NONLETHAL_POISONS, oocOnly = true,
          castSpellFn = function() return FirstKnown(NONLETHAL_POISONS) end },
    },
    SHAMAN = {
        { nameKey = "cr_skyfury", kind = "buff", castSpell = 462854,
          buffIDs = { 462854 }, group = "all" },
        -- Weapon imbues. Separate entries because Enhancement runs two at once;
        -- the "do I know this?" gate keeps the others quiet for the other specs.
        { nameKey = "cr_flametongue",   kind = "enchant", castSpell = 318038,
          enchantIDs = { 5400 }, oocOnly = true },
        { nameKey = "cr_windfury",      kind = "enchant", castSpell = 33757,
          enchantIDs = { 5401 }, oocOnly = true },
        { nameKey = "cr_earthliving",   kind = "enchant", castSpell = 382021,
          enchantIDs = { 6498 }, oocOnly = true },
        { nameKey = "cr_tidecaller",    kind = "enchant", castSpell = 457496,
          enchantIDs = { 7528 }, oocOnly = true },
        { nameKey = "cr_thunderstrike", kind = "enchant", castSpell = 462757,
          enchantIDs = { 7587 }, oocOnly = true },
        -- Shields. With Elemental Orbit the player carries Earth Shield on
        -- themselves AND one of the other two; without it, any shield counts.
        { nameKey = "cr_earth_shield_self", kind = "buff", castSpell = 974,
          buffIDs = { 383648 }, requireTalent = 383010 },
        { nameKey = "cr_orbit_shield", kind = "buff", labelFromKey = true,
          castSpellFn = ShieldCastSpell, buffIDs = { 192106, 52127 },
          requireTalent = 383010 },
        { nameKey = "cr_shield", kind = "buff", labelFromKey = true,
          castSpellFn = ShieldCastSpell, buffIDs = { 974, 192106, 52127 },
          excludeTalent = 383010 },
    },
    DRUID = {
        { nameKey = "cr_mark_of_the_wild", kind = "buff", castSpell = 1126,
          buffIDs = { 1126, 432661 }, group = "all" },
        { nameKey = "cr_cat_form",     kind = "form", castSpell = 768,   specID = 103 },
        { nameKey = "cr_bear_form",    kind = "form", castSpell = 5487,  specID = 104 },
        { nameKey = "cr_moonkin_form", kind = "form", castSpell = 24858,
          formIDs = { 24858, 197625 }, specID = 102 },
    },
    WARRIOR = {
        { nameKey = "cr_battle_shout", kind = "buff", castSpell = 6673,
          buffIDs = { 6673 }, group = "attackPower" },
        -- Stances are talent-granted shapeshift forms, one per specialisation.
        { nameKey = "cr_battle_stance",    kind = "form", castSpell = 386164, specID = 71 },
        { nameKey = "cr_berserker_stance", kind = "form", castSpell = 386196, specID = 72 },
        { nameKey = "cr_defensive_stance", kind = "form", castSpell = 386208, specID = 73 },
    },
    PALADIN = {
        -- Devotion / Crusader / Concentration Aura. Contextually secret in
        -- Midnight, hence out-of-combat only and never inside PvP instances.
        { nameKey = "cr_aura", kind = "buff", castSpell = 465,
          buffIDs = { 465, 32223, 317920 }, oocOnly = true, noPvP = true },
        -- Lightsmith rites: two mutually exclusive weapon enchants sharing one
        -- reminder, so having either one satisfies it.
        { nameKey = "cr_paladin_rite", kind = "enchant", labelFromKey = true,
          castSpellFn = RiteCastSpell, enchantIDs = { 7144, 7143 },
          oocOnly = true },
    },
    EVOKER = {
        { nameKey = "cr_blessing_bronze", kind = "buff", castSpell = 364342,
          buffIDs = {
              381732, 381741, 381746, 381748, 381749, 381750, 381751,
              381752, 381753, 381754, 381756, 381757, 381758,
          }, group = "all" },
    },
}

-- Entries that name a single form spell get their one-element lookup list
-- built once here, so the check path never allocates.
for _, entries in pairs(CLASS_DATA) do
    for _, entry in ipairs(entries) do
        if entry.kind == "form" and not entry.formIDs then
            entry._selfIDs = { entry.castSpell }
        end
    end
end

-- Displayed name: the client's own localisation of the spell, so every locale
-- gets the in-game wording for free. The locale table is only a fallback for
-- the brief window before the spell cache is populated.
-- The spell this entry would have the player press. Resolved at read time for
-- entries whose answer depends on spec or on what is learned.
local function EntryCastSpell(entry)
    if entry.castSpellFn then return entry.castSpellFn() end
    return entry.castSpell
end

local function EntryLabel(entry)
    -- Entries that stand for a category (a poison slot, "a shield") name the
    -- category, not whichever spell happens to fill it.
    if not entry.labelFromKey then
        local id = EntryCastSpell(entry)
        local n = id and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
        if n and n ~= "" then return n end
    end
    return (L and L[entry.nameKey]) or entry.nameKey
end

-- ── State ────────────────────────────────────────────────────

local playerClass
local currentSpecID
local crPreview = false   -- aperçu actif : la mise à jour ne doit pas l'écraser

-- ── Display constants ────────────────────────────────────────

local FONT_LABEL   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local TEAL         = { r = 0.047, g = 0.824, b = 0.624 }
local FALLBACK_TEX = 134400   -- inv_misc_questionmark

local LCG      = LibStub and LibStub("LibCustomGlow-1.0", true)
local GLOW_KEY = "TomoModClassReminder"

-- Glow identifiers stored in the database. Kept as plain strings so a profile
-- stays readable, and matched here rather than indexed, so an unknown value
-- from an older or hand-edited profile simply means "no glow".
local GLOW_NONE     = "None"
local GLOW_PIXEL    = "Pixel Glow"
local GLOW_AUTOCAST = "Autocast Shine"
local GLOW_BUTTON   = "Action Button Glow"
local GLOW_PROC     = "Proc Glow"

CR.GLOW_TYPES = { GLOW_NONE, GLOW_PIXEL, GLOW_AUTOCAST, GLOW_BUTTON, GLOW_PROC }

-- ── Anchor & icon pools ──────────────────────────────────────
-- anchor      plain container; the only frame the mover ever touches
-- securePool  SecureActionButton row, used out of combat, clickable
-- combatPool  plain frames, used under combat lockdown and for previews
--
-- The anchor is shown once and never hidden again: it parents protected
-- buttons, and hiding the parent of a protected frame during combat is exactly
-- the kind of call that propagates taint. Visibility is carried by the icons
-- themselves plus the anchor's alpha, neither of which is protected.

local anchor = CreateFrame("Frame", "TomoMod_ClassReminderFrame", UIParent)
anchor:SetSize(40, 40)
anchor:SetFrameStrata("HIGH")
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:EnableMouse(false)
anchor:Show()
anchor:SetAlpha(0)

local securePool,  secureActive = {}, {}
local combatPool,  combatActive = {}, {}
local dragOverlay, dragLabel
local dismissed = {}      -- [nameKey] = true, cleared on every loading screen
local isLocked  = true    -- false while the mover has the row in placement mode

local RequestUpdate       -- forward declaration, defined with the throttle

-- ── Position ─────────────────────────────────────────────────

-- Screen-absolute coordinates read from GetLeft/GetBottom. GetPoint would hand
-- back whatever relative anchor the frame happened to be dragged from, which
-- does not survive a scale change.
local function SavePosition()
    local db = GetDB()
    if not db then return end
    local left, bottom = anchor:GetLeft(), anchor:GetBottom()
    if not left or not bottom then return end
    local s = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.position = {
        point         = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x             = left * s,
        y             = bottom * s,
    }
end

local function ApplyPosition()
    if InCombatLockdown() then return end
    local db = GetDB()
    anchor:ClearAllPoints()
    local p = db and db.position
    if p and p.point then
        anchor:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- ── Glow ─────────────────────────────────────────────────────

local function StopGlow(f)
    if not LCG then return end
    LCG.PixelGlow_Stop(f, GLOW_KEY)
    LCG.AutoCastGlow_Stop(f, GLOW_KEY)
    LCG.ProcGlow_Stop(f, GLOW_KEY)
    LCG.ButtonGlow_Stop(f)
end

-- The colour table is cached per frame: LibCustomGlow keeps a reference to
-- whatever table it is handed, so a shared one would retint every live glow at
-- once and a fresh one per call would churn the collector on every refresh.
local function StartGlow(f)
    StopGlow(f)
    if not LCG then return end
    local db = GetDB()
    local kind = (db and db.glowType) or GLOW_NONE
    if kind == GLOW_NONE then return end

    local c = (db and db.glowColor) or nil
    local col = f._crGlowColor
    if not col then col = {}; f._crGlowColor = col end
    col[1] = (c and c.r) or 1.0
    col[2] = (c and c.g) or 0.78
    col[3] = (c and c.b) or 0.14
    col[4] = 1

    if kind == GLOW_PIXEL then
        LCG.PixelGlow_Start(f, col, 8, 0.25, nil, 2, 0, 0, false, GLOW_KEY)
    elseif kind == GLOW_AUTOCAST then
        LCG.AutoCastGlow_Start(f, col, 4, 0.25, 1, 0, 0, GLOW_KEY)
    elseif kind == GLOW_BUTTON then
        LCG.ButtonGlow_Start(f, col, 0.125)
    elseif kind == GLOW_PROC then
        LCG.ProcGlow_Start(f, {
            color = col, startAnim = false, xOffset = 0, yOffset = 0, key = GLOW_KEY,
        })
    end
end

-- ── Icon pools ───────────────────────────────────────────────

local function EntryTexture(entry)
    local id = EntryCastSpell(entry)
    local t = id and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
    return t or FALLBACK_TEX
end

local function IconOnEnter(self)
    if not self._spellID then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self._spellID)
    GameTooltip:Show()
end

local function IconOnLeave()
    GameTooltip:Hide()
end

-- Shared visual skin for both pools, so a secure button and its combat stand-in
-- are pixel-identical and the swap at the combat boundary is invisible.
local function DressIcon(f)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0, 0, 0, 1)
    f:SetBackdropBorderColor(0, 0, 0, 1)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f._icon = icon

    local label = f:CreateFontString(nil, "OVERLAY")
    label:SetPoint("TOP", f, "BOTTOM", 0, -2)
    label:SetFont(FONT_LABEL, 12, "OUTLINE")
    f._label = label

    f:Hide()
end

local function GetOrCreateSecure(i)
    local btn = securePool[i]
    if btn then return btn end
    btn = CreateFrame("Button", "TomoMod_ClassReminderIcon" .. i, anchor,
        "SecureActionButtonTemplate, BackdropTemplate")
    btn:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "MiddleButtonUp")
    -- Right-click falls through to the world so the row never eats camera turns.
    if btn.SetPassThroughButtons then
        securecallfunction(btn.SetPassThroughButtons, btn, "RightButton")
    end
    DressIcon(btn)
    btn:SetScript("OnEnter", IconOnEnter)
    btn:SetScript("OnLeave", IconOnLeave)
    -- PostClick, not OnClick: the secure handler must run first and untouched.
    btn:HookScript("PostClick", function(self, button)
        if button ~= "MiddleButton" or not self._nameKey then return end
        dismissed[self._nameKey] = true
        if RequestUpdate then RequestUpdate() end
    end)
    securePool[i] = btn
    return btn
end

local function GetOrCreateCombat(i)
    local f = combatPool[i]
    if f then return f end
    f = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    DressIcon(f)
    combatPool[i] = f
    return f
end

-- ── Row rendering ────────────────────────────────────────────

-- Secure buttons cannot be hidden under lockdown. Fading them to zero is not
-- protected, so combat leaves them in place but invisible and the plain pool
-- takes over; the real hide happens on the next out-of-combat pass.
local function HideSecureRow()
    if InCombatLockdown() then
        for i = 1, #secureActive do
            local b = secureActive[i]
            StopGlow(b)
            b:SetAlpha(0)
        end
        return
    end
    for i = 1, #secureActive do
        local b = secureActive[i]
        StopGlow(b)
        b:SetAlpha(1)
        b:Hide()
    end
    wipe(secureActive)
end

local function HideCombatRow()
    for i = 1, #combatActive do
        local f = combatActive[i]
        StopGlow(f)
        f:Hide()
    end
    wipe(combatActive)
end

-- Icons grow from the anchor's CENTER in both directions, so the row's centre
-- stays put as reminders appear and disappear instead of sliding sideways.
local function LayoutRow(active, size, spacing, textH, opacity)
    local n = #active
    if n == 0 then return 0, 0 end
    local totalW = n * size + (n - 1) * spacing
    local startX = -(totalW / 2) + (size / 2)
    for i = 1, n do
        local f = active[i]
        f:SetSize(size, size)
        f:SetAlpha(opacity)
        f:ClearAllPoints()
        f:SetPoint("CENTER", anchor, "CENTER", startX + (i - 1) * (size + spacing), textH / 2)
    end
    return totalW, size + textH
end

-- Populate one pool from `list` and place the row.
-- secure = true picks the clickable out-of-combat pool; it must never be called
-- under lockdown, where every attribute and point on those buttons is locked.
local function ShowEntries(list, secure)
    local db       = GetDB() or {}
    local size     = db.iconSize or 40
    local spacing  = db.iconSpacing or 8
    local showText = db.showText ~= false
    local textSize = db.textSize or 12
    local opacity  = db.opacity or 1.0
    local tc       = db.textColor or { r = 1, g = 1, b = 1 }

    local pool   = secure and securePool   or combatPool
    local active = secure and secureActive or combatActive
    local get    = secure and GetOrCreateSecure or GetOrCreateCombat

    wipe(active)
    for i = 1, #list do
        local entry = list[i]
        local f = get(i)
        local castSpell = EntryCastSpell(entry)
        f._icon:SetTexture(EntryTexture(entry))
        f._spellID = castSpell
        f._nameKey = entry.nameKey
        if showText then
            f._label:SetFont(FONT_LABEL, textSize, "OUTLINE")
            f._label:SetTextColor(tc.r, tc.g, tc.b, 1)
            f._label:SetText(EntryLabel(entry))
            f._label:Show()
        else
            f._label:SetText("")
            f._label:Hide()
        end
        if secure then
            f:SetAttribute("type", castSpell and "spell" or nil)
            f:SetAttribute("spell", castSpell)
            -- Self-buffs are cast on the player; forms and stances take no unit.
            f:SetAttribute("unit", (entry.kind == "buff") and "player" or nil)
        end
        f:Show()
        active[i] = f
    end

    for i = #list + 1, #pool do
        local f = pool[i]
        if f then StopGlow(f); f:Hide() end
    end

    local textH = showText and (textSize + 4) or 0
    local w, h = LayoutRow(active, size, spacing, textH, opacity)
    if w > 0 and not InCombatLockdown() then
        anchor:SetSize(w, h)
    end
    for i = 1, #active do StartGlow(active[i]) end
    anchor:SetAlpha(w > 0 and 1 or 0)
end

-- ── Core Logic ───────────────────────────────────────────────

-- Every tracked ID readable through combat lockdown? Anything else cannot be
-- judged in combat without guessing.
local function AllIDsReadableInCombat(buffIDs)
    for i = 1, #buffIDs do
        if not NON_SECRET_SPELL_IDS[buffIDs[i]] then return false end
    end
    return true
end

local function PlayerHasBuff(buffIDs)
    if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then return true end
    for i = 1, #buffIDs do
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, buffIDs[i])
        if ok and aura ~= nil then return true end
    end
    return false
end

-- Stance bar lookup by spell ID.
-- Returns: known (present on the bar), active (currently the player's form).
-- active is nil when the client hands back a secret value, which the caller
-- reads as "cannot be determined" rather than "missing".
local function GetFormState(formIDs)
    local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
    for i = 1, numForms do
        local _, isActive, _, formSpellID = GetShapeshiftFormInfo(i)
        local sid = SafeNum(formSpellID)
        if sid then
            for j = 1, #formIDs do
                if sid == formIDs[j] then
                    return true, SafeBool(isActive)
                end
            end
        end
    end
    return false, nil
end

-- ── Weapon enchants ──────────────────────────────────────────

-- Main-hand and off-hand temporary enchant IDs, or nil per hand.
-- C_PaperDollInfo is preferred: in 12.1 GetWeaponEnchantInfo is a deprecation
-- shim behind a CVar, so reading it directly is on borrowed time.
local function WeaponEnchantIDs()
    if C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo then
        local mh = C_PaperDollInfo.GetTemporaryEnchantmentInfo(INVSLOT_MAINHAND)
        local oh = C_PaperDollInfo.GetTemporaryEnchantmentInfo(INVSLOT_OFFHAND)
        return mh and SafeNum(mh.enchantID) or nil, oh and SafeNum(oh.enchantID) or nil
    end
    if not GetWeaponEnchantInfo then return nil, nil end
    local hasMH, _, _, mhID, hasOH, _, _, ohID = GetWeaponEnchantInfo()
    return (hasMH and SafeNum(mhID)) or nil, (hasOH and SafeNum(ohID)) or nil
end

local function HasEnchant(enchantIDs)
    local mh, oh = WeaponEnchantIDs()
    if not (mh or oh) then return false end
    for i = 1, #enchantIDs do
        local id = enchantIDs[i]
        if mh == id or oh == id then return true end
    end
    return false
end

-- ── Rogue poisons ────────────────────────────────────────────

-- A category is satisfied when as many of its slots are filled as the player
-- can fill: one, or two with Dragon-Tempered Blades. Counting rather than
-- checking a specific poison is what makes this survive any talent build.
local function PoisonCategorySatisfied(poisons)
    local known, active = 0, 0
    for i = 1, #poisons do
        local id = poisons[i]
        if IsKnown(id) then
            known = known + 1
            local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
            if ok and aura ~= nil then active = active + 1 end
        end
    end
    if known == 0 then return true end   -- nothing to apply, nothing to remind
    local required = IsKnown(DRAGON_TEMPERED_BLADES) and 2 or 1
    if required > known then required = known end
    return active >= required
end

-- ── Group buff tracking ──────────────────────────────────────

-- Classes that actually want the stat. A class is listed when ANY of its specs
-- wants it, so hybrids appear under both: this over-counts a Retribution
-- Paladin for Intellect, never under-counts anyone who needs the buff.
local BUFF_BENEFICIARIES = {
    intellect = {
        MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true,
        SHAMAN = true, MONK = true, EVOKER = true, PALADIN = true,
    },
    attackPower = {
        WARRIOR = true, ROGUE = true, HUNTER = true, DEATHKNIGHT = true,
        PALADIN = true, MONK = true, DRUID = true, DEMONHUNTER = true,
        SHAMAN = true,
    },
}

-- Mirrors the raid frames' range path. UnitInRange is the real answer but can
-- be a secret value inside instances, and Lua cannot branch on a secret; when
-- that happens fall back to UnitIsVisible, which the raid frames' own sweep
-- branches on in plain Lua. Visible is coarser than cast range, but it still
-- excludes the cases that matter -- members in another wing, cross-zone, or in
-- a different phase.
local function UnitInBuffRange(unit)
    if UnitIsUnit(unit, "player") then return true end
    if not UnitExists(unit) then return false end
    local inRange, checked = UnitInRange(unit)
    if checked and SafeBool(inRange) ~= nil and not issecretvalue(checked) then
        return inRange == true
    end
    local vis = UnitIsVisible(unit)
    if issecretvalue(vis) then return true end
    return vis == true
end

local function UnitIsBuffable(unit)
    return UnitExists(unit) and UnitIsPlayer(unit)
        and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
end

-- Only whitelisted IDs are consulted: everything else on another player is a
-- secret value, and a nil answer there would read as "missing" and produce a
-- reminder nobody can act on.
local function UnitHasBuff(unit, buffIDs)
    for i = 1, #buffIDs do
        local id = buffIDs[i]
        if NON_SECRET_SPELL_IDS[id] then
            local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, id)
            if ok and aura ~= nil and not issecretvalue(aura) then return true end
        end
    end
    return false
end

local _groupTokens = {}
for i = 1, 40 do _groupTokens["raid" .. i] = true end

local function AnyGroupMemberMissing(entry)
    local benefits = entry.group ~= "all" and BUFF_BENEFICIARIES[entry.group] or nil
    local prefix, count
    if IsInRaid() then
        prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then
        prefix, count = "party", GetNumSubgroupMembers()
    else
        return false
    end
    for i = 1, count do
        local unit = prefix .. i
        if UnitIsBuffable(unit) and not UnitIsUnit(unit, "player")
           and UnitInBuffRange(unit) then
            -- [12.1] A secret class token cannot index the benefits table.
            -- Unknown is treated as a beneficiary: a reminder for someone who
            -- does not need the buff is a smaller failure than never
            -- reminding for someone who does.
            local class = TomoMod_Utils and TomoMod_Utils.UnitClassToken(unit)
            -- The class gate runs before the aura read, so non-beneficiaries
            -- are skipped without touching the aura API at all.
            if (not benefits or not class or benefits[class]) and not UnitHasBuff(unit, entry.buffIDs) then
                return true
            end
        end
    end
    return false
end

local _cr_missing = {}

local function CheckMissing()
    wipe(_cr_missing)
    local db = GetDB()
    if not db or not db.enabled then return _cr_missing end

    local entries = CLASS_DATA[playerClass]
    if not entries then return _cr_missing end

    -- Nothing to remind about while dead, flying, in a vehicle or resting.
    if InSuppressedState() then return _cr_missing end

    -- Where the row is allowed to appear at all.
    local showIn = db.showIn or "always"
    if showIn == "instances" and not InInstancedContent() then return _cr_missing end
    if showIn == "group" and not IsInGroup() then return _cr_missing end

    local inCombat = InCombatLockdown()
    local inPvP = InPvPInstance()
    -- Group checks read other players' auras, which are secret in combat, and
    -- consult ranges that move constantly. Own-buff checks continue as normal.
    local groupCheck = db.showOthersMissing and not inCombat and IsInGroup()

    local perEntry = db.entries

    for _, entry in ipairs(entries) do
        local skip = false
        local castSpell = EntryCastSpell(entry)

        -- Per-entry opt-out from the coverage grid. Absent means enabled, so a
        -- profile that predates the grid tracks everything, as it always did.
        if perEntry and perEntry[entry.nameKey] == false then skip = true end
        if not skip and dismissed[entry.nameKey] then skip = true end
        if not skip and entry.specID and entry.specID ~= currentSpecID then skip = true end
        if not skip and entry.specIDs then
            local match = false
            for i = 1, #entry.specIDs do
                if entry.specIDs[i] == currentSpecID then match = true; break end
            end
            if not match then skip = true end
        end
        if not skip and entry.oocOnly and inCombat then skip = true end
        if not skip and entry.noPvP and inPvP then skip = true end
        if not skip and entry.requireTalent and not IsKnown(entry.requireTalent) then skip = true end
        if not skip and entry.excludeTalent and IsKnown(entry.excludeTalent) then skip = true end
        if not skip and not IsKnown(castSpell) then skip = true end

        if not skip then
            if entry.kind == "form" then
                local known, active = GetFormState(entry.formIDs or entry._selfIDs)
                -- Not on the bar means not learned, and a secret active flag
                -- means undecidable. Neither is a missing form.
                if known and active == false then
                    _cr_missing[#_cr_missing + 1] = entry
                end

            elseif entry.kind == "enchant" then
                if not HasEnchant(entry.enchantIDs) then
                    _cr_missing[#_cr_missing + 1] = entry
                end

            elseif entry.kind == "poison" then
                if not PoisonCategorySatisfied(entry.poisons) then
                    _cr_missing[#_cr_missing + 1] = entry
                end

            else
                local readable = not inCombat or AllIDsReadableInCombat(entry.buffIDs)
                if readable then
                    if not PlayerHasBuff(entry.buffIDs) then
                        _cr_missing[#_cr_missing + 1] = entry
                    elseif groupCheck and entry.group and AnyGroupMemberMissing(entry) then
                        _cr_missing[#_cr_missing + 1] = entry
                    end
                end
            end
        end
    end

    return _cr_missing
end

-- Sample row for the preview button and for placement mode: everything this
-- class can be reminded about, or one generic slot for a class with no entries.
local FALLBACK_ENTRY = { nameKey = "cr_preview_sample", kind = "buff", buffIDs = {} }
local _previewList = {}

local function BuildPreviewList()
    wipe(_previewList)
    local entries = playerClass and CLASS_DATA[playerClass]
    if entries then
        for i = 1, #entries do _previewList[i] = entries[i] end
    end
    if #_previewList == 0 then _previewList[1] = FALLBACK_ENTRY end
    return _previewList
end

local function HideEverything()
    HideCombatRow()
    HideSecureRow()
    anchor:SetAlpha(0)
end

local function UpdateDisplay()
    local db = GetDB()
    if not db or not db.enabled then
        HideEverything()
        return
    end
    -- The preview timer and placement mode own the row while they are up.
    if crPreview or not isLocked then return end

    local list = CheckMissing()

    if InCombatLockdown() then
        -- Fade the stale secure row, drive the plain pool instead.
        HideSecureRow()
        HideCombatRow()
        if #list > 0 then ShowEntries(list, false) else anchor:SetAlpha(0) end
        return
    end

    HideCombatRow()
    HideSecureRow()
    anchor:SetScale(db.scale or 1.0)
    ApplyPosition()
    if #list > 0 then ShowEntries(list, true) else anchor:SetAlpha(0) end
end

-- ── Placement mode ───────────────────────────────────────────

local function CreateDragOverlay()
    if dragOverlay then return end
    dragOverlay = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    dragOverlay:SetPoint("TOPLEFT", -4, 4)
    dragOverlay:SetPoint("BOTTOMRIGHT", 4, -4)
    dragOverlay:SetFrameLevel(anchor:GetFrameLevel() + 30)
    dragOverlay:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dragOverlay:SetBackdropColor(TEAL.r, TEAL.g, TEAL.b, 0.18)
    dragOverlay:SetBackdropBorderColor(TEAL.r, TEAL.g, TEAL.b, 0.80)
    dragOverlay:EnableMouse(true)
    dragOverlay:RegisterForDrag("LeftButton")
    dragOverlay:SetScript("OnDragStart", function() anchor:StartMoving() end)
    dragOverlay:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        SavePosition()
    end)

    dragLabel = dragOverlay:CreateFontString(nil, "OVERLAY")
    dragLabel:SetFont(FONT_LABEL, 9, "OUTLINE")
    dragLabel:SetPoint("BOTTOM", dragOverlay, "TOP", 0, 3)
    dragLabel:SetTextColor(TEAL.r, TEAL.g, TEAL.b)
    dragLabel:SetText((L and L["mover_class_reminder"]) or "Class Reminder")
    dragOverlay:Hide()
end

local function SetLockedInternal(locked)
    -- Placement mode drags a frame that parents protected buttons, so it is
    -- an out-of-combat operation only.
    if InCombatLockdown() then return end
    isLocked = locked and true or false
    crPreview = false

    if isLocked then
        if dragOverlay then dragOverlay:Hide() end
        UpdateDisplay()
        return
    end

    CreateDragOverlay()
    HideSecureRow()
    HideCombatRow()
    anchor:SetScale((GetDB() and GetDB().scale) or 1.0)
    ApplyPosition()
    ShowEntries(BuildPreviewList(), false)
    anchor:SetAlpha(1)
    dragOverlay:Show()
end

-- ── Throttled Update ─────────────────────────────────────────
-- [PERF] Event-driven with a short coalescing window. The former 1 s ticker
-- ran forever while the module was enabled, re-scanning even when nothing had
-- changed; UNIT_AURA already fires on gain, loss and expiry, and the stance
-- bar has its own events, so no polling is needed.

local _updatePending = false

local function _flushUpdate()
    _updatePending = false
    UpdateDisplay()
end

RequestUpdate = function()
    if _updatePending then return end
    _updatePending = true
    C_Timer.After(0.2, _flushUpdate)
end

-- ── Public API ───────────────────────────────────────────────

-- Liste des classes couvertes et de leurs buffs/formes suivis (pour le panneau).
function CR.GetCoverage()
    local out = {}
    for classToken, entries in pairs(CLASS_DATA) do
        local items = {}
        for _, entry in ipairs(entries) do
            items[#items + 1] = {
                key        = entry.nameKey,
                label      = EntryLabel(entry),
                classToken = classToken,
            }
        end
        local className = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]) or classToken
        out[#out + 1] = { class = classToken, className = className, items = items }
    end
    table.sort(out, function(a, b) return a.className < b.className end)
    return out
end

-- Flat coverage in one list, class by class, for a grid that wants a single
-- pass instead of a nested loop.
function CR.GetCoverageItems()
    local out = {}
    for _, group in ipairs(CR.GetCoverage()) do
        for _, item in ipairs(group.items) do out[#out + 1] = item end
    end
    return out
end

function CR.IsEntryEnabled(nameKey)
    local db = GetDB()
    return not (db and db.entries and db.entries[nameKey] == false)
end

function CR.SetEntryEnabled(nameKey, v)
    local db = GetDB()
    if not db then return end
    if not db.entries then db.entries = {} end
    -- Stored as an explicit false rather than removed, so the value survives a
    -- profile copy that only walks existing keys.
    db.entries[nameKey] = v and true or false
    UpdateDisplay()
end

-- Affiche une rangée d'exemple à l'emplacement configuré pendant quelques
-- secondes, pour visualiser l'apparence/position sans attendre un buff manquant.
-- Utilise le pool non sécurisé : l'aperçu ne doit rien lancer si on clique
-- dessus, et il reste ainsi utilisable en combat.
function CR.ShowPreview(seconds)
    if not isLocked then return end
    crPreview = true
    HideSecureRow()
    HideCombatRow()
    if not InCombatLockdown() then
        anchor:SetScale((GetDB() and GetDB().scale) or 1.0)
        ApplyPosition()
    end
    ShowEntries(BuildPreviewList(), false)
    anchor:SetAlpha(1)

    C_Timer.After(seconds or 4, function()
        crPreview = false
        HideCombatRow()
        UpdateDisplay()  -- revient à l'état réel (masque si rien ne manque)
    end)
end

-- Detached preview row for the options panel.
--
-- It reuses the live row's skin, layout and glow so what the panel shows is
-- what the screen will show, but it owns its own pool of plain frames: the
-- options panel must never host a SecureActionButton, or hovering a config
-- widget would arm a real cast.
--
-- row:Refresh() redraws from the current settings; callers wire OnIconClick
-- and OnLabelClick to navigate to the option that controls what was clicked.
function CR.CreatePreviewRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(1)
    row._pool = {}

    local function IconClicked(self)
        if row.OnIconClick and self._nameKey then row.OnIconClick(self._nameKey) end
    end
    local function LabelClicked(self)
        if row.OnLabelClick then row.OnLabelClick(self._nameKey) end
    end

    function row:Refresh()
        local db       = GetDB() or {}
        local size     = db.iconSize or 40
        local spacing  = db.iconSpacing or 8
        local showText = db.showText ~= false
        local textSize = db.textSize or 12
        local opacity  = db.opacity or 1.0
        local scale    = db.scale or 1.0
        local tc       = db.textColor or { r = 1, g = 1, b = 1 }

        local list = BuildPreviewList()
        local n    = #list

        for i = 1, n do
            local entry = list[i]
            local f = self._pool[i]
            if not f then
                f = CreateFrame("Button", nil, self, "BackdropTemplate")
                DressIcon(f)
                f:SetScript("OnClick", IconClicked)
                -- A hit area over the label only, so clicking the wording jumps
                -- to the label options while the icon jumps to that reminder.
                local hit = CreateFrame("Button", nil, f)
                hit:SetPoint("TOPLEFT", f._label, "TOPLEFT", 0, 2)
                hit:SetPoint("BOTTOMRIGHT", f._label, "BOTTOMRIGHT", 0, -2)
                hit:SetFrameLevel(f:GetFrameLevel() + 4)
                hit:SetScript("OnClick", LabelClicked)
                f._labelHit = hit
                self._pool[i] = f
            end
            f._nameKey = entry.nameKey
            f._labelHit._nameKey = entry.nameKey
            f._icon:SetTexture(EntryTexture(entry))
            f:SetSize(size, size)
            f:SetScale(scale)
            f:SetAlpha(opacity)
            if showText then
                f._label:SetFont(FONT_LABEL, textSize, "OUTLINE")
                f._label:SetTextColor(tc.r, tc.g, tc.b, 1)
                f._label:SetText(EntryLabel(entry))
                f._label:Show()
                f._labelHit:Show()
            else
                f._label:SetText("")
                f._label:Hide()
                f._labelHit:Hide()
            end
            f:Show()
            StartGlow(f)
        end

        for i = n + 1, #self._pool do
            local f = self._pool[i]
            StopGlow(f)
            f:Hide()
        end

        local textH  = showText and (textSize + 4) or 0
        local totalW = (n > 0) and (n * size + (n - 1) * spacing) or 0
        local startX = -(totalW / 2) + (size / 2)
        for i = 1, n do
            local f = self._pool[i]
            f:ClearAllPoints()
            f:SetPoint("CENTER", self, "CENTER",
                (startX + (i - 1) * (size + spacing)) * scale, (textH / 2) * scale)
        end
        -- Reserve the scaled footprint so the surrounding panel rows never
        -- overlap the preview when the icon size or scale is turned up.
        self:SetHeight(math.max(1, (size + textH) * scale + 8))
    end

    function row:GetIcon(nameKey)
        for i = 1, #self._pool do
            local f = self._pool[i]
            if f._nameKey == nameKey then return f end
        end
    end

    row:Refresh()
    return row
end

function CR.SetLocked(locked)
    SetLockedInternal(locked)
end

function CR.ToggleLock()
    SetLockedInternal(not isLocked)
    return isLocked
end

function CR.IsLocked()
    return isLocked
end

function CR.ResetPosition()
    local db = GetDB()
    if db then db.position = nil end
    ApplyPosition()
end

function CR.SetEnabled(v)
    local db = GetDB()
    if db then db.enabled = v end
    if CR.UpdateAuraRegistration then CR.UpdateAuraRegistration() end
    if v then
        UpdateDisplay()
    else
        HideEverything()
    end
end

function CR.ApplySettings()
    -- Toggling Show Others Missing or the module itself changes whether broad
    -- UNIT_AURA is worth paying for.
    if CR.UpdateAuraRegistration then CR.UpdateAuraRegistration() end
    UpdateDisplay()
end

function CR.Initialize()
    local db = GetDB()
    if not db then return end

    -- Cache class & spec
    local _, englishClass = UnitClass("player")
    playerClass = englishClass
    currentSpecID = CurrentSpecID()

    anchor:SetScale(db.scale or 1.0)
    ApplyPosition()
    if CR.UpdateAuraRegistration then CR.UpdateAuraRegistration() end
    UpdateDisplay()

    if TomoMod_Movers and TomoMod_Movers.RegisterEntry and not CR._moverRegistered then
        CR._moverRegistered = true
        TomoMod_Movers.RegisterEntry({
            label    = (L and L["mover_class_reminder"]) or "Class Reminder",
            unlock   = function() if CR.IsLocked() then SetLockedInternal(false) end end,
            lock     = function() if not CR.IsLocked() then SetLockedInternal(true) end end,
            isActive = function()
                return TomoModDB and TomoModDB.classReminder and TomoModDB.classReminder.enabled
            end,
        })
    end
end

-- ── Events ───────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame", "TomoMod_ClassReminderEvents")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
-- Plural: the set of available forms changed (talent swap), so an entry that
-- was "not learned" a moment ago may now be trackable.
eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_LEVEL_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
eventFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
eventFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
-- Weapon imbues and rites are temporary enchants, not auras: UNIT_AURA never
-- fires for them, so without these two the reminder only cleared on the next
-- unrelated refresh.
eventFrame:RegisterEvent("WEAPON_ENCHANT_CHANGED")
eventFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")

-- Broad UNIT_AURA fires for every member of a raid, dozens of times a second.
-- It is only worth paying for when the player's class actually has a group
-- buff AND Show Others Missing is on; otherwise the player-only registration
-- is all this module ever needs.
local _broadAura = false

local function NeedsGroupAura()
    local db = GetDB()
    if not (db and db.enabled and db.showOthersMissing) then return false end
    local entries = CLASS_DATA[playerClass]
    if not entries then return false end
    for i = 1, #entries do
        if entries[i].group then return true end
    end
    return false
end

local function UpdateAuraRegistration()
    local want = NeedsGroupAura() and IsInGroup() and true or false
    if want == _broadAura then return end
    _broadAura = want
    if want then
        eventFrame:RegisterEvent("UNIT_AURA")
    else
        eventFrame:UnregisterEvent("UNIT_AURA")
        eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    end
end
CR.UpdateAuraRegistration = UpdateAuraRegistration

-- Start player-only; UpdateAuraRegistration widens it if the settings ask.
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")

-- Group members' auras change constantly in combat-adjacent moments. Coalesce
-- them into one deferred pass instead of one refresh per event.
local _groupAuraPending = false

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        CR.Initialize()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Middle-click dismissals last until the next loading screen.
        wipe(dismissed)
    end

    local db = GetDB()
    if not db or not db.enabled then return end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        currentSpecID = CurrentSpecID()
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateAuraRegistration()
    elseif event == "UNIT_AURA" and arg1 ~= "player" then
        -- A group member's aura changed. Only the group-buff pass cares, and
        -- only then when it is actually switched on.
        if not _broadAura then return end
        if _groupAuraPending then return end
        _groupAuraPending = true
        C_Timer.After(0.4, function()
            _groupAuraPending = false
            RequestUpdate()
        end)
        return
    end

    RequestUpdate()
end)

-- ── Register Module ──────────────────────────────────────────

TomoMod_RegisterModule("classReminder", CR)
