-- =====================================================================
-- TomoMod Native Glow Engine
-- Shared lightweight glow renderer for TomoMod modules.
--
-- Midnight 12.1: this renderer is self-contained and does not depend on
-- removed SharedXML animation globals. Animated Lua styles share one gated
-- driver; flipbook styles use AnimationGroup and therefore run C-side.
-- =====================================================================

local ns = TomoMod_TuiNS
if not ns or ns.NativeGlow then return end

local Glow = {}
ns.NativeGlow = Glow
_G.TomoMod_NativeGlow = Glow

local floor, sin, max = math.floor, math.sin, math.max
local TWO_PI = math.pi * 2
local WHITE = "Interface\\Buttons\\WHITE8X8"
local CLASSIC_ANTS = "Interface\\SpellActivationOverlay\\IconAlertAnts"
local MODERN_PROC_ATLAS = "UI-HUD-ActionBar-Proc-Loop-Flipbook"

-- One weak owner registry. Each owner can host multiple keyed effects without
-- one TomoMod subsystem stopping another subsystem's glow.
local owners = setmetatable({}, { __mode = "k" })

local active = {}
local activeFn = {}
local activeIndex = setmetatable({}, { __mode = "k" })
local activeCount = 0
local driver
local driverAccum = 0
local DRIVER_GATE = 0.016

local function IsSecret(v)
    return issecretvalue and issecretvalue(v)
end

local function SafeNumber(v, fallback)
    if v == nil or IsSecret(v) then return fallback end
    local n = tonumber(v)
    return n or fallback
end

local function ReadSize(frame, fallbackW, fallbackH)
    if not frame or not frame.GetSize then return fallbackW or 36, fallbackH or fallbackW or 36 end
    local ok, w, h = pcall(frame.GetSize, frame)
    if not ok or IsSecret(w) or IsSecret(h) then
        return fallbackW or 36, fallbackH or fallbackW or 36
    end
    w = SafeNumber(w, fallbackW or 36)
    h = SafeNumber(h, fallbackH or fallbackW or 36)
    if w <= 0 then w = fallbackW or 36 end
    if h <= 0 then h = fallbackH or fallbackW or 36 end
    return w, h
end

local function DriverOnUpdate(self, elapsed)
    local dt = driverAccum + (elapsed or 0)
    if dt < DRIVER_GATE then
        driverAccum = dt
        return
    end
    driverAccum = 0

    local i = 1
    while i <= activeCount do
        local wrapper = active[i]
        local visible = true
        if wrapper and wrapper.IsVisible then
            local ok, value = pcall(wrapper.IsVisible, wrapper)
            if ok and not IsSecret(value) then visible = value and true or false end
        end
        if visible then
            local fn = activeFn[i]
            if fn then fn(wrapper, dt) end
        end
        if active[i] == wrapper then i = i + 1 end
    end

    if activeCount == 0 then self:Hide() end
end

local function ArmDriver()
    if not driver then
        driver = CreateFrame("Frame")
        driver:Hide()
        driver:SetScript("OnUpdate", DriverOnUpdate)
    end
    driverAccum = 0
    driver:Show()
end

local function RegisterAnimated(wrapper, fn)
    local idx = activeIndex[wrapper]
    if idx then
        activeFn[idx] = fn
        return
    end
    activeCount = activeCount + 1
    active[activeCount] = wrapper
    activeFn[activeCount] = fn
    activeIndex[wrapper] = activeCount
    if activeCount == 1 then ArmDriver() end
end

local function UnregisterAnimated(wrapper)
    local idx = activeIndex[wrapper]
    if not idx then return end
    local last = active[activeCount]
    active[idx] = last
    activeFn[idx] = activeFn[activeCount]
    if last then activeIndex[last] = idx end
    active[activeCount] = nil
    activeFn[activeCount] = nil
    activeIndex[wrapper] = nil
    activeCount = activeCount - 1
    if activeCount == 0 and driver then driver:Hide() end
end

local function OwnerBucket(owner)
    local bucket = owners[owner]
    if not bucket then
        bucket = {}
        owners[owner] = bucket
    end
    return bucket
end

local function NormalizeKey(key, fallback)
    if type(key) == "string" and key ~= "" then return key end
    return fallback or "__default"
end

local function CreateWrapper(owner)
    local wrapper = CreateFrame("Frame", nil, owner)
    wrapper:SetAllPoints(owner)
    wrapper:EnableMouse(false)
    wrapper:Hide()
    if owner.GetFrameLevel and wrapper.SetFrameLevel then
        local ok, level = pcall(owner.GetFrameLevel, owner)
        if ok and type(level) == "number" and not IsSecret(level) then
            pcall(wrapper.SetFrameLevel, wrapper, level + 20)
        end
    end
    return wrapper
end

local function GetWrapper(owner, key, create)
    if not owner then return nil end
    local bucket = owners[owner]
    if not bucket and create then bucket = OwnerBucket(owner) end
    if not bucket then return nil end
    local wrapper = bucket[key]
    if not wrapper and create then
        wrapper = CreateWrapper(owner)
        wrapper._tmGlowOwner = owner
        wrapper._tmGlowKey = key
        bucket[key] = wrapper
    end
    return wrapper
end

local function HideTextures(list)
    if not list then return end
    for i = 1, #list do
        if list[i] then list[i]:Hide() end
    end
end

local function StopWrapper(wrapper)
    if not wrapper then return end
    UnregisterAnimated(wrapper)

    local p = wrapper._tmPixel
    if p then HideTextures(p.segments) end
    local a = wrapper._tmAuto
    if a then HideTextures(a.dots) end
    local b = wrapper._tmButton
    if b then
        if b.group and b.group:IsPlaying() then b.group:Stop() end
        if b.texture then b.texture:Hide() end
    end
    local proc = wrapper._tmProc
    if proc then
        if proc.group and proc.group:IsPlaying() then proc.group:Stop() end
        if proc.texture then proc.texture:Hide() end
    end

    wrapper._tmGlowKind = nil
    wrapper:Hide()
end

local function PrepareWrapper(owner, key)
    key = NormalizeKey(key)
    return GetWrapper(owner, key, true)
end

function Glow.Prepare(owner, key)
    return PrepareWrapper(owner, NormalizeKey(key))
end

function Glow.Stop(owner, key)
    key = NormalizeKey(key)
    StopWrapper(GetWrapper(owner, key, false))
end

function Glow.StopAll(owner)
    local bucket = owners[owner]
    if not bucket then return end
    for _, wrapper in pairs(bucket) do StopWrapper(wrapper) end
end

function Glow.IsActive(owner, key, kind)
    key = NormalizeKey(key)
    local wrapper = GetWrapper(owner, key, false)
    if not wrapper or not wrapper:IsShown() then return false end
    return not kind or wrapper._tmGlowKind == kind
end

local function SetGlowColor(texture, color)
    color = color or { 1, 1, 1, 1 }
    texture:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
end

-- ---------------------------------------------------------------------
-- Pixel Glow: moving line segments around the perimeter.
-- ---------------------------------------------------------------------
local function PixelPoint(dist, w, h)
    if dist < w then return dist, 0, true end
    dist = dist - w
    if dist < h then return w, -dist, false end
    dist = dist - h
    if dist < w then return w - dist, -h, true end
    dist = dist - w
    return 0, -(h - dist), false
end

local function PixelUpdate(wrapper, elapsed)
    local d = wrapper._tmPixel
    if not d then return end
    local w, h = ReadSize(wrapper, d.fallbackW, d.fallbackH)
    local perim = 2 * (w + h)
    if perim <= 0 then return end
    d.phase = (d.phase + elapsed / d.period * perim) % perim
    local spacing = perim / d.count

    for i = 1, d.count do
        local tex = d.segments[i]
        local dist = (d.phase + (i - 1) * spacing) % perim
        local x, y, horizontal = PixelPoint(dist, w, h)
        tex:ClearAllPoints()
        if horizontal then
            tex:SetSize(d.length, d.thickness)
        else
            tex:SetSize(d.thickness, d.length)
        end
        tex:SetPoint("CENTER", wrapper, "TOPLEFT", x + d.xOffset, y + d.yOffset)
    end
end

function Glow.PixelGlow_Start(owner, color, lines, frequency, length, thickness, xOffset, yOffset, border, key)
    key = NormalizeKey(key, "__pixel")
    local wrapper = GetWrapper(owner, key, true)
    StopWrapper(wrapper)

    local d = wrapper._tmPixel
    if not d then
        d = { segments = {}, phase = 0 }
        wrapper._tmPixel = d
    end
    d.count = max(2, floor(SafeNumber(lines, 8)))
    d.period = max(0.20, SafeNumber(frequency, 0.25) * 4)
    d.length = max(2, SafeNumber(length, 8))
    d.thickness = max(1, SafeNumber(thickness, 2))
    d.fallbackW, d.fallbackH = ReadSize(owner, 36, 36)
    d.xOffset = SafeNumber(xOffset, 0)
    d.yOffset = SafeNumber(yOffset, 0)
    d.phase = 0

    for i = 1, d.count do
        local tex = d.segments[i]
        if not tex then
            tex = wrapper:CreateTexture(nil, "OVERLAY", nil, 7)
            tex:SetTexture(WHITE)
            tex:SetBlendMode("ADD")
            d.segments[i] = tex
        end
        SetGlowColor(tex, color)
        tex:Show()
    end
    for i = d.count + 1, #d.segments do d.segments[i]:Hide() end

    wrapper._tmGlowKind = "pixel"
    wrapper:Show()
    RegisterAnimated(wrapper, PixelUpdate)
end

function Glow.PixelGlow_Stop(owner, key)
    key = NormalizeKey(key, "__pixel")
    local wrapper = GetWrapper(owner, key, false)
    if wrapper and wrapper._tmGlowKind == "pixel" then StopWrapper(wrapper) end
end

-- ---------------------------------------------------------------------
-- Auto-Cast Shine: lightweight orbiting additive sparkles.
-- ---------------------------------------------------------------------
local function AutoUpdate(wrapper, elapsed)
    local d = wrapper._tmAuto
    if not d then return end
    local w, h = ReadSize(wrapper, d.fallbackW, d.fallbackH)
    local perim = 2 * (w + h)
    if perim <= 0 then return end
    d.phase = (d.phase + elapsed / d.period) % 1
    for i = 1, d.count do
        local dot = d.dots[i]
        local t = ((i - 1) / d.count + d.phase) % 1
        local x, y = PixelPoint(t * perim, w, h)
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", wrapper, "TOPLEFT", x + d.xOffset, y + d.yOffset)
        dot:SetAlpha(0.55 + 0.45 * (0.5 + 0.5 * sin((t * TWO_PI) + d.phase * TWO_PI)))
    end
end

function Glow.AutoCastGlow_Start(owner, color, particles, frequency, scale, xOffset, yOffset, key)
    key = NormalizeKey(key, "__autocast")
    local wrapper = GetWrapper(owner, key, true)
    StopWrapper(wrapper)

    local d = wrapper._tmAuto
    if not d then
        d = { dots = {}, phase = 0 }
        wrapper._tmAuto = d
    end
    d.count = max(2, floor(SafeNumber(particles, 4)))
    d.period = max(0.35, SafeNumber(frequency, 0.25) * 8)
    d.scale = max(0.5, SafeNumber(scale, 1))
    d.fallbackW, d.fallbackH = ReadSize(owner, 36, 36)
    d.xOffset = SafeNumber(xOffset, 0)
    d.yOffset = SafeNumber(yOffset, 0)
    d.phase = 0

    local dotSize = 4 * d.scale
    for i = 1, d.count do
        local dot = d.dots[i]
        if not dot then
            dot = wrapper:CreateTexture(nil, "OVERLAY", nil, 7)
            dot:SetTexture(WHITE)
            dot:SetBlendMode("ADD")
            d.dots[i] = dot
        end
        dot:SetSize(dotSize, dotSize)
        SetGlowColor(dot, color)
        dot:Show()
    end
    for i = d.count + 1, #d.dots do d.dots[i]:Hide() end

    wrapper._tmGlowKind = "autocast"
    wrapper:Show()
    RegisterAnimated(wrapper, AutoUpdate)
end

function Glow.AutoCastGlow_Stop(owner, key)
    key = NormalizeKey(key, "__autocast")
    local wrapper = GetWrapper(owner, key, false)
    if wrapper and wrapper._tmGlowKind == "autocast" then StopWrapper(wrapper) end
end

local function SetupFlipBook(wrapper, storageKey, textureOrAtlas, isAtlas, color, rows, columns, frames, duration, frameWidth, frameHeight)
    local d = wrapper[storageKey]
    if not d then
        local tex = wrapper:CreateTexture(nil, "OVERLAY", nil, 7)
        tex:SetPoint("TOPLEFT", wrapper, "TOPLEFT", -6, 6)
        tex:SetPoint("BOTTOMRIGHT", wrapper, "BOTTOMRIGHT", 6, -6)
        tex:SetBlendMode("ADD")
        local group = tex:CreateAnimationGroup()
        group:SetLooping("REPEAT")
        local anim = group:CreateAnimation("FlipBook")
        d = { texture = tex, group = group, anim = anim }
        wrapper[storageKey] = d
    end

    if isAtlas then
        local ok = pcall(d.texture.SetAtlas, d.texture, textureOrAtlas)
        if not ok then
            d.texture:SetTexture(CLASSIC_ANTS)
            rows, columns, frames = 5, 5, 22
        end
    else
        d.texture:SetTexture(textureOrAtlas)
    end
    d.texture:SetDesaturated(true)
    SetGlowColor(d.texture, color)
    d.texture:Show()

    d.anim:SetFlipBookRows(rows)
    d.anim:SetFlipBookColumns(columns)
    d.anim:SetFlipBookFrames(frames)
    if d.anim.SetFlipBookFrameWidth then d.anim:SetFlipBookFrameWidth(frameWidth or 0) end
    if d.anim.SetFlipBookFrameHeight then d.anim:SetFlipBookFrameHeight(frameHeight or 0) end
    d.anim:SetDuration(duration)
    if d.group:IsPlaying() then d.group:Stop() end
    d.group:Play()
    return d
end

function Glow.ButtonGlow_Start(owner, color, frequency, key)
    key = NormalizeKey(key, "__button")
    local wrapper = GetWrapper(owner, key, true)
    StopWrapper(wrapper)
    local duration = max(0.22, SafeNumber(frequency, 0.125) * 3)
    SetupFlipBook(wrapper, "_tmButton", CLASSIC_ANTS, false, color, 5, 5, 22, duration, 48, 48)
    wrapper._tmGlowKind = "button"
    wrapper:Show()
end

function Glow.ButtonGlow_Stop(owner, key)
    key = NormalizeKey(key, "__button")
    local wrapper = GetWrapper(owner, key, false)
    if wrapper and wrapper._tmGlowKind == "button" then StopWrapper(wrapper) end
end

function Glow.ProcGlow_Start(owner, options)
    options = options or {}
    local key = NormalizeKey(options.key, "__proc")
    local wrapper = GetWrapper(owner, key, true)
    StopWrapper(wrapper)
    SetupFlipBook(wrapper, "_tmProc", MODERN_PROC_ATLAS, true, options.color, 6, 5, 30, 0.90, 0, 0)
    wrapper._tmGlowKind = "proc"
    wrapper:Show()
end

function Glow.ProcGlow_Stop(owner, key)
    key = NormalizeKey(key, "__proc")
    local wrapper = GetWrapper(owner, key, false)
    if wrapper and wrapper._tmGlowKind == "proc" then StopWrapper(wrapper) end
end

return Glow
