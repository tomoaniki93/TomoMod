-- =====================================================================
-- CBElements.lua -- AstralForge descriptors for the "castbar" domain
-- ---------------------------------------------------------------------
-- Third domain, after "unitframe" and "nameplate". Every default below
-- reproduces EXACTLY the anchor Castbar.lua hard-codes when it builds
-- the bar, so a fresh profile and an existing one render identically.
-- The same discipline UFElements.lua applied: the registry takes over
-- placement without moving anything on the way in.
--
-- Not registered as movable elements, on purpose:
--
--   * bg        -- SetAllPoints, not a single-point anchor. It has no
--                  position to edit; stretching to the bar IS what it is.
--   * icon and  -- their anchor flips side with the iconSide setting, so
--     iconBorder   the descriptor default would be a lie half the time.
--                  Handing placement to the registry means iconSide stops
--                  meaning anything, and that migration is worth doing on
--                  its own rather than smuggling in here. They ARE hosts,
--                  so the texts can anchor to them today.
--   * spark, latency, tick and stage markers -- positioned from the cast
--     progress on every frame. A stored anchor would be overwritten
--     milliseconds later.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge or not Forge.Registry then return end

local R = Forge.Registry

TomoMod_CBElements = TomoMod_CBElements or {}
local CBE = TomoMod_CBElements

CBE.DOMAIN = "castbar"
local DOMAIN = CBE.DOMAIN

-- ---------------------------------------------------------------------
-- Hosts
-- ---------------------------------------------------------------------
-- Structural widgets Castbar.lua positions itself. They can be anchored
-- TO, never moved BY the studio.
-- ---------------------------------------------------------------------

R.DefineHost(DOMAIN, {
    id       = "bar",
    labelKey = "anchor_host_cb_bar",
    resolve  = function(frame) return frame end,
})

R.DefineHost(DOMAIN, {
    id       = "icon",
    labelKey = "anchor_host_cb_icon",
    resolve  = function(frame) return frame and frame.icon end,
})

R.DefineHost(DOMAIN, {
    id       = "iconBorder",
    labelKey = "anchor_host_cb_iconborder",
    resolve  = function(frame) return frame and frame.iconBorder end,
})

-- ---------------------------------------------------------------------
-- Elements
-- ---------------------------------------------------------------------

R.Define(DOMAIN, {
    id         = "spellText",
    kind       = "fontstring",
    labelKey   = "elem_cb_spell",
    order      = 10,
    anchorMode = "inside",
    -- Castbar.lua: spellText:SetPoint("LEFT", 4, 0) -- implicit parent.
    default    = { point = "LEFT", relTo = "bar", relPoint = "LEFT", x = 4, y = 0 },
    resolve    = function(frame) return frame and frame.spellText end,
})

R.Define(DOMAIN, {
    id         = "timerText",
    kind       = "fontstring",
    labelKey   = "elem_cb_timer",
    order      = 20,
    anchorMode = "inside",
    -- Castbar.lua: timerText:SetPoint("RIGHT", -4, 0)
    default    = { point = "RIGHT", relTo = "bar", relPoint = "RIGHT", x = -4, y = 0 },
    resolve    = function(frame) return frame and frame.timerText end,
})

R.Define(DOMAIN, {
    id         = "targetText",
    kind       = "fontstring",
    labelKey   = "elem_cb_target",
    order      = 30,
    anchorMode = "inside",
    -- Castbar.lua: targetText:SetPoint("LEFT", spellText, "RIGHT", 4, 0).
    -- The engine's own edge, so the registry can see it and its cycle
    -- walk guards a player pointing spellText back at this one.
    default    = { point = "LEFT", relTo = "spellText", relPoint = "RIGHT", x = 4, y = 0 },
    resolve    = function(frame) return frame and frame.targetText end,
})

-- ---------------------------------------------------------------------
-- Entry points
-- ---------------------------------------------------------------------
-- Same three names every domain exposes, so AstralForge can hold a
-- registry without knowing which one it is.
-- ---------------------------------------------------------------------

function CBE.Ensure(store)
    return R.Ensure(DOMAIN, store)
end

function CBE.ApplyAll(bar, store)
    return R.ApplyAll(DOMAIN, bar, store)
end

function CBE.List()
    return R.List(DOMAIN)
end

-- ---------------------------------------------------------------------
-- Preview
-- ---------------------------------------------------------------------
-- CB.CreateCastbar parents to UIParent, names the frame after the unit,
-- registers a dozen events and installs a drag overlay. None of that
-- belongs on a studio stage, and threading a "preview" flag through
-- three hundred lines of live-cast machinery to suppress it would put
-- the real bar one bad branch away from breaking.
--
-- So the stage gets its own bar. It reads the same settings and builds
-- the same four widgets under the same names, which is all the canvas
-- needs: placement is geometry, not behaviour. Nothing here ever reads
-- a unit or fires an event.
-- ---------------------------------------------------------------------

local PREVIEW_SPELL = 116        -- Frostbolt: a familiar icon, no unit read
local previewBin

function CBE.CreatePreview(parent, unit, opts)
    if not parent then return nil end
    local db = TomoModDB and TomoModDB.castbars
    if not db then return nil end
    local s = db[unit] or db.player
    if type(s) ~= "table" then return nil end

    -- WoW frames cannot be destroyed, so the previous stage bar goes to a
    -- hidden bin the way UFPreview and the nameplate preview already do.
    local old = opts and opts.recycle
    if old then
        old:Hide()
        old:ClearAllPoints()
        if not previewBin then
            previewBin = CreateFrame("Frame")
            previewBin:Hide()
        end
        old:SetParent(previewBin)
    end

    local CB   = TomoMod_Castbar
    local tex  = CB and CB.ResolveBarTexture and CB.ResolveBarTexture(db)
    local font = CB and CB.ResolveFont and CB.ResolveFont(db)

    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(s.width or 200, s.height or 20)
    if tex then bar:SetStatusBarTexture(tex) end
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(62)
    bar:EnableMouse(false)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)

    if s.showIcon then
        local icon = bar:CreateTexture(nil, "OVERLAY")
        icon:SetSize(s.height or 20, s.height or 20)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local tx = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(PREVIEW_SPELL)
        if tx then icon:SetTexture(tx) end
        if (s.iconSide or "LEFT") == "RIGHT" then
            icon:SetPoint("LEFT", bar, "RIGHT", 3, 0)
        else
            icon:SetPoint("RIGHT", bar, "LEFT", -3, 0)
        end
        bar.icon = icon

        local ib = CreateFrame("Frame", nil, bar)
        ib:SetPoint("TOPLEFT",     icon, "TOPLEFT",     -1,  1)
        ib:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT",  1, -1)
        bar.iconBorder = ib
    end

    local size = (TomoModDB.castbars and TomoModDB.castbars.fontSize) or 12

    local spell = bar:CreateFontString(nil, "OVERLAY")
    if font then spell:SetFont(font, size, "OUTLINE") end
    spell:SetTextColor(1, 1, 1, 1)
    spell:SetJustifyH("LEFT")
    spell:SetText((TomoMod_L and TomoMod_L["cb_preview_spell"]) or "Spell Name")
    bar.spellText = spell

    if s.showTimer then
        local timer = bar:CreateFontString(nil, "OVERLAY")
        if font then timer:SetFont(font, size, "OUTLINE") end
        timer:SetTextColor(1, 1, 1, 0.9)
        timer:SetText("1.4")
        bar.timerText = timer
    end

    -- Castbar.lua only builds the target line for units other than the
    -- player and the pet; the preview mirrors that so the element list
    -- does not offer something the live bar will not have.
    if unit ~= "player" and unit ~= "pet" then
        local target = bar:CreateFontString(nil, "OVERLAY")
        if font then target:SetFont(font, size, "OUTLINE") end
        target:SetTextColor(1, 1, 1, 0.6)
        target:SetJustifyH("LEFT")
        target:SetText((TomoMod_L and TomoMod_L["cb_preview_target"]) or "Target")
        bar.targetText = target
    end

    return bar
end

