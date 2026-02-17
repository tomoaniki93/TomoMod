-- =====================================
-- Panels/Profiles.lua — Profils (3 onglets)
-- Tab 1: Profils nommés + par spécialisation
-- Tab 2: Import / Export avec boutons Copier/Coller
-- Tab 3: Réinitialisations modules
-- =====================================

local W = TomoModMini_Widgets
local L = TomoModMini_L
local T = W.Theme
local FONT = "Interface\\AddOns\\TomoModMini\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoModMini\\Assets\\Fonts\\Poppins-SemiBold.ttf"

-- =====================================
-- HELPER: inline single-line editbox
-- =====================================

local function CreateInlineEditBox(parent, placeholder, width, yOffset)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, 26)
    frame:SetPoint("TOPLEFT", 16, yOffset)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    frame:SetBackdropColor(0.06, 0.06, 0.08, 1)
    frame:SetBackdropBorderColor(unpack(T.border))

    local editBox = CreateFrame("EditBox", nil, frame)
    editBox:SetAllPoints()
    editBox:SetFont(FONT, 11, "")
    editBox:SetTextColor(0.9, 0.9, 0.9, 1)
    editBox:SetAutoFocus(false)
    editBox:SetTextInsets(8, 8, 4, 4)
    editBox:SetMaxLetters(50)

    -- Placeholder
    local ph = editBox:CreateFontString(nil, "OVERLAY")
    ph:SetFont(FONT, 11, "")
    ph:SetPoint("LEFT", 8, 0)
    ph:SetTextColor(unpack(T.textDim))
    ph:SetText(placeholder)

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if self:GetText() ~= "" then ph:Hide() else ph:Show() end
    end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnEditFocusGained", function() frame:SetBackdropBorderColor(unpack(T.accent)) end)
    editBox:SetScript("OnEditFocusLost", function() frame:SetBackdropBorderColor(unpack(T.border)) end)

    frame.editBox = editBox
    return frame, yOffset - 32
end

-- =====================================
-- TAB 1 : PROFILS (Nommés + Spécialisations)
-- =====================================

local function BuildProfileTab(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    TomoModMini_Profiles.EnsureProfilesDB()

    -- =============================================
    -- SECTION: Named Profiles
    -- =============================================
    local _, ny = W.CreateSectionHeader(c, L["section_named_profiles"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_named_profiles"], y)
    y = ny

    -- Current active profile
    local activeName = TomoModMini_Profiles.GetActiveProfileName()
    local _, ny = W.CreateInfoText(c, "|cffff3399" .. L["profile_active_label"] .. ":|r " .. activeName, y)
    y = ny

    -- Dropdown: choose profile
    local profileList = TomoModMini_Profiles.GetProfileList()
    local dropdownOptions = {}
    for _, name in ipairs(profileList) do
        table.insert(dropdownOptions, { text = name, value = name })
    end

    if #dropdownOptions > 0 then
        local _, ny = W.CreateDropdown(c, L["opt_select_profile"], dropdownOptions, activeName, y, function(v)
            if v == activeName then return end
            -- Save current first, then load selected
            TomoModMini_Profiles.SaveCurrentToActiveProfile()
            local ok = TomoModMini_Profiles.LoadNamedProfile(v)
            if ok then
                print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_loaded"], v))
                StaticPopup_Show("TOMOMODMINI_PROFILE_RELOAD")
            else
                print("|cffff0000TomoModMini|r " .. string.format(L["msg_profile_load_failed"], v))
            end
        end)
        y = ny
    end

    -- Create new profile
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSubLabel(c, L["sublabel_create_profile"], y)
    y = ny

    local nameBox, ny = CreateInlineEditBox(c, L["placeholder_profile_name"], 250, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_create_profile"], 180, y, function()
        local name = nameBox.editBox:GetText()
        if not name or name:match("^%s*$") then
            print("|cffff0000TomoModMini|r " .. L["msg_profile_name_empty"])
            return
        end
        name = name:match("^%s*(.-)%s*$") -- trim
        local ok, err = TomoModMini_Profiles.CreateNamedProfile(name)
        if ok then
            print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_created"], name))
            nameBox.editBox:SetText("")
            nameBox.editBox:ClearFocus()
        else
            print("|cffff0000TomoModMini|r " .. (err or "Error"))
        end
    end)
    y = ny

    -- Enter key to create
    nameBox.editBox:SetScript("OnEnterPressed", function(self)
        local name = self:GetText()
        if name and not name:match("^%s*$") then
            name = name:match("^%s*(.-)%s*$")
            local ok = TomoModMini_Profiles.CreateNamedProfile(name)
            if ok then
                print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_created"], name))
                self:SetText("")
            end
        end
        self:ClearFocus()
    end)

    -- Delete current profile (only if not "Default")
    if activeName ~= "Default" then
        local _, ny = W.CreateButton(c, L["btn_delete_named_profile"] .. " '" .. activeName .. "'", 260, y, function()
            StaticPopup_Show("TOMOMODMINI_DELETE_PROFILE", activeName, nil, { name = activeName })
        end)
        y = ny
    end

    -- Save button
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_save_profile"], 220, y, function()
        TomoModMini_Profiles.SaveCurrentToActiveProfile()
        print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_saved"], activeName))
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_save_profile"], y)
    y = ny

    -- =============================================
    -- SECTION: Spec profiles
    -- =============================================
    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_profile_mode"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_spec_profiles"], y)
    y = ny

    local useSpec = TomoModMiniDB._profiles.useSpecProfiles

    local _, ny = W.CreateCheckbox(c, L["opt_enable_spec_profiles"], useSpec, y, function(v)
        if v then
            TomoModMini_Profiles.EnableSpecProfiles()
        else
            TomoModMini_Profiles.DisableSpecProfiles()
        end
        StaticPopup_Show("TOMOMODMINI_PROFILE_RELOAD")
    end)
    y = ny

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local specID = TomoModMini_Profiles.GetCurrentSpecID()
    local allSpecs = TomoModMini_Profiles.GetAllSpecs()

    if useSpec then
        local activeLabel = L["profile_global"]
        for _, spec in ipairs(allSpecs) do
            if spec.id == specID then
                activeLabel = spec.name
                break
            end
        end

        local _, ny = W.CreateInfoText(c, "|cffff3399" .. L["profile_status"] .. ":|r " .. activeLabel, y)
        y = ny

        local _, ny = W.CreateSectionHeader(c, L["section_spec_list"], y)
        y = ny

        for _, spec in ipairs(allSpecs) do
            local hasSaved = TomoModMini_Profiles.HasSpecProfile(spec.id)
            local isCurrent = (spec.id == specID)

            local row = CreateFrame("Frame", nil, c)
            row:SetPoint("TOPLEFT", 10, y)
            row:SetPoint("RIGHT", -10, 0)
            row:SetHeight(36)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("LEFT", 0, 0)
            icon:SetTexture(spec.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local nameFS = row:CreateFontString(nil, "OVERLAY")
            nameFS:SetFont(FONT, 11, "")
            nameFS:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameFS:SetTextColor(unpack(T.text))
            nameFS:SetText(spec.name)

            local statusFS = row:CreateFontString(nil, "OVERLAY")
            statusFS:SetFont(FONT, 10, "")
            statusFS:SetPoint("LEFT", nameFS, "RIGHT", 10, 0)

            local function UpdateBadge()
                local saved = TomoModMini_Profiles.HasSpecProfile(spec.id)
                if isCurrent then
                    statusFS:SetText("|cffff3399° " .. L["profile_badge_active"] .. "|r")
                elseif saved then
                    statusFS:SetText("|cffffff00° " .. L["profile_badge_saved"] .. "|r")
                else
                    statusFS:SetText("|cff666666° " .. L["profile_badge_none"] .. "|r")
                end
            end
            UpdateBadge()

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
                TomoModMini_Profiles.CopyCurrentToSpec(spec.id)
                print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_copied"], spec.name))
                UpdateBadge()
            end)
            copyBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(T.accent)) end)
            copyBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(T.border)) end)

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
                TomoModMini_Profiles.DeleteSpecProfile(spec.id)
                print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_deleted"], spec.name))
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
        local _, ny = W.CreateInfoText(c, "|cffff3399" .. L["profile_status"] .. ":|r " .. L["profile_global"], y)
        y = ny

        local _, ny = W.CreateInfoText(c, L["info_global_mode"], y)
        y = ny
    end

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

-- =====================================
-- TAB 2 : IMPORT / EXPORT (avec Copier/Coller)
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

    -- Editbox export (read-only)
    local exportBox, ny = W.CreateMultiLineEditBox(c, L["label_export_string"], 100, y, {
        readOnly = true,
    })
    y = ny

    -- Row: Generate + Copy buttons side by side
    local btnRow = CreateFrame("Frame", nil, c)
    btnRow:SetSize(400, 30)
    btnRow:SetPoint("TOPLEFT", 16, y)

    -- Generate button
    local genBtn = CreateFrame("Button", nil, btnRow, "BackdropTemplate")
    genBtn:SetSize(220, 28)
    genBtn:SetPoint("LEFT", 0, 0)
    genBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    genBtn:SetBackdropColor(unpack(T.accentDark))
    genBtn:SetBackdropBorderColor(unpack(T.accent))

    local genLabel = genBtn:CreateFontString(nil, "OVERLAY")
    genLabel:SetFont(FONT_BOLD, 11, "")
    genLabel:SetPoint("CENTER")
    genLabel:SetTextColor(1, 1, 1, 1)
    genLabel:SetText(L["btn_export"])

    genBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(T.accent))
        genLabel:SetTextColor(0.08, 0.08, 0.10, 1)
    end)
    genBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(T.accentDark))
        genLabel:SetTextColor(1, 1, 1, 1)
    end)
    genBtn:SetScript("OnClick", function()
        local str, err = TomoModMini_Profiles.Export()
        if str then
            exportBox.editBox:SetText(str)
            exportBox.editBox:HighlightText()
            exportBox.editBox:SetFocus()
            print("|cffff3399TomoModMini|r " .. L["msg_export_success"])
        else
            exportBox.editBox:SetText("")
            print("|cffff0000TomoModMini|r " .. (err or "Export failed"))
        end
    end)

    -- Copy button
    local copyBtn = CreateFrame("Button", nil, btnRow, "BackdropTemplate")
    copyBtn:SetSize(140, 28)
    copyBtn:SetPoint("LEFT", genBtn, "RIGHT", 8, 0)
    copyBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    copyBtn:SetBackdropColor(unpack(T.bgLight))
    copyBtn:SetBackdropBorderColor(unpack(T.border))

    local copyLabel = copyBtn:CreateFontString(nil, "OVERLAY")
    copyLabel:SetFont(FONT_BOLD, 11, "")
    copyLabel:SetPoint("CENTER")
    copyLabel:SetTextColor(unpack(T.text))
    copyLabel:SetText(L["btn_copy_clipboard"])

    copyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(T.accent))
    end)
    copyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(T.border))
    end)
    copyBtn:SetScript("OnClick", function()
        local text = exportBox.editBox:GetText()
        if text and text ~= "" then
            exportBox.editBox:HighlightText()
            exportBox.editBox:SetFocus()
            print("|cffff3399TomoModMini|r " .. L["msg_copy_hint"])
        else
            print("|cffff0000TomoModMini|r " .. L["msg_copy_empty"])
        end
    end)

    y = y - 36

    -- === IMPORT ===
    local _, ny = W.CreateSeparator(c, y - 4)
    y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_import"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_import"], y)
    y = ny

    -- Preview text
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
                local meta = TomoModMini_Profiles.PreviewImport(text)
                if meta then
                    local info = string.format(L["import_preview"],
                        meta.class or "?",
                        tostring(meta.moduleCount or 0),
                        meta.date or "?")
                    previewText:SetText("|cffff3399" .. L["import_preview_valid"] .. "|r " .. info)
                else
                    previewText:SetText("|cffff0000✗|r " .. L["import_preview_invalid"])
                end
            else
                previewText:SetText("")
            end
        end,
    })
    y = ny

    -- Row: Paste + Import buttons side by side
    local importRow = CreateFrame("Frame", nil, c)
    importRow:SetSize(400, 30)
    importRow:SetPoint("TOPLEFT", 16, y)

    -- Paste button
    local pasteBtn = CreateFrame("Button", nil, importRow, "BackdropTemplate")
    pasteBtn:SetSize(140, 28)
    pasteBtn:SetPoint("LEFT", 0, 0)
    pasteBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    pasteBtn:SetBackdropColor(unpack(T.bgLight))
    pasteBtn:SetBackdropBorderColor(unpack(T.border))

    local pasteLabel = pasteBtn:CreateFontString(nil, "OVERLAY")
    pasteLabel:SetFont(FONT_BOLD, 11, "")
    pasteLabel:SetPoint("CENTER")
    pasteLabel:SetTextColor(unpack(T.text))
    pasteLabel:SetText(L["btn_paste_clipboard"])

    pasteBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(T.accent))
    end)
    pasteBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(T.border))
    end)
    pasteBtn:SetScript("OnClick", function()
        importBox.editBox:SetText("")
        importBox.editBox:SetFocus()
        print("|cffff3399TomoModMini|r " .. L["msg_paste_hint"])
    end)

    -- Import button
    local impBtn = CreateFrame("Button", nil, importRow, "BackdropTemplate")
    impBtn:SetSize(220, 28)
    impBtn:SetPoint("LEFT", pasteBtn, "RIGHT", 8, 0)
    impBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    impBtn:SetBackdropColor(unpack(T.accentDark))
    impBtn:SetBackdropBorderColor(unpack(T.accent))

    local impLabel = impBtn:CreateFontString(nil, "OVERLAY")
    impLabel:SetFont(FONT_BOLD, 11, "")
    impLabel:SetPoint("CENTER")
    impLabel:SetTextColor(1, 1, 1, 1)
    impLabel:SetText(L["btn_import"])

    impBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(T.accent))
        impLabel:SetTextColor(0.08, 0.08, 0.10, 1)
    end)
    impBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(T.accentDark))
        impLabel:SetTextColor(1, 1, 1, 1)
    end)
    impBtn:SetScript("OnClick", function()
        local text = importBox.editBox:GetText()
        if not text or text == "" then
            print("|cffff0000TomoModMini|r " .. L["msg_import_empty"])
            return
        end
        StaticPopup_Show("TOMOMODMINI_IMPORT_CONFIRM", nil, nil, { text = text })
    end)

    y = y - 36

    -- Warning
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
        { key = "cursorRing",       label = "Cursor Ring" },
        { key = "autoAcceptInvite", label = "Auto Accept Invite" },
        { key = "autoSummon",       label = "Auto Summon" },
        { key = "autoFillDelete",   label = "Auto Fill Delete" },
        { key = "cinematicSkip",    label = "Cinematic Skip" },
        { key = "hideCastBar",      label = "Hide CastBar" },
        { key = "autoSkipRole",     label = "Auto Skip Role" },
    }

    for _, mod in ipairs(modules) do
        local _, ny = W.CreateButton(c, L["btn_reset_prefix"] .. mod.label, 260, y, function()
            TomoModMini_ResetModule(mod.key)
            print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_reset"], mod.label))
        end)
        y = ny
    end

    local _, ny = W.CreateSeparator(c, y)
    y = ny

    local _, ny = W.CreateSectionHeader(c, L["section_reset_all"], y)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_reset_all_warning"], y)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_reset_all_reload"], 260, y, function()
        StaticPopup_Show("TOMOMODMINI_RESET_ALL")
    end)
    y = ny - 20

    c:SetHeight(math.abs(y) + 20)
    return scroll
end

-- =====================================
-- ENTRY POINT : 3 ONGLETS
-- =====================================

function TomoModMini_ConfigPanel_Profiles(parent)
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

StaticPopupDialogs["TOMOMODMINI_IMPORT_CONFIRM"] = {
    text = L["popup_import_text"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function(self, data)
        if data and data.text then
            local ok, err = TomoModMini_Profiles.Import(data.text)
            if ok then
                print("|cffff3399TomoModMini|r " .. L["msg_import_success"])
                ReloadUI()
            else
                print("|cffff0000TomoModMini|r " .. (err or "Import failed"))
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["TOMOMODMINI_PROFILE_RELOAD"] = {
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

StaticPopupDialogs["TOMOMODMINI_DELETE_PROFILE"] = {
    text = L["popup_delete_profile"],
    button1 = L["popup_confirm"],
    button2 = L["popup_cancel"],
    OnAccept = function(self, data)
        if data and data.name then
            local ok = TomoModMini_Profiles.DeleteNamedProfile(data.name)
            if ok then
                print("|cffff3399TomoModMini|r " .. string.format(L["msg_profile_name_deleted"], data.name))
                StaticPopup_Show("TOMOMODMINI_PROFILE_RELOAD")
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}