-- =====================================================================
-- AuctionHouseStudio.lua -- TomoHDV integrated Auction House workspace
-- Search + tracked recipe sheet + full market scan in one native AH tab.
-- Loaded after AuctionRecipeTracker.lua so the existing price tooltip and
-- saved database remain fully compatible.
-- =====================================================================

local ART = TomoMod_AuctionRecipeTracker
if not ART then return end

ART.Studio = ART.Studio or {}
local Studio = ART.Studio
Studio.IsIntegrated = true

local FONT   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_B = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8 = "Interface\\Buttons\\WHITE8x8"

local C = {
    bg      = { 0.035, 0.043, 0.055, 0.99 },
    panel   = { 0.055, 0.065, 0.082, 0.98 },
    panel2  = { 0.070, 0.082, 0.102, 0.96 },
    border  = { 0.16, 0.18, 0.22, 1.00 },
    accent  = { 0.180, 0.616, 0.847, 1.00 },
    text    = { 0.94, 0.96, 0.95, 1.00 },
    dim     = { 0.56, 0.60, 0.64, 1.00 },
    green   = { 0.28, 0.88, 0.48, 1.00 },
    yellow  = { 0.95, 0.76, 0.14, 1.00 },
    red     = { 0.90, 0.26, 0.24, 1.00 },
}

local SCAN_COOLDOWN = 15 * 60
local SCAN_BATCH = 250
local MAX_RECENTS = 6

local I18N = {
    enUS = {
        tab="TomoHDV", title="TomoHDV", search="Search", recipes="Recipes", scan="AH Scan",
        search_placeholder="Search an item...", search_btn="Search", more="More results",
        recent="Recent", search_idle="Enter an item name to search the Auction House.",
        search_running="Searching: %s", search_results="%d results", search_none="No result.",
        col_item="Item", col_qty="Quantity", col_market="Current", col_scan="Scan price",
        detail="Item details", select_item="Select a result to see its details.", available="Available",
        current_price="Current minimum", scanned_price="Last scanned price", open_buy="Open in Buy",
        direct_buy="Buy now", buy_quantity="Quantity", buy_total="Estimated total", buy_loading="Loading live offer...",
        buy_ready="Live offer ready.", buy_unavailable="No purchasable auction found.", buy_max="Max",
        buy_commodity="Commodity", buy_item="Auction item", buy_failed="Purchase failed or offer changed.",
        buy_hint="Blizzard confirmation opens here without leaving TomoHDV.",
        recipes_title="Tracked recipes", recipes_none="No tracked recipes.", recipe_detail="Recipe sheet",
        select_recipe="Select a tracked recipe.", reagents="Reagents", unit_price="Unit", total="Total",
        missing_prices="%d reagent price(s) missing", search_reagent="Search this reagent",
        scan_title="Full Auction House scan", scan_desc="Stores the lowest unit price seen for each item. Blizzard limits full replicate scans to once every 15 minutes.",
        scan_btn="Start full scan", scanning="Scanning...", scan_wait="Waiting for Auction House data...",
        scan_processing="Processing market data... %d%%", scan_done="Scan complete: %d priced items.",
        scan_failed="Scan failed or was interrupted.", last_scan="Last scan", never="Never",
        next_scan="Next full scan in %dm %ds", only_ah="Open the Auction House first.",
        legacy_retired="The former floating Recipe Tracker is now integrated here.",
    },
    frFR = {
        tab="TomoHDV", title="TomoHDV", search="Recherche", recipes="Recettes", scan="Scan HDV",
        search_placeholder="Rechercher un objet...", search_btn="Rechercher", more="Plus de résultats",
        recent="Récentes", search_idle="Entrez le nom d'un objet à rechercher à l'Hôtel des ventes.",
        search_running="Recherche : %s", search_results="%d résultats", search_none="Aucun résultat.",
        col_item="Objet", col_qty="Quantité", col_market="Actuel", col_scan="Prix du scan",
        detail="Fiche objet", select_item="Sélectionnez un résultat pour afficher sa fiche.", available="Disponible",
        current_price="Prix minimum actuel", scanned_price="Dernier prix scanné", open_buy="Ouvrir dans Achat",
        direct_buy="Acheter", buy_quantity="Quantité", buy_total="Total estimé", buy_loading="Actualisation de l'offre...",
        buy_ready="Offre actuelle prête.", buy_unavailable="Aucune vente achetable trouvée.", buy_max="Max",
        buy_commodity="Composant", buy_item="Objet aux enchères", buy_failed="Achat impossible ou offre modifiée.",
        buy_hint="La confirmation Blizzard s'ouvre ici sans quitter TomoHDV.",
        recipes_title="Recettes suivies", recipes_none="Aucune recette suivie.", recipe_detail="Fiche recette",
        select_recipe="Sélectionnez une recette suivie.", reagents="Composants", unit_price="Unité", total="Total",
        missing_prices="%d prix de composant(s) manquant(s)", search_reagent="Rechercher ce composant",
        scan_title="Scan complet de l'Hôtel des ventes", scan_desc="Mémorise le prix unitaire le plus bas observé pour chaque objet. Blizzard limite le scan complet à une fois toutes les 15 minutes.",
        scan_btn="Lancer le scan complet", scanning="Scan en cours...", scan_wait="En attente des données de l'Hôtel des ventes...",
        scan_processing="Traitement des prix... %d%%", scan_done="Scan terminé : %d objets avec un prix.",
        scan_failed="Le scan a échoué ou a été interrompu.", last_scan="Dernier scan", never="Jamais",
        next_scan="Prochain scan complet dans %dm %ds", only_ah="Ouvrez d'abord l'Hôtel des ventes.",
        legacy_retired="L'ancienne fenêtre flottante des recettes est maintenant intégrée ici.",
    },
    deDE = {
        tab="TomoHDV", title="TomoHDV", search="Suche", recipes="Rezepte", scan="AH-Scan",
        search_placeholder="Gegenstand suchen...", search_btn="Suchen", more="Mehr Ergebnisse",
        recent="Letzte", search_idle="Gegenstandsnamen eingeben, um das Auktionshaus zu durchsuchen.",
        search_running="Suche: %s", search_results="%d Ergebnisse", search_none="Keine Ergebnisse.",
        col_item="Gegenstand", col_qty="Menge", col_market="Aktuell", col_scan="Scanpreis",
        detail="Gegenstand", select_item="Wähle ein Ergebnis für Details.", available="Verfügbar",
        current_price="Aktueller Mindestpreis", scanned_price="Letzter Scanpreis", open_buy="In Kaufen öffnen",
        direct_buy="Jetzt kaufen", buy_quantity="Menge", buy_total="Geschätzte Summe", buy_loading="Aktuelles Angebot wird geladen...",
        buy_ready="Aktuelles Angebot bereit.", buy_unavailable="Keine kaufbare Auktion gefunden.", buy_max="Max",
        buy_commodity="Handelsware", buy_item="Auktionsgegenstand", buy_failed="Kauf fehlgeschlagen oder Angebot geändert.",
        buy_hint="Blizzards Bestätigung öffnet sich hier, ohne TomoHDV zu verlassen.",
        recipes_title="Verfolgte Rezepte", recipes_none="Keine verfolgten Rezepte.", recipe_detail="Rezeptdetails",
        select_recipe="Wähle ein verfolgtes Rezept.", reagents="Reagenzien", unit_price="Einheit", total="Gesamt",
        missing_prices="%d Reagenzpreis(e) fehlen", search_reagent="Reagenz suchen",
        scan_title="Vollständiger Auktionshaus-Scan", scan_desc="Speichert den niedrigsten Stückpreis pro Gegenstand. Blizzard erlaubt den vollständigen Scan nur alle 15 Minuten.",
        scan_btn="Vollscan starten", scanning="Scan läuft...", scan_wait="Warte auf Auktionshausdaten...",
        scan_processing="Marktdaten werden verarbeitet... %d%%", scan_done="Scan abgeschlossen: %d Gegenstände mit Preis.",
        scan_failed="Scan fehlgeschlagen oder abgebrochen.", last_scan="Letzter Scan", never="Nie",
        next_scan="Nächster Vollscan in %dm %ds", only_ah="Öffne zuerst das Auktionshaus.",
        legacy_retired="Der frühere schwebende Rezept-Tracker ist jetzt hier integriert.",
    },
    esES = {
        tab="TomoHDV", title="TomoHDV", search="Buscar", recipes="Recetas", scan="Escanear",
        search_placeholder="Buscar un objeto...", search_btn="Buscar", more="Más resultados",
        recent="Recientes", search_idle="Escribe el nombre de un objeto para buscar en la Casa de Subastas.",
        search_running="Buscando: %s", search_results="%d resultados", search_none="Sin resultados.",
        col_item="Objeto", col_qty="Cantidad", col_market="Actual", col_scan="Precio escaneado",
        detail="Ficha del objeto", select_item="Selecciona un resultado para ver sus detalles.", available="Disponible",
        current_price="Precio mínimo actual", scanned_price="Último precio escaneado", open_buy="Abrir en Comprar",
        direct_buy="Comprar", buy_quantity="Cantidad", buy_total="Total estimado", buy_loading="Actualizando oferta...",
        buy_ready="Oferta actual lista.", buy_unavailable="No se encontró una subasta comprable.", buy_max="Máx.",
        buy_commodity="Componente", buy_item="Objeto de subasta", buy_failed="La compra falló o cambió la oferta.",
        buy_hint="La confirmación de Blizzard se abre aquí sin salir de TomoHDV.",
        recipes_title="Recetas seguidas", recipes_none="No hay recetas seguidas.", recipe_detail="Ficha de receta",
        select_recipe="Selecciona una receta seguida.", reagents="Componentes", unit_price="Unidad", total="Total",
        missing_prices="Faltan %d precio(s) de componentes", search_reagent="Buscar componente",
        scan_title="Escaneo completo de la Casa de Subastas", scan_desc="Guarda el precio unitario más bajo visto por objeto. Blizzard limita el escaneo completo a una vez cada 15 minutos.",
        scan_btn="Iniciar escaneo completo", scanning="Escaneando...", scan_wait="Esperando datos de la Casa de Subastas...",
        scan_processing="Procesando mercado... %d%%", scan_done="Escaneo completado: %d objetos con precio.",
        scan_failed="El escaneo falló o fue interrumpido.", last_scan="Último escaneo", never="Nunca",
        next_scan="Próximo escaneo completo en %dm %ds", only_ah="Abre primero la Casa de Subastas.",
        legacy_retired="La antigua ventana flotante de recetas ahora está integrada aquí.",
    },
    itIT = {
        tab="TomoHDV", title="TomoHDV", search="Cerca", recipes="Ricette", scan="Scansione",
        search_placeholder="Cerca un oggetto...", search_btn="Cerca", more="Altri risultati",
        recent="Recenti", search_idle="Inserisci il nome di un oggetto da cercare nella Casa d'Aste.",
        search_running="Ricerca: %s", search_results="%d risultati", search_none="Nessun risultato.",
        col_item="Oggetto", col_qty="Quantità", col_market="Attuale", col_scan="Prezzo scansione",
        detail="Dettagli oggetto", select_item="Seleziona un risultato per vederne i dettagli.", available="Disponibile",
        current_price="Prezzo minimo attuale", scanned_price="Ultimo prezzo scansionato", open_buy="Apri in Acquista",
        direct_buy="Acquista", buy_quantity="Quantità", buy_total="Totale stimato", buy_loading="Aggiornamento offerta...",
        buy_ready="Offerta attuale pronta.", buy_unavailable="Nessuna asta acquistabile trovata.", buy_max="Max",
        buy_commodity="Merce", buy_item="Oggetto all'asta", buy_failed="Acquisto fallito o offerta modificata.",
        buy_hint="La conferma Blizzard si apre qui senza uscire da TomoHDV.",
        recipes_title="Ricette tracciate", recipes_none="Nessuna ricetta tracciata.", recipe_detail="Scheda ricetta",
        select_recipe="Seleziona una ricetta tracciata.", reagents="Reagenti", unit_price="Unità", total="Totale",
        missing_prices="Mancano %d prezzo/i reagente", search_reagent="Cerca reagente",
        scan_title="Scansione completa Casa d'Aste", scan_desc="Memorizza il prezzo unitario più basso per ogni oggetto. Blizzard limita la scansione completa a una volta ogni 15 minuti.",
        scan_btn="Avvia scansione completa", scanning="Scansione...", scan_wait="In attesa dei dati della Casa d'Aste...",
        scan_processing="Elaborazione mercato... %d%%", scan_done="Scansione completata: %d oggetti con prezzo.",
        scan_failed="Scansione fallita o interrotta.", last_scan="Ultima scansione", never="Mai",
        next_scan="Prossima scansione completa tra %dm %ds", only_ah="Apri prima la Casa d'Aste.",
        legacy_retired="La vecchia finestra mobile delle ricette è ora integrata qui.",
    },
    ptBR = {
        tab="TomoHDV", title="TomoHDV", search="Busca", recipes="Receitas", scan="Escanear",
        search_placeholder="Buscar um item...", search_btn="Buscar", more="Mais resultados",
        recent="Recentes", search_idle="Digite o nome de um item para pesquisar na Casa de Leilões.",
        search_running="Buscando: %s", search_results="%d resultados", search_none="Nenhum resultado.",
        col_item="Item", col_qty="Quantidade", col_market="Atual", col_scan="Preço escaneado",
        detail="Detalhes do item", select_item="Selecione um resultado para ver os detalhes.", available="Disponível",
        current_price="Preço mínimo atual", scanned_price="Último preço escaneado", open_buy="Abrir em Comprar",
        direct_buy="Comprar", buy_quantity="Quantidade", buy_total="Total estimado", buy_loading="Atualizando oferta...",
        buy_ready="Oferta atual pronta.", buy_unavailable="Nenhum leilão comprável encontrado.", buy_max="Máx.",
        buy_commodity="Mercadoria", buy_item="Item de leilão", buy_failed="A compra falhou ou a oferta mudou.",
        buy_hint="A confirmação da Blizzard abre aqui sem sair do TomoHDV.",
        recipes_title="Receitas rastreadas", recipes_none="Nenhuma receita rastreada.", recipe_detail="Ficha da receita",
        select_recipe="Selecione uma receita rastreada.", reagents="Reagentes", unit_price="Unidade", total="Total",
        missing_prices="Faltam %d preço(s) de reagente", search_reagent="Buscar reagente",
        scan_title="Escaneamento completo da Casa de Leilões", scan_desc="Armazena o menor preço unitário visto por item. A Blizzard limita o escaneamento completo a uma vez a cada 15 minutos.",
        scan_btn="Iniciar escaneamento completo", scanning="Escaneando...", scan_wait="Aguardando dados da Casa de Leilões...",
        scan_processing="Processando mercado... %d%%", scan_done="Escaneamento concluído: %d itens com preço.",
        scan_failed="O escaneamento falhou ou foi interrompido.", last_scan="Último escaneamento", never="Nunca",
        next_scan="Próximo escaneamento completo em %dm %ds", only_ah="Abra primeiro a Casa de Leilões.",
        legacy_retired="A antiga janela flutuante de receitas agora está integrada aqui.",
    },
}

local locale = GetLocale and GetLocale() or "enUS"
local TXT = I18N[locale] or I18N.enUS
local function T(key) return TXT[key] or I18N.enUS[key] or key end

local function GetDB()
    TomoModDB = TomoModDB or {}
    local db = TomoModDB.auctionRecipeTracker
    if type(db) ~= "table" then
        db = {}
        TomoModDB.auctionRecipeTracker = db
    end
    db.prices = type(db.prices) == "table" and db.prices or {}
    db.recentSearches = type(db.recentSearches) == "table" and db.recentSearches or {}
    db.lastScan = tonumber(db.lastScan) or 0
    db.lastScanCount = tonumber(db.lastScanCount) or 0
    return db
end

local function Backdrop(frame, bg, border)
    frame:SetBackdrop({ bgFile=WHITE8, edgeFile=WHITE8, edgeSize=1 })
    frame:SetBackdropColor(unpack(bg or C.panel))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function Text(parent, value, size, bold)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(bold and FONT_B or FONT, size or 11, "")
    fs:SetTextColor(unpack(C.text))
    fs:SetText(value or "")
    return fs
end

local function Button(parent, label, w, h, callback)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w or 120, h or 26)
    Backdrop(b, {0.055,0.075,0.090,1}, {C.accent[1],C.accent[2],C.accent[3],0.55})
    local t = Text(b, label, 10, true)
    t:SetPoint("LEFT", 6, 0)
    t:SetPoint("RIGHT", -6, 0)
    t:SetJustifyH("CENTER")
    t:SetWordWrap(false)
    if t.SetMaxLines then t:SetMaxLines(1) end
    b._label = t
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.18)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.95)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.055,0.075,0.090,1)
        self:SetBackdropBorderColor(C.accent[1],C.accent[2],C.accent[3],0.55)
    end)
    b:SetScript("OnClick", callback)
    return b
end

local function Card(parent)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Backdrop(f, C.panel, C.border)
    return f
end

local function FormatMoney(copper)
    copper = tonumber(copper)
    if not copper or copper <= 0 then return "—" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = math.floor(copper % 100)
    if g > 0 then return string.format("|cffffd100%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r", g, s, c) end
    if s > 0 then return string.format("|cffc7c7cf%ds|r |cffeda55f%dc|r", s, c) end
    return string.format("|cffeda55f%dc|r", c)
end

local function FormatAge(epoch)
    epoch = tonumber(epoch) or 0
    if epoch <= 0 then return T("never") end
    local age = math.max(0, time() - epoch)
    if age < 60 then return "< 1m" end
    if age < 3600 then return string.format("%dm", math.floor(age/60)) end
    if age < 86400 then return string.format("%dh %02dm", math.floor(age/3600), math.floor((age%3600)/60)) end
    return string.format("%dd %02dh", math.floor(age/86400), math.floor((age%86400)/3600))
end

local function AddRecent(term)
    term = strtrim(term or "")
    if term == "" then return end
    local db = GetDB()
    for i = #db.recentSearches, 1, -1 do
        if db.recentSearches[i] == term then table.remove(db.recentSearches, i) end
    end
    table.insert(db.recentSearches, 1, term)
    while #db.recentSearches > MAX_RECENTS do table.remove(db.recentSearches) end
end

-- ---------------------------------------------------------------------
-- Generic vertical scroll area
-- ---------------------------------------------------------------------
local function CreateScrollArea(parent)
    local host = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Backdrop(host, {0.040,0.048,0.060,1}, C.border)

    local scroll = CreateFrame("ScrollFrame", nil, host)
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -11, 4)
    scroll:EnableMouseWheel(true)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(10, 10)
    scroll:SetScrollChild(child)

    local track = CreateFrame("Frame", nil, host, "BackdropTemplate")
    track:SetWidth(4)
    track:SetPoint("TOPRIGHT", -4, -4)
    track:SetPoint("BOTTOMRIGHT", -4, 4)
    track:SetBackdrop({bgFile=WHITE8})
    track:SetBackdropColor(0.12,0.13,0.15,0.7)

    local thumb = CreateFrame("Button", nil, track, "BackdropTemplate")
    thumb:SetWidth(4); thumb:SetHeight(32)
    thumb:SetBackdrop({bgFile=WHITE8})
    thumb:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.88)

    local function MaxScroll()
        return math.max(0, (child:GetHeight() or 0) - (scroll:GetHeight() or 0))
    end

    local function Update()
        local ch, vh, th = child:GetHeight() or 0, scroll:GetHeight() or 0, track:GetHeight() or 0
        if ch <= vh or vh <= 0 then track:Hide(); scroll:SetVerticalScroll(0); return end
        track:Show()
        local hh = math.max(18, th * vh / ch)
        thumb:SetHeight(hh)
        local maxS = MaxScroll()
        local pct = maxS > 0 and scroll:GetVerticalScroll()/maxS or 0
        local span = math.max(0, th-hh)
        thumb:ClearAllPoints(); thumb:SetPoint("TOP", track, "TOP", 0, -span*pct)
    end

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maxS = MaxScroll()
        local nv = math.max(0, math.min(maxS, self:GetVerticalScroll() - delta * 52))
        self:SetVerticalScroll(nv); Update()
    end)

    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self)
        self._dragging = true
        self:SetScript("OnUpdate", function(s)
            if not s._dragging then return end
            local _, cursorY = GetCursorPosition(); cursorY = cursorY / s:GetEffectiveScale()
            local top = track:GetTop(); if not top then return end
            local hh, th = s:GetHeight(), track:GetHeight()
            local y = math.max(0, math.min(th-hh, top - cursorY - hh/2))
            local span = math.max(1, th-hh)
            scroll:SetVerticalScroll((y/span)*MaxScroll())
            s:ClearAllPoints(); s:SetPoint("TOP", track, "TOP", 0, -y)
        end)
    end)
    thumb:SetScript("OnDragStop", function(self) self._dragging=false; self:SetScript("OnUpdate", nil); Update() end)
    child:HookScript("OnSizeChanged", Update)
    scroll:HookScript("OnSizeChanged", function(self)
        child:SetWidth(math.max(1, self:GetWidth()))
        Update()
    end)
    host:HookScript("OnShow", function()
        child:SetWidth(math.max(1, scroll:GetWidth()))
        Update()
    end)

    host.scroll, host.child, host.Update = scroll, child, Update
    return host
end

local frame, ahTab
local nav = {}
local content
local currentView = "search"
local suppressDisplayHook = false

local searchView, recipeView, scanView
local searchRows, recipeListRows, reagentRows = {}, {}, {}
local selectedSearch
local selectedRecipeKey
local scanInProgress = false
local scanAbortTimer
local scanProgress = 0
local scanStatus = ""
local purchase = {
    itemKey = nil,
    itemID = nil,
    isCommodity = false,
    pendingInfo = false,
    ready = false,
    quantity = 1,
    available = 0,
    unitPrice = 0,
    totalPrice = 0,
    auctionID = nil,
    buyout = 0,
}

local function HideLegacyFrame()
    local legacy = _G.TomoMod_AuctionRecipeTrackerFrame
    if not legacy then return end
    legacy:Hide()
    if not legacy._tmIntegratedSuppression then
        legacy._tmIntegratedSuppression = true
        legacy:HookScript("OnShow", function(self)
            if AuctionHouseFrame and AuctionHouseFrame:IsShown() then self:Hide() end
        end)
    end
end

local function SetNavSelected(key)
    for id, b in pairs(nav) do
        local on = id == key
        b:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],on and 0.18 or 0.035)
        b:SetBackdropBorderColor(C.accent[1],C.accent[2],C.accent[3],on and 0.82 or 0.24)
        b._label:SetTextColor(on and 1 or 0.72, on and 1 or 0.76, on and 1 or 0.80, 1)
        if b._selectedLine then b._selectedLine:SetShown(on) end
    end
end

local function HideAllViews()
    if searchView then searchView:Hide() end
    if recipeView then recipeView:Hide() end
    if scanView then scanView:Hide() end
end

-- ---------------------------------------------------------------------
-- Search
-- ---------------------------------------------------------------------
local function ItemInfoForBrowse(result)
    if not result or not result.itemKey then return nil end
    local info = C_AuctionHouse and C_AuctionHouse.GetItemKeyInfo and C_AuctionHouse.GetItemKeyInfo(result.itemKey)
    if info then return info end
    local itemID = result.itemKey.itemID
    if itemID and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
    return nil
end

local function SetDetailQuantity(value)
    if not searchView or not searchView.detail or not searchView.detail.qtyBox then return end
    local box = searchView.detail.qtyBox
    box._tmSetting = true
    box:SetText(tostring(math.max(1, math.floor(tonumber(value) or 1))))
    box._tmSetting = false
end

local function SetPurchaseButton(enabled)
    local d = searchView and searchView.detail
    if not d or not d.buy then return end
    if enabled then d.buy:Enable(); d.buy:SetAlpha(1)
    else d.buy:Disable(); d.buy:SetAlpha(0.45) end
end

local function SetPurchaseStatus(text, color)
    local d = searchView and searchView.detail
    if not d or not d.buyStatus then return end
    d.buyStatus:SetText(text or "")
    local c = color or C.dim
    d.buyStatus:SetTextColor(c[1], c[2], c[3], c[4] or 1)
end

local function ResetPurchaseState(message)
    purchase.itemKey = nil
    purchase.itemID = nil
    purchase.isCommodity = false
    purchase.pendingInfo = false
    purchase.ready = false
    purchase.quantity = 1
    purchase.available = 0
    purchase.unitPrice = 0
    purchase.totalPrice = 0
    purchase.auctionID = nil
    purchase.buyout = 0

    local d = searchView and searchView.detail
    if not d then return end
    if d.type then d.type:SetText("") end
    if d.totalValue then d.totalValue:SetText("—") end
    if d.qtyBox then
        SetDetailQuantity(1)
        d.qtyBox:Disable()
        d.qtyBox:SetTextColor(unpack(C.dim))
    end
    if d.max then d.max:Hide() end
    if d.buy and d.buy._label then d.buy._label:SetText(T("direct_buy")) end
    SetPurchaseButton(false)
    SetPurchaseStatus(message or "")
end

local function IsSameItemKey(a, b)
    if not a or not b then return false end
    return a.itemID == b.itemID
        and (a.itemLevel or 0) == (b.itemLevel or 0)
        and (a.itemSuffix or 0) == (b.itemSuffix or 0)
        and (a.battlePetSpeciesID or 0) == (b.battlePetSpeciesID or 0)
end

local function IsSelectedResult(result)
    return selectedSearch and result and IsSameItemKey(selectedSearch.itemKey, result.itemKey)
end

local function RefreshSearchRowSelection()
    for _, row in ipairs(searchRows) do
        row._selected = IsSelectedResult(row.result)
        if row._selected then
            row:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.10)
            row:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.65)
        else
            row:SetBackdropColor(0.055,0.064,0.078,0.94)
            row:SetBackdropBorderColor(0.12,0.14,0.17,1)
        end
    end
end

local function RefreshPurchaseOffer()
    local d = searchView and searchView.detail
    if not d or not purchase.itemKey or not purchase.itemID then return end

    purchase.ready = false
    purchase.auctionID = nil
    purchase.buyout = 0
    SetPurchaseButton(false)

    if purchase.isCommodity then
        local available = 0
        local count = C_AuctionHouse.GetNumCommoditySearchResults and C_AuctionHouse.GetNumCommoditySearchResults(purchase.itemID) or 0
        for i = 1, count do
            local info = C_AuctionHouse.GetCommoditySearchResultInfo(purchase.itemID, i)
            if info then
                local qty = tonumber(info.quantity) or 0
                local own = tonumber(info.numOwnerItems) or 0
                available = available + math.max(0, qty - own)
            end
        end
        purchase.available = available
        if available <= 0 then
            d.totalValue:SetText("—")
            SetPurchaseStatus(T("buy_unavailable"), C.red)
            return
        end

        local wanted = math.max(1, math.floor(tonumber(d.qtyBox:GetText()) or 1))
        wanted = math.min(wanted, available)
        if tostring(wanted) ~= d.qtyBox:GetText() then SetDetailQuantity(wanted) end

        local totalQuantity, totalPrice
        if AuctionHouseUtil and AuctionHouseUtil.AggregateSearchResultsByQuantity then
            totalQuantity, totalPrice = AuctionHouseUtil.AggregateSearchResultsByQuantity(purchase.itemID, wanted)
        end
        totalQuantity = tonumber(totalQuantity) or 0
        totalPrice = tonumber(totalPrice) or 0
        if totalQuantity <= 0 or totalPrice <= 0 then
            d.totalValue:SetText("—")
            SetPurchaseStatus(T("buy_loading"), C.dim)
            return
        end

        purchase.quantity = totalQuantity
        purchase.totalPrice = totalPrice
        purchase.unitPrice = math.ceil(totalPrice / totalQuantity)
        purchase.ready = true
        d.totalValue:SetText(FormatMoney(totalPrice))
        d.buy._label:SetText(string.format("%s ×%d", T("direct_buy"), totalQuantity))
        SetPurchaseStatus(T("buy_ready"), C.green)
        SetPurchaseButton(true)
    else
        purchase.available = 0
        local count = C_AuctionHouse.GetNumItemSearchResults and C_AuctionHouse.GetNumItemSearchResults(purchase.itemKey) or 0
        local best
        for i = 1, count do
            local info = C_AuctionHouse.GetItemSearchResultInfo(purchase.itemKey, i)
            local buyout = info and tonumber(info.buyoutAmount) or 0
            if info and buyout > 0 and not info.containsOwnerItem and not info.containsAccountItem then
                best = info
                break
            end
        end
        if not best then
            d.totalValue:SetText("—")
            SetPurchaseStatus(count > 0 and T("buy_unavailable") or T("buy_loading"), count > 0 and C.red or C.dim)
            return
        end

        purchase.quantity = 1
        purchase.available = 1
        purchase.auctionID = best.auctionID
        purchase.buyout = tonumber(best.buyoutAmount) or 0
        purchase.totalPrice = purchase.buyout
        purchase.unitPrice = purchase.buyout
        purchase.ready = purchase.auctionID ~= nil and purchase.buyout > 0
        SetDetailQuantity(1)
        d.totalValue:SetText(FormatMoney(purchase.buyout))
        d.buy._label:SetText(T("direct_buy"))
        SetPurchaseStatus(purchase.ready and T("buy_ready") or T("buy_unavailable"), purchase.ready and C.green or C.red)
        SetPurchaseButton(purchase.ready)
    end
end

local function RequestPurchaseSearch(result)
    local d = searchView and searchView.detail
    if not result or not result.itemKey or not d then ResetPurchaseState(""); return end

    local info = ItemInfoForBrowse(result)
    local itemID = result.itemKey.itemID
    if not itemID then ResetPurchaseState(T("buy_unavailable")); return end

    purchase.itemKey = result.itemKey
    purchase.itemID = itemID
    purchase.ready = false
    purchase.available = 0
    purchase.auctionID = nil
    purchase.buyout = 0
    purchase.totalPrice = 0
    purchase.unitPrice = 0

    if not info then
        purchase.pendingInfo = true
        SetPurchaseStatus(T("buy_loading"), C.dim)
        SetPurchaseButton(false)
        return
    end

    purchase.pendingInfo = false
    purchase.isCommodity = info.isCommodity and true or false
    d.type:SetText(purchase.isCommodity and T("buy_commodity") or T("buy_item"))
    SetDetailQuantity(1)
    if purchase.isCommodity then d.qtyBox:Enable() else d.qtyBox:Disable() end
    d.qtyBox:SetTextColor(unpack(purchase.isCommodity and C.text or C.dim))
    d.max:SetShown(purchase.isCommodity)
    d.totalValue:SetText("—")
    d.buy._label:SetText(T("direct_buy"))
    SetPurchaseStatus(T("buy_loading"), C.dim)
    SetPurchaseButton(false)

    if not (C_AuctionHouse and C_AuctionHouse.SendSearchQuery) then
        SetPurchaseStatus(T("buy_unavailable"), C.red)
        return
    end

    local sorts
    if purchase.isCommodity then
        sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }
    else
        sorts = {
            { sortOrder = Enum.AuctionHouseSortOrder.Buyout, reverseSort = false },
            { sortOrder = Enum.AuctionHouseSortOrder.Bid, reverseSort = false },
        }
    end
    C_AuctionHouse.SendSearchQuery(result.itemKey, sorts, true)
end

local function SetMaxPurchaseQuantity()
    if not purchase.isCommodity or purchase.available <= 0 then return end
    SetDetailQuantity(purchase.available)
    RefreshPurchaseOffer()
end

local function DirectBuySelected()
    if not purchase.ready or not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return end

    -- Re-evaluate the quote inside the hardware click before starting the
    -- protected purchase. Confirmation itself remains Blizzard-owned and is
    -- displayed above TomoHDV; the user never has to switch back to Buy.
    RefreshPurchaseOffer()
    if not purchase.ready then return end

    if purchase.isCommodity then
        if AuctionHouseFrame.StartCommoditiesPurchase then
            AuctionHouseFrame:StartCommoditiesPurchase(
                purchase.itemID, purchase.quantity, purchase.unitPrice, purchase.totalPrice)
        end
    elseif purchase.auctionID and purchase.buyout > 0 and AuctionHouseFrame.StartItemBuyout then
        AuctionHouseFrame:StartItemBuyout(purchase.auctionID, purchase.buyout)
    end
end

local function UpdateSearchDetail()
    if not searchView or not searchView.detail then return end
    local d = searchView.detail
    local result = selectedSearch
    if not result then
        d.icon:SetTexture(134400); d.name:SetText(T("select_item")); d.qty:SetText("")
        d.current:SetText(""); d.scanned:SetText("")
        ResetPurchaseState("")
        return
    end
    local info = ItemInfoForBrowse(result)
    local itemID = result.itemKey and result.itemKey.itemID
    local name = info and info.itemName or (itemID and ("item:"..itemID) or "—")
    d.icon:SetTexture(info and info.iconFileID or 134400)
    d.name:SetText(name)
    d.qty:SetText(string.format("%s  |cffffffff%s|r", T("available"), tostring(result.totalQuantity or 0)))
    d.current:SetText(FormatMoney(result.minPrice))
    local scanned = itemID and GetDB().prices[itemID]
    d.scanned:SetText(FormatMoney(scanned))
    if info and d.type then d.type:SetText(info.isCommodity and T("buy_commodity") or T("buy_item")) end
end

local function AcquireSearchRow(parent, i)
    local row = searchRows[i]
    if row then return row end
    row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(34)
    Backdrop(row, {0.055,0.064,0.078,0.94}, {0.12,0.14,0.17,1})
    row.icon = row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(26,26); row.icon:SetPoint("LEFT",4,0); row.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    row.scan = Text(row,"",9,false); row.scan:SetPoint("RIGHT",-8,0); row.scan:SetWidth(86); row.scan:SetJustifyH("RIGHT"); row.scan:SetTextColor(unpack(C.dim))
    row.price = Text(row,"",9,true); row.price:SetPoint("RIGHT",row.scan,"LEFT",-6,0); row.price:SetWidth(94); row.price:SetJustifyH("RIGHT")
    row.qty = Text(row,"",9,false); row.qty:SetPoint("RIGHT",row.price,"LEFT",-6,0); row.qty:SetWidth(64); row.qty:SetJustifyH("RIGHT"); row.qty:SetTextColor(unpack(C.dim))
    row.name = Text(row,"",10,true); row.name:SetPoint("LEFT",row.icon,"RIGHT",7,0); row.name:SetPoint("RIGHT",row.qty,"LEFT",-8,0); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.12)
        local r=self.result; local itemID=r and r.itemKey and r.itemKey.itemID
        if itemID then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetItemByID(itemID); GameTooltip:Show() end
    end)
    row:SetScript("OnLeave", function(self)
        if self._selected then self:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.10)
        else self:SetBackdropColor(0.055,0.064,0.078,0.94) end
        if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick", function(self)
        selectedSearch=self.result
        UpdateSearchDetail()
        RequestPurchaseSearch(self.result)
        RefreshSearchRowSelection()
    end)
    searchRows[i]=row
    return row
end

local function RefreshSearchRecents()
    if not searchView or not searchView.recents then return end
    local rec = GetDB().recentSearches
    for i,b in ipairs(searchView.recents) do
        local term=rec[i]
        b:SetShown(term ~= nil)
        if term then b._label:SetText(term); b.term=term end
    end
end

local function RefreshSearchResults()
    if not searchView or not searchView:IsShown() then return end
    local results = C_AuctionHouse and C_AuctionHouse.GetBrowseResults and C_AuctionHouse.GetBrowseResults() or {}
    local child = searchView.list.child
    local y=-2
    for i,result in ipairs(results) do
        local row=AcquireSearchRow(child,i)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",2,y); row:SetPoint("RIGHT",child,"RIGHT",-2,0)
        row.result=result
        row._selected=IsSelectedResult(result)
        local info=ItemInfoForBrowse(result)
        local itemID=result.itemKey and result.itemKey.itemID
        row.icon:SetTexture(info and info.iconFileID or 134400)
        row.name:SetText(info and info.itemName or (itemID and ("item:"..itemID) or "—"))
        row.qty:SetText(tostring(result.totalQuantity or 0))
        row.price:SetText(FormatMoney(result.minPrice))
        row.scan:SetText(FormatMoney(itemID and GetDB().prices[itemID]))
        if row._selected then
            row:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.10)
            row:SetBackdropBorderColor(C.accent[1],C.accent[2],C.accent[3],0.65)
        else
            row:SetBackdropColor(0.055,0.064,0.078,0.94)
            row:SetBackdropBorderColor(0.12,0.14,0.17,1)
        end
        row:Show(); y=y-36
    end
    for i=#results+1,#searchRows do searchRows[i]:Hide() end
    child:SetHeight(math.max(10,-y+2)); searchView.list.Update()
    if #results == 0 then searchView.status:SetText(T("search_none")) else searchView.status:SetText(string.format(T("search_results"),#results)) end
    searchView.more:SetShown(C_AuctionHouse and C_AuctionHouse.HasFullBrowseResults and not C_AuctionHouse.HasFullBrowseResults())
end

local function DoSearch(term)
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then return end
    term=strtrim(term or "")
    if term=="" then return end
    AddRecent(term); RefreshSearchRecents()
    searchView.edit:SetText(term)
    searchView.status:SetText(string.format(T("search_running"),term))
    selectedSearch=nil; ResetPurchaseState(""); UpdateSearchDetail(); RefreshSearchRowSelection()
    C_AuctionHouse.SendBrowseQuery({
        searchString=term,
        sorts={
            {sortOrder=Enum.AuctionHouseSortOrder.Price,reverseSort=false},
            {sortOrder=Enum.AuctionHouseSortOrder.Name,reverseSort=false},
        },
        minLevel=0, maxLevel=0, filters={}, itemClassFilters={},
    })
end

local function BuildSearchView(parent)
    local p=CreateFrame("Frame",nil,parent); p:SetAllPoints(); p:Hide(); searchView=p

    local edit=CreateFrame("EditBox",nil,p,"BackdropTemplate")
    edit:SetAutoFocus(false); edit:SetFont(FONT,11,""); edit:SetTextInsets(10,10,0,0); edit:SetTextColor(unpack(C.text))
    Backdrop(edit,{0.035,0.042,0.052,1},C.border)
    edit:SetPoint("TOPLEFT",18,-18); edit:SetSize(430,30); p.edit=edit
    edit:SetScript("OnEnterPressed",function(self) self:ClearFocus(); DoSearch(self:GetText()) end)
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local ph=Text(edit,T("search_placeholder"),10,false); ph:SetPoint("LEFT",10,0); ph:SetTextColor(unpack(C.dim)); edit.placeholder=ph
    edit:SetScript("OnTextChanged",function(self) ph:SetShown(self:GetText()=="") end)
    local sb=Button(p,T("search_btn"),118,30,function() DoSearch(edit:GetText()) end); sb:SetPoint("LEFT",edit,"RIGHT",8,0)

    local recentLabel=Text(p,T("recent").." :",9,true); recentLabel:SetPoint("TOPLEFT",18,-60); recentLabel:SetTextColor(unpack(C.dim))
    p.recents={}
    local rx=84
    for i=1,MAX_RECENTS do
        local b=Button(p,"",94,22,function(self) if self.term then DoSearch(self.term) end end)
        b:SetPoint("TOPLEFT",rx,-56); b:SetShown(false); b._label:SetFont(FONT,8,"")
        b._label:SetWordWrap(false); if b._label.SetMaxLines then b._label:SetMaxLines(1) end
        p.recents[i]=b; rx=rx+100
    end

    -- The detail sheet owns a real slice of the workspace. V1 gave the result
    -- list a fixed 690px width first, which could squeeze this panel down to a
    -- few dozen pixels depending on UI scale. Keep the sheet around one third
    -- of the available width and let the result list consume the remainder.
    local detail=Card(p); detail:SetPoint("TOPRIGHT",-18,-110); detail:SetPoint("BOTTOMRIGHT",-18,48); p.detail=detail
    local list=CreateScrollArea(p); list:SetPoint("TOPLEFT",18,-110); list:SetPoint("BOTTOMLEFT",18,48); list:SetPoint("RIGHT",detail,"LEFT",-12,0); p.list=list

    local head=CreateFrame("Frame",nil,p,"BackdropTemplate"); head:SetPoint("BOTTOMLEFT",list,"TOPLEFT",0,2); head:SetPoint("BOTTOMRIGHT",list,"TOPRIGHT",0,2); head:SetHeight(24); Backdrop(head,C.panel2,C.border)
    local h4=Text(head,T("col_scan"),8,true); h4:SetPoint("RIGHT",-8,0); h4:SetWidth(86); h4:SetJustifyH("RIGHT"); h4:SetTextColor(unpack(C.dim))
    local h3=Text(head,T("col_market"),8,true); h3:SetPoint("RIGHT",h4,"LEFT",-6,0); h3:SetWidth(94); h3:SetJustifyH("RIGHT"); h3:SetTextColor(unpack(C.dim))
    local h2=Text(head,T("col_qty"),8,true); h2:SetPoint("RIGHT",h3,"LEFT",-6,0); h2:SetWidth(64); h2:SetJustifyH("RIGHT"); h2:SetTextColor(unpack(C.dim))
    local h1=Text(head,T("col_item"),8,true); h1:SetPoint("LEFT",38,0); h1:SetPoint("RIGHT",h2,"LEFT",-8,0); h1:SetJustifyH("LEFT"); h1:SetTextColor(unpack(C.dim))

    local dt=Text(detail,T("detail"),11,true); dt:SetPoint("TOPLEFT",14,-13); dt:SetTextColor(unpack(C.accent))
    detail.icon=detail:CreateTexture(nil,"ARTWORK"); detail.icon:SetSize(48,48); detail.icon:SetPoint("TOPLEFT",14,-38); detail.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    detail.name=Text(detail,T("select_item"),12,true); detail.name:SetPoint("TOPLEFT",detail.icon,"TOPRIGHT",10,-1); detail.name:SetPoint("RIGHT",-14,0); detail.name:SetHeight(36); detail.name:SetJustifyH("LEFT"); detail.name:SetJustifyV("TOP"); detail.name:SetWordWrap(true); if detail.name.SetMaxLines then detail.name:SetMaxLines(2) end
    detail.qty=Text(detail,"",9,false); detail.qty:SetPoint("TOPLEFT",14,-94); detail.qty:SetPoint("RIGHT",-14,0); detail.qty:SetJustifyH("LEFT"); detail.qty:SetWordWrap(false); if detail.qty.SetMaxLines then detail.qty:SetMaxLines(1) end; detail.qty:SetTextColor(unpack(C.dim))

    local divider=detail:CreateTexture(nil,"ARTWORK"); divider:SetHeight(1); divider:SetPoint("TOPLEFT",14,-116); divider:SetPoint("TOPRIGHT",-14,-116); divider:SetColorTexture(C.border[1],C.border[2],C.border[3],0.85)

    local currentCard=Card(detail); currentCard:SetPoint("TOPLEFT",14,-128); currentCard:SetPoint("TOPRIGHT",detail,"TOP",-5,-128); currentCard:SetHeight(50)
    local currentLabel=Text(currentCard,T("current_price"),7,true); currentLabel:SetPoint("TOPLEFT",8,-7); currentLabel:SetPoint("RIGHT",-7,0); currentLabel:SetJustifyH("LEFT"); currentLabel:SetWordWrap(false); if currentLabel.SetMaxLines then currentLabel:SetMaxLines(1) end; currentLabel:SetTextColor(unpack(C.dim))
    detail.current=Text(currentCard,"",10,true); detail.current:SetPoint("BOTTOMLEFT",8,7); detail.current:SetPoint("RIGHT",-7,0); detail.current:SetJustifyH("LEFT"); detail.current:SetWordWrap(false); if detail.current.SetMaxLines then detail.current:SetMaxLines(1) end

    local scanCard=Card(detail); scanCard:SetPoint("TOPLEFT",detail,"TOP",5,-128); scanCard:SetPoint("TOPRIGHT",-14,-128); scanCard:SetHeight(50)
    local scanLabel=Text(scanCard,T("scanned_price"),7,true); scanLabel:SetPoint("TOPLEFT",8,-7); scanLabel:SetPoint("RIGHT",-7,0); scanLabel:SetJustifyH("LEFT"); scanLabel:SetWordWrap(false); if scanLabel.SetMaxLines then scanLabel:SetMaxLines(1) end; scanLabel:SetTextColor(unpack(C.dim))
    detail.scanned=Text(scanCard,"",10,true); detail.scanned:SetPoint("BOTTOMLEFT",8,7); detail.scanned:SetPoint("RIGHT",-7,0); detail.scanned:SetJustifyH("LEFT"); detail.scanned:SetWordWrap(false); if detail.scanned.SetMaxLines then detail.scanned:SetMaxLines(1) end; detail.scanned:SetTextColor(unpack(C.text))

    -- Compact purchase block. Keep it fully below the two price cards and
    -- reserve one horizontal row for quantity controls, one for the total,
    -- then status + the final confirmation button. This avoids the text stack
    -- visible at small/medium UI heights and keeps the right card readable.
    detail.type=Text(detail,"",8,false); detail.type:SetPoint("BOTTOMRIGHT",-14,88); detail.type:SetWidth(112); detail.type:SetJustifyH("RIGHT"); detail.type:SetWordWrap(false); if detail.type.SetMaxLines then detail.type:SetMaxLines(1) end; detail.type:SetTextColor(unpack(C.dim))

    local qtyLabel=Text(detail,T("buy_quantity"),8,true); qtyLabel:SetPoint("BOTTOMLEFT",14,88); qtyLabel:SetWidth(58); qtyLabel:SetWordWrap(false); if qtyLabel.SetMaxLines then qtyLabel:SetMaxLines(1) end; qtyLabel:SetTextColor(unpack(C.dim))
    detail.qtyBox=CreateFrame("EditBox",nil,detail,"BackdropTemplate"); detail.qtyBox:SetSize(72,24); detail.qtyBox:SetPoint("BOTTOMLEFT",78,78); detail.qtyBox:SetAutoFocus(false); detail.qtyBox:SetNumeric(true); detail.qtyBox:SetMaxLetters(7); detail.qtyBox:SetFont(FONT_B,10,""); detail.qtyBox:SetJustifyH("CENTER"); detail.qtyBox:SetTextInsets(5,5,0,0); Backdrop(detail.qtyBox,{0.035,0.042,0.052,1},C.border)
    detail.qtyBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    detail.qtyBox:SetScript("OnEnterPressed",function(self) self:ClearFocus(); RefreshPurchaseOffer() end)
    detail.qtyBox:SetScript("OnTextChanged",function(self)
        if self._tmSetting then return end
        if purchase.isCommodity then RefreshPurchaseOffer() end
    end)
    detail.max=Button(detail,T("buy_max"),48,24,SetMaxPurchaseQuantity); detail.max:SetPoint("LEFT",detail.qtyBox,"RIGHT",6,0); detail.max:Hide()

    local totalLabel=Text(detail,T("buy_total"),8,true); totalLabel:SetPoint("BOTTOMLEFT",14,59); totalLabel:SetWidth(100); totalLabel:SetWordWrap(false); if totalLabel.SetMaxLines then totalLabel:SetMaxLines(1) end; totalLabel:SetTextColor(unpack(C.dim))
    detail.totalValue=Text(detail,"—",11,true); detail.totalValue:SetPoint("BOTTOMRIGHT",-14,58); detail.totalValue:SetWidth(150); detail.totalValue:SetJustifyH("RIGHT"); detail.totalValue:SetWordWrap(false); if detail.totalValue.SetMaxLines then detail.totalValue:SetMaxLines(1) end

    detail.buyStatus=Text(detail,T("buy_hint"),8,false); detail.buyStatus:SetPoint("BOTTOMLEFT",14,43); detail.buyStatus:SetPoint("BOTTOMRIGHT",-14,43); detail.buyStatus:SetHeight(11); detail.buyStatus:SetJustifyH("LEFT"); detail.buyStatus:SetJustifyV("MIDDLE"); detail.buyStatus:SetWordWrap(false); if detail.buyStatus.SetMaxLines then detail.buyStatus:SetMaxLines(1) end; detail.buyStatus:SetTextColor(unpack(C.dim))

    detail.buy=Button(detail,T("direct_buy"),170,28,DirectBuySelected); detail.buy:SetPoint("BOTTOMLEFT",14,10); detail.buy:SetPoint("BOTTOMRIGHT",-14,10); detail.buy:Disable(); detail.buy:SetAlpha(0.45)

    local function LayoutColumns()
        local w=p:GetWidth() or 0
        if w<=0 then return end
        detail:SetWidth(math.max(340,math.min(400,math.floor(w*0.36))))
    end
    p:SetScript("OnSizeChanged",LayoutColumns)

    p.more=Button(p,T("more"),140,26,function() if C_AuctionHouse.RequestMoreBrowseResults then C_AuctionHouse.RequestMoreBrowseResults() end end); p.more:SetPoint("BOTTOMRIGHT",-18,12); p.more:Hide()
    p.status=Text(p,T("search_idle"),9,false); p.status:SetPoint("BOTTOMLEFT",18,20); p.status:SetPoint("RIGHT",p.more,"LEFT",-12,0); p.status:SetJustifyH("LEFT"); p.status:SetTextColor(unpack(C.dim))

    p:SetScript("OnShow",function() LayoutColumns(); RefreshSearchRecents(); UpdateSearchDetail() end)
end

-- ---------------------------------------------------------------------
-- Recipe sheet
-- ---------------------------------------------------------------------
local function CollectTrackedRecipes()
    local out={}
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipesTracked then return out end
    local seen={}
    local function Add(recipeID,isRecraft)
        local key=tostring(recipeID)..":"..(isRecraft and "1" or "0")
        if seen[key] then return end; seen[key]=true
        local info=C_TradeSkillUI.GetRecipeInfo(recipeID)
        local schematic=C_TradeSkillUI.GetRecipeSchematic(recipeID,isRecraft)
        if not info or not schematic then return end
        local e={key=key,recipeID=recipeID,isRecraft=isRecraft,name=info.name or ("Recipe "..recipeID),icon=info.icon,reagents={}}
        local byItem={}
        for _,slot in ipairs(schematic.reagentSlotSchematics or {}) do
            if slot.reagentType==Enum.CraftingReagentType.Basic and slot.reagents and #slot.reagents>0 then
                local itemID=slot.reagents[1].itemID
                if itemID then
                    if byItem[itemID] then byItem[itemID].qty=byItem[itemID].qty+(slot.quantityRequired or 1)
                    else local r={itemID=itemID,qty=slot.quantityRequired or 1}; byItem[itemID]=r; table.insert(e.reagents,r) end
                end
            end
        end
        table.insert(out,e)
    end
    for _,id in ipairs(C_TradeSkillUI.GetRecipesTracked(false) or {}) do Add(id,false) end
    for _,id in ipairs(C_TradeSkillUI.GetRecipesTracked(true) or {}) do Add(id,true) end
    table.sort(out,function(a,b) return (a.name or "") < (b.name or "") end)
    return out
end

local function AcquireRecipeListRow(parent,i)
    local row=recipeListRows[i]
    if row then return row end
    row=CreateFrame("Button",nil,parent,"BackdropTemplate"); row:SetHeight(40); Backdrop(row,{0.055,0.064,0.078,0.94},C.border)
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(30,30); row.icon:SetPoint("LEFT",5,0); row.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    row.name=Text(row,"",9,true); row.name:SetPoint("LEFT",row.icon,"RIGHT",7,0); row.name:SetPoint("RIGHT",-7,0); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
    row:SetScript("OnEnter",function(self) self:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.15) end)
    row:SetScript("OnLeave",function(self)
        if self._selected then self:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.10)
        else self:SetBackdropColor(0.055,0.064,0.078,0.94) end
    end)
    row:SetScript("OnClick",function(self) selectedRecipeKey=self.recipe and self.recipe.key; Studio:RefreshRecipes() end)
    recipeListRows[i]=row; return row
end

local function AcquireReagentRow(parent,i)
    local row=reagentRows[i]
    if row then return row end
    row=CreateFrame("Button",nil,parent,"BackdropTemplate"); row:SetHeight(38); Backdrop(row,{0.055,0.064,0.078,0.94},C.border)
    row.qty=Text(row,"",10,true); row.qty:SetPoint("LEFT",6,0); row.qty:SetWidth(34); row.qty:SetJustifyH("RIGHT"); row.qty:SetTextColor(unpack(C.accent))
    row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(28,28); row.icon:SetPoint("LEFT",row.qty,"RIGHT",5,0); row.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    row.total=Text(row,"",9,true); row.total:SetPoint("RIGHT",-8,0); row.total:SetWidth(112); row.total:SetJustifyH("RIGHT")
    row.unit=Text(row,"",9,false); row.unit:SetPoint("RIGHT",row.total,"LEFT",-8,0); row.unit:SetWidth(112); row.unit:SetJustifyH("RIGHT"); row.unit:SetTextColor(unpack(C.dim))
    row.name=Text(row,"",9,true); row.name:SetPoint("LEFT",row.icon,"RIGHT",7,0); row.name:SetPoint("RIGHT",row.unit,"LEFT",-10,0); row.name:SetJustifyH("LEFT"); row.name:SetWordWrap(false)
    row:SetScript("OnEnter",function(self)
        self:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.12)
        if self.itemID then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetItemByID(self.itemID); GameTooltip:AddLine(" "); GameTooltip:AddLine(T("search_reagent"),C.accent[1],C.accent[2],C.accent[3]); GameTooltip:Show() end
    end)
    row:SetScript("OnLeave",function(self) self:SetBackdropColor(0.055,0.064,0.078,0.94); GameTooltip:Hide() end)
    row:SetScript("OnClick",function(self) if self.itemName then Studio:SelectView("search"); DoSearch(self.itemName) end end)
    reagentRows[i]=row; return row
end

function Studio:RefreshRecipes()
    if not recipeView then return end
    local recipes=CollectTrackedRecipes()
    local listChild=recipeView.list.child
    local selected
    for _,r in ipairs(recipes) do if r.key==selectedRecipeKey then selected=r; break end end
    if not selected then selected=recipes[1]; selectedRecipeKey=selected and selected.key or nil end

    local y=-2
    for i,r in ipairs(recipes) do
        local row=AcquireRecipeListRow(listChild,i); row.recipe=r; row._selected=(r.key==selectedRecipeKey)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",2,y); row:SetPoint("RIGHT",listChild,"RIGHT",-2,0)
        row.icon:SetTexture(r.icon or 134400); row.name:SetText(r.name)
        if row._selected then
            row:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],0.10)
            row:SetBackdropBorderColor(C.accent[1],C.accent[2],C.accent[3],0.72)
        else
            row:SetBackdropColor(0.055,0.064,0.078,0.94)
            row:SetBackdropBorderColor(unpack(C.border))
        end
        row:Show(); y=y-42
    end
    for i=#recipes+1,#recipeListRows do recipeListRows[i]:Hide() end
    listChild:SetHeight(math.max(10,-y+2)); recipeView.list.Update()

    local d=recipeView.detail
    if not selected then
        d.icon:SetTexture(134400); d.name:SetText(T("select_recipe")); d.summary:SetText(T("recipes_none"));
        for _,row in ipairs(reagentRows) do row:Hide() end
        d.reagents.child:SetHeight(10); d.reagents.Update(); return
    end

    d.icon:SetTexture(selected.icon or 134400); d.name:SetText(selected.name)
    local db=GetDB(); local recipeTotal=0; local missing=0; local ry=-2
    for i,reagent in ipairs(selected.reagents) do
        local name,link,_,_,_,_,_,_,_,icon=C_Item.GetItemInfo(reagent.itemID)
        if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(reagent.itemID) end
        local row=AcquireReagentRow(d.reagents.child,i); row:ClearAllPoints(); row:SetPoint("TOPLEFT",2,ry); row:SetPoint("RIGHT",d.reagents.child,"RIGHT",-2,0)
        row.itemID=reagent.itemID; row.itemName=name; row.itemLink=link; row.icon:SetTexture(icon or 134400); row.qty:SetText(tostring(reagent.qty).."×"); row.name:SetText(name or ("item:"..reagent.itemID))
        local unit=db.prices[reagent.itemID]
        if unit then row.unit:SetText(FormatMoney(unit)); local total=unit*reagent.qty; row.total:SetText(FormatMoney(total)); recipeTotal=recipeTotal+total
        else row.unit:SetText("—"); row.total:SetText("—"); missing=missing+1 end
        row:Show(); ry=ry-40
    end
    for i=#selected.reagents+1,#reagentRows do reagentRows[i]:Hide() end
    d.reagents.child:SetHeight(math.max(10,-ry+2)); d.reagents.Update()
    local summary=string.format("%s: %s",T("total"),FormatMoney(recipeTotal))
    if missing>0 then summary=summary.."   |cff90959d"..string.format(T("missing_prices"),missing).."|r" end
    d.summary:SetText(summary)
end

local function BuildRecipeView(parent)
    local p=CreateFrame("Frame",nil,parent); p:SetAllPoints(); p:Hide(); recipeView=p
    local listCard=Card(p); listCard:SetPoint("TOPLEFT",18,-18); listCard:SetPoint("BOTTOMLEFT",18,18)
    local lt=Text(listCard,T("recipes_title"),11,true); lt:SetPoint("TOPLEFT",12,-11); lt:SetTextColor(unpack(C.accent))
    local list=CreateScrollArea(listCard); list:SetPoint("TOPLEFT",10,-36); list:SetPoint("BOTTOMRIGHT",-10,10); p.list=list

    local d=Card(p); d:SetPoint("TOPLEFT",listCard,"TOPRIGHT",12,0); d:SetPoint("BOTTOMRIGHT",-18,18); p.detail=d
    local rt=Text(d,T("recipe_detail"),11,true); rt:SetPoint("TOPLEFT",14,-12); rt:SetTextColor(unpack(C.accent))
    d.icon=d:CreateTexture(nil,"ARTWORK"); d.icon:SetSize(50,50); d.icon:SetPoint("TOPLEFT",14,-40); d.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    d.name=Text(d,T("select_recipe"),13,true); d.name:SetPoint("TOPLEFT",d.icon,"TOPRIGHT",11,-1); d.name:SetPoint("RIGHT",-14,0); d.name:SetJustifyH("LEFT")
    d.summary=Text(d,"",9,false); d.summary:SetPoint("TOPLEFT",14,-101); d.summary:SetPoint("RIGHT",-14,0); d.summary:SetTextColor(unpack(C.dim)); d.summary:SetJustifyH("LEFT")

    local header=CreateFrame("Frame",nil,d,"BackdropTemplate"); header:SetPoint("TOPLEFT",10,-128); header:SetPoint("TOPRIGHT",-10,-128); header:SetHeight(24); Backdrop(header,C.panel2,C.border)
    local th=Text(header,T("total"),8,true); th:SetPoint("RIGHT",-8,0); th:SetWidth(112); th:SetJustifyH("RIGHT"); th:SetTextColor(unpack(C.dim))
    local uh=Text(header,T("unit_price"),8,true); uh:SetPoint("RIGHT",th,"LEFT",-8,0); uh:SetWidth(112); uh:SetJustifyH("RIGHT"); uh:SetTextColor(unpack(C.dim))
    local rh=Text(header,T("reagents"),9,true); rh:SetPoint("LEFT",12,0); rh:SetPoint("RIGHT",uh,"LEFT",-10,0); rh:SetJustifyH("LEFT"); rh:SetTextColor(unpack(C.dim))

    d.reagents=CreateScrollArea(d); d.reagents:SetPoint("TOPLEFT",10,-154); d.reagents:SetPoint("BOTTOMRIGHT",-10,10)

    local function LayoutRecipe()
        local w=p:GetWidth() or 0
        if w<=0 then return end
        listCard:SetWidth(math.max(300,math.min(360,math.floor(w*0.34))))
    end
    p:SetScript("OnSizeChanged",LayoutRecipe)
    p:SetScript("OnShow",function() LayoutRecipe(); Studio:RefreshRecipes() end)
end

-- ---------------------------------------------------------------------
-- Full scan
-- ---------------------------------------------------------------------
local function UpdateScanView()
    if not scanView then return end
    local db=GetDB()
    scanView.last:SetText(string.format("%s: %s",T("last_scan"),db.lastScan>0 and FormatAge(db.lastScan) or T("never")))
    scanView.progress:SetValue(scanProgress or 0)
    scanView.percent:SetFormattedText("%d%%",math.floor((scanProgress or 0)*100+0.5))
    scanView.status:SetText(scanStatus ~= "" and scanStatus or T("scan_desc"))
    if scanInProgress then scanView.button:Disable(); scanView.button:SetAlpha(0.45); scanView.button._label:SetText(T("scanning")); return end
    scanView.button:Enable(); scanView.button:SetAlpha(1); scanView.button._label:SetText(T("scan_btn"))
    local remain=SCAN_COOLDOWN-(time()-(db.lastScan or 0))
    if db.lastScan>0 and remain>0 then
        scanView.cooldown:SetText(string.format(T("next_scan"),math.floor(remain/60),math.floor(remain%60)))
    else scanView.cooldown:SetText("") end
end

local function FinishScan(success,prices,count)
    scanInProgress=false
    if scanAbortTimer then scanAbortTimer:Cancel(); scanAbortTimer=nil end
    if success then
        local db=GetDB(); db.prices=prices or {}; db.lastScan=time(); db.lastScanCount=count or 0
        scanProgress=1; scanStatus=string.format(T("scan_done"),count or 0)
    else
        scanProgress=0; scanStatus=T("scan_failed")
    end
    UpdateScanView()
    if recipeView and recipeView:IsShown() then Studio:RefreshRecipes() end
    if searchView and searchView:IsShown() then RefreshSearchResults() end
end

local function ProcessScanBatch(index,total,prices)
    if not scanInProgress then return end
    if index>=total then
        local count=0; for _ in pairs(prices) do count=count+1 end
        FinishScan(true,prices,count); return
    end
    local stop=math.min(total,index+SCAN_BATCH)
    for i=index,stop-1 do
        local info={C_AuctionHouse.GetReplicateItemInfo(i)}
        local count,buyout,itemID=info[3],info[10],info[17]
        if type(itemID)=="number" and type(count)=="number" and count>0 and type(buyout)=="number" and buyout>0 then
            local unit=math.ceil(buyout/count)
            if not prices[itemID] or unit<prices[itemID] then prices[itemID]=unit end
        end
    end
    scanProgress=0.20+(stop/math.max(total,1))*0.80
    scanStatus=string.format(T("scan_processing"),math.floor(scanProgress*100+0.5)); UpdateScanView()
    C_Timer.After(0.01,function() ProcessScanBatch(stop,total,prices) end)
end

local function StartFullScan()
    if scanInProgress then return end
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then scanStatus=T("only_ah"); UpdateScanView(); return end
    local db=GetDB(); local since=time()-(db.lastScan or 0)
    if db.lastScan>0 and since<SCAN_COOLDOWN then
        local r=SCAN_COOLDOWN-since; scanStatus=string.format(T("next_scan"),math.floor(r/60),math.floor(r%60)); UpdateScanView(); return
    end
    if not C_AuctionHouse or not C_AuctionHouse.ReplicateItems then scanStatus=T("scan_failed"); UpdateScanView(); return end
    scanInProgress=true; scanProgress=0.10; scanStatus=T("scan_wait"); UpdateScanView()
    Studio.eventFrame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    C_AuctionHouse.ReplicateItems()
    scanAbortTimer=C_Timer.NewTimer(90,function() if scanInProgress then Studio.eventFrame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE"); FinishScan(false) end end)
end

local function BuildScanView(parent)
    local p=CreateFrame("Frame",nil,parent); p:SetAllPoints(); p:Hide(); scanView=p
    local c=Card(p); c:SetPoint("TOPLEFT",80,-34); c:SetPoint("TOPRIGHT",-80,-34); c:SetHeight(296)
    local title=Text(c,T("scan_title"),16,true); title:SetPoint("TOPLEFT",24,-22); title:SetTextColor(unpack(C.accent))
    local desc=Text(c,T("scan_desc"),10,false); desc:SetPoint("TOPLEFT",24,-54); desc:SetPoint("RIGHT",-24,0); desc:SetJustifyH("LEFT"); desc:SetWordWrap(true); desc:SetTextColor(unpack(C.dim))
    p.last=Text(c,"",10,true); p.last:SetPoint("TOPLEFT",24,-108)

    local bar=CreateFrame("StatusBar",nil,c,"BackdropTemplate"); bar:SetPoint("TOPLEFT",24,-140); bar:SetPoint("TOPRIGHT",-24,-140); bar:SetHeight(20); bar:SetStatusBarTexture(WHITE8); bar:SetStatusBarColor(C.accent[1],C.accent[2],C.accent[3],0.92); bar:SetMinMaxValues(0,1); Backdrop(bar,{0.020,0.025,0.032,1},{C.accent[1],C.accent[2],C.accent[3],0.34}); p.progress=bar
    p.percent=Text(bar,"0%",9,true); p.percent:SetPoint("CENTER")

    p.status=Text(c,T("scan_desc"),9,false); p.status:SetPoint("TOPLEFT",24,-176); p.status:SetPoint("RIGHT",-24,0); p.status:SetJustifyH("LEFT"); p.status:SetWordWrap(true); p.status:SetTextColor(unpack(C.dim))
    p.button=Button(c,T("scan_btn"),240,32,StartFullScan); p.button:SetPoint("BOTTOMLEFT",24,24)
    p.cooldown=Text(c,"",9,false); p.cooldown:SetPoint("LEFT",p.button,"RIGHT",16,0); p.cooldown:SetPoint("RIGHT",-24,0); p.cooldown:SetJustifyH("LEFT"); p.cooldown:SetTextColor(unpack(C.yellow))
    p:SetScript("OnShow",UpdateScanView)
end

-- ---------------------------------------------------------------------
-- Main integrated tab
-- ---------------------------------------------------------------------
function Studio:SelectView(key)
    key=(key=="recipes" or key=="scan") and key or "search"
    currentView=key; HideAllViews(); SetNavSelected(key)
    if key=="search" then searchView:Show()
    elseif key=="recipes" then recipeView:Show()
    else scanView:Show() end
end

local function SelectTomoTab(view)
    if not frame or not AuctionHouseFrame then return end
    suppressDisplayHook=true
    if AuctionHouseFrame.SetDisplayMode then AuctionHouseFrame:SetDisplayMode({}) end
    suppressDisplayHook=false
    for _,tab in ipairs(AuctionHouseFrame.Tabs or {}) do PanelTemplates_DeselectTab(tab) end
    PanelTemplates_SelectTab(ahTab)
    if AuctionHouseFrame.SetTitle then AuctionHouseFrame:SetTitle(T("title")) end
    frame:Show(); Studio:SelectView(view or currentView)
end

local function BuildIntegration()
    if frame or not AuctionHouseFrame then return end

    frame=CreateFrame("Frame","TomoMod_TomoHDVFrame",AuctionHouseFrame,"BackdropTemplate")
    frame:SetPoint("TOP",0,-40); frame:SetPoint("LEFT",0,0); frame:SetPoint("BOTTOMRIGHT",-4,27)
    Backdrop(frame,C.bg,{0,0,0,0}); frame:Hide()

    local accent=frame:CreateTexture(nil,"ARTWORK"); accent:SetPoint("TOPLEFT",0,0); accent:SetPoint("BOTTOMLEFT",0,0); accent:SetWidth(3); accent:SetColorTexture(unpack(C.accent))
    local top=CreateFrame("Frame",nil,frame,"BackdropTemplate"); top:SetPoint("TOPLEFT",3,-4); top:SetPoint("TOPRIGHT",-4,-4); top:SetHeight(46); Backdrop(top,C.panel,{0,0,0,0})
    local keys={{"search",T("search")},{"recipes",T("recipes")},{"scan",T("scan")}}
    for _,def in ipairs(keys) do
        local key,label=def[1],def[2]
        local b=Button(top,label,136,30,function() Studio:SelectView(key) end)
        local line=b:CreateTexture(nil,"OVERLAY"); line:SetHeight(2); line:SetPoint("BOTTOMLEFT",1,1); line:SetPoint("BOTTOMRIGHT",-1,1); line:SetColorTexture(unpack(C.accent)); line:Hide(); b._selectedLine=line
        nav[key]=b
    end
    nav.recipes:SetPoint("CENTER",0,0)
    nav.search:SetPoint("RIGHT",nav.recipes,"LEFT",-8,0)
    nav.scan:SetPoint("LEFT",nav.recipes,"RIGHT",8,0)

    content=CreateFrame("Frame",nil,frame); content:SetPoint("TOPLEFT",3,-54); content:SetPoint("BOTTOMRIGHT",-4,4)
    BuildSearchView(content); BuildRecipeView(content); BuildScanView(content)

    -- Snapshot Blizzard's last native tab before our template can register
    -- TomoHDV into AuctionHouseFrame.Tabs. Reading the array afterwards can
    -- return ahTab itself and SetPoint would then anchor the tab to itself.
    local tabs=AuctionHouseFrame.Tabs or {}
    local anchor=tabs[#tabs]
    ahTab=CreateFrame("Button","TomoMod_TomoHDVTab",AuctionHouseFrame,"AuctionHouseFrameDisplayModeTabTemplate")
    ahTab:SetText(T("tab")); PanelTemplates_TabResize(ahTab,20,nil,70); PanelTemplates_DeselectTab(ahTab)
    if anchor and anchor~=ahTab then
        ahTab:SetPoint("TOPLEFT",anchor,"TOPRIGHT",3,0)
    else
        ahTab:SetPoint("TOPLEFT",AuctionHouseFrame,"TOPLEFT",60,-28)
    end
    ahTab:SetScript("OnClick",function() SelectTomoTab(currentView) end)

    if not Studio._displayHooked then
        Studio._displayHooked=true
        hooksecurefunc(AuctionHouseFrame,"SetDisplayMode",function()
            if suppressDisplayHook then return end
            if frame and frame:IsShown() then frame:Hide() end
            if ahTab then PanelTemplates_DeselectTab(ahTab) end
        end)
    end
    Studio.frame=frame; Studio.tab=ahTab
    Studio:SelectView(currentView)
end

function Studio:Open(view,searchTerm)
    if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then
        print("|cff2e9dd8TomoMod|r: "..T("only_ah")); return
    end
    BuildIntegration(); HideLegacyFrame(); SelectTomoTab(view or currentView)
    if searchTerm and searchTerm~="" then Studio:SelectView("search"); DoSearch(searchTerm) end
end

function Studio:Hide()
    if frame then frame:Hide() end
    if ahTab then PanelTemplates_DeselectTab(ahTab) end
end

Studio.eventFrame=Studio.eventFrame or CreateFrame("Frame")
Studio.eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
Studio.eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
Studio.eventFrame:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
Studio.eventFrame:RegisterEvent("AUCTION_HOUSE_NEW_RESULTS_RECEIVED")
Studio.eventFrame:RegisterEvent("COMMODITY_SEARCH_RESULTS_RECEIVED")
Studio.eventFrame:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
Studio.eventFrame:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
Studio.eventFrame:RegisterEvent("ITEM_SEARCH_RESULTS_ADDED")
Studio.eventFrame:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
Studio.eventFrame:RegisterEvent("COMMODITY_PURCHASE_FAILED")
Studio.eventFrame:RegisterEvent("AUCTION_HOUSE_PURCHASE_COMPLETED")
Studio.eventFrame:RegisterEvent("ITEM_KEY_ITEM_INFO_RECEIVED")
Studio.eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
Studio.eventFrame:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
Studio.eventFrame:RegisterEvent("TRACKED_RECIPE_UPDATE")
Studio.eventFrame:SetScript("OnEvent",function(self,event,...)
    if event=="AUCTION_HOUSE_SHOW" then
        C_Timer.After(0,function() if AuctionHouseFrame and AuctionHouseFrame:IsShown() then BuildIntegration(); HideLegacyFrame() end end)
    elseif event=="AUCTION_HOUSE_CLOSED" then
        if scanInProgress then self:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE"); FinishScan(false) end
        if frame then frame:Hide() end
    elseif event=="REPLICATE_ITEM_LIST_UPDATE" then
        self:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        if scanAbortTimer then scanAbortTimer:Cancel(); scanAbortTimer=nil end
        if not scanInProgress then return end
        local total=C_AuctionHouse.GetNumReplicateItems and C_AuctionHouse.GetNumReplicateItems() or 0
        scanProgress=0.20; scanStatus=string.format(T("scan_processing"),20); UpdateScanView()
        C_Timer.After(0.05,function() ProcessScanBatch(0,total,{}) end)
    elseif event=="AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event=="AUCTION_HOUSE_NEW_RESULTS_RECEIVED" then
        if searchView and searchView:IsShown() then RefreshSearchResults() end
    elseif event=="COMMODITY_SEARCH_RESULTS_RECEIVED" or event=="COMMODITY_SEARCH_RESULTS_UPDATED"
        or event=="ITEM_SEARCH_RESULTS_UPDATED" or event=="ITEM_SEARCH_RESULTS_ADDED" then
        if searchView and searchView:IsShown() and selectedSearch then RefreshPurchaseOffer() end
    elseif event=="COMMODITY_PURCHASE_SUCCEEDED" or event=="AUCTION_HOUSE_PURCHASE_COMPLETED" then
        if searchView and searchView:IsShown() and selectedSearch then
            SetPurchaseStatus(T("buy_ready"), C.green)
            C_Timer.After(0.10,function()
                if selectedSearch and searchView and searchView:IsShown() then RequestPurchaseSearch(selectedSearch) end
            end)
        end
    elseif event=="COMMODITY_PURCHASE_FAILED" then
        if searchView and searchView:IsShown() then SetPurchaseStatus(T("buy_failed"), C.red); SetPurchaseButton(false) end
    elseif event=="ITEM_KEY_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
        if searchView and searchView:IsShown() then
            RefreshSearchResults(); UpdateSearchDetail()
            if purchase.pendingInfo and selectedSearch then RequestPurchaseSearch(selectedSearch) end
        end
        if recipeView and recipeView:IsShown() then Studio:RefreshRecipes() end
    elseif event=="TRADE_SKILL_LIST_UPDATE" or event=="TRACKED_RECIPE_UPDATE" then
        if recipeView and recipeView:IsShown() then Studio:RefreshRecipes() end
    end
end)

-- Retire the floating frame from user-facing entry points. The old file stays
-- loaded for its saved-price tooltip injection and backward-compatible data.
ART.Show=function() Studio:Open("recipes") end
ART.Hide=function() Studio:Hide() end
ART.Refresh=function()
    if recipeView and recipeView:IsShown() then Studio:RefreshRecipes() end
    if searchView and searchView:IsShown() then RefreshSearchResults() end
end

SLASH_TOMOMODARTRACKER1="/tmrecipe"
SlashCmdList["TOMOMODARTRACKER"]=function() Studio:Open("recipes") end
