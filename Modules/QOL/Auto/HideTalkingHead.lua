--------------------------------------------------
-- Tomo : HideTalkingHead
--------------------------------------------------

local ADDON, Tomo = ...

local applied = false

local function ApplyHideTalkingHead()
    if applied then return end
    if not TalkingHeadFrame then return end
    applied = true

    TalkingHeadFrame:UnregisterAllEvents()
    TalkingHeadFrame:HookScript("OnShow", function(self)
        if not InCombatLockdown() then
            self:Hide()
        end
    end)
    if not InCombatLockdown() then
        TalkingHeadFrame:Hide()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", ApplyHideTalkingHead)
