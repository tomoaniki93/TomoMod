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

-- TalkingHeadFrameMixin owns its own visibility through UpdateShownState(),
-- which is SetShown(self.isInEditMode or self.isPlaying). Hiding the frame from
-- an OnShow hook leaves isPlaying set, leaves finishTimer running and leaves the
-- voiceover playing, and PlayCurrent() skips the Show path entirely when the
-- frame was already visible -- so OnShow is not a reliable choke point.
--
-- CloseImmediately() is Blizzard's own teardown: it clears isPlaying, cancels
-- finishTimer, calls C_TalkingHead.IgnoreCurrentTalkingHead(), hides through
-- UpdateShownState() (keeping the bottom-managed layout and AlertFrame anchors
-- consistent) and stops the voiceover sound.
--
-- TalkingHeadFrame is not a protected frame, so no combat guard is needed --
-- and combat is precisely when most talking heads fire (encounters, scenarios).
local function Suppress()
    if not IsEnabled() then return end

    local frame = _G.TalkingHeadFrame
    if not frame or not frame.CloseImmediately then return end

    -- Never fight Edit Mode: the frame is shown there on purpose.
    if frame.isInEditMode then return end

    local voHandle = frame.voHandle
    frame:CloseImmediately()

    -- StopSound() issued in the same frame as the PlaySound() that started the
    -- voiceover is occasionally ignored by the sound engine; sweep once more.
    if voHandle then
        C_Timer.After(0.05, function()
            StopSound(voHandle)
        end)
    end
end

-- Hook the single entry point. TalkingHeadFrameMixin:OnEvent() routes
-- TALKINGHEAD_REQUESTED to PlayCurrent(), which runs once per line of a
-- multi-line talking head. The hook re-reads the DB toggle every time, so
-- enabling / disabling from the GUI takes effect immediately without a /reload.
local function EnsureHook()
    if hooked then return end

    local frame = _G.TalkingHeadFrame
    if not frame or not frame.PlayCurrent then return end

    hooked = true
    hooksecurefunc(frame, "PlayCurrent", Suppress)
end

local function Apply()
    EnsureHook()

    local frame = _G.TalkingHeadFrame
    if IsEnabled() and frame and frame.isPlaying and not frame.isInEditMode then
        Suppress()
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

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
-- Retail folds TalkingHeadUI into Blizzard_FrameXML, so the frame already
-- exists at PLAYER_LOGIN. ADDON_LOADED is kept only for builds where
-- Blizzard_TalkingHeadUI is still a separate load-on-demand addon.
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 ~= "Blizzard_TalkingHeadUI" then return end
    Apply()
    if hooked then
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

_G.TomoMod_HideTalkingHead = HTH
