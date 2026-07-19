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
    local icon = CreateFrame("Frame", nil, container, "BackdropTemplate")

    -- [S0] optional soft shadow behind the icon (style "verre")
    icon.shadowTex = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
    icon.shadowTex:SetTexture(CDF.SKIN_TEX and CDF.SKIN_TEX.shadow_soft)
    icon.shadowTex:SetPoint("TOPLEFT", icon, "TOPLEFT", -7, 7)
    icon.shadowTex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 7, -7)
    icon.shadowTex:Hide()

    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints(icon)
    icon.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- [S0] corner mask (attached on demand by styleIcon)
    icon.mask = icon:CreateMaskTexture()
    icon.mask:SetAllPoints(icon.tex)

    icon.cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cd:SetAllPoints(icon.tex)
    icon.cd:SetDrawBling(false)

    -- [S0] duration badge strip (style "tomo"); above the cooldown so the
    -- relocated countdown FontString stays visible over its backdrop.
    icon.badge = CreateFrame("Frame", nil, icon, "BackdropTemplate")
    icon.badge:SetHeight(13)
    icon.badge:SetPoint("BOTTOMLEFT", 0, 0)
    icon.badge:SetPoint("BOTTOMRIGHT", 0, 0)
    icon.badge:SetFrameLevel(icon.cd:GetFrameLevel() + 1)
    icon.badge:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    icon.badge:SetBackdropColor(0.03, 0.04, 0.06, 0.82)
    icon.badge:Hide()

    icon.count = icon:CreateFontString(nil, "OVERLAY")
    icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)

    icon.name = icon:CreateFontString(nil, "OVERLAY")
    icon.name:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    icon.name:SetJustifyH("CENTER")
    return icon
end

-- [S0] Locate (once) the Cooldown widget's native countdown FontString so
-- the skin can restyle and reposition it without any per-icon OnUpdate.
local function cdTimerFS(icon)
    if icon._cdfs ~= nil then
        return icon._cdfs or nil
    end
    local fs
    for _, r in ipairs({ icon.cd:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "FontString" then
            fs = r
            break
        end
    end
    icon._cdfs = fs or false
    return fs
end

local function styleIcon(icon, bar)
    icon:SetSize(bar.iconSize, bar.iconSize)
    local st = CDF.ResolveStyle and CDF.ResolveStyle(bar) or {}
    local sw = bar.swipe or {}

    -- [S7] per-bar opacity
    local op = tonumber(st.opacity)
    icon:SetAlpha((op ~= nil) and op or 1)

    -- [S0] border (backdrop on the icon frame; class color resolved live)
    local bd = st.border
    if bd and bd.mode then
        local px = CDF.Px and CDF.Px(bd.thickness or 1) or (bd.thickness or 1)
        local br, bg, bb, ba = CDF.ResolveTint(bd.mode, bd.color, 0, 0, 0)
        icon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = px })
        icon:SetBackdropBorderColor(br, bg, bb, ba or (bd.mode == "class" and 0.9 or 1))
    elseif icon.SetBackdrop then
        icon:SetBackdrop(nil)
    end

    -- [S0] corners: mask on the art + matching swipe texture so the swipe
    -- follows the rounded shape natively (fallback = sharp, no mask).
    local maskPath = (st.corners == "soft"  and CDF.SKIN_TEX.mask_soft)
                  or (st.corners == "round" and CDF.SKIN_TEX.mask_round)
                  or nil
    if maskPath then
        icon.mask:SetTexture(maskPath, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        if not icon._masked then
            icon.tex:AddMaskTexture(icon.mask)
            icon._masked = true
        end
        if icon.cd.SetSwipeTexture then icon.cd:SetSwipeTexture(maskPath) end
    else
        if icon._masked then
            icon.tex:RemoveMaskTexture(icon.mask)
            icon._masked = nil
        end
        if icon.cd.SetSwipeTexture then icon.cd:SetSwipeTexture("") end
    end

    -- [S0] swipe color: style first, legacy bar.swipe.color as fallback
    local smode = st.swipe and st.swipe.mode
    if smode == "class" or smode == "bar" then
        local r, g, b = CDF.ResolveTint(smode, st.swipe.color)
        icon.cd:SetSwipeColor(r * 0.55, g * 0.55, b * 0.55, 0.85)
    elseif smode == "verre" then
        icon.cd:SetSwipeColor(0.04, 0.05, 0.08, 0.62)
    elseif smode == "dark" then
        icon.cd:SetSwipeColor(0, 0, 0, 0.75)
    else
        local col = sw.color or { 0, 0, 0, 0.6 }
        icon.cd:SetSwipeColor(col[1] or 0, col[2] or 0, col[3] or 0, col[4] or 0.6)
    end
    icon.cd:SetDrawSwipe(sw.draw ~= false)
    if icon.cd.SetReverse then icon.cd:SetReverse(sw.reverse == true) end

    -- [S0] timer: native countdown FontString restyled / repositioned
    local text = bar.text or {}
    local tpos = (st.timer and st.timer.pos) or "center"
    local wantTimer = (text.mode == "timer") and tpos ~= "hidden"
    icon.cd:SetHideCountdownNumbers(not wantTimer)
    if wantTimer then
        local tfs = cdTimerFS(icon)
        if tfs then
            local tsize = max(8, (st.timer and st.timer.size) or 13)
            tfs:SetFont(FONT, tsize, "OUTLINE")
            tfs:ClearAllPoints()
            if tpos == "badge" and st.badge then
                tfs:SetParent(icon.badge)
                tfs:SetDrawLayer("OVERLAY")
                tfs:SetPoint("CENTER", icon.badge, "CENTER", 0, 0)
            else
                tfs:SetParent(icon.cd)
                tfs:SetPoint("CENTER", icon.cd, "CENTER", 0, 0)
            end
            -- [S7] timer color: explicit override, else class/accent tint
            local tc = st.timerColor
            if type(tc) == "table" and tc[1] then
                tfs:SetTextColor(tc[1], tc[2] or 1, tc[3] or 1)
            else
                local cr, cg, cb = CDF.ClassColor()
                tfs:SetTextColor(cr, cg, cb)
            end
        end
    end

    -- [S0] badge strip (border tinted like the icon border)
    if st.badge then
        local br, bg, bb = CDF.ResolveTint((bd and bd.mode) or "class", bd and bd.color)
        icon.badge:SetBackdropBorderColor(br, bg, bb, 0.35)
        icon.badge:Show()
    else
        icon.badge:Hide()
    end

    -- [S0] shadow
    icon.shadowTex:SetShown(st.shadow == true)

    -- [S0] stacks anchor + fonts
    local fs = max(9, text.size or 13)
    icon.count:SetFont(FONT, fs, "OUTLINE")
    icon.count:ClearAllPoints()
    if st.stackPos == "TOPRIGHT" then
        icon.count:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -1, -1)
    else
        icon.count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
    end
    icon.name:SetFont(FONT, fs, "OUTLINE")
    icon.name:SetWidth(bar.iconSize + 18)

    icon._cdfStyle = st
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

    -- [S2] per-entry override (nil field = inherit from bar/style)
    local ov = resolved and resolved.override or nil

    -- [S0] desaturate while on cooldown, short color-return flash on ready
    local st = icon._cdfStyle or (CDF.ResolveStyle and CDF.ResolveStyle(bar)) or {}
    local wantDesat = st.desatOnCooldown
    if ov and ov.desat ~= nil then wantDesat = ov.desat end
    if wantDesat then
        icon.tex:SetDesaturated(not ready)
        if ready and icon._cdfWasReady == false then
            if not icon._cdfReadyAnim then
                local ag = icon.tex:CreateAnimationGroup()
                local a  = ag:CreateAnimation("Alpha")
                a:SetFromAlpha(0.35)
                a:SetToAlpha(1)
                a:SetDuration(0.22)
                icon._cdfReadyAnim = ag
            end
            icon._cdfReadyAnim:Stop()
            icon._cdfReadyAnim:Play()
        end
        icon._cdfWasReady = ready
    else
        icon.tex:SetDesaturated(false)
        icon._cdfWasReady = nil
    end

    -- Glow (when ready / off cooldown) -- [S2] per-entry enable + color,
    -- via a per-icon cached cfg table to avoid per-update allocations.
    local glowOn = bar.glow and bar.glow.enabled
    if ov and ov.glow ~= nil then glowOn = ov.glow end
    local gcfg = bar.glow
    if ov and ov.glowColor then
        local t = icon._cdfGlowCfg or {}
        icon._cdfGlowCfg = t
        t.type  = (bar.glow and bar.glow.type) or "Pixel"
        t.color = ov.glowColor
        gcfg = t
    end
    if glowOn and ready and gcfg then
        startGlow(icon, gcfg)
    else
        stopGlow(icon)
    end

    -- [S2] per-entry swipe / timer (bar defaults were set by styleIcon)
    if ov and ov.swipe ~= nil then icon.cd:SetDrawSwipe(ov.swipe) end
    if ov and ov.timer == false then icon.cd:SetHideCountdownNumbers(true) end

    -- Stacks -- [S2] per-entry tri-state
    local text = bar.text or {}
    local stacksOn = text.stacks
    if ov and ov.stacks ~= nil then stacksOn = ov.stacks end
    local shown = false
    if stacksOn and state then
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

-- [preview] Expose the exact icon builder + styler used by real bars, so the
-- studio preview renders identically (no divergent reimplementation). The
-- preview passes its own container; makeIcon/styleIcon don't care where the
-- icon lives. Extensible to fake-active states later via icon.cd:SetCooldown
-- with plain numbers (safe on our own Cooldown frame, not a secret value).
function CDF.MakePreviewIcon(container)
    return makeIcon(container)
end
-- opts (optional): { cooldown = seconds, elapsed = seconds }
--   Starts a fake cooldown on OUR OWN Cooldown frame with plain numbers
--   (never a secret value -- same technique EllesmereUI uses for its
--   fake-active preview). Desaturation follows desatOnCooldown.
function CDF.StylePreviewIcon(icon, bar, texture, opts)
    icon.tex:SetTexture(texture or 134400)
    styleIcon(icon, bar)
    icon:Show()
    icon.tex:Show()

    local st = (CDF.ResolveStyle and CDF.ResolveStyle(bar)) or {}
    opts = opts or {}
    local cd = tonumber(opts.cooldown) or 0
    if cd > 0 then
        icon.cd:SetCooldown(GetTime() - (tonumber(opts.elapsed) or 0), cd)
        if st.desatOnCooldown then icon.tex:SetDesaturated(true) end
    else
        icon.cd:SetCooldown(0, 0)
        icon.tex:SetDesaturated(false)
    end
end

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
                r.override = e.override   -- [S2] per-entry FX travels with it
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
        -- [S2] emphasis: scale the icon around its CELL center so the grid
        -- stays aligned. SetPoint offsets live in the scaled frame's local
        -- space, hence the division by the scale.
        local ov = visible[i].override
        local s = (ov and tonumber(ov.emphasis)) or 1
        if s < 1 then s = 1 elseif s > 1.3 then s = 1.3 end
        icon:SetScale(s)
        if s > 1.001 then
            local half = bar.iconSize / 2
            local cx = ox + ((corner == "TOPLEFT" or corner == "BOTTOMLEFT") and half or -half)
            local cy = oy + ((corner == "TOPLEFT" or corner == "TOPRIGHT") and -half or half)
            icon:SetPoint("CENTER", container, corner, cx / s, cy / s)
        else
            icon:SetPoint(corner, container, corner, ox, oy)
        end
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
            if not CDF.IsBarVisible(bar) then
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
