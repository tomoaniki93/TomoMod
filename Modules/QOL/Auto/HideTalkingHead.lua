--------------------------------------------------
-- Tomo : HideTalkingHead
--------------------------------------------------

local ADDON, Tomo = ...

local function ApplyHideTalkingHead()
    if not TalkingHeadFrame then return end

    TalkingHeadFrame:UnregisterAllEvents()
    TalkingHeadFrame:SetScript("OnShow", TalkingHeadFrame.Hide)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", ApplyHideTalkingHead)
