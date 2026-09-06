-- =====================================================================
-- TomoMod Party & Raid Studio
-- Dedicated LoadOnDemand configuration surface for PartyFrames, RaidFrames
-- and the advanced healer indicator engine.
--
-- Runtime ownership remains in the always-loaded TomoMod modules. This addon
-- only edits the same TomoModDB tables used by TomoMod_Options, calls the
-- existing ApplySettings APIs and renders detached previews.
-- =====================================================================

local W = TomoMod_Widgets
if not W then
    TomoMod_GroupStudio = { loadError = "TomoMod_Widgets indisponible" }
    return
end

local Forge = TomoMod_Forge
if not (Forge and Forge.Studio) then
    TomoMod_GroupStudio = { loadError = "TomoMod_Forge incomplet" }
    return
end

local HI = TomoMod_HealerIndicators
if not HI then
    TomoMod_GroupStudio = { loadError = "HealerIndicators indisponible" }
    return
end

local GP = TomoMod_GroupPreview
if not GP then
    TomoMod_GroupStudio = { loadError = "GroupPreview indisponible" }
    return
end

local L = TomoMod_L
local BRAND = Forge.BRAND
local FONT = Forge.FONT
local FONT_BOLD = Forge.FONT_BOLD
local WHITE8 = "Interface\\Buttons\\WHITE8x8"

local floor, max, min = math.floor, math.max, math.min
local ipairs, pairs, type, tonumber = ipairs, pairs, type, tonumber

local S = {
    view = "party",
    partySection = "general",
    raidSection = "general",
    healerMode = "party",
    healerClass = nil,
    healerSelected = nil,
}
TomoMod_GroupStudio = S

local PANEL_W, PANEL_H = 1360, 880
local SIDE_W = 260
local TITLE_H = 52
local FOOTER_H = 44
local NAV_H = 38
local PREVIEW_H = 300
local TUTORIAL_VERSION = 1

local frame, sidebarList, sideTitle, crudHost, contentHost, footerHint
local navHost, stageHost, inspectorHost, refreshButton
local groupPreview, healerStage, healerCell, healerHealth, healerPower
local navButtons = {}
local sectionRows = {}
local spellRows = {}
local healerIcons = {}
local tutorialUI

-- =====================================================================
-- Shared helpers
-- =====================================================================

local function Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function Round(v)
    if v >= 0 then return floor(v + 0.5) end
    return -floor(-v + 0.5)
end

local function T(key, fallback)
    local v = L and L[key]
    if v and v ~= key then return v end
    return fallback or key
end

local function CanEdit()
    if InCombatLockdown() then
        print("|cff2e9dd8TomoMod|r : " .. T("gs_combat","Party & Raid Studio cannot be edited during combat."))
        return false
    end
    return true
end

local function RefreshResurrectTracker()
    C_Timer.After(0, function()
        local RT = TomoMod_ResurrectTracker
        if RT and RT.ApplySettings then RT.ApplySettings() end
    end)
end

local function RefreshGroupPreview()
    if groupPreview and groupPreview:IsShown() then GP.Refresh(groupPreview) end
end

local function ApplyParty()
    local PF = TomoMod_PartyFrames
    if PF and PF.ApplySettings then PF.ApplySettings() end
    RefreshGroupPreview()
end

local function ApplyRaid()
    local RF = TomoMod_RaidFrames
    if RF and RF.ApplySettings then RF.ApplySettings() end
    if TomoMod_RFPreview and TomoMod_RFPreview.Refresh then
        TomoMod_RFPreview.Refresh()
    end
    RefreshGroupPreview()
end

local function RequestReload(module)
    if TomoMod_Lifecycle and TomoMod_Lifecycle.RequestReload then
        TomoMod_Lifecycle.RequestReload(module)
    end
end

local function Separator(c, y)
    local _, ny = W.CreateSeparator(c, y)
    return ny
end

local function Header(c, y, text, icon)
    local _, ny = W.CreateSectionHeader(c, text, y, icon or "G")
    return ny
end

local function Pair(c, y, left, right)
    local _, ny = W.CreateTwoColumnRow(c, y, left, right)
    return ny
end

local function Bool(c, text, value, y, cb)
    local _, ny = W.CreateCheckbox(c, text, value, y, cb)
    return ny
end

local function Slider(c, text, value, lo, hi, step, y, cb, fmt)
    local _, ny = W.CreateSlider(c, text, value, lo, hi, step, y, cb, fmt)
    return ny
end

local function Dropdown(c, text, opts, value, y, cb)
    local _, ny = W.CreateDropdown(c, text, opts, value, y, cb)
    return ny
end

local function Info(c, text, y)
    local _, ny = W.CreateInfoText(c, text, y)
    return ny
end

local function Color(c, text, value, y, cb)
    local _, ny = W.CreateColorPicker(c, text, value, y, cb)
    return ny
end

-- =====================================================================
-- Party settings -- parity with TomoMod_Options PartyFrames
-- =====================================================================

local PARTY_SECTIONS = {
    { id="general",    key="pf_section_general",     fallback="General" },
    { id="dimensions", key="pf_section_dimensions",  fallback="Dimensions" },
    { id="display",    key="pf_section_display",     fallback="Display" },
    { id="health",     key="pf_section_health_extras", fallback="Health extras" },
    { id="range",      key="pf_section_range",       fallback="Range" },
    { id="dispel",     key="pf_section_dispel",      fallback="Dispel" },
    { id="hots",       key="pf_section_hots",        fallback="HoTs" },
    { id="defensives", key="pf_section_defensives",  fallback="Defensives" },
    { id="cooldowns",  key="pf_section_cooldowns",   fallback="Cooldowns" },
    { id="arena",      key="pf_section_arena",       fallback="Arena" },
}

local function BuildPartyGeneral(c, y, db)
    y = Header(c, y, T("pf_section_general","General"), "P")
    y = Bool(c, T("pf_opt_enable","Enable Party Frames"), db.enabled, y, function(v)
        if not CanEdit() then return end
        db.enabled = v
        if TomoMod_PartyFrames and TomoMod_PartyFrames.SetEnabled then
            TomoMod_PartyFrames.SetEnabled(v)
        end
        RequestReload("partyFrames")
        RefreshGroupPreview()
    end)
    y = Info(c, T("info_module_reload","Some structural changes require a reload."), y)
    y = Bool(c, T("pf_opt_hide_blizzard","Hide Blizzard Party Frames"), db.hideBlizzardFrames, y, function(v)
        if not CanEdit() then return end
        db.hideBlizzardFrames = v
        RequestReload("partyFrames")
    end)
    y = Bool(c, T("pf_opt_sort_role","Sort by role"), db.sortByRole, y, function(v)
        if not CanEdit() then return end
        db.sortByRole = v
        ApplyParty()
    end)
    return y
end

local function BuildPartyDimensions(c, y, db)
    y = Header(c, y, T("pf_section_dimensions","Dimensions"), "D")
    y = Pair(c, y,
        function(col)
            local _, n = W.CreateSlider(col, T("pf_opt_width","Width"), db.width, 100,300,5,0,function(v)
                if not CanEdit() then return end
                db.width=v; ApplyParty()
            end,"%.0f")
            return n
        end,
        function(col)
            local _, n = W.CreateSlider(col, T("pf_opt_height","Height"), db.height, 20,80,1,0,function(v)
                if not CanEdit() then return end
                db.height=v; ApplyParty()
            end,"%.0f")
            return n
        end)
    y = Pair(c, y,
        function(col)
            local _, n = W.CreateSlider(col, T("pf_opt_spacing","Spacing"), db.spacing,0,10,1,0,function(v)
                if not CanEdit() then return end
                db.spacing=v; ApplyParty()
            end,"%.0f")
            return n
        end,
        function(col)
            local opts = {
                {text=T("pf_dir_down","Down"),value="DOWN"},
                {text=T("pf_dir_up","Up"),value="UP"},
                {text=T("pf_dir_right","Right"),value="RIGHT"},
                {text=T("pf_dir_left","Left"),value="LEFT"},
            }
            local _, n = W.CreateDropdown(col,T("pf_opt_grow_direction","Growth direction"),opts,db.growDirection or "DOWN",0,function(v)
                if not CanEdit() then return end
                db.growDirection=v; ApplyParty()
            end)
            return n
        end)
    return y
end

local function BuildPartyDisplay(c, y, db)
    y = Header(c, y, T("pf_section_display","Display"), "V")
    y = Pair(c, y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_name","Show name"),db.showName,0,function(v)
                db.showName=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_health_text","Show health text"),db.showHealthText,0,function(v)
                db.showHealthText=v; ApplyParty()
            end); return n
        end)
    y = Pair(c, y,
        function(col)
            local opts={
                {text=T("fmt_percent","Percent"),value="percent"},
                {text=T("fmt_current","Current"),value="current"},
                {text=T("fmt_current_percent","Current + percent"),value="current_percent"},
                {text=T("pf_fmt_deficit","Deficit"),value="deficit"},
            }
            local _,n=W.CreateDropdown(col,T("pf_opt_health_format","Health format"),opts,db.healthTextFormat or "percent",0,function(v)
                db.healthTextFormat=v; ApplyParty()
            end); return n
        end,
        function(col)
            local opts={
                {text=T("opt_class_color","Class"),value="class"},
                {text=T("pf_color_green","Green"),value="green"},
                {text=T("pf_color_gradient","Gradient"),value="gradient"},
            }
            local _,n=W.CreateDropdown(col,T("pf_opt_health_color","Health color"),opts,db.healthColor or "class",0,function(v)
                db.healthColor=v; ApplyParty()
            end); return n
        end)
    y = Pair(c, y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_power","Show healer power"),db.showPower,0,function(v)
                db.showPower=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_power_height","Power height"),db.powerHeight,1,10,1,0,function(v)
                db.powerHeight=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y = Pair(c, y,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_name_max_length","Max name length"),db.nameMaxLength or 0,0,20,1,0,function(v)
                db.nameMaxLength=v; ApplyParty()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_font_size","Font size"),db.fontSize,8,18,1,0,function(v)
                db.fontSize=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y = Separator(c,y)
    y = Pair(c, y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_role","Show role icon"),db.showRoleIcon,0,function(v)
                db.showRoleIcon=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_role_size","Role icon size"),db.roleIconSize,8,24,1,0,function(v)
                db.roleIconSize=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y = Pair(c, y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_leader","Show leader"),db.showLeaderIcon ~= false,0,function(v)
                db.showLeaderIcon=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_leader_size","Leader icon size"),db.leaderIconSize or 14,8,24,1,0,function(v)
                db.leaderIconSize=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y = Pair(c, y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_marker","Show raid marker"),db.showRaidMarker,0,function(v)
                db.showRaidMarker=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_readycheck_size","Ready check size"),db.readyCheckSize or 24,12,40,1,0,function(v)
                db.readyCheckSize=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y = Slider(c,T("pf_opt_summon_size","Summon icon size"),db.summonSize or 18,10,36,1,y,function(v)
        db.summonSize=v; ApplyParty()
    end,"%.0f")
    return y
end

local function BuildPartyHealth(c,y,db)
    y=Header(c,y,T("pf_section_health_extras","Health extras"),"H")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_absorb","Show absorbs"),db.showAbsorb,0,function(v)
                db.showAbsorb=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_heal_pred","Heal prediction"),db.showHealPrediction,0,function(v)
                db.showHealPrediction=v; ApplyParty()
            end); return n
        end)
    y=Color(c,T("pf_opt_absorb_color","Absorb color"),db.absorbColor or {r=.5,g=.5,b=1},y,function(r,g,b)
        db.absorbColor={r=r,g=g,b=b,a=.5}; ApplyParty()
    end)
    return y
end

local function BuildPartyRange(c,y,db)
    y=Header(c,y,T("pf_section_range","Range"),"R")
    y=Bool(c,T("pf_opt_show_range","Range fading"),db.showRange,y,function(v)
        db.showRange=v; ApplyParty()
    end)
    y=Slider(c,T("pf_opt_oor_alpha","Out-of-range alpha"),db.oorAlpha,.10,.80,.05,y,function(v)
        db.oorAlpha=v; ApplyParty()
    end,"%.2f")
    return y
end

local function BuildPartyDispel(c,y,db)
    y=Header(c,y,T("pf_section_dispel","Dispel"),"D")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_dispel","Show dispel alerts"),db.showDispel,0,function(v)
                db.showDispel=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_dispel_border","Dispel border"),db.showDispelBorder ~= false,0,function(v)
                db.showDispelBorder=v; ApplyParty()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_dispel_icon","Dispel icon"),db.showDispelIcon ~= false,0,function(v)
                db.showDispelIcon=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_dispel_bleed","Include bleed"),db.showDispelBleed ~= false,0,function(v)
                db.showDispelBleed=v; ApplyParty()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_dispel_size","Dispel size"),db.dispelSize or 22,12,32,1,0,function(v)
                db.dispelSize=v; ApplyParty()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_dispel_border_size","Border size"),db.dispelBorderSize or 2,1,5,1,0,function(v)
                db.dispelBorderSize=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y=Info(c,T("pf_info_dispel","Dispel alerts highlight relevant debuff types."),y)
    return y
end

local function BuildPartyHoTs(c,y,db)
    y=Header(c,y,T("pf_section_hots","HoTs"),"H")
    y=Bool(c,T("pf_opt_show_hots","Show HoTs"),db.showHoTs,y,function(v)
        db.showHoTs=v; ApplyParty()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_hot_size","HoT size"),db.hotSize,8,50,1,0,function(v)
                db.hotSize=v; ApplyParty()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_max_hots","Maximum HoTs"),db.maxHoTs,1,6,1,0,function(v)
                db.maxHoTs=v; ApplyParty()
            end,"%.0f"); return n
        end)
    y=Bool(c,T("pf_opt_hot_duration","Show duration"),db.hotShowDuration ~= false,y,function(v)
        db.hotShowDuration=v; ApplyParty()
    end)
    y=Info(c,T("gs_healer_intro","Advanced healer placement is available in the Healer tab."),y)
    return y
end

local function BuildPartyDefensives(c,y,db)
    y=Header(c,y,T("pf_section_defensives","Defensives"),"S")
    y=Bool(c,T("pf_opt_show_defensives","Show defensives"),db.showDefensives,y,function(v)
        db.showDefensives=v; ApplyParty()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_defensive_size","Icon size"),db.defensiveIconSize or 16,10,24,1,0,function(v)
                db.defensiveIconSize=v; ApplyParty()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_max_defensives","Maximum defensives"),db.maxDefensives or 2,1,4,1,0,function(v)
                db.maxDefensives=v; RequestReload("partyFrames"); ApplyParty()
            end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_def_externals","Externals"),db.defensiveShowExternals ~= false,0,function(v)
                db.defensiveShowExternals=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_def_raidwide","Raid-wide"),db.defensiveShowRaidWide == true,0,function(v)
                db.defensiveShowRaidWide=v; ApplyParty()
            end); return n
        end)
    y=Bool(c,T("pf_opt_def_personals","Personals"),db.defensiveShowPersonals == true,y,function(v)
        db.defensiveShowPersonals=v; ApplyParty()
    end)
    return y
end

local function BuildPartyCooldowns(c,y,db)
    y=Header(c,y,T("pf_section_cooldowns","Cooldowns"),"C")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_kick","Show interrupt cooldown"),db.showInterruptCD,0,function(v)
                db.showInterruptCD=v; ApplyParty()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_brez","Show battle-rez cooldown"),db.showBrezCD,0,function(v)
                db.showBrezCD=v; ApplyParty()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_cd_size","Cooldown icon size"),db.cdIconSize,12,28,1,0,function(v)
                db.cdIconSize=v; ApplyParty()
            end,"%.0f"); return n
        end,
        function(col)
            local opts={
                {text=T("pf_cd_vertical","Vertical"),value="vertical"},
                {text=T("pf_cd_horizontal","Horizontal"),value="horizontal"},
            }
            local _,n=W.CreateDropdown(col,T("pf_opt_cd_layout","Cooldown layout"),opts,db.cdLayout or "vertical",0,function(v)
                db.cdLayout=v; ApplyParty()
            end); return n
        end)
    y=Separator(c,y)
    y=Bool(c,T("pf_opt_show_resurrect","Incoming resurrection"),db.showResurrectIndicator,y,function(v)
        db.showResurrectIndicator=v; RefreshResurrectTracker(); RefreshGroupPreview()
    end)
    y=Slider(c,T("pf_opt_resurrect_size","Resurrection icon size"),db.resurrectIconSize or 26,12,44,1,y,function(v)
        db.resurrectIconSize=v; RefreshResurrectTracker(); RefreshGroupPreview()
    end,"%.0f")
    return y
end

local function BuildPartyArena(c,y,db)
    db.arena = db.arena or {}
    local a=db.arena
    y=Header(c,y,T("pf_section_arena","Arena"),"A")
    y=Bool(c,T("pf_opt_arena_enable","Enable arena frames"),a.enabled,y,function(v)
        a.enabled=v; RequestReload("partyFrames")
    end)
    y=Info(c,T("pf_info_arena","Enemy arena frames for 2v2/3v3."),y)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_arena_width","Arena width"),a.width,100,300,5,0,function(v)
                a.width=v; RequestReload("partyFrames")
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_arena_height","Arena height"),a.height,20,80,1,0,function(v)
                a.height=v; RequestReload("partyFrames")
            end,"%.0f"); return n
        end)
    y=Slider(c,T("pf_opt_arena_spacing","Arena spacing"),a.spacing,0,10,1,y,function(v)
        a.spacing=v; RequestReload("partyFrames")
    end,"%.0f")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("pf_opt_show_trinket","Show PvP trinket cooldown"),a.showTrinketCD,0,function(v)
                a.showTrinketCD=v
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("pf_opt_trinket_size","Trinket size"),a.trinketSize,12,32,1,0,function(v)
                a.trinketSize=v
            end,"%.0f"); return n
        end)
    y=Bool(c,T("pf_opt_show_spec","Show specialization icon"),a.showSpecIcon,y,function(v)
        a.showSpecIcon=v
    end)
    y=Separator(c,y)
    local _,ny=W.CreateButton(c,T("pf_btn_reset_arena_pos","Reset arena position"),220,y,function()
        local def=TomoMod_Defaults and TomoMod_Defaults.partyFrames and TomoMod_Defaults.partyFrames.arena
        if def and def.position then
            a.position=CopyTable(def.position)
            RequestReload("partyFrames")
        end
    end)
    y=ny
    return y
end

local PARTY_BUILDERS = {
    general=BuildPartyGeneral, dimensions=BuildPartyDimensions, display=BuildPartyDisplay,
    health=BuildPartyHealth, range=BuildPartyRange, dispel=BuildPartyDispel,
    hots=BuildPartyHoTs, defensives=BuildPartyDefensives, cooldowns=BuildPartyCooldowns,
    arena=BuildPartyArena,
}

-- =====================================================================
-- Raid settings -- parity with TomoMod_Options RaidFrames
-- =====================================================================

local RAID_SECTIONS = {
    {id="general",    key="rf_section_general", fallback="General"},
    {id="layout",     key="rf_section_layout", fallback="Layout"},
    {id="display",    key="rf_section_display", fallback="Display"},
    {id="health",     key="rf_section_health_extras", fallback="Health extras"},
    {id="range",      key="rf_section_range", fallback="Range"},
    {id="dispel",     key="rf_section_dispel", fallback="Dispel"},
    {id="hots",       key="rf_section_hots", fallback="HoTs & debuffs"},
    {id="defensives", key="rf_section_defensives", fallback="Defensives"},
    {id="resurrect",  key="rf_section_resurrect", fallback="Resurrection"},
    {id="overrides",  key="rf_section_size_overrides", fallback="Raid-size overrides"},
}

local function BuildRaidGeneral(c,y,db)
    y=Header(c,y,T("rf_section_general","General"),"R")
    y=Bool(c,T("rf_opt_enable","Enable Raid Frames"),db.enabled,y,function(v)
        if not CanEdit() then return end
        db.enabled=v
        if TomoMod_RaidFrames and TomoMod_RaidFrames.SetEnabled then
            TomoMod_RaidFrames.SetEnabled(v)
        end
        RequestReload("raidFrames"); RefreshGroupPreview()
    end)
    y=Info(c,T("info_module_reload","Some structural changes require a reload."),y)
    y=Bool(c,T("rf_opt_hide_blizzard","Hide Blizzard Raid Frames"),db.hideBlizzardFrames,y,function(v)
        db.hideBlizzardFrames=v; RequestReload("raidFrames")
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_skin_group_manager","Skin group manager"),db.skinGroupManager,0,function(v)
                db.skinGroupManager=v
                if TomoMod_GroupManagerSkin and TomoMod_GroupManagerSkin.ApplySettings then
                    TomoMod_GroupManagerSkin.ApplySettings()
                end
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_sort_role","Sort by role"),db.sortByRole,0,function(v)
                db.sortByRole=v; ApplyRaid()
            end); return n
        end)
    return y
end

local function BuildRaidLayout(c,y,db)
    y=Header(c,y,T("rf_section_layout","Layout"),"L")
    local opts={
        {text=T("rf_layout_grid","Grid"),value="grid"},
        {text=T("rf_layout_list","List"),value="list"},
    }
    y=Dropdown(c,T("rf_opt_layout_mode","Layout mode"),opts,db.layout or "grid",y,function(v)
        db.layout=v; ApplyRaid()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_width","Width"),db.width,40,200,2,0,function(v)
                db.width=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_height","Height"),db.height,20,80,1,0,function(v)
                db.height=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_spacing","Spacing"),db.spacing,0,10,1,0,function(v)
                db.spacing=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_group_spacing","Group spacing"),db.groupSpacing,0,20,1,0,function(v)
                db.groupSpacing=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    return y
end

local function BuildRaidDisplay(c,y,db)
    y=Header(c,y,T("rf_section_display","Display"),"V")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_name","Show name"),db.showName,0,function(v)
                db.showName=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_name_max_length","Max name length"),db.nameMaxLength or 0,0,12,1,0,function(v)
                db.nameMaxLength=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_health_text","Show health text"),db.showHealthText,0,function(v)
                db.showHealthText=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local opts={
                {text=T("fmt_percent","Percent"),value="percent"},
                {text=T("fmt_current","Current"),value="current"},
                {text=T("pf_fmt_deficit","Deficit"),value="deficit"},
            }
            local _,n=W.CreateDropdown(col,T("rf_opt_health_format","Health format"),opts,db.healthTextFormat or "percent",0,function(v)
                db.healthTextFormat=v; ApplyRaid()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local opts={
                {text=T("opt_class_color","Class"),value="class"},
                {text=T("pf_color_green","Green"),value="green"},
                {text=T("pf_color_gradient","Gradient"),value="gradient"},
            }
            local _,n=W.CreateDropdown(col,T("rf_opt_health_color","Health color"),opts,db.healthColor or "class",0,function(v)
                db.healthColor=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_font_size","Font size"),db.fontSize,7,14,1,0,function(v)
                db.fontSize=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_role","Show role icon"),db.showRoleIcon,0,function(v)
                db.showRoleIcon=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_marker","Show raid marker"),db.showRaidMarker,0,function(v)
                db.showRaidMarker=v; ApplyRaid()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_readycheck_size","Ready check size"),db.readyCheckSize or 20,12,40,1,0,function(v)
                db.readyCheckSize=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_summon_size","Summon icon size"),db.summonSize or 18,10,36,1,0,function(v)
                db.summonSize=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    return y
end

local function BuildRaidHealth(c,y,db)
    y=Header(c,y,T("rf_section_health_extras","Health extras"),"H")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_power","Show healer power"),db.showPower,0,function(v)
                db.showPower=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_power_height","Power height"),db.powerHeight,1,8,1,0,function(v)
                db.powerHeight=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_absorb","Show absorbs"),db.showAbsorb,0,function(v)
                db.showAbsorb=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_heal_pred","Heal prediction"),db.showHealPrediction,0,function(v)
                db.showHealPrediction=v; ApplyRaid()
            end); return n
        end)
    return y
end

local function BuildRaidRange(c,y,db)
    y=Header(c,y,T("rf_section_range","Range"),"R")
    y=Bool(c,T("rf_opt_show_range","Range fading"),db.showRange,y,function(v)
        db.showRange=v; ApplyRaid()
    end)
    y=Slider(c,T("rf_opt_oor_alpha","Out-of-range alpha"),db.oorAlpha,.10,.80,.05,y,function(v)
        db.oorAlpha=v; ApplyRaid()
    end,"%.2f")
    return y
end

local function BuildRaidDispel(c,y,db)
    y=Header(c,y,T("rf_section_dispel","Dispel"),"D")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_dispel","Show dispel alerts"),db.showDispel,0,function(v)
                db.showDispel=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_dispel_border","Dispel border"),db.showDispelBorder ~= false,0,function(v)
                db.showDispelBorder=v; ApplyRaid()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_dispel_icon","Dispel icon"),db.showDispelIcon ~= false,0,function(v)
                db.showDispelIcon=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_show_dispel_bleed","Include bleed"),db.showDispelBleed ~= false,0,function(v)
                db.showDispelBleed=v; ApplyRaid()
            end); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_dispel_size","Dispel size"),db.dispelSize or 18,10,28,1,0,function(v)
                db.dispelSize=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_dispel_border_size","Border size"),db.dispelBorderSize or 2,1,5,1,0,function(v)
                db.dispelBorderSize=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    return y
end

local function BuildRaidHoTs(c,y,db)
    y=Header(c,y,T("rf_section_hots","HoTs"),"H")
    y=Bool(c,T("rf_opt_show_hots","Show HoTs"),db.showHoTs,y,function(v)
        db.showHoTs=v; ApplyRaid()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_hot_size","HoT size"),db.hotSize,6,50,1,0,function(v)
                db.hotSize=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_max_hots","Maximum HoTs"),db.maxHoTs,1,4,1,0,function(v)
                db.maxHoTs=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Bool(c,T("rf_opt_hot_duration","Show duration"),db.hotShowDuration ~= false,y,function(v)
        db.hotShowDuration=v; ApplyRaid()
    end)
    y=Separator(c,y)
    y=Header(c,y,T("rf_section_debuffs","Debuffs"),"D")
    y=Bool(c,T("rf_opt_show_debuffs","Show debuffs"),db.showDebuffs,y,function(v)
        db.showDebuffs=v; ApplyRaid()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_debuff_size","Debuff size"),db.debuffSize or 18,10,28,1,0,function(v)
                db.debuffSize=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_max_debuffs","Maximum debuffs"),db.maxDebuffs,1,5,1,0,function(v)
                db.maxDebuffs=v; ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Info(c,T("gs_healer_intro","Advanced healer placement is available in the Healer tab."),y)
    return y
end

local function BuildRaidDefensives(c,y,db)
    y=Header(c,y,T("rf_section_defensives","Defensives"),"S")
    y=Bool(c,T("rf_opt_show_defensives","Show defensives"),db.showDefensives,y,function(v)
        db.showDefensives=v; ApplyRaid()
    end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_defensive_size","Icon size"),db.defensiveIconSize,10,22,1,0,function(v)
                db.defensiveIconSize=v; ApplyRaid()
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("rf_opt_max_defensives","Maximum defensives"),db.maxDefensives or 2,1,4,1,0,function(v)
                db.maxDefensives=v; RequestReload("raidFrames"); ApplyRaid()
            end,"%.0f"); return n
        end)
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_def_externals","Externals"),db.defensiveShowExternals ~= false,0,function(v)
                db.defensiveShowExternals=v; ApplyRaid()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("rf_opt_def_raidwide","Raid-wide"),db.defensiveShowRaidWide == true,0,function(v)
                db.defensiveShowRaidWide=v; ApplyRaid()
            end); return n
        end)
    y=Bool(c,T("rf_opt_def_personals","Personals"),db.defensiveShowPersonals == true,y,function(v)
        db.defensiveShowPersonals=v; ApplyRaid()
    end)
    return y
end

local function BuildRaidResurrect(c,y,db)
    y=Header(c,y,T("rf_section_resurrect","Resurrection"),"R")
    y=Bool(c,T("rf_opt_show_resurrect","Incoming resurrection"),db.showResurrectIndicator,y,function(v)
        db.showResurrectIndicator=v; RefreshResurrectTracker(); RefreshGroupPreview()
    end)
    y=Slider(c,T("rf_opt_resurrect_size","Resurrection icon size"),db.resurrectIconSize or 22,12,40,1,y,function(v)
        db.resurrectIconSize=v; RefreshResurrectTracker(); RefreshGroupPreview()
    end,"%.0f")
    local br=TomoModDB and TomoModDB.battleRez
    if br then
        y=Separator(c,y)
        y=Header(c,y,T("rf_section_battlerez","Battle resurrection counter"),"B")
        y=Pair(c,y,
            function(col)
                local _,n=W.CreateCheckbox(col,T("rf_opt_br_enable","Enable battle-rez counter"),br.enabled,0,function(v)
                    br.enabled=v; RefreshResurrectTracker()
                end); return n
            end,
            function(col)
                local _,n=W.CreateCheckbox(col,T("rf_opt_br_only_instance","Instances only"),br.onlyInstance,0,function(v)
                    br.onlyInstance=v; RefreshResurrectTracker()
                end); return n
            end)
        y=Pair(c,y,
            function(col)
                local _,n=W.CreateSlider(col,T("rf_opt_br_size","Counter size"),br.size or 44,24,96,1,0,function(v)
                    br.size=v; RefreshResurrectTracker()
                end,"%.0f"); return n
            end,
            function(col)
                local _,n=W.CreateSlider(col,T("rf_opt_br_font","Font size"),br.fontSize or 18,10,32,1,0,function(v)
                    br.fontSize=v; RefreshResurrectTracker()
                end,"%.0f"); return n
            end)
    end
    return y
end

local function BuildRaidOverrides(c,y,db)
    y=Header(c,y,T("rf_section_size_overrides","Raid-size overrides"),"O")
    db.raidSizeOverrides=db.raidSizeOverrides or {enabled=false,["10"]={},["25"]={},["40"]={}}
    local ov=db.raidSizeOverrides
    ov["10"]=ov["10"] or {}; ov["25"]=ov["25"] or {}; ov["40"]=ov["40"] or {}
    y=Bool(c,T("rf_opt_overrides_enable","Enable size overrides"),ov.enabled,y,function(v)
        ov.enabled=v; ApplyRaid()
    end)
    y=Info(c,T("rf_info_size_overrides","Use different cell sizes for small, medium and large raids."),y)
    local sets={
        {"10","rf_ov_small","Small raid"},
        {"25","rf_ov_medium","Medium raid"},
        {"40","rf_ov_large","Large raid"},
    }
    for _,rec in ipairs(sets) do
        local key,labelKey,fallback=rec[1],rec[2],rec[3]
        y=Header(c,y,T(labelKey,fallback),"")
        y=Pair(c,y,
            function(col)
                local _,n=W.CreateSlider(col,T("rf_ov_width","Width"),ov[key].width or db.width,40,200,2,0,function(v)
                    ov[key].width=v; ApplyRaid()
                end,"%.0f"); return n
            end,
            function(col)
                local _,n=W.CreateSlider(col,T("rf_ov_height","Height"),ov[key].height or db.height,20,80,1,0,function(v)
                    ov[key].height=v; ApplyRaid()
                end,"%.0f"); return n
            end)
    end
    return y
end

local RAID_BUILDERS = {
    general=BuildRaidGeneral, layout=BuildRaidLayout, display=BuildRaidDisplay,
    health=BuildRaidHealth, range=BuildRaidRange, dispel=BuildRaidDispel,
    hots=BuildRaidHoTs, defensives=BuildRaidDefensives, resurrect=BuildRaidResurrect,
    overrides=BuildRaidOverrides,
}

-- =====================================================================
-- Healer editor -- integrates the existing HealerIndicators engine
-- =====================================================================

local function HealerClassName(token)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token
end

local function HealerModeDB()
    return HI.GetModeDB(S.healerMode)
end

local function HealerEntry()
    if not S.healerSelected then return nil end
    return HI.GetEntry(S.healerMode,S.healerClass,S.healerSelected)
end

local function HealerCellSize()
    local db=TomoModDB and TomoModDB[S.healerMode=="raid" and "raidFrames" or "partyFrames"] or {}
    if S.healerMode=="raid" then
        return tonumber(db.width) or 72, tonumber(db.height) or 36
    end
    return tonumber(db.width) or 160, tonumber(db.height) or 40
end

local function HealerScale()
    local w,h=HealerCellSize()
    return Clamp(min(650/max(w,1),220/max(h,1)),1.4,5.0)
end

local function ApplyHealerFont(fs,size)
    if not fs then return end
    if not fs:SetFont(FONT,max(6,size or 9),"OUTLINE") then
        fs:SetFont(STANDARD_TEXT_FONT,max(6,size or 9),"OUTLINE")
    end
end

local function HealerCommit()
    if HI.Commit then HI.Commit(S.healerMode) end
end

local function HealerTouch()
    if HI.Touch then HI.Touch(S.healerMode) end
end

local function AnchorCoords(f,point)
    local left,right,bottom,top=f:GetLeft(),f:GetRight(),f:GetBottom(),f:GetTop()
    if not left or not right or not bottom or not top then return nil,nil end
    local x
    if point:find("LEFT",1,true) then x=left
    elseif point:find("RIGHT",1,true) then x=right
    else x=(left+right)*.5 end
    local y
    if point:find("TOP",1,true) then y=top
    elseif point:find("BOTTOM",1,true) then y=bottom
    else y=(bottom+top)*.5 end
    return x,y
end

local function PickHealerAnchor(cx,cy)
    local pcx,pcy=healerCell:GetCenter()
    if not pcx or not pcy then return "CENTER" end
    local w,h=healerCell:GetWidth(),healerCell:GetHeight()
    local hor=""
    if cx < pcx-w/6 then hor="LEFT" elseif cx > pcx+w/6 then hor="RIGHT" end
    local ver=""
    if cy > pcy+h/6 then ver="TOP" elseif cy < pcy-h/6 then ver="BOTTOM" end
    local point=ver..hor
    return point~="" and point or "CENTER"
end

local function PlaceHealerIcon(icon,entry)
    if not icon or not entry or not healerCell then return end
    local scale=HealerScale()
    local size=Clamp(tonumber(entry.size) or 12,HI.MIN_SIZE,HI.MAX_SIZE)
    icon:SetSize(size*scale,size*scale)
    if icon.duration then
        ApplyHealerFont(icon.duration,9*scale)
        local mode=HealerModeDB()
        icon.duration:SetShown(not (mode and mode.showDuration==false))
    end
    local point=entry.point or "TOPLEFT"
    icon:ClearAllPoints()
    icon:SetPoint(point,healerCell,point,(tonumber(entry.x) or 0)*scale,(tonumber(entry.y) or 0)*scale)
end

local function SaveHealerDrag(icon,spellID)
    local entry=HI.GetEntry(S.healerMode,S.healerClass,spellID)
    if not entry or not healerCell then return end
    if not CanEdit() then PlaceHealerIcon(icon,entry); return end

    local pl,pr,pb,pt=healerCell:GetLeft(),healerCell:GetRight(),healerCell:GetBottom(),healerCell:GetTop()
    local cx,cy=icon:GetCenter()
    if not pl or not pr or not pb or not pt or not cx or not cy then
        PlaceHealerIcon(icon,entry); return
    end
    local hw,hh=icon:GetWidth()*.5,icon:GetHeight()*.5
    cx=Clamp(cx,pl+hw,pr-hw); cy=Clamp(cy,pb+hh,pt-hh)
    icon:ClearAllPoints(); icon:SetPoint("CENTER",UIParent,"BOTTOMLEFT",cx,cy)
    local point=PickHealerAnchor(cx,cy)
    local ix,iy=AnchorCoords(icon,point)
    local hx,hy=AnchorCoords(healerCell,point)
    local scale=HealerScale()
    if ix and hx then
        entry.point=point
        entry.x=Round((ix-hx)/scale)
        entry.y=Round((iy-hy)/scale)
    end
    PlaceHealerIcon(icon,entry)
    HealerTouch()
    S.RefreshHealer()
end

local function EnsureHealerIcon(spellID)
    local icon=healerIcons[spellID]
    if icon then return icon end
    icon=CreateFrame("Button",nil,healerCell,"BackdropTemplate")
    icon:SetMovable(true); icon:RegisterForDrag("LeftButton")
    icon:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    icon:SetBackdropColor(0,0,0,0)
    icon.texture=icon:CreateTexture(nil,"ARTWORK")
    icon.texture:SetPoint("TOPLEFT",1,-1); icon.texture:SetPoint("BOTTOMRIGHT",-1,1)
    icon.texture:SetTexCoord(.08,.92,.08,.92)
    icon.duration=icon:CreateFontString(nil,"OVERLAY")
    ApplyHealerFont(icon.duration,9)
    icon.duration:SetPoint("CENTER")
    icon.duration:SetText("12")
    icon.duration:SetTextColor(1,1,1,1)
    icon:SetScript("OnMouseDown",function()
        S.healerSelected=spellID; S.RefreshHealer()
    end)
    icon:SetScript("OnDragStart",function(self)
        if not CanEdit() then return end
        S.healerSelected=spellID; self:StartMoving()
    end)
    icon:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing(); SaveHealerDrag(self,spellID)
    end)
    healerIcons[spellID]=icon
    return icon
end

function S.RefreshHealerPreview()
    if not healerCell then return end
    local w,h=HealerCellSize()
    local scale=HealerScale()
    healerCell:SetSize(w*scale,h*scale)

    healerHealth:ClearAllPoints()
    healerHealth:SetPoint("TOPLEFT",healerCell,"TOPLEFT",2,-2)
    healerHealth:SetPoint("BOTTOMRIGHT",healerCell,"BOTTOMRIGHT",-2,max(6,h*scale*.16))
    healerPower:ClearAllPoints()
    healerPower:SetPoint("LEFT",healerCell,"BOTTOMLEFT",2,3)
    healerPower:SetPoint("RIGHT",healerCell,"BOTTOMRIGHT",-2,3)
    healerPower:SetHeight(Clamp(h*scale*.08,3,7))

    local classDB=HI.EnsureClass(S.healerMode,S.healerClass)
    local visible={}
    if classDB then
        for _,spellID in ipairs(HI.GetSpellsForClass(S.healerClass)) do
            local entry=classDB.spells[spellID]
            if entry and entry.enabled then
                local icon=EnsureHealerIcon(spellID)
                local _,tex=HI.GetSpellDisplay(spellID)
                icon.texture:SetTexture(tex)
                PlaceHealerIcon(icon,entry)
                if spellID==S.healerSelected then
                    icon:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],1)
                else
                    icon:SetBackdropBorderColor(0,0,0,.85)
                end
                icon:Show(); visible[spellID]=true
            end
        end
    end
    for id,icon in pairs(healerIcons) do if not visible[id] then icon:Hide() end end
end

-- =====================================================================
-- Sidebar
-- =====================================================================

local function EnsureSectionRow(index)
    local b=sectionRows[index]
    if b then return b end
    b=CreateFrame("Button",nil,sidebarList,"BackdropTemplate")
    b:SetHeight(34)
    b:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    b.text=b:CreateFontString(nil,"OVERLAY")
    b.text:SetFont(FONT_BOLD,10,"")
    b.text:SetPoint("LEFT",12,0); b.text:SetPoint("RIGHT",-8,0); b.text:SetJustifyH("LEFT")
    b:SetScript("OnClick",function(self)
        if not self.sectionID then return end
        if S.view=="party" then S.partySection=self.sectionID
        elseif S.view=="raid" then S.raidSection=self.sectionID end
        S.RebuildSidebar(); S.RebuildInspector()
    end)
    sectionRows[index]=b
    return b
end

local function EnsureSpellRow(index)
    local b=spellRows[index]
    if b then return b end
    b=CreateFrame("Button",nil,sidebarList,"BackdropTemplate")
    b:SetHeight(36); b:SetBackdrop({bgFile=WHITE8})
    b.check=CreateFrame("Button",nil,b,"BackdropTemplate")
    b.check:SetSize(16,16); b.check:SetPoint("LEFT",8,0)
    b.check:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    b.check:SetBackdropColor(.07,.08,.10,1)
    b.check.fill=b.check:CreateTexture(nil,"ARTWORK")
    b.check.fill:SetPoint("TOPLEFT",3,-3); b.check.fill:SetPoint("BOTTOMRIGHT",-3,3)
    b.check.fill:SetColorTexture(BRAND[1],BRAND[2],BRAND[3],1)
    b.icon=b:CreateTexture(nil,"ARTWORK")
    b.icon:SetSize(24,24); b.icon:SetPoint("LEFT",b.check,"RIGHT",8,0); b.icon:SetTexCoord(.08,.92,.08,.92)
    b.name=b:CreateFontString(nil,"OVERLAY")
    b.name:SetFont(FONT,10,""); b.name:SetPoint("TOPLEFT",b.icon,"TOPRIGHT",7,-1); b.name:SetPoint("RIGHT",-5,0)
    b.name:SetJustifyH("LEFT"); b.name:SetWordWrap(false)
    b.category=b:CreateFontString(nil,"OVERLAY")
    b.category:SetFont(FONT,8,""); b.category:SetPoint("BOTTOMLEFT",b.icon,"BOTTOMRIGHT",7,1)
    b.category:SetTextColor(.42,.44,.5,1)
    b:SetScript("OnClick",function(self)
        if not self.spellID then return end
        S.healerSelected=self.spellID; S.RefreshHealer()
    end)
    b.check:SetScript("OnClick",function(self)
        if not CanEdit() then return end
        local row=self:GetParent()
        local e=row.spellID and HI.GetEntry(S.healerMode,S.healerClass,row.spellID)
        if not e then return end
        e.enabled=not e.enabled
        S.healerSelected=row.spellID
        HealerCommit(); S.RefreshHealer()
    end)
    spellRows[index]=b
    return b
end

function S.RebuildSidebar()
    if not sidebarList then return end
    for _,b in ipairs(sectionRows) do b:Hide() end
    for _,b in ipairs(spellRows) do b:Hide() end

    if S.view=="healer" then
        sideTitle:SetText(T("gs_sidebar_spells","HEALER SPELLS"))
        local spells=HI.GetSpellsForClass(S.healerClass)
        local classDB=HI.EnsureClass(S.healerMode,S.healerClass)
        local y=-4
        for i,spellID in ipairs(spells) do
            local b=EnsureSpellRow(i)
            local entry=classDB and classDB.spells[spellID]
            local name,tex,cat=HI.GetSpellDisplay(spellID)
            b.spellID=spellID
            b:ClearAllPoints(); b:SetPoint("TOPLEFT",6,y); b:SetPoint("TOPRIGHT",-6,y)
            local sel=spellID==S.healerSelected
            b:SetBackdropColor(BRAND[1],BRAND[2],BRAND[3],sel and .22 or 0)
            b.icon:SetTexture(tex); b.name:SetText(name)
            b.name:SetTextColor(sel and 1 or .72,sel and 1 or .74,sel and 1 or .78,1)
            b.category:SetText(T("hs_cat_"..(cat or "hot"),cat or "hot"))
            b.check.fill:SetShown(entry and entry.enabled or false)
            b.check:SetBackdropBorderColor(
                entry and entry.enabled and BRAND[1] or .24,
                entry and entry.enabled and BRAND[2] or .26,
                entry and entry.enabled and BRAND[3] or .30,1)
            b:Show(); y=y-38
        end
        return
    end

    if S.view=="reset" then
        sideTitle:SetText(T("gs_sidebar_resets","RESETS"))
        return
    end

    sideTitle:SetText(T("gs_sidebar_settings","SETTINGS"))
    local sections=S.view=="raid" and RAID_SECTIONS or PARTY_SECTIONS
    local current=S.view=="raid" and S.raidSection or S.partySection
    local y=-4
    for i,sec in ipairs(sections) do
        local b=EnsureSectionRow(i)
        b.sectionID=sec.id
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",6,y); b:SetPoint("TOPRIGHT",-6,y)
        local selected=sec.id==current
        b:SetBackdropColor(BRAND[1],BRAND[2],BRAND[3],selected and .19 or .025)
        b:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],selected and .9 or .16)
        b.text:SetText(T(sec.key,sec.fallback))
        b.text:SetTextColor(selected and 1 or .70,selected and 1 or .73,selected and 1 or .80,1)
        b:Show(); y=y-36
    end
end

-- =====================================================================
-- Inspector builders
-- =====================================================================

local function NewInspectorScroll()
    if not inspectorHost._bin then
        inspectorHost._bin=CreateFrame("Frame",nil,inspectorHost); inspectorHost._bin:Hide()
    end
    if inspectorHost._scroll then
        inspectorHost._scroll:Hide()
        inspectorHost._scroll:ClearAllPoints()
        inspectorHost._scroll:SetParent(inspectorHost._bin)
    end
    local scroll=W.CreateScrollPanel(inspectorHost)
    inspectorHost._scroll=scroll
    return scroll,scroll.child
end

local function BuildHealerInspector(c,y)
    y=Header(c,y,T("gs_healer_intro","Healer indicators"),"H")
    local modeOpts={
        {text=T("gs_healer_party","Party"),value="party"},
        {text=T("gs_healer_raid","Raid"),value="raid"},
    }
    local classOpts={}
    for _,token in ipairs(HI.CLASS_ORDER) do
        classOpts[#classOpts+1]={text=HealerClassName(token),value=token}
    end

    y=Pair(c,y,
        function(col)
            local _,n=W.CreateDropdown(col,T("gs_healer_mode","Frame type"),modeOpts,S.healerMode,0,function(v)
                S.healerMode=(v=="raid") and "raid" or "party"
                S.healerSelected=nil
                S.RefreshHealer()
            end); return n
        end,
        function(col)
            local _,n=W.CreateDropdown(col,T("gs_healer_class","Healer class"),classOpts,S.healerClass,0,function(v)
                if not HI.IsHealerClass(v) then return end
                S.healerClass=v; S.healerSelected=nil; S.RefreshHealer()
            end); return n
        end)

    local root=HI.GetRootDB()
    local modeDB=HealerModeDB()
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateCheckbox(col,T("hs_enable","Enable advanced healer indicators"),modeDB and modeDB.enabled,0,function(v)
                if not CanEdit() then return end
                HI.SetModeEnabled(S.healerMode,v,S.healerClass); S.RefreshHealer()
            end); return n
        end,
        function(col)
            local _,n=W.CreateCheckbox(col,T("hs_healer_only","Healer specialization only"),root and root.onlyHealerSpec ~= false,0,function(v)
                if not CanEdit() then return end
                local r=HI.GetRootDB(); if r then r.onlyHealerSpec=v and true or false end
                if HI.Commit then HI.Commit() end
                S.RefreshHealer()
            end); return n
        end)
    y=Bool(c,T("hs_show_duration","Show remaining duration"),modeDB and modeDB.showDuration ~= false,y,function(v)
        if not CanEdit() then return end
        local m=HealerModeDB(); if m then m.showDuration=v and true or false end
        HealerTouch(); S.RefreshHealerPreview()
    end)

    y=Pair(c,y,
        function(col)
            local _,n=W.CreateButton(col,T("gs_healer_starter","Apply starter layout"),210,0,function()
                if not CanEdit() then return end
                HI.ApplyStarterPreset(S.healerMode,S.healerClass); HealerCommit(); S.RefreshHealer()
            end); return n
        end,
        function(col)
            local _,n=W.CreateButton(col,T("gs_healer_reset_class","Reset this class"),190,0,function()
                if not CanEdit() then return end
                HI.ResetClass(S.healerMode,S.healerClass,false); HealerCommit(); S.RefreshHealer()
            end); return n
        end)

    y=Separator(c,y)
    local entry=HealerEntry()
    if not entry then
        y=Info(c,T("hs_select","Select a healer spell on the left."),y)
        return y
    end

    local spellID=S.healerSelected
    local name=HI.GetSpellDisplay(spellID)
    y=Header(c,y,name,"+")
    y=Slider(c,T("hs_size","Indicator size"),entry.size or 12,HI.MIN_SIZE,HI.MAX_SIZE,1,y,function(v)
        if not CanEdit() then return end
        local e=HealerEntry(); if not e then return end
        e.size=Clamp(v,HI.MIN_SIZE,HI.MAX_SIZE); HealerTouch(); S.RefreshHealerPreview()
    end,"%.0f")
    local anchorOpts={}
    for _,p in ipairs(HI.ANCHOR_POINTS) do anchorOpts[#anchorOpts+1]={text=p,value=p} end
    y=Dropdown(c,T("hs_anchor","Anchor"),anchorOpts,entry.point or "TOPLEFT",y,function(v)
        local e=HealerEntry(); if not e then return end
        e.point=v; HealerTouch(); S.RefreshHealerPreview()
    end)
    local cw,ch=HealerCellSize()
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateSlider(col,T("hs_offset_x","Offset X"),entry.x or 0,-Round(cw),Round(cw),1,0,function(v)
                local e=HealerEntry(); if e then e.x=Round(v); HealerTouch(); S.RefreshHealerPreview() end
            end,"%.0f"); return n
        end,
        function(col)
            local _,n=W.CreateSlider(col,T("hs_offset_y","Offset Y"),entry.y or 0,-Round(ch),Round(ch),1,0,function(v)
                local e=HealerEntry(); if e then e.y=Round(v); HealerTouch(); S.RefreshHealerPreview() end
            end,"%.0f"); return n
        end)
    local _,ny=W.CreateButton(c,T("hs_reset_position","Reset spell position"),220,y,function()
        if not CanEdit() then return end
        HI.ResetSpellPosition(S.healerMode,S.healerClass,spellID); HealerCommit(); S.RefreshHealer()
    end)
    return ny
end

local function DeepCopy(v)
    if type(v)~="table" then return v end
    local out={}
    for k,x in pairs(v) do out[k]=DeepCopy(x) end
    return out
end

local function ResetPartyPosition()
    if not (TomoModDB and TomoMod_Defaults and TomoMod_Defaults.partyFrames) then return end
    TomoModDB.partyFrames.position=DeepCopy(TomoMod_Defaults.partyFrames.position)
    ApplyParty()
end

local function ResetPartyAll()
    if not (TomoModDB and TomoMod_Defaults and TomoMod_Defaults.partyFrames) then return end
    TomoModDB.partyFrames=DeepCopy(TomoMod_Defaults.partyFrames)
    ApplyParty(); RequestReload("partyFrames")
end

local function ResetRaidPosition()
    if not (TomoModDB and TomoMod_Defaults and TomoMod_Defaults.raidFrames) then return end
    TomoModDB.raidFrames.position=DeepCopy(TomoMod_Defaults.raidFrames.position)
    ApplyRaid()
end

local function ResetRaidAll()
    if not (TomoModDB and TomoMod_Defaults and TomoMod_Defaults.raidFrames) then return end
    TomoModDB.raidFrames=DeepCopy(TomoMod_Defaults.raidFrames)
    ApplyRaid(); RequestReload("raidFrames")
end

local function ResetHealerClass()
    HI.ResetClass(S.healerMode,S.healerClass,false)
    if HI.Commit then HI.Commit(S.healerMode) end
end

local function ResetHealerAll()
    if TomoMod_Defaults and TomoMod_Defaults.healerStudio then
        TomoModDB.healerStudio=DeepCopy(TomoMod_Defaults.healerStudio)
    else
        TomoModDB.healerStudio=nil
    end
    HI.Invalidate()
    HI.RefreshAll("party"); HI.RefreshAll("raid")
end

local function ResetDone()
    print("|cff2e9dd8TomoMod|r " .. T("gs_reset_done","Reset applied."))
    S.RebuildSidebar(); S.RebuildInspector()
    RefreshGroupPreview(); S.RefreshHealerPreview()
end

local function BuildResetInspector(c,y)
    y=Header(c,y,T("gs_tab_reset","Reset"),"R")
    y=Info(c,T("gs_reset_intro","Restore only what you need."),y)

    y=Header(c,y,T("gs_tab_party","Party"),"P")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateButton(col,T("gs_reset_party_pos","Reset Party position"),220,0,function()
                if not CanEdit() then return end
                ResetPartyPosition(); ResetDone()
            end); return n
        end,
        function(col)
            local _,n=W.CreateButton(col,T("gs_reset_party_all","Reset all Party settings"),230,0,function()
                if not CanEdit() then return end
                ResetPartyAll(); ResetDone()
            end); return n
        end)

    y=Header(c,y,T("gs_tab_raid","Raid"),"R")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateButton(col,T("gs_reset_raid_pos","Reset Raid position"),220,0,function()
                if not CanEdit() then return end
                ResetRaidPosition(); ResetDone()
            end); return n
        end,
        function(col)
            local _,n=W.CreateButton(col,T("gs_reset_raid_all","Reset all Raid settings"),230,0,function()
                if not CanEdit() then return end
                ResetRaidAll(); ResetDone()
            end); return n
        end)

    y=Header(c,y,T("gs_tab_healer","Healer"),"H")
    y=Pair(c,y,
        function(col)
            local _,n=W.CreateButton(col,T("gs_reset_healer_class","Reset current Healer class"),230,0,function()
                if not CanEdit() then return end
                ResetHealerClass(); ResetDone()
            end); return n
        end,
        function(col)
            local _,n=W.CreateButton(col,T("gs_reset_healer_all","Reset all Healer layouts"),230,0,function()
                if not CanEdit() then return end
                ResetHealerAll(); ResetDone()
            end); return n
        end)

    y=Separator(c,y)
    local _,ny=W.CreateButton(c,T("gs_reset_everything","Reset Party + Raid + Healer"),300,y,function()
        if not CanEdit() then return end
        ResetPartyAll(); ResetRaidAll(); ResetHealerAll(); ResetDone()
    end)
    return ny
end

function S.RebuildInspector()
    if not inspectorHost then return end
    local _,c=NewInspectorScroll()
    local y=-10
    if S.view=="party" then
        local db=TomoModDB and TomoModDB.partyFrames
        local b=PARTY_BUILDERS[S.partySection]
        if db and b then y=b(c,y,db) else y=Info(c,T("gs_party_unavailable","PartyFrames settings are unavailable."),y) end
    elseif S.view=="raid" then
        local db=TomoModDB and TomoModDB.raidFrames
        local b=RAID_BUILDERS[S.raidSection]
        if db and b then y=b(c,y,db) else y=Info(c,T("gs_raid_unavailable","RaidFrames settings are unavailable."),y) end
    elseif S.view=="healer" then
        y=BuildHealerInspector(c,y)
    else
        y=BuildResetInspector(c,y)
    end
    c:SetHeight(math.abs(y)+48)
end

function S.RefreshHealer()
    if not S.healerClass then
        local pc=HI.GetPlayerClass()
        S.healerClass=HI.IsHealerClass(pc) and pc or HI.CLASS_ORDER[1]
    end
    HI.EnsureClass(S.healerMode,S.healerClass)
    local spells=HI.GetSpellsForClass(S.healerClass)
    if S.healerSelected and not HI.GetEntry(S.healerMode,S.healerClass,S.healerSelected) then
        S.healerSelected=nil
    end
    if not S.healerSelected then S.healerSelected=spells[1] end
    S.RebuildSidebar(); S.RefreshHealerPreview(); S.RebuildInspector()
end

-- =====================================================================
-- Navigation / chrome
-- =====================================================================

local function UpdateViewLayout()
    if not stageHost or not inspectorHost then return end
    local showStage=S.view~="reset"
    stageHost:SetShown(showStage)
    inspectorHost:ClearAllPoints()
    if showStage then
        inspectorHost:SetPoint("TOPLEFT",stageHost,"BOTTOMLEFT",0,-10)
        inspectorHost:SetPoint("BOTTOMRIGHT",contentHost,"BOTTOMRIGHT",-12,10)
    else
        inspectorHost:SetPoint("TOPLEFT",navHost,"BOTTOMLEFT",0,-10)
        inspectorHost:SetPoint("BOTTOMRIGHT",contentHost,"BOTTOMRIGHT",-12,10)
    end

    if groupPreview then
        groupPreview:SetShown(S.view=="party" or S.view=="raid")
        if S.view=="party" or S.view=="raid" then
            GP.SetMode(groupPreview,S.view)
        end
    end
    if healerStage then healerStage:SetShown(S.view=="healer") end
    if refreshButton then refreshButton:SetShown(S.view~="reset") end

    if footerHint then
        local key=({
            party="gs_hint_party",raid="gs_hint_raid",healer="gs_hint_healer",reset="gs_hint_reset"
        })[S.view]
        footerHint:SetText(T(key,""))
    end
end

local function UpdateNavigation()
    for id,b in pairs(navButtons) do
        local on=id==S.view
        b:SetBackdropColor(on and BRAND[1] or .045,on and BRAND[2] or .05,on and BRAND[3] or .065,on and .20 or 1)
        b:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],on and 1 or .25)
        b._label:SetTextColor(on and 1 or .60,on and 1 or .64,on and 1 or .72,1)
    end
    UpdateViewLayout()
end

local function SetView(view)
    if view~="party" and view~="raid" and view~="healer" and view~="reset" then return end
    S.view=view
    UpdateNavigation()
    if view=="healer" then S.RefreshHealer()
    else
        S.RebuildSidebar(); S.RebuildInspector()
        if groupPreview and (view=="party" or view=="raid") then GP.Refresh(groupPreview) end
    end
end

local function CreateNavButton(parent,id,text,x)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(132,30); b:SetPoint("LEFT",x,0)
    b:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    local fs=b:CreateFontString(nil,"OVERLAY")
    fs:SetFont(FONT_BOLD,11,""); fs:SetPoint("CENTER"); fs:SetText(text)
    b._label=fs
    b:SetScript("OnEnter",function(self)
        if S.view~=id then
            self:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.75)
            fs:SetTextColor(.9,.94,1,1)
        end
    end)
    b:SetScript("OnLeave",UpdateNavigation)
    b:SetScript("OnClick",function() SetView(id) end)
    navButtons[id]=b
end

-- =====================================================================
-- Tutorial
-- =====================================================================

local function TutorialDB()
    TomoModDB.groupStudio=TomoModDB.groupStudio or {}
    return TomoModDB.groupStudio
end

local TUTORIAL_STEPS={
    {view="party", title="gs_tutorial_1_title",body="gs_tutorial_1_body",target=function() return frame end},
    {view="party", title="gs_tutorial_2_title",body="gs_tutorial_2_body",target=function() return stageHost end},
    {view="raid",  title="gs_tutorial_3_title",body="gs_tutorial_3_body",target=function() return stageHost end},
    {view="healer",title="gs_tutorial_4_title",body="gs_tutorial_4_body",target=function() return stageHost end},
    {view="reset", title="gs_tutorial_5_title",body="gs_tutorial_5_body",target=function() return inspectorHost end},
}

local function SmallButton(parent,width)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(width or 100,28)
    b:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    b:SetBackdropColor(.055,.065,.085,1)
    b:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.58)
    local fs=b:CreateFontString(nil,"OVERLAY")
    fs:SetFont(FONT_BOLD,10,""); fs:SetPoint("CENTER"); fs:SetTextColor(.92,.95,1,1)
    b._label=fs
    return b
end

local function EnsureTutorial()
    if tutorialUI or not frame then return tutorialUI end
    local overlay=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    overlay:SetAllPoints(); overlay:SetFrameLevel(frame:GetFrameLevel()+100)
    overlay:SetBackdrop({bgFile=WHITE8}); overlay:SetBackdropColor(.008,.012,.02,.56)
    overlay:EnableMouse(true); overlay:Hide()

    local hi=CreateFrame("Frame",nil,overlay,"BackdropTemplate")
    hi:SetFrameLevel(overlay:GetFrameLevel()+2)
    hi:SetBackdrop({edgeFile=WHITE8,edgeSize=2})
    hi:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],1)

    local card=CreateFrame("Frame",nil,overlay,"BackdropTemplate")
    card:SetSize(570,190); card:SetPoint("BOTTOM",0,56); card:SetFrameLevel(overlay:GetFrameLevel()+5)
    card:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    card:SetBackdropColor(.035,.04,.055,.985); card:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.88)

    local progress=card:CreateFontString(nil,"OVERLAY"); progress:SetFont(FONT_BOLD,9,"")
    progress:SetPoint("TOPLEFT",20,-16); progress:SetTextColor(BRAND[1],BRAND[2],BRAND[3],1)
    local title=card:CreateFontString(nil,"OVERLAY"); title:SetFont(FONT_BOLD,16,"")
    title:SetPoint("TOPLEFT",progress,"BOTTOMLEFT",0,-8); title:SetPoint("RIGHT",-20,0); title:SetJustifyH("LEFT")
    local body=card:CreateFontString(nil,"OVERLAY"); body:SetFont(FONT,11,"")
    body:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-10); body:SetPoint("RIGHT",-20,0); body:SetWidth(530)
    body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetWordWrap(true); body:SetTextColor(.72,.76,.84,1)

    local skip=SmallButton(card,92); skip:SetPoint("BOTTOMLEFT",20,16); skip._label:SetText(T("gs_tutorial_skip","Skip"))
    local back=SmallButton(card,92); back:SetPoint("BOTTOMRIGHT",-218,16); back._label:SetText(T("gs_tutorial_back","Back"))
    local nextB=SmallButton(card,112); nextB:SetPoint("BOTTOMRIGHT",-20,16)
    tutorialUI={overlay=overlay,highlight=hi,progress=progress,title=title,body=body,skip=skip,back=back,next=nextB,step=1}
    return tutorialUI
end

local function EndTutorial(done)
    local ui=tutorialUI; if not ui then return end
    ui.overlay:Hide()
    if done then TutorialDB().tutorialVersion=TUTORIAL_VERSION end
    SetView(ui.restoreView or "party")
end

local function ShowTutorialStep(index)
    local ui=EnsureTutorial(); local step=TUTORIAL_STEPS[index]
    if not ui or not step then return end
    ui.step=index; SetView(step.view)
    ui.progress:SetText(string.format(T("gs_tutorial_progress","Step %d / %d"),index,#TUTORIAL_STEPS))
    ui.title:SetText(T(step.title)); ui.body:SetText(T(step.body))
    ui.back:SetShown(index>1)
    ui.next._label:SetText(index==#TUTORIAL_STEPS and T("gs_tutorial_finish","Finish") or T("gs_tutorial_next","Next"))
    ui.highlight:ClearAllPoints()
    local target=step.target and step.target()
    if target then
        ui.highlight:SetPoint("TOPLEFT",target,"TOPLEFT",-5,5)
        ui.highlight:SetPoint("BOTTOMRIGHT",target,"BOTTOMRIGHT",5,-5)
        ui.highlight:Show()
    else ui.highlight:Hide() end
    ui.overlay:Show()
end

function S.StartTutorial()
    local ui=EnsureTutorial(); if not ui then return end
    ui.restoreView=S.view
    ui.skip:SetScript("OnClick",function() EndTutorial(true) end)
    ui.back:SetScript("OnClick",function() ShowTutorialStep(max(1,ui.step-1)) end)
    ui.next:SetScript("OnClick",function()
        if ui.step>=#TUTORIAL_STEPS then EndTutorial(true) else ShowTutorialStep(ui.step+1) end
    end)
    ShowTutorialStep(1)
end

-- =====================================================================
-- Window / public API
-- =====================================================================

local function BuildHealerStage(parent)
    healerStage=CreateFrame("Frame",nil,parent)
    healerStage:SetAllPoints(parent)
    healerCell=CreateFrame("Frame",nil,healerStage,"BackdropTemplate")
    healerCell:SetPoint("CENTER")
    healerCell:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    healerCell:SetBackdropColor(.08,.095,.105,1); healerCell:SetBackdropBorderColor(.42,.48,.52,1)

    healerHealth=healerCell:CreateTexture(nil,"BACKGROUND")
    healerHealth:SetColorTexture(.12,.40,.24,1)
    healerPower=healerCell:CreateTexture(nil,"BACKGROUND")
    healerPower:SetColorTexture(.12,.32,.55,1)

    local name=healerCell:CreateFontString(nil,"ARTWORK")
    name:SetFont(FONT,11,""); name:SetPoint("CENTER",0,2)
    name:SetText(UnitName("player") or "TomoAniki")
end

local function BuildWindow()
    local shell=Forge.Studio.CreateShell({
        name="TomoModGroupStudioFrame",
        title="|cff2e9dd8"..T("gs_title","Party & Raid Studio").."|r",
        width=PANEL_W,height=PANEL_H,sideWidth=SIDE_W,titleH=TITLE_H,footerH=FOOTER_H,
        crudHeight=48,accent=BRAND,sidebarTitle=T("gs_sidebar_settings","SETTINGS"),
        hint=T("gs_hint_party",""),
    })
    frame=shell.frame; sidebarList=shell.sidebarList; sideTitle=shell.sideTitle
    crudHost=shell.crudHost; contentHost=shell.contentHost; footerHint=shell.hint

    refreshButton=W.CreateButton(crudHost,T("gs_refresh","Refresh preview"),210,-6,function()
        if S.view=="healer" then S.RefreshHealer()
        elseif S.view=="party" or S.view=="raid" then RefreshGroupPreview() end
    end)

    local help=CreateFrame("Button",nil,frame,"BackdropTemplate")
    help:SetSize(82,26); help:SetPoint("TOPRIGHT",-46,-10)
    help:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    help:SetBackdropColor(.055,.065,.085,1); help:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.48)
    local ht=help:CreateFontString(nil,"OVERLAY"); ht:SetFont(FONT_BOLD,10,""); ht:SetPoint("CENTER")
    ht:SetText("? "..T("gs_help","Help")); ht:SetTextColor(.8,.86,.94,1)
    help:SetScript("OnEnter",function(self)
        self:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.95); ht:SetTextColor(1,1,1,1)
    end)
    help:SetScript("OnLeave",function(self)
        self:SetBackdropBorderColor(BRAND[1],BRAND[2],BRAND[3],.48); ht:SetTextColor(.8,.86,.94,1)
    end)
    help:SetScript("OnClick",function() S.StartTutorial() end)

    navHost=CreateFrame("Frame",nil,contentHost,"BackdropTemplate")
    navHost:SetPoint("TOPLEFT",12,-10); navHost:SetPoint("TOPRIGHT",-12,-10); navHost:SetHeight(NAV_H)
    navHost:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    navHost:SetBackdropColor(.025,.03,.042,1); navHost:SetBackdropBorderColor(.10,.12,.16,1)

    CreateNavButton(navHost,"party",T("gs_tab_party","Party"),8)
    CreateNavButton(navHost,"raid",T("gs_tab_raid","Raid"),148)
    CreateNavButton(navHost,"healer",T("gs_tab_healer","Healer"),288)
    CreateNavButton(navHost,"reset",T("gs_tab_reset","Reset"),428)

    stageHost=CreateFrame("Frame",nil,contentHost,"BackdropTemplate")
    stageHost:SetPoint("TOPLEFT",navHost,"BOTTOMLEFT",0,-8)
    stageHost:SetPoint("TOPRIGHT",navHost,"BOTTOMRIGHT",0,-8)
    stageHost:SetHeight(PREVIEW_H)
    stageHost:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    stageHost:SetBackdropColor(.018,.022,.032,1); stageHost:SetBackdropBorderColor(.10,.12,.16,1)

    groupPreview=GP.Create(stageHost,"party")
    BuildHealerStage(stageHost)
    healerStage:Hide()

    inspectorHost=CreateFrame("Frame",nil,contentHost)
    inspectorHost:SetPoint("TOPLEFT",stageHost,"BOTTOMLEFT",0,-10)
    inspectorHost:SetPoint("BOTTOMRIGHT",contentHost,"BOTTOMRIGHT",-12,10)

    frame:SetScript("OnShow",function()
        UpdateNavigation()
        if S.view=="healer" then S.RefreshHealer()
        else S.RebuildSidebar(); S.RebuildInspector(); RefreshGroupPreview() end
    end)
end

function S.Open(view)
    if InCombatLockdown() then
        print("|cff2e9dd8TomoMod|r : " .. T("hs_combat","Configuration unavailable in combat."))
        return
    end

    -- Compatibility entry points used by TomoMod_OpenHealerStudio(mode).
    -- This keeps the old TomoMod_Options buttons working while the dedicated
    -- TomoMod_HealerStudio addon is removed.
    if view == "healer_raid" then
        S.healerMode = "raid"
        view = "healer"
    elseif view == "healer_party" then
        S.healerMode = "party"
        view = "healer"
    end

    if not S.healerClass then
        local pc=HI.GetPlayerClass()
        S.healerClass=HI.IsHealerClass(pc) and pc or HI.CLASS_ORDER[1]
    end
    if view=="raid" or view=="healer" or view=="reset" then S.view=view else S.view="party" end
    if not frame then BuildWindow() end
    UpdateNavigation()
    if S.view=="healer" then S.RefreshHealer()
    else S.RebuildSidebar(); S.RebuildInspector(); RefreshGroupPreview() end
    frame:Show(); frame:Raise()

    local db=TutorialDB()
    if (tonumber(db.tutorialVersion) or 0) < TUTORIAL_VERSION then
        C_Timer.After(.15,function()
            if frame and frame:IsShown() then S.StartTutorial() end
        end)
    end
end
