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

-- The old name, for anything not yet moved over.
TomoMod_NPAuraContainer = AC

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
local filterCache = {}

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

    local key = base
    for i = 1, #rest do key = key .. "|" .. rest[i] end

    local cached = filterCache[key]
    if cached then return cached end
    filterCache[key] = key
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

local function MakeInitializer(opts)
    return function(button)
        local d = {}
        buttonData[button] = d

        local size = opts.size or 24
        -- The engine anchors buttons but never sizes them: an unsized
        -- button renders nothing at all.
        --
        -- KNOWN GAP, and the one to watch when testing this: SetSize on an
        -- aura button is refused while auras are restricted, which is exactly
        -- the situation this whole file exists for. A button first initialised
        -- during a restricted stretch therefore comes out with no size and
        -- draws nothing, and there is no retry yet -- d.sizedTo and
        -- buttonData above are written for one and nothing reads them.
        -- Whether this bites depends on whether the engine runs
        -- initializeFrame once per pooled button or again on reuse, which
        -- needs checking in game before a retry is worth writing.
        local okSize = pcall(button.SetSize, button, size, size - 4)
        if okSize then d.sizedTo = size end

        pcall(button.SetMouseClickEnabled, button, false)

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
        d.cooldown:SetHideCountdownNumbers(true)
        d.cooldown:EnableMouse(false)

        d.count = button:CreateFontString(nil, "OVERLAY")
        d.count:SetFont(opts.font, 9, "OUTLINE")
        d.count:SetPoint("BOTTOMRIGHT", 1, 1)
        d.count:SetJustifyH("RIGHT")

        d.duration = button:CreateFontString(nil, "OVERLAY")
        d.duration:SetFont(opts.font, 9, "OUTLINE")
        d.duration:SetPoint("TOPLEFT", button, "TOPLEFT", -3, 4)
        d.duration:SetJustifyH("LEFT")
        d.duration:SetTextColor(1, 1, 0, 1)

        if opts.border then opts.border(button) end

        -- Registration last, and each one guarded: these are the calls the
        -- client refuses while auras are restricted, and one refusal must
        -- not stop the others from binding.
        pcall(button.SetIcon, button, d.icon)
        pcall(button.SetDurationCooldown, button, d.cooldown)
        pcall(button.SetApplicationCount, button, d.count, {})
        if button.SetDurationText then
            pcall(button.SetDurationText, button, d.duration, {})
        end
    end
end

-- ---------------------------------------------------------------------
-- Container
-- ---------------------------------------------------------------------

-- Builds the debuff container for one plate. Returns it, or nil when the
-- engine is unavailable or refused.
--
-- opts: unit, size, max, font, onlyMine, border, point
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

    local okGroup = pcall(container.AddAuraGroup, container, opts.key or "auras", filter, {
        maxFrameCount   = opts.max or 5,
        initializeFrame = MakeInitializer({
            size = size, font = opts.font, border = opts.border,
        }),
        layout = {
            elementWidth  = size,
            elementHeight = size - 4,
            spacingX      = 2,
        },
    })
    if not okGroup then
        container:Hide()
        container:SetParent(nil)
        return nil
    end

    -- Unit LAST: assigning it re-evaluates the engine's event
    -- registrations, and those are gated on the container having groups.
    containerSpec[container] = {
        key = opts.key or "auras", filter = filter, size = size,
        max = opts.max or 5, font = opts.font, border = opts.border,
    }

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
    -- value, and a stale group would keep drawing at the old size.
    if container.RemoveAuraGroup then
        pcall(container.RemoveAuraGroup, container, data.key)
    end
    local ok = pcall(container.AddAuraGroup, container, data.key, data.filter, {
        maxFrameCount   = max,
        initializeFrame = MakeInitializer({
            size = size, font = data.font, border = data.border,
        }),
        layout = {
            elementWidth  = size,
            elementHeight = size - 4,
            spacingX      = 2,
        },
    })
    if ok then pcall(container.UpdateAllAuras, container) end
    return ok
end

-- The unit behind a plate changes as plates are recycled.
function AC.SetUnit(container, unit)
    if not container or not container.SetUnit then return false end
    local ok = pcall(container.SetUnit, container, unit)
    if ok then pcall(container.UpdateAllAuras, container) end
    return ok
end
