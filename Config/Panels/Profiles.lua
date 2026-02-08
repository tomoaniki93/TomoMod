-- =====================================
-- Panels/Profiles.lua — Profils (3 onglets)
-- Tab 1: Profil global / par spécialisation
-- Tab 2: Import / Export sécurisé
-- Tab 3: Réinitialisations modules
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L
local T = W.Theme
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"

-- =====================================
-- TAB 1 : PROFILS (Global & Spécialisations)
-- =====================================

local function BuildProfileTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- Section : mode de profil
    local _, ny = W.CreateSectionHeader(c, L["section_profile_mode"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_spec_profiles"], y)
    y = ny

    -- Toggle profils par spécialisation
    TomoMod_Profiles.EnsureProfilesDB()
    local useSpec = TomoModDB._profiles.useSpecProfiles

    local _, ny = W.CreateCheckbox(c, L["opt_enable_spec_profiles"], useSpec, y, function(v)
        if v then
            TomoMod_Profiles.EnableSpecProfiles()
        else
            TomoMod_Profiles.DisableSpecProfiles()
        end
        StaticPopup_Show("TOMOMOD_PROFILE_RELOAD")
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    -- Status actuel
    local specID = TomoMod_Profiles.GetCurrentSpecID()
    local allSpecs = TomoMod_Profiles.GetAllSpecs()

    if useSpec then
        -- Afficher le profil actif
        local activeLabel = L["profile_global"]
        for _, spec in ipairs(allSpecs) do
            if spec.id == specID then
                activeLabel = spec.name
                break
            end
        end

        local _, ny = W.CreateInfoText(c, "|cff0cd29f" .. L["profile_status"] .. ":|r " .. activeLabel, y)
        y = ny

        -- Liste des spécialisations
        local _, ny = W.CreateSectionHeader(c, L["section_spec_list"], y)
        y = ny

        for _, spec in ipairs(allSpecs) do
            local hasSaved = TomoMod_Profiles.HasSpecProfile(spec.id)
            local isCurrent = (spec.id == specID)

            -- Ligne par spec
            local row = CreateFrame("Frame", nil, c)
            row:SetPoint("TOPLEFT", 10, y)
            row:SetPoint("RIGHT", -10, 0)
            row:SetHeight(36)

            -- Icône de la spé
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("LEFT", 0, 0)
            icon:SetTexture(spec.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Nom de la spé
            local nameFS = row:CreateFontString(nil, "OVERLAY")
            nameFS:SetFont(FONT, 11, "")
            nameFS:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameFS:SetTextColor(unpack(T.text))
            nameFS:SetText(spec.name)

            -- Badge status
            local statusFS = row:CreateFontString(nil, "OVERLAY")
            statusFS:SetFont(FONT, 10, "")
            statusFS:SetPoint("LEFT", nameFS, "RIGHT", 10, 0)

            local function UpdateBadge()
                local saved = TomoMod_Profiles.HasSpecProfile(spec.id)
                if isCurrent then
                    statusFS:SetText("|cff0cd29f● " .. L["profile_badge_active"] .. "|r")
                elseif saved then
                    statusFS:SetText("|cffffff00● " .. L["profile_badge_saved"] .. "|r")
                else
                    statusFS:SetText("|cff666666● " .. L["profile_badge_none"] .. "|r")
                end
            end
            UpdateBadge()

            -- Bouton "Copier vers"
            local copyBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
            copyBtn:SetSize(110, 22)
            copyBtn:SetPoint("RIGHT", -120, 0)
            copyBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            copyBtn:SetBackdropColor(unpack(T.bgLight))
            copyBtn:SetBackdropBorderColor(unpack(T.border))

            local copyText = copyBtn:CreateFontString(nil, "OVERLAY")
            copyText:SetFont(FONT, 9, "")
            copyText:SetPoint("CENTER")
            copyText:SetTextColor(unpack(T.text))
            copyText:SetText(L["btn_copy_to_spec"])

            copyBtn:SetScript("OnClick", function()
                TomoMod_Profiles.CopyCurrentToSpec(spec.id)
                print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_copied"], spec.name))
                UpdateBadge()
            end)
            copyBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(T.accent)) end)
            copyBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(T.border)) end)

            -- Bouton "Supprimer"
            local delBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
            delBtn:SetSize(110, 22)
            delBtn:SetPoint("RIGHT", 0, 0)
            delBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
            delBtn:SetBackdropColor(0.15, 0.05, 0.05, 1)
            delBtn:SetBackdropBorderColor(unpack(T.border))

            local delText = delBtn:CreateFontString(nil, "OVERLAY")
            delText:SetFont(FONT, 9, "")
            delText:SetPoint("CENTER")
            delText:SetTextColor(unpack(T.red))
            delText:SetText(L["btn_delete_profile"])

            delBtn:SetScript("OnClick", function()
                TomoMod_Profiles.DeleteSpecProfile(spec.id)
                print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_deleted"], spec.name))
                UpdateBadge()
            end)
            delBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(T.red)) end)
            delBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(T.border)) end)

            y = y - 40
        end

        local _, ny = W.CreateSeparator(c, y)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_spec_reload"], y)
        y = ny
    else
        -- Mode global uniquement
        local _, ny = W.CreateInfoText(c, "|cff0cd29f" .. L["profile_status"] .. ":|r " .. L["profile_global"], y)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_global_mode"], y)
        y = ny
    end

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

-- =====================================
-- TAB 2 : IMPORT / EXPORT
-- =====================================

local function BuildImportExportTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- === EXPORT ===
    local _, ny = W.CreateSectionHeader(c, L["section_export"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_export"], y)
    y = ny

    -- Editbox export (lecture seule)
    local exportBox, ny = W.CreateMultiLineEditBox(c, L["label_export_string"], 100, y, {
        readOnly = true,
    })
    y = ny

    -- Bouton exporter
    local _, ny = W.CreateButton(c, L["btn_export"], 220, y, function()
        local str, err = TomoMod_Profiles.Export()
        if str then
            exportBox.editBox:SetText(str)
            exportBox.editBox:HighlightText()
            exportBox.editBox:SetFocus()
            print("|cff0cd29fTomoMod|r " .. L["msg_export_success"])
        else
            exportBox.editBox:SetText("")
            print("|cffff0000TomoMod|r " .. (err or "Export failed"))
        end
    end)
    y = ny

    -- === IMPORT ===
    local _, ny = W.CreateSeparator(c, y - 4)
    y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_import"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_import"], y)
    y = ny

    -- Texte de preview
    local previewText = c:CreateFontString(nil, "OVERLAY")
    previewText:SetFont(FONT, 10, "")
    previewText:SetPoint("TOPLEFT", 10, y)
    previewText:SetPoint("RIGHT", -10, 0)
    previewText:SetTextColor(unpack(T.textDim))
    previewText:SetText("")
    previewText:SetJustifyH("LEFT")
    y = y - 16

    -- Editbox import
    local importBox, ny = W.CreateMultiLineEditBox(c, L["label_import_string"], 100, y, {
        onTextChanged = function(text)
            if text and text ~= "" then
                local meta = TomoMod_Profiles.PreviewImport(text)
                if meta then
                    local info = string.format(L["import_preview"],
                        meta.class or "?",
                        tostring(meta.moduleCount or 0),
                        meta.date or "?")
                    previewText:SetText("|cff0cd29f" .. L["import_preview_valid"] .. "|r " .. info)
                else
                    previewText:SetText("|cffff0000✗|r " .. L["import_preview_invalid"])
                end
            else
                previewText:SetText("")
            end
        end,
    })
    y = ny

    -- Bouton importer
    local _, ny = W.CreateButton(c, L["btn_import"], 220, y, function()
        local text = importBox.editBox:GetText()
        if not text or text == "" then
            print("|cffff0000TomoMod|r " .. L["msg_import_empty"])
            return
        end
        StaticPopup_Show("TOMOMOD_IMPORT_CONFIRM", nil, nil, { text = text })
    end)
    y = ny

    -- Avertissement
    local _, ny = W.CreateInfoText(c, "|cffff8800⚠|r " .. L["info_import_warning"], y)
    y = ny

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

-- =====================================
-- TAB 3 : RÉINITIALISATIONS
-- =====================================

local function BuildResetsTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    local _, ny = W.CreateSectionHeader(c, L["section_reset_module"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_resets"], y)
    y = ny

    local modules = {
        { key = "unitFrames",       label = "UnitFrames" },
        { key = "nameplates",       label = "Nameplates" },
        { key = "resourceBars",     label = "Resource Bars" },
        { key = "cooldownManager",  label = "Cooldown Manager" },
        { key = "minimap",          label = "Minimap" },
        { key = "infoPanel",        label = "Info Panel" },
        { key = "cursorRing",       label = "Cursor Ring" },
        { key = "skyRide",          label = "SkyRide" },
        { key = "autoQuest",        label = "Auto Quest" },
        { key = "autoAcceptInvite", label = "Auto Accept Invite" },
        { key = "autoSummon",       label = "Auto Summon" },
        { key = "autoFillDelete",   label = "Auto Fill Delete" },
        { key = "frameAnchors",     label = "Frame Anchors" },
        { key = "cinematicSkip",    label = "Cinematic Skip" },
        { key = "hideCastBar",      label = "Hide CastBar" },
        { key = "MythicKeys",       label = "Mythic Keys" },
    }

    for _, mod in ipairs(modules) do
        local _, ny = W.CreateButton(c, L["btn_reset_prefix"] .. mod.label, 260, y, function()
            TomoMod_ResetModule(mod.key)
            print("|cff0cd29fTomoMod|r " .. string.format(L["msg_profile_reset"], mod.label))
        end)
        y = ny
    end

    -- Séparateur + Reset ALL
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_reset_all"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_reset_all_warning"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_all_reload"], 260, y, function()
        StaticPopup_Show("TOMOMOD_RESET_ALL")
    end)
    y = ny - 20

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

-- =====================================
-- ENTRY POINT : 3 ONGLETS
-- =====================================

function TomoMod_ConfigPanel_Profiles(parent)
    local tabs = {
        { key = "profiles",     label = L["tab_profiles"],      builder = function(p) return BuildProfileTab(p) end },
        { key = "importexport", label = L["tab_import_export"], builder = function(p) return BuildImportExportTab(p) end },
        { key = "resets",       label = L["tab_resets"],        builder = function(p) return BuildResetsTab(p) end },
    }

    return W.CreateTabPanel(parent, tabs)
end

-- =====================================
-- STATIC POPUPS
-- =====================================

StaticPopupDialogs["TOMOMOD_IMPORT_CONFIRM"] = {
    text = L["popup_import_text"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function(self, data)
        if data and data.text then
            local ok, err = TomoMod_Profiles.Import(data.text)
            if ok then
                print("|cff0cd29fTomoMod|r " .. L["msg_import_success"])
                ReloadUI()
            else
                print("|cffff0000TomoMod|r " .. (err or "Import failed"))
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["TOMOMOD_PROFILE_RELOAD"] = {
    text = L["popup_profile_reload"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
