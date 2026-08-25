-- ---------------------------------------------------------------------
-- AuraContainer.lua -- every aura display, through the 12.1 aura engine
--
-- The scan-and-draw approach cannot work any more: since 12.1 the client
-- refuses aura reads from addon code while auras are restricted, which is
-- most of a dungeon pull. Guarding those reads stopped the errors but the
-- debuffs simply stopped appearing in combat, which is when they matter.
--
-- CustomAuraContainerTemplate inverts the flow. We declare a container,
-- a filter and how to build one button; the client does the scanning,
-- sorting and updating itself and hands us buttons to style. Nothing here
-- ever reads an aura, so nothing here can be refused.
--
-- Every aura display in the addon goes through here: nameplate debuffs
-- and buffs, unit frame auras, group and raid frames. There is no legacy
-- scan any more -- the TOC floor is 12.1, so the engine is always there.
-- ---------------------------------------------------------------------

local AC = {}
TomoMod_AuraContainer = AC

-- Per-button regions, keyed by button. The engine owns the buttons and
-- recycles them, so anything of ours has to hang off a side table rather
-- than off fields it might reuse.
local buttonData = setmetatable({}, { __mode = "k" })

-- What each container was built with. Relayout rebuilds its group from
-- this rather than asking the engine, which exposes no getters.
local containerSpec = setmetatable({}, { __mode = "k" })

-- ---------------------------------------------------------------------
-- Filter strings
--
-- The engine batches one scan per DISTINCT filter string, compared byte
-- for byte. Two callers asking for the same thing in a different token
-- order pay for two scans, so every filter in the suite is built here:
-- polarity first, then the rest in a fixed order.
-- ---------------------------------------------------------------------
function AC.Filter(...)
    local n = select("#", ...)
    local base, rest = nil, {}
    for i = 1, n do
        local t = select(i, ...)
        if t and t ~= "" then
            if t == "HELPFUL" or t == "HARMFUL" then
                base = t
            else
                rest[#rest + 1] = t
            end
        end
    end
    base = base or "HARMFUL"
    -- A negated token sorts directly after the token it negates, so
    -- "!CROWD_CONTROL" cannot land far from "CROWD_CONTROL" and turn one
    -- request into two scans.
    table.sort(rest, function(a, b)
        local ka = (a:sub(1, 1) == "!") and (a:sub(2) .. "!") or a
        local kb = (b:sub(1, 1) == "!") and (b:sub(2) .. "!") or b
        return ka < kb
    end)

    -- No cache: Lua interns strings, so looking one up costs what building
    -- it costs. The table only added memory.
    local key = base
    for i = 1, #rest do key = key .. "|" .. rest[i] end
    return key
end

-- ---------------------------------------------------------------------
-- Availability
-- ---------------------------------------------------------------------

local _available   -- nil = not yet probed

-- True when this client has the aura container engine.
--
-- The TOC floor is 12.1, so this is expected to be true. It is still a
-- probe rather than an assumption: a client that loads the addon with a
-- missing template should draw nothing, not error on every plate.
--
-- Probed by creating one and throwing it away -- the frame type and the
-- template must both exist, and the interface version does not say
-- whether the template is registered.
function AC.IsAvailable()
    if _available ~= nil then return _available end

    local ok, frame = pcall(CreateFrame, "AuraContainer", nil, UIParent,
        "CustomAuraContainerTemplate")
    if ok and frame and frame.AddAuraGroup and frame.SetUnit then
        _available = true
        -- Nothing owns this one; park it rather than leave it visible.
        frame:Hide()
        frame:SetParent(nil)
    else
        _available = false
    end
    return _available
end

-- ---------------------------------------------------------------------
-- Button construction
--
-- Order matters and is not obvious: every Set* registration immediately
-- runs the engine's update, which writes into our font strings. A font
-- string with no font assigned errors inside the engine, so all regions
-- are created and styled BEFORE any of them is registered.
-- ---------------------------------------------------------------------

-- Buttons whose size has not landed yet. Weak keys: the engine pools and
-- discards buttons, and a stale entry must not keep one alive.
local pending = setmetatable({}, { __mode = "k" })

-- Applies the recorded size. Returns true once it has landed.
function AC.TrySize(button)
    local d = buttonData[button]
    if not d or not d.wantSize then return false end
    if d.sizedTo == d.wantSize then pending[button] = nil; return true end

    local size = d.wantSize
    -- Height is size - 4 for a normal aura button; a probe button is square
    -- and one pixel, where that formula would ask for a negative height.
    local ok = pcall(button.SetSize, button, size, d.wantHeight or (size - 4))
    -- Stamped AFTER the call: stamping first would make the next retry read
    -- a refusal as already applied, which is the bug this exists for.
    if ok then
        d.sizedTo = size
        pending[button] = nil
        return true
    end
    return false
end

-- Retries every outstanding button.
function AC.ResizePending()
    if not next(pending) then return end
    for button in pairs(pending) do
        AC.TrySize(button)
    end
end

local function MakeInitializer(opts)
    return function(button)
        local d = {}
        buttonData[button] = d

        local size = opts.size or 24
        -- The engine anchors buttons but never sizes them: an unsized button
        -- renders nothing at all.
        --
        -- SetSize on an aura button is refused while auras are restricted --
        -- exactly the situation this file exists for. A button first built
        -- during a restricted stretch would come out sizeless and stay that
        -- way, because the engine runs this initializer once per pooled
        -- button, not again on reuse.
        --
        -- So the wanted size is recorded and retried from the container
        -- update. d.wantSize is what was asked for, d.sizedTo what landed;
        -- they differ only while a refusal is outstanding.
        d.wantSize = size
        pending[button] = true
        AC.TrySize(button)

        -- The engine shows aura tooltips itself: motion is what carries
        -- them, clicks are separate. Disabling clicks was right; disabling
        -- motion would silently drop a feature the unit frames had.
        pcall(button.SetMouseClickEnabled, button, false)
        if opts.tooltips == false then
            pcall(button.SetMouseMotionEnabled, button, false)
        else
            pcall(button.SetMouseMotionEnabled, button, true)
            if button.SetTooltipAnchorPoint then
                pcall(button.SetTooltipAnchorPoint, button, "ANCHOR_BOTTOMLEFT")
            end
        end

        d.icon = button:CreateTexture(nil, "ARTWORK")
        d.icon:SetPoint("TOPLEFT", 1, -1)
        d.icon:SetPoint("BOTTOMRIGHT", -1, 1)
        local crop = 2 / size
        d.icon:SetTexCoord(0.08, 0.92, 0.08 + crop, 0.92 - crop)

        -- CooldownFrameTemplate carries the swipe textures; a bare
        -- Cooldown draws no swipe.
        d.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        d.cooldown:SetAllPoints(d.icon)
        d.cooldown:SetDrawEdge(false)
        d.cooldown:SetReverse(true)
        -- Blizzard's swipe digits stay off, always. The remaining time is
        -- written by the engine on d.duration below, and having both on drew
        -- it twice -- once centred over the icon art, once in the corner.
        -- One mechanism, placed and coloured per caller; showDuration now
        -- governs that one font string rather than a second overlay.
        d.cooldown:SetHideCountdownNumbers(true)
        d.cooldown:EnableMouse(false)

        d.count = button:CreateFontString(nil, "OVERLAY")
        d.count:SetFont(opts.font, 9, "OUTLINE")
        d.count:SetPoint("BOTTOMRIGHT", 1, 1)
        d.count:SetJustifyH("RIGHT")

        d.duration = button:CreateFontString(nil, "OVERLAY")
        d.duration:SetFont(opts.font, 9, "OUTLINE")
        -- Placement and colour are the caller's: the plates want it in the
        -- corner in yellow, the unit frames had their time centred on the
        -- icon in white. Same mechanism, each surface keeps its look.
        local dp = opts.durationPoint or "TOPLEFT"
        local drp = opts.durationRelPoint or dp
        d.duration:SetPoint(dp, button, drp, opts.durationX or -3, opts.durationY or 4)
        d.duration:SetJustifyH("LEFT")
        local dc = opts.durationColor
        if dc then
            d.duration:SetTextColor(dc[1], dc[2], dc[3], dc[4] or 1)
        else
            d.duration:SetTextColor(1, 1, 0, 1)
        end

        if opts.border then opts.border(button) end

        -- Dispel-type colouring. The old scans read auraData.dispelName and
        -- picked a border colour from it; the engine does that itself, from
        -- data we are no longer allowed to read.
        if opts.dispelBorder and button.AddDispelTypeTexture then
            d.dispelBorder = button:CreateTexture(nil, "OVERLAY", nil, 6)
            d.dispelBorder:SetAllPoints(button)
            pcall(button.AddDispelTypeTexture, button, d.dispelBorder, {
                showWhenHarmful = true,
                showWhenHelpful = false,
                customDispelColorMap = opts.dispelColorMap,
            })
        end

        -- Registration last, and each one guarded: these are the calls the
        -- client refuses while auras are restricted, and one refusal must
        -- not stop the others from binding.
        pcall(button.SetIcon, button, d.icon)
        pcall(button.SetDurationCooldown, button, d.cooldown)
        pcall(button.SetApplicationCount, button, d.count, {})
        if button.SetDurationText then
            pcall(button.SetDurationText, button, d.duration, {})
        end
        d.duration:SetShown(opts.showDuration ~= false)
    end
end

-- ---------------------------------------------------------------------
-- Container layout
--
-- Growth direction and wrapping belong to the CONTAINER, not to a group:
-- a group's layout only describes one button's box. Sending element sizes
-- and nothing else is why the grow direction and the icons-per-row limit
-- stopped doing anything after the conversion.
-- ---------------------------------------------------------------------

-- Blizzard names the two axes separately, and so does the addon: unit frame
-- auras carry growDirection (LEFT/RIGHT) and growVertical (UP, or nil for
-- DOWN) as independent settings, both exposed in the options. Folding the
-- vertical axis into the horizontal one would have pinned every row to Down
-- and made the "grow upwards" dropdown do nothing.
--
-- growDirection also accepts UP/DOWN, which other surfaces store; those name
-- the vertical axis, so they leave the horizontal one at its default.
local HORIZONTAL = { LEFT = "Left", RIGHT = "Right" }
local VERTICAL   = { UP = "Up", DOWN = "Down" }

-- The flow always starts AT its anchor corner and grows AWAY from it: a
-- container anchored by its TOPLEFT with growVertical=UP grows further and
-- further past its own top edge, leaving the space between its anchor and
-- whatever it was meant to sit next to (a health bar, say) empty. The
-- anchor corner has to be the one the content grows AWAY from, i.e. the
-- opposite edge from the growth direction, so row/col 1 lands at the
-- anchor and the stack fills outward from there instead of floating off
-- past it.
local HORIZONTAL_ANCHOR = { LEFT = "RIGHT", RIGHT = "LEFT" }
local VERTICAL_ANCHOR   = { UP = "BOTTOM", DOWN = "TOP" }

local function ApplyContainerLayout(container, spec)
    local dir = spec.growDirection or "RIGHT"
    local h = HORIZONTAL[dir] or "Right"
    -- growVertical wins when set; a vertical growDirection is the fallback.
    local v = VERTICAL[spec.growVertical or ""] or VERTICAL[dir] or "Down"

    local setGrowth = container.SetFlowLayoutGrowthDirection
        or container.SetAuraLayoutGrowthDirection
    if setGrowth then pcall(setGrowth, container, h, v) end

    -- Row width is a pixel budget, which is exactly how the setting was
    -- already expressed: the old grid wrapped on auras.maxWidth. nil means
    -- unlimited, which is what an unset or zero width should mean.
    local setRow = container.SetFlowLayoutMaximumLineSize
        or container.SetAuraLayoutRowWidth
    if setRow then
        local w = tonumber(spec.rowWidth)
        pcall(setRow, container, (w and w > 0) and w or nil)
    end

    -- Opt-in: callers that want the anchor corner to track growDirection/
    -- growVertical (instead of a fixed corner passed once at Create) supply
    -- anchorHost. Re-run on every layout change so flipping a direction
    -- dropdown live moves the anchor, not just the flow inside it.
    if spec.anchorHost then
        local vAnchor = VERTICAL_ANCHOR[spec.growVertical or ""] or VERTICAL_ANCHOR[dir] or "TOP"
        local hAnchor = HORIZONTAL_ANCHOR[dir] or "LEFT"
        local anchorPoint = vAnchor .. hAnchor
        container:ClearAllPoints()
        container:SetPoint(anchorPoint, spec.anchorHost, anchorPoint,
            spec.anchorOffsetX or 0, spec.anchorOffsetY or 0)
    end
end

-- ---------------------------------------------------------------------
-- Container
-- ---------------------------------------------------------------------

-- Adds a container's aura groups from its spec. The single place that does
-- it, so Create and Relayout cannot drift: a button-shaping option added to
-- one of them and forgotten in the other is precisely how the tooltip and
-- duration settings would be lost on the first size change.
local function AddGroups(container, spec)
    -- "Both polarities" is two groups, and each one honours maxFrameCount
    -- on its own: giving both the full budget would let a container set to
    -- 8 draw 16. The budget is split, with the odd icon going to the
    -- polarity the caller asked for first.
    local total = spec.max or 5
    local primary, secondary = total, 0
    if spec.both then
        secondary = math.floor(total / 2)
        primary = total - secondary
    end

    local init = MakeInitializer({
        size = spec.size, font = spec.font, border = spec.border,
        showDuration = spec.showDuration, tooltips = spec.tooltips,
        durationPoint = spec.durationPoint, durationRelPoint = spec.durationRelPoint,
        durationX = spec.durationX, durationY = spec.durationY,
        durationColor = spec.durationColor,
        dispelBorder = spec.dispelBorder, dispelColorMap = spec.dispelColorMap,
    })
    local layout = {
        elementWidth  = spec.size,
        elementHeight = spec.size - 4,
        spacingX      = spec.spacing or 2,
        spacingY      = spec.spacing or 2,
    }

    -- includeSpellIDs narrows a group to a known set. That is how the HoT
    -- rows keep working: they matched auraData.spellId against a table, and
    -- spellId is exactly what the client now withholds.
    local candidates = spec.includeSpellIDs
        and { includeSpellIDs = spec.includeSpellIDs } or nil

    if not pcall(container.AddAuraGroup, container, spec.key, spec.filter, {
        maxFrameCount    = primary,
        initializeFrame  = init,
        layout           = layout,
        candidateFilters = candidates,
    }) then
        return false
    end

    -- "Both polarities" is two groups on one container, not one filter
    -- string: a group carries exactly one filter. The engine batches the
    -- two scans and lays both groups out in the same container.
    if spec.both and secondary > 0 then
        pcall(container.AddAuraGroup, container, spec.key .. "_helpful",
            AC.Filter("HELPFUL", spec.onlyMine and "PLAYER" or nil), {
                maxFrameCount    = secondary,
                initializeFrame  = init,
                layout           = layout,
                candidateFilters = candidates,
            })
    end
    return true
end

-- Builds the aura container for one host frame. Returns it, or nil when the
-- engine is unavailable or refused.
--
-- opts: unit, size, max, font, onlyMine, border, point, both, tooltips,
--       showDuration
function AC.Create(parent, opts)
    if not AC.IsAvailable() then return nil end
    if not parent or not opts then return nil end

    local ok, container = pcall(CreateFrame, "AuraContainer", nil, parent,
        "CustomAuraContainerTemplate")
    if not ok or not container then return nil end

    -- A renderable rect from the first dirty mark: the engine drains its
    -- layout from an OnUpdate and needs somewhere to draw. It replaces the
    -- size on every layout pass.
    if opts.point then container:SetPoint(unpack(opts.point)) end
    container:SetSize(1, 1)

    -- Exact strings matter: the engine batches one scan per distinct
    -- filter, so "HARMFUL|PLAYER" and "PLAYER|HARMFUL" would scan twice.
    -- AC.Filter is the one place that builds them, so every caller in the
    -- suite produces byte-identical strings for the same request.
    local filter = opts.filter or AC.Filter(opts.harmful ~= false and "HARMFUL" or "HELPFUL",
        opts.onlyMine and "PLAYER" or nil)
    local size = opts.size or 24

    -- Everything that shapes a button belongs here. AddGroups is the only
    -- builder, and Relayout replays this spec: an option that stops at
    -- Create is an option that silently reverts on the first size change.
    local spec = {
        key = opts.key or "auras", filter = filter, size = size,
        max = opts.max or 5, font = opts.font, border = opts.border,
        showDuration = opts.showDuration, tooltips = opts.tooltips,
        onlyMine = opts.onlyMine, both = opts.both,
        durationPoint = opts.durationPoint, durationRelPoint = opts.durationRelPoint,
        durationX = opts.durationX, durationY = opts.durationY,
        durationColor = opts.durationColor,
        dispelBorder = opts.dispelBorder, dispelColorMap = opts.dispelColorMap,
        includeSpellIDs = opts.includeSpellIDs,
        growDirection = opts.growDirection, growVertical = opts.growVertical,
        rowWidth = opts.rowWidth,
        spacing = opts.spacing,
        anchorHost = opts.anchorHost,
        anchorOffsetX = opts.anchorOffsetX, anchorOffsetY = opts.anchorOffsetY,
    }

    if not AddGroups(container, spec) then
        container:Hide()
        container:SetParent(nil)
        return nil
    end

    -- Unit LAST: assigning it re-evaluates the engine's event
    -- registrations, and those are gated on the container having groups.
    containerSpec[container] = spec
    ApplyContainerLayout(container, spec)

    pcall(container.SetUnit, container, opts.unit)
    pcall(container.UpdateAllAuras, container)

    return container
end

-- Applies a new size, count, or flow layout (direction/rowWidth).
--
-- The engine owns button geometry: it sizes and anchors its own buttons
-- from the group layout, so there is nothing to reach into. Rebuilding
-- the group is the sanctioned way to change size or count, and that part
-- is only ever triggered by a settings change.
--
-- growDirection/growVertical/rowWidth do NOT need a group rebuild --
-- ApplyContainerLayout re-asserts them on the existing groups. Gating that
-- call behind "size or max changed" (the original shape of this function)
-- is exactly why the direction/row-count dropdowns did nothing until the
-- next full container rebuild: a caller passing only a new growDirection
-- hit the early return before ApplyContainerLayout ever ran.
--
-- Returns true when the container was updated. Be aware that no caller acts
-- on false today: UpdateSize ignores it, so a refused relayout leaves the
-- container drawing at its previous size until the next settings change.
-- Acting on it would mean a rebuild path -- recreate the container, re-anchor
-- it, reassign the unit -- which does not exist yet.
function AC.Relayout(container, opts)
    if not container or not opts then return false end
    local data = containerSpec[container]
    if not data then return false end

    local size = opts.size or data.size
    local max  = opts.max  or data.max
    local growDirection = (opts.growDirection ~= nil) and opts.growDirection or data.growDirection
    local growVertical  = (opts.growVertical  ~= nil) and opts.growVertical  or data.growVertical
    local rowWidth       = (opts.rowWidth ~= nil) and opts.rowWidth or data.rowWidth

    local sizeChanged   = (size ~= data.size or max ~= data.max)
    local layoutChanged = (growDirection ~= data.growDirection
        or growVertical ~= data.growVertical or rowWidth ~= data.rowWidth)
    if not sizeChanged and not layoutChanged then return true end

    data.size, data.max = size, max
    data.growDirection, data.growVertical, data.rowWidth = growDirection, growVertical, rowWidth

    if sizeChanged then
        -- RemoveAuraGroup then AddAuraGroup: there is no setter for either
        -- value, and a stale group would keep drawing at the old size. Both
        -- groups go when the container carries both polarities -- dropping
        -- only the primary would leave the helpful half at the old size.
        if container.RemoveAuraGroup then
            pcall(container.RemoveAuraGroup, container, data.key)
            if data.both then
                pcall(container.RemoveAuraGroup, container, data.key .. "_helpful")
            end
        end
        if not AddGroups(container, data) then return false end
    end

    ApplyContainerLayout(container, data)
    pcall(container.UpdateAllAuras, container)
    return true
end

-- ---------------------------------------------------------------------
-- Aura probe
--
-- Cooldown Studio cannot use a container to draw its bar: it orders
-- cooldowns and auras in one row, which the engine has no notion of. What
-- it needs is narrower -- "is this buff up, and how long is left" -- and
-- that is exactly what it may no longer read.
--
-- A probe is a container with no visible buttons whose single slot is
-- restricted to the tracked spell. The engine fills it, and it drives a
-- Cooldown widget the CALLER owns: the swipe lands on the studio's own
-- icon without anything reading an aura.
--
-- Presence comes from asking the button whether it is shown, which is a
-- frame query and not an aura read.
-- ---------------------------------------------------------------------

-- Builds a probe. `cooldown` is the caller's Cooldown frame, driven by the
-- engine. Returns the probe, or nil when it could not be built.
function AC.CreateAuraProbe(parent, spellIDs, cooldown)
    if not parent or type(spellIDs) ~= "table" or not next(spellIDs) then return nil end
    if not AC.IsAvailable() then return nil end

    local ok, container = pcall(CreateFrame, "AuraContainer", nil, parent,
        "CustomAuraContainerTemplate")
    if not ok or not container then return nil end

    container:SetSize(1, 1)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    container:SetAlpha(0)

    -- The caller's cooldown is kept: it is the readable side of the same
    -- question. The engine drives it, and unlike the engine's own button
    -- it belongs to us, so its shown state is not withheld.
    local probe = { container = container, cooldown = cooldown }

    local okGroup = pcall(container.AddAuraGroup, container, "probe",
        AC.Filter("HELPFUL"), {
            maxFrameCount    = 1,
            candidateFilters = { includeSpellIDs = spellIDs },
            initializeFrame  = function(button)
                probe.button = button
                -- Invisible and inert: the button exists to be driven, not
                -- to be seen. Sizing it still matters -- an unsized button
                -- is never laid out, so it would never be shown either, and
                -- ProbeActive reads exactly that.
                --
                -- Which is why it goes through the same retry as every other
                -- button rather than a bare SetSize: sizing is refused while
                -- auras are restricted, and a probe that cannot be sized then
                -- is a probe that answers "not up" during the only stretch it
                -- was built for.
                buttonData[button] = { wantSize = 1, wantHeight = 1 }
                pending[button] = true
                AC.TrySize(button)
                pcall(button.SetAlpha, button, 0)
                pcall(button.SetMouseClickEnabled, button, false)
                pcall(button.SetMouseMotionEnabled, button, false)
                -- The caller's cooldown, driven by the engine. This is the
                -- whole point: the swipe is correct in combat because
                -- nothing here read the aura to produce it.
                if cooldown then
                    pcall(button.SetDurationCooldown, button, cooldown)
                end
            end,
            layout = { elementWidth = 1, elementHeight = 1 },
        })
    if not okGroup then
        container:Hide()
        container:SetParent(nil)
        return nil
    end

    pcall(container.SetUnit, container, "player")
    pcall(container.UpdateAllAuras, container)
    return probe
end

-- Discards a probe. Two probes on one icon would both drive its cooldown.
function AC.DestroyAuraProbe(probe)
    if not probe or not probe.container then return end
    if probe.button then
        pcall(probe.button.SetDurationCooldown, probe.button, nil)
        pending[probe.button] = nil
        buttonData[probe.button] = nil
    end
    pcall(probe.container.SetUnit, probe.container, nil)
    probe.container:Hide()
    probe.container:SetParent(nil)
    probe.button = nil
end

-- True when the tracked aura is up.
--
-- NOT a plain frame query, which is what this used to assume: IsShown on an
-- ENGINE button is a secret boolean, because whether an aura button is
-- displayed is exactly the aura presence the client is withholding. Testing
-- it threw on the first probed icon.
--
-- The caller's own Cooldown answers the same question and is ours: the
-- engine puts a swipe on it while the aura is up and takes it away when it
-- ends. The engine button stays as a fallback, now guarded.
--
-- When neither side can be read the answer is false, which costs nothing:
-- the probe simply contributes no presence that frame and goes on driving
-- the swipe, which is its other and larger job.
function AC.ProbeActive(probe)
    -- The retry sweep is hooked to SetUnit, which probes never call: they sit
    -- on "player" for life. Asking here is the sweep's only guaranteed
    -- trigger in a session with no frames on screen, and it costs a next()
    -- on an empty table once everything is sized.
    AC.ResizePending()
    if not probe then return false end

    local U = TomoMod_Utils
    local function readable(frame)
        if not frame or not frame.IsShown then return nil end
        local ok, shown = pcall(frame.IsShown, frame)
        if not ok then return nil end
        -- The guard has to run BEFORE the boolean test, not after: testing
        -- a secret is the operation that throws.
        if U and U.IsSecret and U.IsSecret(shown) then return nil end
        return shown and true or false
    end

    local mine = readable(probe.cooldown)
    if mine ~= nil then return mine end

    local theirs = readable(probe.button)
    if theirs ~= nil then return theirs end

    return false
end

-- ---------------------------------------------------------------------
-- Typed debuff indicator (party / raid)
--
-- One AuraSlot per dispel type lets the client answer "is there a Magic /
-- Curse / Disease / Poison / Bleed aura?" without Lua reading aura data.
-- That matters in 12.1: aura fields are secret through most combat, while
-- candidateFilters/includeDispelTypes remains engine-side and combat-safe.
--
-- The slot button itself is a 1x1 parked anchor. Its children draw:
--   * the REAL aura icon (SetIcon, driven by the client),
--   * a cooldown swipe + stack count,
--   * an outward full-frame border pre-coloured for that slot's type.
-- When the engine hides the slot, all of those children hide with it.
-- ---------------------------------------------------------------------
local dispelIndicatorData = setmetatable({}, { __mode = "k" })

local DISPEL_ALERT_SLOTS = {
    { key = "Magic",   level = 5 },
    { key = "Curse",   level = 4 },
    { key = "Disease", level = 3 },
    { key = "Poison",  level = 2 },
    { key = "Bleed",   level = 1 },
}

local DISPEL_ALERT_FALLBACK_COLORS = {
    Magic   = { r = 0.10, g = 0.55, b = 1.00 },
    Curse   = { r = 0.65, g = 0.10, b = 0.95 },
    Disease = { r = 1.00, g = 0.50, b = 0.05 },
    Poison  = { r = 0.55, g = 0.90, b = 0.05 },
    Bleed   = { r = 1.00, g = 0.05, b = 0.12 },
}

local function GetDispelAlertColor(kind)
    local AD = TomoMod_AuraData
    local c = AD and AD.DEBUFF_TYPE_COLORS and AD.DEBUFF_TYPE_COLORS[kind]
    return c or DISPEL_ALERT_FALLBACK_COLORS[kind] or { r = 1, g = 1, b = 1 }
end

local function ApplyDispelAlertVisual(record, kind, d)
    if not record or not d then return end

    local iconSize = math.max(8, tonumber(record.iconSize) or 20)
    local borderSize = math.max(1, math.floor((tonumber(record.borderSize) or 2) + 0.5))
    local typeEnabled = (kind ~= "Bleed") or record.showBleed
    local showIcon = typeEnabled and record.showIcon
    local showBorder = typeEnabled and record.showBorder
    local c = GetDispelAlertColor(kind)
    local borderAlpha = showBorder and 1 or 0

    d.icon:SetSize(iconSize, iconSize)
    d.icon:SetAlpha(showIcon and 1 or 0)
    d.cooldown:SetAlpha(showIcon and 1 or 0)
    d.count:SetAlpha(showIcon and 1 or 0)
    d.count:SetFont(record.font or STANDARD_TEXT_FONT,
        math.max(8, math.floor(iconSize * 0.42)), "OUTLINE")

    -- Four simple textures, all children of the engine AuraButton. They grow
    -- OUTSIDE the unit frame, so the health bar itself is never recoloured
    -- or resized. Textures remain addon-owned and safe to restyle in combat.
    d.edgeTop:ClearAllPoints()
    d.edgeTop:SetPoint("TOPLEFT", record.parent, "TOPLEFT", -borderSize, borderSize)
    d.edgeTop:SetPoint("TOPRIGHT", record.parent, "TOPRIGHT", borderSize, borderSize)
    d.edgeTop:SetHeight(borderSize)

    d.edgeBottom:ClearAllPoints()
    d.edgeBottom:SetPoint("BOTTOMLEFT", record.parent, "BOTTOMLEFT", -borderSize, -borderSize)
    d.edgeBottom:SetPoint("BOTTOMRIGHT", record.parent, "BOTTOMRIGHT", borderSize, -borderSize)
    d.edgeBottom:SetHeight(borderSize)

    d.edgeLeft:ClearAllPoints()
    d.edgeLeft:SetPoint("TOPLEFT", record.parent, "TOPLEFT", -borderSize, borderSize)
    d.edgeLeft:SetPoint("BOTTOMLEFT", record.parent, "BOTTOMLEFT", -borderSize, -borderSize)
    d.edgeLeft:SetWidth(borderSize)

    d.edgeRight:ClearAllPoints()
    d.edgeRight:SetPoint("TOPRIGHT", record.parent, "TOPRIGHT", borderSize, borderSize)
    d.edgeRight:SetPoint("BOTTOMRIGHT", record.parent, "BOTTOMRIGHT", borderSize, -borderSize)
    d.edgeRight:SetWidth(borderSize)

    d.edgeTop:SetColorTexture(c.r, c.g, c.b, borderAlpha)
    d.edgeBottom:SetColorTexture(c.r, c.g, c.b, borderAlpha)
    d.edgeLeft:SetColorTexture(c.r, c.g, c.b, borderAlpha)
    d.edgeRight:SetColorTexture(c.r, c.g, c.b, borderAlpha)
end

local function MakeDispelAlertInitializer(record, slot)
    return function(button)
        local d = { wantSize = 1, wantHeight = 1 }
        buttonData[button] = d
        pending[button] = true
        AC.TrySize(button)

        pcall(button.SetMouseClickEnabled, button, false)
        pcall(button.SetMouseMotionEnabled, button, false)

        -- AuraSlots are not auto-anchored. Do this inside initializeFrame:
        -- touching an engine-owned AuraButton later can be forbidden while
        -- auras are secret.
        pcall(button.SetPoint, button, "CENTER", record.parent, "CENTER", 0, 0)
        pcall(button.SetFrameLevel, button,
            record.parent:GetFrameLevel() + (slot.level or 1))

        d.icon = button:CreateTexture(nil, "ARTWORK", nil, 4)
        d.icon:SetPoint(record.iconPoint or "TOPRIGHT", record.parent,
            record.iconRelPoint or "TOPRIGHT", record.iconX or -2, record.iconY or -2)
        d.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        d.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        d.cooldown:SetAllPoints(d.icon)
        d.cooldown:SetDrawEdge(false)
        d.cooldown:SetReverse(true)
        d.cooldown:SetHideCountdownNumbers(true)
        d.cooldown:SetSwipeColor(0, 0, 0, 0.62)
        d.cooldown:EnableMouse(false)

        d.count = button:CreateFontString(nil, "OVERLAY")
        d.count:SetPoint("BOTTOMRIGHT", d.icon, "BOTTOMRIGHT", 1, 1)
        d.count:SetJustifyH("RIGHT")

        d.edgeTop = button:CreateTexture(nil, "OVERLAY", nil, 7)
        d.edgeBottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
        d.edgeLeft = button:CreateTexture(nil, "OVERLAY", nil, 7)
        d.edgeRight = button:CreateTexture(nil, "OVERLAY", nil, 7)

        record.slots[slot.key] = d
        ApplyDispelAlertVisual(record, slot.key, d)

        -- Registration last: these setters immediately let the aura engine
        -- drive our regions, so every region must already be fully styled.
        if button.SetIcon then
            pcall(button.SetIcon, button, d.icon)
        end
        if button.SetDurationCooldown then
            pcall(button.SetDurationCooldown, button, d.cooldown)
        end
        if button.SetApplicationCount then
            pcall(button.SetApplicationCount, button, d.count, {})
        end
    end
end

function AC.CreateDispelIndicator(parent, opts)
    if not AC.IsAvailable() then return nil end
    if not parent or not opts then return nil end

    local ok, container = pcall(CreateFrame, "AuraContainer", nil, parent,
        "CustomAuraContainerTemplate")
    if not ok or not container or not container.AddAuraSlot then return nil end

    container:SetSize(1, 1)
    container:SetPoint("CENTER", parent, "CENTER", 0, 0)

    local record = {
        parent = parent,
        slots = {},
        iconSize = opts.iconSize or 20,
        borderSize = opts.borderSize or 2,
        showIcon = opts.showIcon ~= false,
        showBorder = opts.showBorder ~= false,
        showBleed = opts.showBleed ~= false,
        font = opts.font or STANDARD_TEXT_FONT,
        iconPoint = opts.iconPoint or "TOPRIGHT",
        iconRelPoint = opts.iconRelPoint or "TOPRIGHT",
        iconX = opts.iconX or -2,
        iconY = opts.iconY or -2,
    }
    dispelIndicatorData[container] = record

    local filter = AC.Filter("HARMFUL", "!CROWD_CONTROL")
    local added = 0
    for i = 1, #DISPEL_ALERT_SLOTS do
        local slot = DISPEL_ALERT_SLOTS[i]
        local okSlot = pcall(container.AddAuraSlot, container,
            "tomomod_debuff_" .. slot.key:lower(), filter, {
                candidateFilters = {
                    includeDispelTypes = { [slot.key] = true },
                },
                initializeFrame = MakeDispelAlertInitializer(record, slot),
            })
        if okSlot then added = added + 1 end
    end

    if added == 0 then
        dispelIndicatorData[container] = nil
        container:Hide()
        container:SetParent(nil)
        return nil
    end

    pcall(container.SetUnit, container, opts.unit)
    pcall(container.UpdateAllAuras, container)
    return container
end

-- Visual options are addon-owned regions, so these can update live without
-- rebuilding slots or reading any aura. The slot filters stay fixed forever.
function AC.UpdateDispelIndicator(container, opts)
    local record = dispelIndicatorData[container]
    if not record or not opts then return false end

    if opts.iconSize ~= nil then record.iconSize = opts.iconSize end
    if opts.borderSize ~= nil then record.borderSize = opts.borderSize end
    if opts.showIcon ~= nil then record.showIcon = opts.showIcon == true end
    if opts.showBorder ~= nil then record.showBorder = opts.showBorder == true end
    if opts.showBleed ~= nil then record.showBleed = opts.showBleed == true end
    if opts.font then record.font = opts.font end

    for kind, d in pairs(record.slots) do
        ApplyDispelAlertVisual(record, kind, d)
    end
    return true
end

-- The unit behind a plate changes as plates are recycled.
function AC.SetUnit(container, unit)
    if not container or not container.SetUnit then return false end
    local ok = pcall(container.SetUnit, container, unit)
    if ok then pcall(container.UpdateAllAuras, container) end
    -- Every plate calls this on update, so it is the cheapest hook for the
    -- retry: a `next()` on an empty table when nothing is pending.
    AC.ResizePending()
    return ok
end
