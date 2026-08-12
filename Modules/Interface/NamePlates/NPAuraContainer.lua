-- ---------------------------------------------------------------------
-- NPAuraContainer.lua -- nameplate debuffs through the 12.1 aura engine
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
-- This is the pilot: nameplate debuffs only. The legacy path stays and
-- still runs on clients without the template, so nobody loses their auras
-- to a version check.
-- ---------------------------------------------------------------------

local NPAC = {}
TomoMod_NPAuraContainer = NPAC

-- Per-button regions, keyed by button. The engine owns the buttons and
-- recycles them, so anything of ours has to hang off a side table rather
-- than off fields it might reuse.
local buttonData = setmetatable({}, { __mode = "k" })

-- ---------------------------------------------------------------------
-- Availability
-- ---------------------------------------------------------------------

local _available   -- nil = not yet probed

-- True when this client has the aura container engine.
--
-- Probed by creating one and throwing it away: the frame type and the
-- template have to both exist, and asking the API version would not tell
-- us whether the template is registered.
function NPAC.IsAvailable()
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
        -- KNOWN GAP, and the one to watch when testing this pilot: SetSize
        -- on an aura button is refused while auras are restricted, which is
        -- exactly the situation this whole file exists for. A button first
        -- initialised during a restricted stretch therefore comes out with
        -- no size and draws nothing, and there is no retry yet -- d.sizedTo
        -- and buttonData below are written for one and nothing reads them.
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
function NPAC.Create(parent, opts)
    if not NPAC.IsAvailable() then return nil end
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
    local filter = opts.onlyMine and "HARMFUL|PLAYER" or "HARMFUL"
    local size = opts.size or 24

    local okGroup = pcall(container.AddAuraGroup, container, "debuffs", filter, {
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
    pcall(container.SetUnit, container, opts.unit)
    pcall(container.UpdateAllAuras, container)

    return container
end

-- The unit behind a plate changes as plates are recycled.
function NPAC.SetUnit(container, unit)
    if not container or not container.SetUnit then return false end
    local ok = pcall(container.SetUnit, container, unit)
    if ok then pcall(container.UpdateAllAuras, container) end
    return ok
end
