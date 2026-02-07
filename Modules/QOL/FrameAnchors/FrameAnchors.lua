-- =====================================
-- FrameAnchors.lua — Movable anchors for AlertFrame & LootFrame
-- Invisible in normal play, blue border when unlocked via /tm sr
-- =====================================

TomoMod_FrameAnchors = {}
local FA = TomoMod_FrameAnchors
local L = TomoMod_L

local isLocked = true
local anchors = {}

local ANCHOR_DEFS = {
    {
        key = "alertFrame",
        label = L["anchor_alert"],
        width = 200,
        height = 40,
        defaultPoint = { "TOP", "TOP", 0, -18 },
        target = function() return AlertFrame end,
        targetPoint = "TOP",
        anchorPoint = "TOP",
    },
    {
        key = "lootFrame",
        label = L["anchor_loot"],
        width = 180,
        height = 40,
        defaultPoint = { "TOPLEFT", "TOPLEFT", 36, -186 },
        target = function() return LootFrame end,
        targetPoint = "TOPLEFT",
        anchorPoint = "TOPLEFT",
    },
}

-- =====================================
-- DB ACCESS
-- =====================================

local function DB()
    return TomoModDB and TomoModDB.frameAnchors
end

-- =====================================
-- CREATE ANCHOR FRAME
-- =====================================

local function CreateAnchor(def)
    local anchor = CreateFrame("Frame", "TomoModAnchor_" .. def.key, UIParent, "BackdropTemplate")
    anchor:SetSize(def.width, def.height)
    anchor:SetFrameStrata("HIGH")
    anchor:SetFrameLevel(200)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:EnableMouse(false) -- invisible by default, no mouse
    anchor:SetAlpha(0)

    -- Blue border (visible only when unlocked)
    anchor:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    anchor:SetBackdropColor(0.1, 0.15, 0.3, 0.6)
    anchor:SetBackdropBorderColor(0.3, 0.5, 1.0, 1)

    -- Label
    local label = anchor:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetTextColor(0.5, 0.7, 1.0, 1)
    label:SetText(def.label)
    anchor.label = label

    -- Drag handling
    anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function(self)
        if not isLocked then
            self:StartMoving()
        end
    end)
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local db = DB()
        if db and db[def.key] then
            local point, _, relPoint, x, y = self:GetPoint()
            db[def.key].position = { point, relPoint, x, y }
        end
        -- Re-anchor the target frame
        FA.ApplyAnchor(def)
    end)

    -- Position from DB or default
    anchor:ClearAllPoints()
    local db = DB()
    local saved = db and db[def.key] and db[def.key].position
    if saved then
        anchor:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
    else
        local d = def.defaultPoint
        anchor:SetPoint(d[1], UIParent, d[2], d[3], d[4])
    end

    anchor:Show()
    anchor.def = def
    return anchor
end

-- =====================================
-- APPLY ANCHOR TO TARGET FRAME
-- =====================================

function FA.ApplyAnchor(def)
    local target = def.target()
    if not target then return end

    local anchor = anchors[def.key]
    if not anchor then return end

    target:ClearAllPoints()
    target:SetPoint(def.targetPoint, anchor, def.anchorPoint, 0, 0)
end

-- =====================================
-- LOCK / UNLOCK
-- =====================================

local function SetLocked(locked)
    isLocked = locked

    for _, anchor in pairs(anchors) do
        if locked then
            anchor:SetAlpha(0)
            anchor:EnableMouse(false)
        else
            anchor:SetAlpha(1)
            anchor:EnableMouse(true)
        end
    end
end

function FA.ToggleLock()
    SetLocked(not isLocked)
    if isLocked then
        print("|cff0cd29fTomoMod Anchors:|r " .. L["msg_anchors_locked"])
    else
        print("|cff0cd29fTomoMod Anchors:|r " .. L["msg_anchors_unlocked"])
    end
end

function FA.IsLocked()
    return isLocked
end

-- =====================================
-- HOOK TARGET FRAMES
-- =====================================

local hookedFrames = {}

local function HookTargetFrame(def)
    local target = def.target()
    if not target or hookedFrames[def.key] then return end

    -- Apply initial position
    FA.ApplyAnchor(def)

    -- Hook SetPoint to force our position (Blizzard may try to reposition)
    hooksecurefunc(target, "SetPoint", function()
        -- Only override if we're not in the middle of our own SetPoint
        if not anchors[def.key] or not anchors[def.key]._applying then
            C_Timer.After(0, function()
                local anchor = anchors[def.key]
                if anchor then
                    anchor._applying = true
                    FA.ApplyAnchor(def)
                    anchor._applying = nil
                end
            end)
        end
    end)

    hookedFrames[def.key] = true
end

-- =====================================
-- INITIALIZE
-- =====================================

function FA.Initialize()
    local db = DB()
    if not db or not db.enabled then return end

    -- Create anchors
    for _, def in ipairs(ANCHOR_DEFS) do
        anchors[def.key] = CreateAnchor(def)
    end

    -- Hook targets after a short delay (frames may not exist yet)
    C_Timer.After(2, function()
        for _, def in ipairs(ANCHOR_DEFS) do
            HookTargetFrame(def)
        end
    end)

    -- Start locked
    SetLocked(true)
end
