-- =====================================
-- AutoQuest.lua
-- =====================================

TomoMod_AutoQuest = {}
local autoQuestFrame

-- Auto-accepter les quêtes
local function AutoAcceptQuest()
    if not TomoModDB.autoQuest.autoAccept then return end
    if IsShiftKeyDown() then return end
    
    -- Accepter toutes les quêtes disponibles
    if QuestFrameDetailPanel and QuestFrameDetailPanel:IsShown() then
        AcceptQuest()
    end
end

-- Auto-compléter les quêtes
local function AutoTurnInQuest()
    if not TomoModDB.autoQuest.autoTurnIn then return end
    if IsShiftKeyDown() then return end
    
    -- Vérifier s'il y a plusieurs récompenses
    local numRewards = GetNumQuestChoices()
    
    if numRewards > 1 then
        -- Ne pas auto-compléter si plusieurs récompenses (laisse le joueur choisir)
        return
    end
    
    -- Compléter la quête
    if QuestFrameCompleteQuestButton and QuestFrameCompleteQuestButton:IsShown() then
        CompleteQuest()
    end
    
    -- Si une seule récompense ou aucune récompense, la récupérer
    if QuestFrameRewardPanel and QuestFrameRewardPanel:IsShown() then
        if numRewards <= 1 then
            GetQuestReward(1)
        end
    end
end

-- Auto-sélectionner les options de gossip
local function AutoSelectGossip()
    if not TomoModDB.autoQuest.autoGossip then return end
    if IsShiftKeyDown() then return end
    
    -- Sélectionner la première option de gossip liée aux quêtes
    local gossipOptions = C_GossipInfo.GetOptions()
    
    if gossipOptions then
        for i, option in ipairs(gossipOptions) do
            -- Vérifier si c'est une option de quête
            if option.type == "gossip" then
                C_GossipInfo.SelectOption(option.gossipOptionID)
                return
            end
        end
    end
end

-- Hook sur l'ouverture des frames de quêtes
local function HookQuestFrames()
    -- Hook pour auto-accepter
    if QuestFrameDetailPanel then
        QuestFrameDetailPanel:HookScript("OnShow", function()
            C_Timer.After(0.1, AutoAcceptQuest)
        end)
    end
    
    -- Hook pour auto-compléter
    if QuestFrameCompleteQuestButton then
        QuestFrameCompleteQuestButton:HookScript("OnShow", function()
            C_Timer.After(0.1, AutoTurnInQuest)
        end)
    end
    
    if QuestFrameRewardPanel then
        QuestFrameRewardPanel:HookScript("OnShow", function()
            C_Timer.After(0.1, AutoTurnInQuest)
        end)
    end
end

-- Gérer les événements de quêtes
local function SetupAutoQuest()
    if autoQuestFrame then return end
    
    autoQuestFrame = CreateFrame("Frame")
    
    -- Événements pour les quêtes
    autoQuestFrame:RegisterEvent("QUEST_DETAIL")
    autoQuestFrame:RegisterEvent("QUEST_PROGRESS")
    autoQuestFrame:RegisterEvent("QUEST_COMPLETE")
    autoQuestFrame:RegisterEvent("GOSSIP_SHOW")
    
    autoQuestFrame:SetScript("OnEvent", function(self, event, ...)
        if IsShiftKeyDown() then return end
        
        if event == "QUEST_DETAIL" then
            -- Quête proposée
            if TomoModDB.autoQuest.autoAccept then
                C_Timer.After(0.1, function()
                    if not IsShiftKeyDown() and QuestGetAutoAccept() ~= true then
                        AcceptQuest()
                    end
                end)
            end
            
        elseif event == "QUEST_PROGRESS" then
            -- Quête en cours de progression (vérifier si complétée)
            if IsQuestCompletable() and TomoModDB.autoQuest.autoTurnIn then
                C_Timer.After(0.1, function()
                    if not IsShiftKeyDown() then
                        CompleteQuest()
                    end
                end)
            end
            
        elseif event == "QUEST_COMPLETE" then
            -- Quête prête à être rendue
            if TomoModDB.autoQuest.autoTurnIn then
                local numRewards = GetNumQuestChoices()
                
                -- Ne pas auto-compléter si plusieurs choix de récompenses
                if numRewards <= 1 then
                    C_Timer.After(0.1, function()
                        if not IsShiftKeyDown() then
                            GetQuestReward(1)
                        end
                    end)
                end
            end
            
        elseif event == "GOSSIP_SHOW" then
            -- Options de dialogue
            if TomoModDB.autoQuest.autoGossip then
                C_Timer.After(0.2, function()
                    if not IsShiftKeyDown() then
                        AutoSelectGossip()
                    end
                end)
            end
        end
    end)
    
    -- Hook les frames pour plus de fiabilité
    C_Timer.After(1, function()
        if QuestFrameDetailPanel then
            HookQuestFrames()
        end
    end)
end

-- Initialisation du module
function TomoMod_AutoQuest.Initialize()
    SetupAutoQuest()
end