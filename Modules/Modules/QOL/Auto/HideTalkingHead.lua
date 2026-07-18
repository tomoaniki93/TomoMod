--------------------------------------------------
-- Tomo : HideTalkingHead
--------------------------------------------------

local ADDON, Tomo = ...

TomoMod_HideTalkingHead = TomoMod_HideTalkingHead or {}
local HTH = TomoMod_HideTalkingHead

local hooked = false

local function IsEnabled()
    return TomoModDB and TomoModDB.hideTalkingHead and TomoModDB.hideTalkingHead.enabled
end

-- Hook OnShow once. The hook checks the DB toggle each time, so enabling /
-- disabling from the GUI takes effect immediately without a /reload.
local function EnsureHook()
    if hooked or not TalkingHeadFrame then return end
    hooked = true
    TalkingHeadFrame:HookScript("OnShow", function(self)
        if IsEnabled() and not InCombatLockdown() then
            self:Hide()
        end
    end)
end

local function Apply()
    EnsureHook()
    if IsEnabled() and TalkingHeadFrame and TalkingHeadFrame:IsShown() and not InCombatLockdown() then
        TalkingHeadFrame:Hide()
    end
end

function HTH.SetEnabled(enabled)
    if not TomoModDB then return end
    TomoModDB.hideTalkingHead = TomoModDB.hideTalkingHead or {}
    TomoModDB.hideTalkingHead.enabled = enabled and true or false
    Apply()
end

function HTH.Toggle()
    HTH.SetEnabled(not IsEnabled())
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
-- Blizzard_TalkingHeadUI is load-on-demand: hook as soon as its frame exists.
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 ~= "Blizzard_TalkingHeadUI" then return end
    Apply()
end)

_G.TomoMod_HideTalkingHead = HTH
