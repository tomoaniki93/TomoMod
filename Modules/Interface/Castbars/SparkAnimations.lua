-- =====================================
-- SparkAnimations.lua — Spark animation styles for TomoMod Castbars
-- Styles: Comet, Pulse, Helix, Glitch
-- =====================================

TomoMod_CastbarSpark = TomoMod_CastbarSpark or {}
local SA = TomoMod_CastbarSpark

local GetTime   = GetTime
local math_sin  = math.sin
local math_cos  = math.cos
local math_abs  = math.abs
local math_max  = math.max
local math_min  = math.min
local math_pi   = math.pi
local math_random = math.random
local math_fmod = math.fmod

local function Clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

SA.Styles = {}

-- [PERF] Module-scope constant tables — hoisted out of style functions to avoid
-- reallocating on every OnUpdate tick. Reassigning the locals inside each function
-- to these module-level tables is effectively zero-cost (just a register copy).
local COMET_POSITIONS = { 0.06, 0.13, 0.21, 0.32 }
local HELIX_OFFSETS   = { -12, -24, -38, -56 }
local HELIX_PHASES    = { 0, math_pi * 0.5, math_pi, math_pi * 1.5 }

-- =====================================
-- STYLE 1 : COMET
-- =====================================
SA.Styles["Comet"] = function(spark, db, progress, barWidth, elapsed)
    local head = spark.head
    local glow = spark.glow
    local tails = spark.tails
    if not head then return end

    local xPos = barWidth * progress

    head:ClearAllPoints()
    head:SetPoint("CENTER", spark.bar, "LEFT", xPos, 0)
    head:Show()

    if glow then
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", head, "CENTER", 0, 0)
        local pulse = 0.6 + 0.4 * math_sin(GetTime() * 6)
        glow:SetAlpha(Clamp(db.sparkGlowAlpha * pulse, 0, 1))
        glow:Show()
    end

    local positions = COMET_POSITIONS
    for i, tail in ipairs(tails) do
        local trailX = -(positions[i] * barWidth)
        local clampedX = math_max(trailX, -xPos)
        tail:ClearAllPoints()
        tail:SetPoint("CENTER", head, "CENTER", clampedX, 0)
        local alpha = db.sparkTailAlpha * (1 - (i - 1) * 0.22)
        tail:SetAlpha(Clamp(alpha, 0, 1))
        tail:Show()
    end
end

-- =====================================
-- STYLE 2 : PULSE
-- =====================================
SA.Styles["Pulse"] = function(spark, db, progress, barWidth, elapsed)
    local head = spark.head
    local glow = spark.glow
    local tails = spark.tails
    if not head then return end

    local xPos = barWidth * progress
    local now  = GetTime()
    local h    = db.height or 20

    head:ClearAllPoints()
    head:SetPoint("CENTER", spark.bar, "LEFT", xPos, 0)
    head:Show()

    if glow then
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", head, "CENTER", 0, 0)
        glow:SetAlpha(Clamp(db.sparkGlowAlpha * 0.5, 0, 1))
        glow:Show()
    end

    local cycleDur = 0.7
    for i, tail in ipairs(tails) do
        local offset  = (i - 1) * (cycleDur / #tails)
        local t       = math_fmod(now + offset, cycleDur) / cycleDur
        local scale   = 0.2 + t * 2.2
        local size    = h * scale
        local alpha   = Clamp(db.sparkTailAlpha * (1 - t * t), 0, 1)

        tail:ClearAllPoints()
        tail:SetPoint("CENTER", head, "CENTER", 0, 0)
        tail:SetSize(size, size)
        tail:SetAlpha(alpha)
        tail:Show()
    end
end

-- =====================================
-- STYLE 3 : HELIX
-- =====================================
SA.Styles["Helix"] = function(spark, db, progress, barWidth, elapsed)
    local head = spark.head
    local glow = spark.glow
    local tails = spark.tails
    if not head then return end

    local xPos    = barWidth * progress
    local now     = GetTime()
    local h       = db.height or 20
    local amp     = h * 0.5
    local speed   = 7

    head:ClearAllPoints()
    head:SetPoint("CENTER", spark.bar, "LEFT", xPos, 0)
    head:Show()

    if glow then
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", head, "CENTER", 0, 0)
        local pulse = 0.5 + 0.5 * math_sin(now * 4)
        glow:SetAlpha(Clamp(db.sparkGlowAlpha * pulse, 0, 1))
        glow:Show()
    end

    local xOffsets = HELIX_OFFSETS
    local phases   = HELIX_PHASES

    for i, tail in ipairs(tails) do
        local trailX  = xOffsets[i]
        local clampedX = math_max(trailX, -xPos)
        local yOff    = amp * math_sin(now * speed + phases[i])
        local alpha   = db.sparkTailAlpha * (1 - (i - 1) * 0.2)

        tail:ClearAllPoints()
        tail:SetPoint("CENTER", head, "CENTER", clampedX, yOff)
        tail:SetAlpha(Clamp(alpha, 0, 1))
        tail:Show()
    end
end

-- =====================================
-- STYLE 4 : GLITCH
-- =====================================
SA.Styles["Glitch"] = function(spark, db, progress, barWidth, elapsed)
    local head = spark.head
    local glow = spark.glow
    local tails = spark.tails
    if not head then return end

    local xPos = barWidth * progress

    head:ClearAllPoints()
    head:SetPoint("CENTER", spark.bar, "LEFT", xPos, 0)
    head:SetAlpha(0.3)
    head:Show()

    if glow then glow:Hide() end

    local colors = {
        { 1, 0.1, 0.1 },
        { 0.1, 0.8, 0.1 },
        { 0.1, 0.1, 1 },
        { 1, 1, 1 },
    }
    local glitchChance = 0.4

    for i, tail in ipairs(tails) do
        if math_random() < glitchChance then
            local ox = math_random(-8, 8)
            local oy = math_random(-3, 3)
            local col = colors[i] or colors[1]

            tail:ClearAllPoints()
            tail:SetPoint("CENTER", head, "CENTER", ox, oy)
            tail:SetVertexColor(col[1], col[2], col[3], 1)
            local alpha = db.sparkTailAlpha * (0.4 + math_random() * 0.5)
            tail:SetAlpha(Clamp(alpha, 0, 1))
            tail:Show()
        else
            tail:Hide()
        end
    end
end

-- =====================================
-- DISPATCH
-- =====================================
function SA.Update(spark, db, progress, barWidth, elapsed)
    if not spark or not spark.bar then return end
    if progress <= 0.001 or progress >= 0.999 then
        SA.HideAll(spark)
        return
    end

    local style = db.sparkStyle or "Comet"
    local fn = SA.Styles[style]
    if not fn then fn = SA.Styles["Comet"] end

    local ok, err = pcall(fn, spark, db, progress, barWidth, elapsed)
    if not ok then
        pcall(SA.Styles["Comet"], spark, db, progress, barWidth, elapsed)
    end
end

function SA.HideAll(spark)
    if not spark then return end
    if spark.head then spark.head:Hide() end
    if spark.glow then spark.glow:Hide() end
    if spark.tails then
        for _, t in ipairs(spark.tails) do t:Hide() end
    end
end

function SA.CreateSparkTextures(castbar, db)
    local spark = {}
    spark.bar = castbar

    local h = db.height or 20

    local head = castbar:CreateTexture(nil, "OVERLAY", nil, 5)
    head:SetTexture(db.customSparkPath)
    head:SetSize(14, h * 1.4)
    head:SetBlendMode("ADD")
    head:SetAlpha(0.95)
    head:Hide()
    spark.head = head

    local glow = castbar:CreateTexture(nil, "OVERLAY", nil, 4)
    glow:SetTexture("Interface\\CastingBar\\UI-CastingBar-Pushback")
    glow:SetSize(h * 3.5, h * 2.2)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0)
    glow:Hide()
    spark.glow = glow

    local tailTex    = db.customSparkPath
    local tailSizes  = {
        { 28, h * 1.2 },
        { 20, h * 0.9 },
        { 14, h * 0.7 },
        { 10, h * 0.5 },
    }

    spark.tails = {}
    for i = 1, 4 do
        local tail = castbar:CreateTexture(nil, "OVERLAY", nil, 3)
        tail:SetTexture(tailTex)
        tail:SetSize(tailSizes[i][1], tailSizes[i][2])
        tail:SetBlendMode("ADD")
        tail:Hide()
        spark.tails[i] = tail
    end

    return spark
end

function SA.ApplyColors(spark, db)
    if not spark then return end
    local sc = db.sparkColor or { r=1, g=1, b=1 }
    local gc = db.sparkGlowColor or { r=0.8, g=0.6, b=1 }
    local tc = db.sparkTailColor or { r=0.9, g=0.7, b=0.3 }

    if spark.head then spark.head:SetVertexColor(sc.r, sc.g, sc.b, 1) end
    if spark.glow then spark.glow:SetVertexColor(gc.r, gc.g, gc.b, 1) end
    if spark.tails then
        for _, t in ipairs(spark.tails) do
            t:SetVertexColor(tc.r, tc.g, tc.b, 1)
        end
    end
end

function SA.ApplySizes(spark, db)
    if not spark then return end
    local h = db.height or 20
    local sizes = {
        { 28, h * 1.2 },
        { 20, h * 0.9 },
        { 14, h * 0.7 },
        { 10, h * 0.5 },
    }
    if spark.head then spark.head:SetSize(14, h * 1.4) end
    if spark.glow then spark.glow:SetSize(h * 3.5, h * 2.2) end
    if spark.tails then
        for i, t in ipairs(spark.tails) do
            if sizes[i] then t:SetSize(sizes[i][1], sizes[i][2]) end
        end
    end
end
