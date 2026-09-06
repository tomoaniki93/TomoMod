-- =====================================================================
-- Resource & Cast Studio -- detached previews
-- =====================================================================

TomoMod_ResourceCastPreview = TomoMod_ResourceCastPreview or {}
local P = TomoMod_ResourceCastPreview
local L = TomoMod_L

local WHITE8 = "Interface\\Buttons\\WHITE8x8"
local TOMO_TEX = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\tomoaniki"
local FONT = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"

local CLASS_TEX_PATH = "Interface\\AddOns\\TomoMod\\Assets\\Textures\\ClassPower\\"

local ICON_PREVIEW = {
    combo = {
        texture = CLASS_TEX_PATH .. "combopoints",
        empty   = {0, 0.5, 0.5, 0},
        filled  = {0.5, 1, 0.5, 0},
    },
    shards = {
        texture = CLASS_TEX_PATH .. "soulshard",
        empty   = {0.5, 1, 1, 0},
        filled  = {0, 0.5, 1, 0},
    },
    essence = {
        texture = CLASS_TEX_PATH .. "evoker",
        empty   = {0.5, 1, 0, 1},
        filled  = {0, 0.5, 0, 1},
    },
    runes = {
        texture = CLASS_TEX_PATH .. "runes",
        empty   = {0, 0.5, 0, 1},
        filled  = {0.5, 1, 0, 1},
    },
}

local BAND_PREVIEW = {
    chi = {
        texture = CLASS_TEX_PATH .. "chi",
        multiplier = 0.111,
        bgRow = function(maxValue) return maxValue + 2 end,
    },
    holy = {
        texture = CLASS_TEX_PATH .. "holypower",
        multiplier = 0.125,
        bgRow = function(maxValue) return maxValue - 1 end,
        desaturateBg = true,
    },
    arcane = {
        texture = CLASS_TEX_PATH .. "arcane",
        multiplier = 0.125,
        bgRow = function(maxValue) return maxValue - 1 end,
        desaturateBg = true,
    },
}

local function T(key, fallback)
    local v = L and L[key]
    if v and v ~= key then return v end
    return fallback or key
end

local function Clamp(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function SafeFont(fs, path, size, outline)
    if not fs then return end
    if not fs:SetFont(path or FONT, math.max(6, size or 10), outline or "OUTLINE") then
        fs:SetFont(STANDARD_TEXT_FONT, math.max(6, size or 10), outline or "OUTLINE")
    end
end

local function Style(db,key)
    local st=db and db.styles and db.styles[key]
    return st or db or {}
end

local function ResolveRBTexture(db,key)
    local st=Style(db,key)
    local texKey=st.barTexture or (db and db.barTexture) or "tomo"
    if texKey == "flat" then return WHITE8 end
    if texKey == "blizzard" then return "Interface\\TargetingFrame\\UI-StatusBar" end
    return TOMO_TEX
end

local function BorderColor(db,key)
    local st=Style(db,key)
    local c=st.borderColor or (db and db.borderColor) or {r=0,g=0,b=0}
    return c.r or 0,c.g or 0,c.b or 0
end

local function ApplyBackdrop(frame,db,key,forceBorder)
    local st=Style(db,key)
    local alpha=Clamp(st.backgroundAlpha or (db and db.backgroundAlpha) or .80,0,1)
    local edge=Clamp(st.borderSize or (db and db.borderSize) or 1,1,4)
    frame:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=edge})
    frame:SetBackdropColor(.025,.03,.04,alpha)
    local enabled=st.borderEnabled
    if enabled==nil and db then enabled=db.borderEnabled end
    if forceBorder~=nil then enabled=forceBorder end
    if enabled==false then
        frame:SetBackdropBorderColor(0,0,0,0)
    else
        local r,g,b=BorderColor(db,key)
        frame:SetBackdropBorderColor(r,g,b,1)
    end
end

local function ClassConfig(db)
    return db and db.classResource or {}
end

local function ThresholdColor(db,current,maxValue,baseR,baseG,baseB)
    local th=db and db.thresholds and db.thresholds.class
    if not (th and th.enabled) then return baseR,baseG,baseB,false end
    local metric=current
    if th.mode~="value" then
        metric=(maxValue and maxValue>0) and (current/maxValue*100) or 0
    end
    local c
    if metric <= (tonumber(th.low) or 30) then c=th.lowColor
    elseif metric >= (tonumber(th.high) or 80) then c=th.highColor end
    if c then return c.r or baseR,c.g or baseG,c.b or baseB,true end
    return baseR,baseG,baseB,false
end

local function HideHashes(bar)
    if not bar or not bar._hashes then return end
    for _,t in ipairs(bar._hashes) do t:Hide() end
end

local function ApplyHashes(bar,cfg,maxValue,orientation)
    if not bar then return end
    HideHashes(bar)
    if not (cfg and cfg.enabled and cfg.values and cfg.values~="") then return end
    local vals={}
    for token in tostring(cfg.values):gmatch("[%d%.]+") do
        local n=tonumber(token)
        if n and n>=0 then vals[#vals+1]=n end
    end
    bar._hashes=bar._hashes or {}
    local col=cfg.color or {r=1,g=1,b=1,a=.75}
    local thick=Clamp(cfg.width or 1,1,5)
    for i,v in ipairs(vals) do
        local pct
        if cfg.mode=="value" then pct=(maxValue and maxValue>0) and v/maxValue*100 or nil
        else pct=v end
        if pct and pct>0 and pct<100 then
            local t=bar._hashes[i]
            if not t then t=bar:CreateTexture(nil,"OVERLAY",nil,6); bar._hashes[i]=t end
            t:ClearAllPoints(); t:SetColorTexture(col.r or 1,col.g or 1,col.b or 1,col.a or .75)
            if orientation=="VERTICAL" then
                local y=bar:GetHeight()*(pct/100)
                t:SetHeight(thick)
                t:SetPoint("LEFT",bar,"BOTTOMLEFT",0,y)
                t:SetPoint("RIGHT",bar,"BOTTOMRIGHT",0,y)
            else
                t:SetWidth(thick); t:SetPoint("TOP"); t:SetPoint("BOTTOM")
                t:SetPoint("LEFT",bar,"LEFT",bar:GetWidth()*(pct/100),0)
            end
            t:Show()
        end
    end
end

local function AutoKind()
    local _, class = UnitClass("player")
    if class=="ROGUE" or class=="DRUID" then return "combo" end
    if class=="DEATHKNIGHT" then return "runes" end
    if class=="WARLOCK" then return "shards" end
    if class=="PALADIN" then return "holy" end
    if class=="MONK" then return "chi" end
    if class=="EVOKER" then return "essence" end
    if class=="MAGE" then return "arcane" end
    if class=="SHAMAN" or class=="HUNTER" then return "aura" end
    if class=="DEMONHUNTER" then return "aura" end
    return "combo"
end

local KIND_META = {
    combo   = {count=7, filled=5, color="comboPoints"},
    runes   = {count=6, filled=4, color="runesReady"},
    shards  = {count=5, filled=3, color="soulShards"},
    holy    = {count=5, filled=4, color="holyPower"},
    chi     = {count=6, filled=4, color="chi"},
    essence = {count=6, filled=5, color="essence"},
    arcane  = {count=4, filled=3, color="arcaneCharges"},
}

local function KindDisplay(kind)
    local keys = {
        combo   = "rcs_preview_combo",
        runes   = "rcs_preview_runes",
        shards  = "rcs_preview_shards",
        holy    = "rcs_preview_holy",
        chi     = "rcs_preview_chi",
        essence = "rcs_preview_essence",
        arcane  = "rcs_preview_arcane",
        stagger = "rcs_preview_stagger",
        aura    = "rcs_preview_aura",
    }
    return T(keys[kind] or "rcs_preview_auto", kind or "Auto")
end

local function Color(db, key, fallback)
    local c = db and db.colors and db.colors[key]
    if c then return c.r or 1,c.g or 1,c.b or 1 end
    return unpack(fallback or {1,1,1})
end

local function CreateStatusBar(parent)
    local b=CreateFrame("StatusBar",nil,parent,"BackdropTemplate")
    b:SetMinMaxValues(0,100)
    b.bg=b:CreateTexture(nil,"BACKGROUND")
    b.bg:SetAllPoints()
    b.text=b:CreateFontString(nil,"OVERLAY")
    b.text:SetPoint("CENTER")
    return b
end

function P.CreateResource(parent)
    local root=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    root:SetAllPoints(parent)
    root:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    root:SetBackdropColor(.014,.018,.028,1)
    root:SetBackdropBorderColor(.10,.12,.16,1)

    root.title=root:CreateFontString(nil,"OVERLAY")
    SafeFont(root.title,FONT_BOLD,11,"")
    root.title:SetPoint("TOPLEFT",14,-12)
    root.title:SetTextColor(.18,.62,.85,1)
    root.title:SetText(T("rcs_preview_resources","Real-time resource preview"))

    root.info=root:CreateFontString(nil,"OVERLAY")
    SafeFont(root.info,FONT,9,"")
    root.info:SetPoint("TOPLEFT",root.title,"BOTTOMLEFT",0,-3)
    root.info:SetPoint("RIGHT",-14,0)
    root.info:SetJustifyH("LEFT")
    root.info:SetTextColor(.48,.52,.60,1)
    root.info:SetText(T("rcs_preview_info",""))

    root.modeText=root:CreateFontString(nil,"OVERLAY")
    SafeFont(root.modeText,FONT_BOLD,9,"")
    root.modeText:SetPoint("TOPRIGHT",-14,-12)
    root.modeText:SetTextColor(.62,.68,.76,1)

    root.stack=CreateFrame("Frame",nil,root)
    root.stack:SetPoint("CENTER",0,-10)
    root.stack:SetSize(700,220)
    if root.SetClipsChildren then root:SetClipsChildren(false) end
    if root.stack.SetClipsChildren then root.stack:SetClipsChildren(false) end

    root.segmentHolder=CreateFrame("Frame",nil,root.stack,"BackdropTemplate")
    root.bandHolder=CreateFrame("Frame",nil,root.stack,"BackdropTemplate")
    root.bandBg=root.bandHolder:CreateTexture(nil,"BACKGROUND")
    root.bandBg:SetAllPoints()
    root.bandFill=root.bandHolder:CreateTexture(nil,"ARTWORK")
    root.bandFill:SetAllPoints()

    root.health=CreateStatusBar(root.stack)
    root.power=CreateStatusBar(root.stack)
    root.secondary=CreateStatusBar(root.stack)
    root.classBar=CreateStatusBar(root.stack)

    root.segments={}
    for i=1,8 do
        local f=CreateFrame("Frame",nil,root.stack,"BackdropTemplate")
        f.bg=f:CreateTexture(nil,"BACKGROUND"); f.bg:SetAllPoints()
        f.fill=f:CreateTexture(nil,"ARTWORK"); f.fill:SetAllPoints()
        f.partial=f:CreateTexture(nil,"ARTWORK"); f.partial:Hide()
        root.segments[i]=f
    end

    root.textOverlay=CreateFrame("Frame",nil,root.stack)
    root.textOverlay:SetAllPoints(root.stack)
    root.textOverlay:SetFrameLevel(root.stack:GetFrameLevel()+50)
    root.textOverlay:EnableMouse(false)

    root.segmentText=root.textOverlay:CreateFontString(nil,"OVERLAY")
    root.bandText=root.textOverlay:CreateFontString(nil,"OVERLAY")

    function root:Refresh(kind)
        local db=TomoModDB and TomoModDB.resourceBars
        if not db then return end

        local uiDB=TomoModDB and TomoModDB.resourceCastStudio or {}
        kind=kind or uiDB.previewKind or self._previewKind or "auto"
        self._previewKind=kind
        local resolvedKind=(kind=="auto") and AutoKind() or kind

        local demoPct=Clamp(uiDB.demoValuePct or 70,0,100)
        local displayMode=db.displayMode or "bars"
        self.modeText:SetText(
            KindDisplay(resolvedKind) .. "  •  " ..
            (displayMode=="icons" and T("display_mode_icons","Icons")
             or T("display_mode_bars","Bars"))
        )
        kind=resolvedKind
        local scale=Clamp(db.scale or 1,0.5,2)
        local width=Clamp((db.width or 260)*math.min(scale,1.65),120,650)
        local gap=Clamp(db.barSpacing or 2,0,12)
        local stackUp=(db.stackDirection=="UP")
        local fontSize=Clamp(db.fontSize or 11,7,20)
        local cr=ClassConfig(db)
        local orientation=cr.orientation or "HORIZONTAL"

        self.stack:SetWidth(width)
        self.segmentText:Hide()
        self.bandText:Hide()
        self.bandHolder:Hide()
        for key,bar in pairs({health=self.health,power=self.power,secondary=self.secondary,class=self.classBar}) do
            bar:Hide()
            HideHashes(bar)
            local styleKey=(key=="health") and "health" or (key=="class" and "class" or "power")
            local tex=ResolveRBTexture(db,styleKey)
            local st=Style(db,styleKey)
            bar:SetOrientation("HORIZONTAL")
            bar:SetStatusBarTexture(tex)
            bar.bg:SetTexture(tex)
            bar.bg:SetVertexColor(.06,.06,.08,Clamp(st.backgroundAlpha or db.backgroundAlpha or .80,0,1))
            local forceBorder
            if styleKey=="class" then forceBorder=(cr.borderMode or "segments")~="none" end
            ApplyBackdrop(bar,db,styleKey,forceBorder)
            SafeFont(bar.text,db.font or FONT,fontSize,"OUTLINE")
            bar.text:SetTextColor(1,1,1,.92)
        end
        for _,f in ipairs(self.segments) do
            f:Hide()
            f.partial:Hide()
            f.bg:SetDesaturated(false)
            f.fill:SetDesaturated(false)
            f.partial:SetDesaturated(false)
            f.bg:SetTexCoord(0,1,0,1)
            f.fill:SetTexCoord(0,1,0,1)
            f.partial:SetTexCoord(0,1,0,1)
        end
        self.segmentHolder:Hide()

        local layers={}
        if db.healthBarEnabled then
            local h=Clamp(db.healthBarHeight or 14,8,30)
            self.health:SetHeight(h); self.health:SetWidth(width); self.health:SetValue(73)
            local hr,hg,hb=Color(db,"health",{.15,.75,.3})
            self.health:SetStatusBarColor(hr,hg,hb,1)
            local fmt=db.healthTextFormat or "both"
            self.health.text:SetText(fmt=="none" and "" or (fmt=="value" and "728K" or fmt=="percent" and "73%" or "728K | 73%"))
            layers[#layers+1]={frame=self.health,height=h}
        end

        local meta=KIND_META[kind]
        local classH=Clamp(db.primaryHeight or 16,6,40)
        if meta then
            local count=meta.count
            local current=count*(demoPct/100)
            local full=math.floor(current)
            local frac=current-full
            local crR,crG,crB=Color(db,meta.color,{1,.8,.2})
            local tr,tg,tb,thresholdActive=ThresholdColor(db,current,count,crR,crG,crB)
            local th=db.thresholds and db.thresholds.class
            local target=th and th.target or "both"
            local fillR,fillG,fillB=crR,crG,crB
            if thresholdActive and target~="text" then fillR,fillG,fillB=tr,tg,tb end

            local useContinuous=(cr.mode=="bar" and kind~="runes")
            local useBand=(not useContinuous)
                and displayMode=="icons"
                and orientation=="HORIZONTAL"
                and BAND_PREVIEW[kind]~=nil

            if useContinuous then
                local bar=self.classBar
                local vertical=(orientation=="VERTICAL")
                local length=vertical and Clamp(width,120,210) or width
                bar:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
                if vertical then bar:SetSize(classH,length) else bar:SetSize(width,classH) end
                bar:SetMinMaxValues(0,count); bar:SetValue(current)
                bar:SetStatusBarTexture(ResolveRBTexture(db,"class"))
                bar.bg:SetTexture(ResolveRBTexture(db,"class"))
                local st=Style(db,"class")
                bar.bg:SetVertexColor(.06,.06,.08,Clamp(st.backgroundAlpha or .8,0,1))
                ApplyBackdrop(bar,db,"class",cr.borderMode~="none")
                bar:SetStatusBarColor(fillR,fillG,fillB,1)
                bar.text:SetText(db.showText==false and "" or string.format("%.1f / %d",current,count))
                if thresholdActive and target~="bar" then bar.text:SetTextColor(tr,tg,tb,1) end
                ApplyHashes(bar,db.hashLines and db.hashLines.class,count,orientation)
                layers[#layers+1]={frame=bar,height=vertical and length or classH,keepSize=vertical}

            elseif useBand then
                local cfg=BAND_PREVIEW[kind]
                local holder=self.bandHolder
                holder:SetSize(width,classH)
                ApplyBackdrop(holder,db,"class",(cr.borderMode or "segments")~="none")
                holder:SetBackdropColor(0,0,0,0)

                self.bandBg:SetTexture(cfg.texture)
                self.bandBg:SetVertexColor(1,1,1,Clamp(Style(db,"class").backgroundAlpha or .8,0,1))
                self.bandBg:SetDesaturated(cfg.desaturateBg==true)
                local bgRow=cfg.bgRow(count)
                self.bandBg:SetTexCoord(0,1,cfg.multiplier*bgRow,cfg.multiplier*(bgRow+1))

                self.bandFill:SetTexture(cfg.texture)
                self.bandFill:SetDesaturated(false)
                self.bandFill:SetVertexColor(fillR,fillG,fillB,1)
                if full>0 then
                    local fillRow=math.min(full,count)-1
                    self.bandFill:SetTexCoord(0,1,cfg.multiplier*fillRow,cfg.multiplier*(fillRow+1))
                    self.bandFill:Show()
                else
                    self.bandFill:Hide()
                end

                SafeFont(self.bandText,db.font or FONT,fontSize,"OUTLINE")
                self.bandText:ClearAllPoints()
                self.bandText:SetPoint("CENTER",holder,"CENTER")
                self.bandText:SetText(db.showText==false and "" or string.format("%.1f / %d",current,count))
                self.bandText:SetTextColor(1,1,1,.95)
                if thresholdActive and target~="bar" then self.bandText:SetTextColor(tr,tg,tb,1) end
                self.bandText:SetShown(db.showText~=false)
                holder:Show()
                layers[#layers+1]={frame=holder,height=classH}

            else
                local holder=self.segmentHolder
                local vertical=(orientation=="VERTICAL")
                local length=vertical and Clamp(width,120,210) or width
                local spacing=Clamp(db.segmentSpacing or 2,0,12)

                local iconCfg=(displayMode=="icons") and ICON_PREVIEW[kind] or nil
                local extent
                local offset=0
                if iconCfg then
                    extent=classH
                    local total=count*extent+(count-1)*spacing
                    offset=math.max((length-total)/2,0)
                else
                    extent=(length-(count-1)*spacing)/count
                end

                if vertical then holder:SetSize(classH,length) else holder:SetSize(width,classH) end
                local mode=cr.borderMode or "segments"
                local segBorder=(mode=="segments" or mode=="both")
                local outerBorder=(mode=="outer" or mode=="both")
                ApplyBackdrop(holder,db,"class",outerBorder)
                holder:SetBackdropColor(0,0,0,0)

                local empty=cr.emptyColor or {r=.06,g=.06,b=.08}
                local st=Style(db,"class")
                local alpha=Clamp(st.backgroundAlpha or .8,0,1)
                local tex=ResolveRBTexture(db,"class")

                for i=1,count do
                    local f=self.segments[i]
                    if vertical then f:SetSize(classH,extent) else f:SetSize(extent,classH) end
                    ApplyBackdrop(f,db,"class",segBorder)
                    f:SetBackdropColor(0,0,0,0)

                    if iconCfg then
                        f.bg:SetTexture(iconCfg.texture)
                        f.bg:SetTexCoord(unpack(iconCfg.empty))
                        f.bg:SetVertexColor(1,1,1,alpha)
                        f.fill:SetTexture(iconCfg.texture)
                        f.fill:SetTexCoord(unpack(iconCfg.filled))
                        f.fill:SetVertexColor(1,1,1,1)
                        f.partial:SetTexture(iconCfg.texture)
                        f.partial:SetTexCoord(unpack(iconCfg.filled))
                        f.partial:SetVertexColor(1,1,1,.72)
                    else
                        f.bg:SetTexture(tex)
                        f.bg:SetVertexColor(empty.r or .06,empty.g or .06,empty.b or .08,alpha)
                        f.fill:SetTexture(tex)
                        f.fill:SetVertexColor(fillR,fillG,fillB,1)
                        f.partial:SetTexture(tex)
                        f.partial:SetVertexColor(fillR,fillG,fillB,.72)
                    end

                    f.fill:SetShown(i<=full)
                    f.partial:Hide()
                    if i==full+1 and frac>0 and cr.partialFill~=false then
                        f.partial:ClearAllPoints()
                        if vertical then
                            f.partial:SetPoint("BOTTOMLEFT"); f.partial:SetPoint("BOTTOMRIGHT")
                            f.partial:SetHeight(math.max(1,extent*frac))
                        else
                            f.partial:SetPoint("TOPLEFT"); f.partial:SetPoint("BOTTOMLEFT")
                            f.partial:SetWidth(math.max(1,extent*frac))
                        end
                        f.partial:Show()
                    end

                    f:ClearAllPoints()
                    f:SetParent(holder)
                    if vertical then
                        f:SetPoint("BOTTOM",holder,"BOTTOM",0,offset+(i-1)*(extent+spacing))
                    else
                        f:SetPoint("LEFT",holder,"LEFT",offset+(i-1)*(extent+spacing),0)
                    end
                    f:Show()
                end

                SafeFont(self.segmentText,db.font or FONT,fontSize,"OUTLINE")
                self.segmentText:ClearAllPoints()
                self.segmentText:SetPoint("CENTER",holder,"CENTER")
                self.segmentText:SetText(db.showText==false and "" or string.format("%.1f / %d",current,count))
                self.segmentText:SetTextColor(1,1,1,.95)
                if thresholdActive and target~="bar" then self.segmentText:SetTextColor(tr,tg,tb,1) end
                self.segmentText:SetShown(db.showText~=false)
                holder:Show()
                layers[#layers+1]={frame=holder,height=vertical and length or classH,keepSize=vertical}
            end
        elseif kind=="stagger" or kind=="aura" then
            local vertical=(orientation=="VERTICAL")
            local length=vertical and Clamp(width,120,210) or width
            local bar=self.classBar
            bar:SetOrientation(vertical and "VERTICAL" or "HORIZONTAL")
            if vertical then bar:SetSize(classH,length) else bar:SetSize(width,classH) end
            local current=(kind=="stagger") and demoPct or (10*demoPct/100)
            local maximum=(kind=="stagger") and 100 or 10
            bar:SetMinMaxValues(0,maximum); bar:SetValue(current)
            local r,g,b=Color(db,kind=="stagger" and "stagger" or "maelstromWeapon",{.4,.8,.4})
            local tr,tg,tb,active=ThresholdColor(db,current,maximum,r,g,b)
            local th=db.thresholds and db.thresholds.class
            local target=th and th.target or "both"
            if active and target~="text" then r,g,b=tr,tg,tb end

            if kind=="stagger" and displayMode=="icons" and not vertical then
                bar:SetStatusBarTexture(CLASS_TEX_PATH.."monk\\stagger-yellow")
                bar.bg:SetTexture(CLASS_TEX_PATH.."monk\\stagger-bg")
                bar.bg:SetVertexColor(1,1,1,Clamp(Style(db,"class").backgroundAlpha or .8,0,1))
                bar:SetStatusBarColor(1,1,1,1)
            else
                bar:SetStatusBarTexture(ResolveRBTexture(db,"class"))
                bar.bg:SetTexture(ResolveRBTexture(db,"class"))
                bar.bg:SetVertexColor(.06,.06,.08,Clamp(Style(db,"class").backgroundAlpha or .8,0,1))
                bar:SetStatusBarColor(r,g,b,1)
            end
            bar.text:SetText(db.showText==false and "" or (kind=="stagger" and string.format("Stagger %d%%",demoPct) or string.format("%.1f / 10",current)))
            if active and target~="bar" then bar.text:SetTextColor(tr,tg,tb,1) end
            ApplyHashes(bar,db.hashLines and db.hashLines.class,maximum,orientation)
            layers[#layers+1]={frame=bar,height=vertical and length or classH,keepSize=vertical}
        end

        if db.primaryPowerCentered then
            local h=Clamp(db.primaryPowerBarHeight or 14,6,30)
            self.power:SetSize(width,h); self.power:SetMinMaxValues(0,100); self.power:SetValue(demoPct)
            local r,g,b=Color(db,"mana",{0,0,1}); self.power:SetStatusBarColor(r,g,b,1)
            self.power.text:SetText(db.showText==false and "" or string.format("%d%%",demoPct))
            ApplyHashes(self.power,db.hashLines and db.hashLines.power,100,"HORIZONTAL")
            layers[#layers+1]={frame=self.power,height=h}
        end

        if kind=="combo" and select(2,UnitClass("player"))=="DRUID" then
            local h=Clamp(db.secondaryHeight or 12,6,30)
            self.secondary:SetSize(width,h); self.secondary:SetValue(68)
            local r,g,b=Color(db,"mana",{0,0,1}); self.secondary:SetStatusBarColor(r,g,b,1)
            self.secondary.text:SetText(db.showText==false and "" or "68K")
            layers[#layers+1]={frame=self.secondary,height=h}
        end

        local total=0
        for i,layer in ipairs(layers) do
            total=total+layer.height
            if i<#layers then total=total+gap end
        end
        local cursor=stackUp and (-total/2) or (total/2)
        for _,layer in ipairs(layers) do
            local f=layer.frame
            f:ClearAllPoints()
            if stackUp then
                f:SetPoint("BOTTOM",self.stack,"CENTER",0,cursor)
                cursor=cursor+layer.height+gap
            else
                f:SetPoint("TOP",self.stack,"CENTER",0,cursor)
                cursor=cursor-layer.height-gap
            end
            if not layer.keepSize then f:SetWidth(width) end
            f:Show()
        end
    end

    function root:SetPreviewKind(kind)
        kind=kind or "auto"
        self._previewKind=kind
        if TomoModDB then
            TomoModDB.resourceCastStudio=TomoModDB.resourceCastStudio or {}
            TomoModDB.resourceCastStudio.previewKind=kind
        end
        self:Refresh(kind)
    end

    root._previewWatchElapsed=0
    root:SetScript("OnUpdate",function(self,elapsed)
        if not self:IsShown() then return end
        self._previewWatchElapsed=self._previewWatchElapsed+elapsed
        if self._previewWatchElapsed<0.12 then return end
        self._previewWatchElapsed=0

        local db=TomoModDB and TomoModDB.resourceBars
        local ui=TomoModDB and TomoModDB.resourceCastStudio
        if not db then return end
        local cr=db.classResource or {}
        local sig=table.concat({
            tostring(ui and ui.previewKind or self._previewKind or "auto"),
            tostring(ui and ui.demoValuePct or 70),
            tostring(db.displayMode or "bars"),
            tostring(cr.mode or "segments"),
            tostring(cr.orientation or "HORIZONTAL"),
            tostring(db.primaryPowerCentered and 1 or 0),
            tostring(db.healthBarEnabled and 1 or 0),
        },"|")
        if sig~=self._previewSignature then
            self._previewSignature=sig
            self:Refresh(ui and ui.previewKind or self._previewKind)
        end
    end)

    return root
end

local function PlayerClassColor()
    local _,class=UnitClass("player")
    local c=class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r,c.g,c.b end
    return .18,.62,.85
end

local function CastTexture(db)
    if TomoMod_Castbar and TomoMod_Castbar.ResolveBarTexture then
        return TomoMod_Castbar.ResolveBarTexture(db)
    end
    if db.barTexture=="smooth" then return "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" end
    if db.barTexture=="flat" then return WHITE8 end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

function P.CreateCast(parent)
    local root=CreateFrame("Frame",nil,parent,"BackdropTemplate")
    root:SetAllPoints(parent)
    root:SetBackdrop({bgFile=WHITE8,edgeFile=WHITE8,edgeSize=1})
    root:SetBackdropColor(.014,.018,.028,1)
    root:SetBackdropBorderColor(.10,.12,.16,1)

    root.title=root:CreateFontString(nil,"OVERLAY")
    SafeFont(root.title,FONT_BOLD,11,"")
    root.title:SetPoint("TOPLEFT",14,-12)
    root.title:SetTextColor(.18,.62,.85,1)
    root.title:SetText(T("rcs_preview_cast","Real-time Player cast preview"))

    root.info=root:CreateFontString(nil,"OVERLAY")
    SafeFont(root.info,FONT,9,"")
    root.info:SetPoint("TOPLEFT",root.title,"BOTTOMLEFT",0,-3)
    root.info:SetPoint("RIGHT",-14,0)
    root.info:SetJustifyH("LEFT")
    root.info:SetTextColor(.48,.52,.60,1)
    root.info:SetText(T("rcs_preview_info",""))

    root.holder=CreateFrame("Frame",nil,root)
    root.holder:SetPoint("CENTER",0,-4)

    root.bar=CreateFrame("StatusBar",nil,root.holder,"BackdropTemplate")
    root.bar:SetMinMaxValues(0,100); root.bar:SetValue(62)
    root.bg=root.bar:CreateTexture(nil,"BACKGROUND"); root.bg:SetAllPoints()

    root.name=root.bar:CreateFontString(nil,"OVERLAY")
    root.name:SetPoint("LEFT",7,0); root.name:SetJustifyH("LEFT")
    root.timer=root.bar:CreateFontString(nil,"OVERLAY")
    root.timer:SetPoint("RIGHT",-7,0); root.timer:SetJustifyH("RIGHT")

    root.icon=CreateFrame("Frame",nil,root.holder,"BackdropTemplate")
    root.icon.tex=root.icon:CreateTexture(nil,"ARTWORK"); root.icon.tex:SetAllPoints()
    root.icon.tex:SetTexture(135812)
    root.icon:SetBackdrop({edgeFile=WHITE8,edgeSize=1}); root.icon:SetBackdropBorderColor(0,0,0,1)

    root.latency=root.bar:CreateTexture(nil,"OVERLAY")
    root.latency:SetColorTexture(1,.12,.12,.28)
    root.latency:SetPoint("TOPRIGHT"); root.latency:SetPoint("BOTTOMRIGHT")

    root.spark=root.bar:CreateTexture(nil,"OVERLAY")
    root.spark:SetColorTexture(1,1,1,.95)

    root.gcd=CreateFrame("StatusBar",nil,root.holder,"BackdropTemplate")
    root.gcd:SetMinMaxValues(0,100); root.gcd:SetValue(35)
    root.gcd:SetStatusBarTexture(WHITE8)

    function root:Refresh()
        local db=TomoModDB and TomoModDB.castbars
        local p=db and db.player
        if not (db and p) then return end

        local w=Clamp(p.width or 260,100,500)
        local h=Clamp(p.height or 22,8,40)
        self.holder:SetSize(w+50,h+30)
        self.bar:SetSize(w,h)
        self.bar:SetStatusBarTexture(CastTexture(db))

        if db.backgroundMode=="transparent" then
            self.bg:SetColorTexture(0,0,0,0)
        elseif db.backgroundMode=="custom" and db.customBackgroundPath then
            self.bg:SetTexture(db.customBackgroundPath)
            self.bg:SetVertexColor(1,1,1,1)
        else
            self.bg:SetTexture(WHITE8); self.bg:SetVertexColor(.02,.02,.025,.95)
        end

        local r,g,b
        if db.useClassColor then r,g,b=PlayerClassColor()
        else
            local c=db.castbarColor or {r=1,g=.7,b=0}
            r,g,b=c.r,c.g,c.b
        end
        self.bar:SetStatusBarColor(r,g,b,1)

        SafeFont(self.name,db.font or FONT,db.fontSize or 12,"OUTLINE")
        SafeFont(self.timer,db.font or FONT,db.fontSize or 12,"OUTLINE")
        self.name:SetText(T("rcs_preview_spell","Demonstration cast"))
        self.timer:SetText((db.timerFormat=="remaining_total") and "1.4 / 2.3" or (db.timerFormat=="elapsed" and "0.9" or "1.4"))
        self.timer:SetShown(p.showTimer~=false)

        self.icon:SetSize(h,h)
        self.icon:ClearAllPoints()
        self.bar:ClearAllPoints()
        if p.showIcon~=false then
            self.icon:Show()
            if (p.iconSide or "LEFT")=="RIGHT" then
                self.bar:SetPoint("CENTER",self.holder,"CENTER",-h/2-2,0)
                self.icon:SetPoint("LEFT",self.bar,"RIGHT",3,0)
            else
                self.bar:SetPoint("CENTER",self.holder,"CENTER",h/2+2,0)
                self.icon:SetPoint("RIGHT",self.bar,"LEFT",-3,0)
            end
        else
            self.icon:Hide()
            self.bar:SetPoint("CENTER",self.holder,"CENTER",0,0)
        end

        self.latency:SetWidth(math.max(2,w*.12))
        self.latency:SetShown(p.showLatency==true)

        self.spark:SetSize(2,h*1.35)
        self.spark:ClearAllPoints()
        self.spark:SetPoint("CENTER",self.bar,"LEFT",w*.62,0)
        local sc=db.sparkColor or {r=1,g=1,b=1}
        self.spark:SetColorTexture(sc.r,sc.g,sc.b,1)
        self.spark:SetShown(db.showSpark~=false)

        self.gcd:ClearAllPoints()
        self.gcd:SetPoint("TOPLEFT",self.bar,"BOTTOMLEFT",0,-5)
        self.gcd:SetWidth(w)
        self.gcd:SetHeight(Clamp(db.gcdHeight or 4,2,12))
        local gc=db.gcdColor or {r=1,g=1,b=1}
        self.gcd:SetStatusBarColor(gc.r,gc.g,gc.b,1)
        self.gcd:SetShown(db.showGCDSpark==true)
    end

    return root
end
