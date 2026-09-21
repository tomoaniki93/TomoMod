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

-- Use Blizzard atlas markup instead of a Unicode triangle. The Poppins/UI
-- font used by TomoMod does not contain every geometric glyph, which could
-- render the old ▲ marker as a missing-character box in item tooltips.
local UPGRADE_MARK = "|A:bags-greenarrow:12:12:0:0|a"

local DEFAULTS = {
    enabled = false,
    mode = "automatic",
    showTooltip = true,
    showBagArrow = true,
    showScores = false,
    minUpgradePercent = 1.0,
    itemLevelWeight = 8.0,
    custom = {},
    imported = {},
}

local LOCALE = {
    enUS = {
        tab = "Gear Advisor", section = "TomoGear Advisor",
        desc = "Lightweight gear comparison for quick in-game decisions. Automatic mode uses conservative role-based weights; special effects, set bonuses and complex trinket procs are not simulated.",
        enable = "Enable TomoGear Advisor", tooltip = "Show advice in item tooltips",
        bags = "Show upgrade arrow in TomoMod bags", scores = "Show numeric scores in tooltips",
        mode = "Scoring mode", automatic = "Automatic", custom = "Custom", imported = "Imported",
        import_title = "Import stat weights",
        import_desc = "Paste a Pawn v1 / Ask Mr. Robot scale or compatible key=value text. TomoGear imports your primary stat, Stamina, Crit, Haste, Mastery and Versatility. Unsupported values are ignored. Item level has no extra weight unless ItemLevel= is present.",
        import_box = "Pawn / AMR scale", import_button = "Import for current specialization", import_clear = "Remove imported profile",
        import_none = "No imported profile for the current specialization.",
        import_ok = "Imported '%s': %d supported weights%s.", import_ignored = " · %d unsupported ignored",
        import_fail = "Import failed: no supported stat weights were found.",
        import_wrong_class = "Import refused: this scale is for %s.", import_wrong_spec = "Import refused: this scale is for %s.",
        import_wrong_primary = "Import refused: the primary stat does not match the current specialization.",
        import_active = "Imported profile: %s · %s",
        threshold = "Minimum bag upgrade arrow (%)", weights = "Custom weights for the current specialization",
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
        mode = "Mode de calcul", automatic = "Automatique", custom = "Personnalisé", imported = "Importé",
        import_title = "Importer des Stat Weights",
        import_desc = "Colle une chaîne Pawn v1 / Ask Mr. Robot ou un texte key=value compatible. TomoGear importe la caractéristique principale, l'Endurance, le Critique, la Hâte, la Maîtrise et la Polyvalence. Les valeurs non prises en charge sont ignorées. Le niveau d'objet n'ajoute aucun poids sauf si ItemLevel= est présent.",
        import_box = "Échelle Pawn / AMR", import_button = "Importer pour la spécialisation actuelle", import_clear = "Supprimer le profil importé",
        import_none = "Aucun profil importé pour la spécialisation actuelle.",
        import_ok = "Profil '%s' importé : %d poids pris en charge%s.", import_ignored = " · %d non pris en charge ignorés",
        import_fail = "Import impossible : aucun poids de statistique pris en charge n'a été trouvé.",
        import_wrong_class = "Import refusé : cette échelle est prévue pour %s.", import_wrong_spec = "Import refusé : cette échelle est prévue pour %s.",
        import_wrong_primary = "Import refusé : la caractéristique principale ne correspond pas à la spécialisation actuelle.",
        import_active = "Profil importé : %s · %s",
        threshold = "Seuil de la flèche d’amélioration dans les sacs (%)", weights = "Poids personnalisés pour la spécialisation actuelle",
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
        mode = "Wertungsmodus", automatic = "Automatisch", custom = "Benutzerdefiniert", imported = "Importiert",
        import_title = "Stat-Gewichtungen importieren",
        import_desc = "Füge eine Pawn-v1-/Ask-Mr.-Robot-Skala oder kompatiblen key=value-Text ein. TomoGear importiert Primärattribut, Ausdauer, Krit, Tempo, Meisterschaft und Vielseitigkeit. Nicht unterstützte Werte werden ignoriert. Gegenstandsstufe erhält nur Gewicht, wenn ItemLevel= vorhanden ist.",
        import_box = "Pawn-/AMR-Skala", import_button = "Für aktuelle Spezialisierung importieren", import_clear = "Importiertes Profil entfernen",
        import_none = "Kein importiertes Profil für die aktuelle Spezialisierung.",
        import_ok = "'%s' importiert: %d unterstützte Gewichtungen%s.", import_ignored = " · %d nicht unterstützte ignoriert",
        import_fail = "Import fehlgeschlagen: keine unterstützten Stat-Gewichtungen gefunden.",
        import_wrong_class = "Import abgelehnt: diese Skala ist für %s.", import_wrong_spec = "Import abgelehnt: diese Skala ist für %s.",
        import_wrong_primary = "Import abgelehnt: das Primärattribut passt nicht zur aktuellen Spezialisierung.",
        import_active = "Importiertes Profil: %s · %s",
        threshold = "Mindestwert für Taschen-Upgradepfeil (%)", weights = "Benutzerdefinierte Gewichte der aktuellen Spezialisierung",
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
        mode = "Modo de puntuación", automatic = "Automático", custom = "Personalizado", imported = "Importado",
        import_title = "Importar pesos de estadísticas",
        import_desc = "Pega una escala Pawn v1 / Ask Mr. Robot o texto key=value compatible. TomoGear importa estadística principal, Aguante, Crítico, Celeridad, Maestría y Versatilidad. Los valores no compatibles se ignoran. El nivel de objeto no añade peso salvo que exista ItemLevel=.",
        import_box = "Escala Pawn / AMR", import_button = "Importar para la especialización actual", import_clear = "Eliminar perfil importado",
        import_none = "No hay perfil importado para la especialización actual.",
        import_ok = "'%s' importado: %d pesos compatibles%s.", import_ignored = " · %d no compatibles ignorados",
        import_fail = "Error de importación: no se encontraron pesos de estadísticas compatibles.",
        import_wrong_class = "Importación rechazada: esta escala es para %s.", import_wrong_spec = "Importación rechazada: esta escala es para %s.",
        import_wrong_primary = "Importación rechazada: la estadística principal no coincide con la especialización actual.",
        import_active = "Perfil importado: %s · %s",
        threshold = "Mejora mínima para la flecha de bolsa (%)", weights = "Pesos personalizados para la especialización actual",
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
        mode = "Modalità punteggio", automatic = "Automatica", custom = "Personalizzata", imported = "Importata",
        import_title = "Importa pesi statistiche",
        import_desc = "Incolla una scala Pawn v1 / Ask Mr. Robot o testo key=value compatibile. TomoGear importa statistica primaria, Tempra, Critico, Celerità, Maestria e Versatilità. I valori non supportati vengono ignorati. Il livello oggetto non aggiunge peso salvo ItemLevel=.",
        import_box = "Scala Pawn / AMR", import_button = "Importa per la specializzazione attuale", import_clear = "Rimuovi profilo importato",
        import_none = "Nessun profilo importato per la specializzazione attuale.",
        import_ok = "Importato '%s': %d pesi supportati%s.", import_ignored = " · %d non supportati ignorati",
        import_fail = "Importazione fallita: nessun peso statistica supportato trovato.",
        import_wrong_class = "Importazione rifiutata: questa scala è per %s.", import_wrong_spec = "Importazione rifiutata: questa scala è per %s.",
        import_wrong_primary = "Importazione rifiutata: la statistica primaria non corrisponde alla specializzazione attuale.",
        import_active = "Profilo importato: %s · %s",
        threshold = "Miglioramento minimo per la freccia nelle borse (%)", weights = "Pesi personalizzati per la specializzazione attuale",
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
        mode = "Modo de pontuação", automatic = "Automático", custom = "Personalizado", imported = "Importado",
        import_title = "Importar pesos de atributos",
        import_desc = "Cole uma escala Pawn v1 / Ask Mr. Robot ou texto key=value compatível. TomoGear importa atributo primário, Vigor, Crítico, Aceleração, Maestria e Versatilidade. Valores não suportados são ignorados. O nível do item não ganha peso extra salvo se ItemLevel= estiver presente.",
        import_box = "Escala Pawn / AMR", import_button = "Importar para a especialização atual", import_clear = "Remover perfil importado",
        import_none = "Nenhum perfil importado para a especialização atual.",
        import_ok = "'%s' importado: %d pesos suportados%s.", import_ignored = " · %d não suportados ignorados",
        import_fail = "Falha na importação: nenhum peso de atributo suportado foi encontrado.",
        import_wrong_class = "Importação recusada: esta escala é para %s.", import_wrong_spec = "Importação recusada: esta escala é para %s.",
        import_wrong_primary = "Importação recusada: o atributo primário não corresponde à especialização atual.",
        import_active = "Perfil importado: %s · %s",
        threshold = "Melhoria mínima para a seta nas bolsas (%)", weights = "Pesos personalizados para a especialização atual",
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

local IMPORT_ALIASES = {
    strength = "strength", str = "strength",
    agility = "agility", agi = "agility",
    intellect = "intellect", int = "intellect",
    stamina = "stamina", sta = "stamina",
    crit = "crit", critrating = "crit", criticalstrike = "crit", criticalstrikerating = "crit",
    haste = "haste", hasterating = "haste",
    mastery = "mastery", masteryrating = "mastery",
    versatility = "versatility", versatilityrating = "versatility", vers = "versatility",
    itemlevel = "itemLevel", ilvl = "itemLevel",
}

local PRIMARY_IMPORT_KEY = { [1] = "strength", [2] = "agility", [4] = "intellect" }

-- English Pawn scale tags use English spec names even on non-English clients.
-- Resolve them inside the player's class so ambiguous names such as Frost,
-- Holy, Protection and Restoration remain unambiguous. Unknown future specs
-- are accepted rather than rejected.
local SPEC_ALIAS_BY_CLASS = {
    DEATHKNIGHT = { blood = 250, frost = 251, unholy = 252 },
    DEMONHUNTER = { havoc = 577, vengeance = 581 },
    DRUID = { balance = 102, feral = 103, guardian = 104, restoration = 105 },
    EVOKER = { devastation = 1467, preservation = 1468, augmentation = 1473 },
    HUNTER = { beastmastery = 253, marksmanship = 254, survival = 255 },
    MAGE = { arcane = 62, fire = 63, frost = 64 },
    MONK = { brewmaster = 268, windwalker = 269, mistweaver = 270 },
    PALADIN = { holy = 65, protection = 66, retribution = 70 },
    PRIEST = { discipline = 256, holy = 257, shadow = 258 },
    ROGUE = { assassination = 259, outlaw = 260, subtlety = 261 },
    SHAMAN = { elemental = 262, enhancement = 263, restoration = 264 },
    WARLOCK = { affliction = 265, demonology = 266, destruction = 267 },
    WARRIOR = { arms = 71, fury = 72, protection = 73 },
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

local function MergeMissing(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    for key, value in pairs(src) do
        if dst[key] == nil then
            if type(value) == "table" then
                local copy = {}
                MergeMissing(copy, value)
                dst[key] = copy
            else
                dst[key] = value
            end
        elseif type(dst[key]) == "table" and type(value) == "table" then
            MergeMissing(dst[key], value)
        end
    end
end

local function EnsureDB()
    -- TomoGear owns its SavedVariables. Gear weights and advisor preferences
    -- therefore survive TomoMod profile changes/imports and do not pollute
    -- TomoModDB. Migrate the V1 table once for players already using it.
    if type(TomoGearDB) ~= "table" then TomoGearDB = {} end
    local db = TomoGearDB

    if db._migratedFromTomoMod ~= true then
        if TomoModDB and type(TomoModDB.gearAdvisor) == "table" then
            MergeMissing(db, TomoModDB.gearAdvisor)
        end
        db._migratedFromTomoMod = true
    end
    if TomoModDB and TomoModDB.gearAdvisor ~= nil then
        TomoModDB.gearAdvisor = nil
    end

    for key, value in pairs(DEFAULTS) do
        if db[key] == nil then
            if type(value) == "table" then db[key] = {} else db[key] = value end
        end
    end
    if type(db.custom) ~= "table" then db.custom = {} end
    if type(db.imported) ~= "table" then db.imported = {} end
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

local function Trim(value)
    if type(value) ~= "string" then return "" end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizeToken(value)
    value = Trim(tostring(value or "")):lower()
    return (value:gsub("[^%w]", ""))
end

local function StripQuotes(value)
    value = Trim(value)
    local quoted = value:match('^"(.*)"$')
    return quoted or value
end

local function ParseScaleAssignments(text)
    local pawnVersion, pawnName, body = text:match('^%s*%(%s*[Pp][Aa][Ww][Nn]%s*:%s*v(%d+)%s*:%s*"([^"]+)"%s*:%s*(.-)%s*%)%s*$')
    body = body or text

    local values, meta = {}, {}
    for part in body:gmatch("[^,]+") do
        local key, raw = part:match("^%s*([%a_][%w_]*)%s*=%s*(.-)%s*$")
        if key and raw and raw ~= "" then
            local norm = NormalizeToken(key)
            local number = tonumber(StripQuotes(raw))
            if number then values[norm] = number else meta[norm] = StripQuotes(raw) end
        end
    end
    return tonumber(pawnVersion), pawnName, values, meta
end

local function CurrentClassMatches(scaleClass)
    if not scaleClass or scaleClass == "" then return true end
    local localized, token
    if UnitClass then localized, token = UnitClass("player") end
    local wanted = NormalizeToken(scaleClass)
    return wanted == NormalizeToken(localized) or wanted == NormalizeToken(token)
end

local function ResolveScaleSpec(scaleSpec, localizedSpecName)
    if not scaleSpec or scaleSpec == "" then return nil end
    local direct = tonumber(scaleSpec)
    if direct then return direct end
    local norm = NormalizeToken(scaleSpec)
    if norm == NormalizeToken(localizedSpecName) then return CurrentSpec() end

    local classToken
    if UnitClass then _, classToken = UnitClass("player") end
    local aliases = classToken and SPEC_ALIAS_BY_CLASS[classToken]
    return aliases and aliases[norm] or nil
end

function GA:GetImportedProfile()
    local db = EnsureDB()
    if not db then return nil end
    local specID = CurrentSpec()
    local profile = db.imported[specID]
    return type(profile) == "table" and profile or nil
end

function GA:GetImportedSummary()
    local profile = self:GetImportedProfile()
    if not profile then return self.L("import_none") end
    local source = profile.source or self.L("imported")
    return string.format(self.L("import_active"), profile.name or self.L("imported"), source)
end

function GA:GetCurrentProfileName()
    local _, name, role = CurrentSpec()
    local db = EnsureDB()
    if db and db.mode == "imported" then
        local profile = self:GetImportedProfile()
        if profile then return string.format("%s · %s", profile.name or name, self.L("imported")) end
    end
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
    if db and db.mode == "imported" then
        local profile = self:GetImportedProfile()
        if profile and type(profile.weights) == "table" then return CopyWeights(profile.weights) end
    end
    return self:GetAutomaticWeights()
end

function GA:ImportWeights(text)
    text = Trim(text)
    if text == "" or #text > 16384 then return false, self.L("import_fail") end

    local specID, specName, _, primaryStat = CurrentSpec()
    if specID == 0 then return false, self.L("import_fail") end

    local pawnVersion, pawnName, values, meta = ParseScaleAssignments(text)
    local classTag = meta.class
    local specTag = meta.spec or (values.spec and tostring(values.spec))

    if classTag and not CurrentClassMatches(classTag) then
        return false, string.format(self.L("import_wrong_class"), classTag)
    end

    local taggedSpec = ResolveScaleSpec(specTag, specName)
    if taggedSpec and tonumber(taggedSpec) ~= specID then
        return false, string.format(self.L("import_wrong_spec"), specTag)
    end

    local parsed = { primary = 0, stamina = 0, crit = 0, haste = 0, mastery = 0, versatility = 0 }
    local provided, ignored = {}, {}
    local primaries = {}
    local itemLevelWeight = 0

    for rawKey, value in pairs(values) do
        if rawKey ~= "spec" then
            local key = IMPORT_ALIASES[rawKey]
            if key == "strength" or key == "agility" or key == "intellect" then
                primaries[key] = value
            elseif key == "itemLevel" then
                itemLevelWeight = value
                provided.itemLevel = true
            elseif key and parsed[key] ~= nil then
                parsed[key] = value
                provided[key] = true
            elseif rawKey ~= "class" then
                ignored[#ignored + 1] = rawKey
            end
        end
    end

    local expectedPrimary = PRIMARY_IMPORT_KEY[primaryStat]
    if expectedPrimary and primaries[expectedPrimary] ~= nil then
        parsed.primary = primaries[expectedPrimary]
        provided.primary = true
    elseif expectedPrimary then
        for key, value in pairs(primaries) do
            if key ~= expectedPrimary and value ~= 0 then
                return false, self.L("import_wrong_primary")
            end
        end
    else
        -- Unknown future primary-stat identifiers keep the former fallback,
        -- but select it deterministically instead of entering a loop that can
        -- only ever execute once.
        local fallbackPrimary = primaries.strength or primaries.agility or primaries.intellect
        if fallbackPrimary ~= nil then
            parsed.primary = fallbackPrimary
            provided.primary = true
        end
    end

    local count = 0
    for _ in pairs(provided) do count = count + 1 end
    if count == 0 then return false, self.L("import_fail") end

    local source = pawnVersion and ("Pawn v" .. tostring(pawnVersion)) or "key=value"
    local profileName = Trim(pawnName or "")
    if profileName == "" then profileName = specName .. " · " .. source end

    local db = EnsureDB()
    db.imported[specID] = {
        name = profileName, source = source, weights = parsed,
        itemLevelWeight = tonumber(itemLevelWeight) or 0, raw = text,
        class = classTag, spec = specTag, ignored = ignored, count = count,
    }
    db.mode = "imported"
    self:ApplySettings()

    local suffix = #ignored > 0 and string.format(self.L("import_ignored"), #ignored) or ""
    return true, string.format(self.L("import_ok"), profileName, count, suffix)
end

function GA:ClearImportedProfile()
    local db = EnsureDB()
    if not db then return self.L("import_none") end
    local specID = CurrentSpec()
    db.imported[specID] = nil
    if db.mode == "imported" then db.mode = "automatic" end
    self:ApplySettings()
    return self.L("import_none")
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
    local itemLevelWeight = tonumber(db.itemLevelWeight) or DEFAULTS.itemLevelWeight
    if db.mode == "imported" then
        local profile = self:GetImportedProfile()
        if profile then itemLevelWeight = tonumber(profile.itemLevelWeight) or 0 end
    end
    local score = ilvl * itemLevelWeight
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

local function SafeTooltipAddLine(tooltip, text)
    -- ItemRefTooltip can pass through the item post-processor while its runtime
    -- methods are not available to addon code on some Midnight builds. Calling
    -- AddLine blindly there produced "attempt to call a nil value" when a chat
    -- item link was opened. Keep the normal GameTooltip path, but feature-test
    -- the method and isolate the call for every tooltip implementation.
    if not tooltip or type(tooltip.AddLine) ~= "function" then return false end
    local ok = pcall(tooltip.AddLine, tooltip, text)
    return ok
end

local function AddTooltipAdvice(tooltip, itemLink)
    local db = EnsureDB()
    if not db or not db.enabled or db.showTooltip == false then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    if TomoMod_IsCompareOrMoneyTooltip and TomoMod_IsCompareOrMoneyTooltip(tooltip) then return end

    local info = GA:GetUpgradeInfo(itemLink)
    if not info then return end

    local line
    if info.emptySlot then
        line = "|cff2e9dd8TomoGear|r  " .. UPGRADE_MARK .. " |cff31d158" .. GA.L("newslot") .. "|r"
    elseif info.percent then
        local percent = math.abs(info.percent) < 0.05 and 0 or info.percent
        if percent > 0 then
            line = string.format("|cff2e9dd8TomoGear|r  |cff31d158+%.1f%%|r", percent)
        elseif percent < 0 then
            line = string.format("|cff2e9dd8TomoGear|r  |cffff5a5f%.1f%%|r", percent)
        else
            line = "|cff2e9dd8TomoGear|r  |cff9aa4af0.0%|r"
        end
    end
    if line and not SafeTooltipAddLine(tooltip, line) then return end

    if not line and db.showScores ~= true then return end

    if db.showScores == true and info.equippedScore and info.equippedScore > 0 then
        local line = string.format("|cff9aa4af%s|r", string.format(GA.L("score"), info.score, info.equippedScore))
        if not SafeTooltipAddLine(tooltip, line) then return end
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
