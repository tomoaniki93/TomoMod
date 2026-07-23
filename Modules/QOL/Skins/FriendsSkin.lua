-- FriendsSkin.lua
-- Lightweight reskin of Blizzard's Friends/Contacts window in the TomoMod mint
-- theme: a dark backdrop and a BRAND-colored border, WITHOUT rebuilding the
-- frame or touching its functional widgets (lists, tabs, buttons stay native).
-- The window is scalable from the GUI (chatFrameSkin-style scale setting).

local _, ns = ...
local U = ns and ns.Utils or _G.TomoMod_Utils or {}
local BRAND = U.BRAND or { 0.180, 0.847, 0.518 }

TomoMod_FriendsSkin = TomoMod_FriendsSkin or {}
local FS = TomoMod_FriendsSkin

local WHITE8 = "Interface\\Buttons\\WHITE8x8"
local isInitialized = false
local applied = false

local function GetSettings()
    local db = _G.TomoModDB
    return (db and db.friendsSkin) or {}
end

local function IsEnabled()
    local s = GetSettings()
    return s.enabled ~= false
end

local function StripTextures(frame)
    if not frame or not frame.GetRegions then return end
    for _, region in pairs({ frame:GetRegions() }) do
        if region.IsObjectType and region:IsObjectType("Texture") then
            pcall(function() region:SetTexture(nil); region:SetAlpha(0); region:Hide() end)
        end
    end
end

local function ApplyBackdrop(frame, bg, border)
    if not frame then return end
    if not frame.SetBackdrop then
        if Mixin and BackdropTemplateMixin then Mixin(frame, BackdropTemplateMixin) else return end
    end
    frame:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

function FS.ApplySkin()
    if not IsEnabled() then return end
    local frame = _G.FriendsFrame
    if not frame then return end

    -- Kill Blizzard's NineSlice / portrait chrome, then apply our panel.
    if frame.NineSlice then
        StripTextures(frame.NineSlice)
        frame.NineSlice:SetAlpha(0)
    end
    StripTextures(frame)
    ApplyBackdrop(frame, { 0.043, 0.047, 0.061, 1 }, BRAND)

    -- Accent strip along the top for the mint signature.
    if not frame._tmAccent then
        local acc = frame:CreateTexture(nil, "OVERLAY")
        acc:SetHeight(2)
        acc:SetPoint("TOPLEFT", 1, -1)
        acc:SetPoint("TOPRIGHT", -1, -1)
        acc:SetColorTexture(BRAND[1], BRAND[2], BRAND[3], 1)
        frame._tmAccent = acc
    end

    -- Inset panels (friends list, who list, etc.) get the same dark backdrop.
    for _, name in ipairs({
        "FriendsFrameInset", "FriendsListFrameScrollFrame",
        "FriendsFrameFriendsScrollFrame", "WhoListScrollFrame",
        "FriendsFrameIgnoredScrollFrame",
    }) do
        local inset = _G[name]
        if inset then
            StripTextures(inset)
            ApplyBackdrop(inset, { 0.07, 0.08, 0.10, 1 }, { 0.16, 0.18, 0.22, 1 })
        end
    end

    -- Scale from the GUI setting.
    local scale = GetSettings().scale or 1.0
    if scale and scale > 0 then
        frame:SetScale(scale)
    end

    applied = true
end

function FS.Initialize()
    if isInitialized then return end
    isInitialized = true

    local function hookWhenReady()
        local frame = _G.FriendsFrame
        if not frame then return false end
        frame:HookScript("OnShow", function()
            if C_Timer and C_Timer.After then C_Timer.After(0, FS.ApplySkin) else FS.ApplySkin() end
        end)
        return true
    end

    if not hookWhenReady() then
        -- Blizzard_FriendsFrame is loaded on demand: wait for it.
        local waiter = CreateFrame("Frame")
        waiter:RegisterEvent("ADDON_LOADED")
        waiter:SetScript("OnEvent", function(self, _, name)
            if name == "Blizzard_FriendsFrame" or _G.FriendsFrame then
                if hookWhenReady() then self:UnregisterAllEvents() end
            end
        end)
    end
end

-- Self-initialize once the addon environment is up.
local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function() FS.Initialize() end)
