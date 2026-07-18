-- =====================================================================
-- TomoMod Forge -- Studio (L2)
-- Shell factory for dedicated editor windows (Cooldown Studio today,
-- the UnitFrames studio tomorrow): window chrome, header with optional
-- selector dropdown, sidebar (title + list host + action host), content
-- host, footer buttons and hint. The consumer keeps its own list
-- rendering, tabs and business wiring -- the factory only owns the
-- chrome so every studio looks and behaves the same.
-- Uses TomoMod_Widgets, resolved lazily (Forge loads before Config).
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

Forge.Studio = Forge.Studio or {}

local WHITE8 = "Interface\\Buttons\\WHITE8x8"

-- opts:
--   name          : global frame name (registered in UISpecialFrames)
--   title         : header title text (can contain color codes)
--   width, height : window size (default 1280x840)
--   sideWidth     : sidebar width (default 250)
--   titleH        : header height (default 52)
--   footerH       : footer height (default 44)
--   crudHeight    : sidebar action-host height (default 112)
--   accent        : {r,g,b} (default Forge.BRAND)
--   sidebarTitle  : small caps label above the list (default "ELEMENTS")
--   selector      : optional { label, options, get, set } header dropdown
--   footerButtons : array of { text, width, callback }
--   hint          : footer right-side hint text
-- Returns { frame, sidebarList, crudHost, contentHost }.
function Forge.Studio.CreateShell(opts)
    local W = TomoMod_Widgets
    opts = opts or {}
    local accent  = opts.accent or Forge.BRAND
    local PW      = opts.width or 1280
    local PH      = opts.height or 840
    local SIDE_W  = opts.sideWidth or 250
    local TITLE_H = opts.titleH or 52
    local FOOT_H  = opts.footerH or 44

    local frame = CreateFrame("Frame", opts.name, UIParent, "BackdropTemplate")
    frame:SetSize(PW, PH)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(100)
    frame:SetToplevel(true)
    frame:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    frame:SetBackdropColor(0.043, 0.047, 0.061, 1)
    frame:SetBackdropBorderColor(0.16, 0.18, 0.22, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop",  frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    if opts.name then
        tinsert(UISpecialFrames, opts.name)
    end

    -- Widgets built inside inherit the studio accent (FindDesign walks up
    -- to _muiDesign; without this they fall back to the default accent).
    if W and W.ApplyPanelContext then
        W.ApplyPanelContext(frame, { key = opts.name or "studio", label = opts.title, accent = accent })
    end

    -- Header
    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(Forge.FONT_BOLD, 15, "")
    title:SetPoint("TOPLEFT", 18, -17)
    title:SetText(opts.title or "Studio")

    if opts.selector and W and W.CreateDropdown then
        local sel = opts.selector
        local host = CreateFrame("Frame", nil, frame)
        host:SetSize(300, 48)
        host:SetPoint("TOPLEFT", 200, -6)
        W.CreateDropdown(host, sel.label or "", sel.options or {},
            sel.get and sel.get() or nil, 0, function(v)
                if sel.set then sel.set(v) end
            end)
    end

    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("TOPRIGHT", -10, -10)
    local ct = closeBtn:CreateFontString(nil, "OVERLAY")
    ct:SetFont(Forge.FONT_BOLD, 15, "")
    ct:SetPoint("CENTER", 0, 0)
    ct:SetText("X")
    ct:SetTextColor(0.5, 0.5, 0.55, 1)
    closeBtn:SetScript("OnEnter", function() ct:SetTextColor(1, 0.4, 0.4, 1) end)
    closeBtn:SetScript("OnLeave", function() ct:SetTextColor(0.5, 0.5, 0.55, 1) end)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local function sep()
        local t = frame:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(0.14, 0.15, 0.19, 1)
        return t
    end
    local hsep = sep()
    hsep:SetPoint("TOPLEFT", 0, -TITLE_H)
    hsep:SetPoint("TOPRIGHT", 0, -TITLE_H)
    hsep:SetHeight(1)

    -- Sidebar
    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPLEFT", 0, -TITLE_H - 1)
    side:SetPoint("BOTTOMLEFT", 0, FOOT_H)
    side:SetWidth(SIDE_W)

    local vsep = sep()
    vsep:SetPoint("TOPLEFT", SIDE_W, -TITLE_H)
    vsep:SetPoint("BOTTOMLEFT", SIDE_W, FOOT_H)
    vsep:SetWidth(1)

    local sideTitle = side:CreateFontString(nil, "OVERLAY")
    sideTitle:SetFont(Forge.FONT, 10, "")
    sideTitle:SetPoint("TOPLEFT", 12, -10)
    sideTitle:SetTextColor(0.42, 0.44, 0.5, 1)
    sideTitle:SetText(opts.sidebarTitle or "ELEMENTS")

    local crudH = opts.crudHeight or 112
    local sidebarList = CreateFrame("Frame", nil, side)
    sidebarList:SetPoint("TOPLEFT", 0, -26)
    sidebarList:SetPoint("BOTTOMRIGHT", 0, crudH + 6)

    local crudHost = CreateFrame("Frame", nil, side)
    crudHost:SetPoint("BOTTOMLEFT", 0, 4)
    crudHost:SetPoint("BOTTOMRIGHT", 0, 4)
    crudHost:SetHeight(crudH)

    -- Content host
    local contentHost = CreateFrame("Frame", nil, frame)
    contentHost:SetPoint("TOPLEFT", SIDE_W + 1, -TITLE_H - 1)
    contentHost:SetPoint("BOTTOMRIGHT", 0, FOOT_H)
    -- [fix] contentHost is created after the sidebar, so at equal frame
    -- level it would sit ON TOP of the sidebar CRUD buttons and swallow
    -- their clicks. Keep content below the sidebar so its buttons get input.
    contentHost:SetFrameLevel(frame:GetFrameLevel() + 1)
    side:SetFrameLevel(frame:GetFrameLevel() + 5)

    -- Footer
    local fsep = sep()
    fsep:SetPoint("BOTTOMLEFT", 0, FOOT_H)
    fsep:SetPoint("BOTTOMRIGHT", 0, FOOT_H)
    fsep:SetHeight(1)

    local fx = 14
    for _, def in ipairs(opts.footerButtons or {}) do
        local b = CreateFrame("Button", nil, frame, "BackdropTemplate")
        b:SetSize(def.width or 180, 28)
        b:SetPoint("BOTTOMLEFT", fx, 8)
        b:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        b:SetBackdropColor(0.07, 0.11, 0.09, 1)
        b:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.5)
        local bt = b:CreateFontString(nil, "OVERLAY")
        bt:SetFont(Forge.FONT_BOLD, 11, "")
        bt:SetPoint("CENTER")
        bt:SetTextColor(0.92, 0.95, 0.93, 1)
        bt:SetText(def.text or "")
        b:SetScript("OnClick", def.callback)
        fx = fx + (def.width or 180) + 10
    end

    if opts.hint then
        local hint = frame:CreateFontString(nil, "OVERLAY")
        hint:SetFont(Forge.FONT, 9, "")
        hint:SetPoint("BOTTOMRIGHT", -16, 16)
        hint:SetTextColor(0.36, 0.38, 0.44, 1)
        hint:SetText(opts.hint)
    end

    return {
        frame       = frame,
        sidebarList = sidebarList,
        crudHost    = crudHost,
        contentHost = contentHost,
    }
end
