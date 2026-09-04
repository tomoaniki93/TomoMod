-- =====================================
-- FrameAnchors.lua — Movable anchors for AlertFrame & LootFrame
-- Invisible in normal play, blue border when unlocked via /tm sr
-- =====================================

TomoMod_FrameAnchors = TomoMod_FrameAnchors or {}
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
        -- The queue status eye. Blizzard parents it to the minimap cluster and
        -- gives it no Edit Mode entry, so it is the one HUD element a player
        -- cannot place -- which is exactly what gets reported. Minimap.lua
        -- already lists it under the buttons it must not collect, so nothing
        -- else in TomoMod claims it.
        key = "queueStatus",
        label = L["anchor_queue"],
        width = 34,
        height = 34,
        -- Near the minimap, where the eye lives natively. The previous corner
        -- offset was guessed blind and lands somewhere different on every
        -- resolution -- which is how it went missing on an ultrawide.
        defaultPoint = { "TOPRIGHT", "TOPRIGHT", -30, -220 },
        target = function() return QueueStatusButton end,
        targetPoint = "CENTER",
        anchorPoint = "CENTER",
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
    -- Shared Layout Mode appearance. This frame still owns its drag and save
    -- behaviour; the common renderer supplies the gradient, edge and label.
    if TomoMod_Utils and TomoMod_Utils.StyleMoverOverlay then
        TomoMod_Utils.StyleMoverOverlay(anchor, def.label)
    end
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:EnableMouse(false) -- invisible by default, no mouse
    anchor:SetAlpha(0)

    anchor.label = anchor._tmMoverText

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
        -- Create the entry rather than drop the position on the floor: a
        -- defaults table that has fallen behind ANCHOR_DEFS should cost a
        -- table, not a setting the player believes they saved.
        if db and not db[def.key] then db[def.key] = {} end
        if db and db[def.key] then
            -- [DRAG] screen-absolute coords instead of GetPoint
            local left, bottom = self:GetLeft(), self:GetBottom()
            if left and bottom then
                local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
                db[def.key].position = { "BOTTOMLEFT", "BOTTOMLEFT", left * scale, bottom * scale }
            end
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

local pendingAnchors = {}
local combatFrame

--- Re-apply everything that was refused while the player was in combat.
local function FlushPendingAnchors()
    for key, def in pairs(pendingAnchors) do
        pendingAnchors[key] = nil
        FA.ApplyAnchor(def)
    end
end

--- Re-apply one anchor by key. MicroBar calls this after it reparents the
--- Group Finder eye, and again whenever Blizzard re-anchors it, so placement
--- stays in one place instead of two systems fighting over SetPoint.
function FA.ApplyAnchorByKey(key)
    for _, def in ipairs(ANCHOR_DEFS) do
        if def.key == key then
            FA.ApplyAnchor(def)
            return true
        end
    end
    return false
end

function FA.ApplyAnchor(def)
    local target = def.target()
    if not target then return end

    local anchor = anchors[def.key]
    if not anchor then return end

    -- SetPoint on a protected frame is refused in combat. AlertFrame and
    -- LootFrame are not protected so this never bit, but QueueStatusButton
    -- hangs off MinimapCluster, which Edit Mode manages -- and a refused move
    -- would surface as an ADDON_ACTION_BLOCKED attributed to us. Defer instead
    -- of trying and failing.
    if InCombatLockdown() then
        pendingAnchors[def.key] = def
        if not combatFrame then
            combatFrame = CreateFrame("Frame")
            combatFrame:SetScript("OnEvent", FlushPendingAnchors)
        end
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

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
        print("|cff2e9dd8TomoMod Anchors:|r " .. L["msg_anchors_locked"])
    else
        print("|cff2e9dd8TomoMod Anchors:|r " .. L["msg_anchors_unlocked"])
    end
end

function FA.IsLocked()
    return isLocked
end

-- =====================================
-- HOOK TARGET FRAMES
-- =====================================

local hookedFrames = {}

-- [PERF] Pre-built callbacks per anchor key to avoid closure allocation on every SetPoint
local hookCallbacks = {}

local function HookTargetFrame(def)
    local target = def.target()
    if not target or hookedFrames[def.key] then return end

    -- Apply initial position
    FA.ApplyAnchor(def)

    -- Build callback once per key
    if not hookCallbacks[def.key] then
        local key = def.key
        local defRef = def
        hookCallbacks[key] = function()
            local anchor = anchors[key]
            if anchor then
                anchor._applying = true
                FA.ApplyAnchor(defRef)
                anchor._applying = nil
            end
        end
    end
    local cb = hookCallbacks[def.key]

    -- Hook SetPoint to force our position (Blizzard may try to reposition)
    hooksecurefunc(target, "SetPoint", function()
        -- Only override if we're not in the middle of our own SetPoint
        if not anchors[def.key] or not anchors[def.key]._applying then
            C_Timer.After(0, cb)
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
