-- =====================================================================
-- ActionBars.lua v4.0.0 — Complete ActionBar System
-- Container-based bar management with grid layout, mover integration,
-- position persistence, and SecureHandler vehicle/override support.
-- Inspired by QUI, EllesUI, MidnightUI, GW2_UI.
-- =====================================================================

TomoMod_ActionBars = TomoMod_ActionBars or {}
local AB = TomoMod_ActionBars

-- =====================================================================
-- SHARED CONSTANTS (single source of truth for all AB files)
-- =====================================================================

local ADDON_NAME = "TomoMod"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- Localized math for hot paths
local floor, ceil, max = math.floor, math.ceil, math.max

AB.BAR_DEFS = {
    { id = "bar1",   blizzFrame = "MainMenuBar",        prefix = "ActionButton",              count = 12, paging = true  },
    { id = "bar2",   blizzFrame = "MultiBarBottomLeft",  prefix = "MultiBarBottomLeftButton",  count = 12 },
    { id = "bar3",   blizzFrame = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton", count = 12 },
    { id = "bar4",   blizzFrame = "MultiBarRight",       prefix = "MultiBarRightButton",       count = 12 },
    { id = "bar5",   blizzFrame = "MultiBarLeft",        prefix = "MultiBarLeftButton",        count = 12 },
    { id = "bar6",   blizzFrame = "MultiBar5",           prefix = "MultiBar5Button",           count = 12 },
    { id = "bar7",   blizzFrame = "MultiBar6",           prefix = "MultiBar6Button",           count = 12 },
    { id = "bar8",   blizzFrame = "MultiBar7",           prefix = "MultiBar7Button",           count = 12 },
    { id = "pet",    blizzFrame = "PetActionBar",        prefix = "PetActionButton",           count = 10 },
    { id = "stance", blizzFrame = "StanceBar",           prefix = "StanceButton",              count = 10 },
}

-- Lookup by id
local DEF_BY_ID = {}
for _, def in ipairs(AB.BAR_DEFS) do DEF_BY_ID[def.id] = def end

-- Per-bar defaults (merged into DB lazily)
local BAR_DEFAULTS = {
    enabled          = true,
    columns          = 12,
    spacing          = 2,
    buttonSize       = 36,
    orientation      = "horizontal",
    growDirection    = "rightdown",
    alpha            = 1.0,
    scale            = 1.0,
    fadeEnabled      = false,
    fadeInDelay      = 0,
    fadeInDuration   = 0.2,
    fadeOutDelay     = 0.5,
    fadeOutDuration  = 0.3,
    fadeOutAlpha     = 0,
    displayCondition = "",
    clickThrough     = false,
    showEmptyButtons = false,
    showCountText    = true,
    showHotkeyText   = true,
}

-- Override defaults for specific bars
local BAR_DEFAULT_OVERRIDES = {
    pet    = { columns = 10, buttonSize = 30 },
    stance = { columns = 10, buttonSize = 30 },
}

-- Display condition presets (macro conditionals)
AB.DISPLAY_PRESETS = {
    { label = "always",        condition = "" },
    { label = "combat",        condition = "[combat] show; hide" },
    { label = "shift",         condition = "[mod:shift] show; hide" },
    { label = "ctrl",          condition = "[mod:ctrl] show; hide" },
    { label = "alt",           condition = "[mod:alt] show; hide" },
    { label = "combat_shift",  condition = "[combat][mod:shift] show; hide" },
    { label = "group",         condition = "[group] show; hide" },
    { label = "hostile",       condition = "[harm,exists] show; hide" },
}

-- Default positions (used when no saved position exists)
local DEFAULT_POSITIONS = {
    bar1   = { "BOTTOM", "UIParent", "BOTTOM",   0,    38 },
    bar2   = { "BOTTOM", "UIParent", "BOTTOM",   0,    80 },
    bar3   = { "BOTTOM", "UIParent", "BOTTOM",   0,   122 },
    bar4   = { "RIGHT",  "UIParent", "RIGHT",  -40,     0 },
    bar5   = { "RIGHT",  "UIParent", "RIGHT",  -80,     0 },
    bar6   = { "BOTTOM", "UIParent", "BOTTOM",   0,   164 },
    bar7   = { "BOTTOM", "UIParent", "BOTTOM",   0,   206 },
    bar8   = { "BOTTOM", "UIParent", "BOTTOM",   0,   248 },
    pet    = { "BOTTOM", "UIParent", "BOTTOM", 250,    38 },
    stance = { "BOTTOM", "UIParent", "BOTTOM",-250,    38 },
}

-- =====================================================================
-- STATE
-- =====================================================================

local containers     = {}
local dragOverlays   = {}
local barButtons     = {}
local isLayoutMode   = false
local hiddenParent   = nil
local L              = nil

-- Combat-deferred queue (MidnightUI pattern)
local pendingLayouts = {}
local pendingCount   = 0
local combatQueueFrame = CreateFrame("Frame")
combatQueueFrame:Hide()

-- =====================================================================
-- HELPERS
-- =====================================================================

local function GetDB()
    if not TomoModDB then return nil end
    if not TomoModDB.actionBars then TomoModDB.actionBars = {} end
    return TomoModDB.actionBars
end

local function GetBarDB(id)
    local db = GetDB()
    if not db then return BAR_DEFAULTS end
    if not db.bars then db.bars = {} end
    if not db.bars[id] then db.bars[id] = {} end
    local overrides = BAR_DEFAULT_OVERRIDES[id]
    local result = db.bars[id]
    for k, v in pairs(BAR_DEFAULTS) do
        if result[k] == nil then
            result[k] = (overrides and overrides[k] ~= nil) and overrides[k] or v
        end
    end
    return result
end

AB.GetBarDB = GetBarDB

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled ~= false
end

-- =====================================================================
-- COMBAT DEFERRED QUEUE
-- =====================================================================

local function QueueProtectedOp(key, callback)
    if not pendingLayouts[key] then
        pendingCount = pendingCount + 1
    end
    pendingLayouts[key] = callback
    combatQueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function FlushProtectedQueue()
    if InCombatLockdown() then return end
    for key, callback in pairs(pendingLayouts) do
        pendingLayouts[key] = nil
        pendingCount = pendingCount - 1
        callback()
    end
    if pendingCount <= 0 then
        pendingCount = 0
        combatQueueFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

combatQueueFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then FlushProtectedQueue() end
end)

-- =====================================================================
-- HIDDEN PARENT
-- =====================================================================

local function GetHiddenParent()
    if not hiddenParent then
        hiddenParent = CreateFrame("Frame", "TomoMod_ABHiddenParent", UIParent)
        hiddenParent:SetAllPoints()
        hiddenParent:Hide()
    end
    return hiddenParent
end

-- =====================================================================
-- POSITION PERSISTENCE
-- =====================================================================

local function SavePosition(id)
    local db = GetDB()
    if not db then return end
    if not db.positions then db.positions = {} end
    local container = containers[id]
    if not container then return end
    local point, _, relPoint, x, y = container:GetPoint()
    if point then
        db.positions[id] = { point, "UIParent", relPoint, floor(x + 0.5), floor(y + 0.5) }
    end
end

local function RestorePosition(id)
    local container = containers[id]
    if not container then return end
    local db = GetDB()
    local pos = db and db.positions and db.positions[id]
    if not pos then pos = DEFAULT_POSITIONS[id] end
    if pos then
        container:ClearAllPoints()
        container:SetPoint(pos[1], UIParent, pos[3], pos[4], pos[5])
    end
end

-- =====================================================================
-- PAGING DRIVER (bar1 only)
-- =====================================================================

local pagingInitialized = false

local function BuildPagingCondition()
    local parts = {}
    table.insert(parts, "[overridebar] override")
    table.insert(parts, "[vehicleui][possessbar][shapeshift] possess")
    table.insert(parts, "[bonusbar:5] 11")
    for i = 4, 1, -1 do
        table.insert(parts, "[bonusbar:" .. i .. "] " .. (6 + i))
    end
    for i = 6, 2, -1 do
        table.insert(parts, "[bar:" .. i .. "] " .. i)
    end
    table.insert(parts, "1")
    return table.concat(parts, "; ")
end

local function SetupPaging(container)
    if pagingInitialized then return end
    pagingInitialized = true
    container:SetAttribute("_onstate-page", [[
        local page = newstate
        if page == "override" then
            if HasVehicleActionBar and HasVehicleActionBar() then
                page = GetVehicleBarIndex()
            elseif HasOverrideActionBar and HasOverrideActionBar() then
                page = GetOverrideBarIndex()
            elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
                page = GetTempShapeshiftBarIndex()
            else page = 1 end
        elseif page == "possess" then
            if HasVehicleActionBar and HasVehicleActionBar() then
                page = GetVehicleBarIndex()
            elseif HasOverrideActionBar and HasOverrideActionBar() then
                page = GetOverrideBarIndex()
            elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
                page = GetTempShapeshiftBarIndex()
            elseif HasBonusActionBar and HasBonusActionBar() then
                page = GetBonusBarIndex()
            else page = 1 end
        end
        page = tonumber(page) or 1
        local offset = (page - 1) * 12
        control:ChildUpdate("offset", offset)
    ]])
    RegisterStateDriver(container, "page", BuildPagingCondition())
end

local CHILD_UPDATE_OFFSET = [[
    local index = self:GetAttribute("index")
    local newAction = index + (message or 0)
    self:SetAttribute("action", newAction)
    if IsPressHoldReleaseSpell then
        local pressAndHold = false
        self:SetAttribute("typerelease", "actionrelease")
        local actionType, id, subType = GetActionInfo(newAction)
        if actionType == "spell" then
            pressAndHold = IsPressHoldReleaseSpell(id)
        elseif actionType == "macro" and subType == "spell" then
            pressAndHold = IsPressHoldReleaseSpell(id)
        end
        self:SetAttribute("pressAndHoldAction", pressAndHold)
    end
]]

-- =====================================================================
-- CONTAINER CREATION
-- =====================================================================

local function CreateContainer(def)
    local id = def.id
    local name = "TomoMod_AB_" .. id
    local container = CreateFrame("Frame", name, UIParent, "SecureHandlerStateTemplate")
    container:SetSize(1, 1)
    container:SetClampedToScreen(true)
    container:Show()

    -- Vehicle/Override/PetBattle visibility gate (QUI pattern)
    container:SetAttribute("tomo-user-shown", true)
    container:SetAttribute("_onstate-tomooverride", [[
        if newstate == "hide" then
            self:Hide()
        elseif self:GetAttribute("tomo-user-shown") then
            self:Show()
        end
    ]])
    RegisterStateDriver(container, "tomooverride",
        "[overridebar][vehicleui][possessbar][petbattle] hide; show")

    if def.paging then
        SetupPaging(container)
    end

    containers[id] = container
    return container
end

-- =====================================================================
-- BLIZZARD BAR HIDING
-- =====================================================================

local suppressedFrames = {}

local function HideBlizzardBar(def)
    if InCombatLockdown() then
        QueueProtectedOp("hide_" .. def.id, function() HideBlizzardBar(def) end)
        return
    end
    local blizzFrame = _G[def.blizzFrame]
    if not blizzFrame or suppressedFrames[def.id] then return end
    suppressedFrames[def.id] = true
    blizzFrame:UnregisterAllEvents()
    blizzFrame:SetParent(GetHiddenParent())
    blizzFrame:Hide()
    if blizzFrame.SetIsShownInEditMode then
        blizzFrame:SetIsShownInEditMode(false)
    end
end

-- =====================================================================
-- BUTTON REPARENTING
-- =====================================================================

local function ReparentButtons(def, container)
    if InCombatLockdown() then
        QueueProtectedOp("reparent_" .. def.id, function() ReparentButtons(def, container) end)
        return
    end
    local buttons = {}
    for i = 1, def.count do
        local btn = _G[def.prefix .. i]
        if btn then
            btn:SetParent(container)
            btn:Show()   -- Ensure visible (Blizzard OnHide may have hidden them)
            if def.paging then
                btn:SetAttribute("index", i)
                btn:SetAttribute("action", i)
                btn:SetAttribute("_childupdate-offset", CHILD_UPDATE_OFFSET)
            end
            if btn.TextOverlayContainer then
                btn.TextOverlayContainer:EnableMouse(false)
            end
            buttons[i] = btn
        end
    end
    barButtons[def.id] = buttons
end

-- =====================================================================
-- GRID LAYOUT ENGINE
-- =====================================================================

local function LayoutBar(id)
    local def = DEF_BY_ID[id]
    if not def then return end
    local barDB = GetBarDB(id)
    local buttons = barButtons[id]
    local container = containers[id]
    if not buttons or not container then return end

    if InCombatLockdown() then
        QueueProtectedOp("layout_" .. id, function() LayoutBar(id) end)
        return
    end

    local btnSize     = barDB.buttonSize or 36
    local spacing     = barDB.spacing or 2
    local cols        = barDB.columns or def.count
    local isVertical  = barDB.orientation == "vertical"
    local growDir     = barDB.growDirection or "rightdown"
    local numVisible  = def.count
    local scale       = barDB.scale or 1.0

    -- Pixel snap
    local px = 1 / (container:GetEffectiveScale() or 1)
    btnSize = floor(btnSize / px + 0.5) * px
    spacing = floor(spacing / px + 0.5) * px

    local numCols, numRows
    if isVertical then
        numRows = cols
        numCols = ceil(numVisible / numRows)
    else
        numCols = cols
        numRows = ceil(numVisible / numCols)
    end

    local groupWidth  = numCols * btnSize + max(0, numCols - 1) * spacing
    local groupHeight = numRows * btnSize + max(0, numRows - 1) * spacing
    container:SetSize(groupWidth, groupHeight)

    local xDir, yDir = 1, -1
    if     growDir == "rightup"  then xDir, yDir =  1,  1
    elseif growDir == "leftdown" then xDir, yDir = -1, -1
    elseif growDir == "leftup"   then xDir, yDir = -1,  1
    end

    local anchor = "TOPLEFT"
    if     growDir == "rightup"  then anchor = "BOTTOMLEFT"
    elseif growDir == "leftdown" then anchor = "TOPRIGHT"
    elseif growDir == "leftup"   then anchor = "BOTTOMRIGHT"
    end

    for i = 1, numVisible do
        local btn = buttons[i]
        if btn then
            local idx = i - 1
            local col, row
            if isVertical then
                col = floor(idx / numRows)
                row = idx % numRows
            else
                col = idx % numCols
                row = floor(idx / numCols)
            end
            local x = col * (btnSize + spacing) * xDir
            local y = row * (btnSize + spacing) * yDir
            btn:ClearAllPoints()
            btn:SetSize(btnSize, btnSize)
            btn:SetPoint(anchor, container, anchor, x, y)

            local hotkey = btn.HotKey or _G[def.prefix .. i .. "HotKey"]
            if hotkey then hotkey:SetShown(barDB.showHotkeyText ~= false) end
            local count = btn.Count or _G[def.prefix .. i .. "Count"]
            if count then count:SetShown(barDB.showCountText ~= false) end
        end
    end

    container:SetScale(scale)
end

-- =====================================================================
-- DISPLAY CONDITIONS
-- =====================================================================

local function UpdateDisplayCondition(id)
    local container = containers[id]
    if not container then return end
    local barDB = GetBarDB(id)
    local condition = barDB.displayCondition or ""
    UnregisterStateDriver(container, "tomovis")
    if condition == "" then
        container:SetAttribute("_onstate-tomovis", nil)
        if container:GetAttribute("tomo-user-shown") then
            container:Show()
        end
    else
        container:SetAttribute("_onstate-tomovis", [[
            if newstate == "show" then self:Show() else self:Hide() end
        ]])
        RegisterStateDriver(container, "tomovis", condition)
    end
end

-- =====================================================================
-- FADE SYSTEM
-- =====================================================================

local fadeState     = {}
local fadeWatched   = {}
local fadeFrame     = CreateFrame("Frame")
local fadePollTimer = 0

local function GetFadeState(id)
    if not fadeState[id] then
        fadeState[id] = {
            currentAlpha = 1, targetAlpha = 1,
            isFading = false, fadeStart = 0,
            fadeStartAlpha = 1, fadeDuration = 0.3,
            isMouseOver = false, delayTimer = nil,
        }
    end
    return fadeState[id]
end

local function IsContainerFocused(id)
    local container = containers[id]
    if not container then return false end
    if container:IsMouseOver() then return true end
    local buttons = barButtons[id]
    if buttons then
        for _, btn in ipairs(buttons) do
            if btn:IsMouseOver() then return true end
        end
    end
    if SpellFlyout and SpellFlyout:IsShown() then
        local flyoutParent = SpellFlyout:GetParent()
        if flyoutParent and buttons then
            for _, btn in ipairs(buttons) do
                if flyoutParent == btn then return true end
            end
        end
        if SpellFlyout:IsMouseOver() then return true end
    end
    return false
end

local function SetBarAlpha(id, alpha)
    local container = containers[id]
    if not container then return end
    container:SetAlpha(alpha)
    local buttons = barButtons[id]
    if buttons then
        for _, btn in ipairs(buttons) do
            local cd = btn.cooldown or _G[(btn:GetName() or "") .. "Cooldown"]
            if cd then
                if alpha < 0.01 then
                    cd:SetDrawSwipe(false); cd:SetDrawBling(false)
                else
                    cd:SetDrawSwipe(true); cd:SetDrawBling(true)
                end
            end
        end
    end
end

local function StartFade(id, targetAlpha, duration, delay)
    local state = GetFadeState(id)
    if delay and delay > 0 then
        state.delayTimer = GetTime() + delay
        state.targetAlpha = targetAlpha
        state.isFading = false
        return
    end
    state.delayTimer = nil
    state.isFading = true
    state.fadeStart = GetTime()
    state.fadeStartAlpha = state.currentAlpha
    state.targetAlpha = targetAlpha
    state.fadeDuration = duration or 0.3
end

fadeFrame:SetScript("OnUpdate", function(self, elapsed)
    fadePollTimer = fadePollTimer + elapsed
    if fadePollTimer < 0.05 then return end
    fadePollTimer = 0
    local now = GetTime()
    for id in pairs(fadeWatched) do
        local state = GetFadeState(id)
        local barDB = GetBarDB(id)
        local focused = IsContainerFocused(id)
        if focused ~= state.isMouseOver then
            state.isMouseOver = focused
            if focused then
                StartFade(id, barDB.alpha or 1, barDB.fadeInDuration or 0.2, barDB.fadeInDelay or 0)
            else
                StartFade(id, barDB.fadeOutAlpha or 0, barDB.fadeOutDuration or 0.3, barDB.fadeOutDelay or 0.5)
            end
        end
        if state.delayTimer then
            if now >= state.delayTimer then
                local dur = state.targetAlpha < state.currentAlpha
                    and (barDB.fadeOutDuration or 0.3)
                    or  (barDB.fadeInDuration or 0.2)
                state.delayTimer = nil
                state.isFading = true
                state.fadeStart = now
                state.fadeStartAlpha = state.currentAlpha
                state.fadeDuration = dur
            end
        end
        if state.isFading then
            local el = now - state.fadeStart
            local progress = (state.fadeDuration > 0) and (el / state.fadeDuration) or 1
            if progress >= 1 then
                state.currentAlpha = state.targetAlpha
                state.isFading = false
            else
                local t = progress
                t = t * t * (3 - 2 * t)
                state.currentAlpha = state.fadeStartAlpha + (state.targetAlpha - state.fadeStartAlpha) * t
            end
            SetBarAlpha(id, state.currentAlpha)
        end
    end
end)

local function UpdateFade(id)
    local barDB = GetBarDB(id)
    if barDB.fadeEnabled then
        fadeWatched[id] = true
        local state = GetFadeState(id)
        if not state.isMouseOver then
            state.currentAlpha = barDB.fadeOutAlpha or 0
            SetBarAlpha(id, state.currentAlpha)
        end
    else
        fadeWatched[id] = nil
        local state = GetFadeState(id)
        state.currentAlpha = barDB.alpha or 1
        SetBarAlpha(id, state.currentAlpha)
    end
end

-- =====================================================================
-- SHOW EMPTY BUTTONS
-- =====================================================================

-- EllesUI / QUI pattern:
-- Blizzard's ShowGrid/HideGrid uses a counter stored in the "showgrid"
-- attribute.  ACTIONBAR_SHOWGRID increments (+1), ACTIONBAR_HIDEGRID
-- decrements (-1).  When the counter reaches 0, the button hides.
--
-- Setting the attribute to a high base value (32) means Blizzard's
-- +1/-1 cycles (33→32) never reach 0.  The button stays visible.
-- When the user disables the option, we reset to 0 and let Blizzard's
-- normal HasAction visibility take over.

local SHOWGRID_ALWAYS = 32

local function UpdateEmptyButtons(id)
    local barDB = GetBarDB(id)
    local buttons = barButtons[id]
    if not buttons then return end
    if InCombatLockdown() then
        QueueProtectedOp("emptybtns_" .. id, function() UpdateEmptyButtons(id) end)
        return
    end
    for _, btn in ipairs(buttons) do
        if barDB.showEmptyButtons then
            if not btn._tomoGrid then
                btn._tomoGrid = true
                btn:SetAttribute("showgrid", SHOWGRID_ALWAYS)
                btn:Show()
                btn:SetAlpha(1)
            end
        else
            if btn._tomoGrid then
                btn._tomoGrid = nil
                btn:SetAttribute("showgrid", 0)
                -- Let Blizzard decide visibility based on HasAction
                local action = btn.action or btn:GetAttribute("action") or 0
                if not HasAction(action) then
                    btn:Hide()
                end
            end
        end
    end
end

-- =====================================================================
-- CLICK-THROUGH
-- =====================================================================

local function SetClickThrough(id, enable)
    if InCombatLockdown() then
        QueueProtectedOp("clickthrough_" .. id, function() SetClickThrough(id, enable) end)
        return
    end
    local buttons = barButtons[id]
    if not buttons then return end
    for _, btn in ipairs(buttons) do
        btn:EnableMouse(not enable)
    end
end

-- =====================================================================
-- MOVER OVERLAY
-- =====================================================================

local function CreateDragOverlay(id)
    local container = containers[id]
    if not container then return end
    local overlay = CreateFrame("Frame", "TomoMod_ABMover_" .. id, container)
    overlay:SetAllPoints(container)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(100)
    overlay:EnableMouse(true)
    overlay:SetMovable(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:Hide()

    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.047, 0.824, 0.624, 0.25)

    local borderParts = {}
    for _, info in ipairs({
        {"TOPLEFT","TOPRIGHT",true}, {"BOTTOMLEFT","BOTTOMRIGHT",true},
        {"TOPLEFT","BOTTOMLEFT",false}, {"TOPRIGHT","BOTTOMRIGHT",false},
    }) do
        local t = overlay:CreateTexture(nil, "BORDER")
        t:SetColorTexture(0.047, 0.824, 0.624, 0.8)
        if info[3] then t:SetHeight(1) else t:SetWidth(1) end
        t:SetPoint(info[1]); t:SetPoint(info[2])
        borderParts[#borderParts+1] = t
    end

    local label = overlay:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 11, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetTextColor(1, 1, 1, 0.9)
    local displayId = id:upper()
    if L then displayId = L["mover_ab_" .. id] or displayId end
    label:SetText(displayId)

    overlay:SetScript("OnDragStart", function()
        container:SetMovable(true)
        container:StartMoving()
    end)
    overlay:SetScript("OnDragStop", function()
        container:StopMovingOrSizing()
        container:SetMovable(false)
        SavePosition(id)
    end)

    dragOverlays[id] = overlay
    return overlay
end

-- =====================================================================
-- APPLY SETTINGS
-- =====================================================================

function AB.ApplyBar(id)
    local def = DEF_BY_ID[id]
    if not def then return end
    local barDB = GetBarDB(id)

    if not containers[id] then
        CreateContainer(def)
        HideBlizzardBar(def)
        ReparentButtons(def, containers[id])
    end

    LayoutBar(id)
    RestorePosition(id)
    UpdateEmptyButtons(id)

    if not barDB.fadeEnabled then
        SetBarAlpha(id, barDB.alpha or 1)
    end

    UpdateFade(id)
    UpdateDisplayCondition(id)
    SetClickThrough(id, barDB.clickThrough)

    local container = containers[id]
    if container then
        if barDB.enabled == false then
            container:SetAttribute("tomo-user-shown", false)
            container:Hide()
        else
            container:SetAttribute("tomo-user-shown", true)
            if not InCombatLockdown() then container:Show() end
        end
    end
end

-- =====================================================================
-- MOVER INTEGRATION
-- =====================================================================

local function RegisterWithMovers()
    if not TomoMod_Movers or not TomoMod_Movers.RegisterEntry then return end
    TomoMod_Movers.RegisterEntry({
        label = L and L["mover_actionbars"] or "Action Bars",
        unlock = function()
            isLayoutMode = true
            for id in pairs(containers) do
                local barDB = GetBarDB(id)
                if barDB.enabled ~= false then
                    if not dragOverlays[id] then CreateDragOverlay(id) end
                    dragOverlays[id]:Show()
                end
            end
        end,
        lock = function()
            isLayoutMode = false
            for id, overlay in pairs(dragOverlays) do
                overlay:Hide()
                SavePosition(id)
            end
        end,
        isActive = function() return IsEnabled() end,
    })
end

-- =====================================================================
-- SHIFT REVEAL
-- =====================================================================

local shiftFrame = CreateFrame("Frame")
shiftFrame:Hide()

local function SetShiftReveal(enabled)
    if enabled then
        shiftFrame._lastShift = nil
        shiftFrame:SetScript("OnUpdate", function(self)
            local shift = IsShiftKeyDown()
            if shift == self._lastShift then return end
            self._lastShift = shift
            for id in pairs(fadeWatched) do
                local barDB = GetBarDB(id)
                if shift then
                    SetBarAlpha(id, barDB.alpha or 1)
                else
                    local state = GetFadeState(id)
                    if not state.isMouseOver then
                        SetBarAlpha(id, barDB.fadeOutAlpha or 0)
                    end
                end
            end
        end)
        shiftFrame:Show()
    else
        shiftFrame:SetScript("OnUpdate", nil)
        shiftFrame:Hide()
    end
end

-- =====================================================================
-- PUBLIC API
-- =====================================================================

function AB.Initialize()
    L = TomoMod_L
    if not IsEnabled() then return end

    for _, def in ipairs(AB.BAR_DEFS) do
        CreateContainer(def)
        HideBlizzardBar(def)
        ReparentButtons(def, containers[def.id])
        LayoutBar(def.id)
        RestorePosition(def.id)
    end

    RegisterWithMovers()

    C_Timer.After(0.3, function()
        AB.ApplyAll()
        local db = GetDB()
        if db and db.shiftReveal then SetShiftReveal(true) end
    end)
end

function AB.ApplyAll()
    for _, def in ipairs(AB.BAR_DEFS) do AB.ApplyBar(def.id) end
end

function AB.GetBar(id) return containers[id] end
function AB.GetButtons(id) return barButtons[id] end
function AB.GetDef(id) return DEF_BY_ID[id] end
function AB.IsLayoutMode() return isLayoutMode end

function AB.SetShiftReveal(enabled)
    SetShiftReveal(enabled)
    local db = GetDB()
    if db then db.shiftReveal = enabled end
end

function AB.RefreshBar(id)
    AB.ApplyBar(id)
    if TomoMod_ActionBarSkin and TomoMod_ActionBarSkin.ReskinBar then
        TomoMod_ActionBarSkin.ReskinBar(id)
    end
end

-- =====================================================================
-- VEHICLE / OVERRIDE HANDLING
-- =====================================================================

local vehicleFrame = CreateFrame("Frame")
vehicleFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
vehicleFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
vehicleFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
vehicleFrame:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
vehicleFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
vehicleFrame:SetScript("OnEvent", function(_, event, unit)
    if (event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and unit ~= "player" then return end
    C_Timer.After(0.2, function()
        if not InCombatLockdown() then
            for _, def in ipairs(AB.BAR_DEFS) do
                local barDB = GetBarDB(def.id)
                if not barDB.fadeEnabled then
                    SetBarAlpha(def.id, barDB.alpha or 1)
                end
            end
        end
    end)
end)

-- =====================================================================
-- BOOT
-- =====================================================================

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function()
    C_Timer.After(0.5, function()
        if InCombatLockdown() then
            -- RegisterStateDriver calls SetAttribute on SecureStateDriverManager,
            -- which is blocked in combat. Defer until combat ends.
            local combatFrame = CreateFrame("Frame")
            combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            combatFrame:SetScript("OnEvent", function(self)
                self:UnregisterAllEvents()
                AB.Initialize()
            end)
        else
            AB.Initialize()
        end
    end)
end)
