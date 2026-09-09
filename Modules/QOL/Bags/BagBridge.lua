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

-- Blizzard dynamically limits "Show in Backpack" currencies from the width
-- of its native BackpackTokenFrame. In TomoMod combined mode that native bag is
-- intentionally suppressed, so Blizzard can mis-detect a capacity of 1. Keep
-- the normal Blizzard result everywhere else, but preserve the traditional
-- three tracked-currency slots while TomoMod owns the combined bag.
local TRACKED_CURRENCY_CAP = 3
local function EnsureBackpackTokenCapacity()
    local tokenFrame = _G.BackpackTokenFrame
    if not tokenFrame or tokenFrame._TomoModOriginalGetMaxTokensWatched then return end
    if type(tokenFrame.GetMaxTokensWatched) ~= "function" then return end

    local original = tokenFrame.GetMaxTokensWatched
    tokenFrame._TomoModOriginalGetMaxTokensWatched = original
    tokenFrame.GetMaxTokensWatched = function(self, ...)
        local maxWatched = tonumber(original(self, ...)) or 1
        if Bags.IsEnabled() and DisplayMode() == "combined" then
            return math.max(maxWatched, TRACKED_CURRENCY_CAP)
        end
        return maxWatched
    end
end

-- ---------------------------------------------------------------------
-- Native separate-bag skin
-- Blizzard keeps ownership of the individual ContainerFrame windows in
-- separate mode; TomoMod only changes their presentation.
-- ---------------------------------------------------------------------
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local ACCENT = { 0.18, 0.62, 0.85 }
local NATIVE_BG = { 0.055, 0.060, 0.068 }
local NATIVE_HEADER = { 0.105, 0.112, 0.122 }
local NATIVE_SLOT = { 0.030, 0.036, 0.042 }

local function AddBorder(parent, store, r, g, b, a)
    if store.border then return end
    store.border = {}
    local defs = {
        { "TOPLEFT", "TOPRIGHT", 1, nil },
        { "BOTTOMLEFT", "BOTTOMRIGHT", 1, nil },
        { "TOPLEFT", "BOTTOMLEFT", nil, 1 },
        { "TOPRIGHT", "BOTTOMRIGHT", nil, 1 },
    }
    for _, def in ipairs(defs) do
        local tex = parent:CreateTexture(nil, "OVERLAY")
        tex:SetTexture(WHITE)
        tex:SetPoint(def[1], parent, def[1])
        tex:SetPoint(def[2], parent, def[2])
        if def[3] then tex:SetHeight(def[3]) end
        if def[4] then tex:SetWidth(def[4]) end
        tex:SetColorTexture(r, g, b, a)
        store.border[#store.border + 1] = tex
    end
end

local function SetBorderColor(store, r, g, b, a)
    if not store or not store.border then return end
    for _, tex in ipairs(store.border) do tex:SetColorTexture(r, g, b, a) end
end

local function CollectNativeSlots(frame)
    local out, seen = {}, {}
    local function add(button)
        if not button or seen[button] or not button.GetObjectType then return end
        if button:GetObjectType() ~= "Button" then return end
        seen[button] = true
        out[#out + 1] = button
    end

    if type(frame.Items) == "table" then
        for _, button in pairs(frame.Items) do add(button) end
    end

    local frameName = frame.GetName and frame:GetName()
    if frameName then
        for i = 1, 80 do add(_G[frameName .. "Item" .. i]) end
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child.GetName and child:GetName()
        if name and name:match("Item%d+$") then add(child) end
    end

    return out
end

local function NativeSlotIcon(button)
    return button.Icon or button.icon or (button.GetName and button:GetName() and _G[button:GetName() .. "IconTexture"])
end

local function SkinNativeSlot(button)
    if not button then return end
    local skin = button._TomoModSeparateBagSkin
    if not skin then
        skin = {}
        button._TomoModSeparateBagSkin = skin

        local normal = button.GetNormalTexture and button:GetNormalTexture()
        if normal then
            skin.normal = normal
            skin.normalAlpha = normal:GetAlpha()
        end

        local bg = button:CreateTexture(nil, "BACKGROUND", nil, 7)
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(NATIVE_SLOT[1], NATIVE_SLOT[2], NATIVE_SLOT[3], 0.98)
        skin.bg = bg

        AddBorder(button, skin, 1, 1, 1, 0.12)

        button:HookScript("OnEnter", function(self)
            SetBorderColor(self._TomoModSeparateBagSkin, ACCENT[1], ACCENT[2], ACCENT[3], 0.72)
        end)
        button:HookScript("OnLeave", function(self)
            SetBorderColor(self._TomoModSeparateBagSkin, 1, 1, 1, 0.12)
        end)
    end

    if skin.normal then skin.normal:SetAlpha(0) end
    if skin.bg then skin.bg:Show() end
    if skin.border then for _, tex in ipairs(skin.border) do tex:Show() end end

    local icon = NativeSlotIcon(button)
    if icon and icon.SetTexCoord then icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
end

local function RestoreNativeSlot(button)
    local skin = button and button._TomoModSeparateBagSkin
    if not skin then return end
    if skin.normal then skin.normal:SetAlpha(skin.normalAlpha or 1) end
    if skin.bg then skin.bg:Hide() end
    if skin.border then for _, tex in ipairs(skin.border) do tex:Hide() end end
end

local function NativeTitle(frame)
    if frame.TitleContainer and frame.TitleContainer.TitleText then return frame.TitleContainer.TitleText end
    if frame.TitleText then return frame.TitleText end
    local name = frame.GetName and frame:GetName()
    return name and _G[name .. "Name"] or nil
end

local function SkinNativeFrame(frame)
    if not frame then return end
    local skin = frame._TomoModSeparateBagSkin
    if not skin then
        skin = { hiddenRegions = {} }
        frame._TomoModSeparateBagSkin = skin

        for i = 1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                skin.hiddenRegions[region] = region:GetAlpha()
            end
        end

        if frame.NineSlice then
            skin.nineSliceWasShown = frame.NineSlice:IsShown()
        end

        local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 7)
        bg:SetAllPoints()
        bg:SetColorTexture(NATIVE_BG[1], NATIVE_BG[2], NATIVE_BG[3], 0.985)
        skin.bg = bg

        local header = frame:CreateTexture(nil, "BACKGROUND", nil, 7)
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(28)
        header:SetColorTexture(NATIVE_HEADER[1], NATIVE_HEADER[2], NATIVE_HEADER[3], 0.98)
        skin.header = header

        local accent = frame:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT", 1, -28)
        accent:SetPoint("TOPRIGHT", -1, -28)
        accent:SetHeight(1)
        accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.62)
        skin.accent = accent

        AddBorder(frame, skin, ACCENT[1], ACCENT[2], ACCENT[3], 0.32)

        local title = NativeTitle(frame)
        if title and title.GetFont then
            skin.title = title
            skin.titleFont, skin.titleSize, skin.titleFlags = title:GetFont()
            skin.titleR, skin.titleG, skin.titleB, skin.titleA = title:GetTextColor()
        end
    end

    for region in pairs(skin.hiddenRegions) do
        if region and region.SetAlpha then region:SetAlpha(0) end
    end
    if frame.NineSlice then frame.NineSlice:Hide() end
    if skin.bg then skin.bg:Show() end
    if skin.header then skin.header:Show() end
    if skin.accent then skin.accent:Show() end
    if skin.border then for _, tex in ipairs(skin.border) do tex:Show() end end

    if skin.title then
        skin.title:SetFont(FONT_BOLD, 11, "OUTLINE")
        skin.title:SetTextColor(0.92, 0.96, 0.98, 1)
    end

    for _, button in ipairs(CollectNativeSlots(frame)) do SkinNativeSlot(button) end
end

local function RestoreNativeFrame(frame)
    local skin = frame and frame._TomoModSeparateBagSkin
    if not skin then return end

    for region, alpha in pairs(skin.hiddenRegions) do
        if region and region.SetAlpha then region:SetAlpha(alpha or 1) end
    end
    if frame.NineSlice and skin.nineSliceWasShown then frame.NineSlice:Show() end
    if skin.bg then skin.bg:Hide() end
    if skin.header then skin.header:Hide() end
    if skin.accent then skin.accent:Hide() end
    if skin.border then for _, tex in ipairs(skin.border) do tex:Hide() end end

    if skin.title and skin.titleFont then
        skin.title:SetFont(skin.titleFont, skin.titleSize or 11, skin.titleFlags or "")
        skin.title:SetTextColor(skin.titleR or 1, skin.titleG or 1, skin.titleB or 1, skin.titleA or 1)
    end

    for _, button in ipairs(CollectNativeSlots(frame)) do RestoreNativeSlot(button) end
end

function Bridge:SkinSeparateFrames()
    if not Bags.IsEnabled() or DisplayMode() ~= "separate" then return end
    for i = 1, 13 do SkinNativeFrame(_G["ContainerFrame" .. i]) end
end

function Bridge:RestoreNativeSkins()
    for i = 1, 13 do RestoreNativeFrame(_G["ContainerFrame" .. i]) end
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
        self:SkinSeparateFrames()
    else
        self:RestoreNativeSkins()
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
    C_Timer.After(0, function() Bridge:SkinSeparateFrames() end)
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
    C_Timer.After(0, function() Bridge:SkinSeparateFrames() end)
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
        C_Timer.After(0, function() Bridge:SkinSeparateFrames() end)
    else
        self:RestoreNativeSkins()
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
        self:RestoreNativeSkins()
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
            if not Bags.IsEnabled() then return end
            if DisplayMode() == "combined" then
                C_Timer.After(0, function() Bridge:SuppressAll() end)
            else
                C_Timer.After(0, function() Bridge:SkinSeparateFrames() end)
            end
        end)
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("BAG_UPDATE_COOLDOWN")
    events:RegisterEvent("PLAYER_MONEY")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(self, event)
        if event == "ADDON_LOADED" then
            EnsureBackpackTokenCapacity()
            if _G.BackpackTokenFrame and _G.BackpackTokenFrame._TomoModOriginalGetMaxTokensWatched then
                self:UnregisterEvent("ADDON_LOADED")
            end
            return
        end

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
                Bridge:SkinSeparateFrames()
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

    EnsureBackpackTokenCapacity()
    self:ApplyEnabled(Bags.IsEnabled())
end
