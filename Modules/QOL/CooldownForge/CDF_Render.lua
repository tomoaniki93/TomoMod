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
local cos, sin, rad = math.cos, math.sin, math.rad

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
-- `n` (total icon count) is only needed by the radial layout, which must
-- know how many icons share the arc before it can place any of them.
function CDF.__layoutOffset(bar, i, n)
    -- [S8] radial: icons sit on a circle centred on the container.
    if bar.layout == "radial" then
        local r = bar.radial or CDF.RADIAL_DEFAULT
        local count = max(1, tonumber(n) or 1)
        local arc = r.arc or 360
        local step
        if arc >= 360 then
            step = 360 / count           -- full circle: first and last never collide
        elseif count > 1 then
            step = arc / (count - 1)     -- open arc: both ends included
        else
            step = 0
        end
        local dir = (r.clockwise ~= false) and -1 or 1
        local ang = rad((r.startAngle or 90) + dir * step * (i - 1))
        local radius = r.radius or 90
        return "CENTER", radius * cos(ang), radius * sin(ang)
    end

    -- [S8] `spacing` runs along the growth axis, `spacingCross` between
    -- wrapped lines. nil keeps the historic single-value behaviour.
    local along = bar.spacing or 0
    local cross = bar.spacingCross or along
    -- [G2] the step along the growth axis uses that axis' extent, the step
    -- between wrapped lines the other one.
    local extA, extC = CDF.IconExtents(bar)
    local stepA = extA + along
    local stepC = extC + cross
    local p = i - 1
    local pos, line
    if bar.wrap and bar.wrap > 0 then
        line = floor(p / bar.wrap); pos = p % bar.wrap
    else
        line = 0; pos = p
    end
    if bar.orientation == "vertical" then
        if bar.growth == "UP" then
            return "BOTTOMLEFT", line * stepC, pos * stepA
        else -- DOWN
            return "TOPLEFT", line * stepC, -pos * stepA
        end
    else
        if bar.growth == "LEFT" then
            return "TOPRIGHT", -pos * stepA, -line * stepC
        else -- RIGHT
            return "TOPLEFT", pos * stepA, -line * stepC
        end
    end
end

-- Returns container (width, height) for `n` icons.
function CDF.__barSize(bar, n)
    -- [S8] radial: square box covering the circle plus one icon width.
    if bar.layout == "radial" then
        local r = bar.radial or CDF.RADIAL_DEFAULT
        -- [G2] the larger dimension decides the box, so a wide icon at the
        -- edge of the circle is never clipped.
        local iw, ih = CDF.IconDims(bar)
        local side = 2 * ((r.radius or 90) + math.max(iw, ih) / 2)
        return side, side
    end
    local along = bar.spacing or 0
    local cross = bar.spacingCross or along
    local perLine, lines
    if bar.wrap and bar.wrap > 0 then
        perLine = min(bar.wrap, n); lines = ceil(n / bar.wrap)
    else
        perLine = n; lines = 1
    end
    if perLine < 1 then perLine = 1 end
    if lines < 1 then lines = 1 end
    local extA, extC = CDF.IconExtents(bar)
    local sizeA = perLine * extA + (perLine - 1) * along
    local sizeC = lines * extC + (lines - 1) * cross
    if bar.orientation == "vertical" then return sizeC, sizeA else return sizeA, sizeC end
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
    icon:SetSize(CDF.IconDims(bar))
    local st = CDF.ResolveStyle and CDF.ResolveStyle(bar) or {}
    local sw = bar.swipe or {}

    -- [S7] per-bar opacity
    local op = tonumber(st.opacity)
    icon:SetAlpha((op ~= nil) and op or 1)

    -- [S0] border (backdrop on the icon frame; class color resolved live)
    local bd = st.border
    local edge = 0
    if bd and bd.mode then
        local px = CDF.Px and CDF.Px(bd.thickness or 1) or (bd.thickness or 1)
        local br, bg, bb, ba = CDF.ResolveTint(bd.mode, bd.color, 0, 0, 0)
        icon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = px })
        icon:SetBackdropBorderColor(br, bg, bb, ba or (bd.mode == "class" and 0.9 or 1))
        edge = px
    elseif icon.SetBackdrop then
        icon:SetBackdrop(nil)
    end

    -- The backdrop edge is drawn ON the frame border, while the icon art spans
    -- the WHOLE frame in the ARTWORK layer -- so the outline was painted over
    -- and looked identical at 1px and 4px. Inset the art by the edge width so
    -- the border actually has room to show. The mask and the cooldown swipe
    -- are anchored to the art, so they follow it.
    icon.tex:ClearAllPoints()
    if edge > 0 then
        icon.tex:SetPoint("TOPLEFT",     icon, "TOPLEFT",      edge, -edge)
        icon.tex:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -edge,  edge)
    else
        icon.tex:SetAllPoints(icon)
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
    icon.name:SetWidth((select(1, CDF.IconDims(bar))) + 18)

    icon._cdfStyle = st
end

-- Feed cooldown, decide ready state, then style glow/stacks/name.
local function applyEntry(icon, resolved, state, bar)
    icon.tex:SetTexture(resolved.icon or QUESTION)
    icon._resolved = resolved

    -- [G4] Tracked buff: the swipe shows the aura running out, not a
    -- cooldown filling up. Duration and stacks are only applied when they
    -- came back readable (see CDF.GetAuraState); under restricted content
    -- the icon still appears and disappears, just without a timer.
    local auraID = CDF.EntryAuraID and CDF.EntryAuraID(resolved and resolved._entry, resolved)
    if auraID then
        local a = CDF.GetAuraState and CDF.GetAuraState(auraID)
        if a and a.active and a.durationObject and icon.cd.SetCooldownFromDurationObject then
            -- Preferred: no arithmetic on values that may be secret.
            local okD = pcall(icon.cd.SetCooldownFromDurationObject, icon.cd, a.durationObject)
            if not okD then icon.cd:Clear() end
        elseif a and a.active and a.timed then
            icon.cd:SetCooldown(a.expirationTime - a.duration, a.duration)
        else
            icon.cd:Clear()
        end
        icon._auraState = a
    end

    local ready
    if auraID then
        -- An active buff is the "on" state: never desaturated, never treated
        -- as a spell on cooldown.
        ready = true
    elseif state and state.isSpell then
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

    -- [S9] castability tint. Orthogonal to the cooldown desaturation above:
    -- an off-cooldown spell the player cannot afford (Ironfur with no rage)
    -- now reads the same way it does on the action bars. Vertex color and
    -- desaturation multiply, so the two states compose instead of fighting.
    local um = st.unusableMode or "off"
    if ov and ov.unusableMode then um = ov.unusableMode end
    local usable = true
    if um ~= "off" then
        local noPower
        usable, noPower = CDF.GetUsable(resolved)
        if noPower and um == "resource" then
            icon.tex:SetVertexColor(0.35, 0.35, 0.85)
        elseif not usable then
            icon.tex:SetVertexColor(0.40, 0.40, 0.40)
        else
            icon.tex:SetVertexColor(1, 1, 1)
        end
    else
        icon.tex:SetVertexColor(1, 1, 1)
    end

    -- Glow -- [S2] per-entry enable + color, via a per-icon cached cfg
    -- table to avoid per-update allocations.
    local glowOn = bar.glow and bar.glow.enabled
    if ov and ov.glow ~= nil then glowOn = ov.glow end

    -- [S8] Trigger condition. "ready" is the historic hardcoded behaviour
    -- and stays the default; "aura" glows while a buff is up on the player;
    -- "always" glows whenever the icon is shown. [S9] "usable" is "ready"
    -- plus castability, so a rage-starved Ironfur stops glowing. The buff
    -- watched defaults
    -- to the entry's own spellID, which is wrong for trinkets and a few
    -- talents, hence the explicit auraSpellID escape hatch.
    local cond = (bar.glow and bar.glow.condition) or "ready"
    if ov and ov.glowCondition then cond = ov.glowCondition end
    local condMet
    if cond == "always" then
        condMet = true
    elseif cond == "aura" then
        local auraID = (ov and ov.auraSpellID)
                       or (bar.glow and bar.glow.auraSpellID)
                       or resolved.spellID
        condMet = CDF.IsAuraActive and CDF.IsAuraActive(auraID) or false
    elseif cond == "usable" then
        -- [S9] off cooldown AND actually castable. `usable` above was only
        -- computed when a tint mode is active, so ask again when it wasn't.
        local u = (um ~= "off") and usable or (CDF.GetUsable(resolved))
        condMet = (ready == true) and (u == true)
    else
        condMet = ready
    end

    local gcfg = bar.glow
    if ov and ov.glowColor then
        local t = icon._cdfGlowCfg or {}
        icon._cdfGlowCfg = t
        t.type  = (bar.glow and bar.glow.type) or "Pixel"
        t.color = ov.glowColor
        gcfg = t
    end
    if glowOn and condMet and gcfg then
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
    -- [G4] A tracked buff carries its own stack count. SetText is a safe sink
    -- for a secret value, but GetAuraState already dropped unreadable ones, so
    -- this is a plain number or nothing.
    if stacksOn and auraID then
        local a = icon._auraState
        local n = a and a.applications
        if n and n > 1 then icon.count:SetText(n); shown = true end
    elseif stacksOn and state then
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
    -- [S9] the preview has no real castability; keep the art untinted so a
    -- pooled icon reused from a live bar cannot leak a grey/blue state.
    icon.tex:SetVertexColor(1, 1, 1)
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

-- [S8] Does this entry survive the bar's hide filters?
-- [S9] Two independent filters now: hideOnCooldown drops what is running,
-- hideOnUnusable drops what the player cannot currently afford. Kept in one
-- place so readySignature and layoutBar can never drift apart.
-- [DIAG] Transition log. A single /tm forge is a snapshot, and a proc that is
-- consumed and reapplied several times a second is almost impossible to catch
-- that way. This records every active/inactive flip the engine actually SEES,
-- with the combat state at that moment, so "the engine never saw it go active
-- in combat" and "it saw it but did not draw it" stop looking alike.
CDF.__auraLog = CDF.__auraLog or {}
local AURA_LOG_MAX = 40
local auraSeen = setmetatable({}, { __mode = "k" })

-- [DIAG] The transition log only records CHANGES, so a silent stretch is
-- ambiguous: either the entries stopped being evaluated, or they were
-- evaluated and the aura was simply never found. These counters separate the
-- two, which is the whole remaining question.
CDF.__auraStats = CDF.__auraStats or { calls = 0, found = 0, lastCall = 0, lastFound = 0,
                                       callsCombat = 0, foundCombat = 0 }

local function CountAuraEval(active)
    local st = CDF.__auraStats
    local inCombat = (InCombatLockdown() or UnitAffectingCombat("player")) and true or false
    st.calls = st.calls + 1
    st.lastCall = GetTime()
    if inCombat then st.callsCombat = st.callsCombat + 1 end
    if active then
        st.found = st.found + 1
        st.lastFound = GetTime()
        if inCombat then st.foundCombat = st.foundCombat + 1 end
    end
end

local function LogAuraFlip(entry, auraID, active)
    if auraSeen[entry] == active then return end
    auraSeen[entry] = active
    local log = CDF.__auraLog
    log[#log + 1] = {
        t      = GetTime(),
        id     = auraID,
        active = active,
        combat = (InCombatLockdown() or UnitAffectingCombat("player")) and true or false,
    }
    while #log > AURA_LOG_MAX do table.remove(log, 1) end
end

local function entryShown(bar, r, state, entry)
    -- [G4] A tracked-buff entry only exists on screen while its aura is up.
    -- This runs before the cooldown filters: an absent proc is not "ready",
    -- it is simply not there.
    local auraID = CDF.EntryAuraID and CDF.EntryAuraID(entry, r)
    if auraID then
        local a = CDF.GetAuraState and CDF.GetAuraState(auraID)
        local active = (a and a.active) and true or false
        CountAuraEval(active)
        LogAuraFlip(entry, auraID, active)
        if not active then return false end
        return true
    end
    if bar.hideOnCooldown and not CDF.IsReady(r, state) then return false end
    if bar.hideOnUnusable and CDF.GetUsable then
        local usable = CDF.GetUsable(r)
        if usable == false then return false end
    end
    return true
end

-- [S9] True when the bar filters its icons at all, i.e. when the layout
-- depends on live state and a signature has to be tracked.
-- True when the set of icons on screen can change without a layout event.
-- Aura entries count: their icons come and go with the buff, and the
-- signature check in updateBar is what re-packs the bar when they do.
local function hasAuraEntry(bar)
    for _, e in ipairs(bar.entries or {}) do
        if type(e) == "table" and e.mode == "aura" then return true end
    end
    return false
end

local function hasHideFilter(bar)
    return bar.hideOnCooldown == true or bar.hideOnUnusable == true
           or hasAuraEntry(bar)
end

-- [S8] Compact picture of every entry's state, used to decide whether a
-- filtered bar has to be laid out again. Marks must stay in sync with the
-- ones layoutBar writes below, or the comparison never matches.
--   "-" filtered out   "x" unresolvable   "1" shown   "0" hidden
local function readySignature(bar)
    local arr, parts = bar.entries or {}, {}
    for i = 1, #arr do
        local e = arr[i]
        local mark = "-"
        if CDF.IsEntryVisible(e) then
            local r = CDF.ResolveEntry(e)
            if r and not r.empty then
                mark = entryShown(bar, r, CDF.GetCooldownState(r), e) and "1" or "0"
            else
                mark = "x"
            end
        end
        parts[i] = mark
    end
    return table.concat(parts)
end

local function layoutBar(container, bar)
    local arr = bar.entries or {}
    local visible = {}
    -- [S8] "ready only" filter. The probe in CDF_Watch lets us know
    -- the ready state BEFORE laying out, so this stays a single pass --
    -- the alternative (reading it back off the real icons) would only be
    -- knowable after applyEntry, i.e. one frame too late.
    local filtered = hasHideFilter(bar)
    local sig = filtered and {} or nil
    for i = 1, #arr do
        local e = arr[i]
        local mark = "-"
        if CDF.IsEntryVisible(e) then
            local r = CDF.ResolveEntry(e)
            if r and not r.empty then
                local keep = true
                if filtered then
                    local st = CDF.GetCooldownState(r)
                    keep = entryShown(bar, r, st, e)
                    r._cdState = st        -- reuse below, avoids a second read
                end
                mark = keep and "1" or "0"
                if keep then
                    r.override = e.override   -- [S2] per-entry FX travels with it
                    r._entry   = e            -- [G4] aura mode is read from it
                    visible[#visible + 1] = r
                end
            else
                mark = "x"
            end
        end
        if sig then sig[i] = mark end
    end
    container._readySig = sig and table.concat(sig) or nil

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
        local corner, ox, oy = CDF.__layoutOffset(bar, i, n)
        icon:ClearAllPoints()
        -- [S2] emphasis: scale the icon around its CELL center so the grid
        -- stays aligned. SetPoint offsets live in the scaled frame's local
        -- space, hence the division by the scale.
        local ov = visible[i].override
        local s = (ov and tonumber(ov.emphasis)) or 1
        if s < 1 then s = 1 elseif s > 1.3 then s = 1.3 end
        icon:SetScale(s)
        if s > 1.001 then
            local cx, cy
            if corner == "CENTER" then
                -- [S8] radial: the offset already targets the cell centre
                cx, cy = ox, oy
            else
                -- [G2] each axis re-centres on its own half-extent
                local iw, ih = CDF.IconDims(bar)
                local halfW, halfH = iw / 2, ih / 2
                cx = ox + ((corner == "TOPLEFT" or corner == "BOTTOMLEFT") and halfW or -halfW)
                cy = oy + ((corner == "TOPLEFT" or corner == "TOPRIGHT") and -halfH or halfH)
            end
            icon:SetPoint("CENTER", container, corner, cx / s, cy / s)
        else
            icon:SetPoint(corner, container, corner, ox, oy)
        end
        icon:Show()
        applyEntry(icon, visible[i],
                   visible[i]._cdState or CDF.GetCooldownState(visible[i]), bar)
    end
    for i = n + 1, #container._icons do
        container._icons[i]:Hide()
        stopGlow(container._icons[i])
    end
    container._count = n
end

-- Light refresh: re-read cooldowns on already-shown icons (no re-layout).
local function updateBar(container, bar)
    -- [S8] With a hide filter on, a cooldown tick -- [S9] or a resource
    -- crossing -- can change WHICH icons belong on the bar, not just their
    -- swipe. Re-layout only when the set actually changed, so the common
    -- case stays a light refresh.
    if hasHideFilter(bar) then
        if readySignature(bar) ~= container._readySig then
            layoutBar(container, bar)
            return
        end
    end
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
-- [S8] Does anything on screen actually need aura state? Checked on every
-- layout refresh so UNIT_AURA is only ever registered when it earns its
-- keep (see CDF.SetAuraWatch).
local function needsAuraWatch(arr)
    for i = 1, #arr do
        local bar = arr[i]
        if bar.enabled ~= false then
            if bar.glow and bar.glow.enabled and bar.glow.condition == "aura" then
                return true
            end
            for _, e in ipairs(bar.entries or {}) do
                -- [G4] a tracked-buff entry needs UNIT_AURA to appear and
                -- disappear at all
                if e.mode == "aura" then return true end
                local o = e.override
                if o and o.glowCondition == "aura" and o.glow ~= false then
                    return true
                end
            end
        end
    end
    return false
end

-- [S9] Same pay-for-what-you-use rule for SPELL_UPDATE_USABLE: only worth
-- listening to when a bar consumes castability somewhere -- a tint mode, a
-- "usable" glow condition, or the hideOnUnusable filter.
local function needsUsableWatch(arr)
    for i = 1, #arr do
        local bar = arr[i]
        if bar.enabled ~= false then
            if bar.hideOnUnusable then return true end
            local st = (CDF.ResolveStyle and CDF.ResolveStyle(bar)) or {}
            if st.unusableMode and st.unusableMode ~= "off" then return true end
            if bar.glow and bar.glow.enabled and bar.glow.condition == "usable" then
                return true
            end
            for _, e in ipairs(bar.entries or {}) do
                local o = e.override
                if o then
                    if o.unusableMode and o.unusableMode ~= "off" then return true end
                    if o.glowCondition == "usable" and o.glow ~= false then return true end
                end
            end
        end
    end
    return false
end

CDF.__hasHideFilter = hasHideFilter
CDF.__entryShown    = entryShown

-- Prints what the engine actually sees for each bar of `class`. Written for
-- the tracked-buff work: every step below is a place an icon can silently
-- vanish, and reading them one by one is faster than guessing.
function CDF.DumpAura(class)
    local P = "|cff2ed884TomoMod|r "
    class = class or CDF.PlayerClass()
    local bars = class and CDF.GetClassBars(class)
    if not bars or #bars == 0 then print(P .. "aucune barre pour " .. tostring(class)); return end
    print(P .. "--- CooldownForge / " .. tostring(class) .. " ---")
    -- api=false means the Cooldown Viewer category API did not answer, so NO
    -- ability resolves to its buff and every "candidats" below is a lone id.
    -- That is a different failure from a spell that genuinely has no link.
    if CDF.AuraLinkStatus then
        local api, n = CDF.AuraLinkStatus()
        print(("%sliens aura: api=%s entrees=%d"):format(P, tostring(api), n or 0))
    end
    for _, bar in ipairs(bars) do
        local vis = CDF.GetBarVisibility and CDF.GetBarVisibility(bar) or "?"
        -- The verdict alone is read at the moment the command runs, which is
        -- necessarily out of combat: print the CONDITIONS too, so a bar that is
        -- configured to disappear in combat is distinguishable from one that is
        -- shown but ends up with no icon.
        local conds = {}
        local v = bar.visibility
        if type(v) == "table" then
            for _, k in ipairs(CDF.VIS_CONDS or {}) do
                if v[k] ~= nil then conds[#conds + 1] = k .. "=" .. tostring(v[k]) end
            end
            if v.unmet then conds[#conds + 1] = "sinon=" .. tostring(v.unmet) end
        end
        local f = CDF._barFrames and CDF._barFrames[bar.id]
        print(("%s[%s] %s  visibilite=%s  conditions=%s  filtre=%s  cadre=%s  icones=%s"):format(
            P, tostring(bar.id), tostring(bar.name), tostring(vis),
            (#conds > 0) and table.concat(conds, ",") or "aucune",
            tostring(hasHideFilter(bar)),
            f and (f:IsShown() and ("visible/alpha=" .. string.format("%.2f", f:GetAlpha() or 1))
                                or "masque") or "absent",
            f and tostring(f._count or 0) or "-"))
        for i, e in ipairs(bar.entries or {}) do
            local r  = CDF.ResolveEntry(e)
            local id = CDF.EntryAuraID and CDF.EntryAuraID(e, r)
            local a  = id and CDF.GetAuraState and CDF.GetAuraState(id)
            local cand = id and CDF.AuraCandidates and CDF.AuraCandidates(id)
            print(("%s  %d. %s id=%s mode=%s auraSurveillee=%s candidats=%s trouve=%s visible=%s active=%s minuteur=%s cumuls=%s"):format(
                P, i, tostring(e.kind), tostring(e.id), tostring(e.mode or "cooldown"),
                tostring(id), cand and table.concat(cand, "/") or "-",
                tostring(a and a.matchedID),
                tostring(CDF.IsEntryVisible(e)),
                tostring(a and a.active), tostring(a and a.timed),
                tostring(a and a.applications)))
        end
    end
end

-- Prints the recorded transitions. `combat=true` on an `actif` line proves the
-- engine saw the buff land during combat.
function CDF.DumpAuraLog()
    local P = "|cff2ed884TomoMod|r "
    local log = CDF.__auraLog or {}
    if #log == 0 then
        print(P .. "aucune transition enregistree (joue quelques secondes puis relance)")
        return
    end
    local now = GetTime()
    local st = CDF.__auraStats or {}
    print(P .. ("evaluations=%d (dont %d en combat)  trouvees=%d (dont %d en combat)")
        :format(st.calls or 0, st.callsCombat or 0, st.found or 0, st.foundCombat or 0))
    print(P .. ("derniere evaluation il y a %.1fs  /  derniere aura trouvee il y a %s")
        :format(now - (st.lastCall or now),
                (st.lastFound and st.lastFound > 0) and ("%.1fs"):format(now - st.lastFound) or "jamais"))
    local sc = CDF.__scanStats
    if sc then
        print(P .. ("scan: %d balayages, %d auras vues, %d avec spellID lisible")
            :format(sc.calls or 0, sc.seen or 0, sc.keyed or 0))
        print(P .. ("     en combat: %d balayages, %d vues, %d lisibles  /  dernier: %d vues, %d lisibles (combat=%s)")
            :format(sc.callsCombat or 0, sc.seenCombat or 0, sc.keyedCombat or 0,
                    sc.lastSeen or 0, sc.lastKeyed or 0, tostring(sc.lastCombat)))
    end
    print(P .. ("--- %d transitions d'aura (la plus recente en dernier) ---"):format(#log))
    for i = 1, #log do
        local e = log[i]
        print(("%s  -%.1fs  aura=%s  %s  combat=%s"):format(
            P, now - e.t, tostring(e.id),
            e.active and "ACTIF" or "inactif", tostring(e.combat)))
    end
end

-- Full rebuild for the current class (visibility + layout).
function CDF.RefreshAll()
    if not CDF.DB() then return end
    local present = {}
    local arr = CDF.GetClassBars()
    if CDF.SetAuraWatch then CDF.SetAuraWatch(needsAuraWatch(arr or {})) end
    if CDF.SetUsableWatch then CDF.SetUsableWatch(needsUsableWatch(arr or {})) end
    if arr then
        for i = 1, #arr do
            local bar = arr[i]
            present[bar.id] = true
            local f = getBarFrame(bar)
            positionContainer(f, bar)
            -- [G3] "dim" keeps the bar laid out and polled, only faded. The
            -- alpha rides on the container so it multiplies with each icon's
            -- own style opacity instead of overwriting it.
            local vis = CDF.GetBarVisibility and CDF.GetBarVisibility(bar)
                        or (CDF.IsBarVisible(bar) and "show" or "hide")
            if vis == "hide" then
                f:Hide()
            else
                f:SetAlpha(vis == "dim" and CDF.GetBarDimAlpha(bar) or 1)
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
        local bar = f._bar
        -- [S8] A filtered bar hides itself once every icon is filtered out,
        -- so it must keep being polled while hidden or nothing would ever
        -- bring it back. Bars hidden by a visibility condition are
        -- deliberately left alone.
        if bar and (f:IsShown()
                    or (hasHideFilter(bar) and CDF.IsBarVisible(bar))) then
            updateBar(f, bar)
        end
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
