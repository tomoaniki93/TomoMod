-- =====================================
-- AuraTracker/AuraTracker.lua — WeakAura-lite overlay
-- Tracks trinket procs, enchant procs, self-buffs, defensives
-- =====================================

TomoMod_AuraTracker = TomoMod_AuraTracker or {}
local AT = TomoMod_AuraTracker

local pcall, pairs, ipairs, wipe = pcall, pairs, ipairs, wipe
local floor, abs, format = math.floor, math.abs, string.format
local GetTime = GetTime
local UnitBuff = C_UnitAuras and C_UnitAuras.GetBuffDataByIndex
local issecretvalue = issecretvalue

local ADDON_FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local TEAL = { 0.047, 0.824, 0.624 }
local DARK_BG = { 0.04, 0.04, 0.06, 0.85 }

-- State
AT.icons = {}          -- pooled icon frames
AT.activeAuras = {}    -- { [spellID] = { data = {...}, frame = <icon> } }
AT.anchor = nil
AT.isLocked = true
AT.ticker = nil

-- [PERF] Module-scope scratch tables. ScanAuras runs on every player UNIT_AURA
-- -- several times per second in combat -- and LayoutIcons runs with it. Both
-- used to allocate their working tables per call, plus one table per aura, which
-- made this module the overlay's main GC source. They are wiped and refilled.
local scanFound    = {}   -- [spellID] = true, auras seen in the current scan
local scanNewProcs = {}   -- [spellID] = true, auras that appeared this scan
local sortBuf      = {}   -- [1..n] = spellID, sort working array
local sortExpiry   = {}   -- [spellID] = expirationTime, read by the comparator

-- =====================================
-- SECRET-VALUE HELPERS (Midnight)
-- =====================================

-- Midnight can hand back "secret" values for aura fields. Branching on one
-- raises, so every field read goes through here once, at the single boundary
-- where the game hands it over.
local function IsSecret(v)
    return (type(issecretvalue) == "function" and issecretvalue(v))
        or (type(issecurevalue) == "function" and issecurevalue(v))
        or false
end

-- ORDER MATTERS: issecretvalue() is tested BEFORE any comparison touches the
-- value. Comparing a secret raises outright, so a test like `v > 0` placed
-- first crashes on exactly the values these guards were written to catch.
-- Never move a comparison above the IsSecret line.
local function SafeNum(v)
    if IsSecret(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

local function SafeStr(v)
    if IsSecret(v) then return nil end
    if type(v) ~= "string" then return nil end
    return v
end

-- =====================================
-- HELPERS
-- =====================================

local function GetDB()
    return TomoModDB and TomoModDB.auraTracker
end

local function IsTracked(spellID)
    local db = GetDB()
    if not db then return false end

    -- Blacklist check
    if db.blacklist and db.blacklist[spellID] then return false end

    -- Custom user-added spells always tracked
    if db.customSpells and db.customSpells[spellID] then return true end

    -- Check SpellDB categories
    local SDB = TomoMod_AuraTrackerDB
    if not SDB or not SDB.spellIndex then return false end

    local cat = SDB.spellIndex[spellID]
    if not cat then return false end

    return db.categories and db.categories[cat]
end

local function FormatTime(sec)
    if sec >= 60 then
        return format("%dm", floor(sec / 60))
    elseif sec >= 10 then
        return format("%d", floor(sec))
    else
        return format("%.1f", sec)
    end
end

-- =====================================
-- ICON POOL
-- =====================================

local iconPool = {}

local function AcquireIcon(parent, size)
    local f = table.remove(iconPool)
    if not f then
        f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetBackdrop({ bgFile = "Interface\\BUTTONS\\WHITE8X8", edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1 })
        f:SetBackdropColor(0, 0, 0, 0.6)
        f:SetBackdropBorderColor(0, 0, 0, 0.9)

        local icon = f:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        f.icon = icon

        -- Cooldown sweep
        local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
        cd:SetAllPoints(f.icon)
        cd:SetDrawEdge(false)
        cd:SetHideCountdownNumbers(true)
        cd:SetSwipeColor(0, 0, 0, 0.6)
        f.cooldown = cd

        -- Timer text
        local timer = f:CreateFontString(nil, "OVERLAY")
        timer:SetFont(ADDON_FONT, 11, "OUTLINE")
        timer:SetPoint("BOTTOM", f, "BOTTOM", 0, 1)
        timer:SetTextColor(1, 1, 1)
        f.timer = timer

        -- Stack count
        local stacks = f:CreateFontString(nil, "OVERLAY")
        stacks:SetFont(ADDON_FONT, 10, "OUTLINE")
        stacks:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        stacks:SetTextColor(1, 1, 1)
        f.stacks = stacks

        -- Glow animation (simple alpha pulse)
        local glow = f:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("TOPLEFT", -2, 2)
        glow:SetPoint("BOTTOMRIGHT", 2, -2)
        glow:SetColorTexture(TEAL[1], TEAL[2], TEAL[3], 0.5)
        glow:SetBlendMode("ADD")
        glow:Hide()
        f.glow = glow

        local ag = glow:CreateAnimationGroup()
        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(0.6)
        fadeIn:SetDuration(0.15)
        fadeIn:SetOrder(1)
        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(0.6)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.45)
        fadeOut:SetOrder(2)
        ag:SetScript("OnFinished", function() glow:Hide() end)
        f.glowAnim = ag
    end

    f:SetParent(parent)
    f:SetSize(size, size)
    f:Show()
    return f
end

local function ReleaseIcon(f)
    f:Hide()
    f:ClearAllPoints()
    f.cooldown:Clear()
    f.timer:SetText("")
    f.stacks:SetText("")
    f.glow:Hide()
    f._spellID = nil
    table.insert(iconPool, f)
end

-- =====================================
-- ANCHOR FRAME
-- =====================================

local function CreateAnchor()
    if AT.anchor then return end
    local db = GetDB()
    if not db then return end

    local anchor = CreateFrame("Frame", "TomoMod_AuraTrackerAnchor", UIParent)
    anchor:SetSize(db.iconSize or 36, db.iconSize or 36)
    anchor:SetClampedToScreen(true)

    local pos = db.position
    if pos then
        anchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    end

    -- Mover overlay (hidden by default, shown in layout mode)
    local mover = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    mover:SetAllPoints()
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    mover:SetBackdropColor(TEAL[1], TEAL[2], TEAL[3], 0.25)
    mover:SetBackdropBorderColor(TEAL[1], TEAL[2], TEAL[3], 0.8)
    mover:SetFrameLevel(500)
    local label = mover:CreateFontString(nil, "OVERLAY")
    label:SetFont(ADDON_FONT, 10, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText("Aura Tracker")
    label:SetTextColor(TEAL[1], TEAL[2], TEAL[3], 1)
    mover:Hide()
    anchor.moverOverlay = mover
    anchor.moverLabel = label

    AT.anchor = anchor
end

-- =====================================
-- SCAN AURAS
-- =====================================

function AT.ScanAuras()
    local db = GetDB()
    if not db or not db.enabled then return end

    wipe(scanFound)
    wipe(scanNewProcs)

    -- Scan all player buffs via C_UnitAuras
    for i = 1, 40 do
        local ok, aura = pcall(UnitBuff, "player", i)
        if not ok or not aura then break end
        local spellID = SafeNum(aura.spellId)
        if spellID and IsTracked(spellID) then
            scanFound[spellID] = true

            local entry = AT.activeAuras[spellID]
            if not entry then
                -- Absent from activeAuras means it just appeared: that is the
                -- proc the glow is for. Detected here rather than in a second
                -- pass, since activeAuras is only mutated below this point.
                scanNewProcs[spellID] = true
                entry = { data = {} }
                AT.activeAuras[spellID] = entry
            end

            -- [PERF] Fields are written into the entry's existing data table
            -- instead of building a fresh one per aura per scan.
            -- Every field is sanitised HERE, at the one boundary where the game
            -- hands it over, so no downstream consumer -- sort comparator,
            -- cooldown sweep, timer text, stack count -- ever compares or does
            -- arithmetic on a secret value.
            local data = entry.data
            data.name           = SafeStr(aura.name)
            data.stacks         = SafeNum(aura.applications) or 0
            data.duration       = SafeNum(aura.duration) or 0
            data.expirationTime = SafeNum(aura.expirationTime) or 0
            -- Opaque passthrough: the icon is only ever handed back to the game
            -- via SetTexture and never inspected, so a secret one is usable.
            data.icon           = aura.icon
        end
    end

    -- Remove expired
    for spellID, entry in pairs(AT.activeAuras) do
        if not scanFound[spellID] then
            if entry.frame then
                ReleaseIcon(entry.frame)
            end
            AT.activeAuras[spellID] = nil
        end
    end

    AT.LayoutIcons(scanNewProcs)
end

-- =====================================
-- LAYOUT ICONS
-- =====================================

-- Hoisted out of LayoutIcons: defining it inline meant one garbage function
-- object per aura refresh. Reads expiry from sortExpiry so it can sort bare
-- spellIDs. Every value it touches was sanitised by ScanAuras, so none of these
-- comparisons can raise on a secret.
local function SortByExpiry(a, b)
    local ea, eb = sortExpiry[a], sortExpiry[b]
    -- 0 means permanent -- those go last, whatever the other side is.
    if ea == 0 and eb == 0 then return a < b end
    if ea == 0 then return false end
    if eb == 0 then return true end
    -- spellID tiebreak: two auras applied in the same frame with the same
    -- duration share an expirationTime, and without this their relative order
    -- came from pairs() hash order and could flip between refreshes, visibly
    -- swapping the two icons.
    if ea == eb then return a < b end
    return ea < eb
end

function AT.LayoutIcons(newProcs)
    local db = GetDB()
    if not db or not AT.anchor then return end
    newProcs = newProcs or {}

    local size = db.iconSize or 36
    local spacing = db.spacing or 4
    local grow = db.growDirection or "RIGHT"
    local maxIcons = db.maxIcons or 8
    local showTimer = db.showTimer
    local showStacks = db.showStacks
    local showGlow = db.showGlow
    local fontSize = db.fontSize or 11
    local now = GetTime()

    -- Sort by expiration (soonest first, 0 = permanent last).
    -- [PERF] sortBuf holds bare spellIDs and the comparator reads expiry from
    -- sortExpiry, so the sort costs no wrapper table per icon and no comparator
    -- closure per call.
    wipe(sortBuf)
    wipe(sortExpiry)
    local count = 0
    for spellID, entry in pairs(AT.activeAuras) do
        count = count + 1
        sortBuf[count] = spellID
        sortExpiry[spellID] = entry.data.expirationTime or 0
    end
    table.sort(sortBuf, SortByExpiry)

    -- Trim to max. Iterating downwards releases the same icons the old
    -- table.remove loop did, without re-measuring the array each pass.
    for i = count, maxIcons + 1, -1 do
        local entry = AT.activeAuras[sortBuf[i]]
        if entry and entry.frame then
            ReleaseIcon(entry.frame)
            entry.frame = nil
        end
        sortBuf[i] = nil
        count = count - 1
    end

    -- Position each icon
    for i = 1, count do
        local spellID = sortBuf[i]
        local entry = AT.activeAuras[spellID]
        local data = entry.data

        -- Acquire frame if needed
        if not entry.frame then
            entry.frame = AcquireIcon(AT.anchor, size)
            entry.frame._spellID = spellID
        end

        local f = entry.frame
        f:SetSize(size, size)
        f.icon:SetTexture(data.icon)

        -- Cooldown sweep
        if data.duration and data.duration > 0 and data.expirationTime > 0 then
            f.cooldown:SetCooldown(data.expirationTime - data.duration, data.duration)
        else
            f.cooldown:Clear()
        end

        -- Timer text
        if showTimer and data.expirationTime and data.expirationTime > 0 then
            local remaining = data.expirationTime - now
            if remaining > 0 then
                f.timer:SetFont(ADDON_FONT, fontSize, "OUTLINE")
                f.timer:SetText(FormatTime(remaining))
                if remaining <= (db.timerThreshold or 5) then
                    f.timer:SetTextColor(1, 0.3, 0.3)
                else
                    f.timer:SetTextColor(1, 1, 1)
                end
            else
                f.timer:SetText("")
            end
        else
            f.timer:SetText("")
        end

        -- Stacks
        if showStacks and data.stacks and data.stacks > 1 then
            f.stacks:SetFont(ADDON_FONT, fontSize - 1, "OUTLINE")
            f.stacks:SetText(data.stacks)
        else
            f.stacks:SetText("")
        end

        -- Glow on new proc
        if showGlow and newProcs[spellID] then
            f.glow:Show()
            f.glowAnim:Stop()
            f.glowAnim:Play()
        end

        -- Position
        local offset = (i - 1) * (size + spacing)
        f:ClearAllPoints()
        if grow == "RIGHT" then
            f:SetPoint("LEFT", AT.anchor, "LEFT", offset, 0)
        elseif grow == "LEFT" then
            f:SetPoint("RIGHT", AT.anchor, "RIGHT", -offset, 0)
        elseif grow == "UP" then
            f:SetPoint("BOTTOM", AT.anchor, "BOTTOM", 0, offset)
        elseif grow == "DOWN" then
            f:SetPoint("TOP", AT.anchor, "TOP", 0, -offset)
        end
    end
end

-- =====================================
-- UPDATE TIMERS (0.1s ticker)
-- =====================================

local function UpdateTimers()
    local db = GetDB()
    if not db or not db.enabled then return end
    if not db.showTimer then return end

    local now = GetTime()
    local threshold = db.timerThreshold or 5

    for spellID, entry in pairs(AT.activeAuras) do
        if entry.frame and entry.data then
            local exp = entry.data.expirationTime
            if exp and exp > 0 then
                local remaining = exp - now
                if remaining > 0 then
                    entry.frame.timer:SetText(FormatTime(remaining))
                    if remaining <= threshold then
                        entry.frame.timer:SetTextColor(1, 0.3, 0.3)
                    else
                        entry.frame.timer:SetTextColor(1, 1, 1)
                    end
                else
                    entry.frame.timer:SetText("")
                end
            end
        end
    end
end

-- =====================================
-- EVENT HANDLER
-- =====================================

local eventFrame = CreateFrame("Frame")
eventFrame:Hide()

-- Every event this frame listens to leads to the same scan, and UNIT_AURA is
-- registered player-only (see AT.Start), so there is no unit token left to test
-- -- which also removes a comparison 12.x could hand a secret token to.
eventFrame:SetScript("OnEvent", function()
    AT.ScanAuras()
end)

-- =====================================
-- MOVER INTEGRATION
-- =====================================

function AT.ToggleLock()
    if not AT.anchor then return end
    AT.isLocked = not AT.isLocked
    local db = GetDB()

    if not AT.isLocked then
        -- Resize anchor to show full mover area
        local size = db and db.iconSize or 36
        local spacing = db and db.spacing or 4
        local maxIcons = db and db.maxIcons or 8
        local dir = db and db.growDirection or "RIGHT"
        if dir == "RIGHT" or dir == "LEFT" then
            AT.anchor:SetSize(maxIcons * (size + spacing), size)
        else
            AT.anchor:SetSize(size, maxIcons * (size + spacing))
        end

        AT.anchor:SetMovable(true)
        AT.anchor:EnableMouse(true)
        AT.anchor:RegisterForDrag("LeftButton")
        AT.anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
        AT.anchor:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            if db then
                -- [DRAG] StartMoving can corrupt child frame anchors; GetPoint's
                -- return value depends on the first anchor stored, which may have
                -- shifted. Use GetLeft/GetBottom (screen-absolute coords) and re-anchor
                -- relative to UIParent BOTTOMLEFT for a deterministic save.
                local left   = self:GetLeft()
                local bottom = self:GetBottom()
                if left and bottom then
                    local uiScale = UIParent:GetEffectiveScale()
                    local sScale  = self:GetEffectiveScale()
                    -- Convert self's coords (in its own scale) to UIParent's scale
                    local x = (left   * sScale) / uiScale
                    local y = (bottom * sScale) / uiScale
                    db.position = {
                        point         = "BOTTOMLEFT",
                        relativePoint = "BOTTOMLEFT",
                        x             = x,
                        y             = y,
                    }
                    -- Re-anchor cleanly so future :GetPoint() also returns this.
                    self:ClearAllPoints()
                    self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
                end
            end
        end)

        -- Show mover overlay
        AT.anchor.moverOverlay:Show()

        -- Show preview icons if none active
        if not next(AT.activeAuras) then
            AT.ShowPreview()
        end
    else
        -- Restore anchor to single icon size
        local size = db and db.iconSize or 36
        AT.anchor:SetSize(size, size)

        AT.anchor:SetMovable(false)
        AT.anchor:EnableMouse(false)
        AT.anchor:SetScript("OnDragStart", nil)
        AT.anchor:SetScript("OnDragStop", nil)
        AT.anchor.moverOverlay:Hide()
        AT.HidePreview()
    end
end

function AT.IsLocked()
    return AT.isLocked
end

-- Preview icons for mover mode
function AT.ShowPreview()
    if not AT.anchor then return end
    local db = GetDB()
    if not db then return end

    AT._previewIcons = AT._previewIcons or {}
    local size = db.iconSize or 36
    local spacing = db.spacing or 4
    local grow = db.growDirection or "RIGHT"

    for i = 1, 3 do
        local f = AT._previewIcons[i]
        if not f then
            f = AcquireIcon(AT.anchor, size)
            AT._previewIcons[i] = f
        end
        f:SetSize(size, size)
        f.icon:SetTexture(134400)  -- generic question mark
        f.timer:SetText("3." .. i)
        f.stacks:SetText(i > 1 and tostring(i) or "")
        f:ClearAllPoints()
        local offset = (i - 1) * (size + spacing)
        if grow == "RIGHT" then
            f:SetPoint("LEFT", AT.anchor, "LEFT", offset, 0)
        elseif grow == "LEFT" then
            f:SetPoint("RIGHT", AT.anchor, "RIGHT", -offset, 0)
        elseif grow == "UP" then
            f:SetPoint("BOTTOM", AT.anchor, "BOTTOM", 0, offset)
        elseif grow == "DOWN" then
            f:SetPoint("TOP", AT.anchor, "TOP", 0, -offset)
        end
        f:Show()
    end
end

function AT.HidePreview()
    if not AT._previewIcons then return end
    for _, f in ipairs(AT._previewIcons) do
        ReleaseIcon(f)
    end
    wipe(AT._previewIcons)
end

-- =====================================
-- PUBLIC API
-- =====================================

function AT.SetEnabled(v)
    local db = GetDB()
    if db then db.enabled = v end
    if v then
        AT.Start()
    else
        AT.Stop()
    end
end

function AT.Start()
    if not AT.anchor then CreateAnchor() end
    -- [PERF] RegisterUnitEvent, not RegisterEvent: the handler only ever acted
    -- on "player", but an unfiltered UNIT_AURA wakes this frame for every unit
    -- whose auras change -- 20+ raid members plus every visible nameplate --
    -- and each wake used to run a full 40-slot scan's worth of setup. Filtering
    -- at registration drops those dispatches at the client level, and keeps our
    -- insecure code out of Blizzard's dispatch chain for the other units.
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:Show()

    if AT.ticker then AT.ticker:Cancel() end
    AT.ticker = C_Timer.NewTicker(0.2, UpdateTimers)  -- [PERF] 0.2s (5fps) au lieu de 0.1s — suffisant pour "%.1f" affichage

    AT.ScanAuras()
end

function AT.Stop()
    eventFrame:UnregisterAllEvents()
    eventFrame:Hide()
    if AT.ticker then AT.ticker:Cancel(); AT.ticker = nil end

    -- Release all icons
    for spellID, entry in pairs(AT.activeAuras) do
        if entry.frame then
            ReleaseIcon(entry.frame)
        end
    end
    wipe(AT.activeAuras)

    if AT.anchor then AT.anchor:Hide() end
end

function AT.ApplySettings()
    local db = GetDB()
    if not db then return end

    if db.enabled then
        if not AT.anchor then CreateAnchor() end
        AT.anchor:Show()
        AT.ScanAuras()
    else
        AT.Stop()
    end
end

function AT.Initialize()
    local db = GetDB()
    if not db or not db.enabled then return end

    CreateAnchor()
    AT.Start()
end
