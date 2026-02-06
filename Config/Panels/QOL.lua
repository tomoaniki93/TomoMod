-- =====================================
-- Panels/QOL.lua — QOL Modules Config
-- =====================================

local W = TomoMod_Widgets

function TomoMod_ConfigPanel_QOL(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child

    local y = -10

    -- CINEMATIC SKIP
    local _, ny = W.CreateSectionHeader(c, "Cinematic Skip", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Skip automatique après 1ère vue", TomoModDB.cinematicSkip.enabled, y, function(v)
        TomoModDB.cinematicSkip.enabled = v
        if v and TomoMod_CinematicSkip then TomoMod_CinematicSkip.Initialize() end
    end)
    y = ny

    local viewedStr = "0"
    if TomoMod_CinematicSkip and TomoMod_CinematicSkip.GetViewedCount then
        viewedStr = tostring(TomoMod_CinematicSkip.GetViewedCount())
    end
    local _, ny = W.CreateInfoText(c, "Cinématiques déjà vues: " .. viewedStr .. "\nL'historique est partagé entre personnages.", y)
    y = ny

    local _, ny = W.CreateButton(c, "Effacer l'historique", 180, y, function()
        if TomoMod_CinematicSkip then TomoMod_CinematicSkip.ClearHistory() end
    end)
    y = ny

    -- AUTO QUEST
    local _, ny = W.CreateSectionHeader(c, "Auto Quest", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Auto-accepter les quêtes", TomoModDB.autoQuest.autoAccept, y, function(v)
        TomoModDB.autoQuest.autoAccept = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Auto-compléter les quêtes", TomoModDB.autoQuest.autoTurnIn, y, function(v)
        TomoModDB.autoQuest.autoTurnIn = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Auto-sélectionner les dialogues", TomoModDB.autoQuest.autoGossip, y, function(v)
        TomoModDB.autoQuest.autoGossip = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, "Maintenez SHIFT pour désactiver temporairement.\nLes quêtes avec choix multiples ne sont pas auto-complétées.", y)
    y = ny

    -- AUTO VENDOR/REPAIR
    local _, ny = W.CreateSectionHeader(c, "Automatisations", y)
    y = ny

    -- HideCastBar
    local _, ny = W.CreateCheckbox(c, "Cacher la barre de cast Blizzard", TomoModDB.hideCastBar.enabled, y, function(v)
        if TomoMod_HideCastBar then TomoMod_HideCastBar.SetEnabled(v) end
    end)
    y = ny

    -- Auto Accept Invite
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, "— Auto Accept Invite —", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer", TomoModDB.autoAcceptInvite.enabled, y, function(v)
        TomoModDB.autoAcceptInvite.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Accepter des amis", TomoModDB.autoAcceptInvite.acceptFriends, y, function(v)
        TomoModDB.autoAcceptInvite.acceptFriends = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Accepter de la guilde", TomoModDB.autoAcceptInvite.acceptGuild, y, function(v)
        TomoModDB.autoAcceptInvite.acceptGuild = v
    end)
    y = ny

    -- Auto Summon
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, "— Auto Summon —", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer", TomoModDB.autoSummon.enabled, y, function(v)
        TomoModDB.autoSummon.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Accepter des amis", TomoModDB.autoSummon.acceptFriends, y, function(v)
        TomoModDB.autoSummon.acceptFriends = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Accepter de la guilde", TomoModDB.autoSummon.acceptGuild, y, function(v)
        TomoModDB.autoSummon.acceptGuild = v
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Délai (secondes)", TomoModDB.autoSummon.delaySec, 0, 10, 1, y, function(v)
        TomoModDB.autoSummon.delaySec = v
    end)
    y = ny

    -- Auto Fill Delete
    local _, ny = W.CreateSeparator(c, y)
    y = ny
    local _, ny = W.CreateSubLabel(c, "— Auto Fill Delete —", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer", TomoModDB.autoFillDelete.enabled, y, function(v)
        TomoModDB.autoFillDelete.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Focus sur OK après remplissage", TomoModDB.autoFillDelete.focusButton, y, function(v)
        TomoModDB.autoFillDelete.focusButton = v
    end)
    y = ny

    -- MYTHIC KEYS
    local _, ny = W.CreateSectionHeader(c, "Mythic+ Keys", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer le tracker", TomoModDB.MythicKeys.enabled, y, function(v)
        TomoModDB.MythicKeys.enabled = v
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Mini-frame sur l'UI M+", TomoModDB.MythicKeys.miniFrame, y, function(v)
        TomoModDB.MythicKeys.miniFrame = v
        if MK and MK.UpdateMiniFrame then MK:UpdateMiniFrame() end
    end)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Actualisation automatique", TomoModDB.MythicKeys.autoRefresh, y, function(v)
        TomoModDB.MythicKeys.autoRefresh = v
    end)
    y = ny

    -- SKYRIDE
    local _, ny = W.CreateSectionHeader(c, "SkyRide", y)
    y = ny

    local _, ny = W.CreateCheckbox(c, "Activer (affichage en vol)", TomoModDB.skyRide.enabled, y, function(v)
        if TomoMod_SkyRide and TomoMod_SkyRide.SetEnabled then
            TomoMod_SkyRide.SetEnabled(v)
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Largeur", TomoModDB.skyRide.width, 100, 600, 10, y, function(v)
        TomoModDB.skyRide.width = v
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Hauteur barre", TomoModDB.skyRide.height, 10, 40, 1, y, function(v)
        TomoModDB.skyRide.height = v
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateSlider(c, "Taille police", TomoModDB.skyRide.fontSize, 8, 24, 1, y, function(v)
        TomoModDB.skyRide.fontSize = v
        if TomoMod_SkyRide and TomoMod_SkyRide.ApplySettings then
            TomoMod_SkyRide.ApplySettings()
        end
    end)
    y = ny

    local _, ny = W.CreateButton(c, "Reset Position SkyRide", 200, y, function()
        if TomoMod_SkyRide and TomoMod_SkyRide.ResetPosition then
            TomoMod_SkyRide.ResetPosition()
        end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 20)
    return scroll
end
