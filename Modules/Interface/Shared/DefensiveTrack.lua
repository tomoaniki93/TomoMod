-- =====================================
-- Interface/Shared/DefensiveTrack.lua — defensive cooldown icons
--
-- Raid frames used to show a single defensive buff with no duration and no
-- category, party frames showed nothing at all. Both now use this track:
-- N icons, border coloured by category (external / raid-wide / personal),
-- remaining time in the corner, sorted so externals come first.
--
-- Creation and update live here; each consumer only supplies its own anchor
-- and its slice of the database.
-- =====================================

TomoMod_DefensiveTrack = TomoMod_DefensiveTrack or {}
local DT = TomoMod_DefensiveTrack

local ipairs, math_max = ipairs, math.max

local BORDER_FILE = "Interface\\Buttons\\WHITE8X8"

-- =====================================
-- CREATE
-- parent   : the frame the icons hang off
-- opts     : { size, count, point, relPoint, x, y, grow, font, fontSize }
--            grow is "LEFT" or "RIGHT" (defaults to "LEFT")
-- =====================================
function DT.Create(parent, opts)
    if not parent or not opts then return nil end

    local size  = opts.size or 16
    local count = opts.count or 2
    if count < 1 then count = 1 end
    local grow  = opts.grow or "LEFT"

    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint(opts.point or "TOPRIGHT", parent,
                       opts.relPoint or opts.point or "TOPRIGHT",
                       opts.x or -1, opts.y or -1)
    container:SetSize(size * count + (count - 1), size)
    container.icons = {}

    for i = 1, count do
        local icon = CreateFrame("Frame", nil, container, "BackdropTemplate")
        icon:SetSize(size, size)
        if grow == "RIGHT" then
            icon:SetPoint("LEFT", container, "LEFT", (i - 1) * (size + 1), 0)
        else
            icon:SetPoint("RIGHT", container, "RIGHT", -(i - 1) * (size + 1), 0)
        end
        icon:SetBackdrop({ edgeFile = BORDER_FILE, edgeSize = 1 })
        icon:SetBackdropBorderColor(0, 0, 0, 1)

        local tex = icon:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", 1, -1)
        tex:SetPoint("BOTTOMRIGHT", -1, 1)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon.texture = tex

        local dur = icon:CreateFontString(nil, "OVERLAY")
        if opts.font then
            dur:SetFont(opts.font, opts.fontSize or math_max(7, size - 8), "OUTLINE")
        end
        dur:SetPoint("CENTER", 0, 0)
        icon.duration = dur

        icon:Hide()
        container.icons[i] = icon
    end

    return container
end

-- =====================================
-- RESIZE (settings applied without a full frame rebuild)
-- =====================================
function DT.Resize(container, size, grow)
    if not container or not container.icons then return end
    if not size or size < 1 then return end
    grow = grow or "LEFT"

    local count = #container.icons
    container:SetSize(size * count + (count - 1), size)

    for i, icon in ipairs(container.icons) do
        icon:SetSize(size, size)
        icon:ClearAllPoints()
        if grow == "RIGHT" then
            icon:SetPoint("LEFT", container, "LEFT", (i - 1) * (size + 1), 0)
        else
            icon:SetPoint("RIGHT", container, "RIGHT", -(i - 1) * (size + 1), 0)
        end
    end
end

-- =====================================
-- HIDE ALL
-- =====================================
function DT.Clear(container)
    if not container or not container.icons then return end
    for _, icon in ipairs(container.icons) do icon:Hide() end
end

-- =====================================
-- UPDATE
-- unit    : unit token
-- want    : caller-owned { external, raidwide, personal } boolean table
-- max     : how many icons the player asked for
-- results : caller-owned scratch table, entries reused between calls
-- =====================================
function DT.Update(container, unit, want, max, results)
    if not container or not container.icons then return end

    local AD = TomoMod_AuraData
    if not AD then DT.Clear(container); return end

    local slots = #container.icons
    if not max or max > slots then max = slots end

    local count = AD.ScanDefensives(unit, want, max, results)

    for i, icon in ipairs(container.icons) do
        local data = (i <= count) and results[i] or nil
        if data then
            icon.texture:SetTexture(data.icon)

            local c = AD.DEFENSIVE_KIND_COLORS[data.kind]
            if c then
                icon:SetBackdropBorderColor(c.r, c.g, c.b, 1)
            else
                icon:SetBackdropBorderColor(0, 0, 0, 1)
            end

            local remaining = AD.RemainingTime(data.duration, data.expTime)
            if remaining then
                if remaining >= 60 then
                    icon.duration:SetText(string.format("%.0fm", remaining / 60))
                else
                    icon.duration:SetText(string.format("%.0f", remaining))
                end
            else
                icon.duration:SetText("")
            end

            icon:Show()
        else
            icon:Hide()
        end
    end
end
