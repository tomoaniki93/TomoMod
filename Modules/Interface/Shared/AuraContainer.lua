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
    table.sort(rest)

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
    local ok = pcall(button.SetSize, button, size, size - 4)
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
-- Container
-- ---------------------------------------------------------------------

-- Adds a container's aura groups from its spec. The single place that does
-- it, so Create and Relayout cannot drift: a button-shaping option added to
-- one of them and forgotten in the other is precisely how the tooltip and
-- duration settings would be lost on the first size change.
local function AddGroups(container, spec)
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
        spacingX      = 2,
    }

    -- includeSpellIDs narrows a group to a known set. That is how the HoT
    -- rows keep working: they matched auraData.spellId against a table, and
    -- spellId is exactly what the client now withholds.
    local candidates = spec.includeSpellIDs
        and { includeSpellIDs = spec.includeSpellIDs } or nil

    if not pcall(container.AddAuraGroup, container, spec.key, spec.filter, {
        maxFrameCount    = spec.max,
        initializeFrame  = init,
        layout           = layout,
        candidateFilters = candidates,
    }) then
        return false
    end

    -- "Both polarities" is two groups on one container, not one filter
    -- string: a group carries exactly one filter. The engine batches the
    -- two scans and lays both groups out in the same container.
    if spec.both then
        pcall(container.AddAuraGroup, container, spec.key .. "_helpful",
            AC.Filter("HELPFUL", spec.onlyMine and "PLAYER" or nil), {
                maxFrameCount    = spec.max,
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
    }

    if not AddGroups(container, spec) then
        container:Hide()
        container:SetParent(nil)
        return nil
    end

    -- Unit LAST: assigning it re-evaluates the engine's event
    -- registrations, and those are gated on the container having groups.
    containerSpec[container] = spec

    pcall(container.SetUnit, container, opts.unit)
    pcall(container.UpdateAllAuras, container)

    return container
end

-- Applies a new size or count.
--
-- The engine owns button geometry: it sizes and anchors its own buttons
-- from the group layout, so there is nothing to reach into. Rebuilding
-- the group is the sanctioned way to change either, and it is only ever
-- triggered by a settings change.
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
    if size == data.size and max == data.max then return true end

    data.size, data.max = size, max

    -- RemoveAuraGroup then AddAuraGroup: there is no setter for either
    -- value, and a stale group would keep drawing at the old size. Both
    -- groups go when the container carries both polarities -- dropping only
    -- the primary would leave the helpful half at the old size for good.
    if container.RemoveAuraGroup then
        pcall(container.RemoveAuraGroup, container, data.key)
        if data.both then
            pcall(container.RemoveAuraGroup, container, data.key .. "_helpful")
        end
    end
    local ok = AddGroups(container, data)
    if ok then pcall(container.UpdateAllAuras, container) end
    return ok
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
