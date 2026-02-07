-- =====================================
-- AutoQuest.lua
-- =====================================

TomoMod_AutoQuest = {}
local autoQuestFrame
local lastProcessedTime = 0

-- Anti-doublon: evite de traiter le meme event 2 fois en < 0.5s
local function CanProcess()
    local now = GetTime()
    if now - lastProcessedTime < 0.5 then
        return false
    end
    lastProcessedTime = now
    return true
end

-- Auto-selectionner les options de gossip
local function AutoSelectGossip()
    if not TomoModDB or not TomoModDB.autoQuest then return end
    if not TomoModDB.autoQuest.autoGossip then return end
    if IsShiftKeyDown() then return end

    local gossipOptions = C_GossipInfo.GetOptions()

    if gossipOptions then
        for i, option in ipairs(gossipOptions) do
            if option.type == "gossip" then
                C_GossipInfo.SelectOption(option.gossipOptionID)
                return
            end
        end
    end
end

-- Gerer les evenements de quetes
local function SetupAutoQuest()
    if autoQuestFrame then return end

    autoQuestFrame = CreateFrame("Frame")

    autoQuestFrame:RegisterEvent("QUEST_DETAIL")
    autoQuestFrame:RegisterEvent("QUEST_PROGRESS")
    autoQuestFrame:RegisterEvent("QUEST_COMPLETE")
    autoQuestFrame:RegisterEvent("GOSSIP_SHOW")

    autoQuestFrame:SetScript("OnEvent", function(self, event, ...)
        if not TomoModDB or not TomoModDB.autoQuest then return end
        if IsShiftKeyDown() then return end

        if event == "QUEST_DETAIL" then
            if TomoModDB.autoQuest.autoAccept then
                C_Timer.After(0.1, function()
                    if not IsShiftKeyDown() and not CanProcess() then return end
                    if QuestGetAutoAccept and QuestGetAutoAccept() then return end
                    AcceptQuest()
                end)
            end

        elseif event == "QUEST_PROGRESS" then
            if IsQuestCompletable() and TomoModDB.autoQuest.autoTurnIn then
                C_Timer.After(0.1, function()
                    if not IsShiftKeyDown() and not CanProcess() then return end
                    CompleteQuest()
                end)
            end

        elseif event == "QUEST_COMPLETE" then
            if TomoModDB.autoQuest.autoTurnIn then
                local numRewards = GetNumQuestChoices()

                -- Ne pas auto-completer si plusieurs choix de recompenses
                if numRewards <= 1 then
                    C_Timer.After(0.1, function()
                        if not IsShiftKeyDown() and not CanProcess() then return end
                        -- Si 1 recompense, la selectionner; si 0, appeler sans index
                        if numRewards == 1 then
                            GetQuestReward(1)
                        else
                            GetQuestReward()
                        end
                    end)
                end
            end

        elseif event == "GOSSIP_SHOW" then
            if TomoModDB.autoQuest.autoGossip then
                C_Timer.After(0.2, function()
                    if not IsShiftKeyDown() then
                        AutoSelectGossip()
                    end
                end)
            end
        end
    end)
end

-- Initialisation du module
function TomoMod_AutoQuest.Initialize()
    SetupAutoQuest()
end
