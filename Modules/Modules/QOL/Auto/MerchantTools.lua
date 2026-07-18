-- =====================================
-- MerchantTools.lua
-- AlreadyKnown : désature/teinte les items déjà possédés
--                (montures, mascottes, jouets, transmogrification,
--                 recettes/sorts) dans les fenêtres marchand et rachat.
-- ExtendPages  : étend la fenêtre marchand pour afficher plusieurs
--                colonnes de 10 items (N × BLIZZARD_ITEMS_PER_PAGE).
--
-- Inspiré de ElvUI_WindTools – AlreadyKnown.lua & ExtendMerchantPages.lua
-- Adapté au style TomoMod (pas d'ElvUI, pas d'AceHook).
-- =====================================

TomoMod_MerchantTools = TomoMod_MerchantTools or {}
local MT = TomoMod_MerchantTools

-- =====================================
-- LOCALS
-- =====================================
local ipairs        = ipairs
local strmatch      = strmatch
local strfind       = strfind
local tonumber      = tonumber

-- Valeur Blizzard de base ; on ne lit PAS _G.MERCHANT_ITEMS_PER_PAGE ici
-- car Blizzard_MerchantUI n'est pas encore chargé au démarrage.
local BLIZZARD_ITEMS_PER_PAGE = 10

-- Addons qui gèrent déjà l'extension du marchand ; on leur cède la place.
local CONFLICTING_ADDONS = { "ExtVendor", "Krowi_ExtendedVendorUI", "CompactVendor" }

-- Cache de liens "déjà connu" réinitialisé à chaque fermeture du marchand.
local knowns = {}

-- =====================================
-- ACCÈS AUX PARAMÈTRES
-- =====================================
local function GetDB()
    return TomoModDB and TomoModDB.merchantTools
end

-- =====================================
-- ALREADY KNOWN — DÉTECTION
-- =====================================

local function IsPetCollected(speciesID)
    if not speciesID then return false end
    local ok, num = pcall(C_PetJournal.GetNumCollectedInfo, speciesID)
    return ok and num and num > 0
end

local function IsMountCollected(itemID)
    local mountID = C_MountJournal.GetMountFromItem(itemID)
    if not mountID then return false end
    return select(11, C_MountJournal.GetMountInfoByID(mountID)) == true
end

local function IsToyCollected(itemID)
    return C_ToyBox.GetToyInfo(itemID) ~= nil and PlayerHasToy(itemID)
end

local function IsPetItemCollected(itemID)
    local speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemID))
    return speciesID and IsPetCollected(speciesID)
end

local transmogInventoryTypes = {
    [Enum.InventoryType.IndexBodyType]   = true,
    [Enum.InventoryType.IndexTabardType] = true,
}

local function IsTransmogCollected(itemID)
    if not C_Item.IsCosmeticItem(itemID) then
        local invType = C_Item.GetItemInventoryTypeByID(itemID)
        if not transmogInventoryTypes[invType] then
            return false
        end
    end
    return C_TransmogCollection.PlayerHasTransmogByItemInfo(itemID)
end

local function IsTransmogSetCollected(itemID)
    if not C_Item.GetItemLearnTransmogSet then return false end
    local setID = C_Item.GetItemLearnTransmogSet(itemID)
    if not setID then return false end
    local info = C_TransmogSets.GetSetInfo and C_TransmogSets.GetSetInfo(setID)
    if not info then return false end
    if info.collected then return true end
    if not C_Transmog.GetAllSetAppearancesByID or not ContainsIf then return false end
    local items = C_Transmog.GetAllSetAppearancesByID(setID)
    if not items then return false end
    return not ContainsIf(items, function(item)
        return not C_TransmogCollection.PlayerHasTransmogByItemInfo(item.itemID)
    end)
end

local knowableClasses = {
    [Enum.ItemClass.Consumable]      = true,
    [Enum.ItemClass.Weapon]          = true,
    [Enum.ItemClass.Armor]           = true,
    [Enum.ItemClass.ItemEnhancement] = true,
    [Enum.ItemClass.Recipe]          = true,
    [Enum.ItemClass.Miscellaneous]   = true,
    [Enum.ItemClass.Battlepet]       = true,
}

-- Initialisé dans RegisterHooks() une fois Blizzard_MerchantUI chargé.
local PET_SEARCH_PATTERN = nil

local function IsKnown(link)
    if not link then return false end

    local linkType, linkID = strmatch(link, "|H(%a+):(%d+)")
    linkID = tonumber(linkID)
    if not linkID then return false end

    if linkType == "battlepet" then
        return IsPetCollected(linkID)

    elseif linkType == "item" then
        if knowns[link] then return true end

        local classID = select(6, C_Item.GetItemInfoInstant(link))
        if not knowableClasses[classID] then return false end

        if IsMountCollected(linkID)
            or IsToyCollected(linkID)
            or IsPetItemCollected(linkID)
            or IsTransmogCollected(linkID)
            or IsTransmogSetCollected(linkID)
        then
            knowns[link] = true
            return true
        end

        -- Repli : parse le tooltip (COLLECTED / ITEM_SPELL_KNOWN).
        local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
        if ok and data and data.lines then
            for _, line in ipairs(data.lines) do
                local text = line.leftText
                if text then
                    if (COLLECTED and strfind(text, COLLECTED, 1, true))
                        or (ITEM_SPELL_KNOWN and strfind(text, ITEM_SPELL_KNOWN, 1, true))
                        or (PET_SEARCH_PATTERN and strmatch(text, PET_SEARCH_PATTERN))
                    then
                        knowns[link] = true
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- =====================================
-- ALREADY KNOWN — APPLICATION DU STYLE
-- =====================================

local function ApplyKnownStyle(tex, link, numAvailable)
    local db = GetDB()
    if not db or not db.alreadyKnown.enabled then
        tex:SetDesaturated(false)
        tex:SetVertexColor(1, 1, 1)
        return
    end

    if IsKnown(link) then
        if db.alreadyKnown.mode == "MONOCHROME" then
            tex:SetDesaturated(true)
        else
            local r = db.alreadyKnown.color.r
            local g = db.alreadyKnown.color.g
            local b = db.alreadyKnown.color.b
            if numAvailable == 0 then
                r, g, b = r * 0.5, g * 0.5, b * 0.5
            end
            tex:SetDesaturated(false)
            tex:SetVertexColor(r, g, b)
        end
    else
        tex:SetDesaturated(false)
        tex:SetVertexColor(1, 1, 1)
    end
end

-- Scan tous les slots affichés du marchand.
local function OnMerchantUpdate()
    local db = GetDB()
    if not db or not db.alreadyKnown.enabled then return end

    -- _G.MERCHANT_ITEMS_PER_PAGE est défini par Blizzard_MerchantUI (maintenant chargé).
    local perPage = _G.MERCHANT_ITEMS_PER_PAGE or BLIZZARD_ITEMS_PER_PAGE

    for i = 1, perPage do
        local button = _G["MerchantItem" .. i .. "ItemButton"]
        local tex    = _G["MerchantItem" .. i .. "ItemButtonIconTexture"]
        if not button or not tex then break end
        if button:IsShown() then
            -- button:GetID() retourne l'index global de l'item (posé par Blizzard).
            local itemIndex = button:GetID()
            if itemIndex and itemIndex > 0 then
                local link = GetMerchantItemLink(itemIndex)
                if link then
                    local info = C_MerchantFrame.GetItemInfo(itemIndex)
                    local numAvailable = info and info.numAvailable or -1
                    ApplyKnownStyle(tex, link, numAvailable)
                end
            end
        end
    end
end

local function OnBuybackUpdate()
    local db = GetDB()
    if not db or not db.alreadyKnown.enabled then return end

    local numItems = GetNumBuybackItems()
    for i = 1, (BUYBACK_ITEMS_PER_PAGE or 12) do
        if i > numItems then break end
        local button = _G["MerchantItem" .. i .. "ItemButton"]
        local tex    = _G["MerchantItem" .. i .. "ItemButtonIconTexture"]
        if button and tex and button:IsShown() then
            local link = GetBuybackItemLink(i)
            if link then
                ApplyKnownStyle(tex, link, -1)
            end
        end
    end
end

-- =====================================
-- EXTEND PAGES — REPOSITIONNEMENT
-- =====================================

local function RepositionMerchantItems()
    local db = GetDB()
    if not db or not db.extendPages.enabled then return end

    local perPage = _G.MERCHANT_ITEMS_PER_PAGE or BLIZZARD_ITEMS_PER_PAGE

    for i = 1, perPage do
        local button = _G["MerchantItem" .. i]
        if not button then break end

        button:Show()
        button:ClearAllPoints()

        if (i % BLIZZARD_ITEMS_PER_PAGE) == 1 then
            if i == 1 then
                button:SetPoint("TOPLEFT", _G.MerchantFrame, "TOPLEFT", 11, -69)
            else
                button:SetPoint(
                    "TOPLEFT",
                    _G["MerchantItem" .. (i - (BLIZZARD_ITEMS_PER_PAGE - 1))],
                    "TOPRIGHT", 12, 0
                )
            end
        elseif (i % 2) == 1 then
            button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 2)], "BOTTOMLEFT", 0, -8)
        else
            button:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", 12, 0)
        end
    end
end

-- =====================================
-- ENREGISTREMENT DES HOOKS
-- (appelé seulement APRÈS chargement de Blizzard_MerchantUI)
-- =====================================

local function RegisterHooks()
    -- Initialiser le motif de recherche de mascotte.
    if not PET_SEARCH_PATTERN and ITEM_PET_KNOWN then
        PET_SEARCH_PATTERN = strmatch(ITEM_PET_KNOWN, "[^%(（]+")
    end

    local db = GetDB()
    if not db then return end

    -- Already Known hooks.
    if not MT._akHooked then
        if MerchantFrame_UpdateMerchantInfo then
            hooksecurefunc("MerchantFrame_UpdateMerchantInfo", OnMerchantUpdate)
        end
        if MerchantFrame_UpdateBuybackInfo then
            hooksecurefunc("MerchantFrame_UpdateBuybackInfo", OnBuybackUpdate)
        end
        MT._akHooked = true
    end

    -- Extend Pages (une seule fois).
    if not MT._extendInitialized and db.extendPages.enabled then
        for _, addon in ipairs(CONFLICTING_ADDONS) do
            if C_AddOns.IsAddOnLoaded(addon) then return end
        end

        local numPages = db.extendPages.numberOfPages
        _G.MERCHANT_ITEMS_PER_PAGE = numPages * BLIZZARD_ITEMS_PER_PAGE
        _G.MerchantFrame:SetWidth(30 + numPages * 330)

        for i = 1, _G.MERCHANT_ITEMS_PER_PAGE do
            if not _G["MerchantItem" .. i] then
                local frame = CreateFrame("Frame", "MerchantItem" .. i, _G.MerchantFrame, "MerchantItemTemplate")
                local altCurrency = _G["MerchantItem" .. i .. "AltCurrencyFrame"]
                if altCurrency then altCurrency:Hide() end
            end
        end

        _G.MerchantBuyBackItem:ClearAllPoints()
        _G.MerchantBuyBackItem:SetPoint("TOPLEFT", _G.MerchantItem10, "BOTTOMLEFT", 30, -53)

        local buttonOffset = 25 + ((numPages - 1) * 165)
        _G.MerchantPrevPageButton:ClearAllPoints()
        _G.MerchantPrevPageButton:SetPoint("CENTER", _G.MerchantFrame, "BOTTOMLEFT", buttonOffset, 93)
        _G.MerchantPageText:ClearAllPoints()
        _G.MerchantPageText:SetPoint("BOTTOM", _G.MerchantFrame, "BOTTOM", 0, 86)
        _G.MerchantNextPageButton:ClearAllPoints()
        _G.MerchantNextPageButton:SetPoint("CENTER", _G.MerchantFrame, "BOTTOMRIGHT", -buttonOffset, 93)

        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", RepositionMerchantItems)
        MT._extendInitialized = true
    end
end

-- =====================================
-- FRAME D'ÉVÉNEMENTS
-- =====================================

local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("MERCHANT_SHOW")
mainFrame:RegisterEvent("MERCHANT_CLOSED")

mainFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        -- Blizzard_MerchantUI vient de charger : on peut hooker en toute sécurité.
        if arg1 == "Blizzard_MerchantUI" then
            RegisterHooks()
        end

    elseif event == "MERCHANT_SHOW" then
        -- Sécurité : si l'addon n'avait pas encore chargé lors du ADDON_LOADED,
        -- on tente les hooks maintenant.
        RegisterHooks()
        -- Déclencher le scan après que Blizzard a fini de peupler les slots.
        C_Timer.After(0.05, OnMerchantUpdate)

    elseif event == "MERCHANT_CLOSED" then
        knowns = {}
    end
end)

-- =====================================
-- API PUBLIQUE
-- =====================================

function MT.SetAlreadyKnownEnabled(v)
    local db = GetDB()
    if not db then return end
    db.alreadyKnown.enabled = v
    -- Ré-essayer les hooks si non encore enregistrés.
    if v and not MT._akHooked then
        RegisterHooks()
    end
    knowns = {}
    if MerchantFrame and MerchantFrame:IsShown() then
        OnMerchantUpdate()
    end
end

function MT.SetMode(mode)
    local db = GetDB()
    if not db then return end
    db.alreadyKnown.mode = mode
    knowns = {}
    if MerchantFrame and MerchantFrame:IsShown() then
        OnMerchantUpdate()
    end
end

function MT.SetColor(r, g, b)
    local db = GetDB()
    if not db then return end
    db.alreadyKnown.color.r = r
    db.alreadyKnown.color.g = g
    db.alreadyKnown.color.b = b
    knowns = {}
    if MerchantFrame and MerchantFrame:IsShown() then
        OnMerchantUpdate()
    end
end


