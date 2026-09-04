-- =====================================
-- ConsumableBar.lua — Ready / Consumable Tracker
-- Flacon | Bien nourri | Huile d'arme
-- Disponible partout, sans restriction de type de contenu.
-- Bouton intégré au panneau d'informations sous la minimap.
-- =====================================

TomoMod_ConsumableBar = TomoMod_ConsumableBar or {}
local CB = TomoMod_ConsumableBar

local pcall, ipairs = pcall, ipairs
local floor, format = math.floor, string.format
local GetTime = GetTime
local issecretvalue = issecretvalue

-- =====================================
-- CONSTANTES
-- =====================================

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local TEAL      = { r = 0.047, g = 0.824, b = 0.624 }
local RED       = { r = 0.95,  g = 0.20,  b = 0.20  }
local AMBER     = { r = 1.00,  g = 0.62,  b = 0.12  }
local WHITE     = { r = 1.00,  g = 1.00,  b = 1.00  }

-- Spell IDs des Flacons Midnight.
local FLASK_IDS = {
    [1235111] = true,   -- Flask of the Shattered Sun
    [1235057] = true,   -- Flask of Thalassian Resistance
    [1235108] = true,   -- Flask of the Magisters
    [1235110] = true,   -- Flask of the Blood Knights
}

-- Huile de phénix thalassienne.
-- GetWeaponEnchantInfo() renvoie l'EnchantID temporaire, pas le SpellID.
-- 1237008 -> enchant 8051 ; 1237006 -> enchant 8052.
local OIL_SPELL_BY_ENCHANT = {
    [8051] = 1237008,
    [8052] = 1237006,
}
local OIL_DEFAULT_SPELL_ID = 1237008

-- Plage de durée pour détecter un buff de nourriture (entre 50 min et 62 min).
local FOOD_DUR_MIN = 3000
local FOOD_DUR_MAX = 3720

local ICON_FOOD_DEFAULT = "Interface\\Icons\\inv_misc_food_15"

-- Glyphe maison, blanc et plat : c'est lui qui porte la couleur d'état,
-- via SetVertexColor. Une icône de sort ne pourrait pas être teintée.
local ICON_TRACKER = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\icon_consumables.tga"

-- Durées de prévisualisation (mode placement).
local PREVIEW_TIMES = {
    flask = 3480,   -- 58m
    food  = 2700,   -- 45m
    oil   = 7140,   -- 1h59m
}

local IS_FR = GetLocale and GetLocale() == "frFR"
local TXT = IS_FR and {
    title       = "Préparation",
    flask       = "Flacon",
    food        = "Bien nourri",
    oil         = "Huile d'arme",
    ready       = "OK",
    missing     = "Manquant",
    leftClick   = "Clic gauche : afficher / masquer",
    rightClick  = "Clic droit : changer de côté",
    sideLeft    = "Bouton placé à gauche de l'heure",
    sideRight   = "Bouton placé à droite de l'heure",
} or {
    title       = "Ready Check",
    flask       = "Flask",
    food        = "Well Fed",
    oil         = "Weapon Oil",
    ready       = "Ready",
    missing     = "Missing",
    leftClick   = "Left click: show / hide",
    rightClick  = "Right click: swap side",
    sideLeft    = "Button placed left of the clock",
    sideRight   = "Button placed right of the clock",
}

-- =====================================
-- STATE
-- =====================================

local frame         = nil
local slots         = nil
local dragOverlay   = nil
local dragLabel     = nil
local statusButton  = nil
local isLocked      = true
local updateTicker  = nil
local initialized   = false
local L             = nil

local buffData = {
    flask = nil,    -- { icon, expirationTime, spellID }
    food  = nil,
    oil   = nil,    -- { icon, expirationTime, spellID, ready, count, required }
}

-- =====================================
-- HELPERS
-- =====================================

local function DB()
    return TomoModDB and TomoModDB.consumableBar
end

local function IsSecret(value)
    if value == nil or not issecretvalue then return false end
    return issecretvalue(value)
end

local function SafeNumber(value, fallback)
    if value == nil or IsSecret(value) or type(value) ~= "number" then
        return fallback or 0
    end
    return value
end

local function GetSpellIconSafe(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
        if ok and tex then return tex end
    end
    if GetSpellInfo then
        local ok, _, _, tex = pcall(GetSpellInfo, spellID)
        if ok and tex then return tex end
    end
    return nil
end

local function FormatTime(sec)
    sec = SafeNumber(sec, 0)
    if sec >= 3600 then
        local h = floor(sec / 3600)
        local m = floor((sec % 3600) / 60)
        return format("%dh %02dm", h, m)
    elseif sec >= 60 then
        return format("%dm", floor(sec / 60))
    else
        return format("%ds", floor(sec))
    end
end

-- Contenu de groupe. Ne conditionne PAS l'affichage — le bouton est visible
-- partout — mais seulement la mise en couleur du glyphe : voir UpdateStatusButton().
local function IsEligibleContent()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
        return true
    end

    -- Midnight 12.x : Blizzard utilise C_DelvesUI.HasActiveDelve(mapID).
    -- Ce repli couvre un gouffre même si son instanceType évolue dans un patch.
    if C_DelvesUI and C_DelvesUI.HasActiveDelve and C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local ok, active = pcall(C_DelvesUI.HasActiveDelve, mapID)
            if ok and active then return true end
        end
    end

    return false
end

-- Seule condition d'affichage restante : la présence de l'horloge à laquelle
-- le bouton est ancré.
local function IsClockVisible()
    local clock = _G.TomoMod_ClockBar
    return clock and clock:IsShown()
end

local function IsAllReady()
    return buffData.flask ~= nil
       and buffData.food ~= nil
       and buffData.oil ~= nil
       and buffData.oil.ready ~= false
end

local function SavePosition()
    local db = DB()
    if not db or not frame then return end
    local left, bottom = frame:GetLeft(), frame:GetBottom()
    if not left or not bottom then return end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.position = {
        point         = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x             = left * scale,
        y             = bottom * scale,
    }
end

local function ApplyPosition()
    local db = DB()
    if not db or not frame then return end

    frame:ClearAllPoints()
    local p = db.position
    if p and p.point then
        frame:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
        return
    end

    local clock = _G.TomoMod_ClockBar
    if clock and clock:IsShown() then
        frame:SetPoint("TOP", clock, "BOTTOM", 0, -4)
    elseif Minimap then
        frame:SetPoint("TOP", Minimap, "BOTTOM", 0, -34)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -260)
    end
end

local function ApplyButtonAnchor()
    if not statusButton then return end

    local db = DB()
    local clock = _G.TomoMod_ClockBar
    statusButton:ClearAllPoints()

    if clock and clock:IsShown() then
        -- Le bouton est maintenant un ENFANT de la barre d'heure, pas un frame
        -- UIParent ancré aux FontStrings timeText/timeLabel. Il reste donc au-
        -- dessus de la barre quand l'heure ouvre le calendrier ou change de mode.
        if statusButton:GetParent() ~= clock then
            statusButton:SetParent(clock)
        end
        statusButton:SetFrameStrata(clock:GetFrameStrata())
        statusButton:SetFrameLevel((clock:GetFrameLevel() or 0) + 20)

        -- Dock stable autour du centre de la barre. Le texte peut changer de
        -- largeur (heure locale/serveur, 12/24 h) sans déplacer ni recouvrir le
        -- bouton, puisque l'ancre ne dépend plus du FontString.
        local buttonSize = db and tonumber(db.buttonSize) or 20
        buttonSize = math.max(14, math.min(32, buttonSize))
        local offset = 40 + (buttonSize * 0.5)
        if db and db.buttonSide == "right" then
            statusButton:SetPoint("CENTER", clock, "CENTER", offset, 0)
        else
            statusButton:SetPoint("CENTER", clock, "CENTER", -offset, 0)
        end
    elseif Minimap then
        if statusButton:GetParent() ~= UIParent then
            statusButton:SetParent(UIParent)
        end
        statusButton:SetFrameStrata("MEDIUM")
        statusButton:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 20)
        statusButton:SetPoint("TOP", Minimap, "BOTTOM", 0, -7)
    else
        if statusButton:GetParent() ~= UIParent then
            statusButton:SetParent(UIParent)
        end
        statusButton:SetFrameStrata("MEDIUM")
        statusButton:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -250)
    end
end

-- =====================================
-- SCAN BUFFS / HUILES
-- =====================================

local OILABLE_OFFHAND_EQUIP_LOCS = {
    INVTYPE_WEAPON        = true, -- arme à une main, utilisable dans les deux mains
    INVTYPE_WEAPONOFFHAND = true, -- arme explicitement main gauche
}

local function OffHandNeedsOil()
    local slot = INVSLOT_OFFHAND or 17
    local link = GetInventoryItemLink("player", slot)
    if not link then return false end

    if C_Item and C_Item.GetItemInfoInstant then
        local ok, _, _, _, itemEquipLoc, _, classID = pcall(C_Item.GetItemInfoInstant, link)
        if ok and classID ~= nil and not IsSecret(classID)
            and itemEquipLoc ~= nil and not IsSecret(itemEquipLoc) then
            local weaponClass = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2

            -- Un bouclier (INVTYPE_SHIELD) ou un objet « tenu en main gauche »
            -- (INVTYPE_HOLDABLE : tome, focus, orbe...) ne peut pas recevoir
            -- d'huile. On ne demande donc une seconde huile que pour une vraie
            -- arme équipée en main gauche.
            return classID == weaponClass and OILABLE_OFFHAND_EQUIP_LOCS[itemEquipLoc] == true
        end
    end

    return false
end

local function ScanWeaponOil()
    buffData.oil = nil
    if not GetWeaponEnchantInfo then return end

    local ok, hasMain, mainExpireMS, _, mainEnchantID,
              hasOff, offExpireMS, _, offEnchantID = pcall(GetWeaponEnchantInfo)
    if not ok then return end

    local required = OffHandNeedsOil() and 2 or 1
    local count = 0
    local minRemaining = nil
    local spellID = nil

    local function AcceptOil(hasEnchant, expireMS, enchantID)
        if not hasEnchant or IsSecret(hasEnchant) or IsSecret(enchantID) then return end
        local sid = OIL_SPELL_BY_ENCHANT[enchantID]
        if not sid then return end

        count = count + 1
        spellID = spellID or sid

        local remaining = SafeNumber(expireMS, 0) / 1000
        if remaining > 0 and (not minRemaining or remaining < minRemaining) then
            minRemaining = remaining
        end
    end

    AcceptOil(hasMain, mainExpireMS, mainEnchantID)
    if required == 2 then
        AcceptOil(hasOff, offExpireMS, offEnchantID)
    end

    if count > 0 then
        buffData.oil = {
            icon           = GetSpellIconSafe(spellID or OIL_DEFAULT_SPELL_ID),
            expirationTime = minRemaining and (GetTime() + minRemaining) or 0,
            spellID        = spellID or OIL_DEFAULT_SPELL_ID,
            ready          = count >= required,
            count          = count,
            required       = required,
        }
    end
end

local function ScanBuffs()
    buffData.flask = nil
    buffData.food  = nil

    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not ok or not aura then break end

        local spellID = aura and aura.spellId
        if not spellID then
            -- pas de spellID : passer à l'aura suivante
        elseif IsSecret(spellID) then
            -- Valeur protégée : ne pas la comparer / indexer.
        elseif FLASK_IDS[spellID] then
            if not buffData.flask then
                buffData.flask = {
                    icon           = aura.icon,
                    expirationTime = IsSecret(aura.expirationTime) and 0 or (aura.expirationTime or 0),
                    spellID        = spellID,
                }
            end
        elseif not buffData.food then
            local dur = aura.duration
            if not IsSecret(dur) then
                dur = dur or 0
                local src = aura.sourceUnit
                local selfApplied = (src == nil) or (src == "player") or (src == "")
                if dur >= FOOD_DUR_MIN and dur <= FOOD_DUR_MAX and selfApplied then
                    buffData.food = {
                        icon           = aura.icon,
                        expirationTime = IsSecret(aura.expirationTime) and 0 or (aura.expirationTime or 0),
                        spellID        = spellID,
                    }
                end
            end
        end
    end

    ScanWeaponOil()
end

-- =====================================
-- STATUS BUTTON
-- =====================================

local function UpdateStatusButton()
    if not statusButton then return end

    -- Hors contenu de groupe le glyphe reste blanc : le bouton est là, cliquable,
    -- consultable, mais il ne réclame rien. La couleur ne s'allume qu'en donjon,
    -- raid, scénario et gouffre, là où un consommable oublié se paie — et c'est
    -- ce passage du blanc au vert ou au rouge qui accroche l'œil.
    local c = WHITE
    if IsEligibleContent() then
        c = IsAllReady() and TEAL or RED
    end
    statusButton.icon:SetVertexColor(c.r, c.g, c.b, 1)
end

local function AddTooltipStatus(label, ready, suffix)
    local status = ready and TXT.ready or TXT.missing
    if suffix and suffix ~= "" then status = status .. " " .. suffix end
    if ready then
        GameTooltip:AddDoubleLine(label, status, 0.95, 0.95, 0.97, TEAL.r, TEAL.g, TEAL.b)
    else
        GameTooltip:AddDoubleLine(label, status, 0.95, 0.95, 0.97, RED.r, RED.g, RED.b)
    end
end

local function CreateStatusButton()
    if statusButton then return end

    statusButton = CreateFrame("Button", "TomoMod_ConsumableTrackerButton", UIParent, "BackdropTemplate")
    local db = DB()
    local buttonSize = db and tonumber(db.buttonSize) or 20
    buttonSize = math.max(14, math.min(32, buttonSize))
    statusButton:SetSize(buttonSize, buttonSize)
    statusButton:SetClampedToScreen(true)
    statusButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    statusButton:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    statusButton:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
    statusButton:SetBackdropBorderColor(0.15, 0.15, 0.17, 1)

    -- Le glyphe est déjà détouré : pas de SetTexCoord, sinon on rogne les dents
    -- de l'engrenage. Sa couleur est posée par UpdateStatusButton().
    local icon = statusButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexture(ICON_TRACKER)
    statusButton.icon = icon

    statusButton:SetScript("OnClick", function(_, button)
        local db = DB()
        if not db then return end

        if button == "RightButton" then
            db.buttonSide = db.buttonSide == "right" and "left" or "right"
            ApplyButtonAnchor()
        else
            db.expanded = not db.expanded
            if db.expanded then
                ScanBuffs()
            end
            CB.ApplySettings()
        end
    end)

    statusButton:SetScript("OnEnter", function(self)
        ScanBuffs()
        UpdateStatusButton()

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(TXT.title, 1, 1, 1)
        GameTooltip:AddLine(" ")
        AddTooltipStatus(TXT.flask, buffData.flask ~= nil)
        AddTooltipStatus(TXT.food, buffData.food ~= nil)

        local oilReady = buffData.oil ~= nil and buffData.oil.ready ~= false
        local oilSuffix = ""
        if buffData.oil and buffData.oil.required and buffData.oil.required > 1 then
            oilSuffix = format("(%d/%d)", buffData.oil.count or 0, buffData.oil.required)
        elseif not buffData.oil and OffHandNeedsOil() then
            oilSuffix = "(0/2)"
        end
        AddTooltipStatus(TXT.oil, oilReady, oilSuffix)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(TXT.leftClick, 0.75, 0.75, 0.78)
        GameTooltip:AddLine(TXT.rightClick, 0.75, 0.75, 0.78)
        local db = DB()
        GameTooltip:AddLine(db and db.buttonSide == "right" and TXT.sideRight or TXT.sideLeft, AMBER.r, AMBER.g, AMBER.b)
        GameTooltip:Show()
    end)

    statusButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ApplyButtonAnchor()
    UpdateStatusButton()
    statusButton:Hide()
end

-- =====================================
-- LAYOUT & UPDATE SLOTS
-- =====================================

local function UpdateAllSlots(isPreview)
    if not slots or not frame then return end
    local db = DB()
    if not db then return end

    local iconSize    = db.iconSize    or 36
    local gap         = db.gap         or 4
    local showMissing = db.showMissing ~= false
    local orientation = db.orientation or "horizontal"
    local timerPos    = db.timerPos    or "below"
    local now         = GetTime()

    if orientation == "horizontal" and (timerPos == "right" or timerPos == "left") then
        timerPos = "below"
    elseif orientation == "vertical" and (timerPos == "above" or timerPos == "below") then
        timerPos = "right"
    end

    -- Le tracker se redimensionne réellement avec iconSize : la zone du timer
    -- et sa police suivent aussi la taille des icônes au lieu de rester figées.
    local TIMER_H = math.max(12, floor(iconSize * 0.40))
    local TIMER_W = math.max(36, floor(iconSize * 1.15))
    local timerFontSize = math.max(8, math.min(14, floor(iconSize * 0.28 + 0.5)))

    local slotW, slotH
    if orientation == "vertical" then
        slotW = iconSize + TIMER_W
        slotH = iconSize
    else
        slotW = iconSize
        slotH = iconSize + TIMER_H
    end

    local prevSlot     = nil
    local visibleCount = 0

    for _, slotDef in ipairs(slots) do
        local slot = slotDef.frame
        local key  = slotDef.key
        local data = buffData[key]

        local shouldShow = true
        if not isPreview and not showMissing and not data then
            shouldShow = false
        end

        if shouldShow then
            slot:SetSize(slotW, slotH)
            slot.timer:SetFont(FONT, timerFontSize, "OUTLINE")

            slot.icon:ClearAllPoints()
            if orientation == "vertical" then
                if timerPos == "left" then
                    slot.icon:SetPoint("TOPRIGHT",    slot, "TOPRIGHT",    -1, -1)
                    slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1,  1)
                else
                    slot.icon:SetPoint("TOPLEFT",    slot, "TOPLEFT",    1, -1)
                    slot.icon:SetPoint("BOTTOMLEFT", slot, "BOTTOMLEFT", 1,  1)
                end
                slot.icon:SetWidth(iconSize - 2)
            else
                if timerPos == "above" then
                    slot.icon:SetPoint("BOTTOMLEFT",  slot, "BOTTOMLEFT",   1,  1)
                    slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1,  1)
                else
                    slot.icon:SetPoint("TOPLEFT",  slot, "TOPLEFT",   1, -1)
                    slot.icon:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -1, -1)
                end
                slot.icon:SetHeight(iconSize - 2)
            end

            slot.timer:ClearAllPoints()
            if orientation == "vertical" then
                if timerPos == "left" then
                    slot.timer:SetPoint("LEFT", slot, "LEFT", 2, 0)
                    slot.timer:SetJustifyH("LEFT")
                else
                    slot.timer:SetPoint("RIGHT", slot, "RIGHT", -2, 0)
                    slot.timer:SetJustifyH("RIGHT")
                end
            else
                if timerPos == "above" then
                    slot.timer:SetPoint("TOP", slot, "TOP", 0, -1)
                else
                    slot.timer:SetPoint("BOTTOM", slot, "BOTTOM", 0, 1)
                end
                slot.timer:SetJustifyH("CENTER")
            end

            if isPreview then
                slot.icon:SetTexture(slotDef.defaultIcon)
                slot.icon:SetDesaturated(false)
                slot.icon:SetAlpha(1)
                slot.currentSpellID = nil
                slot.timer:SetText(FormatTime(PREVIEW_TIMES[key] or 3480))
                slot.timer:SetTextColor(1, 1, 1)
                slot.timer:Show()
                slot:SetBackdropBorderColor(TEAL.r, TEAL.g, TEAL.b, 0.85)

            elseif data then
                local ready = data.ready ~= false
                slot.icon:SetTexture(data.icon or slotDef.defaultIcon)
                slot.icon:SetDesaturated(not ready)
                slot.icon:SetAlpha(ready and 1 or 0.55)
                slot.currentSpellID = data.spellID

                if not ready and data.count and data.required then
                    slot.timer:SetText(format("%d/%d", data.count, data.required))
                    slot.timer:SetTextColor(RED.r, RED.g, RED.b)
                    slot.timer:Show()
                else
                    local expirationTime = SafeNumber(data.expirationTime, 0)
                    local rem = expirationTime > 0 and (expirationTime - now) or 0
                    if rem > 0 then
                        if rem < 300 then
                            slot.timer:SetTextColor(1, 0.35, 0.35)
                        else
                            slot.timer:SetTextColor(1, 1, 1)
                        end
                        slot.timer:SetText(FormatTime(rem))
                        slot.timer:Show()
                    else
                        slot.timer:Hide()
                    end
                end

                if ready then
                    slot:SetBackdropBorderColor(TEAL.r * 0.6, TEAL.g * 0.6, TEAL.b * 0.6, 1)
                else
                    slot:SetBackdropBorderColor(RED.r, RED.g, RED.b, 0.9)
                end

            else
                slot.icon:SetTexture(slotDef.defaultIcon)
                slot.icon:SetDesaturated(true)
                slot.icon:SetAlpha(0.28)
                slot.currentSpellID = nil
                slot.timer:Hide()
                slot:SetBackdropBorderColor(RED.r * 0.75, RED.g * 0.75, RED.b * 0.75, 0.85)
            end

            slot:ClearAllPoints()
            if not prevSlot then
                slot:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            elseif orientation == "vertical" then
                slot:SetPoint("TOPLEFT", prevSlot, "BOTTOMLEFT", 0, -gap)
            else
                slot:SetPoint("TOPLEFT", prevSlot, "TOPRIGHT", gap, 0)
            end

            slot:Show()
            prevSlot = slot
            visibleCount = visibleCount + 1
        else
            slot:Hide()
        end
    end

    if visibleCount > 0 then
        if orientation == "vertical" then
            frame:SetSize(slotW, visibleCount * slotH + (visibleCount - 1) * gap)
        else
            frame:SetSize(visibleCount * slotW + (visibleCount - 1) * gap, slotH)
        end
    elseif not isLocked then
        frame:SetSize(slotW, slotH)
    end
end

-- =====================================
-- CRÉATION DES SLOTS
-- =====================================

local function CreateSlot(parent, key, defaultIcon)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    slot.key            = key
    slot.defaultIcon    = defaultIcon
    slot.currentSpellID = nil

    slot:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    slot:SetBackdropColor(0, 0, 0, 0.65)
    slot:SetBackdropBorderColor(0.15, 0.15, 0.17, 1)

    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("TOPLEFT",  slot, "TOPLEFT",  1, -1)
    icon:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -1, -1)
    slot.icon = icon

    local timer = slot:CreateFontString(nil, "OVERLAY")
    timer:SetFont(FONT, 10, "OUTLINE")
    timer:SetPoint("BOTTOM", slot, "BOTTOM", 0, 1)
    timer:SetTextColor(1, 1, 1)
    timer:SetJustifyH("CENTER")
    timer:Hide()
    slot.timer = timer

    slot:EnableMouse(true)
    slot:SetScript("OnEnter", function(self)
        if self.currentSpellID then
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            local ok = pcall(GameTooltip.SetSpellByID, GameTooltip, self.currentSpellID)
            if ok then GameTooltip:Show() end
        end
    end)
    slot:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return slot
end

-- =====================================
-- CRÉATION DE LA BARRE
-- =====================================

local function CreateBar()
    if frame then return end
    local db = DB()
    if not db then return end

    local iconSize = db.iconSize or 36
    local timerH   = 14

    frame = CreateFrame("Frame", "TomoMod_ConsumableBar", UIParent, "BackdropTemplate")
    frame:SetSize(iconSize * 3 + 8, iconSize + timerH)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(60)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:Hide()

    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.04, 0.04, 0.06, 0.88)
    frame:SetBackdropBorderColor(0.12, 0.12, 0.14, 1)

    ApplyPosition()

    dragOverlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    dragOverlay:SetAllPoints()
    dragOverlay:SetFrameLevel(frame:GetFrameLevel() + 20)
    -- Unified Layout Mode appearance from Core/Utils.lua.
    if TomoMod_Utils and TomoMod_Utils.StyleMoverOverlay then
        TomoMod_Utils.StyleMoverOverlay(dragOverlay, (TomoMod_L and TomoMod_L["mover_consumable_bar"]))
    end
    dragOverlay:EnableMouse(true)
    dragOverlay:RegisterForDrag("LeftButton")
    dragOverlay:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragOverlay:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition()
    end)

    dragLabel = dragOverlay._tmMoverText
    dragOverlay:Hide()

    local defaultFlaskIcon = GetSpellIconSafe(1235111) or 134906
    local defaultOilIcon   = GetSpellIconSafe(OIL_DEFAULT_SPELL_ID) or 134906

    slots = {}
    local slotDefs = {
        { key = "flask", defaultIcon = defaultFlaskIcon  },
        { key = "food",  defaultIcon = ICON_FOOD_DEFAULT },
        { key = "oil",   defaultIcon = defaultOilIcon    },
    }
    for i, def in ipairs(slotDefs) do
        local slot = CreateSlot(frame, def.key, def.defaultIcon)
        slotDefs[i].frame = slot
        slots[i] = slotDefs[i]
    end
end

-- =====================================
-- VISIBILITÉ / REFRESH
-- =====================================

local function UpdateVisibility()
    if not frame then return end
    local db = DB()

    if not db or not db.enabled or not IsClockVisible() then
        frame:Hide()
        if statusButton then statusButton:Hide() end
        return
    end

    ApplyButtonAnchor()
    if statusButton then
        UpdateStatusButton()
        statusButton:Show()
    end

    if not db.position then
        ApplyPosition()
    end

    if not isLocked then
        frame:Show()
    elseif db.expanded then
        frame:Show()
    else
        frame:Hide()
    end
end

local function Refresh()
    if not frame then return end
    ScanBuffs()
    UpdateAllSlots(not isLocked)
    UpdateStatusButton()
    UpdateVisibility()
end

-- =====================================
-- LOCK / UNLOCK (Mover)
-- =====================================

local function SetLockedInternal(locked)
    isLocked = locked
    if not frame then return end

    if locked then
        if dragOverlay then dragOverlay:Hide() end
        Refresh()
    else
        if dragOverlay then dragOverlay:Show() end
        UpdateAllSlots(true)
        UpdateVisibility()
    end
end

function CB.SetLocked(locked)
    SetLockedInternal(locked)
end

function CB.ToggleLock()
    SetLockedInternal(not isLocked)
    return isLocked
end

function CB.IsLocked()
    return isLocked
end

-- =====================================
-- APPLY SETTINGS
-- =====================================

function CB.ApplySettings()
    if not frame then return end

    local db = DB()
    if not db then return end

    -- Taille du bouton et du tracker appliquées à chaud depuis le GUI.
    db.buttonSize = math.max(14, math.min(32, tonumber(db.buttonSize) or 20))
    db.iconSize = math.max(24, math.min(56, tonumber(db.iconSize) or 36))
    if statusButton then
        statusButton:SetSize(db.buttonSize, db.buttonSize)
    end

    if dragLabel and L then
        dragLabel:SetText(L["mover_consumable_bar"] or "Consommables")
    end

    ApplyButtonAnchor()
    Refresh()
end

-- =====================================
-- EVENTS
-- =====================================

local function OnEvent(_, event, unit)
    if (event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED") and unit ~= "player" then
        return
    end

    Refresh()
end

-- =====================================
-- INITIALIZE
-- =====================================

function CB.Initialize()
    if initialized then return end
    initialized = true

    L = TomoMod_L

    local db = DB()
    if not db then return end

    -- L'ancien ConsumableBar était livré désactivé et non chargé. La première
    -- initialisation de la V1 Ready Tracker l'active une seule fois, sans écraser
    -- ensuite un choix utilisateur explicite.
    if not db.readyTrackerMigrated then
        db.enabled = true
        db.showMissing = true
        db.expanded = false
        db.buttonSide = "left"
        db.buttonSize = 20
        db.readyTrackerMigrated = true
    else
        if db.expanded == nil then db.expanded = false end
        if db.buttonSide ~= "right" then db.buttonSide = "left" end
        if db.buttonSize == nil then db.buttonSize = 20 end
        if db.showMissing == nil then db.showMissing = true end
    end

    CreateBar()
    CreateStatusButton()

    local eventFrame = CreateFrame("Frame")
    -- [PERF v4] Ces deux evenements n'interessent que le joueur : OnEvent
    -- sortait aussitot pour toute autre unite. Enregistres globalement, ils
    -- reveillaient le handler pour chaque changement d'aura de chaque unite
    -- visible -- soit, en raid, des centaines de reveils par seconde pour
    -- un test qui retourne immediatement. Le filtre est fait par le client.
    if eventFrame.RegisterUnitEvent then
        eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
        eventFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
    else
        eventFrame:RegisterEvent("UNIT_AURA")
        eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    end
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:SetScript("OnEvent", OnEvent)

    updateTicker = C_Timer.NewTicker(1, function()
        local liveDB = DB()
        if liveDB and liveDB.enabled then
            Refresh()
        else
            UpdateVisibility()
        end
    end)

    -- InfoPanel construit sa barre d'heure avec un léger délai : ce refresh
    -- replace le bouton et la frame sur l'horloge dès qu'elle existe.
    C_Timer.After(1.2, Refresh)
    Refresh()
end
