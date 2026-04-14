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
AT.activeAuras = {}    -- { [spellID] = { icon, name, expirationTime, stacks, texture } }
AT.anchor = nil
AT.isLocked = true
AT.ticker = nil

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

    local found = {}
    local now = GetTime()

    -- Scan all player buffs via C_UnitAuras
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not ok or not aura then break end
        if aura.spellId and not (issecretvalue and issecretvalue(aura.spellId)) then
            local spellID = aura.spellId
            if IsTracked(spellID) then
                found[spellID] = {
                    name = aura.name,
                    icon = aura.icon,
                    stacks = aura.applications or 0,
                    duration = aura.duration or 0,
                    expirationTime = aura.expirationTime or 0,
                }
            end
        end
    end

    -- Detect new procs (for glow)
    local newProcs = {}
    for spellID, data in pairs(found) do
        if not AT.activeAuras[spellID] then
            newProcs[spellID] = true
        end
    end

    -- Remove expired
    for spellID, iconFrame in pairs(AT.activeAuras) do
        if not found[spellID] then
            if iconFrame.frame then
                ReleaseIcon(iconFrame.frame)
            end
            AT.activeAuras[spellID] = nil
        end
    end

    -- Update / create icons
    for spellID, data in pairs(found) do
        if not AT.activeAuras[spellID] then
            AT.activeAuras[spellID] = { data = data }
        else
            AT.activeAuras[spellID].data = data
        end
    end

    AT.LayoutIcons(newProcs)
end

-- =====================================
-- LAYOUT ICONS
-- =====================================

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

    -- Sort by expiration (soonest first, 0 = permanent last)
    local sorted = {}
    for spellID, entry in pairs(AT.activeAuras) do
        table.insert(sorted, { spellID = spellID, entry = entry })
    end
    table.sort(sorted, function(a, b)
        local ea = a.entry.data.expirationTime
        local eb = b.entry.data.expirationTime
        if ea == 0 and eb == 0 then return a.spellID < b.spellID end
        if ea == 0 then return false end
        if eb == 0 then return true end
        return ea < eb
    end)

    -- Trim to max
    while #sorted > maxIcons do
        local removed = table.remove(sorted)
        if AT.activeAuras[removed.spellID] and AT.activeAuras[removed.spellID].frame then
            ReleaseIcon(AT.activeAuras[removed.spellID].frame)
            AT.activeAuras[removed.spellID].frame = nil
        end
    end

    -- Position each icon
    for i, item in ipairs(sorted) do
        local spellID = item.spellID
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

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            AT.ScanAuras()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        AT.ScanAuras()
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        AT.ScanAuras()
    end
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
                local point, _, relativePoint, x, y = self:GetPoint()
                db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
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
    eventFrame:RegisterEvent("UNIT_AURA")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:Show()

    if AT.ticker then AT.ticker:Cancel() end
    AT.ticker = C_Timer.NewTicker(0.1, UpdateTimers)

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
