-- =====================================================================
-- CooldownForge -- Render (containers, icon pool, cooldown widget, glow,
-- layout). AstralForge Cooldown -- Lot 3. Display-only; frames are our own
-- (parented to UIParent), so no taint and no InCombatLockdown guard needed.
-- Requires CDF_Core + CDF_Catalog + CDF_Watch.
--
-- Secret-safe (see docs sec.6): spells feed duration OBJECTS to the Cooldown
-- widget; items feed non-secret numbers. "Ready" state is detected via
-- Cooldown:IsShown() (detect-don't-test), never by reading a secret value.
-- =====================================================================

local CDF = TomoMod_CooldownForge
local U   = TomoMod_Utils
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

local FONT     = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local GLOW_KEY = "TomoCDF"
local QUESTION = 134400 -- fallback icon

local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max

-- ---------------------------------------------------------------------
-- Glow (LibCustomGlow). Cached active type per frame to avoid flicker.
-- ---------------------------------------------------------------------
local function stopGlow(f)
    if not LCG then return end
    LCG.PixelGlow_Stop(f, GLOW_KEY)
    LCG.AutoCastGlow_Stop(f, GLOW_KEY)
    LCG.ButtonGlow_Stop(f)
    f._cdfGlow = nil
end

local function startGlow(f, glow)
    if not LCG then return end
    local t = glow.type or "Pixel"
    local c = glow.color or { U.BRAND[1], U.BRAND[2], U.BRAND[3], 1 }
    if not c[4] then c = { c[1], c[2], c[3], 1 } end
    if f._cdfGlow == t then return end -- already active, same type
    stopGlow(f)
    if t == "Autocast" then
        LCG.AutoCastGlow_Start(f, c, 4, 0.125, 1, 0, 0, GLOW_KEY)
    elseif t == "Button" then
        LCG.ButtonGlow_Start(f, c, 0.125)
    else -- "Pixel" (default)
        LCG.PixelGlow_Start(f, c, 8, 0.25, nil, 2, 0, 0, false, GLOW_KEY)
    end
    f._cdfGlow = t
end
CDF._stopGlow = stopGlow

-- ---------------------------------------------------------------------
-- Layout math (pure; exposed for tests)
-- ---------------------------------------------------------------------
-- Returns anchor corner + (x, y) offset for icon `i` (1-based) in `bar`.
function CDF.__layoutOffset(bar, i)
    local step = bar.iconSize + bar.spacing
    local p = i - 1
    local pos, line
    if bar.wrap and bar.wrap > 0 then
        line = floor(p / bar.wrap); pos = p % bar.wrap
    else
        line = 0; pos = p
    end
    if bar.orientation == "vertical" then
        if bar.growth == "UP" then
            return "BOTTOMLEFT", line * step, pos * step
        else -- DOWN
            return "TOPLEFT", line * step, -pos * step
        end
    else
        if bar.growth == "LEFT" then
            return "TOPRIGHT", -pos * step, -line * step
        else -- RIGHT
            return "TOPLEFT", pos * step, -line * step
        end
    end
end

-- Returns container (width, height) for `n` icons.
function CDF.__barSize(bar, n)
    local perLine, lines
    if bar.wrap and bar.wrap > 0 then
        perLine = min(bar.wrap, n); lines = ceil(n / bar.wrap)
    else
        perLine = n; lines = 1
    end
    if perLine < 1 then perLine = 1 end
    if lines < 1 then lines = 1 end
    local along = perLine * bar.iconSize + (perLine - 1) * bar.spacing
    local cross = lines * bar.iconSize + (lines - 1) * bar.spacing
    if bar.orientation == "vertical" then return cross, along else return along, cross end
end

-- ---------------------------------------------------------------------
-- Icon pool
-- ---------------------------------------------------------------------
local function makeIcon(container)
    local icon = CreateFrame("Frame", nil, container)
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints(icon)
    icon.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cd:SetAllPoints(icon.tex)
    icon.cd:SetDrawBling(false)

    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)

    icon.name = icon:CreateFontString(nil, "OVERLAY")
    icon.name:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    icon.name:SetJustifyH("CENTER")
    return icon
end

local function styleIcon(icon, bar)
    icon:SetSize(bar.iconSize, bar.iconSize)
    local sw = bar.swipe or {}
    local col = sw.color or { 0, 0, 0, 0.6 }
    icon.cd:SetSwipeColor(col[1] or 0, col[2] or 0, col[3] or 0, col[4] or 0.6)
    icon.cd:SetDrawSwipe(sw.draw ~= false)
    if icon.cd.SetReverse then icon.cd:SetReverse(sw.reverse == true) end
    local text = bar.text or {}
    icon.cd:SetHideCountdownNumbers(text.mode ~= "timer")
    local fs = max(9, text.size or 13)
    icon.count:SetFont(FONT, fs, "OUTLINE")
    icon.name:SetFont(FONT, fs, "OUTLINE")
    icon.name:SetWidth(bar.iconSize + 18)
end

-- Feed cooldown, decide ready state, then style glow/stacks/name.
local function applyEntry(icon, resolved, state, bar)
    icon.tex:SetTexture(resolved.icon or QUESTION)
    icon._resolved = resolved

    local ready
    if state and state.isSpell then
        local durObj = (state.maxCharges and state.maxCharges > 1 and state.chargeDurObj) or state.durObj
        if durObj then icon.cd:SetCooldownFromDurationObject(durObj) end
        ready = not icon.cd:IsShown()
    elseif state then
        icon.cd:SetCooldown(state.start or 0, state.duration or 0)
        ready = (not state.duration) or state.duration == 0
    else
        ready = true
    end

    -- Glow (when ready / off cooldown)
    if bar.glow and bar.glow.enabled and ready then
        startGlow(icon, bar.glow)
    else
        stopGlow(icon)
    end

    -- Stacks
    local text = bar.text or {}
    local shown = false
    if text.stacks and state then
        if state.isSpell and state.maxCharges and state.maxCharges > 1 and state.chargeInfo then
            icon.count:SetText(state.chargeInfo.currentCharges) -- SetText is a safe sink
            shown = true
        elseif (not state.isSpell) and resolved.itemID and C_Item and C_Item.GetItemCount then
            local c = C_Item.GetItemCount(resolved.itemID) or 0
            if c > 1 then icon.count:SetText(c); shown = true end
        end
    end
    if shown then icon.count:Show() else icon.count:SetText(""); icon.count:Hide() end

    -- Name
    if text.mode == "name" then
        icon.name:SetText(resolved.name or "")
        icon.name:Show()
    else
        icon.name:Hide()
    end
end

-- ---------------------------------------------------------------------
-- Bar container + layout
-- ---------------------------------------------------------------------
local function getBarFrame(bar)
    CDF._barFrames = CDF._barFrames or {}
    local f = CDF._barFrames[bar.id]
    if not f then
        f = CreateFrame("Frame", nil, UIParent)
        f:SetFrameStrata("MEDIUM")
        CDF._barFrames[bar.id] = f
    end
    return f
end
CDF.GetBarFrame = getBarFrame

local function positionContainer(f, bar)
    local pos = bar.position or {}
    local point = pos.point or "CENTER"
    f:ClearAllPoints()
    f:SetPoint(point, UIParent, pos.relPoint or point, pos.x or 0, pos.y or 0)
end

local function layoutBar(container, bar)
    local arr = bar.entries or {}
    local visible = {}
    for i = 1, #arr do
        local e = arr[i]
        if CDF.IsEntryVisible(e) then
            local r = CDF.ResolveEntry(e)
            if r and not r.empty then
                visible[#visible + 1] = r
            end
        end
    end

    container._icons = container._icons or {}
    container._bar = bar
    local n = #visible
    if n == 0 then container._count = 0; container:Hide(); return end

    container:Show()
    local w, h = CDF.__barSize(bar, n)
    container:SetSize(max(1, w), max(1, h))

    for i = 1, n do
        local icon = container._icons[i]
        if not icon then icon = makeIcon(container); container._icons[i] = icon end
        styleIcon(icon, bar)
        local corner, ox, oy = CDF.__layoutOffset(bar, i)
        icon:ClearAllPoints()
        icon:SetPoint(corner, container, corner, ox, oy)
        icon:Show()
        applyEntry(icon, visible[i], CDF.GetCooldownState(visible[i]), bar)
    end
    for i = n + 1, #container._icons do
        container._icons[i]:Hide()
        stopGlow(container._icons[i])
    end
    container._count = n
end

-- Light refresh: re-read cooldowns on already-shown icons (no re-layout).
local function updateBar(container, bar)
    local icons = container._icons
    if not icons then return end
    for i = 1, (container._count or 0) do
        local icon = icons[i]
        if icon and icon._resolved then
            applyEntry(icon, icon._resolved, CDF.GetCooldownState(icon._resolved), bar)
        end
    end
end

-- ---------------------------------------------------------------------
-- Public refresh entry points
-- ---------------------------------------------------------------------
-- Full rebuild for the current class (visibility + layout).
function CDF.RefreshAll()
    if not CDF.DB() then return end
    local present = {}
    local arr = CDF.GetClassBars()
    if arr then
        for i = 1, #arr do
            local bar = arr[i]
            present[bar.id] = true
            local f = getBarFrame(bar)
            positionContainer(f, bar)
            if bar.enabled == false then
                f:Hide()
            else
                layoutBar(f, bar)
            end
        end
    end
    if CDF._barFrames then
        for id, f in pairs(CDF._barFrames) do
            if not present[id] then f:Hide() end
        end
    end
end

-- Light update for shown bars (cooldown ticks).
function CDF.UpdateAll()
    if not CDF._barFrames then return end
    for _, f in pairs(CDF._barFrames) do
        if f:IsShown() and f._bar then updateBar(f, f._bar) end
    end
end

-- ---------------------------------------------------------------------
-- Wire to the Lot 2 dispatcher + initial build
-- ---------------------------------------------------------------------
CDF.RegisterUpdate(function(reason)
    if reason == "layout" then CDF.RefreshAll() else CDF.UpdateAll() end
end)

local rf = CreateFrame("Frame")
rf:RegisterEvent("PLAYER_ENTERING_WORLD")
rf:RegisterEvent("PLAYER_LOGIN")
rf:SetScript("OnEvent", function()
    if CDF.DB() then CDF.RefreshAll() end
end)
CDF._renderFrame = rf
