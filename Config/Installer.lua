-- ============================================================
-- Installer.lua — Assistant de première installation
-- 12 étapes guidées : profil, skins, tank, nameplates,
-- action bars, lustsound, mythic+, cvars, qol, skyriding, fin.
-- Ouverture : auto au premier démarrage ou /tm install
-- ============================================================

TomoMod_Installer = TomoMod_Installer or {}
local INS = TomoMod_Installer
local L   = TomoMod_L

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local LOGO_TEX  = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\Logo.tga"
local ICON_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icons\\"

-- Palette
local A  = { 0.047, 0.824, 0.624 }   -- teal accent
local AD = { 0.030, 0.560, 0.420 }   -- teal dark
local BG = { 0.07,  0.07,  0.09,  0.98 }
local BG2= { 0.10,  0.10,  0.13,  1    }
local BD = { 0.18,  0.18,  0.22,  1    }
local TX = { 0.88,  0.90,  0.89,  1    }
local DM = { 0.48,  0.48,  0.54,  1    }

local PANEL_W = 760
local PANEL_H = 560
local TOTAL_STEPS = 12

-- State
local frame, dimmer
local stepPanels    = {}
local stepDots      = {}
local currentStep   = 1
local prevBtn, nextBtn, stepLabel
local contentHost   -- zone de contenu, les panels s'y ancrent

-- ============================================================
-- WIDGET HELPERS  (locaux, simples, sans dépendance à W)
-- ============================================================
local function Sec(parent, text, y)
    local strip = parent:CreateTexture(nil, "BACKGROUND")
    strip:SetHeight(24)
    strip:SetPoint("TOPLEFT",  8, y)
    strip:SetPoint("TOPRIGHT", -8, y)
    strip:SetColorTexture(A[1]*0.10, A[2]*0.10, A[3]*0.10, 1)
    local bar = parent:CreateTexture(nil, "ARTWORK")
    bar:SetWidth(3); bar:SetHeight(24)
    bar:SetPoint("TOPLEFT", 8, y)
    bar:SetColorTexture(A[1], A[2], A[3], 1)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_BOLD, 11, "")
    lbl:SetPoint("LEFT", strip, "LEFT", 6, 0)
    lbl:SetTextColor(A[1], A[2], A[3], 1)
    lbl:SetText(text)
    return y - 30
end

local function Info(parent, text, y)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 10, "")
    lbl:SetPoint("TOPLEFT",  12, y)
    lbl:SetPoint("TOPRIGHT", -12, y)
    lbl:SetJustifyH("LEFT")
    lbl:SetTextColor(DM[1], DM[2], DM[3], 1)
    lbl:SetText(text)
    local rawH = lbl:GetStringHeight()
    local h    = tonumber(tostring(rawH)) or 12
    return y - (math.ceil(h / 12) * 14 + 8)
end

local function Cb(parent, text, val, y, cb)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(700, 24); f:SetPoint("TOPLEFT", 12, y)
    local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
    box:SetSize(14, 14); box:SetPoint("LEFT")
    box:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    box:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1)
    box:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
    local tick = box:CreateTexture(nil, "OVERLAY")
    tick:SetPoint("TOPLEFT", 2, -2); tick:SetPoint("BOTTOMRIGHT", -2, 2)
    tick:SetColorTexture(A[1], A[2], A[3], 1)
    local lbl = f:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, ""); lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
    lbl:SetTextColor(TX[1], TX[2], TX[3], 1); lbl:SetText(text)
    local state = val
    local function Upd()
        if state then
            tick:Show()
            box:SetBackdropBorderColor(A[1], A[2], A[3], 0.80)
            box:SetBackdropColor(A[1]*0.12, A[2]*0.12, A[3]*0.12, 1)
        else
            tick:Hide()
            box:SetBackdropBorderColor(BD[1], BD[2], BD[3], 1)
            box:SetBackdropColor(BG2[1], BG2[2], BG2[3], 1)
        end
    end
    Upd()
    f:SetScript("OnClick", function()
        state = not state; Upd()
        if cb then cb(state) end
    end)
    f.SetChecked = function(_, v) state = v; Upd() end
    f.GetChecked = function() return state end
    return f, y - 28
end

local function Sldr(parent, text, val, mn, mx, step, y, cb, fmt)
    fmt = fmt or "%.0f"
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, ""); lbl:SetPoint("TOPLEFT", 12, y)
    lbl:SetTextColor(TX[1], TX[2], TX[3], 1); lbl:SetText(text)
    local vbx = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    vbx:SetSize(52, 17); vbx:SetPoint("TOPRIGHT", -12, y)
    vbx:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    vbx:SetBackdropColor(A[1]*0.09,A[2]*0.09,A[3]*0.09,1)
    vbx:SetBackdropBorderColor(A[1]*0.5,A[2]*0.5,A[3]*0.5,1)
    local vtxt = vbx:CreateFontString(nil, "OVERLAY")
    vtxt:SetFont(FONT_BOLD, 10, ""); vtxt:SetPoint("CENTER")
    vtxt:SetTextColor(A[1],A[2],A[3],1); vtxt:SetText(string.format(fmt, val))
    local slName = "TomoInstSlider_"..tostring(math.random(1e6))
    local sl = CreateFrame("Slider", slName, parent, "BackdropTemplate")
    sl:SetOrientation("HORIZONTAL"); sl:SetHeight(14)
    sl:SetPoint("TOPLEFT", 12, y-18); sl:SetPoint("TOPRIGHT", -12, y-18)
    sl:SetMinMaxValues(mn, mx); sl:SetValueStep(step); sl:SetObeyStepOnDrag(true); sl:SetValue(val)
    local trk = sl:CreateTexture(nil,"BACKGROUND"); trk:SetAllPoints()
    trk:SetColorTexture(0.12,0.12,0.15,1)
    local fill = sl:CreateTexture(nil,"ARTWORK"); fill:SetHeight(14)
    fill:SetPoint("LEFT",trk,"LEFT"); fill:SetColorTexture(AD[1],AD[2],AD[3],1)
    sl:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local th = sl:GetThumbTexture(); th:SetSize(9,15); th:SetVertexColor(A[1],A[2],A[3],1)
    sl:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v/step+0.5)*step
        vtxt:SetText(string.format(fmt, v))
        local pct = (v-mn)/(mx-mn)
        local w = trk:GetWidth()
        if w and w > 0 then fill:SetWidth(math.max(0, pct*w)) end
        if cb then cb(v) end
    end)
    sl:SetScript("OnSizeChanged", function()
        local v = sl:GetValue(); local pct=(v-mn)/(mx-mn)
        local w=trk:GetWidth(); if w and w>0 then fill:SetWidth(math.max(0,pct*w)) end
    end)
    local f = {}; f.SetValue=function(_,v) sl:SetValue(v) end
    f.GetValue=function() return sl:GetValue() end
    return f, y-44
end

local function Dd(parent, text, opts, sel, y, cb)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, ""); lbl:SetPoint("TOPLEFT", 12, y)
    lbl:SetTextColor(TX[1], TX[2], TX[3], 1); lbl:SetText(text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(220, 22); btn:SetPoint("TOPLEFT", 12, y-16)
    btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    btn:SetBackdropColor(BG2[1],BG2[2],BG2[3],1)
    btn:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
    local btxt = btn:CreateFontString(nil,"OVERLAY")
    btxt:SetFont(FONT,11,""); btxt:SetPoint("LEFT",8,0); btxt:SetTextColor(TX[1],TX[2],TX[3],1)
    local function GetDisp(v) for _,o in ipairs(opts) do if o.value==v then return o.text end end return tostring(v) end
    btxt:SetText(GetDisp(sel))
    local menu = CreateFrame("Frame",nil,btn,"BackdropTemplate")
    menu:SetPoint("TOPLEFT",btn,"BOTTOMLEFT",0,-2)
    menu:SetSize(220,#opts*22+4)
    menu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    menu:SetBackdropColor(0.09,0.09,0.12,1); menu:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
    menu:SetFrameStrata("DIALOG"); menu:Hide()
    for i,opt in ipairs(opts) do
        local item = CreateFrame("Button",nil,menu)
        item:SetHeight(22); item:SetPoint("TOPLEFT",3,-(i-1)*22-3); item:SetPoint("TOPRIGHT",-3,-(i-1)*22-3)
        local ibg=item:CreateTexture(nil,"BACKGROUND"); ibg:SetAllPoints(); ibg:SetColorTexture(0,0,0,0)
        local itxt=item:CreateFontString(nil,"OVERLAY"); itxt:SetFont(FONT,11,"")
        itxt:SetPoint("LEFT",8,0); itxt:SetTextColor(TX[1],TX[2],TX[3],1); itxt:SetText(opt.text)
        item:SetScript("OnEnter",function() ibg:SetColorTexture(A[1],A[2],A[3],0.15) end)
        item:SetScript("OnLeave",function() ibg:SetColorTexture(0,0,0,0) end)
        item:SetScript("OnClick",function()
            sel=opt.value; btxt:SetText(opt.text); menu:Hide()
            btn:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
            if cb then cb(opt.value) end
        end)
    end
    btn:SetScript("OnClick",function()
        if menu:IsShown() then menu:Hide(); btn:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
        else menu:Show(); menu:SetFrameLevel(btn:GetFrameLevel()+50); btn:SetBackdropBorderColor(A[1],A[2],A[3],0.7) end
    end)
    return nil, y-48
end

local function BigBtn(parent, text, y, clickCb, accent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(260, 36); btn:SetPoint("TOPLEFT", 12, y)
    if accent then
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        btn:SetBackdropColor(AD[1],AD[2],AD[3],0.9); btn:SetBackdropBorderColor(A[1],A[2],A[3],0.75)
    else
        btn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        btn:SetBackdropColor(BG2[1],BG2[2],BG2[3],1); btn:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
    end
    local lbl = btn:CreateFontString(nil,"OVERLAY")
    lbl:SetFont(FONT_BOLD,12,""); lbl:SetPoint("CENTER"); lbl:SetText(text)
    lbl:SetTextColor(accent and 1 or TX[1], accent and 1 or TX[2], accent and 1 or TX[3], 1)
    btn:SetScript("OnEnter",function()
        btn:SetBackdropColor(A[1],A[2],A[3],1); lbl:SetTextColor(0.06,0.06,0.08,1)
    end)
    btn:SetScript("OnLeave",function()
        if accent then btn:SetBackdropColor(AD[1],AD[2],AD[3],0.9); lbl:SetTextColor(1,1,1,1)
        else btn:SetBackdropColor(BG2[1],BG2[2],BG2[3],1); lbl:SetTextColor(TX[1],TX[2],TX[3],1) end
    end)
    btn:SetScript("OnClick", function() if clickCb then clickCb() end end)
    return btn, y-50
end

-- ============================================================
-- STEP DEFINITIONS
-- ============================================================
local steps = {}

-- ── STEP 1: Bienvenue ──────────────────────────────────────
steps[1] = {
    title = L["ins_step1_title"],
    icon  = ICON_PATH.."icon_general.tga",
    build = function(c)
        -- Logo centré
        local logo = c:CreateTexture(nil,"OVERLAY")
        logo:SetSize(64,64); logo:SetPoint("TOP",0,-20)
        logo:SetTexture(LOGO_TEX); logo:SetVertexColor(A[1],A[2],A[3],1)
        local title = c:CreateFontString(nil,"OVERLAY")
        title:SetFont(FONT_BOLD,20,""); title:SetPoint("TOP",0,-95)
        title:SetText("|cff0cd29fTomo|r|cffe8e8e8Mod|r  v" .. (C_AddOns.GetAddOnMetadata("TomoMod", "Version") or "?"))
        title:SetTextColor(1,1,1,1)
        local sub = c:CreateFontString(nil,"OVERLAY")
        sub:SetFont(FONT,12,""); sub:SetPoint("TOP",0,-125)
        sub:SetTextColor(DM[1],DM[2],DM[3],1)
        sub:SetText(L["ins_subtitle"])
        -- Description
        local desc = c:CreateFontString(nil,"OVERLAY")
        desc:SetFont(FONT,11,""); desc:SetPoint("TOPLEFT",40,-170); desc:SetPoint("TOPRIGHT",-40,-170)
        desc:SetJustifyH("LEFT"); desc:SetSpacing(3); desc:SetWordWrap(true)
        desc:SetTextColor(TX[1],TX[2],TX[3],0.85)
        desc:SetText(L["ins_welcome_desc"])
        return -300
    end,
}

-- ── STEP 2: Profil ─────────────────────────────────────────
steps[2] = {
    title = L["ins_step2_title"],
    icon  = ICON_PATH.."icon_profiles.tga",
    build = function(c)
        local y = -10
        y = Info(c, L["ins_profile_info"], y)
        y = Sec(c, L["ins_profile_section"], y)
        -- EditBox pour le nom
        local ebF = CreateFrame("Frame",nil,c,"BackdropTemplate")
        ebF:SetSize(300,26); ebF:SetPoint("TOPLEFT",12,y)
        ebF:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        ebF:SetBackdropColor(BG2[1],BG2[2],BG2[3],1); ebF:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
        local eb = CreateFrame("EditBox",nil,ebF)
        eb:SetAllPoints(); eb:SetFont(FONT,11,""); eb:SetTextColor(TX[1],TX[2],TX[3],1)
        eb:SetAutoFocus(false); eb:SetTextInsets(8,8,4,4); eb:SetMaxLetters(32)
        -- Placeholder
        local ph = eb:CreateFontString(nil,"OVERLAY")
        ph:SetFont(FONT,11,""); ph:SetPoint("LEFT",8,0); ph:SetTextColor(DM[1],DM[2],DM[3],1); ph:SetText(L["ins_profile_placeholder"])
        eb:SetScript("OnTextChanged",function(self,u) if u then if #self:GetText()>0 then ph:Hide() else ph:Show() end end end)
        eb:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        eb:SetScript("OnEditFocusGained",function() ebF:SetBackdropBorderColor(A[1],A[2],A[3],0.7) end)
        eb:SetScript("OnEditFocusLost",function() ebF:SetBackdropBorderColor(BD[1],BD[2],BD[3],1) end)
        y = y - 36

        local _, ny = BigBtn(c, L["ins_profile_create"], y, function()
            if TomoMod_Profiles then
                local name = eb:GetText()
                if name == "" then name = L["ins_profile_placeholder"] end
                TomoMod_Profiles.CreateNamedProfile(name)
                TomoMod_Profiles.LoadNamedProfile(name)
                print("|cff0cd29fTomoMod|r " .. L["ins_profile_created"] .. name)
            end
        end, false)
        y = ny

        y = Sec(c, L["ins_spec_section"], y)
        y = Info(c, L["ins_spec_info"], y)
        return y
    end,
}

-- ── STEP 3: Skins visuels ──────────────────────────────────
steps[3] = {
    title = L["ins_step3_title"],
    icon  = ICON_PATH.."icon_qol.tga",
    build = function(c)
        local y = -10
        y = Info(c,L["ins_skins_info"], y)
        y = Sec(c, L["ins_skins_section"], y)
        local _, ny = Cb(c,L["ins_skin_gamemenu"],    TomoModDB.gameMenuSkin and TomoModDB.gameMenuSkin.enabled, y, function(v)
            TomoModDB.gameMenuSkin = TomoModDB.gameMenuSkin or {}
            TomoModDB.gameMenuSkin.enabled = v
            if TomoMod_GameMenuSkin then TomoMod_GameMenuSkin.SetEnabled(v) end
        end); y = ny

        local _, ny = Cb(c,L["ins_skin_actionbar"], TomoModDB.actionBarSkin and TomoModDB.actionBarSkin.enabled, y, function(v)
            TomoModDB.actionBarSkin = TomoModDB.actionBarSkin or {}
            TomoModDB.actionBarSkin.enabled = v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetEnabled(v) end
        end); y = ny

        local _, ny = Cb(c,L["ins_skin_buffs"],           TomoModDB.buffSkin and TomoModDB.buffSkin.enabled, y, function(v)
            TomoModDB.buffSkin = TomoModDB.buffSkin or {}
            TomoModDB.buffSkin.enabled = v
            if TomoMod_BuffSkin then TomoMod_BuffSkin.SetEnabled(v) end
        end); y = ny

        local _, ny = Cb(c,L["ins_skin_chat"],                       TomoModDB.chatSkin and TomoModDB.chatSkin.enabled, y, function(v)
            TomoModDB.chatSkin = TomoModDB.chatSkin or {}
            TomoModDB.chatSkin.enabled = v
            if TomoMod_ChatFrameSkin then TomoMod_ChatFrameSkin.SetEnabled(v) end
        end); y = ny

        local _, ny = Cb(c,L["ins_skin_character"],     TomoModDB.characterSkin and TomoModDB.characterSkin.enabled, y, function(v)
            TomoModDB.characterSkin = TomoModDB.characterSkin or {}
            TomoModDB.characterSkin.enabled = v
        end); y = ny

        y = Sec(c, L["ins_skin_style_section"], y)
        local _, ny = Dd(c, L["ins_skin_style"], {
            {value="classic",  text="Classic (9-slice)"},
            {value="flat",     text="Flat"},
            {value="outlined", text="Outlined"},
            {value="glass",    text="Glass"},
        }, (TomoModDB.actionBarSkin and TomoModDB.actionBarSkin.skinStyle) or "classic", y, function(v)
            TomoModDB.actionBarSkin = TomoModDB.actionBarSkin or {}
            TomoModDB.actionBarSkin.skinStyle = v
            if TomoMod_ActionBarSkin and TomoMod_ActionBarSkin.Reskin then TomoMod_ActionBarSkin.Reskin() end
        end); y = ny
        return y
    end,
}

-- ── STEP 4: Mode Tank ─────────────────────────────────────
steps[4] = {
    title = L["ins_step4_title"],
    icon  = ICON_PATH.."icon_unitframes.tga",
    build = function(c)
        local y = -10
        y = Info(c,L["ins_tank_info"], y)
        y = Sec(c,L["ins_tank_np_section"], y)
        local _, ny = Cb(c, L["ins_tank_enable_np"],
            TomoModDB.nameplates and TomoModDB.nameplates.tankMode, y, function(v)
                TomoModDB.nameplates = TomoModDB.nameplates or {}
                TomoModDB.nameplates.tankMode = v
                if TomoMod_Nameplates then TomoMod_Nameplates.ApplySettings() end
            end); y = ny
        y = Info(c, L["ins_tank_colors_info"], y)

        y = Sec(c, L["ins_tank_uf_section"], y)
        local _, ny = Cb(c, L["ins_tank_threat_indicator"],
            TomoModDB.unitFrames and TomoModDB.unitFrames.target and TomoModDB.unitFrames.target.showThreat, y, function(v)
                if TomoModDB.unitFrames and TomoModDB.unitFrames.target then
                    TomoModDB.unitFrames.target.showThreat = v
                    if TomoMod_UnitFrames and TomoMod_UnitFrames.RefreshUnit then
                        TomoMod_UnitFrames.RefreshUnit("target")
                    end
                end
            end); y = ny

        local _, ny = Cb(c, L["ins_tank_threat_text"],
            TomoModDB.unitFrames and TomoModDB.unitFrames.target and
            TomoModDB.unitFrames.target.threatText and TomoModDB.unitFrames.target.threatText.enabled, y, function(v)
                if TomoModDB.unitFrames and TomoModDB.unitFrames.target then
                    TomoModDB.unitFrames.target.threatText = TomoModDB.unitFrames.target.threatText or {}
                    TomoModDB.unitFrames.target.threatText.enabled = v
                end
            end); y = ny

        y = Sec(c, L["ins_tank_cotank_section"], y)
        local _, ny = Cb(c, L["ins_tank_cotank_enable"],
            TomoModDB.coTankTracker and TomoModDB.coTankTracker.enabled, y, function(v)
                TomoModDB.coTankTracker = TomoModDB.coTankTracker or {}
                TomoModDB.coTankTracker.enabled = v
            end); y = ny
        y = Info(c, L["ins_tank_cotank_info"], y)
        return y
    end,
}

-- ── STEP 5: Nameplates ────────────────────────────────────
steps[5] = {
    title = L["ins_step5_title"],
    icon  = ICON_PATH.."icon_nameplates.tga",
    build = function(c)
        local y = -10
        local npDB = TomoModDB.nameplates or {}
        y = Sec(c, L["ins_np_general"], y)
        local _, ny = Cb(c,L["ins_np_enable"], npDB.enabled, y, function(v)
            TomoModDB.nameplates.enabled = v
            if TomoMod_Nameplates then
                if v then TomoMod_Nameplates.Enable() else TomoMod_Nameplates.Disable() end
            end
        end); y = ny
        y = Info(c, L["ins_np_reload_info"], y)

        y = Sec(c, L["ins_np_display"], y)
        local _, ny = Cb(c,L["ins_np_class_colors"],     npDB.useClassColors,           y,function(v) TomoModDB.nameplates.useClassColors=v end); y=ny
        local _, ny = Cb(c,L["ins_np_castbar"], npDB.showCastbar,  y,function(v) TomoModDB.nameplates.showCastbar=v end); y=ny
        local _, ny = Cb(c,L["ins_np_health_text"], npDB.showHealthText, y,function(v) TomoModDB.nameplates.showHealthText=v end); y=ny
        local _, ny = Cb(c,L["ins_np_auras"], npDB.showAuras,           y,function(v) TomoModDB.nameplates.showAuras=v end); y=ny
        local _, ny = Cb(c,L["ins_np_role_icons"], npDB.friendlyRoleIcons~=false, y, function(v)
            TomoModDB.nameplates.friendlyRoleIcons=v
        end); y=ny

        y = Sec(c, L["ins_np_dimensions"], y)
        local _, ny = Sldr(c,L["ins_np_width"], npDB.width or 170, 60, 300, 5, y, function(v)
            TomoModDB.nameplates.width = v
            if TomoMod_Nameplates then TomoMod_Nameplates.RefreshAll() end
        end); y = ny
        return y
    end,
}

-- ── STEP 6: Barres d'action ───────────────────────────────
steps[6] = {
    title = L["ins_step6_title"],
    icon  = ICON_PATH.."icon_actionbars.tga",
    build = function(c)
        local y = -10
        local abDB = TomoModDB.actionBarSkin or {}
        y = Sec(c,L["ins_ab_skin_section"], y)
        local _, ny = Cb(c,L["ins_ab_enable"], abDB.enabled, y, function(v)
            TomoModDB.actionBarSkin.enabled=v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetEnabled(v) end
        end); y=ny
        local _, ny = Cb(c,L["ins_ab_class_color"], abDB.useClassColor, y, function(v)
            TomoModDB.actionBarSkin.useClassColor=v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.UpdateColors() end
        end); y=ny
        local _, ny = Cb(c,L["ins_ab_shift_reveal"], abDB.shiftReveal, y, function(v)
            TomoModDB.actionBarSkin.shiftReveal=v
            if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.SetShiftReveal(v) end
        end); y=ny

        y = Sec(c,L["ins_ab_opacity_section"], y)
        local _, ny = Sldr(c,L["ins_ab_opacity"], 85, 0, 100, 5, y, function(v)
            TomoModDB.actionBarSkin.barOpacity = TomoModDB.actionBarSkin.barOpacity or {}
            local bars = {"ActionButton","MultiBarBottomLeft","MultiBarBottomRight",
                          "MultiBarRight","MultiBarLeft","MultiBar5","MultiBar6","MultiBar7"}
            for _,bk in ipairs(bars) do
                TomoModDB.actionBarSkin.barOpacity[bk] = v
                if TomoMod_ActionBarSkin then TomoMod_ActionBarSkin.ApplyBarOpacity(bk, v) end
            end
        end, "%d%%"); y=ny

        y = Sec(c,L["ins_ab_manage_section"], y)
        y = Info(c,L["ins_ab_manage_info"], y)
        return y
    end,
}

-- ── STEP 7: LustSound ─────────────────────────────────────
steps[7] = {
    title = L["ins_step7_title"],
    icon  = ICON_PATH.."icon_sound.tga",
    build = function(c)
        local y = -10
        local lsDB = TomoModDB.lustSound or {}
        y = Info(c,L["ins_sound_info"], y)
        y = Sec(c,L["ins_sound_activation"], y)
        local _, ny = Cb(c,L["ins_sound_enable"], lsDB.enabled, y, function(v)
            TomoModDB.lustSound = TomoModDB.lustSound or {}
            TomoModDB.lustSound.enabled = v
            if TomoMod_LustSound and TomoMod_LustSound.SetEnabled then TomoMod_LustSound.SetEnabled(v) end
        end); y=ny

        y = Sec(c,L["ins_sound_choice"], y)
        local soundOpts = {}
        if TomoMod_LustSound and TomoMod_LustSound.soundRegistry then
            for key, entry in pairs(TomoMod_LustSound.soundRegistry) do
                soundOpts[#soundOpts+1] = { value = key, text = entry.name }
            end
            table.sort(soundOpts, function(a,b) return a.text < b.text end)
        else
            soundOpts = {{value="default", text=L["ins_sound_default"]}}
        end
        local _, ny = Dd(c,L["ins_sound_sound"], soundOpts, lsDB.sound or "default", y, function(v)
            TomoModDB.lustSound = TomoModDB.lustSound or {}
            TomoModDB.lustSound.sound = v
        end); y=ny

        local _, ny = Dd(c,L["ins_sound_channel"], {
            {value="Master",   text="Master"},
            {value="SFX",      text="SFX"},
            {value="Music",    text="Music"},
        }, lsDB.channel or "SFX", y, function(v)
            TomoModDB.lustSound = TomoModDB.lustSound or {}
            TomoModDB.lustSound.channel = v
        end); y=ny

        y = Sec(c,L["ins_sound_preview_section"], y)
        local _, ny = BigBtn(c,L["ins_sound_preview_btn"], y, function()
            if TomoMod_LustSound then TomoMod_LustSound.PlayPreview() end
        end, false); y=ny
        return y
    end,
}

-- ── STEP 8: Mythic+ ───────────────────────────────────────
steps[8] = {
    title = L["ins_step8_title"],
    icon  = ICON_PATH.."icon_mythicplus.tga",
    build = function(c)
        local y = -10
        local mtDB = TomoModDB.MythicTracker or {}
        local tsDB = TomoModDB.TomoScore or {}
        y = Sec(c,L["ins_mplus_tracker_section"], y)
        y = Info(c,L["ins_mplus_tracker_info"], y)
        local _, ny = Cb(c,L["ins_mplus_tracker_enable"], mtDB.enabled, y, function(v)
            TomoModDB.MythicTracker = TomoModDB.MythicTracker or {}
            TomoModDB.MythicTracker.enabled = v
        end); y=ny
        local _, ny = Cb(c,L["ins_mplus_show_timer"], mtDB.showTimer, y, function(v)
            TomoModDB.MythicTracker.showTimer = v
        end); y=ny
        local _, ny = Cb(c,L["ins_mplus_show_forces"], mtDB.showForces, y, function(v)
            TomoModDB.MythicTracker.showForces = v
        end); y=ny
        local _, ny = Cb(c,L["ins_mplus_hide_blizzard"], mtDB.hideBlizzard, y, function(v)
            TomoModDB.MythicTracker.hideBlizzard = v
        end); y=ny

        y = Sec(c,L["ins_mplus_score_section"], y)
        y = Info(c,L["ins_mplus_score_info"], y)
        local _, ny = Cb(c,L["ins_mplus_score_enable"], tsDB.enabled, y, function(v)
            TomoModDB.TomoScore = TomoModDB.TomoScore or {}
            TomoModDB.TomoScore.enabled = v
        end); y=ny
        local _, ny = Cb(c,L["ins_mplus_score_auto"], tsDB.autoShowMPlus, y, function(v)
            TomoModDB.TomoScore.autoShowMPlus = v
        end); y=ny
        return y
    end,
}

-- ── STEP 9: CVars ─────────────────────────────────────────
steps[9] = {
    title = L["ins_step9_title"],
    icon  = ICON_PATH.."icon_qol.tga",
    build = function(c)
        local y = -10
        y = Info(c,L["ins_cvar_info"], y)
        y = Sec(c,L["ins_cvar_section"], y)
        local opts = {
            L["ins_cvar_opt1"],
            L["ins_cvar_opt2"],
            L["ins_cvar_opt3"],
            L["ins_cvar_opt4"],
            L["ins_cvar_opt5"],
            L["ins_cvar_opt6"],
        }
        for _, o in ipairs(opts) do
            local dot = c:CreateFontString(nil,"OVERLAY")
            dot:SetFont(FONT,11,""); dot:SetPoint("TOPLEFT",18,y)
            dot:SetTextColor(A[1],A[2],A[3],0.8); dot:SetText("•  "..o)
            y = y - 20
        end
        y = y - 6
        local applied = false
        local statusLbl = c:CreateFontString(nil,"OVERLAY")
        statusLbl:SetFont(FONT_BOLD,11,""); statusLbl:SetPoint("TOPLEFT",12,y-44)
        statusLbl:SetTextColor(A[1],A[2],A[3],0)
        statusLbl:SetText(L["ins_cvar_success"])
        local _, ny = BigBtn(c,L["ins_cvar_apply_btn"], y, function()
            if TomoMod_CVarOptimizer and TomoMod_CVarOptimizer.ApplyAll then
                TomoMod_CVarOptimizer.ApplyAll()
                applied = true
                statusLbl:SetTextColor(A[1],A[2],A[3],1)
                print("|cff0cd29fTomoMod|r " .. L["ins_cvar_applied"])
            end
        end, true); y=ny
        y = y - 44  -- room for status label
        return y
    end,
}

-- ── STEP 10: QOL ──────────────────────────────────────────
steps[10] = {
    title = L["ins_step10_title"],
    icon  = ICON_PATH.."icon_qol.tga",
    build = function(c)
        local y = -10
        y = Info(c,L["ins_qol_info"], y)
        y = Sec(c,L["ins_qol_auto_section"], y)
        local function qol(lbl, get, set, onTrue, ny)
            local _, nny = Cb(c, lbl, get(), ny, function(v)
                set(v); if v and onTrue then onTrue() end
            end)
            return nny
        end
        y = qol(L["ins_qol_auto_repair"],
            function() return TomoModDB.autoSummon and TomoModDB.autoSummon.enabled end,
            function(v)
                TomoModDB.autoVendorRepair = TomoModDB.autoVendorRepair or {}
                TomoModDB.autoVendorRepair.enabled = v
            end, nil, y)
        y = qol(L["ins_qol_fast_loot"],
            function() return TomoModDB.fastLoot and TomoModDB.fastLoot.enabled end,
            function(v) TomoModDB.fastLoot = TomoModDB.fastLoot or {}; TomoModDB.fastLoot.enabled = v end, nil, y)
        y = qol(L["ins_qol_skip_cinematics"],
            function() return TomoModDB.cinematicSkip and TomoModDB.cinematicSkip.enabled end,
            function(v) TomoModDB.cinematicSkip.enabled = v end, nil, y)
        y = qol(L["ins_qol_hide_talking_head"],
            function() return false end,
            function(v) TomoModDB.hideTalkingHead = { enabled = v } end, nil, y)
        y = qol(L["ins_qol_auto_accept"],
            function() return TomoModDB.autoAcceptInvite and TomoModDB.autoAcceptInvite.enabled end,
            function(v) TomoModDB.autoAcceptInvite.enabled = v end, nil, y)
        y = qol(L["ins_qol_tooltip_ids"],
            function() return TomoModDB.tooltipIDs and TomoModDB.tooltipIDs.enabled end,
            function(v) TomoModDB.tooltipIDs.enabled = v end, nil, y)

        y = Sec(c,L["ins_qol_combat_section"], y)
        y = qol(L["ins_qol_combat_text"],
            function() return TomoModDB.combatText and TomoModDB.combatText.enabled end,
            function(v) TomoModDB.combatText.enabled = v end, nil, y)
        y = qol(L["ins_qol_hide_castbar"],
            function() return TomoModDB.hideCastBar and TomoModDB.hideCastBar.enabled end,
            function(v) TomoModDB.hideCastBar.enabled = v end, nil, y)
        return y
    end,
}

-- ── STEP 11: SkyRide ──────────────────────────────────────
steps[11] = {
    title = L["ins_step11_title"],
    icon  = ICON_PATH.."icon_resources.tga",
    build = function(c)
        local y = -10
        local srDB = TomoModDB.skyRide or {}
        y = Info(c,L["ins_skyride_info"], y)
        y = Sec(c,L["ins_skyride_activation"], y)
        local _, ny = Cb(c,L["ins_skyride_enable"], srDB.enabled, y, function(v)
            TomoModDB.skyRide = TomoModDB.skyRide or {}
            TomoModDB.skyRide.enabled = v
            if TomoMod_SkyRide then TomoMod_SkyRide.SetEnabled(v) end
        end); y=ny
        y = Info(c,L["ins_skyride_auto_info"], y)

        y = Sec(c,L["ins_skyride_dimensions"], y)
        local _, ny = Sldr(c,L["ins_skyride_width"], srDB.width or 340, 150, 600, 10, y, function(v)
            TomoModDB.skyRide.width = v
            if TomoMod_SkyRide then TomoMod_SkyRide.ApplySettings() end
        end); y=ny
        local _, ny = Sldr(c,L["ins_skyride_height"], srDB.height or 20, 8, 40, 1, y, function(v)
            TomoModDB.skyRide.height = v
            if TomoMod_SkyRide then TomoMod_SkyRide.ApplySettings() end
        end); y=ny

        y = Sec(c,L["ins_skyride_reset_section"], y)
        local _, ny = BigBtn(c,L["ins_skyride_reset_btn"], y, function()
            if TomoMod_SkyRide then TomoMod_SkyRide.ResetPosition() end
        end, false); y=ny
        return y
    end,
}

-- ── STEP 12: Fin ──────────────────────────────────────────
steps[12] = {
    title = L["ins_step12_title"],
    icon  = ICON_PATH.."icon_general.tga",
    build = function(c)
        local logo = c:CreateTexture(nil,"OVERLAY")
        logo:SetSize(52,52); logo:SetPoint("TOP",0,-18)
        logo:SetTexture(LOGO_TEX); logo:SetVertexColor(A[1],A[2],A[3],1)

        local check = c:CreateFontString(nil,"OVERLAY")
        check:SetFont(FONT_BOLD,22,""); check:SetPoint("TOP",0,-78)
        check:SetTextColor(A[1],A[2],A[3],1); check:SetText(L["ins_done_check"])

        local recap = c:CreateFontString(nil,"OVERLAY")
        recap:SetFont(FONT,11,""); recap:SetPoint("TOPLEFT",40,-120); recap:SetPoint("TOPRIGHT",-40,-120)
        recap:SetJustifyH("LEFT"); recap:SetSpacing(3); recap:SetWordWrap(true)
        recap:SetTextColor(TX[1],TX[2],TX[3],0.85)
        recap:SetText(L["ins_done_recap"])

        local rlBtn = CreateFrame("Button", nil, c, "BackdropTemplate")
        rlBtn:SetSize(280, 42); rlBtn:SetPoint("TOP", recap, "BOTTOM", 0, -30)
        rlBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
        rlBtn:SetBackdropColor(AD[1],AD[2],AD[3],0.9)
        rlBtn:SetBackdropBorderColor(A[1],A[2],A[3],0.8)
        local rlTxt = rlBtn:CreateFontString(nil,"OVERLAY")
        rlTxt:SetFont(FONT_BOLD,14,""); rlTxt:SetPoint("CENTER"); rlTxt:SetText(L["ins_done_reload"])
        rlTxt:SetTextColor(1,1,1,1)
        rlBtn:SetScript("OnEnter",function()
            rlBtn:SetBackdropColor(A[1],A[2],A[3],1); rlTxt:SetTextColor(0.05,0.05,0.07,1)
        end)
        rlBtn:SetScript("OnLeave",function()
            rlBtn:SetBackdropColor(AD[1],AD[2],AD[3],0.9); rlTxt:SetTextColor(1,1,1,1)
        end)
        rlBtn:SetScript("OnClick",function()
            TomoModDB.installer.completed = true
            ReloadUI()
        end)
        return -300
    end,
}

-- ============================================================
-- FRAME CONSTRUCTION
-- ============================================================
local function BuildFrame()
    -- Dimmer
    dimmer = CreateFrame("Frame", nil, UIParent)
    dimmer:SetFrameStrata("DIALOG")
    dimmer:SetAllPoints(UIParent)
    dimmer:EnableMouse(true)
    local dimTex = dimmer:CreateTexture(nil,"BACKGROUND")
    dimTex:SetAllPoints(); dimTex:SetColorTexture(0,0,0,0.60)
    dimmer:Hide()

    -- Main panel
    frame = CreateFrame("Frame", "TomoModInstallerFrame", UIParent, "BackdropTemplate")
    frame:SetSize(PANEL_W, PANEL_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(150)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    frame:SetBackdropColor(BG[1],BG[2],BG[3],BG[4])
    frame:SetBackdropBorderColor(A[1],A[2],A[3],0.40)
    frame:SetMovable(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",frame.StartMoving)
    frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "TomoModInstallerFrame")

    -- ── HEADER ─────────────────────────────────────────────
    local hBar = CreateFrame("Frame",nil,frame)
    hBar:SetPoint("TOPLEFT"); hBar:SetPoint("TOPRIGHT"); hBar:SetHeight(52)
    local hBg = hBar:CreateTexture(nil,"BACKGROUND")
    hBg:SetAllPoints(); hBg:SetColorTexture(0.05,0.05,0.065,1)
    local hLine = frame:CreateTexture(nil,"ARTWORK")
    hLine:SetHeight(1); hLine:SetPoint("TOPLEFT",0,-52); hLine:SetPoint("TOPRIGHT",0,-52)
    hLine:SetColorTexture(A[1],A[2],A[3],0.22)

    -- Logo mini
    local hLogo = hBar:CreateTexture(nil,"OVERLAY")
    hLogo:SetSize(24,24); hLogo:SetPoint("LEFT",14,0)
    hLogo:SetTexture(LOGO_TEX); hLogo:SetVertexColor(A[1],A[2],A[3],1)
    local hTitle = hBar:CreateFontString(nil,"OVERLAY")
    hTitle:SetFont(FONT_BOLD,14,""); hTitle:SetPoint("LEFT",hLogo,"RIGHT",8,1)
    hTitle:SetText(L["ins_header_title"])

    -- Step counter
    stepLabel = hBar:CreateFontString(nil,"OVERLAY")
    stepLabel:SetFont(FONT,10,""); stepLabel:SetPoint("RIGHT",-14,0)
    stepLabel:SetTextColor(DM[1],DM[2],DM[3],1)

    -- ── STEP DOTS ──────────────────────────────────────────
    local dotHost = CreateFrame("Frame",nil,frame)
    dotHost:SetPoint("TOPLEFT",0,-52); dotHost:SetPoint("TOPRIGHT",0,-52); dotHost:SetHeight(28)
    local dotBg = dotHost:CreateTexture(nil,"BACKGROUND")
    dotBg:SetAllPoints(); dotBg:SetColorTexture(0.07,0.07,0.09,1)

    local DOT_SIZE = 10
    local DOT_GAP  = 8
    local totalDotW = TOTAL_STEPS * DOT_SIZE + (TOTAL_STEPS - 1) * DOT_GAP
    local dotStartX = (PANEL_W - totalDotW) / 2

    for i = 1, TOTAL_STEPS do
        local dot = dotHost:CreateTexture(nil,"OVERLAY")
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetPoint("LEFT", dotHost, "LEFT", dotStartX + (i-1)*(DOT_SIZE+DOT_GAP), 0)
        dot:SetColorTexture(BD[1],BD[2],BD[3],1)
        stepDots[i] = dot
    end
    local dotLine = frame:CreateTexture(nil,"ARTWORK")
    dotLine:SetHeight(1); dotLine:SetPoint("TOPLEFT",0,-80); dotLine:SetPoint("TOPRIGHT",0,-80)
    dotLine:SetColorTexture(BD[1],BD[2],BD[3],1)

    -- ── STEP TITLE ─────────────────────────────────────────
    local stepTitleFrame = CreateFrame("Frame",nil,frame)
    stepTitleFrame:SetPoint("TOPLEFT",0,-80); stepTitleFrame:SetPoint("TOPRIGHT",0,-80)
    stepTitleFrame:SetHeight(42)
    local stBg = stepTitleFrame:CreateTexture(nil,"BACKGROUND")
    stBg:SetAllPoints(); stBg:SetColorTexture(0.052,0.052,0.066,1)

    local stepIcon = stepTitleFrame:CreateTexture(nil,"OVERLAY")
    stepIcon:SetSize(22,22); stepIcon:SetPoint("LEFT",16,0)
    frame._stepIcon = stepIcon

    local stepTitleLbl = stepTitleFrame:CreateFontString(nil,"OVERLAY")
    stepTitleLbl:SetFont(FONT_BOLD,13,""); stepTitleLbl:SetPoint("LEFT",stepIcon,"RIGHT",10,0)
    stepTitleLbl:SetTextColor(0.90,0.92,0.91,1)
    frame._stepTitle = stepTitleLbl

    local stLine = frame:CreateTexture(nil,"ARTWORK")
    stLine:SetHeight(1); stLine:SetPoint("TOPLEFT",0,-122); stLine:SetPoint("TOPRIGHT",0,-122)
    stLine:SetColorTexture(A[1],A[2],A[3],0.15)

    -- ── CONTENT HOST ───────────────────────────────────────
    contentHost = CreateFrame("Frame",nil,frame)
    contentHost:SetPoint("TOPLEFT",0,-123); contentHost:SetPoint("BOTTOMRIGHT",0,60)
    contentHost:SetClipsChildren(true)

    -- ── NAV BUTTONS ────────────────────────────────────────
    local navBar = CreateFrame("Frame",nil,frame)
    navBar:SetPoint("BOTTOMLEFT"); navBar:SetPoint("BOTTOMRIGHT"); navBar:SetHeight(60)
    local navBg = navBar:CreateTexture(nil,"BACKGROUND")
    navBg:SetAllPoints(); navBg:SetColorTexture(0.05,0.05,0.065,1)
    local navLine = navBar:CreateTexture(nil,"ARTWORK")
    navLine:SetHeight(1); navLine:SetPoint("TOPLEFT"); navLine:SetPoint("TOPRIGHT")
    navLine:SetColorTexture(BD[1],BD[2],BD[3],1)

    -- Previous button
    prevBtn = CreateFrame("Button",nil,navBar,"BackdropTemplate")
    prevBtn:SetSize(140,32); prevBtn:SetPoint("LEFT",16,0)
    prevBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    prevBtn:SetBackdropColor(BG2[1],BG2[2],BG2[3],1); prevBtn:SetBackdropBorderColor(BD[1],BD[2],BD[3],1)
    local prevTxt = prevBtn:CreateFontString(nil,"OVERLAY")
    prevTxt:SetFont(FONT,12,""); prevTxt:SetPoint("CENTER"); prevTxt:SetText(L["ins_btn_prev"])
    prevTxt:SetTextColor(TX[1],TX[2],TX[3],1)
    prevBtn:SetScript("OnEnter",function() prevBtn:SetBackdropBorderColor(A[1],A[2],A[3],0.6); prevTxt:SetTextColor(A[1],A[2],A[3],1) end)
    prevBtn:SetScript("OnLeave",function() prevBtn:SetBackdropBorderColor(BD[1],BD[2],BD[3],1); prevTxt:SetTextColor(TX[1],TX[2],TX[3],1) end)
    prevBtn:SetScript("OnClick",function() INS.GoToStep(currentStep - 1) end)

    -- Next button
    nextBtn = CreateFrame("Button",nil,navBar,"BackdropTemplate")
    nextBtn:SetSize(160,32); nextBtn:SetPoint("RIGHT",-16,0)
    nextBtn:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    nextBtn:SetBackdropColor(AD[1],AD[2],AD[3],0.85); nextBtn:SetBackdropBorderColor(A[1],A[2],A[3],0.7)
    local nextTxt = nextBtn:CreateFontString(nil,"OVERLAY")
    nextTxt:SetFont(FONT_BOLD,12,""); nextTxt:SetPoint("CENTER"); nextTxt:SetText(L["ins_btn_next"])
    nextTxt:SetTextColor(1,1,1,1)
    nextBtn:SetScript("OnEnter",function() nextBtn:SetBackdropColor(A[1],A[2],A[3],1); nextTxt:SetTextColor(0.05,0.05,0.07,1) end)
    nextBtn:SetScript("OnLeave",function() nextBtn:SetBackdropColor(AD[1],AD[2],AD[3],0.85); nextTxt:SetTextColor(1,1,1,1) end)
    nextBtn:SetScript("OnClick",function() INS.GoToStep(currentStep + 1) end)

    -- Skip link
    local skipBtn = CreateFrame("Button",nil,navBar)
    skipBtn:SetSize(120,20); skipBtn:SetPoint("CENTER")
    local skipTxt = skipBtn:CreateFontString(nil,"OVERLAY")
    skipTxt:SetFont(FONT,10,""); skipTxt:SetPoint("CENTER")
    skipTxt:SetTextColor(DM[1],DM[2],DM[3],1); skipTxt:SetText(L["ins_btn_skip"])
    skipBtn:SetScript("OnEnter",function() skipTxt:SetTextColor(TX[1],TX[2],TX[3],1) end)
    skipBtn:SetScript("OnLeave",function() skipTxt:SetTextColor(DM[1],DM[2],DM[3],1) end)
    skipBtn:SetScript("OnClick",function()
        TomoModDB.installer.completed = true
        INS.Hide()
    end)
end

-- ============================================================
-- NAVIGATION
-- ============================================================
function INS.GoToStep(n)
    if not frame then return end
    n = math.max(1, math.min(TOTAL_STEPS, n))

    -- Hide all panels, reset scroll position
    for _, p in pairs(stepPanels) do
        p:Hide()
        if p._sf then p._sf:SetVerticalScroll(0) end
    end

    -- Build panel if not done yet
    if not stepPanels[n] then
        local SCROLL_W   = 5
        local SCROLL_PAD = 8
        local SF_INSET   = 16  -- right inset reserved for scrollbar

        local p = CreateFrame("Frame", nil, contentHost)
        p:Hide()  -- hide before building to prevent overlap flash
        p:SetAllPoints(contentHost)

        -- Scrollbar track
        local track = p:CreateTexture(nil, "BACKGROUND")
        track:SetWidth(SCROLL_W)
        track:SetPoint("TOPRIGHT",    -SCROLL_PAD, -SCROLL_PAD)
        track:SetPoint("BOTTOMRIGHT", -SCROLL_PAD,  SCROLL_PAD)
        track:SetColorTexture(0.12, 0.12, 0.16, 0.70)
        track:Hide()

        -- Scrollbar thumb
        local thumbF = CreateFrame("Frame", nil, p)
        thumbF:SetWidth(SCROLL_W)
        local thumbTex = thumbF:CreateTexture(nil, "OVERLAY")
        thumbTex:SetAllPoints()
        thumbTex:SetColorTexture(A[1], A[2], A[3], 0.75)
        thumbF:Hide()

        -- ScrollFrame (inset on right for scrollbar)
        local sf = CreateFrame("ScrollFrame", nil, p)
        sf:SetPoint("TOPLEFT",     0, 0)
        sf:SetPoint("BOTTOMRIGHT", -SF_INSET, 0)
        p._sf = sf

        -- Content child
        local c = CreateFrame("Frame", nil, sf)
        c:SetWidth(PANEL_W - SF_INSET)
        c:SetHeight(1)
        sf:SetScrollChild(c)

        -- Build content, capture final y for height
        local finalY = steps[n] and steps[n].build and steps[n].build(c) or -10
        c:SetHeight(math.max(math.abs(finalY) + 20, 100))

        -- Scrollbar update
        local function Upd()
            local sfH  = sf:GetHeight() or 0
            local cH   = c:GetHeight()  or 0
            local maxS = cH - sfH
            if maxS <= 0 then track:Hide(); thumbF:Hide(); return end
            track:Show(); thumbF:Show()
            local trkH  = sfH - 2 * SCROLL_PAD
            local ratio = sfH / cH
            local thH   = math.max(20, math.floor(trkH * ratio))
            thumbF:SetHeight(thH)
            local cur = sf:GetVerticalScroll()
            local thY = (cur / maxS) * (trkH - thH)
            thumbF:ClearAllPoints()
            thumbF:SetPoint("TOPRIGHT", p, "TOPRIGHT", -SCROLL_PAD, -(SCROLL_PAD + thY))
        end

        sf:EnableMouseWheel(true)
        sf:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll()
            self:SetVerticalScroll(math.max(0, math.min(cur - delta * 36, self:GetVerticalScrollRange())))
            Upd()
        end)
        sf:SetScript("OnShow",        function(self) local w = self:GetWidth(); if w and w > 0 then c:SetWidth(w) end; C_Timer.After(0, Upd) end)
        sf:SetScript("OnSizeChanged", function(self, w) if w and w > 10 then c:SetWidth(w) end; Upd() end)

        p._upd = Upd
        stepPanels[n] = p
    end

    stepPanels[n]:Show()
    C_Timer.After(0, stepPanels[n]._upd)

    currentStep = n
    TomoModDB.installer.step = n

    -- Update dots
    for i, dot in ipairs(stepDots) do
        if i == n then
            dot:SetColorTexture(A[1],A[2],A[3],1)
            dot:SetSize(12,12)
        elseif i < n then
            dot:SetColorTexture(AD[1],AD[2],AD[3],0.8)
            dot:SetSize(10,10)
        else
            dot:SetColorTexture(BD[1],BD[2],BD[3],1)
            dot:SetSize(10,10)
        end
    end

    -- Update header
    stepLabel:SetText(string.format(L["ins_step_counter"], n, TOTAL_STEPS))
    if steps[n] then
        if frame._stepTitle then frame._stepTitle:SetText(steps[n].title) end
        if frame._stepIcon  then
            frame._stepIcon:SetTexture(steps[n].icon)
            frame._stepIcon:SetVertexColor(A[1],A[2],A[3],1)
        end
    end

    -- Update nav buttons
    prevBtn:SetShown(n > 1)
    if n == TOTAL_STEPS then
        nextBtn:Hide()
    else
        nextBtn:Show()
        local nextTxt = nextBtn:GetFontString()
        if nextTxt then
            nextTxt:SetText(n == TOTAL_STEPS - 1 and L["ins_btn_finish"] or L["ins_btn_next"])
        end
    end
end

-- ============================================================
-- PUBLIC API
-- ============================================================
function INS.Show()
    if not frame then BuildFrame() end
    dimmer:Show()
    frame:Show()
    local step = (TomoModDB and TomoModDB.installer and TomoModDB.installer.step) or 1
    INS.GoToStep(step)
end

function INS.Hide()
    if dimmer then dimmer:Hide() end
    if frame  then frame:Hide()  end
end

function INS.Toggle()
    if frame and frame:IsShown() then INS.Hide() else INS.Show() end
end

-- ── Auto-ouverture au premier démarrage ────────────────────
local bootF = CreateFrame("Frame")
bootF:RegisterEvent("PLAYER_LOGIN")
bootF:SetScript("OnEvent", function()
    C_Timer.After(1.5, function()
        if not TomoModDB then return end
        TomoModDB.installer = TomoModDB.installer or { completed = false, step = 1 }
        if not TomoModDB.installer.completed then
            INS.Show()
        end
    end)
end)
