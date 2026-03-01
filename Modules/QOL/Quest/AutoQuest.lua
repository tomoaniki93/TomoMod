-- =====================================
-- Quest/AutoQuest.lua
-- Automatisation des quêtes — version améliorée
--
-- Améliorations vs version précédente :
--   • QUEST_ACCEPT_CONFIRM géré (quêtes d'escorte / partagées)
--   • QUEST_GREETING géré (PNJ legacy à plusieurs quêtes)
--   • Dual API : C_QuestLog / C_GossipInfo + fallback legacy
--   • AutoSelectGossip sélectionne turn-in en priorité sur accept
--   • GetQuestReward(GetNumQuestChoices()) — index correct (pas hardcodé 1)
--   • Alt key bypass au lieu de Shift (plus ergonomique au clavier)
--   • Suppression des C_Timer.After et des hooks de frames (event-driven pur)
-- =====================================

TomoMod_AutoQuest = TomoMod_AutoQuest or {}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

local function GetDB()
    return TomoModDB and TomoModDB.autoQuest
end

frame:SetScript("OnEvent", function(self, event, ...)
    local db = GetDB()
    if not db then return end

    -- ─── Initialisation ────────────────────────────────────────────────────
    if event == "PLAYER_LOGIN" then
        self:RegisterEvent("QUEST_DETAIL")
        self:RegisterEvent("QUEST_PROGRESS")
        self:RegisterEvent("QUEST_COMPLETE")
        self:RegisterEvent("QUEST_ACCEPT_CONFIRM")
        self:RegisterEvent("QUEST_GREETING")
        self:RegisterEvent("GOSSIP_SHOW")
        self:UnregisterEvent("PLAYER_LOGIN")
        return
    end

    -- Maintenir Alt enfoncé pour bypasser toute automation
    if IsAltKeyDown() then return end

    -- ─── Auto-accepter ─────────────────────────────────────────────────────
    if event == "QUEST_DETAIL" then
        if not db.autoAccept then return end
        if QuestGetAutoAccept() then
            CloseQuest()           -- Quête auto-acceptée côté serveur
        else
            AcceptQuest()
        end
        return
    end

    -- Quêtes d'escorte / partagées (confirmation explicite)
    if event == "QUEST_ACCEPT_CONFIRM" then
        if not db.autoAccept then return end
        ConfirmAcceptQuest()
        StaticPopup_Hide("QUEST_ACCEPT")
        return
    end

    -- ─── Auto-rendre ───────────────────────────────────────────────────────
    if event == "QUEST_PROGRESS" then
        if not db.autoTurnIn then return end
        if IsQuestCompletable() then CompleteQuest() end
        return
    end

    if event == "QUEST_COMPLETE" then
        if not db.autoTurnIn then return end
        -- Ne pas auto-compléter si plusieurs choix de récompense
        if GetNumQuestChoices() <= 1 then
            GetQuestReward(GetNumQuestChoices())
        end
        return
    end

    -- ─── Auto-sélection gossip / greeting ──────────────────────────────────
    if event == "GOSSIP_SHOW" or event == "QUEST_GREETING" then
        if not db.autoGossip then return end

        if event == "QUEST_GREETING" then
            -- Priorité : rendre une quête complétée
            if db.autoTurnIn then
                local activeQuests = C_QuestLog.GetActiveQuests and C_QuestLog.GetActiveQuests()
                if activeQuests then
                    for _, q in ipairs(activeQuests) do
                        if q.isComplete and q.questID then
                            C_GossipInfo.SelectActiveQuest(q.questID); return
                        end
                    end
                else
                    for i = 1, GetNumActiveQuests() do
                        local _, isComplete = GetActiveTitle(i)
                        if isComplete then SelectActiveQuest(i); return end
                    end
                end
            end
            -- Sinon : accepter une nouvelle quête
            if db.autoAccept then
                local availQuests = C_QuestLog.GetAvailableQuests and C_QuestLog.GetAvailableQuests()
                if availQuests then
                    for _, q in ipairs(availQuests) do
                        if q.questID then
                            C_GossipInfo.SelectAvailableQuest(q.questID); return
                        end
                    end
                else
                    if GetNumAvailableQuests() > 0 then SelectAvailableQuest(1); return end
                end
            end
            return
        end

        -- GOSSIP_SHOW — C_GossipInfo API uniquement
        if db.autoTurnIn then
            local activeQuests = C_GossipInfo.GetActiveQuests()
            for _, q in ipairs(activeQuests) do
                if q.isComplete and q.questID then
                    C_GossipInfo.SelectActiveQuest(q.questID); return
                end
            end
        end
        if db.autoAccept then
            local availQuests = C_GossipInfo.GetAvailableQuests()
            for _, q in ipairs(availQuests) do
                if q.questID then
                    C_GossipInfo.SelectAvailableQuest(q.questID); return
                end
            end
        end
        return
    end
end)

function TomoMod_AutoQuest.Initialize()
    -- L'initialisation se fait via PLAYER_LOGIN
end