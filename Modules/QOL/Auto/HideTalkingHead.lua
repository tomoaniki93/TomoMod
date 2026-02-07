--------------------------------------------------
-- Tomo : HideTalkingHead
-- TalkingHeadFrame est charge a la demande via
-- Blizzard_TalkingHeadUI, on attend ADDON_LOADED.
--------------------------------------------------

local function ApplyHideTalkingHead()
    if not TalkingHeadFrame then return end

    TalkingHeadFrame:UnregisterAllEvents()
    TalkingHeadFrame:SetScript("OnShow", TalkingHeadFrame.Hide)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_TalkingHeadUI" then
        ApplyHideTalkingHead()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
