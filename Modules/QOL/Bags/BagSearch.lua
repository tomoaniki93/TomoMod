-- =====================================================================
-- BagSearch.lua — instant visual bag filtering
-- =====================================================================

local Bags = TomoMod_BagSkin
if not Bags then return end

local Search = { query = "" }
Bags.RegisterModule("Search", Search)

local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local ACCENT = { 0.18, 0.85, 0.52 }

local function L(key, fallback)
    local value = TomoMod_L and TomoMod_L[key]
    if type(value) == "string" and value ~= key and value ~= "" then return value end
    return fallback
end

function Search:Create()
    if self.editBox then return end
    local host = Bags.Modules.Layout.searchHost

    local box = CreateFrame("EditBox", nil, host, "BackdropTemplate")
    box:SetPoint("LEFT", 10, 0)
    box:SetPoint("RIGHT", -10, 0)
    box:SetHeight(24)
    box:SetAutoFocus(false)
    box:SetFont(FONT, 11, "OUTLINE")
    box:SetTextInsets(10, 24, 0, 0)
    box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    box:SetBackdropColor(0.035, 0.045, 0.048, 0.95)
    box:SetBackdropBorderColor(1, 1, 1, 0.10)
    self.editBox = box

    local placeholder = box:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(FONT, 10, "OUTLINE")
    placeholder:SetPoint("LEFT", 10, 0)
    placeholder:SetText(L("bags_v4_search", "Search bags..."))
    placeholder:SetTextColor(0.38, 0.43, 0.45, 1)
    self.placeholder = placeholder

    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(20, 20)
    clear:SetPoint("RIGHT", -2, 0)
    local clearText = clear:CreateFontString(nil, "OVERLAY")
    clearText:SetFont(FONT, 12, "OUTLINE")
    clearText:SetPoint("CENTER")
    clearText:SetText("×")
    clearText:SetTextColor(0.55, 0.60, 0.62, 1)
    clear:SetScript("OnClick", function()
        box:SetText("")
        box:ClearFocus()
    end)
    self.clear = clear

    box:SetScript("OnEditFocusGained", function(selfBox)
        selfBox:SetBackdropBorderColor(ACCENT[1], ACCENT[2], ACCENT[3], 0.55)
    end)
    box:SetScript("OnEditFocusLost", function(selfBox)
        selfBox:SetBackdropBorderColor(1, 1, 1, 0.10)
    end)
    box:SetScript("OnEscapePressed", function(selfBox)
        if selfBox:GetText() ~= "" then selfBox:SetText("") else selfBox:ClearFocus() end
    end)
    box:SetScript("OnEnterPressed", function(selfBox) selfBox:ClearFocus() end)
    box:SetScript("OnTextChanged", function(selfBox)
        local text = selfBox:GetText() or ""
        Search.query = text
        placeholder:SetShown(text == "")
        clear:SetShown(text ~= "")
        Bags.RequestRefresh(true)
    end)
    clear:Hide()
end

function Search:GetQuery()
    return self.query or ""
end

function Search:SetQuery(value)
    value = tostring(value or "")
    if self.editBox then
        self.editBox:SetText(value)
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    else
        self.query = value
        Bags.RequestRefresh(true)
    end
end

function Search:ApplySettings()
    if not self.editBox then return end
    local enabled = Bags.GetDB().search.enabled ~= false
    Bags.Modules.Layout.searchHost:SetShown(enabled)
    if not enabled and self.editBox:GetText() ~= "" then self.editBox:SetText("") end
end

function Search:Initialize()
    self:Create()
    self:ApplySettings()
end
