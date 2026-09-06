-- =====================================================================
-- Party & Raid Studio -- detached real-time preview
-- The preview reads TomoModDB directly; no secure unit button and no live
-- unit APIs are involved. This means the player can configure a full party
-- or a twenty-member raid while solo and outside an instance.
-- =====================================================================

TomoMod_GroupPreview = TomoMod_GroupPreview or {}
local GP = TomoMod_GroupPreview
local L = TomoMod_L

local WHITE8 = "Interface\\Buttons\\WHITE8x8"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local CLASS_COLORS = {
    {0.96,0.55,0.73}, {0.00,0.44,0.87}, {0.78,0.61,0.43}, {0.67,0.83,0.45}, {0.58,0.51,0.79},
    {0.90,0.90,0.90}, {0.77,0.12,0.23}, {0.41,0.80,0.94}, {1.00,0.49,0.04}, {0.00,1.00,0.59},
    {0.64,0.19,0.79}, {1.00,0.96,0.41}, {0.20,0.58,0.50},
}

local NAMES = {
    "Tomoyuki","Aelindra","Broxtar","Cynara","Draleth",
    "Elowen","Fyrath","Garissa","Helyon","Isolde",
    "Jaxren","Kelvara","Luneth","Mordak","Nyssara",
    "Orvyn","Pyrael","Quelith","Ryndra","Sylvar",
}

local HP = {100,86,61,44,92,76,55,98,68,34,88,73,47,95,59,82,39,90,66,52}
local ROLES = {
    "TANK","HEALER","DAMAGER","DAMAGER","DAMAGER",
    "TANK","HEALER","DAMAGER","DAMAGER","DAMAGER",
    "HEALER","DAMAGER","DAMAGER","DAMAGER","DAMAGER",
    "DAMAGER","HEALER","DAMAGER","DAMAGER","DAMAGER",
}

local function Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function SafeFont(fs, path, size, outline)
    if not fs then return end
    if not fs:SetFont(path or FONT, math.max(5, size or 10), outline or "OUTLINE") then
        fs:SetFont(STANDARD_TEXT_FONT, math.max(5, size or 10), outline or "OUTLINE")
    end
end

local function NewMember(parent)
    local m = {}
    m.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    m.frame:SetBackdrop({ bgFile=WHITE8, edgeFile=WHITE8, edgeSize=1 })
    m.frame:SetBackdropColor(0.025, 0.030, 0.040, 0.98)

    m.health = CreateFrame("StatusBar", nil, m.frame)
    m.health:SetStatusBarTexture(WHITE8)
    m.health:SetMinMaxValues(0, 100)
    m.healthBg = m.health:CreateTexture(nil, "BACKGROUND")
    m.healthBg:SetAllPoints()

    m.absorb = m.health:CreateTexture(nil, "OVERLAY")
    m.absorb:SetPoint("TOPRIGHT")
    m.absorb:SetPoint("BOTTOMRIGHT")
    m.absorb:SetColorTexture(0.72, 0.78, 1.00, 0.78)

    m.healPred = m.health:CreateTexture(nil, "OVERLAY")
    m.healPred:SetPoint("TOPRIGHT")
    m.healPred:SetPoint("BOTTOMRIGHT")
    m.healPred:SetColorTexture(0.15, 1.00, 0.34, 0.52)

    m.name = m.health:CreateFontString(nil, "OVERLAY")
    m.name:SetPoint("TOP", 0, -1)
    m.name:SetJustifyH("CENTER")
    m.name:SetWordWrap(false)

    m.healthText = m.health:CreateFontString(nil, "OVERLAY")
    m.healthText:SetPoint("BOTTOM", 0, 1)
    m.healthText:SetTextColor(1,1,1,0.82)

    m.power = CreateFrame("StatusBar", nil, m.frame)
    m.power:SetStatusBarTexture(WHITE8)
    m.power:SetMinMaxValues(0, 100)
    m.power:SetStatusBarColor(0.12,0.42,1.00,0.95)
    m.powerBg = m.power:CreateTexture(nil, "BACKGROUND")
    m.powerBg:SetAllPoints()
    m.powerBg:SetColorTexture(0.02,0.03,0.09,1)

    m.role = m.frame:CreateTexture(nil, "OVERLAY")
    m.role:SetPoint("TOPLEFT", 2, -2)

    m.leader = m.frame:CreateTexture(nil, "OVERLAY")
    m.leader:SetPoint("BOTTOMLEFT", m.frame, "TOPLEFT", 1, 1)
    m.leader:SetColorTexture(1.00,0.80,0.20,1)

    m.marker = m.frame:CreateTexture(nil, "OVERLAY")
    m.marker:SetPoint("BOTTOMRIGHT", m.frame, "TOPRIGHT", -1, 1)
    m.marker:SetColorTexture(0.95,0.20,0.22,1)

    m.dispel = CreateFrame("Frame", nil, m.frame, "BackdropTemplate")
    m.dispel:SetAllPoints()
    m.dispel:SetBackdrop({ edgeFile=WHITE8, edgeSize=2 })

    m.hots = {}
    for i=1,4 do
        local t = m.frame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.18 + i*0.08, 0.82, 0.26 + i*0.08, 0.95)
        m.hots[i] = t
    end

    m.debuffs = {}
    for i=1,3 do
        local t = m.frame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.75, 0.18 + i*0.08, 0.20, 0.96)
        m.debuffs[i] = t
    end

    m.defensives = {}
    for i=1,2 do
        local t = m.frame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(0.22, 0.58 + i*0.10, 0.96, 0.95)
        m.defensives[i] = t
    end

    m.cooldowns = {}
    for i=1,2 do
        local t = m.frame:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(i == 1 and 0.90 or 0.35, i == 1 and 0.55 or 0.85, 0.18, 0.95)
        m.cooldowns[i] = t
    end

    m.resurrect = m.frame:CreateTexture(nil, "OVERLAY")
    m.resurrect:SetPoint("CENTER")
    m.resurrect:SetColorTexture(0.96,0.86,0.30,0.90)

    return m
end

local function HealthColor(db, idx, hp)
    local mode = db.healthColor or "class"
    if mode == "green" then return 0.15,0.75,0.20 end
    if mode == "gradient" then
        local t = hp / 100
        return math.max(0,1-t*1.15), math.min(1,t*1.10), 0.05
    end
    local c = CLASS_COLORS[((idx-1)%#CLASS_COLORS)+1]
    return c[1],c[2],c[3]
end

local function HealthText(db, hp)
    local fmt = db.healthTextFormat or "percent"
    if fmt == "current" then return math.floor(hp * 0.82) .. "K" end
    if fmt == "current_percent" then return math.floor(hp * 0.82) .. "K  " .. hp .. "%" end
    if fmt == "deficit" then return hp < 100 and ("-" .. (100-hp) .. "%") or "" end
    return hp .. "%"
end

local function ApplyMember(m, idx, db, w, h, scale, isRaid)
    local hp = HP[idx] or 75
    local role = ROLES[idx] or "DAMAGER"
    local powerH = db.showPower and (db.powerHeight or (isRaid and 3 or 4)) or 0
    powerH = powerH * scale
    local healthH = math.max(4, h - powerH)

    m.frame:SetSize(w,h)
    local r,g,b = HealthColor(db, idx, hp)
    m.frame:SetBackdropBorderColor(r*0.35+0.08, g*0.35+0.08, b*0.35+0.08, 0.95)

    m.health:ClearAllPoints()
    m.health:SetPoint("TOPLEFT", 1, -1)
    m.health:SetPoint("TOPRIGHT", -1, -1)
    m.health:SetHeight(math.max(3, healthH-1))
    m.health:SetValue(hp)
    m.health:SetStatusBarColor(r,g,b,0.92)
    m.healthBg:SetColorTexture(r*0.12,g*0.12,b*0.12,1)

    local fontSize = math.max(5, math.floor((db.fontSize or 10) * scale + 0.5))
    SafeFont(m.name, db.font or FONT, fontSize, db.fontOutline)
    SafeFont(m.healthText, db.font or FONT, math.max(5,fontSize-2), db.fontOutline)

    local name = NAMES[idx] or ("P"..idx)
    local maxLen = tonumber(db.nameMaxLength) or 0
    if maxLen > 0 and #name > maxLen then name = name:sub(1,maxLen) end
    m.name:SetText(name)
    m.name:SetShown(db.showName ~= false)

    m.healthText:SetText(HealthText(db,hp))
    m.healthText:SetShown(db.showHealthText == true)

    local healer = role == "HEALER"
    m.power:ClearAllPoints()
    m.power:SetPoint("BOTTOMLEFT",1,1)
    m.power:SetPoint("BOTTOMRIGHT",-1,1)
    m.power:SetHeight(math.max(2,powerH-1))
    m.power:SetValue(46 + (idx*11)%48)
    m.power:SetShown(db.showPower == true and healer and powerH > 0)

    local roleSize = math.max(4, math.floor((db.roleIconSize or (isRaid and 10 or 14))*scale+0.5))
    m.role:SetSize(roleSize,roleSize)
    if role == "TANK" then m.role:SetColorTexture(0.20,0.55,1.00,0.95)
    elseif role == "HEALER" then m.role:SetColorTexture(0.20,0.88,0.28,0.95)
    else m.role:SetColorTexture(0.90,0.22,0.22,0.95) end
    m.role:SetShown(db.showRoleIcon == true)

    local leaderSize = math.max(4, math.floor((db.leaderIconSize or 14)*scale+0.5))
    m.leader:SetSize(leaderSize,leaderSize)
    m.leader:SetShown(not isRaid and db.showLeaderIcon ~= false and idx == 1)

    local markerSize = math.max(4, math.floor((isRaid and 10 or 14)*scale+0.5))
    m.marker:SetSize(markerSize,markerSize)
    m.marker:SetShown(db.showRaidMarker == true and (idx == 3 or idx == 8))

    local showAbsorb = db.showAbsorb == true and (idx % 5 == 0)
    m.absorb:SetWidth(math.max(2,w*0.10))
    m.absorb:SetShown(showAbsorb)

    local showHeal = db.showHealPrediction == true and (idx % 5 == 2)
    m.healPred:SetWidth(math.max(2,w*0.13))
    m.healPred:SetShown(showHeal)

    local dispel = db.showDispel == true and (idx == 3 or idx == 8 or idx == 13)
    if dispel then
        local dr,dg,dbb = idx == 3 and 0.2 or 0.65, idx == 8 and 0.78 or 0.24, idx == 13 and 0.82 or 1.0
        m.dispel:SetBackdropBorderColor(dr,dg,dbb,0.98)
        m.dispel:Show()
    else
        m.dispel:Hide()
    end

    local hotCount = db.showHoTs == true and math.min(#m.hots, tonumber(db.maxHoTs) or 3) or 0
    local hotSize = math.max(3, math.min(h*0.36, (tonumber(db.hotSize) or 12)*scale))
    for i,t in ipairs(m.hots) do
        t:SetSize(hotSize,hotSize)
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", m.frame, "BOTTOMLEFT", 2+(i-1)*(hotSize+2), 2)
        t:SetShown(i <= hotCount and (healer or idx % 4 == 0))
    end

    local debuffCount = isRaid and db.showDebuffs == true and math.min(#m.debuffs, tonumber(db.maxDebuffs) or 2) or 0
    local debuffSize = math.max(3, math.min(h*0.34, (tonumber(db.debuffSize) or 12)*scale))
    for i,t in ipairs(m.debuffs) do
        t:SetSize(debuffSize,debuffSize)
        t:ClearAllPoints()
        t:SetPoint("TOPRIGHT",m.frame,"TOPRIGHT",-2-(i-1)*(debuffSize+2),-2)
        t:SetShown(i <= debuffCount and idx % 6 == 0)
    end

    local defCount = db.showDefensives == true and math.min(#m.defensives, tonumber(db.maxDefensives) or 2) or 0
    local defSize = math.max(3, math.min(h*0.34, (tonumber(db.defensiveIconSize) or 14)*scale))
    for i,t in ipairs(m.defensives) do
        t:SetSize(defSize,defSize)
        t:ClearAllPoints()
        t:SetPoint("RIGHT",m.frame,"RIGHT",-2-(i-1)*(defSize+2),0)
        t:SetShown(i <= defCount and idx % 7 == 0)
    end

    for i,t in ipairs(m.cooldowns) do
        local show = (not isRaid) and ((i == 1 and db.showInterruptCD) or (i == 2 and db.showBrezCD))
        local cdSize = math.max(4, math.min(h*0.45, (tonumber(db.cdIconSize) or 16)*scale))
        t:SetSize(cdSize,cdSize)
        t:ClearAllPoints()
        if (db.cdLayout or "vertical") == "horizontal" then
            t:SetPoint("TOPLEFT",m.frame,"BOTTOMLEFT",(i-1)*(cdSize+2),-2)
        else
            t:SetPoint("TOPRIGHT",m.frame,"TOPRIGHT",-2,-2-(i-1)*(cdSize+2))
        end
        t:SetShown(show and idx == 2)
    end

    local rezSize = math.max(5, math.min(h*0.60, (tonumber(db.resurrectIconSize) or 22)*scale))
    m.resurrect:SetSize(rezSize,rezSize)
    m.resurrect:SetShown(db.showResurrectIndicator == true and idx == 4)

    if db.showRange and (idx == (isRaid and 20 or 5)) then
        m.frame:SetAlpha(tonumber(db.oorAlpha) or 0.40)
    else
        m.frame:SetAlpha(1)
    end
end

local function EffectiveRaidLayout(db)
    local width,height = db.width or 72, db.height or 36
    local ov = db.raidSizeOverrides
    if ov and ov.enabled and ov["25"] then
        width = ov["25"].width or width
        height = ov["25"].height or height
    end
    return width,height
end

local function LayoutParty(root, db)
    local availW = math.max(200,(root:GetWidth() or 800)-32)
    local availH = math.max(120,(root:GetHeight() or 250)-50)
    local width,height = db.width or 160, db.height or 40
    local spacing = db.spacing or 2
    local dir = db.growDirection or "DOWN"
    local horizontal = dir == "LEFT" or dir == "RIGHT"
    local logicalW = horizontal and (width*5+spacing*4) or width
    local logicalH = horizontal and height or (height*5+spacing*4)
    local scale = math.min(availW/math.max(1,logicalW), availH/math.max(1,logicalH), 2.3)
    scale = Clamp(scale,0.45,2.3)
    local w,h,sp = width*scale,height*scale,spacing*scale
    local totalW = horizontal and (w*5+sp*4) or w
    local totalH = horizontal and h or (h*5+sp*4)
    local startX,startY = -totalW*0.5,totalH*0.5

    for i=1,5 do
        local m=root.members[i]
        m.frame:ClearAllPoints()
        local x,y = startX,startY
        if dir=="DOWN" then y=startY-(i-1)*(h+sp)
        elseif dir=="UP" then y=-totalH*0.5+(i-1)*(h+sp)+h
        elseif dir=="RIGHT" then x=startX+(i-1)*(w+sp)
        elseif dir=="LEFT" then x=totalW*0.5-i*w-(i-1)*sp end
        m.frame:SetPoint("TOPLEFT",root,"CENTER",x,y)
        ApplyMember(m,i,db,w,h,scale,false)
        m.frame:Show()
    end
    for i=6,#root.members do root.members[i].frame:Hide() end
end

local function LayoutRaid(root, db)
    local availW = math.max(260,(root:GetWidth() or 800)-32)
    local availH = math.max(140,(root:GetHeight() or 250)-50)
    local width,height = EffectiveRaidLayout(db)
    local spacing = db.spacing or 2
    local groupSpacing = db.groupSpacing or 6
    local layout = db.layout or "grid"

    local logicalW,logicalH
    if layout=="list" then
        logicalW=width
        logicalH=height*20+spacing*19
    else
        logicalW=width*4+groupSpacing*3
        logicalH=height*5+spacing*4
    end
    local scale=math.min(availW/math.max(1,logicalW),availH/math.max(1,logicalH),1.8)
    scale=Clamp(scale,0.25,1.8)
    local w,h,sp,gsp=width*scale,height*scale,spacing*scale,groupSpacing*scale
    local totalW = layout=="list" and w or (w*4+gsp*3)
    local totalH = layout=="list" and (h*20+sp*19) or (h*5+sp*4)
    local startX,startY=-totalW*0.5,totalH*0.5

    for i=1,20 do
        local m=root.members[i]
        m.frame:ClearAllPoints()
        local x,y
        if layout=="list" then
            x=startX
            y=startY-(i-1)*(h+sp)
        else
            local g=math.floor((i-1)/5)
            local row=(i-1)%5
            x=startX+g*(w+gsp)
            y=startY-row*(h+sp)
        end
        m.frame:SetPoint("TOPLEFT",root,"CENTER",x,y)
        ApplyMember(m,i,db,w,h,scale,true)
        m.frame:Show()
    end
end

function GP.Create(parent, mode)
    local root=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    root:SetAllPoints(parent)
    root:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    root:SetBackdropColor(0.018,0.022,0.032,1)
    root:SetBackdropBorderColor(0.11,0.13,0.18,1)
    root.mode=mode=="raid" and "raid" or "party"
    root.members={}

    local title=root:CreateFontString(nil,"OVERLAY")
    SafeFont(title,FONT_BOLD,11,"")
    title:SetPoint("TOPLEFT",14,-12)
    title:SetTextColor(0.18,0.62,0.85,1)
    root.title=title

    local info=root:CreateFontString(nil,"OVERLAY")
    SafeFont(info,FONT,9,"")
    info:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-3)
    info:SetPoint("RIGHT",root,"RIGHT",-14,0)
    info:SetJustifyH("LEFT")
    info:SetTextColor(0.48,0.52,0.60,1)
    info:SetText(L["gs_preview_info"] or "")
    root.info=info

    for i=1,20 do root.members[i]=NewMember(root) end

    root:SetScript("OnSizeChanged",function(self)
        C_Timer.After(0,function()
            if self and self:IsShown() then GP.Refresh(self) end
        end)
    end)
    GP.Refresh(root)
    return root
end

function GP.SetMode(root,mode)
    if not root then return end
    root.mode=mode=="raid" and "raid" or "party"
    GP.Refresh(root)
end

function GP.Refresh(root)
    if not root then return end
    local mode=root.mode=="raid" and "raid" or "party"
    local db=TomoModDB and TomoModDB[mode=="raid" and "raidFrames" or "partyFrames"]
    if not db then return end
    root.title:SetText(mode=="raid" and (L["gs_preview_raid"] or "Raid preview") or (L["gs_preview_party"] or "Party preview"))
    if mode=="raid" then LayoutRaid(root,db) else LayoutParty(root,db) end
end
