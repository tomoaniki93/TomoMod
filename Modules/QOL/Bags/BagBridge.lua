-- =====================================================================
-- BagBridge.lua — Blizzard bag lifecycle + combat-safe native suppression
-- =====================================================================

local Bags = TomoMod_BagSkin
if not Bags then return end

local Bridge = {
    nativeParents = setmetatable({}, { __mode = "k" }),
    pendingEnabled = nil,
    pendingMode = nil,
    syncing = false,
    suppressing = false,
}
Bags.RegisterModule("Bridge", Bridge)

local function InCombat()
    return InCombatLockdown and InCombatLockdown()
end

local function DisplayMode()
    local db = Bags.GetDB()
    return db and db.layout and db.layout.mode == "separate" and "separate" or "combined"
end

function Bridge:NativeFrames()
    local out = {}
    for i = 1, 13 do
        local f = _G["ContainerFrame" .. i]
        if f then out[#out + 1] = f end
    end
    if _G.ContainerFrameCombinedBags then out[#out + 1] = _G.ContainerFrameCombinedBags end
    return out
end

function Bridge:SuppressFrame(frame)
    if not frame then return end
    if InCombat() then
        self.pendingMode = "combined"
        return
    end

    -- Blizzard can reparent/reuse container frames when the bags are opened.
    -- Keep the original parent only once, but re-sink the frame every time.
    if not self.nativeParents[frame] then
        self.nativeParents[frame] = frame:GetParent() or UIParent
    end
    if frame:GetParent() ~= self.hiddenParent then
        frame:SetParent(self.hiddenParent)
    end
end

function Bridge:SuppressAll()
    if InCombat() then
        self.pendingMode = "combined"
        return
    end
    for _, frame in ipairs(self:NativeFrames()) do self:SuppressFrame(frame) end
end

function Bridge:RestoreAll()
    if InCombat() then
        self.pendingMode = "separate"
        return
    end
    for frame, parent in pairs(self.nativeParents) do
        if frame then frame:SetParent(parent or UIParent) end
        self.nativeParents[frame] = nil
    end
end

function Bridge:AnyNativeShown()
    for _, frame in ipairs(self:NativeFrames()) do
        if frame:IsShown() then return true end
    end
    return false
end

function Bridge:SyncFromBlizzard()
    if self.syncing or not Bags.IsEnabled() then return end
    self.syncing = true

    if DisplayMode() == "separate" then
        -- Separate mode deliberately lets Blizzard own its individual bag
        -- windows. The custom V4 frame is not displayed at the same time.
        local layout = Bags.Modules.Layout
        if layout and layout.frame then layout.frame:Hide() end
        Bags.State.visible = false
        self:RestoreAll()
    else
        -- We cannot safely reparent newly-created Blizzard container frames
        -- while locked down. In that rare case keep the native bag visible
        -- for the remainder of combat instead of displaying both systems.
        if InCombat() then
            self.pendingMode = "combined"
            local layout = Bags.Modules.Layout
            if layout and layout.frame then layout.frame:Hide() end
            Bags.State.visible = false
            self.syncing = false
            return
        end
        if self:AnyNativeShown() then
            Bags.Show()
        else
            Bags.Hide(true)
        end
        self:SuppressAll()
    end

    self.syncing = false
end

function Bridge:ScheduleSync()
    if self._syncQueued then return end
    self._syncQueued = true
    C_Timer.After(0, function()
        self._syncQueued = false
        if Bags.IsEnabled() then self:SyncFromBlizzard() end
    end)
end

function Bridge:CloseNativeState()
    if self.syncing or self._closingNative then return end
    self._closingNative = true
    if CloseAllBags then CloseAllBags() end
    self._closingNative = false
end

function Bridge:ShowSeparate()
    if InCombat() then
        self.pendingMode = "separate"
        return
    end
    self:RestoreAll()
    if OpenAllBags then OpenAllBags() end
end

function Bridge:ToggleSeparate()
    if InCombat() then return end
    self:RestoreAll()
    if ToggleAllBags then
        ToggleAllBags()
    elseif self:AnyNativeShown() then
        if CloseAllBags then CloseAllBags() end
    elseif OpenAllBags then
        OpenAllBags()
    end
end

function Bridge:ApplyMode(mode)
    mode = mode == "separate" and "separate" or "combined"
    if InCombat() then
        self.pendingMode = mode
        return
    end

    self.pendingMode = nil
    local nativeWasOpen = self:AnyNativeShown()
    local customWasOpen = Bags.State.visible

    if mode == "separate" then
        local layout = Bags.Modules.Layout
        if layout and layout.frame then layout.frame:Hide() end
        Bags.State.visible = false
        self:RestoreAll()

        -- Force the native system to use individual bags when this mode is
        -- explicitly selected. It is a normal client CVar, not a protected
        -- action. Failure is harmless on clients where the CVar is absent.
        if SetCVar then pcall(SetCVar, "combinedBags", "0") end

        if customWasOpen and not nativeWasOpen and OpenAllBags then
            OpenAllBags()
        end
    else
        if SetCVar then pcall(SetCVar, "combinedBags", "1") end
        self:SuppressAll()
        if nativeWasOpen or customWasOpen then Bags.Show() end
    end
end

function Bridge:ApplyEnabled(enabled)
    enabled = enabled and true or false
    if InCombat() then
        self.pendingEnabled = enabled
        return
    end

    self.pendingEnabled = nil
    if enabled then
        self:ApplyMode(DisplayMode())
    else
        Bags.Hide(true)
        self:RestoreAll()
        if CloseAllBags then CloseAllBags() end
    end
end

local function HookBagFunction(name)
    if type(_G[name]) ~= "function" then return end
    hooksecurefunc(name, function()
        if Bags.IsEnabled() then Bridge:ScheduleSync() end
    end)
end

function Bridge:Initialize()
    self.hiddenParent = self.hiddenParent or CreateFrame("Frame", "TomoMod_BagsV4_NativeSink", UIParent)
    self.hiddenParent:Hide()

    HookBagFunction("OpenAllBags")
    HookBagFunction("CloseAllBags")
    HookBagFunction("ToggleAllBags")
    HookBagFunction("ToggleBackpack")
    HookBagFunction("ToggleBag")

    if type(_G.ContainerFrame_GenerateFrame) == "function" then
        hooksecurefunc("ContainerFrame_GenerateFrame", function()
            if Bags.IsEnabled() and DisplayMode() == "combined" then
                C_Timer.After(0, function() Bridge:SuppressAll() end)
            end
        end)
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("BAG_UPDATE_COOLDOWN")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            Bags.Modules.Slots:EnsurePool()
            if Bridge.pendingEnabled ~= nil then
                Bridge:ApplyEnabled(Bridge.pendingEnabled)
            elseif Bridge.pendingMode ~= nil then
                Bridge:ApplyMode(Bridge.pendingMode)
            end
            if Bags.State.layoutPending then Bags.RequestRefresh(true) end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" then
            Bridge:ApplyEnabled(Bags.IsEnabled())
            Bags.Modules.Data:Scan(false)
            return
        end

        if event == "PLAYER_MONEY" then
            if Bags.Modules.Layout then Bags.Modules.Layout:RefreshHeader() end
            return
        end

        if event == "BAG_UPDATE_DELAYED" then
            if DisplayMode() == "combined" and Bags.IsVisible() then
                Bags.RequestRefresh(true)
            else
                Bags.Modules.Data:Scan(true)
            end
            return
        end

        if DisplayMode() == "combined" and Bags.IsVisible() then Bags.RequestRefresh(false) end
    end)
    self.events = events

    -- Temporary Phase-1 bridge: Presets / Installer still toggle
    -- bagSkin.enabled. Dashboard and the Bags panel now use bagsV4 directly.
    self.compatTicker = C_Timer.NewTicker(0.5, function()
        if not TomoModDB or type(TomoModDB.bagSkin) ~= "table" then return end
        local db = Bags.GetDB()
        local legacyEnabled = TomoModDB.bagSkin.enabled and true or false
        if legacyEnabled ~= db._legacyEnabledMirror then
            Bags.SetEnabled(legacyEnabled)
        end
    end)

    self:ApplyEnabled(Bags.IsEnabled())
end
