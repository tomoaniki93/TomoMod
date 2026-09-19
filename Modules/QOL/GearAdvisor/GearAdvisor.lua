-- =====================================================================
-- GearAdvisor.lua — TomoGear lightweight equipment advisor
-- ---------------------------------------------------------------------
-- Original TomoMod implementation inspired by the general idea of weighted
-- item comparison. No Pawn code or scale data is included.
--
-- Midnight safety:
--   * never touches World Quest / Encounter Journal / comparison tooltips;
--   * never evaluates uncached bag upgrades for the first time in combat;
--   * never hooks secure bag-button input scripts.
-- =====================================================================

TomoMod_GearAdvisor = TomoMod_GearAdvisor or {}
local GA = TomoMod_GearAdvisor

local Scales = TomoMod_GearAdvisorScales or {}
local issecretvalue = issecretvalue

local DEFAULTS = {
    enabled = false,
    mode = "automatic",
    showTooltip = true,
    showBagArrow = true,
    showScores = false,
    minUpgradePercent = 1.0,
    itemLevelWeight = 8.0,
    custom = {},
}

local LOCALE = {
    enUS = {
        tab = "Gear Advisor", section = "TomoGear Advisor",
        desc = "Lightweight gear comparison for quick in-game decisions. Automatic mode uses conservative role-based weights; special effects, set bonuses and complex trinket procs are not simulated.",
        enable = "Enable TomoGear Advisor", tooltip = "Show advice in item tooltips",
        bags = "Show upgrade arrow in TomoMod bags", scores = "Show numeric scores in tooltips",
        mode = "Scoring mode", automatic = "Automatic", custom = "Custom",
        threshold = "Minimum upgrade shown (%)", weights = "Custom weights for the current specialization",
        primary = "Primary stat", stamina = "Stamina", crit = "Critical Strike", haste = "Haste",
        mastery = "Mastery", versatility = "Versatility", reset = "Reset current specialization weights",
        profile = "Current profile: %s", newslot = "empty slot", upgrade = "upgrade",
        score = "score %.0f vs %.0f", note = "Special effects and set bonuses are not simulated.",
    },
    frFR = {
        tab = "Conseiller équipement", section = "Conseiller TomoGear",
        desc = "Comparaison légère d'équipement pour décider rapidement en jeu. Le mode Automatique utilise des poids prudents selon le rôle ; les effets spéciaux, bonus d'ensemble et procs complexes de bijoux ne sont pas simulés.",
        enable = "Activer le conseiller TomoGear", tooltip = "Afficher le conseil dans les infobulles d'objet",
        bags = "Afficher une flèche d'amélioration dans les sacs TomoMod", scores = "Afficher les scores numériques dans les infobulles",
        mode = "Mode de calcul", automatic = "Automatique", custom = "Personnalisé",
        threshold = "Amélioration minimale affichée (%)", weights = "Poids personnalisés pour la spécialisation actuelle",
        primary = "Caractéristique principale", stamina = "Endurance", crit = "Coup critique", haste = "Hâte",
        mastery = "Maîtrise", versatility = "Polyvalence", reset = "Réinitialiser les poids de la spécialisation",
        profile = "Profil actuel : %s", newslot = "emplacement vide", upgrade = "amélioration",
        score = "score %.0f contre %.0f", note = "Les effets spéciaux et bonus d'ensemble ne sont pas simulés.",
    },
    deDE = {
        tab = "Ausrüstungsberater", section = "TomoGear-Berater",
        desc = "Leichte Ausrüstungsvergleiche für schnelle Entscheidungen. Automatik nutzt vorsichtige rollenbasierte Gewichtungen; Spezialeffekte, Setboni und komplexe Schmuck-Procs werden nicht simuliert.",
        enable = "TomoGear-Berater aktivieren", tooltip = "Hinweise in Gegenstands-Tooltips anzeigen",
        bags = "Upgrade-Pfeil in TomoMod-Taschen anzeigen", scores = "Numerische Werte in Tooltips anzeigen",
        mode = "Wertungsmodus", automatic = "Automatisch", custom = "Benutzerdefiniert",
        threshold = "Minimales angezeigtes Upgrade (%)", weights = "Benutzerdefinierte Gewichte der aktuellen Spezialisierung",
        primary = "Primärattribut", stamina = "Ausdauer", crit = "Kritischer Treffer", haste = "Tempo",
        mastery = "Meisterschaft", versatility = "Vielseitigkeit", reset = "Gewichte der Spezialisierung zurücksetzen",
        profile = "Aktuelles Profil: %s", newslot = "leerer Platz", upgrade = "Upgrade",
        score = "Wert %.0f vs. %.0f", note = "Spezialeffekte und Setboni werden nicht simuliert.",
    },
    esES = {
        tab = "Asesor de equipo", section = "Asesor TomoGear",
        desc = "Comparación ligera de equipo para decisiones rápidas. El modo Automático usa pesos conservadores según el rol; no simula efectos especiales, bonus de conjunto ni procs complejos de abalorios.",
        enable = "Activar el asesor TomoGear", tooltip = "Mostrar consejo en las descripciones de objetos",
        bags = "Mostrar flecha de mejora en las bolsas de TomoMod", scores = "Mostrar puntuaciones numéricas en las descripciones",
        mode = "Modo de puntuación", automatic = "Automático", custom = "Personalizado",
        threshold = "Mejora mínima mostrada (%)", weights = "Pesos personalizados para la especialización actual",
        primary = "Estadística principal", stamina = "Aguante", crit = "Golpe crítico", haste = "Celeridad",
        mastery = "Maestría", versatility = "Versatilidad", reset = "Restablecer pesos de la especialización",
        profile = "Perfil actual: %s", newslot = "hueco vacío", upgrade = "mejora",
        score = "puntuación %.0f vs %.0f", note = "No se simulan efectos especiales ni bonus de conjunto.",
    },
    itIT = {
        tab = "Consigliere equip.", section = "Consigliere TomoGear",
        desc = "Confronto leggero dell'equipaggiamento per decisioni rapide. La modalità Automatica usa pesi prudenti in base al ruolo; effetti speciali, bonus set e proc complessi dei monili non sono simulati.",
        enable = "Attiva consigliere TomoGear", tooltip = "Mostra i consigli nei tooltip degli oggetti",
        bags = "Mostra freccia miglioramento nelle borse TomoMod", scores = "Mostra punteggi numerici nei tooltip",
        mode = "Modalità punteggio", automatic = "Automatica", custom = "Personalizzata",
        threshold = "Miglioramento minimo mostrato (%)", weights = "Pesi personalizzati per la specializzazione attuale",
        primary = "Stat primaria", stamina = "Tempra", crit = "Critico", haste = "Celerità",
        mastery = "Maestria", versatility = "Versatilità", reset = "Ripristina pesi della specializzazione",
        profile = "Profilo attuale: %s", newslot = "slot vuoto", upgrade = "miglioramento",
        score = "punteggio %.0f vs %.0f", note = "Effetti speciali e bonus set non sono simulati.",
    },
    ptBR = {
        tab = "Assistente de equipamento", section = "Assistente TomoGear",
        desc = "Comparação leve de equipamento para decisões rápidas. O modo Automático usa pesos conservadores por função; efeitos especiais, bônus de conjunto e procs complexos de berloques não são simulados.",
        enable = "Ativar Assistente TomoGear", tooltip = "Mostrar recomendação nas dicas de item",
        bags = "Mostrar seta de melhoria nas bolsas TomoMod", scores = "Mostrar pontuações numéricas nas dicas",
        mode = "Modo de pontuação", automatic = "Automático", custom = "Personalizado",
        threshold = "Melhoria mínima exibida (%)", weights = "Pesos personalizados para a especialização atual",
        primary = "Atributo primário", stamina = "Vigor", crit = "Acerto crítico", haste = "Aceleração",
        mastery = "Maestria", versatility = "Versatilidade", reset = "Redefinir pesos da especialização",
        profile = "Perfil atual: %s", newslot = "espaço vazio", upgrade = "melhoria",
        score = "pontuação %.0f vs %.0f", note = "Efeitos especiais e bônus de conjunto não são simulados.",
    },
}
LOCALE.esMX = LOCALE.esES

local SCORE_KEYS = {
    stamina = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_STAMINA" },
    crit = { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRIT_RATING" },
    haste = { "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_HASTE_RATING" },
    mastery = { "ITEM_MOD_MASTERY_RATING_SHORT", "ITEM_MOD_MASTERY_RATING" },
    versatility = { "ITEM_MOD_VERSATILITY", "ITEM_MOD_VERSATILITY_SHORT", "ITEM_MOD_VERSATILITY_RATING_SHORT" },
}
local PRIMARY_KEYS_BY_STAT = {
    [1] = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_STRENGTH" },
    [2] = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_AGILITY" },
    [4] = { "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_INTELLECT" },
}
local PRIMARY_FALLBACK_KEYS = {
    "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_STRENGTH",
    "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_AGILITY",
    "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_INTELLECT",
}

local SLOT_MAP = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_WEAPON = { 16 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 16 }, INVTYPE_RANGEDRIGHT = { 16 }, INVTYPE_THROWN = { 16 },
}

local scoreCache = {}
local upgradeCache = {}
local generation = 0

local function SafeNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "number" then return nil end
    return value
end

local function SafeString(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "string" then return nil end
    return value
end

local function CopyWeights(src)
    return {
        primary = tonumber(src and src.primary) or 1.00,
        stamina = tonumber(src and src.stamina) or 0.00,
        crit = tonumber(src and src.crit) or 0.65,
        haste = tonumber(src and src.haste) or 0.65,
        mastery = tonumber(src and src.mastery) or 0.65,
        versatility = tonumber(src and src.versatility) or 0.65,
    }
end

local function FirstStat(stats, keys)
    if type(stats) ~= "table" then return 0 end
    for _, key in ipairs(keys) do
        local value = SafeNumber(stats[key])
        if value then return value end
    end
    return 0
end

local function PrimaryStat(stats, primaryStat)
    if type(stats) ~= "table" then return 0 end

    -- GetSpecializationInfo returns the specialization's real primary-stat
    -- index (1 Strength, 2 Agility, 4 Intellect). Scoring only that stat is
    -- important for hybrid classes: an Intellect mail piece must not gain
    -- "primary" value while the player is in an Agility specialization.
    local keys = PRIMARY_KEYS_BY_STAT[tonumber(primaryStat)]
    if keys then return FirstStat(stats, keys) end

    local best = 0
    for _, key in ipairs(PRIMARY_FALLBACK_KEYS) do
        local value = SafeNumber(stats[key])
        if value and value > best then best = value end
    end
    return best
end

local function CurrentSpec()
    local index = GetSpecialization and GetSpecialization()
    if not index or not GetSpecializationInfo then return 0, "No specialization", "NONE", nil end
    local specID, name, _, _, role, primaryStat = GetSpecializationInfo(index)
    return tonumber(specID) or 0, name or "Specialization", role or "NONE", tonumber(primaryStat)
end

local function EnsureDB()
    if not TomoModDB then return nil end
    local db = TomoModDB.gearAdvisor
    if type(db) ~= "table" then
        db = {}
        TomoModDB.gearAdvisor = db
    end
    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then db[key] = {} else db[key] = value end
        end
    end
    if type(db.custom) ~= "table" then db.custom = {} end
    return db
end

function GA.L(key)
    local loc = GetLocale and GetLocale() or "enUS"
    local tbl = LOCALE[loc] or LOCALE.enUS
    return tbl[key] or LOCALE.enUS[key] or key
end

function GA:GetSettings()
    return EnsureDB()
end

function GA:GetCurrentProfileName()
    local _, name, role = CurrentSpec()
    return string.format("%s · %s", name, role)
end

function GA:GetAutomaticWeights()
    local _, _, role = CurrentSpec()
    return CopyWeights(Scales[role] or Scales.NONE or DEFAULTS)
end

function GA:GetCustomWeights()
    local db = EnsureDB()
    if not db then return CopyWeights(Scales.NONE) end
    local specID = CurrentSpec()
    local current = db.custom[specID]
    if type(current) ~= "table" then
        current = self:GetAutomaticWeights()
        db.custom[specID] = current
    end
    return current
end

function GA:GetWeights()
    local db = EnsureDB()
    if db and db.mode == "custom" then return self:GetCustomWeights() end
    return self:GetAutomaticWeights()
end

function GA:ResetCurrentSpecWeights()
    local db = EnsureDB()
    if not db then return end
    local specID = CurrentSpec()
    db.custom[specID] = CopyWeights(self:GetAutomaticWeights())
    self:ApplySettings()
end

local function ItemLevel(itemLink)
    if not itemLink or not C_Item or not C_Item.GetDetailedItemLevelInfo then return 0 end
    local ok, level = pcall(C_Item.GetDetailedItemLevelInfo, itemLink)
    if not ok then return 0 end
    return SafeNumber(level) or 0
end

local function ItemStats(itemLink)
    if not itemLink or not C_Item or not C_Item.GetItemStats then return nil end
    local ok, stats = pcall(C_Item.GetItemStats, itemLink)
    if not ok or type(stats) ~= "table" then return nil end
    return stats
end

function GA:GetItemScore(itemLink)
    itemLink = SafeString(itemLink)
    if not itemLink then return nil end

    local db = EnsureDB()
    if not db then return nil end
    local cacheKey = tostring(generation) .. "|" .. itemLink
    local cached = scoreCache[cacheKey]
    if cached then return cached.score, cached.ilvl end

    -- First-time scoring during combat is deliberately avoided. Cached scores
    -- remain usable, which keeps bag visuals stable without asking Midnight's
    -- restricted item APIs for new data from a combat execution path.
    if InCombatLockdown and InCombatLockdown() then return nil end

    local ilvl = ItemLevel(itemLink)
    local stats = ItemStats(itemLink)
    if ilvl <= 0 and not stats then return nil end

    local weights = self:GetWeights()
    local _, _, _, primaryStat = CurrentSpec()
    local score = ilvl * (tonumber(db.itemLevelWeight) or DEFAULTS.itemLevelWeight)
    score = score + PrimaryStat(stats, primaryStat) * (tonumber(weights.primary) or 0)
    score = score + FirstStat(stats, SCORE_KEYS.stamina) * (tonumber(weights.stamina) or 0)
    score = score + FirstStat(stats, SCORE_KEYS.crit) * (tonumber(weights.crit) or 0)
    score = score + FirstStat(stats, SCORE_KEYS.haste) * (tonumber(weights.haste) or 0)
    score = score + FirstStat(stats, SCORE_KEYS.mastery) * (tonumber(weights.mastery) or 0)
    score = score + FirstStat(stats, SCORE_KEYS.versatility) * (tonumber(weights.versatility) or 0)

    local value = { score = score, ilvl = ilvl }
    scoreCache[cacheKey] = value
    return score, ilvl
end

local function EquipLocation(itemLink)
    if not C_Item or not C_Item.GetItemInfoInstant then return nil end
    local ok, _, _, _, equipLoc = pcall(C_Item.GetItemInfoInstant, itemLink)
    if not ok then return nil end
    return SafeString(equipLoc)
end

function GA:GetUpgradeInfo(itemLink)
    itemLink = SafeString(itemLink)
    if not itemLink then return nil end
    local db = EnsureDB()
    if not db or not db.enabled then return nil end

    local cacheKey = tostring(generation) .. "|upgrade|" .. itemLink
    local cached = upgradeCache[cacheKey]
    if cached then return cached end
    if InCombatLockdown and InCombatLockdown() then return nil end

    local equipLoc = EquipLocation(itemLink)
    local slots = equipLoc and SLOT_MAP[equipLoc]
    if not slots then return nil end

    if C_Item and C_Item.IsEquippableItem then
        local ok, equippable = pcall(C_Item.IsEquippableItem, itemLink)
        if ok and not (issecretvalue and issecretvalue(equippable)) and equippable == false then return nil end
    end

    local candidateScore, candidateIlvl = self:GetItemScore(itemLink)
    if not candidateScore or candidateScore <= 0 then return nil end

    local replaceScore, replaceLink, replaceSlot
    local emptySlot = false
    for _, slotID in ipairs(slots) do
        local equipped = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
        if not equipped then
            replaceScore, replaceLink, replaceSlot, emptySlot = 0, nil, slotID, true
            break
        end
        local equippedScore = self:GetItemScore(equipped)
        if equippedScore and (not replaceScore or equippedScore < replaceScore) then
            replaceScore, replaceLink, replaceSlot = equippedScore, equipped, slotID
        end
    end
    if replaceScore == nil then return nil end

    local percent
    if replaceScore > 0 then
        percent = ((candidateScore / replaceScore) - 1) * 100
    end
    local threshold = tonumber(db.minUpgradePercent) or DEFAULTS.minUpgradePercent
    local isUpgrade = emptySlot or (percent and percent >= threshold) or false

    local info = {
        isUpgrade = isUpgrade,
        percent = percent,
        score = candidateScore,
        equippedScore = replaceScore,
        candidateIlvl = candidateIlvl,
        equippedLink = replaceLink,
        slotID = replaceSlot,
        emptySlot = emptySlot,
        equipLoc = equipLoc,
    }
    upgradeCache[cacheKey] = info
    return info
end

function GA:GetBagUpgradeInfo(item)
    local db = EnsureDB()
    if not db or not db.enabled or db.showBagArrow == false then return nil end
    if not item or not item.hasItem or not item.link then return nil end

    local weapon = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
    local armor = Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4
    if item.classID ~= weapon and item.classID ~= armor then return nil end

    return self:GetUpgradeInfo(item.link)
end

function GA:IsBagArrowEnabled()
    local db = EnsureDB()
    return db and db.enabled and db.showBagArrow ~= false
end

local function RefreshBags()
    local bags = TomoMod_BagSkin
    if bags and bags.RequestRefresh then bags.RequestRefresh(false) end
end

function GA:Invalidate()
    generation = generation + 1
    wipe(scoreCache)
    wipe(upgradeCache)
end

function GA:ApplySettings()
    self:Invalidate()
    RefreshBags()
end

function GA.SetEnabled(enabled)
    local db = EnsureDB()
    if not db then return end
    db.enabled = enabled and true or false
    GA:ApplySettings()
end

local function AddTooltipAdvice(tooltip, itemLink)
    local db = EnsureDB()
    if not db or not db.enabled or db.showTooltip == false then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    if TomoMod_IsCompareOrMoneyTooltip and TomoMod_IsCompareOrMoneyTooltip(tooltip) then return end

    local info = GA:GetUpgradeInfo(itemLink)
    if not info then return end

    if info.isUpgrade then
        if info.emptySlot then
            tooltip:AddLine("|cff2e9dd8TomoGear|r  |cff31d158▲ " .. GA.L("newslot") .. "|r")
        elseif info.percent then
            tooltip:AddLine(string.format("|cff2e9dd8TomoGear|r  |cff31d158▲ +%.1f%% %s|r", info.percent, GA.L("upgrade")))
        end
    elseif db.showScores ~= true then
        return
    end

    if db.showScores == true and info.equippedScore and info.equippedScore > 0 then
        tooltip:AddLine(string.format("|cff9aa4af%s|r", string.format(GA.L("score"), info.score, info.equippedScore)))
    end

    C_Timer.After(0, function()
        if tooltip and tooltip.IsShown and tooltip:IsShown() then tooltip:Show() end
    end)
end

local function OnTooltipSetItem(tooltip)
    if not TooltipUtil or not TooltipUtil.GetDisplayedItem then return end
    local ok, _, link = pcall(TooltipUtil.GetDisplayedItem, tooltip)
    if not ok or not link then
        local ok2, _, fallback = pcall(tooltip.GetItem, tooltip)
        if ok2 then link = fallback end
    end
    link = SafeString(link)
    if link then AddTooltipAdvice(tooltip, link) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
    local db = EnsureDB()
    if not db or not db.enabled then return end
    GA:Invalidate()
    if event ~= "PLAYER_LOGIN" then RefreshBags() end
end)
