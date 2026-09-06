-- =====================================================================
-- TomoMod Resource & Cast Studio
-- LoadOnDemand visual editor for ResourceBars + Player Castbar.
-- =====================================================================

local W=TomoMod_Widgets
local Forge=TomoMod_Forge
local Preview=TomoMod_ResourceCastPreview
if not W then TomoMod_ResourceCastStudio={loadError="TomoMod_Widgets indisponible"} return end
if not (Forge and Forge.Studio) then TomoMod_ResourceCastStudio={loadError="TomoMod_Forge incomplet"} return end
if not Preview then TomoMod_ResourceCastStudio={loadError="ResourceCastPreview indisponible"} return end

local L=TomoMod_L
local BRAND=Forge.BRAND
local FONT=Forge.FONT
local FONT_BOLD=Forge.FONT_BOLD
local WHITE8="Interface\\Buttons\\WHITE8x8"

local floor,max,min=math.floor,math.max,math.min
local ipairs,pairs,type,tonumber=ipairs,pairs,type,tonumber

local S={
    view="resources",
    resourceSection="general",
    castSection="general",
    previewKind="auto",
}
TomoMod_ResourceCastStudio=S

local frame,sidebarList,sideTitle,crudHost,contentHost,footerHint
local navHost,stageHost,inspectorHost,refreshButton
local resourcePreview,castPreview
local navButtons,rows={},{}
local tutorialUI
local TUTORIAL_VERSION=1

local RESOURCE_SECTIONS={
    {id="general",key="rcs_sec_general"},
    {id="visibility",key="rcs_sec_visibility"},
    {id="layout",key="rcs_sec_layout"},
    {id="health",key="rcs_sec_health"},
    {id="power",key="rcs_sec_power"},
    {id="class",key="rcs_sec_class"},
    {id="text",key="rcs_sec_text"},
    {id="colors",key="rcs_sec_colors"},
    {id="position",key="rcs_sec_position"},
}
local CAST_SECTIONS={
    {id="general",key="rcs_sec_cast_general"},
    {id="player",key="rcs_sec_cast_player"},
    {id="appearance",key="rcs_sec_cast_appearance"},
    {id="colors",key="rcs_sec_cast_colors"},
    {id="spark",key="rcs_sec_cast_spark"},
    {id="gcd",key="rcs_sec_cast_gcd"},
    {id="interrupt",key="rcs_sec_cast_interrupt"},
    {id="position",key="rcs_sec_position"},
}

local FONT_LIST={
    {text="Poppins Medium",value="Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"},
    {text="Poppins SemiBold",value="Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"},
    {text="Poppins Bold",value="Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Bold.ttf"},
    {text="Expressway",value="Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Expressway.TTF"},
    {text="Tomo",value="Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf"},
    {text="Friz Quadrata",value="Fonts\\FRIZQT__.TTF"},
    {text="Arial Narrow",value="Fonts\\ARIALN.TTF"},
}

local function T(key,fallback)
    local v=L and L[key]
    if v and v~=key then return v end
    return fallback or key
end

local function CanEdit()
    if InCombatLockdown() then
        print("|cff2e9dd8TomoMod|r : "..T("rcs_combat","Studio unavailable in combat."))
        return false
    end
    return true
end

local function Clamp(v,lo,hi)
    v=tonumber(v) or lo
    if v<lo then return lo end
    if v>hi then return hi end
    return v
end

local function DeepCopy(v)
    if type(v)~="table" then return v end
    local out={}
    for k,x in pairs(v) do out[k]=DeepCopy(x) end
    return out
end

local function Header(c,y,text,icon)
    local _,ny=W.CreateSectionHeader(c,text,y,icon or "R")
    return ny
end
local function Info(c,text,y)
    local _,ny=W.CreateInfoText(c,text,y); return ny
end
local function Sep(c,y)
    local _,ny=W.CreateSeparator(c,y); return ny
end
local function Pair(c,y,a,b)
    local _,ny=W.CreateTwoColumnRow(c,y,a,b); return ny
end
local function Bool(c,text,value,y,cb)
    local _,ny=W.CreateCheckbox(c,text,value,y,cb); return ny
end
local function Slider(c,text,value,lo,hi,step,y,cb,fmt)
    local _,ny=W.CreateSlider(c,text,value,lo,hi,step,y,cb,fmt); return ny
end
local function Dropdown(c,text,opts,value,y,cb)
    local _,ny=W.CreateDropdown(c,text,opts,value,y,cb); return ny
end
local function Color(c,text,value,y,cb)
    local _,ny=W.CreateColorPicker(c,text,value,y,cb); return ny
end

local function EditRow(c,text,value,y,cb,hint)
    local row=CreateFrame("Frame",nil,c)
    row:SetPoint("TOPLEFT",12,y); row:SetPoint("TOPRIGHT",-12,y); row:SetHeight(hint and 58 or 42)
    local label=row:CreateFontString(nil,"OVERLAY")
    label:SetFont(FONT,10,""); label:SetPoint("TOPLEFT",0,0); label:SetText(text); label:SetTextColor(.72,.76,.84,1)
    local edit=CreateFrame("EditBox",nil,row,"InputBoxTemplate")
    edit:SetAutoFocus(false); edit:SetHeight(24); edit:SetPoint("TOPLEFT",0,-17); edit:SetPoint("TOPRIGHT",0,-17)
    edit:SetText(value or ""); edit:SetCursorPosition(0)
    edit:SetScript("OnEnterPressed",function(self) self:ClearFocus(); if cb then cb(self:GetText() or "") end end)
    edit:SetScript("OnEditFocusLost",function(self) if cb then cb(self:GetText() or "") end end)
    if hint then
        local h=row:CreateFontString(nil,"OVERLAY")
        h:SetFont(FONT,8,""); h:SetPoint("TOPLEFT",edit,"BOTTOMLEFT",4,-2); h:SetText(hint); h:SetTextColor(.42,.46,.54,1)
    end
    return y-row:GetHeight()-6
end

local function RBDB()
    TomoModDB.resourceBars=TomoModDB.resourceBars or {}
    return TomoModDB.resourceBars
end
local function CastDB()
    TomoModDB.castbars=TomoModDB.castbars or {}
    TomoModDB.castbars.player=TomoModDB.castbars.player or {}
    return TomoModDB.castbars
end

local function ApplyRB()
    local rb=TomoMod_ResourceBars
    local db=RBDB()

    -- Refresh the detached Studio preview first. Runtime ResourceBars may
    -- rebuild several frames, but that must never leave the editor visually
    -- stale if a runtime update is delayed or rejected by the game state.
    if resourcePreview and resourcePreview:IsShown() then
        if resourcePreview.SetPreviewKind then
            resourcePreview:SetPreviewKind(S.previewKind)
        else
            resourcePreview:Refresh(S.previewKind)
        end
    end

    if rb then
        if db.enabled and rb.SetEnabled then rb.SetEnabled(true)
        elseif not db.enabled and rb.SetEnabled then rb.SetEnabled(false)
        elseif rb.ApplySettings then rb.ApplySettings() end
        if rb.ApplySettings and db.enabled then rb.ApplySettings() end
    end
end

local function ApplyPrimaryCentered()
    ApplyRB()
    if TomoMod_UnitFrames and TomoMod_UnitFrames.RebuildUnit then
        TomoMod_UnitFrames.RebuildUnit("player")
    end
end

local function ApplyCB()
    if TomoMod_Castbar and TomoMod_Castbar.ApplySettings then TomoMod_Castbar.ApplySettings() end
    if castPreview and castPreview:IsShown() then castPreview:Refresh() end
end

local PREVIEW_KINDS={
    {text=T("rcs_preview_auto","Auto"),value="auto"},
    {text=T("rcs_preview_combo","Combo Points"),value="combo"},
    {text=T("rcs_preview_runes","Runes"),value="runes"},
    {text=T("rcs_preview_shards","Soul Shards"),value="shards"},
    {text=T("rcs_preview_holy","Holy Power"),value="holy"},
    {text=T("rcs_preview_chi","Chi"),value="chi"},
    {text=T("rcs_preview_essence","Essence"),value="essence"},
    {text=T("rcs_preview_arcane","Arcane Charges"),value="arcane"},
    {text=T("rcs_preview_stagger","Stagger"),value="stagger"},
    {text=T("rcs_preview_aura","Aura resource"),value="aura"},
}

local function EnsureStyle(db,key)
    db.styles=db.styles or {}
    local st=db.styles[key]
    if not st then
        st={
            barTexture=db.barTexture or "tomo",
            backgroundAlpha=db.backgroundAlpha or .80,
            borderEnabled=db.borderEnabled~=false,
            borderSize=db.borderSize or 1,
            borderColor=DeepCopy(db.borderColor or {r=0,g=0,b=0}),
        }
        db.styles[key]=st
    end
    st.borderColor=st.borderColor or {r=0,g=0,b=0}
    return st
end

local function EnsureClassDesigner(db)
    db.classResource=db.classResource or {}
    local cr=db.classResource
    if cr.mode==nil then cr.mode="segments" end
    if cr.orientation==nil then cr.orientation="HORIZONTAL" end
    if cr.partialFill==nil then cr.partialFill=true end
    if cr.borderMode==nil then cr.borderMode="segments" end
    cr.emptyColor=cr.emptyColor or {r=.06,g=.06,b=.08}

    db.hashLines=db.hashLines or {}
    for _,key in ipairs({"power","class"}) do
        db.hashLines[key]=db.hashLines[key] or {}
        local h=db.hashLines[key]
        if h.enabled==nil then h.enabled=false end
        h.values=h.values or ""
        h.mode=h.mode or "percent"
        h.width=h.width or 1
        h.color=h.color or {r=1,g=1,b=1,a=.75}
        if h.color.a==nil then h.color.a=.75 end
    end

    db.thresholds=db.thresholds or {}
    db.thresholds.class=db.thresholds.class or {}
    local th=db.thresholds.class
    if th.enabled==nil then th.enabled=false end
    th.mode=th.mode or "percent"
    if th.low==nil then th.low=30 end
    if th.high==nil then th.high=80 end
    th.lowColor=th.lowColor or {r=1,g=.22,b=.18}
    th.highColor=th.highColor or {r=1,g=.78,b=.16}
    th.target=th.target or "both"
    return cr,db.hashLines,th
end

local function BuildStyleControls(c,y,db,key,title)
    local st=EnsureStyle(db,key)
    y=Header(c,y,title,"S")
    y=Dropdown(c,T("rcs_bar_texture","Bar texture"),{
        {text=T("rcs_tex_tomo","TomoMod"),value="tomo"},
        {text=T("rcs_tex_flat","Flat"),value="flat"},
        {text=T("rcs_tex_blizzard","Blizzard"),value="blizzard"},
    },st.barTexture or "tomo",y,function(v) st.barTexture=v; ApplyRB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_bg_alpha","Background opacity"),st.backgroundAlpha or .8,0,1,.05,0,function(v) st.backgroundAlpha=v; ApplyRB() end,"%.2f")
            return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rcs_border_enable","Show borders"),st.borderEnabled~=false,0,function(v) st.borderEnabled=v; ApplyRB() end)
            return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_border_size","Border size"),st.borderSize or 1,1,4,1,0,function(v) st.borderSize=v; ApplyRB() end,"%.0f")
            return n
        end,
        function(col)
            local _,n=W.CreateColorPicker(col,T("rcs_border_color","Border color"),st.borderColor,0,function(r,g,b) st.borderColor={r=r,g=g,b=b}; ApplyRB() end)
            return n
        end)
    return y
end

local function BuildHashControls(c,y,db,key)
    local _,hashes=EnsureClassDesigner(db)
    local h=hashes[key]
    y=Header(c,y,T("rcs_hash_title","Hash Lines V2"),"#")
    y=Bool(c,T("rcs_hash_enable","Show hash lines"),h.enabled,y,function(v) h.enabled=v; ApplyRB() end)
    y=EditRow(c,T("rcs_hash_values","Positions"),h.values or "",y,function(v) h.values=v; ApplyRB() end,T("rcs_hash_values_hint",""))
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateDropdown(col,T("rcs_hash_mode","Position mode"),{
                {text=T("rcs_hash_percent","Percent"),value="percent"},
                {text=T("rcs_hash_value","Value"),value="value"},
            },h.mode or "percent",0,function(v) h.mode=v; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_hash_width","Line thickness"),h.width or 1,1,5,1,0,function(v) h.width=v; ApplyRB() end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateColorPicker(col,T("rcs_hash_color","Line color"),h.color,0,function(r,g,b) h.color.r,h.color.g,h.color.b=r,g,b; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_hash_alpha","Line opacity"),h.color.a or .75,.05,1,.05,0,function(v) h.color.a=v; ApplyRB() end,"%.2f"); return n
        end)
    return y
end

-- =====================================================================
-- Resource sections
-- =====================================================================

local function BuildResourceGeneral(c,y,db)
    y=Header(c,y,T("rcs_sec_general","General"),"R")
    y=Bool(c,T("opt_rb_enable","Enable Resource Bars"),db.enabled~=false,y,function(v)
        if not CanEdit() then return end
        db.enabled=v; ApplyRB()
    end)
    y=Dropdown(c,T("rcs_preview_kind","Preview resource"),PREVIEW_KINDS,S.previewKind,y,function(v)
        S.previewKind=v or "auto"
        TomoModDB.resourceCastStudio=TomoModDB.resourceCastStudio or {}
        TomoModDB.resourceCastStudio.previewKind=S.previewKind
        if resourcePreview then
            if resourcePreview.SetPreviewKind then
                resourcePreview:SetPreviewKind(S.previewKind)
            else
                resourcePreview:Refresh(S.previewKind)
            end
        end
    end)
    y=Dropdown(c,T("opt_rb_display_mode","Display mode"),{
        {text=T("display_mode_icons","Icons"),value="icons"},
        {text=T("display_mode_bars","Bars"),value="bars"},
    },db.displayMode or "bars",y,function(v)
        db.displayMode=v
        if resourcePreview then
            if resourcePreview.SetPreviewKind then
                resourcePreview:SetPreviewKind(S.previewKind)
            else
                resourcePreview:Refresh(S.previewKind)
            end
        end
        ApplyRB()
    end)
    y=Bool(c,T("opt_rb_primary_centered","Centered primary power"),db.primaryPowerCentered or false,y,function(v)
        db.primaryPowerCentered=v; ApplyPrimaryCentered()
    end)
    y=Info(c,T("info_rb_primary_centered",""),y)
    return y
end

local function BuildResourceVisibility(c,y,db)
    y=Header(c,y,T("rcs_sec_visibility","Visibility"),"V")
    y=Dropdown(c,T("opt_rb_visibility_mode","Visibility mode"),{
        {text=T("vis_always","Always"),value="always"},
        {text=T("vis_combat","Combat"),value="combat"},
        {text=T("vis_target","Target"),value="target"},
        {text=T("vis_hidden","Hidden"),value="hidden"},
    },db.visibilityMode or "always",y,function(v) db.visibilityMode=v; ApplyRB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cdm_alpha_combat","Combat alpha"),db.combatAlpha or 1,0,1,.05,0,function(v) db.combatAlpha=v; ApplyRB() end,"%.2f")
            return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cdm_alpha_ooc","Out of combat alpha"),db.oocAlpha or .6,0,1,.05,0,function(v) db.oocAlpha=v; ApplyRB() end,"%.2f")
            return n
        end)
    return y
end

local function BuildResourceLayout(c,y,db)
    y=Header(c,y,T("rcs_sec_layout","Layout"),"L")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_width","Width"),db.width or 260,80,600,5,0,function(v) db.width=v; ApplyRB() end,"%.0f")
            return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_global_scale","Scale"),db.scale or 1,.5,2,.05,0,function(v) db.scale=v; ApplyRB() end,"%.2f")
            return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_classpower_height","Class power height"),db.primaryHeight or 16,6,40,1,0,function(v) db.primaryHeight=v; ApplyRB() end,"%.0f")
            return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_druidmana_height","Secondary mana height"),db.secondaryHeight or 12,6,30,1,0,function(v) db.secondaryHeight=v; ApplyRB() end,"%.0f")
            return n
        end)
    y=Slider(c,T("opt_rb_primary_power_height","Primary power height"),db.primaryPowerBarHeight or 14,6,30,1,y,function(v) db.primaryPowerBarHeight=v; ApplyRB() end,"%.0f")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_bar_spacing","Spacing between bars"),db.barSpacing or 2,0,12,1,0,function(v) db.barSpacing=v; ApplyRB() end,"%.0f")
            return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_segment_spacing","Segment spacing"),db.segmentSpacing or 2,0,12,1,0,function(v) db.segmentSpacing=v; ApplyRB() end,"%.0f")
            return n
        end)
    y=Dropdown(c,T("rcs_stack_direction","Stack direction"),{
        {text=T("rcs_stack_down","Down"),value="DOWN"},
        {text=T("rcs_stack_up","Up"),value="UP"},
    },db.stackDirection or "DOWN",y,function(v) db.stackDirection=v; ApplyRB() end)
    return y
end

local function BuildResourceHealth(c,y,db)
    db.colors=db.colors or {}
    db.colors.health=db.colors.health or {r=.15,g=.75,b=.30}
    db.colors.healthLow=db.colors.healthLow or {r=1,g=.2,b=.2}
    y=Header(c,y,T("rcs_sec_health","Health HUD"),"H")
    y=Bool(c,T("opt_rb_hb_enable","Enable health bar"),db.healthBarEnabled or false,y,function(v) db.healthBarEnabled=v; ApplyRB() end)
    y=Info(c,T("info_rb_healthbar",""),y)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_hb_height","Health height"),db.healthBarHeight or 14,8,30,1,0,function(v) db.healthBarHeight=v; ApplyRB() end,"%.0f")
            return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("opt_rb_hb_text","Health text"),{
                {text=T("hb_text_none","None"),value="none"},
                {text=T("hb_text_value","Value"),value="value"},
                {text=T("hb_text_percent","Percent"),value="percent"},
                {text=T("hb_text_both","Both"),value="both"},
            },db.healthTextFormat or "both",0,function(v) db.healthTextFormat=v; ApplyRB() end)
            return n
        end)
    y=Bool(c,T("opt_rb_hb_classcolor","Class color"),db.healthClassColored~=false,y,function(v) db.healthClassColored=v; ApplyRB() end)
    y=Color(c,T("opt_rb_hb_color","Health color"),db.colors.health,y,function(r,g,b) db.colors.health={r=r,g=g,b=b}; ApplyRB() end)
    y=Bool(c,T("opt_rb_hb_threshold","Low-health threshold"),db.healthThresholdEnabled~=false,y,function(v) db.healthThresholdEnabled=v; ApplyRB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_hb_threshold_pct","Threshold"),db.healthThresholdPct or 30,10,60,5,0,function(v) db.healthThresholdPct=v; ApplyRB() end,"%.0f%%")
            return n
        end,
        function(col)
            local _,n=W.CreateColorPicker(col,T("opt_rb_hb_threshold_color","Threshold color"),db.colors.healthLow,0,function(r,g,b) db.colors.healthLow={r=r,g=g,b=b}; ApplyRB() end)
            return n
        end)
    y=Sep(c,y)
    y=BuildStyleControls(c,y,db,"health",T("rcs_style_health","Health style"))
    return y
end

local function BuildResourcePower(c,y,db)
    db.colors=db.colors or {}
    db.colors.powerLow=db.colors.powerLow or {r=1,g=.25,b=.25}
    y=Header(c,y,T("rcs_sec_power","Power & animations"),"P")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_rb_smooth","Smooth bars"),db.smoothBars~=false,0,function(v) db.smoothBars=v; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_rb_full_glow","Full resource glow"),db.showFullResourceGlow~=false,0,function(v) db.showFullResourceGlow=v; ApplyRB() end); return n
        end)
    y=Bool(c,T("opt_rb_supercharged_points","Supercharged combo points"),db.showSuperchargedComboPoints~=false,y,function(v) db.showSuperchargedComboPoints=v; ApplyRB() end)
    y=Dropdown(c,T("opt_rb_power_ticks","Power ticks"),{
        {text=T("ticks_none","None"),value=""},
        {text="50%",value="50"},
        {text="25 / 50 / 75%",value="25 50 75"},
        {text="20 / 40 / 60 / 80%",value="20 40 60 80"},
    },db.powerTicks or "",y,function(v) db.powerTicks=v; ApplyRB() end)
    y=Bool(c,T("opt_rb_power_threshold","Low-power threshold"),db.powerThresholdEnabled or false,y,function(v) db.powerThresholdEnabled=v; ApplyRB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_power_threshold_pct","Threshold"),db.powerThresholdPct or 25,5,60,5,0,function(v) db.powerThresholdPct=v; ApplyRB() end,"%.0f%%"); return n
        end,
        function(col)
            local _,n=W.CreateColorPicker(col,T("opt_rb_power_threshold_color","Threshold color"),db.colors.powerLow,0,function(r,g,b) db.colors.powerLow={r=r,g=g,b=b}; ApplyRB() end); return n
        end)
    y=Info(c,T("info_rb_anim",""),y)
    y=Sep(c,y)
    y=BuildStyleControls(c,y,db,"power",T("rcs_style_power","Power style"))
    y=Sep(c,y)
    y=BuildHashControls(c,y,db,"power")
    return y
end

local function BuildResourceClass(c,y,db)
    local cr,_,th=EnsureClassDesigner(db)
    y=Header(c,y,T("rcs_sec_class","Class Resource Designer"),"C")
    y=Info(c,T("rcs_style_independent_info",""),y)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateDropdown(col,T("rcs_class_mode","Display type"),{
                {text=T("rcs_class_segments","Segments"),value="segments"},
                {text=T("rcs_class_bar","Continuous bar"),value="bar"},
            },cr.mode or "segments",0,function(v) cr.mode=v; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("rcs_class_orientation","Orientation"),{
                {text=T("rcs_horizontal","Horizontal"),value="HORIZONTAL"},
                {text=T("rcs_vertical","Vertical"),value="VERTICAL"},
            },cr.orientation or "HORIZONTAL",0,function(v) cr.orientation=v; ApplyRB() end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rcs_class_partial","Show partial fill"),cr.partialFill~=false,0,function(v) cr.partialFill=v; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("rcs_class_border_mode","Class resource border"),{
                {text=T("rcs_border_segments","Each segment"),value="segments"},
                {text=T("rcs_border_outer","Outer border"),value="outer"},
                {text=T("rcs_border_both","Both"),value="both"},
                {text=T("rcs_border_none","None"),value="none"},
            },cr.borderMode or "segments",0,function(v) cr.borderMode=v; ApplyRB() end); return n
        end)
    y=Color(c,T("rcs_class_empty_color","Empty segment color"),cr.emptyColor,y,function(r,g,b) cr.emptyColor={r=r,g=g,b=b}; ApplyRB() end)

    TomoModDB.resourceCastStudio=TomoModDB.resourceCastStudio or {}
    local uiDB=TomoModDB.resourceCastStudio
    if uiDB.demoValuePct==nil then uiDB.demoValuePct=70 end
    y=Slider(c,T("rcs_demo_value","Demonstration value"),uiDB.demoValuePct,0,100,5,y,function(v)
        uiDB.demoValuePct=v
        if resourcePreview then resourcePreview:Refresh(S.previewKind) end
    end,"%.0f%%")

    y=Sep(c,y)
    y=BuildStyleControls(c,y,db,"class",T("rcs_style_class","Class resource style"))
    y=Sep(c,y)
    y=BuildHashControls(c,y,db,"class")

    y=Sep(c,y)
    y=Header(c,y,T("rcs_threshold_title","Threshold System V2"),"!")
    y=Bool(c,T("rcs_threshold_enable","Enable class thresholds"),th.enabled,y,function(v) th.enabled=v; ApplyRB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateDropdown(col,T("rcs_threshold_mode","Threshold mode"),{
                {text=T("rcs_hash_percent","Percent"),value="percent"},
                {text=T("rcs_hash_value","Value"),value="value"},
            },th.mode or "percent",0,function(v) th.mode=v; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("rcs_threshold_target","Recolor"),{
                {text=T("rcs_threshold_bar","Bar / segments"),value="bar"},
                {text=T("rcs_threshold_text","Text"),value="text"},
                {text=T("rcs_threshold_both","Bar + text"),value="both"},
            },th.target or "both",0,function(v) th.target=v; ApplyRB() end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_threshold_low","Low threshold"),th.low or 30,0,100,1,0,function(v) th.low=v; ApplyRB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_threshold_high","High threshold"),th.high or 80,0,100,1,0,function(v) th.high=v; ApplyRB() end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateColorPicker(col,T("rcs_threshold_low_color","Low color"),th.lowColor,0,function(r,g,b) th.lowColor={r=r,g=g,b=b}; ApplyRB() end); return n
        end,
        function(col)
            local _,n=W.CreateColorPicker(col,T("rcs_threshold_high_color","High color"),th.highColor,0,function(r,g,b) th.highColor={r=r,g=g,b=b}; ApplyRB() end); return n
        end)
    return y
end

local function BuildResourceText(c,y,db)
    y=Header(c,y,T("rcs_sec_text","Text & font"),"T")
    y=Bool(c,T("opt_rb_show_text","Show text"),db.showText~=false,y,function(v) db.showText=v; ApplyRB() end)
    y=Dropdown(c,T("opt_rb_text_align","Text alignment"),{
        {text=T("align_left","Left"),value="LEFT"},
        {text=T("align_center","Center"),value="CENTER"},
        {text=T("align_right","Right"),value="RIGHT"},
    },db.textAlignment or "CENTER",y,function(v) db.textAlignment=v; ApplyRB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_rb_font_size","Font size"),db.fontSize or 11,7,20,1,0,function(v) db.fontSize=v; ApplyRB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("opt_rb_font","Font"),FONT_LIST,db.font or FONT_LIST[1].value,0,function(v) db.font=v; ApplyRB() end); return n
        end)
    return y
end

local RESOURCE_COLORS={
    {"comboPoints","res_combo_points"},{"chargedComboPoints","res_charged_combo_points"},
    {"holyPower","res_holy_power"},{"soulShards","res_soul_shards"},
    {"chi","res_chi"},{"essence","res_essence"},{"arcaneCharges","res_arcane_charges"},
    {"runes","res_runes_cd"},{"runesReady","res_runes_ready"},{"stagger","res_stagger"},
    {"mana","res_mana"},{"soulFragments","res_soul_fragments"},
    {"tipOfTheSpear","res_tip_of_spear"},{"maelstromWeapon","res_maelstrom_weapon"},
}
local function BuildResourceColors(c,y,db)
    db.colors=db.colors or {}
    y=Header(c,y,T("rcs_sec_colors","Resource colors"),"C")
    y=Info(c,T("info_rb_colors_custom",""),y)
    local i=1
    while i<=#RESOURCE_COLORS do
        local a=RESOURCE_COLORS[i]
        local b=RESOURCE_COLORS[i+1]
        if a and b and db.colors[a[1]] and db.colors[b[1]] then
            local ka,kb=a[1],b[1]
            y=Pair(c,y,
                function(col)
                    local _,n=W.CreateColorPicker(col,T(a[2],ka),db.colors[ka],0,function(r,g,bv) db.colors[ka]={r=r,g=g,b=bv}; ApplyRB() end); return n
                end,
                function(col)
                    local _,n=W.CreateColorPicker(col,T(b[2],kb),db.colors[kb],0,function(r,g,bv) db.colors[kb]={r=r,g=g,b=bv}; ApplyRB() end); return n
                end)
            i=i+2
        elseif a and db.colors[a[1]] then
            local ka=a[1]
            y=Color(c,T(a[2],ka),db.colors[ka],y,function(r,g,bv) db.colors[ka]={r=r,g=g,b=bv}; ApplyRB() end)
            i=i+1
        else
            i=i+1
        end
    end
    return y
end

local function BuildResourcePosition(c,y,db)
    y=Header(c,y,T("rcs_sec_position","Position"),"M")
    db.position=db.position or {point="BOTTOM",relativePoint="CENTER",x=0,y=-230}
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_rb_pos_x","Position X"),db.position.x or 0,-960,960,1,0,function(v) db.position.x=v; ApplyRB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_rb_pos_y","Position Y"),db.position.y or -230,-540,540,1,0,function(v) db.position.y=v; ApplyRB() end,"%.0f"); return n
        end)
    y=Bool(c,T("opt_rb_sync_width","Sync width with cooldowns"),db.syncWidthWithCooldowns or false,y,function(v)
        db.syncWidthWithCooldowns=v
        if v and TomoMod_ResourceBars and TomoMod_ResourceBars.SyncWidth then TomoMod_ResourceBars.SyncWidth() end
        ApplyRB()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateButton(col,T("btn_sync_now","Sync now"),180,0,function()
                if TomoMod_ResourceBars and TomoMod_ResourceBars.SyncWidth then TomoMod_ResourceBars.SyncWidth() end
                ApplyRB()
            end); return n
        end,
        function(col)
            local _,n=W.CreateButton(col,T("btn_toggle_lock","Toggle lock"),180,0,function()
                if TomoMod_ResourceBars and TomoMod_ResourceBars.ToggleLock then TomoMod_ResourceBars.ToggleLock() end
            end); return n
        end)
    y=Info(c,T("info_rb_position",""),y)
    return y
end

local RESOURCE_BUILDERS={
    general=BuildResourceGeneral,visibility=BuildResourceVisibility,layout=BuildResourceLayout,
    health=BuildResourceHealth,power=BuildResourcePower,class=BuildResourceClass,
    text=BuildResourceText,colors=BuildResourceColors,position=BuildResourcePosition,
}

-- =====================================================================
-- Player cast sections
-- =====================================================================

local function BuildCastGeneral(c,y,db)
    y=Header(c,y,T("rcs_sec_cast_general","General cast settings"),"C")
    y=Info(c,T("rcs_cast_shared_info",""),y)
    y=Bool(c,T("opt_cb_enable","Enable Castbars"),db.enabled~=false,y,function(v)
        db.enabled=v
        if TomoMod_Castbar and TomoMod_Castbar.SetEnabled then TomoMod_Castbar.SetEnabled(v) else ApplyCB() end
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_hide_blizzard","Hide Blizzard castbar"),db.hideBlizzardCastbar~=false,0,function(v) db.hideBlizzardCastbar=v; ApplyCB() end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_class_color","Use class color"),db.useClassColor~=false,0,function(v) db.useClassColor=v; ApplyCB() end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_show_transitions","Show transitions"),db.showTransitions~=false,0,function(v) db.showTransitions=v; ApplyCB() end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_show_channel_ticks","Show channel ticks"),db.showChannelTicks~=false,0,function(v) db.showChannelTicks=v; ApplyCB() end); return n
        end)
    y=Dropdown(c,T("opt_cb_timer_format","Timer format"),{
        {text=T("cb_timer_remaining","Remaining"),value="remaining"},
        {text=T("cb_timer_remaining_total","Remaining / total"),value="remaining_total"},
        {text=T("cb_timer_elapsed","Elapsed"),value="elapsed"},
    },db.timerFormat or "remaining",y,function(v) db.timerFormat=v; ApplyCB() end)
    y=Slider(c,T("opt_cb_spell_max_len","Maximum spell name length"),db.spellNameMaxLen or 0,0,40,1,y,function(v) db.spellNameMaxLen=v; ApplyCB() end,"%.0f")
    return y
end

local function BuildCastPlayer(c,y,db)
    local p=db.player
    y=Header(c,y,T("rcs_sec_cast_player","Player bar"),"P")
    y=Bool(c,T("opt_cb_unit_enable","Enable"),p.enabled~=false,y,function(v) p.enabled=v; ApplyCB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_unit_width","Width"),p.width or 260,100,500,5,0,function(v) p.width=v; ApplyCB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_unit_height","Height"),p.height or 22,8,40,1,0,function(v) p.height=v; ApplyCB() end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_unit_show_icon","Show icon"),p.showIcon~=false,0,function(v) p.showIcon=v; ApplyCB() end); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("opt_cb_unit_icon_side","Icon side"),{
                {text=T("cb_icon_left","Left"),value="LEFT"},
                {text=T("cb_icon_right","Right"),value="RIGHT"},
            },p.iconSide or "LEFT",0,function(v) p.iconSide=v; ApplyCB() end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_unit_show_timer","Show timer"),p.showTimer~=false,0,function(v) p.showTimer=v; ApplyCB() end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("opt_cb_unit_show_latency","Show latency"),p.showLatency~=false,0,function(v) p.showLatency=v; ApplyCB() end); return n
        end)
    y=Info(c,T("info_cb_latency",""),y)
    return y
end

local function BuildCastAppearance(c,y,db)
    y=Header(c,y,T("rcs_sec_cast_appearance","Appearance"),"A")
    y=Dropdown(c,T("opt_cb_bar_texture","Bar texture"),{
        {text=T("cb_tex_blizzard","Blizzard"),value="blizzard"},
        {text=T("cb_tex_smooth","Smooth"),value="smooth"},
        {text=T("cb_tex_flat","Flat"),value="flat"},
    },db.barTexture or "blizzard",y,function(v) db.barTexture=v; ApplyCB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_font_size","Font size"),db.fontSize or 12,8,24,1,0,function(v) db.fontSize=v; ApplyCB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("opt_cb_bg_mode","Background"),{
                {text=T("cb_bg_black","Black"),value="black"},
                {text=T("cb_bg_transparent","Transparent"),value="transparent"},
                {text=T("cb_bg_custom","Custom"),value="custom"},
            },db.backgroundMode or "black",0,function(v) db.backgroundMode=v; ApplyCB() end); return n
        end)
    return y
end

local function BuildCastColors(c,y,db)
    y=Header(c,y,T("rcs_sec_cast_colors","Colors"),"C")
    y=Color(c,T("opt_cb_cast_color","Cast color"),db.castbarColor or {r=1,g=.7,b=0},y,function(r,g,b) db.castbarColor={r=r,g=g,b=b}; ApplyCB() end)
    y=Color(c,T("opt_cb_ni_color","Non-interruptible color"),db.castbarNIColor or {r=.5,g=.5,b=.5},y,function(r,g,b) db.castbarNIColor={r=r,g=g,b=b}; ApplyCB() end)
    y=Color(c,T("opt_cb_interrupt_color","Interrupt color"),db.castbarInterruptColor or {r=.1,g=.8,b=.1},y,function(r,g,b) db.castbarInterruptColor={r=r,g=g,b=b}; ApplyCB() end)
    return y
end

local function BuildCastSpark(c,y,db)
    y=Header(c,y,T("rcs_sec_cast_spark","Spark"),"S")
    y=Bool(c,T("opt_cb_show_spark","Show spark"),db.showSpark~=false,y,function(v) db.showSpark=v; ApplyCB() end)
    y=Dropdown(c,T("opt_cb_spark_style","Spark style"),{
        {text="Comet",value="Comet"},{text="Pulse",value="Pulse"},{text="Helix",value="Helix"},{text="Glitch",value="Glitch"},
    },db.sparkStyle or "Comet",y,function(v) db.sparkStyle=v; ApplyCB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateColorPicker(col,T("opt_cb_spark_color","Spark color"),db.sparkColor or {r=1,g=1,b=1},0,function(r,g,b) db.sparkColor={r=r,g=g,b=b}; ApplyCB() end); return n
        end,
        function(col)
            local _,n=W.CreateColorPicker(col,T("opt_cb_spark_glow_color","Glow color"),db.sparkGlowColor or {r=1,g=.9,b=.5},0,function(r,g,b) db.sparkGlowColor={r=r,g=g,b=b}; ApplyCB() end); return n
        end)
    y=Color(c,T("opt_cb_spark_tail_color","Tail color"),db.sparkTailColor or {r=1,g=.8,b=.3},y,function(r,g,b) db.sparkTailColor={r=r,g=g,b=b}; ApplyCB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_spark_glow_alpha","Glow alpha"),db.sparkGlowAlpha or .7,0,1,.05,0,function(v) db.sparkGlowAlpha=v; ApplyCB() end,"%.2f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_spark_tail_alpha","Tail alpha"),db.sparkTailAlpha or .6,0,1,.05,0,function(v) db.sparkTailAlpha=v; ApplyCB() end,"%.2f"); return n
        end)
    return y
end

local function BuildCastGCD(c,y,db)
    y=Header(c,y,T("rcs_sec_cast_gcd","GCD"),"G")
    y=Bool(c,T("opt_cb_show_gcd","Show GCD"),db.showGCDSpark or false,y,function(v) db.showGCDSpark=v; ApplyCB() end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_gcd_height","GCD height"),db.gcdHeight or 4,2,12,1,0,function(v) db.gcdHeight=v; ApplyCB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateColorPicker(col,T("opt_cb_gcd_color","GCD color"),db.gcdColor or {r=1,g=1,b=1},0,function(r,g,b) db.gcdColor={r=r,g=g,b=b}; ApplyCB() end); return n
        end)
    return y
end

local function BuildCastInterrupt(c,y,db)
    y=Header(c,y,T("rcs_sec_cast_interrupt","Interrupt feedback"),"I")
    y=Bool(c,T("opt_cb_show_interrupt_feedback","Show interrupt feedback"),db.showInterruptFeedback~=false,y,function(v) db.showInterruptFeedback=v end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateColorPicker(col,T("opt_cb_interrupt_fb_color","Feedback color"),db.interruptFeedbackColor or {r=.1,g=.8,b=.1},0,function(r,g,b) db.interruptFeedbackColor={r=r,g=g,b=b} end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("opt_cb_interrupt_fb_size","Feedback font size"),db.interruptFeedbackFontSize or 28,14,48,1,0,function(v) db.interruptFeedbackFontSize=v end,"%.0f"); return n
        end)
    return y
end

local function BuildCastPosition(c,y,db)
    local p=db.player
    p.position=p.position or {point="CENTER",relativePoint="CENTER",x=0,y=-150}
    y=Header(c,y,T("rcs_sec_position","Position"),"M")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_cast_pos_x","Position X"),p.position.x or 0,-960,960,1,0,function(v) p.position.x=v; ApplyCB() end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rcs_cast_pos_y","Position Y"),p.position.y or -150,-540,540,1,0,function(v) p.position.y=v; ApplyCB() end,"%.0f"); return n
        end)
    y=Info(c,T("info_cb_position",""),y)
    return y
end

local CAST_BUILDERS={
    general=BuildCastGeneral,player=BuildCastPlayer,appearance=BuildCastAppearance,
    colors=BuildCastColors,spark=BuildCastSpark,gcd=BuildCastGCD,
    interrupt=BuildCastInterrupt,position=BuildCastPosition,
}

-- =====================================================================
-- Reset
-- =====================================================================

local CAST_GLOBAL_KEYS={
    "enabled","hideBlizzardCastbar","barTexture","barTextureLSM","font","fontLSM","fontSize",
    "backgroundMode","customBackgroundPath","useCustomBorder","customBorderPath",
    "showSpark","sparkStyle","customSparkPath","sparkColor","sparkGlowColor","sparkTailColor",
    "sparkGlowAlpha","sparkTailAlpha","castbarColor","castbarNIColor","castbarInterruptColor",
    "useClassColor","timerFormat","spellNameMaxLen","showTransitions","showChannelTicks",
    "showGCDSpark","gcdHeight","gcdColor","showInterruptFeedback","interruptFeedbackColor",
    "interruptFeedbackFontSize",
}

local function ResetResourcePosition()
    local def=TomoMod_Defaults and TomoMod_Defaults.resourceBars
    if def and def.position then RBDB().position=DeepCopy(def.position); ApplyRB() end
end
local function ResetResourceAll()
    local def=TomoMod_Defaults and TomoMod_Defaults.resourceBars
    if def then TomoModDB.resourceBars=DeepCopy(def); ApplyRB(); ApplyPrimaryCentered() end
end
local function ResetCastPosition()
    local def=TomoMod_Defaults and TomoMod_Defaults.castbars and TomoMod_Defaults.castbars.player
    if def and def.position then CastDB().player.position=DeepCopy(def.position); ApplyCB() end
end
local function ResetCastPlayer()
    local def=TomoMod_Defaults and TomoMod_Defaults.castbars and TomoMod_Defaults.castbars.player
    if def then CastDB().player=DeepCopy(def); ApplyCB() end
end
local function ResetCastVisual()
    local def=TomoMod_Defaults and TomoMod_Defaults.castbars
    local db=CastDB()
    if not def then return end
    for _,k in ipairs(CAST_GLOBAL_KEYS) do
        if def[k]~=nil then db[k]=DeepCopy(def[k]) end
    end
    ApplyCB()
end
local function ResetDone()
    print("|cff2e9dd8TomoMod|r "..T("rcs_reset_done","Reset applied."))
    S.RebuildInspector()
end
local function BuildReset(c,y)
    -- Reset actions use a strict grid instead of fixed-width buttons.
    -- CreateTwoColumnRow already gives us equal columns; stretch each button
    -- across its column so every left/right edge lines up regardless of locale.
    local function GridButton(col, text, callback)
        local btn, n = W.CreateButton(col, text, 230, 0, callback)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", col, "TOPLEFT", 0, 0)
        btn:SetPoint("TOPRIGHT", col, "TOPRIGHT", 0, 0)
        return n
    end

    local function FullButton(parent, text, yOffset, callback)
        local btn, n = W.CreateButton(parent, text, 300, yOffset, callback)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, yOffset)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, yOffset)
        return n
    end

    y=Header(c,y,T("rcs_tab_reset","Reset"),"R")
    y=Info(c,T("rcs_reset_intro",""),y)

    y=Header(c,y,T("rcs_tab_resources","Resources"),"R")
    y=Pair(c,y,
        function(col)
            return GridButton(col,T("rcs_reset_rb_pos","Reset ResourceBars position"),function()
                if CanEdit() then ResetResourcePosition(); ResetDone() end
            end)
        end,
        function(col)
            return GridButton(col,T("rcs_reset_rb_all","Reset all ResourceBars"),function()
                if CanEdit() then ResetResourceAll(); ResetDone() end
            end)
        end)

    y=Header(c,y,T("rcs_tab_cast","Player Cast"),"C")
    y=Pair(c,y,
        function(col)
            return GridButton(col,T("rcs_reset_cast_pos","Reset Player cast position"),function()
                if CanEdit() then ResetCastPosition(); ResetDone() end
            end)
        end,
        function(col)
            return GridButton(col,T("rcs_reset_cast_player","Reset Player cast settings"),function()
                if CanEdit() then ResetCastPlayer(); ResetDone() end
            end)
        end)

    y=FullButton(c,T("rcs_reset_cast_visual","Reset shared cast appearance"),y,function()
        if CanEdit() then ResetCastVisual(); ResetDone() end
    end)

    y=Sep(c,y)

    y=FullButton(c,T("rcs_reset_all","Reset ResourceBars + Player cast"),y,function()
        if not CanEdit() then return end
        ResetResourceAll(); ResetCastPlayer(); ResetCastVisual(); ResetDone()
    end)
    return y
end

-- =====================================================================
-- Sidebar / inspector
-- =====================================================================

local function EnsureRow(i)
    local b=rows[i]
    if b then return b end
    b=CreateFrame("Button",nil,sidebarList,"BackdropTemplate")
    b:SetHeight(34)
    b:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    b.text=b:CreateFontString(nil,"OVERLAY")
    b.text:SetFont(FONT_BOLD,10,"")
    b.text:SetPoint("LEFT",12,0); b.text:SetPoint("RIGHT",-8,0); b.text:SetJustifyH("LEFT")
    b:SetScript("OnClick",function(self)
        if not self.sectionID then return end
        if S.view=="resources" then S.resourceSection=self.sectionID
        elseif S.view=="cast" then S.castSection=self.sectionID end
        S.RebuildSidebar(); S.RebuildInspector()
    end)
    rows[i]=b
    return b
end

function S.RebuildSidebar()
    for _,b in ipairs(rows) do b:Hide() end
    if S.view=="reset" then
        sideTitle:SetText(T("rcs_sidebar_resets","RESETS"))
        return
    end
    sideTitle:SetText(T("rcs_sidebar_settings","SETTINGS"))
    local defs=S.view=="cast" and CAST_SECTIONS or RESOURCE_SECTIONS
    local current=S.view=="cast" and S.castSection or S.resourceSection
    local y=-4
    for i,def in ipairs(defs) do
        local b=EnsureRow(i)
        local on=def.id==current
        b.sectionID=def.id
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",6,y); b:SetPoint("TOPRIGHT",-6,y)
        b:SetBackdropColor(BRAND[1],BRAND[2],BRAND[3],on and .19 or .025)
        b:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],on and .9 or .16)
        b.text:SetText(T(def.key,def.id))
        b.text:SetTextColor(on and 1 or .70,on and 1 or .73,on and 1 or .80,1)
        b:Show(); y=y-36
    end
end

local function NewScroll()
    if not inspectorHost._bin then inspectorHost._bin=CreateFrame("Frame",nil,inspectorHost); inspectorHost._bin:Hide() end
    if inspectorHost._scroll then
        inspectorHost._scroll:Hide(); inspectorHost._scroll:ClearAllPoints(); inspectorHost._scroll:SetParent(inspectorHost._bin)
    end
    local scroll=W.CreateScrollPanel(inspectorHost)
    inspectorHost._scroll=scroll
    return scroll,scroll.child
end

function S.RebuildInspector()
    local _,c=NewScroll()
    local y=-10
    if S.view=="resources" then
        local b=RESOURCE_BUILDERS[S.resourceSection]
        if b then y=b(c,y,RBDB()) end
    elseif S.view=="cast" then
        local b=CAST_BUILDERS[S.castSection]
        if b then y=b(c,y,CastDB()) end
    else
        y=BuildReset(c,y)
    end
    c:SetHeight(math.abs(y)+48)
end

-- =====================================================================
-- View chrome
-- =====================================================================

local function UpdatePreviews()
    if resourcePreview then
        resourcePreview:SetShown(S.view=="resources")
        if S.view=="resources" then resourcePreview:Refresh(S.previewKind) end
    end
    if castPreview then
        castPreview:SetShown(S.view=="cast")
        if S.view=="cast" then castPreview:Refresh() end
    end
    stageHost:SetShown(S.view~="reset")
    refreshButton:SetShown(S.view~="reset")
    inspectorHost:ClearAllPoints()
    if S.view=="reset" then
        inspectorHost:SetPoint("TOPLEFT",navHost,"BOTTOMLEFT",0,-10)
    else
        inspectorHost:SetPoint("TOPLEFT",stageHost,"BOTTOMLEFT",0,-10)
    end
    inspectorHost:SetPoint("BOTTOMRIGHT",contentHost,"BOTTOMRIGHT",-12,10)
end

local function UpdateNav()
    for id,b in pairs(navButtons) do
        local on=id==S.view
        b:SetBackdropColor(on and BRAND[1] or .045,on and BRAND[2] or .05,on and BRAND[3] or .065,on and .20 or 1)
        b:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],on and 1 or .25)
        b._label:SetTextColor(on and 1 or .60,on and 1 or .64,on and 1 or .72,1)
    end
    if footerHint then
        footerHint:SetText(T(S.view=="resources" and "rcs_hint_resources" or S.view=="cast" and "rcs_hint_cast" or "rcs_hint_reset",""))
    end
    UpdatePreviews()
end

local function SetView(view)
    if view~="resources" and view~="cast" and view~="reset" then return end
    S.view=view
    UpdateNav(); S.RebuildSidebar(); S.RebuildInspector()
end

local function NavButton(parent,id,text,x)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(170,30); b:SetPoint("LEFT",x,0)
    b:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    local fs=b:CreateFontString(nil,"OVERLAY")
    fs:SetFont(FONT_BOLD,11,""); fs:SetPoint("CENTER"); fs:SetText(text); b._label=fs
    b:SetScript("OnClick",function() SetView(id) end)
    navButtons[id]=b
end

-- =====================================================================
-- Tutorial
-- =====================================================================

local function StudioDB()
    TomoModDB.resourceCastStudio=TomoModDB.resourceCastStudio or {}
    return TomoModDB.resourceCastStudio
end

local STEPS={
    {view="resources",title="rcs_tutorial_1_title",body="rcs_tutorial_1_body",target=function() return frame end},
    {view="resources",title="rcs_tutorial_2_title",body="rcs_tutorial_2_body",target=function() return stageHost end},
    {view="resources",title="rcs_tutorial_3_title",body="rcs_tutorial_3_body",target=function() return inspectorHost end},
    {view="cast",title="rcs_tutorial_4_title",body="rcs_tutorial_4_body",target=function() return stageHost end},
    {view="reset",title="rcs_tutorial_5_title",body="rcs_tutorial_5_body",target=function() return inspectorHost end},
}

local function SmallButton(parent,w)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(w or 100,28)
    b:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    b:SetBackdropColor(.055,.065,.085,1); b:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.58)
    local f=b:CreateFontString(nil,"OVERLAY"); f:SetFont(FONT_BOLD,10,""); f:SetPoint("CENTER"); b._label=f
    return b
end

local function EnsureTutorial()
    if tutorialUI then return tutorialUI end
    local overlay=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    overlay:SetAllPoints(); overlay:SetFrameLevel(frame:GetFrameLevel()+100)
    overlay:SetBackdrop({bgFile=WHITE8}); overlay:SetBackdropColor(.008,.012,.02,.56); overlay:EnableMouse(true); overlay:Hide()
    local hi=CreateFrame("Frame",nil,overlay,"BackdropTemplate")
    hi:SetFrameLevel(overlay:GetFrameLevel()+2); hi:SetBackdrop({edgeFile=WHITE8,edgeSize=2}); hi:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],1)
    local card=CreateFrame("Frame",nil,overlay,"BackdropTemplate")
    card:SetSize(570,190); card:SetPoint("BOTTOM",0,56); card:SetFrameLevel(overlay:GetFrameLevel()+5)
    card:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1}); card:SetBackdropColor(.035,.04,.055,.985); card:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.88)
    local progress=card:CreateFontString(nil,"OVERLAY"); progress:SetFont(FONT_BOLD,9,""); progress:SetPoint("TOPLEFT",20,-16); progress:SetTextColor(BRAND[1],BRAND[2],BRAND[3],1)
    local title=card:CreateFontString(nil,"OVERLAY"); title:SetFont(FONT_BOLD,16,""); title:SetPoint("TOPLEFT",progress,"BOTTOMLEFT",0,-8); title:SetPoint("RIGHT",-20,0); title:SetJustifyH("LEFT")
    local body=card:CreateFontString(nil,"OVERLAY"); body:SetFont(FONT,11,""); body:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10); body:SetPoint("RIGHT",-20,0); body:SetWidth(530); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetWordWrap(true); body:SetTextColor(.72,.76,.84,1)
    local skip=SmallButton(card,92); skip:SetPoint("BOTTOMLEFT",20,16); skip._label:SetText(T("rcs_tutorial_skip","Skip"))
    local back=SmallButton(card,92); back:SetPoint("BOTTOMRIGHT",-218,16); back._label:SetText(T("rcs_tutorial_back","Back"))
    local nextB=SmallButton(card,112); nextB:SetPoint("BOTTOMRIGHT",-20,16)
    tutorialUI={overlay=overlay,highlight=hi,progress=progress,title=title,body=body,skip=skip,back=back,next=nextB,step=1}
    return tutorialUI
end

local function EndTutorial()
    tutorialUI.overlay:Hide()
    StudioDB().tutorialVersion=TUTORIAL_VERSION
    SetView(tutorialUI.restoreView or "resources")
end

local function ShowStep(i)
    local ui=EnsureTutorial(); local st=STEPS[i]; if not st then return end
    ui.step=i; SetView(st.view)
    ui.progress:SetText(string.format(T("rcs_tutorial_progress","Step %d / %d"),i,#STEPS))
    ui.title:SetText(T(st.title)); ui.body:SetText(T(st.body))
    ui.back:SetShown(i>1)
    ui.next._label:SetText(i==#STEPS and T("rcs_tutorial_finish","Finish") or T("rcs_tutorial_next","Next"))
    ui.highlight:ClearAllPoints()
    local target=st.target()
    ui.highlight:SetPoint("TOPLEFT",target,"TOPLEFT",-5,5); ui.highlight:SetPoint("BOTTOMRIGHT",target,"BOTTOMRIGHT",5,-5)
    ui.highlight:Show(); ui.overlay:Show()
end

function S.StartTutorial()
    local ui=EnsureTutorial(); ui.restoreView=S.view
    ui.skip:SetScript("OnClick",EndTutorial)
    ui.back:SetScript("OnClick",function() ShowStep(max(1,ui.step-1)) end)
    ui.next:SetScript("OnClick",function() if ui.step>=#STEPS then EndTutorial() else ShowStep(ui.step+1) end end)
    ShowStep(1)
end

-- =====================================================================
-- Window
-- =====================================================================

local function BuildWindow()
    local shell=Forge.Studio.CreateShell({
        name="TomoModResourceCastStudioFrame",
        title="|cff2e9dd8"..T("rcs_title","Resource & Cast Studio").."|r",
        width=1360,height=880,sideWidth=260,titleH=52,footerH=44,crudHeight=48,
        accent=BRAND,sidebarTitle=T("rcs_sidebar_settings","SETTINGS"),
        hint=T("rcs_hint_resources",""),
    })
    frame=shell.frame; sidebarList=shell.sidebarList; sideTitle=shell.sideTitle
    crudHost=shell.crudHost; contentHost=shell.contentHost; footerHint=shell.hint

    refreshButton=W.CreateButton(crudHost,T("rcs_refresh","Refresh preview"),210,-6,function()
        if S.view=="resources" and resourcePreview then
            if resourcePreview.SetPreviewKind then resourcePreview:SetPreviewKind(S.previewKind)
            else resourcePreview:Refresh(S.previewKind) end
        elseif S.view=="cast" and castPreview then
            castPreview:Refresh()
        end
    end)

    local help=CreateFrame("Button",nil,frame,"BackdropTemplate")
    help:SetSize(82,26); help:SetPoint("TOPRIGHT",-46,-10)
    help:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1}); help:SetBackdropColor(.055,.065,.085,1); help:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.48)
    local ht=help:CreateFontString(nil,"OVERLAY"); ht:SetFont(FONT_BOLD,10,""); ht:SetPoint("CENTER"); ht:SetText("? "..T("rcs_help","Help"))
    help:SetScript("OnClick",function() S.StartTutorial() end)

    navHost=CreateFrame("Frame",nil,contentHost,"BackdropTemplate")
    navHost:SetPoint("TOPLEFT",12,-10); navHost:SetPoint("TOPRIGHT",-12,-10); navHost:SetHeight(38)
    navHost:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1}); navHost:SetBackdropColor(.025,.03,.042,1); navHost:SetBackdropBorderColor(.10,.12,.16,1)
    NavButton(navHost,"resources",T("rcs_tab_resources","Resources"),8)
    NavButton(navHost,"cast",T("rcs_tab_cast","Player Cast"),186)
    NavButton(navHost,"reset",T("rcs_tab_reset","Reset"),364)

    stageHost=CreateFrame("Frame",nil,contentHost)
    stageHost:SetPoint("TOPLEFT",navHost,"BOTTOMLEFT",0,-8); stageHost:SetPoint("TOPRIGHT",navHost,"BOTTOMRIGHT",0,-8); stageHost:SetHeight(300)
    resourcePreview=Preview.CreateResource(stageHost)
    castPreview=Preview.CreateCast(stageHost); castPreview:Hide()

    inspectorHost=CreateFrame("Frame",nil,contentHost)
    inspectorHost:SetPoint("TOPLEFT",stageHost,"BOTTOMLEFT",0,-10); inspectorHost:SetPoint("BOTTOMRIGHT",contentHost,"BOTTOMRIGHT",-12,10)

    frame:SetScript("OnShow",function()
        UpdateNav(); S.RebuildSidebar(); S.RebuildInspector()
    end)
end

function S.Open(view)
    if InCombatLockdown() then
        print("|cff2e9dd8TomoMod|r : "..T("rcs_combat","Studio unavailable in combat."))
        return
    end
    TomoModDB.resourceCastStudio=TomoModDB.resourceCastStudio or {}
    S.previewKind=TomoModDB.resourceCastStudio.previewKind or S.previewKind or "auto"
    if view=="cast" or view=="reset" then S.view=view else S.view="resources" end
    if not frame then BuildWindow() end
    UpdateNav(); S.RebuildSidebar(); S.RebuildInspector()
    frame:Show(); frame:Raise()
    if (tonumber(StudioDB().tutorialVersion) or 0)<TUTORIAL_VERSION then
        C_Timer.After(.15,function() if frame and frame:IsShown() then S.StartTutorial() end end)
    end
end
