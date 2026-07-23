-- =====================================
-- Panels/Diagnostics.lua — Diagnostics Config Panel
-- =====================================

local W = TomoMod_Widgets
local L = TomoMod_L

function TomoMod_ConfigPanel_Diagnostics(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -10

    -- Section header
    local _, ny = W.CreateSectionHeader(c, L["section_diagnostics"], y)
    y = ny

    -- Description
    local _, ny = W.CreateInfoText(c, L["info_diag_desc"], y)
    y = ny

    -- Session info (dynamic)
    local sessionLabel = c:CreateFontString(nil, "OVERLAY")
    sessionLabel:SetFont("Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf", 10, "")
    sessionLabel:SetPoint("TOPLEFT", 16, y)
    sessionLabel:SetTextColor(0.5, 0.5, 0.55, 1)
    local function UpdateSessionInfo()
        local D = TomoMod_Diagnostics
        local sessionID = TomoModDB and TomoModDB.diagnostics and TomoModDB.diagnostics.sessionCount or 0
        local total = D and D.GetErrorCount and D.GetErrorCount() or 0
        local tomo = D and D.GetTomoModErrorCount and D.GetTomoModErrorCount() or 0
        local fmt = L["info_diag_session"]
        sessionLabel:SetText(string.format(fmt, sessionID, total, tomo))
    end
    UpdateSessionInfo()
    y = y - 20

    -- Enable toggle
    local _, ny = W.CreateCheckbox(c, L["opt_diag_enabled"], TomoModDB.diagnostics.enabled, y, function(v)
        TomoModDB.diagnostics.enabled = v
        if v then
            -- Re-init capture if turning on mid-session
            SlashCmdList["TOMODIAG"]("on")
        else
            SlashCmdList["TOMODIAG"]("off")
        end
        UpdateSessionInfo()
    end)
    y = ny

    -- Capture all toggle
    local _, ny = W.CreateCheckbox(c, L["opt_diag_capture_all"], TomoModDB.diagnostics.captureAll, y, function(v)
        TomoModDB.diagnostics.captureAll = v
    end)
    y = ny

    local _, ny = W.CreateInfoText(c, L["info_diag_capture_all_desc"], y)
    y = ny

    -- Suppress popups toggle
    local _, ny = W.CreateCheckbox(c, L["opt_diag_suppress_popups"], TomoModDB.diagnostics.suppressPopups, y, function(v)
        TomoModDB.diagnostics.suppressPopups = v
    end)
    y = ny

    -- Auto-open toggle
    local _, ny = W.CreateCheckbox(c, L["opt_diag_auto_open"], TomoModDB.diagnostics.autoOpenOnError, y, function(v)
        TomoModDB.diagnostics.autoOpenOnError = v
    end)
    y = ny

    y = y - 10

    -- Buttons row
    local _, ny = W.CreateButton(c, L["btn_diag_open_console"], 160, y, function()
        local D = TomoMod_Diagnostics
        if D and D.ShowConsole then D.ShowConsole() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_diag_clear"], 160, y, function()
        SlashCmdList["TOMODIAG"]("clear")
        UpdateSessionInfo()
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_diag_export"], 160, y, function()
        local D = TomoMod_Diagnostics
        if D and D.ShowExportFrame then D.ShowExportFrame() end
    end)
    y = ny

    local _, ny = W.CreateButton(c, L["btn_diag_export_tracker"], 180, y, function()
        local D = TomoMod_Diagnostics
        if D and D.ShowExportFrame then D.ShowExportFrame("tracker") end
    end)
    y = ny

    c:SetHeight(math.abs(y) + 40)
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end
