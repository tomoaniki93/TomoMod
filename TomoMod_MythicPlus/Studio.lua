-- =====================================================================
-- TomoMod_MythicPlus / Studio.lua
-- Mouse-only Mythic+ dashboard and configuration centre. It intentionally
-- does not EnableKeyboard: this window may be opened around dungeon events
-- and must never compete with WorldFrame for movement bindings.
-- =====================================================================

local MP = TomoMod_MythicPlus
if not MP then return end

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"

local DEFAULT_STUDIO_ACCENT = { 0.18, 0.85, 0.52, 1 }
local DEFAULT_STUDIO_BG_ALPHA = 0.98

local C = {
    bg       = { 0.035, 0.043, 0.055, 0.98 },
    panel    = { 0.055, 0.065, 0.082, 0.96 },
    panel2   = { 0.070, 0.082, 0.102, 0.92 },
    border   = { 0.16, 0.18, 0.22, 1 },
    accent   = { unpack(DEFAULT_STUDIO_ACCENT) },
    text     = { 0.94, 0.96, 0.95, 1 },
    dim      = { 0.50, 0.54, 0.58, 1 },
    red      = { 0.90, 0.26, 0.24, 1 },
    yellow   = { 0.95, 0.76, 0.14, 1 },
    green    = { 0.28, 0.88, 0.48, 1 },
}

local PANEL_W, PANEL_H = 1120, 800
local SIDE_W, HEADER_H = 210, 52
local PAGE_PAD = 18
local navButtons = {}
local content, pageBin

local _issecret = issecretvalue
local function IsSecret(v)
    if not _issecret then return false end
    local ok, secret = pcall(_issecret, v)
    return ok and secret or false
end
local function Num(v)
    if v == nil or IsSecret(v) or type(v) ~= "number" then return nil end
    return v
end
local function Bool(v)
    if v == nil or IsSecret(v) then return nil end
    return v and true or false
end

local function UIStringScale()
    local scale = 1
    if MP and MP.GetDB then
        local ok, db = pcall(MP.GetDB, MP)
        if ok and type(db) == "table" and type(db.ui) == "table" then
            scale = tonumber(db.ui.textScale) or 1
        end
    end
    return math.max(0.85, math.min(scale, 1.60))
end

local function Backdrop(frame, bg, border)
    frame:SetBackdrop({ bgFile=WHITE8, edgeFile=WHITE8, edgeSize=1 })
    frame:SetBackdropColor(unpack(bg or C.panel))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function ApplyTextFont(fs)
    if not fs then return end
    local base = fs._tmMPlusBaseSize or 11
    local scaled = math.max(7, math.floor(base * UIStringScale() + 0.5))
    fs:SetFont(fs._tmMPlusBold and FONT_BOLD or FONT, scaled, "")
end

local function Text(parent, value, size, bold)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs._tmMPlusBaseSize = size or 11
    fs._tmMPlusBold = bold and true or false
    ApplyTextFont(fs)
    fs:SetTextColor(unpack(C.text))
    fs:SetText(value or "")
    return fs
end

function MP:ApplyStudioAppearance()
    local db = self:GetDB()
    local ui = db and db.ui or {}
    local accent = ui.useCustomAccent and ui.accent or nil
    C.accent[1] = accent and (tonumber(accent.r or accent[1]) or DEFAULT_STUDIO_ACCENT[1]) or DEFAULT_STUDIO_ACCENT[1]
    C.accent[2] = accent and (tonumber(accent.g or accent[2]) or DEFAULT_STUDIO_ACCENT[2]) or DEFAULT_STUDIO_ACCENT[2]
    C.accent[3] = accent and (tonumber(accent.b or accent[3]) or DEFAULT_STUDIO_ACCENT[3]) or DEFAULT_STUDIO_ACCENT[3]
    C.accent[4] = 1
    C.bg[4] = math.max(0.72, math.min(tonumber(ui.backgroundAlpha) or DEFAULT_STUDIO_BG_ALPHA, 1))

    if not self.Frame then return end
    self.Frame:SetScale(math.max(0.85, math.min(tonumber(ui.windowScale) or 1, 1.15)))
    self.Frame:SetBackdropColor(unpack(C.bg))
    self.Frame:SetBackdropBorderColor(unpack(C.border))
    if self.Frame._accent then self.Frame._accent:SetColorTexture(unpack(C.accent)) end
    if self.Frame._headerLine then self.Frame._headerLine:SetColorTexture(unpack(C.border)) end
    if self.Frame._vsep then self.Frame._vsep:SetColorTexture(unpack(C.border)) end

    ApplyTextFont(self.Frame._title)
    ApplyTextFont(self.Frame._subtitle)
    ApplyTextFont(self.Frame._version)
    for id, button in pairs(navButtons) do
        ApplyTextFont(button and button._text)
        if button then
            local selected = id == (self.page or "dashboard")
            button:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], selected and 0.20 or 0)
        end
    end
end

function MP:RefreshStudioAppearance(page)
    self:ApplyStudioAppearance()
    -- SelectPage rebuilds the page this was called from, and a rebuilt control
    -- can call straight back in. One level of rebuild is all that is ever
    -- useful; the pcall is so a failure inside SelectPage cannot leave the
    -- flag latched and silently disable every later refresh.
    if self._appearanceRefreshing then return end
    if self.Frame and self.Frame:IsShown() then
        self._appearanceRefreshing = true
        local ok, err = pcall(self.SelectPage, self, page or self.page or "appearance")
        self._appearanceRefreshing = false
        if not ok then error(err, 0) end
    end
end

local function PageTitle(parent, title, subtitle)
    local t = Text(parent, title, 20, true)
    t:SetPoint("TOPLEFT", PAGE_PAD, -PAGE_PAD)
    local s = Text(parent, subtitle or "", 10, false)
    s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -4)
    s:SetTextColor(unpack(C.dim))
    return -62
end

local function Card(parent, x, y, w, h, title)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetPoint("TOPLEFT", x, y)
    f:SetSize(w, h)
    Backdrop(f, C.panel, C.border)
    if title then
        local t = Text(f, title, 11, true)
        t:SetPoint("TOPLEFT", 12, -10)
        t:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
    return f
end

local function Button(parent, label, x, y, w, callback)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetPoint("TOPLEFT", x, y)
    b:SetSize(w or 180, 28)
    Backdrop(b, { 0.065, 0.095, 0.080, 1 }, { C.accent[1], C.accent[2], C.accent[3], 0.55 })
    local txt = Text(b, label, 10, true)
    txt:SetPoint("CENTER")
    b._text = txt
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.18)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.065, 0.095, 0.080, 1)
    end)
    b:SetScript("OnClick", callback)
    return b
end

local function Segmented(parent, label, options, value, x, y, w, callback)
    local host=CreateFrame("Frame",nil,parent)
    host:SetPoint("TOPLEFT",x,y); host:SetSize(w or 380,48)
    local title=Text(host,label,8,false); title:SetPoint("TOPLEFT",0,0); title:SetTextColor(unpack(C.dim))
    local buttons={}; local gap=4; local bw=((w or 380)-gap*(#options-1))/#options
    local selected=value
    local function Refresh()
        for _,entry in ipairs(buttons) do
            local on=entry.value==selected
            entry.button:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],on and 0.24 or 0.05)
            entry.button:SetBackdropBorderColor(C.accent[1],C.accent[2],C.accent[3],on and 0.85 or 0.25)
            entry.text:SetTextColor(on and 1 or 0.68,on and 1 or 0.71,on and 1 or 0.75,1)
        end
    end
    for i,opt in ipairs(options) do
        local b=CreateFrame("Button",nil,host,"BackdropTemplate"); b:SetPoint("TOPLEFT",(i-1)*(bw+gap),-17); b:SetSize(bw,25); Backdrop(b,{0.05,0.06,0.075,1},C.border)
        local t=Text(b,opt.text,8,true); t:SetPoint("CENTER")
        buttons[#buttons+1]={button=b,text=t,value=opt.value}
        b:SetScript("OnClick",function() selected=opt.value; Refresh(); if callback then callback(selected) end end)
    end
    Refresh()
    return host
end

local function Check(parent, label, value, x, y, callback, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetPoint("TOPLEFT", x, y)
    b:SetSize(width or 350, 22)

    local box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    box:SetPoint("LEFT", 0, 0)
    box:SetSize(16, 16)
    Backdrop(box, { 0.04, 0.05, 0.065, 1 }, C.border)
    local fill = box:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3); fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)

    local txt = Text(b, label, 10, false)
    txt:SetPoint("LEFT", box, "RIGHT", 8, 0)
    txt:SetPoint("RIGHT", b, "RIGHT", 0, 0)
    txt:SetJustifyH("LEFT")

    b._value = value and true or false
    fill:SetShown(b._value)
    function b:SetValue(v)
        self._value = v and true or false
        fill:SetShown(self._value)
    end
    b:SetScript("OnClick", function(self)
        self:SetValue(not self._value)
        if callback then callback(self._value) end
    end)
    return b
end

local function Slider(parent, label, value, lo, hi, step, x, y, w, callback, fmt)
    local width = w or 300
    local host = CreateFrame("Frame", nil, parent)
    host:SetPoint("TOPLEFT", x, y)
    host:SetSize(width, 46)

    local title = Text(host, label, 9, false)
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetTextColor(unpack(C.dim))
    local val = Text(host, "", 10, true)
    val:SetPoint("TOPRIGHT", 0, 0)

    local rail = CreateFrame("Frame", nil, host, "BackdropTemplate")
    rail:SetPoint("TOPLEFT", 0, -20)
    rail:SetPoint("TOPRIGHT", 0, -20)
    rail:SetHeight(10)
    Backdrop(rail, { 0.045, 0.055, 0.070, 1 }, { C.border[1], C.border[2], C.border[3], 0.85 })

    local fill = rail:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.92)

    local s = CreateFrame("Slider", nil, host)
    s:SetPoint("TOPLEFT", rail, "TOPLEFT", 0, 6)
    s:SetPoint("TOPRIGHT", rail, "TOPRIGHT", 0, 6)
    s:SetHeight(24)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(lo, hi)
    s:SetValueStep(step)
    s:SetObeyStepOnDrag(true)
    s:SetThumbTexture(WHITE8)
    local thumb = s:GetThumbTexture()
    if thumb then
        thumb:SetSize(12, 18)
        thumb:SetColorTexture(C.text[1], C.text[2], C.text[3], 1)
    end

    local function Update(v)
        local minv, maxv = s:GetMinMaxValues()
        local span = math.max((maxv or 1) - (minv or 0), 0.0001)
        local ratio = math.min(math.max(((v or minv) - minv) / span, 0), 1)
        local usable = math.max((rail:GetWidth() or width) - 2, 1)
        fill:SetWidth(math.max(2, usable * ratio))
        val:SetText(string.format(fmt or "%.2f", v))
    end

    -- Seed the value BEFORE wiring OnValueChanged. SetValue() raises that
    -- script, so with the two in the other order every slider fires its
    -- caller's callback once while being built -- and on the appearance page
    -- that callback rebuilds the page, which builds the slider, which fires
    -- again: unbounded recursion until the C stack gives out.
    rail:SetScript("OnSizeChanged", function() Update(s:GetValue()) end)
    s:SetValue(value or lo)
    Update(value or lo)

    s:SetScript("OnValueChanged", function(_, v)
        Update(v)
        if callback then callback(v) end
    end)
    s:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetValue()
        self:SetValue(current + (delta > 0 and step or -step))
    end)
    s:EnableMouseWheel(true)
    return s
end

local function RaiseColorPicker()
    local cp = ColorPickerFrame
    if not cp then return end
    if not cp._tmMPlusZFix then
        cp._tmMPlusZFix = true
        cp:HookScript("OnHide", function(self)
            if self._tmMPlusPrevStrata then
                self:SetFrameStrata(self._tmMPlusPrevStrata)
                self:SetFrameLevel(self._tmMPlusPrevLevel or 1)
                self._tmMPlusPrevStrata, self._tmMPlusPrevLevel = nil, nil
            end
        end)
    end
    if not cp._tmMPlusPrevStrata then
        cp._tmMPlusPrevStrata = cp:GetFrameStrata()
        cp._tmMPlusPrevLevel = cp:GetFrameLevel()
    end
    cp:SetFrameStrata("TOOLTIP")
    cp:SetFrameLevel(9500)
    cp:SetToplevel(true)
    cp:SetClampedToScreen(true)
end

local function ColorPicker(parent, label, color, x, y, w, callback)
    local host = CreateFrame("Frame", nil, parent)
    host:SetPoint("TOPLEFT", x, y)
    host:SetSize(w or 180, 26)
    local txt = Text(host, label, 9, false)
    txt:SetPoint("LEFT", 0, 0)
    txt:SetTextColor(unpack(C.dim))

    local swatch = CreateFrame("Button", nil, host, "BackdropTemplate")
    swatch:SetSize(28, 18)
    swatch:SetPoint("RIGHT", 0, 0)
    Backdrop(swatch, { color.r or 1, color.g or 1, color.b or 1, 1 }, C.border)

    local function Update(r, g, b)
        color.r, color.g, color.b = r, g, b
        swatch:SetBackdropColor(r, g, b, 1)
        if callback then callback(r, g, b) end
    end

    swatch:SetScript("OnClick", function()
        if not ColorPickerFrame then return end
        local prev = { color.r or 1, color.g or 1, color.b or 1 }
        local function Changed()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            Update(r, g, b)
        end
        local function Cancelled()
            Update(prev[1], prev[2], prev[3])
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = Changed,
                cancelFunc = Cancelled,
                r = prev[1], g = prev[2], b = prev[3],
                hasOpacity = false,
            })
        else
            ColorPickerFrame:SetColorRGB(prev[1], prev[2], prev[3])
            ColorPickerFrame.hasOpacity = false
            ColorPickerFrame.func = Changed
            ColorPickerFrame.cancelFunc = Cancelled
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
        RaiseColorPicker()
    end)
    return host
end

local function ProgressBar(parent, label, current, target, x, y, w)
    local host = CreateFrame("Frame", nil, parent)
    host:SetPoint("TOPLEFT", x, y)
    host:SetSize(w or 360, 42)
    local title = Text(host, label, 9, false)
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetTextColor(unpack(C.dim))
    local value = Text(host, "", 9, true)
    value:SetPoint("TOPRIGHT", 0, 0)

    local bar = CreateFrame("StatusBar", nil, host)
    bar:SetPoint("TOPLEFT", 0, -18)
    bar:SetPoint("TOPRIGHT", 0, -18)
    bar:SetHeight(14)
    bar:SetStatusBarTexture(WHITE8)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(C.panel2[1], C.panel2[2], C.panel2[3], 1)

    function host:SetProgress(now, goal, display)
        now = tonumber(now) or 0
        goal = math.max(tonumber(goal) or 1, 1)
        bar:SetMinMaxValues(0, goal)
        bar:SetValue(math.min(now, goal))
        local ratio = math.min(now / goal, 1)
        local rr = C.red[1] + (C.green[1] - C.red[1]) * ratio
        local rg = C.red[2] + (C.green[2] - C.red[2]) * ratio
        local rb = C.red[3] + (C.green[3] - C.red[3]) * ratio
        bar:SetStatusBarColor(rr, rg, rb, 0.92)
        value:SetText(display or string.format("%d / %d", now, goal))
    end
    host:SetProgress(current, target)
    return host
end

local function SignedSeconds(sec)
    if sec == nil then return "—" end
    local sign = sec <= 0 and "-" or "+"
    sec = math.abs(sec)
    return string.format("%s%d:%02d", sign, math.floor(sec / 60), math.floor(sec % 60))
end

local function SafeRunHistory()
    if not MP.RunHistory or not MP.RunHistory.GetRuns then return {} end
    return MP.RunHistory:GetRuns() or {}
end

local function FindRunIndex(runs, id, fallback)
    if id then
        for i, run in ipairs(runs) do
            if run.id == id then return i end
        end
    end
    return math.min(math.max(fallback or 1, 1), math.max(#runs, 1))
end

local function RunLabel(run)
    if not run then return "—" end
    return string.format("%s  +%d  %s  %s", date("%d/%m", run.finishedAt or time()), run.level or 0,
        run.mapName or MP:T("unknown"), FormatMS(run.durationMS))
end

local function SeasonIDs()
    if TomoMod_DataKeys and TomoMod_DataKeys.GetCurrentSeasonIDs then
        return TomoMod_DataKeys.GetCurrentSeasonIDs() or {}
    end
    if C_ChallengeMode and C_ChallengeMode.GetMapTable then
        local ok, maps = pcall(C_ChallengeMode.GetMapTable)
        if ok and type(maps) == "table" then return maps end
    end
    return {}
end

local function SeasonBest(mapID)
    local bestLevel, bestScore, bestDuration, overTime = 0, 0, 0, false
    if C_MythicPlus and C_MythicPlus.GetSeasonBestAffixScoreInfoForMap then
        local ok, affixScores, overall = pcall(C_MythicPlus.GetSeasonBestAffixScoreInfoForMap, mapID)
        if ok then
            bestScore = Num(overall) or 0
            if type(affixScores) == "table" then
                if affixScores.score then affixScores = { affixScores } end
                for _, info in ipairs(affixScores) do
                    if type(info) == "table" then
                        local level = Num(info.level) or 0
                        local score = Num(info.score) or 0
                        if score > bestScore then bestScore = score end
                        if level > bestLevel then
                            bestLevel = level
                            bestDuration = (Num(info.durationSec) or 0) * 1000
                            overTime = Bool(info.overTime) == true
                        end
                    end
                end
            end
        end
    end
    if C_MythicPlus and C_MythicPlus.GetSeasonBestForMap then
        local ok, intime, overtime = pcall(C_MythicPlus.GetSeasonBestForMap, mapID)
        if ok then
            for _, info in ipairs({ intime, overtime }) do
                if type(info) == "table" then
                    local level = Num(info.level) or 0
                    if level > bestLevel then
                        bestLevel = level
                        bestDuration = (Num(info.durationSec) or 0) * 1000
                        overTime = info == overtime
                    end
                end
            end
        end
    end
    return bestLevel, bestScore, bestDuration, overTime
end

local function WeeklyRewardItemLevel(level)
    level = tonumber(level) or 0
    if level <= 0 or not C_MythicPlus then return nil end

    local values = {}
    local function Push(...)
        for i = 1, select('#', ...) do
            local v = select(i, ...)
            if type(v) == "number" and v > 0 then values[#values+1] = v end
        end
    end

    if C_MythicPlus.GetRewardLevelForDifficultyLevel then
        local ok, a, b, c, d = pcall(C_MythicPlus.GetRewardLevelForDifficultyLevel, level)
        if ok then Push(a, b, c, d) end
    end
    if #values == 0 and C_MythicPlus.GetRewardLevelFromKeystoneLevel then
        local ok, a, b, c, d = pcall(C_MythicPlus.GetRewardLevelFromKeystoneLevel, level)
        if ok then Push(a, b, c, d) end
    end
    if #values == 0 then return nil end
    table.sort(values)
    return values[#values]
end

local function CopyTableShallow(src)
    local dst = {}
    if type(src) == "table" then
        for k, v in pairs(src) do dst[k] = v end
    end
    return dst
end

function MP:AttachWeeklyRewardTooltip(frame, activity, vtype, index)
    if not frame then return end

    local data = CopyTableShallow(activity)
    data.type = Num(data.type) or Num(vtype) or 1
    data.index = Num(data.index) or Num(index) or 0
    data.progress = Num(data.progress) or 0
    data.threshold = Num(data.threshold) or 0
    data.level = Num(data.level) or Num(data.bestLevel) or 0

    frame._activityData = data
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        local hub = TomoMod_MythicHub
        if hub and hub.ShowVaultTooltip then
            hub:ShowVaultTooltip(self)
            return
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -3, -6)
        GameTooltip:SetText(MP:T("vault"), unpack(C.text))
        GameTooltip:AddLine(string.format("%d / %d", data.progress, data.threshold), unpack(C.dim))
        if data.level and data.level > 0 then
            GameTooltip:AddLine("+" .. data.level, unpack(C.text))
            local reward = WeeklyRewardItemLevel(data.level)
            if reward then
                GameTooltip:AddLine(string.format(MP:T("weekly_reward_ilvl"), reward), unpack(C.accent))
            end
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function RefreshOpenPage()
    if MP and MP.Frame and MP.Frame:IsShown() then
        MP:SelectPage(MP.page or "dashboard")
    end
end

function MP:HideTrackerStandalonePreview(force)
    if not self._trackerPreviewVisible then return end
    local active = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    if active and not force then return end
    local T = TomoMod_MythicTracker
    if T then
        if T.HideFrame then T:HideFrame()
        elseif T.Frame then T.Frame:Hide() end
    end
    self._trackerPreviewVisible = false
end

function MP:ToggleTrackerStandalonePreview()
    local T = TomoMod_MythicTracker
    if not T then return end
    if self._trackerPreviewVisible then
        self:HideTrackerStandalonePreview(true)
    else
        if T.Preview then T:Preview()
        elseif T.BuildFrame then
            T:BuildFrame()
            if T.Frame then T.Frame:Show() end
        end
        self._trackerPreviewVisible = true
    end
    RefreshOpenPage()
end

local function StatValue(card, value, label, size)
    local v = Text(card, value, size or 24, true)
    v:SetPoint("CENTER", 0, 5)
    local l = Text(card, label, 9, false)
    l:SetPoint("TOP", v, "BOTTOM", 0, -4)
    l:SetTextColor(unpack(C.dim))
end

local function Divider(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetPoint("TOPLEFT", 0, y)
    t:SetPoint("TOPRIGHT", 0, y)
    t:SetHeight(1)
    t:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.8)
end

local function FormatMS(ms)
    ms = tonumber(ms) or 0
    if ms <= 0 then return "--:--" end
    local sec = math.floor(ms / 1000)
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function FormatSec(sec)
    sec = tonumber(sec) or 0
    if sec <= 0 then return "--:--" end
    sec = math.floor(sec)
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function MapName(mapID)
    if not mapID or mapID <= 0 or not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then return MP:T("unknown") end
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if IsSecret(name) or type(name) ~= "string" then return MP:T("unknown") end
    return name
end

local function ScoreNow()
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        return Num(C_ChallengeMode.GetOverallDungeonScore()) or 0
    end
    return 0
end

local function OwnKey()
    if TomoMod_KeySync and TomoMod_KeySync.ReadOwnKeystone then
        local k = TomoMod_KeySync.ReadOwnKeystone()
        if k then return tonumber(k.challengeMapID) or 0, tonumber(k.level) or 0 end
    end
    local mapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID and Num(C_MythicPlus.GetOwnedKeystoneChallengeMapID()) or 0
    local level = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel and Num(C_MythicPlus.GetOwnedKeystoneLevel()) or 0
    return mapID or 0, level or 0
end

local function BlizzardWeekRuns()
    if not C_MythicPlus or not C_MythicPlus.GetRunHistory then return 0 end
    local ok, runs = pcall(C_MythicPlus.GetRunHistory, true, true, true)
    if not ok or type(runs) ~= "table" then return 0 end
    local n = 0
    for _, run in ipairs(runs) do
        if Bool(run.thisWeek) == true and Bool(run.completed) == true then n = n + 1 end
    end
    return n
end

local function BeginPage(key)
    if MP.page == "tracker" and key ~= "tracker" then
        MP:HideTrackerStandalonePreview(false)
    end
    if MP._pageFrame then
        MP._pageFrame:Hide()
        MP._pageFrame:ClearAllPoints()
        MP._pageFrame:SetParent(pageBin)
    end
    local p = CreateFrame("Frame", nil, content)
    p:SetAllPoints(content)
    MP._pageFrame = p
    MP.page = key
    MP:GetDB().ui.lastPage = key
    return p
end

-- ---------------------------------------------------------------------
-- Dashboard
-- ---------------------------------------------------------------------
function MP:BuildDashboard()
    local p = BeginPage("dashboard")
    local y = PageTitle(p, self:T("title"), self:T("subtitle"))
    local innerW = content:GetWidth() - PAGE_PAD * 2
    local gap = 10
    local cardW = (innerW - gap * 3) / 4

    local score = math.floor(ScoreNow() + 0.5)
    local mapID, level = OwnKey()
    local keyText = level > 0 and ("+" .. level .. "  " .. MapName(mapID)) or self:T("no_key")
    local weekRuns = BlizzardWeekRuns()
    local tracked = self.RunHistory and #self.RunHistory:GetRuns() or 0

    local c1 = Card(p, PAGE_PAD, y, cardW, 92); StatValue(c1, tostring(score), self:T("current_score"))
    local c2 = Card(p, PAGE_PAD + cardW + gap, y, cardW, 92); StatValue(c2, keyText, self:T("owned_key"), 11)
    local c3 = Card(p, PAGE_PAD + (cardW + gap) * 2, y, cardW, 92); StatValue(c3, tostring(weekRuns), self:T("weekly_runs"))
    local c4 = Card(p, PAGE_PAD + (cardW + gap) * 3, y, cardW, 92); StatValue(c4, tostring(tracked), self:T("tracked_runs"))
    y = y - 104

    local vault = Card(p, PAGE_PAD, y, innerW, 136, self:T("vault"))
    local vtype = Enum and Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.Activities or 1
    local acts = C_WeeklyRewards and C_WeeklyRewards.GetActivities and C_WeeklyRewards.GetActivities(vtype) or {}
    table.sort(acts, function(a,b) return (Num(a.index) or 99) < (Num(b.index) or 99) end)
    for i=1,3 do
        local a = acts[i]
        local progress = a and Num(a.progress) or 0
        local threshold = a and Num(a.threshold) or 0
        local lvl = a and Num(a.level) or 0
        local complete = threshold > 0 and progress >= threshold
        local slot = Card(vault, 14 + (i-1) * ((innerW-42)/3), -34, (innerW-54)/3, 82)
        slot:SetBackdropBorderColor(complete and C.green[1] or C.border[1], complete and C.green[2] or C.border[2], complete and C.green[3] or C.border[3], 1)
        local a1 = Text(slot, string.format("%d / %d", progress, threshold), 16, true); a1:SetPoint("CENTER", 0, 7)
        local a2 = Text(slot, lvl > 0 and ("+"..lvl) or "—", 9, false); a2:SetPoint("TOP", a1, "BOTTOM", 0, -2); a2:SetTextColor(unpack(C.dim))
        local reward = WeeklyRewardItemLevel(lvl)
        local a3 = Text(slot, reward and string.format(self:T("weekly_reward_ilvl"), reward) or self:T("weekly_reward_ilvl_unknown"), 8, false)
        a3:SetPoint("TOP", a2, "BOTTOM", 0, -3)
        a3:SetTextColor(unpack(reward and C.accent or C.dim))
        self:AttachWeeklyRewardTooltip(slot, a, vtype, i)
    end
    y = y - 148

    local recent = Card(p, PAGE_PAD, y, innerW, 220, self:T("recent_runs"))
    local runs = self.RunHistory and self.RunHistory:GetRuns() or {}
    local ry = -36
    if #runs == 0 then
        local none = Text(recent, self:T("no_data"), 11, false); none:SetPoint("TOPLEFT", 14, ry); none:SetTextColor(unpack(C.dim))
    else
        for i=1, math.min(6, #runs) do
            local r = runs[i]
            local line = Text(recent, string.format("+%d  %s", r.level or 0, r.mapName or self:T("unknown")), 10, true)
            line:SetPoint("TOPLEFT", 14, ry)
            local result = Text(recent, r.onTime and self:T("timed") or self:T("depleted"), 9, false)
            result:SetPoint("TOPRIGHT", -150, ry)
            result:SetTextColor(unpack(r.onTime and C.green or C.red))
            local tm = Text(recent, FormatMS(r.durationMS), 9, false); tm:SetPoint("TOPRIGHT", -14, ry); tm:SetTextColor(unpack(C.dim))
            ry = ry - 31
            if i < math.min(6,#runs) then Divider(recent, ry + 8) end
        end
    end

    Button(p, self:T("detailed_hub"), PAGE_PAD, y - 234, 235, function()
        if TomoMod_MythicPlusLauncher and TomoMod_MythicPlusLauncher.OpenLegacyHub then
            TomoMod_MythicPlusLauncher:OpenLegacyHub()
        end
    end)
    Button(p, self:T("refresh"), PAGE_PAD + 247, y - 234, 120, function() MP:SelectPage("dashboard") end)
end

-- ---------------------------------------------------------------------
-- Tracker configuration
-- ---------------------------------------------------------------------
local TRACKER_COLOR_DEFAULTS = {
    accent={r=0.180,g=0.847,b=0.518}, background={r=0.035,g=0.055,b=0.046}, header={r=0.055,g=0.092,b=0.076},
    text={r=0.88,g=0.90,b=0.89}, forces={r=0.180,g=0.847,b=0.518}, comfort={r=0.180,g=0.847,b=0.518},
    warning={r=0.96,g=0.80,b=0.10}, danger={r=0.88,g=0.22,b=0.22},
}

local function EnsureTrackerColors(db)
    db.colors = type(db.colors) == "table" and db.colors or {}
    for key, def in pairs(TRACKER_COLOR_DEFAULTS) do
        local c = db.colors[key]
        if type(c) ~= "table" then
            c = { r=def.r, g=def.g, b=def.b }
            db.colors[key] = c
        else
            c.r = tonumber(c.r or c[1]) or def.r
            c.g = tonumber(c.g or c[2]) or def.g
            c.b = tonumber(c.b or c[3]) or def.b
        end
    end
    return db.colors
end

local function PreviewPalette(db)
    local colors = EnsureTrackerColors(db)
    if db.useCustomColors then return colors end
    local U = TomoMod_Utils
    local brand = (U and U.BRAND) or {0.180,0.847,0.518}
    return {
        accent={r=brand[1],g=brand[2],b=brand[3]}, background=TRACKER_COLOR_DEFAULTS.background,
        header=TRACKER_COLOR_DEFAULTS.header, text=TRACKER_COLOR_DEFAULTS.text,
        forces={r=brand[1],g=brand[2],b=brand[3]}, comfort={r=brand[1],g=brand[2],b=brand[3]},
        warning=TRACKER_COLOR_DEFAULTS.warning, danger=TRACKER_COLOR_DEFAULTS.danger,
    }
end

function MP:UpdateTrackerPreview()
    local pv = self._trackerPreview
    local db = TomoModDB and TomoModDB.MythicTracker
    if not pv or not db then return end
    local pc = PreviewPalette(db)
    local scale = tonumber(db.fontScale) or 1

    pv.frame:SetBackdropColor(pc.background.r,pc.background.g,pc.background.b,db.showBackground == false and 0 or 0.94)
    pv.frame:SetBackdropBorderColor(pc.accent.r,pc.accent.g,pc.accent.b,db.showBackground == false and 0 or 0.55)
    pv.accent:SetColorTexture(pc.accent.r,pc.accent.g,pc.accent.b,db.showBackground == false and 0 or 1)
    pv.headerBG:SetColorTexture(pc.header.r,pc.header.g,pc.header.b,db.showHeaderBlock == false and 0 or 1)
    pv.dungeon:SetShown(db.showDungeonName == true)
    pv.dungeon:SetTextColor(pc.text.r,pc.text.g,pc.text.b,1)
    pv.level:SetTextColor(pc.accent.r,pc.accent.g,pc.accent.b,1)
    pv.deaths:SetTextColor(pc.danger.r,pc.danger.g,pc.danger.b,1)

    -- The compact preview mirrors the real tracker's information header:
    -- deaths, elapsed timer and keystone level share the top row. The timer
    -- must therefore stay visible for both stacked and inline timer layouts.
    pv.timer:SetShown(db.showTimer ~= false)
    pv.timerText:SetShown(db.showTimer ~= false)
    for i, seg in ipairs(pv.segments) do
        seg:SetShown(db.showTimer ~= false)
        local c
        if db.segmentColors == "brand" then c = pc.comfort
        else c = i == 1 and pc.comfort or (i == 2 and pc.warning or pc.danger) end
        seg:SetStatusBarColor(c.r,c.g,c.b,0.88)
    end
    pv.forces:SetShown(db.showForces ~= false)
    pv.forces:SetStatusBarColor(pc.forces.r,pc.forces.g,pc.forces.b,0.88)

    local showBosses = db.showBosses ~= false and db.objectiveStyle ~= "none"
    for i, row in ipairs(pv.bosses) do
        row:SetShown(showBosses)
        row.name:SetTextColor(pc.text.r,pc.text.g,pc.text.b,i == 1 and 1 or 0.70)
        row.time:SetTextColor(pc.accent.r,pc.accent.g,pc.accent.b,1)
        row.dot:SetShown(db.objectiveStyle == "rows")
        row.dot:SetColorTexture(i == 1 and pc.accent.r or 0.30, i == 1 and pc.accent.g or 0.30, i == 1 and pc.accent.b or 0.30, 1)
    end

    for _, fs in ipairs(pv.fonts) do
        local base = fs._tmBaseSize or 10
        fs:SetFont(FONT, math.max(7, math.floor(base * scale + 0.5)), "")
    end

    -- Reflow the preview from the compact header downwards. The optional
    -- dungeon name gets its own second header line; everything else begins
    -- below it so no text can spill outside the preview frame.
    local headerH = db.showDungeonName == true and 44 or 28
    pv.headerBG:SetHeight(headerH)

    pv.deaths:ClearAllPoints()
    pv.deaths:SetPoint("TOPLEFT", pv.frame, "TOPLEFT", 10, -8)
    pv.level:ClearAllPoints()
    pv.level:SetPoint("TOPRIGHT", pv.frame, "TOPRIGHT", -9, -8)
    pv.timerText:ClearAllPoints()
    pv.timerText:SetPoint("TOP", pv.frame, "TOP", 10, -8)

    pv.dungeon:ClearAllPoints()
    pv.dungeon:SetPoint("TOPLEFT", pv.frame, "TOPLEFT", 10, -27)

    local nextY = headerH + 7
    if db.showTimer ~= false then
        pv.timer:ClearAllPoints()
        pv.timer:SetPoint("TOPLEFT", pv.frame, "TOPLEFT", 10, -nextY)
        nextY = nextY + 22
    end
    if db.showForces ~= false then
        pv.forces:ClearAllPoints()
        pv.forces:SetPoint("TOPLEFT", pv.frame, "TOPLEFT", 10, -nextY)
        nextY = nextY + 22
    end
    if showBosses then
        for _, row in ipairs(pv.bosses) do
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", pv.frame, "TOPLEFT", 10, -nextY)
            nextY = nextY + 20
        end
    end
    pv.frame:SetHeight(math.max(90, nextY + 7))
end

local function BuildTrackerPreview(parent)
    local host = CreateFrame("Frame", nil, parent)
    host:SetPoint("TOPLEFT", 18, -42)
    host:SetPoint("BOTTOMRIGHT", -18, 16)

    local f = CreateFrame("Frame", nil, host, "BackdropTemplate")
    f:SetSize(300,210)
    f:SetPoint("CENTER",0,-4)
    Backdrop(f,C.panel,C.border)
    local accent=f:CreateTexture(nil,"ARTWORK"); accent:SetPoint("TOPLEFT"); accent:SetPoint("BOTTOMLEFT"); accent:SetWidth(3)
    local headerBG=f:CreateTexture(nil,"BACKGROUND"); headerBG:SetPoint("TOPLEFT",3,0); headerBG:SetPoint("TOPRIGHT",0,0); headerBG:SetHeight(32)

    local fonts={}
    local function PF(text,size)
        local fs=Text(f,text,size,false); fs._tmBaseSize=size; fonts[#fonts+1]=fs; return fs
    end
    -- Header preview: same information order as the real tracker. Keep the
    -- three runtime values on one line and reserve a second line only for
    -- the optional dungeon name. UpdateTrackerPreview owns their final
    -- anchors so the layout can react to the toggles live.
    local deaths=PF(MP:T("h_deaths").." 3  (+0:15)",8); deaths:SetPoint("TOPLEFT",10,-8)
    local timerText=PF("19:42 / 30:00  -10:18",9); timerText:SetPoint("TOP",10,-8)
    local level=PF("+12",11); level:SetPoint("TOPRIGHT",-9,-8)
    local dungeon=PF("Ara-Kara, City of Echoes",9); dungeon:SetPoint("TOPLEFT",10,-27)

    local timer=CreateFrame("Frame",nil,f); timer:SetPoint("TOPLEFT",10,-35); timer:SetSize(280,18)
    local segments={}
    local widths={150,70,56}
    local last
    for i=1,3 do
        local seg=CreateFrame("StatusBar",nil,timer); seg:SetStatusBarTexture(WHITE8); seg:SetMinMaxValues(0,1); seg:SetValue(i==1 and 0.72 or 0.18); seg:SetSize(widths[i],16)
        if last then seg:SetPoint("LEFT",last,"RIGHT",2,0) else seg:SetPoint("LEFT",0,0) end
        local label=Text(seg,"+"..(4-i),8,true); label:SetPoint("CENTER"); label._tmBaseSize=8; fonts[#fonts+1]=label
        segments[i]=seg; last=seg
    end
    local forces=CreateFrame("StatusBar",nil,f); forces:SetStatusBarTexture(WHITE8); forces:SetMinMaxValues(0,1); forces:SetValue(0.73); forces:SetPoint("TOPLEFT",10,-57); forces:SetSize(280,16)
    local fl=Text(forces,"Forces 73%",8,true); fl:SetPoint("CENTER"); fl._tmBaseSize=8; fonts[#fonts+1]=fl

    local bosses={}
    local names={"Avanoxx","Anub'zekt","Ki'katal"}
    for i=1,3 do
        local row=CreateFrame("Frame",nil,f); row:SetPoint("TOPLEFT",10,-79-(i-1)*20); row:SetSize(280,18)
        local dot=row:CreateTexture(nil,"ARTWORK"); dot:SetSize(6,6); dot:SetPoint("LEFT",0,0)
        local name=Text(row,names[i],9,false); name:SetPoint("LEFT",dot,"RIGHT",6,0); name._tmBaseSize=9; fonts[#fonts+1]=name
        local tm=Text(row,i==1 and "6:13" or "—",8,false); tm:SetPoint("RIGHT",0,0); tm._tmBaseSize=8; fonts[#fonts+1]=tm
        row.dot=dot; row.name=name; row.time=tm; bosses[i]=row
    end

    MP._trackerPreview={frame=f,accent=accent,headerBG=headerBG,dungeon=dungeon,deaths=deaths,level=level,timer=timer,timerText=timerText,segments=segments,forces=forces,bosses=bosses,fonts=fonts}
    MP:UpdateTrackerPreview()
    return host
end

local function TrackerRefresh()
    local T = TomoMod_MythicTracker
    if T then
        if T.ResolvePreset then T:ResolvePreset() end
        if T.RefreshStyle then T:RefreshStyle()
        elseif T.LayoutFrame then T:LayoutFrame() end
    end
    MP:UpdateTrackerPreview()
end

function MP:BeginTrackerEditMode()
    local active = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
    if active then
        print("|cff2ed884TomoMod|r Mythic+ : " .. self:T("tracker_edit_blocked"))
        return
    end
    local T = TomoMod_MythicTracker
    local db = TomoModDB and TomoModDB.MythicTracker
    if not T or not db then return end
    if not T.Frame and T.BuildFrame then T:BuildFrame() end
    if not T.Frame then return end

    self._trackerEditState = {
        locked=db.locked,
        anchor=db.position and db.position.anchor or "CENTER",
        relTo=db.position and db.position.relTo or "CENTER",
        x=db.position and db.position.x or 0,
        y=db.position and db.position.y or 0,
    }
    self:Hide()
    if T.Preview then T:Preview() end
    if T.SetMovable then T:SetMovable(true) end

    local bar=self._trackerEditBar
    if not bar then
        bar=CreateFrame("Frame","TomoMod_MythicPlusTrackerEditBar",UIParent,"BackdropTemplate")
        self._trackerEditBar=bar
        bar:SetSize(520,54); bar:SetPoint("TOP",UIParent,"TOP",0,-42); bar:SetFrameStrata("FULLSCREEN_DIALOG"); bar:SetFrameLevel(500); Backdrop(bar,C.bg,C.accent)
        local title=Text(bar,self:T("tracker_edit_title"),11,true); title:SetPoint("LEFT",14,0)
        Button(bar,self:T("tracker_edit_reset"),230,-13,110,function() if TomoMod_MythicTracker and TomoMod_MythicTracker.ResetPosition then TomoMod_MythicTracker:ResetPosition() end end)
        Button(bar,self:T("tracker_edit_cancel"),346,-13,76,function() MP:EndTrackerEditMode(true) end)
        Button(bar,self:T("tracker_edit_done"),428,-13,76,function() MP:EndTrackerEditMode(false) end)
    end
    bar:Show()
end

function MP:EndTrackerEditMode(cancel)
    local state=self._trackerEditState
    local T=TomoMod_MythicTracker
    local db=TomoModDB and TomoModDB.MythicTracker
    if not state or not T or not db then return end
    if cancel then
        db.position=db.position or {}
        db.position.anchor=state.anchor; db.position.relTo=state.relTo; db.position.x=state.x; db.position.y=state.y
        if T.Frame then T.Frame:ClearAllPoints(); T.Frame:SetPoint(state.anchor,UIParent,state.relTo,state.x,state.y) end
    end
    if T.SetMovable then T:SetMovable(not state.locked) end
    db.locked=state.locked
    if T.HideFrame then T:HideFrame() end
    if self._trackerEditBar then self._trackerEditBar:Hide() end
    self._trackerEditState=nil
    self:Open("tracker")
end

function MP:BuildTracker()
    local p = BeginPage("tracker")
    local y = PageTitle(p, self:T("tracker"), "MythicTracker")
    local db = TomoModDB and TomoModDB.MythicTracker
    if not db then return end
    EnsureTrackerColors(db)

    local innerW=content:GetWidth()-PAGE_PAD*2
    local gap=10
    local leftW=420
    local rightX=PAGE_PAD+leftW+gap
    local rightW=innerW-leftW-gap

    local card = Card(p, PAGE_PAD, y, leftW, 646, self:T("tracker"))
    local cy = -36
    Check(card, self:T("tracker_enable"), db.enabled, 14, cy, function(v) db.enabled=v; TrackerRefresh() end, 380); cy=cy-28

    local pl = Text(card, self:T("preset"), 8, false); pl:SetPoint("TOPLEFT",14,cy); pl:SetTextColor(unpack(C.dim))
    Button(card, self:T("preset_panel"), 14, cy-16, 105, function() if TomoMod_MythicTracker and TomoMod_MythicTracker.ApplyPreset then TomoMod_MythicTracker:ApplyPreset("panel"); TrackerRefresh(); MP:SelectPage("tracker") end end)
    Button(card, self:T("preset_hud"), 127, cy-16, 105, function() if TomoMod_MythicTracker and TomoMod_MythicTracker.ApplyPreset then TomoMod_MythicTracker:ApplyPreset("hud"); TrackerRefresh(); MP:SelectPage("tracker") end end)
    Button(card, self:T("preset_minimal"), 240, cy-16, 105, function() if TomoMod_MythicTracker and TomoMod_MythicTracker.ApplyPreset then TomoMod_MythicTracker:ApplyPreset("minimal"); TrackerRefresh(); MP:SelectPage("tracker") end end)
    cy=cy-50

    Check(card,self:T("tracker_background"),db.showBackground~=false,14,cy,function(v) db.showBackground=v; TrackerRefresh() end,190)
    Check(card,self:T("tracker_header"),db.showHeaderBlock~=false,210,cy,function(v) db.showHeaderBlock=v; TrackerRefresh() end,190); cy=cy-27
    Check(card,self:T("tracker_dungeon"),db.showDungeonName==true,14,cy,function(v) db.showDungeonName=v; TrackerRefresh() end,190); cy=cy-45

    Segmented(card,self:T("tracker_objectives"),{
        {value="rows",text=self:T("tracker_objectives_rows")},{value="text",text=self:T("tracker_objectives_text")},{value="none",text=self:T("tracker_objectives_none")},
    },db.objectiveStyle or "rows",14,cy,370,function(v) db.objectiveStyle=v; TrackerRefresh() end); cy=cy-48
    Segmented(card,self:T("tracker_timer_layout"),{
        {value="stacked",text=self:T("tracker_timer_stacked")},{value="inline",text=self:T("tracker_timer_inline")},
    },db.timerLayout or "stacked",14,cy,370,function(v) db.timerLayout=v; TrackerRefresh() end); cy=cy-48
    Segmented(card,self:T("tracker_segment_colors"),{
        {value="palier",text=self:T("tracker_segment_tiers")},{value="brand",text=self:T("tracker_segment_brand")},
    },db.segmentColors or "palier",14,cy,370,function(v) db.segmentColors=v; TrackerRefresh() end); cy=cy-48

    Check(card,self:T("tracker_timer"),db.showTimer,14,cy,function(v) db.showTimer=v; TrackerRefresh() end,190)
    Check(card,self:T("tracker_forces"),db.showForces,210,cy,function(v) db.showForces=v; TrackerRefresh() end,190); cy=cy-27
    Check(card,self:T("tracker_bosses"),db.showBosses,14,cy,function(v) db.showBosses=v; TrackerRefresh() end,190)
    Check(card,self:T("tracker_hide_blizzard"),db.hideBlizzard,210,cy,function(v) db.hideBlizzard=v; TrackerRefresh() end,190); cy=cy-27
    Check(card,self:T("tracker_splits"),db.splitsEnabled,14,cy,function(v) db.splitsEnabled=v; TrackerRefresh() end,190)
    Check(card,self:T("tracker_checkpoints"),db.checkpointsEnabled,210,cy,function(v) db.checkpointsEnabled=v; TrackerRefresh() end,190); cy=cy-27
    Check(card,self:T("tracker_lock"),db.locked,14,cy,function(v) db.locked=v; if TomoMod_MythicTracker and TomoMod_MythicTracker.SetMovable then TomoMod_MythicTracker:SetMovable(not v) end end,190); cy=cy-40

    Slider(card,self:T("tracker_font_scale"),db.fontScale or 1,0.7,1.6,0.05,14,cy,370,function(v) db.fontScale=v; TrackerRefresh() end,"%.2f"); cy=cy-48
    Slider(card,self:T("tracker_scale"),db.scale or 1,0.5,2.0,0.05,14,cy,370,function(v) db.scale=v; if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then TomoMod_MythicTracker.Frame:SetScale(v) end end,"%.2f"); cy=cy-48
    Slider(card,self:T("tracker_alpha"),db.alpha or 1,0.2,1.0,0.05,14,cy,370,function(v) db.alpha=v; if TomoMod_MythicTracker and TomoMod_MythicTracker.Frame then TomoMod_MythicTracker.Frame:SetAlpha(v) end end,"%.2f"); cy=cy-52
    local bw = 122
    local bgap = 8
    Button(card, MP._trackerPreviewVisible and self:T("tracker_preview_button_hide") or self:T("tracker_preview_button_show"), 14, cy, bw, function() MP:ToggleTrackerStandalonePreview() end)
    Button(card,self:T("tracker_editmode"),14+bw+bgap,cy,bw,function() MP:BeginTrackerEditMode() end)
    Button(card,self:T("tracker_reset_short"),14+(bw+bgap)*2,cy,bw,function()
        MP:HideTrackerStandalonePreview(true)
        if TomoMod_MythicTracker and TomoMod_MythicTracker.ResetPosition then TomoMod_MythicTracker:ResetPosition() end
        RefreshOpenPage()
    end)

    local previewCard=Card(p,rightX,y,rightW,338,self:T("tracker_live_preview"))
    BuildTrackerPreview(previewCard)

    local colorCard=Card(p,rightX,y-350,rightW,278,self:T("tracker_colors"))
    Check(colorCard,self:T("tracker_custom_colors"),db.useCustomColors==true,14,-36,function(v) db.useCustomColors=v; TrackerRefresh() end,rightW-28)
    local colors=EnsureTrackerColors(db)
    local function Changed() db.useCustomColors=true; TrackerRefresh() end
    local cw=(rightW-42)/2
    ColorPicker(colorCard,self:T("tracker_color_accent"),colors.accent,14,-70,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_background"),colors.background,28+cw,-70,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_header"),colors.header,14,-100,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_text"),colors.text,28+cw,-100,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_forces"),colors.forces,14,-130,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_comfort"),colors.comfort,28+cw,-130,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_warning"),colors.warning,14,-160,cw,Changed)
    ColorPicker(colorCard,self:T("tracker_color_danger"),colors.danger,28+cw,-160,cw,Changed)
    Button(colorCard,self:T("tracker_colors_reset"),14,-202,170,function()
        db.colors={}
        EnsureTrackerColors(db)
        db.useCustomColors=false
        TrackerRefresh()
        MP:SelectPage("tracker")
    end)
end

-- ---------------------------------------------------------------------
-- TomoScore configuration
-- ---------------------------------------------------------------------
function MP:BuildScore()
    local p = BeginPage("score")
    local y = PageTitle(p, self:T("score"), "End-of-run scoreboard")
    local db = TomoModDB and TomoModDB.TomoScore
    if not db then return end
    local card = Card(p,PAGE_PAD,y,content:GetWidth()-PAGE_PAD*2,340,self:T("score"))
    local cy=-40
    Check(card,self:T("score_enable"),db.enabled,14,cy,function(v) db.enabled=v end); cy=cy-32
    Check(card,self:T("score_auto"),db.autoShowMPlus,14,cy,function(v) db.autoShowMPlus=v end); cy=cy-58
    Slider(card,self:T("score_scale"),db.scale or 1,0.5,2.0,0.05,14,cy,330,function(v) db.scale=v; if TomoMod_TomoScore and TomoMod_TomoScore.SB then TomoMod_TomoScore.SB:SetScale(v) end end,"%.2f")
    Slider(card,self:T("score_alpha"),db.alpha or 1,0.2,1.0,0.05,410,cy,330,function(v) db.alpha=v; if TomoMod_TomoScore and TomoMod_TomoScore.SB then TomoMod_TomoScore.SB:SetAlpha(v) end end,"%.2f")
    cy=cy-72
    Button(card,self:T("score_preview"),14,cy,180,function() if TomoMod_TomoScore and TomoMod_TomoScore.ShowPreview then TomoMod_TomoScore:ShowPreview() end end)
    Button(card,self:T("score_reset"),206,cy,190,function() if TomoMod_TomoScore and TomoMod_TomoScore.ResetPosition then TomoMod_TomoScore:ResetPosition() end end)
end

-- ---------------------------------------------------------------------
-- Keys
-- ---------------------------------------------------------------------
function MP:BuildKeys()
    local p = BeginPage("keys")
    local y = PageTitle(p, self:T("keys"), "KeySync")
    local innerW=content:GetWidth()-PAGE_PAD*2
    local mapID,level=OwnKey()
    local own=Card(p,PAGE_PAD,y,innerW,82,self:T("own_key"))
    local kt=Text(own,level>0 and ("+"..level.."  "..MapName(mapID)) or self:T("no_key"),18,true); kt:SetPoint("LEFT",16,-8)
    y=y-94

    local party=Card(p,PAGE_PAD,y,innerW,330,self:T("party_keys"))
    local rowY=-38
    if not IsInGroup() then
        local t=Text(party,self:T("not_grouped"),10,false); t:SetPoint("TOPLEFT",14,rowY); t:SetTextColor(unpack(C.dim))
    else
        local count=0
        local function Row(unit)
            local name=UnitName(unit)
            local info=TomoMod_KeySync and TomoMod_KeySync.GetKeystoneInfo and TomoMod_KeySync.GetKeystoneInfo(unit)
            if not name then return end
            count=count+1
            local txt=Text(party,name,10,true); txt:SetPoint("TOPLEFT",14,rowY)
            local kv
            if info and (tonumber(info.level) or 0)>0 then
                kv="+"..(tonumber(info.level) or 0).."  "..MapName(tonumber(info.challengeMapID or info.mythicPlusMapID) or 0)
            else kv="—" end
            local v=Text(party,kv,10,false); v:SetPoint("TOPRIGHT",-14,rowY); v:SetTextColor(unpack(C.dim))
            rowY=rowY-30
        end
        Row("player")
        for i=1,4 do if UnitExists("party"..i) then Row("party"..i) end end
        if count==0 then local t=Text(party,self:T("no_party_keys"),10,false); t:SetPoint("TOPLEFT",14,rowY); t:SetTextColor(unpack(C.dim)) end
    end
    Button(party,self:T("request_keys"),14,-284,175,function() if TomoMod_KeySync and TomoMod_KeySync.RequestKeystoneDataFromParty then TomoMod_KeySync.RequestKeystoneDataFromParty(); C_Timer.After(1,function() if MP.Frame and MP.Frame:IsShown() then MP:SelectPage("keys") end end) end end)
    Button(party,self:T("roulette"),201,-284,165,function() if TomoMod_MythicKeys and TomoMod_MythicKeys.ShowKeyRoulette then TomoMod_MythicKeys:ShowKeyRoulette() end end)
    Button(party,self:T("keys_chat"),378,-284,175,function() if TomoMod_MythicKeys and TomoMod_MythicKeys.SendKeysToChat then TomoMod_MythicKeys:SendKeysToChat() end end)
end

-- ---------------------------------------------------------------------
-- Run history
-- ---------------------------------------------------------------------
function MP:BuildHistory()
    local p=BeginPage("history")
    local y=PageTitle(p,self:T("history"),"TomoMod local history")
    if not self:GetDB().modules.runHistory then
        local t=Text(p,self:T("module_disabled"),11,false); t:SetPoint("TOPLEFT",PAGE_PAD,y); t:SetTextColor(unpack(C.dim)); return
    end
    local card=Card(p,PAGE_PAD,y,content:GetWidth()-PAGE_PAD*2,590,self:T("history"))
    local cols={ {self:T("h_date"),14}, {self:T("h_dungeon"),105}, {self:T("h_level"),390}, {self:T("h_result"),465}, {self:T("h_time"),575}, {self:T("h_deaths"),650}, {self:T("h_score"),725} }
    for _,c in ipairs(cols) do local t=Text(card,c[1],8,true); t:SetPoint("TOPLEFT",c[2],-35); t:SetTextColor(unpack(C.dim)) end
    Divider(card,-55)
    local runs=self.RunHistory and self.RunHistory:GetRuns() or {}
    local ry=-68
    if #runs==0 then local t=Text(card,self:T("no_data"),10,false); t:SetPoint("TOPLEFT",14,ry); t:SetTextColor(unpack(C.dim)); return end
    for i=1,math.min(16,#runs) do
        local r=runs[i]
        local dt=date("%d/%m %H:%M",r.finishedAt or time())
        local vals={
            {dt,14,C.dim}, {r.mapName or self:T("unknown"),105,C.text}, {"+"..(r.level or 0),390,C.text},
            {r.onTime and self:T("timed") or self:T("depleted"),465,r.onTime and C.green or C.red},
            {FormatMS(r.durationMS),575,C.dim}, {tostring(r.deaths or 0),650,C.dim}, {r.scoreGain and r.scoreGain>0 and ("+"..math.floor(r.scoreGain+0.5)) or "—",725,C.dim},
        }
        for _,v in ipairs(vals) do local t=Text(card,v[1],9,false); t:SetPoint("TOPLEFT",v[2],ry); t:SetTextColor(unpack(v[3])) end
        ry=ry-31
        if i<math.min(16,#runs) then Divider(card,ry+9) end
    end
    local cap=Text(card,self:T("history_cap"),8,false); cap:SetPoint("BOTTOMLEFT",14,10); cap:SetTextColor(unpack(C.dim))
end

-- ---------------------------------------------------------------------
-- Statistics
-- ---------------------------------------------------------------------
function MP:BuildStatistics()
    local p=BeginPage("statistics")
    local y=PageTitle(p,self:T("statistics"),self:T("season"))
    if not self:GetDB().modules.statistics then
        local t=Text(p,self:T("module_disabled"),11,false); t:SetPoint("TOPLEFT",PAGE_PAD,y); t:SetTextColor(unpack(C.dim)); return
    end
    local s=self.RunHistory and self.RunHistory:GetStats() or {total=0,timed=0,depleted=0,rate=0,bestLevel=0,averageLevel=0,scoreGain=0,thisWeek=0,byDungeon={}}
    local innerW=content:GetWidth()-PAGE_PAD*2; local gap=8; local w=(innerW-gap*3)/4
    local cards={
        {s.total,self:T("stat_total")},{s.timed,self:T("stat_timed")},{string.format("%.0f%%",s.rate),self:T("stat_rate")},{"+"..s.bestLevel,self:T("stat_best")},
        {string.format("%.1f",s.averageLevel),self:T("stat_average")},{math.floor(s.scoreGain+0.5),self:T("stat_score")},{s.thisWeek,self:T("stat_week")},{s.depleted,self:T("stat_depleted")},
    }
    for i,d in ipairs(cards) do local row=math.floor((i-1)/4); local col=(i-1)%4; local c=Card(p,PAGE_PAD+col*(w+gap),y-row*82,w,72); StatValue(c,tostring(d[1]),d[2],20) end
    y=y-166

    local runs=SafeRunHistory()
    local compareW=520
    local cc=Card(p,PAGE_PAD,y,compareW,430,self:T("compare"))
    if #runs < 2 then
        local none=Text(cc,self:T("no_data"),10,false); none:SetPoint("TOPLEFT",14,-40); none:SetTextColor(unpack(C.dim))
    else
        local ui=self:GetDB().ui
        local ia=FindRunIndex(runs,ui.compareAId,math.min(2,#runs))
        local ib=FindRunIndex(runs,ui.compareBId,1)
        if ia==ib then ia=(ib==1 and 2 or 1) end
        local a,b=runs[ia],runs[ib]
        ui.compareAId=a and a.id or nil; ui.compareBId=b and b.id or nil

        local function Shift(which,delta)
            local key=which=="a" and "compareAId" or "compareBId"
            local current=FindRunIndex(runs,ui[key],1)
            current=((current-1+delta)%#runs)+1
            ui[key]=runs[current].id
            MP:SelectPage("statistics")
        end
        local la=Text(cc,self:T("compare_run_a"),8,true); la:SetPoint("TOPLEFT",14,-36); la:SetTextColor(unpack(C.dim))
        Button(cc,"<",14,-52,28,function() Shift("a",-1) end); local at=Text(cc,RunLabel(a),8,false); at:SetPoint("LEFT",50,-66); at:SetWidth(395); at:SetJustifyH("LEFT")
        Button(cc,">",474,-52,28,function() Shift("a",1) end)
        local lb=Text(cc,self:T("compare_run_b"),8,true); lb:SetPoint("TOPLEFT",14,-86); lb:SetTextColor(unpack(C.dim))
        Button(cc,"<",14,-102,28,function() Shift("b",-1) end); local bt=Text(cc,RunLabel(b),8,false); bt:SetPoint("LEFT",50,-116); bt:SetWidth(395); bt:SetJustifyH("LEFT")
        Button(cc,">",474,-102,28,function() Shift("b",1) end)
        Button(cc,self:T("compare_swap"),14,-136,120,function() ui.compareAId,ui.compareBId=ui.compareBId,ui.compareAId; MP:SelectPage("statistics") end)

        if a.mapID~=b.mapID then local warn=Text(cc,self:T("compare_different"),8,false); warn:SetPoint("TOPLEFT",146,-141); warn:SetWidth(352); warn:SetWordWrap(true); warn:SetTextColor(unpack(C.yellow)) end
        local hy=-180
        local headers={{self:T("compare_run_a"),265},{self:T("compare_run_b"),365},{self:T("compare_delta"),465}}
        for _,h in ipairs(headers) do local t=Text(cc,h[1],8,true); t:SetPoint("TOPRIGHT",h[2],hy); t:SetTextColor(unpack(C.dim)) end
        hy=hy-22
        local function Row(label,av,bv,delta)
            local l=Text(cc,label,8,false); l:SetPoint("TOPLEFT",14,hy)
            local ta=Text(cc,av or "—",8,false); ta:SetPoint("TOPRIGHT",265,hy)
            local tb=Text(cc,bv or "—",8,false); tb:SetPoint("TOPRIGHT",365,hy)
            local td=Text(cc,delta or "—",8,true); td:SetPoint("TOPRIGHT",465,hy); td:SetTextColor(unpack(C.dim))
            hy=hy-24
        end
        Row(self:T("h_level"),"+"..(a.level or 0),"+"..(b.level or 0),string.format("%+d",(b.level or 0)-(a.level or 0)))
        Row(self:T("h_time"),FormatMS(a.durationMS),FormatMS(b.durationMS),SignedSeconds(((b.durationMS or 0)-(a.durationMS or 0))/1000))
        Row(self:T("h_deaths"),tostring(a.deaths or 0),tostring(b.deaths or 0),string.format("%+d",(b.deaths or 0)-(a.deaths or 0)))
        local as=a.splits or {}; local bs=b.splits or {}
        Row(self:T("compare_forces"),FormatSec(as.forcesDone),FormatSec(bs.forcesDone),as.forcesDone and bs.forcesDone and SignedSeconds(bs.forcesDone-as.forcesDone) or "—")
        local ab=as.bosses or {}; local bb=bs.bosses or {}
        for i=1,math.min(4,math.max(#ab,#bb)) do
            local ar,br=ab[i],bb[i]
            local label=(ar and ar.name) or (br and br.name) or ("Boss "..i)
            Row(label,ar and FormatSec(ar.time) or "—",br and FormatSec(br.time) or "—",ar and br and ar.time and br.time and SignedSeconds(br.time-ar.time) or "—")
        end
    end

    local dx=PAGE_PAD+compareW+10
    local dw=innerW-compareW-10
    local dc=Card(p,dx,y,dw,430,self:T("dungeon_stats"))
    local list={}; for _,d in pairs(s.byDungeon or {}) do list[#list+1]=d end
    table.sort(list,function(a,b) if a.total==b.total then return (a.name or "")<(b.name or "") end return a.total>b.total end)
    local ry=-38
    if #list==0 then local t=Text(dc,self:T("no_data"),10,false); t:SetPoint("TOPLEFT",14,ry); t:SetTextColor(unpack(C.dim))
    else
        for i=1,math.min(12,#list) do
            local d=list[i]; local rate=d.total>0 and (d.timed/d.total*100) or 0; local avg=d.total>0 and (d.levelTotal/d.total) or 0
            local n=Text(dc,d.name or self:T("unknown"),9,true); n:SetPoint("TOPLEFT",14,ry); n:SetWidth(dw-28); n:SetJustifyH("LEFT")
            local info=Text(dc,string.format("%d %s   %.0f%%   +%d   avg %.1f",d.total,self:T("runs"),rate,d.bestLevel or 0,avg),8,false); info:SetPoint("TOPLEFT",14,ry-14); info:SetTextColor(unpack(C.dim))
            ry=ry-32
        end
    end
end

-- ---------------------------------------------------------------------
-- Weekly Planner
-- ---------------------------------------------------------------------
function MP:BuildWeeklyPlanner()
    local p=BeginPage("weekly")
    local y=PageTitle(p,self:T("weekly_planner"),self:T("week"))
    local innerW=content:GetWidth()-PAGE_PAD*2
    local vtype=Enum and Enum.WeeklyRewardChestThresholdType and (Enum.WeeklyRewardChestThresholdType.Activities or Enum.WeeklyRewardChestThresholdType.MythicPlus) or 1
    local acts=C_WeeklyRewards and C_WeeklyRewards.GetActivities and C_WeeklyRewards.GetActivities(vtype) or {}
    table.sort(acts,function(a,b) return (Num(a.index) or 99)<(Num(b.index) or 99) end)
    local gap=10; local cw=(innerW-gap*2)/3; local nextRemaining=nil
    for i=1,3 do
        local a=acts[i] or {}; local progress=Num(a.progress) or 0; local threshold=Num(a.threshold) or 0; local level=Num(a.level) or 0
        local complete=threshold>0 and progress>=threshold; local remaining=math.max(threshold-progress,0)
        if not complete and not nextRemaining then nextRemaining=remaining end
        local c=Card(p,PAGE_PAD+(i-1)*(cw+gap),y,cw,150,string.format(self:T("weekly_slot"),i))
        local main=Text(c,string.format("%d / %d",progress,threshold),22,true); main:SetPoint("TOP",0,-42); main:SetTextColor(unpack(complete and C.green or C.text))
        local lvl=Text(c,level>0 and ("+"..level) or "—",10,false); lvl:SetPoint("TOP",main,"BOTTOM",0,-4); lvl:SetTextColor(unpack(C.dim))
        local reward = WeeklyRewardItemLevel(level)
        local ilvl=Text(c,reward and string.format(self:T("weekly_reward_ilvl"), reward) or self:T("weekly_reward_ilvl_unknown"),9,false); ilvl:SetPoint("TOP",lvl,"BOTTOM",0,-4); ilvl:SetTextColor(unpack(reward and C.accent or C.dim))
        local st=Text(c,complete and self:T("weekly_complete") or (self:T("weekly_remaining").." : "..remaining),9,true); st:SetPoint("BOTTOM",0,16); st:SetTextColor(unpack(complete and C.green or C.yellow))
        self:AttachWeeklyRewardTooltip(c, a, vtype, i)
    end
    y=y-165

    local mapID,keyLevel=OwnKey(); local best=0
    if C_MythicPlus and C_MythicPlus.GetRunHistory then
        local ok,runs=pcall(C_MythicPlus.GetRunHistory,false,false,true)
        if ok and type(runs)=="table" then for _,r in ipairs(runs) do if Bool(r.thisWeek)==true and Bool(r.completed)==true then best=math.max(best,Num(r.level) or 0) end end end
    end
    local info=Card(p,PAGE_PAD,y,innerW,180,self:T("weekly_recommendation"))
    local k1=Text(info,self:T("weekly_current_key"),9,false); k1:SetPoint("TOPLEFT",14,-42); k1:SetTextColor(unpack(C.dim))
    local kv=Text(info,keyLevel>0 and ("+"..keyLevel.."  "..MapName(mapID)) or self:T("no_key"),13,true); kv:SetPoint("TOPLEFT",180,-39)
    local b1=Text(info,self:T("weekly_best"),9,false); b1:SetPoint("TOPLEFT",14,-76); b1:SetTextColor(unpack(C.dim))
    local bv=Text(info,best>0 and ("+"..best) or "—",13,true); bv:SetPoint("TOPLEFT",180,-73)
    local rec=Text(info,nextRemaining and string.format(self:T("weekly_runs_needed"),nextRemaining) or self:T("weekly_all_done"),11,true); rec:SetPoint("TOPLEFT",14,-118); rec:SetTextColor(unpack(nextRemaining and C.yellow or C.green))
end

-- ---------------------------------------------------------------------
-- Score Planner
-- ---------------------------------------------------------------------
function MP:BuildScorePlanner()
    local p=BeginPage("scoreplanner")
    local y=PageTitle(p,self:T("score_planner"),self:T("season"))
    local innerW=content:GetWidth()-PAGE_PAD*2
    local card=Card(p,PAGE_PAD,y,innerW,560,self:T("score_planner"))
    local note=Text(card,self:T("score_estimate_note"),9,false); note:SetPoint("TOPLEFT",14,-34); note:SetWidth(innerW-28); note:SetWordWrap(true); note:SetTextColor(unpack(C.dim))
    local rows={}; local maxLevel=0
    for _,mapID in ipairs(SeasonIDs()) do
        local level,score,duration,over=SeasonBest(mapID); maxLevel=math.max(maxLevel,level)
        rows[#rows+1]={mapID=mapID,name=MapName(mapID),level=level,score=score,duration=duration,over=over}
    end
    table.sort(rows,function(a,b) if a.level==b.level then return a.score<b.score end return a.level<b.level end)
    local headers={{self:T("h_dungeon"),14},{self:T("score_current"),410},{self:T("score_target"),610},{self:T("score_est_gain"),760},{self:T("score_potential"),900}}
    for _,h in ipairs(headers) do local t=Text(card,h[1],9,true); t:SetPoint("TOPLEFT",h[2],-78); t:SetTextColor(unpack(C.dim)) end
    Divider(card,-102); local ry=-118
    for i=1,math.min(12,#rows) do
        local r=rows[i]; local target=math.max(2,(r.level or 0)+1); local gap=(r.level or 0)==0 and 99 or (maxLevel-(r.level or 0))
        local potential=gap>=2 and self:T("score_potential_high") or (gap==1 and self:T("score_potential_medium") or self:T("score_potential_low"))
        local potColor=gap>=2 and C.green or (gap==1 and C.yellow or C.dim)
        local current=(r.level or 0)>0 and string.format("+%d  %.0f",r.level,r.score or 0) or self:T("score_new")
        local vals={{r.name,14,C.text},{current,410,C.dim},{"+"..target,610,C.text},{(r.level or 0)>0 and "~+5" or self:T("score_new"),760,C.dim},{potential,900,potColor}}
        for _,v in ipairs(vals) do local t=Text(card,v[1],10,false); t:SetPoint("TOPLEFT",v[2],ry); t:SetTextColor(unpack(v[3])) end
        ry=ry-36; if i<math.min(12,#rows) then Divider(card,ry+11) end
    end
end

-- ---------------------------------------------------------------------
-- Level analysis
-- ---------------------------------------------------------------------
function MP:BuildLevelAnalysis()
    local p=BeginPage("analysis")
    local y=PageTitle(p,self:T("level_analysis"),self:T("season"))
    local stats=self.RunHistory and self.RunHistory:GetStats() or {byLevel={},comfortLevel=0}
    local innerW=content:GetWidth()-PAGE_PAD*2
    local comfort=Card(p,PAGE_PAD,y,innerW,88,self:T("analysis_comfort"))
    local cv=Text(comfort,(stats.comfortLevel or 0)>0 and ("+"..stats.comfortLevel) or "—",24,true); cv:SetPoint("LEFT",18,-6); cv:SetTextColor(unpack(C.accent))
    local cd=Text(comfort,self:T("analysis_comfort_desc"),9,false); cd:SetPoint("LEFT",cv,"RIGHT",24,0); cd:SetWidth(innerW-120); cd:SetWordWrap(true); cd:SetTextColor(unpack(C.dim))
    y=y-100
    local card=Card(p,PAGE_PAD,y,innerW,465,self:T("level_analysis"))
    local headers={{self:T("analysis_level"),14},{self:T("analysis_runs"),160},{self:T("analysis_timed"),270},{self:T("analysis_rate"),390},{self:T("analysis_avg_time"),535},{self:T("analysis_avg_deaths"),700}}
    for _,h in ipairs(headers) do local t=Text(card,h[1],8,true); t:SetPoint("TOPLEFT",h[2],-36); t:SetTextColor(unpack(C.dim)) end
    Divider(card,-56)
    local list={}; for _,d in pairs(stats.byLevel or {}) do list[#list+1]=d end; table.sort(list,function(a,b) return a.level>b.level end)
    local ry=-72
    if #list==0 then local t=Text(card,self:T("no_data"),10,false); t:SetPoint("TOPLEFT",14,ry); t:SetTextColor(unpack(C.dim)); return end
    for i=1,math.min(14,#list) do local d=list[i]; local rate=d.total>0 and d.timed/d.total*100 or 0; local avgTime=d.total>0 and d.durationTotal/d.total or 0; local avgDeaths=d.total>0 and d.deathsTotal/d.total or 0
        local vals={{"+"..d.level,14,C.text},{d.total,160,C.text},{d.timed,270,C.text},{string.format("%.0f%%",rate),390,rate>=70 and C.green or (rate>=50 and C.yellow or C.red)},{FormatSec(avgTime),535,C.dim},{string.format("%.1f",avgDeaths),700,C.dim}}
        for _,v in ipairs(vals) do local t=Text(card,tostring(v[1]),9,false); t:SetPoint("TOPLEFT",v[2],ry); t:SetTextColor(unpack(v[3])) end
        ry=ry-28
    end
end

-- ---------------------------------------------------------------------
-- Season goals
-- ---------------------------------------------------------------------
function MP:BuildSeasonGoals()
    local p=BeginPage("goals")
    local y=PageTitle(p,self:T("season_goals"),self:T("season"))
    local db=self:GetDB(); db.goals=db.goals or {}; local g=db.goals
    g.score=tonumber(g.score) or 3000; g.bestLevel=tonumber(g.bestLevel) or 15; g.timedLevel=tonumber(g.timedLevel) or 12; g.timedCount=tonumber(g.timedCount) or 50; g.totalRuns=tonumber(g.totalRuns) or 100; g.allDungeonsLevel=tonumber(g.allDungeonsLevel) or 10
    local stats=self.RunHistory and self.RunHistory:GetStats() or {total=0,bestLevel=0}; local runs=SafeRunHistory(); local currentScore=ScoreNow()
    local currentSeason=C_MythicPlus and C_MythicPlus.GetCurrentSeason and Num(C_MythicPlus.GetCurrentSeason()) or 0
    local function TimedAt(level) local n=0; for _,r in ipairs(runs) do if (currentSeason<=0 or (tonumber(r.seasonID) or 0)==currentSeason) and r.onTime and (tonumber(r.level) or 0)>=level then n=n+1 end end; return n end
    local function DungeonsAt(level) local n=0; local ids=SeasonIDs(); for _,id in ipairs(ids) do local best=SeasonBest(id); if best>=level then n=n+1 end end; return n,#ids end
    local innerW=content:GetWidth()-PAGE_PAD*2; local leftW=420; local rightX=PAGE_PAD+leftW+10; local rightW=innerW-leftW-10
    local controls=Card(p,PAGE_PAD,y,leftW,540,self:T("season_goals")); local cy=-40
    Slider(controls,self:T("goals_score"),g.score,1000,4000,50,14,cy,370,function(v) g.score=math.floor(v+0.5) end,"%.0f"); cy=cy-64
    Slider(controls,self:T("goals_best"),g.bestLevel,2,30,1,14,cy,370,function(v) g.bestLevel=math.floor(v+0.5) end,"+%.0f"); cy=cy-64
    Slider(controls,self:T("goals_target_level"),g.timedLevel,2,30,1,14,cy,370,function(v) g.timedLevel=math.floor(v+0.5) end,"+%.0f"); cy=cy-58
    Slider(controls,self:T("goals_target_count"),g.timedCount,5,100,5,14,cy,370,function(v) g.timedCount=math.floor(v+0.5) end,"%.0f"); cy=cy-64
    Slider(controls,self:T("goals_runs"),g.totalRuns,10,200,10,14,cy,370,function(v) g.totalRuns=math.floor(v+0.5) end,"%.0f"); cy=cy-64
    Slider(controls,self:T("goals_all_dungeons"),g.allDungeonsLevel,2,25,1,14,cy,370,function(v) g.allDungeonsLevel=math.floor(v+0.5) end,"+%.0f")

    local prog=Card(p,rightX,y,rightW,540,self:T("goals_progress")); local py=-42
    ProgressBar(prog,self:T("goals_score"),currentScore,g.score,14,py,rightW-28):SetProgress(currentScore,g.score,string.format("%.0f / %.0f",currentScore,g.score)); py=py-72
    ProgressBar(prog,self:T("goals_best"),stats.bestLevel or 0,g.bestLevel,14,py,rightW-28):SetProgress(stats.bestLevel or 0,g.bestLevel,string.format("+%d / +%d",stats.bestLevel or 0,g.bestLevel)); py=py-72
    local timed=TimedAt(g.timedLevel); ProgressBar(prog,self:T("goals_timed"),timed,g.timedCount,14,py,rightW-28):SetProgress(timed,g.timedCount,string.format("%d / %d  (+%d)",timed,g.timedCount,g.timedLevel)); py=py-72
    ProgressBar(prog,self:T("goals_runs"),stats.total or 0,g.totalRuns,14,py,rightW-28):SetProgress(stats.total or 0,g.totalRuns); py=py-72
    local done,total=DungeonsAt(g.allDungeonsLevel); ProgressBar(prog,self:T("goals_all_dungeons"),done,math.max(total,1),14,py,rightW-28):SetProgress(done,math.max(total,1),string.format("%d / %d  (+%d)",done,total,g.allDungeonsLevel)); py=py-72
    local note=Text(prog,self:T("goals_local_note"),8,false); note:SetPoint("TOPLEFT",14,py); note:SetWidth(rightW-28); note:SetWordWrap(true); note:SetTextColor(unpack(C.dim))
end

-- ---------------------------------------------------------------------
-- Appearance — compact, no scrolling required
-- ---------------------------------------------------------------------
function MP:BuildAppearance()
    local p=BeginPage("appearance")
    local y=PageTitle(p,self:T("appearance"),self:T("subtitle"))
    local db=self:GetDB(); db.ui=db.ui or {}
    local ui=db.ui
    ui.textScale=tonumber(ui.textScale) or 1
    ui.windowScale=tonumber(ui.windowScale) or 1
    ui.backgroundAlpha=tonumber(ui.backgroundAlpha) or DEFAULT_STUDIO_BG_ALPHA
    ui.accent=type(ui.accent)=="table" and ui.accent or {r=DEFAULT_STUDIO_ACCENT[1],g=DEFAULT_STUDIO_ACCENT[2],b=DEFAULT_STUDIO_ACCENT[3]}

    local innerW=content:GetWidth()-PAGE_PAD*2
    local gap=12
    local half=(innerW-gap)/2
    local left=Card(p,PAGE_PAD,y,half,300,self:T("appearance_window"))
    local right=Card(p,PAGE_PAD+half+gap,y,half,300,self:T("appearance_theme"))

    local cy=-48
    Slider(left,self:T("window_text_scale"),ui.textScale,0.85,1.50,0.05,16,cy,half-32,function(v)
        ui.textScale=math.max(0.85,math.min(v,1.50))
        MP:RefreshStudioAppearance("appearance")
    end,"%.2f"); cy=cy-72
    Slider(left,self:T("window_scale"),ui.windowScale,0.85,1.15,0.05,16,cy,half-32,function(v)
        ui.windowScale=math.max(0.85,math.min(v,1.15))
        MP:ApplyStudioAppearance()
    end,"%.2f"); cy=cy-72
    Slider(left,self:T("window_opacity"),ui.backgroundAlpha,0.72,1.00,0.02,16,cy,half-32,function(v)
        ui.backgroundAlpha=math.max(0.72,math.min(v,1.00))
        MP:ApplyStudioAppearance()
    end,"%.2f")

    Check(right,self:T("use_custom_accent"),ui.useCustomAccent==true,16,-46,function(v)
        ui.useCustomAccent=v
        MP:RefreshStudioAppearance("appearance")
    end,half-32)
    ColorPicker(right,self:T("studio_accent"),ui.accent,16,-86,half-32,function(r,g,b)
        ui.accent.r,ui.accent.g,ui.accent.b=r,g,b
        ui.useCustomAccent=true
        MP:ApplyStudioAppearance()
        if MP._appearancePreviewAccent then MP._appearancePreviewAccent:SetColorTexture(unpack(C.accent)) end
        if MP._appearancePreviewValue then MP._appearancePreviewValue:SetTextColor(unpack(C.accent)) end
    end)
    Button(right,self:T("appearance_reset"),16,-136,205,function()
        ui.textScale=1.00
        ui.windowScale=1.00
        ui.backgroundAlpha=DEFAULT_STUDIO_BG_ALPHA
        ui.useCustomAccent=false
        ui.accent={r=DEFAULT_STUDIO_ACCENT[1],g=DEFAULT_STUDIO_ACCENT[2],b=DEFAULT_STUDIO_ACCENT[3]}
        MP:RefreshStudioAppearance("appearance")
    end)
    local note=Text(right,self:T("appearance_note"),9,false)
    note:SetPoint("TOPLEFT",16,-190); note:SetPoint("RIGHT",right,"RIGHT",-16,0)
    note:SetJustifyH("LEFT"); note:SetWordWrap(true); note:SetTextColor(unpack(C.dim))

    y=y-312
    local preview=Card(p,PAGE_PAD,y,innerW,188,self:T("appearance_preview"))
    local mock=CreateFrame("Frame",nil,preview,"BackdropTemplate")
    mock:SetPoint("TOPLEFT",18,-44); mock:SetSize(innerW-36,112)
    Backdrop(mock,C.bg,C.border)
    local ac=mock:CreateTexture(nil,"ARTWORK"); ac:SetPoint("TOPLEFT"); ac:SetPoint("BOTTOMLEFT"); ac:SetWidth(3); ac:SetColorTexture(unpack(C.accent)); MP._appearancePreviewAccent=ac
    local mt=Text(mock,self:T("title"),15,true); mt:SetPoint("TOPLEFT",18,-14)
    local ms=Text(mock,self:T("subtitle"),9,false); ms:SetPoint("LEFT",mt,"RIGHT",10,0); ms:SetTextColor(unpack(C.dim))
    local mini=Card(mock,18,-48,230,48,self:T("dashboard"))
    local sample=Text(mini,"1135",17,true); sample:SetPoint("RIGHT",-14,-3); sample:SetTextColor(unpack(C.accent)); MP._appearancePreviewValue=sample
    local desc=Text(mock,self:T("current_score"),9,false); desc:SetPoint("LEFT",mini,"RIGHT",18,0); desc:SetTextColor(unpack(C.dim))
end

-- ---------------------------------------------------------------------
-- Modules
-- ---------------------------------------------------------------------
local function ModuleCard(parent,y,title,desc,value,callback)
    local c=Card(parent,PAGE_PAD,y,content:GetWidth()-PAGE_PAD*2,94)
    Check(c,title,value,14,-18,callback,320)
    local d=Text(c,desc,9,false); d:SetPoint("TOPLEFT",42,-48); d:SetPoint("RIGHT",c,"RIGHT",-14,0); d:SetJustifyH("LEFT"); d:SetWordWrap(true); d:SetTextColor(unpack(C.dim))
    return y-104
end

function MP:BuildModules()
    local p=BeginPage("modules")
    local y=PageTitle(p,self:T("modules"),"V1.1")
    local db=self:GetDB()
    y=ModuleCard(p,y,self:T("mod_history"),self:T("mod_history_desc"),db.modules.runHistory,function(v) db.modules.runHistory=v end)
    y=ModuleCard(p,y,self:T("mod_stats"),self:T("mod_stats_desc"),db.modules.statistics,function(v) db.modules.statistics=v end)
    local tdb=TomoModDB and TomoModDB.MythicTracker
    y=ModuleCard(p,y,self:T("mod_tracker"),self:T("mod_tracker_desc"),tdb and tdb.enabled,function(v) if tdb then tdb.enabled=v; TrackerRefresh() end end)
    local sdb=TomoModDB and TomoModDB.TomoScore
    y=ModuleCard(p,y,self:T("mod_score"),self:T("mod_score_desc"),sdb and sdb.enabled,function(v) if sdb then sdb.enabled=v end end)
    local note=Text(p,self:T("v11_note"),9,false); note:SetPoint("TOPLEFT",PAGE_PAD,y-4); note:SetPoint("RIGHT",p,"RIGHT",-PAGE_PAD,0); note:SetJustifyH("LEFT"); note:SetWordWrap(true); note:SetTextColor(unpack(C.dim))
end

local BUILDERS={ dashboard="BuildDashboard", tracker="BuildTracker", score="BuildScore", keys="BuildKeys", history="BuildHistory", statistics="BuildStatistics", weekly="BuildWeeklyPlanner", scoreplanner="BuildScorePlanner", analysis="BuildLevelAnalysis", goals="BuildSeasonGoals", appearance="BuildAppearance", modules="BuildModules" }

function MP:SelectPage(key)
    key=BUILDERS[key] and key or "dashboard"
    for id,b in pairs(navButtons) do
        local selected=(id==key)
        b:SetBackdropColor(C.accent[1],C.accent[2],C.accent[3],selected and 0.20 or 0)
        b._text:SetTextColor(selected and 1 or 0.70,selected and 1 or 0.73,selected and 1 or 0.77,1)
    end
    local fn=self[BUILDERS[key]]
    if fn then fn(self) end
end

function MP:RefreshCurrentPage()
    self:SelectPage(self.page or "dashboard")
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------
function MP:BuildStudio()
    if self.Frame then return self.Frame end

    local availW=UIParent:GetWidth() or PANEL_W
    local availH=UIParent:GetHeight() or PANEL_H
    local pw=math.min(PANEL_W,math.floor(availW)-24)
    local ph=math.min(PANEL_H,math.floor(availH)-24)

    local f=CreateFrame("Frame","TomoMod_MythicPlusStudio",UIParent,"BackdropTemplate")
    self.Frame=f
    f:SetSize(pw,ph)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(180)
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    Backdrop(f,C.bg,C.border)
    f:SetScript("OnDragStart",function(s) s:StartMoving() end)
    f:SetScript("OnDragStop",function(s) s:StopMovingOrSizing() end)
    f:SetScript("OnHide",function(s)
        local point,_,relPoint,x,y=s:GetPoint(1)
        local db=MP:GetDB().ui
        db.point=point or "CENTER"; db.relPoint=relPoint or "CENTER"; db.x=x or 0; db.y=y or 20
    end)

    local accent=f:CreateTexture(nil,"ARTWORK"); accent:SetPoint("TOPLEFT"); accent:SetPoint("BOTTOMLEFT"); accent:SetWidth(3); accent:SetColorTexture(unpack(C.accent)); f._accent=accent
    local title=Text(f,self:T("title"),15,true); title:SetPoint("TOPLEFT",18,-17); f._title=title
    local sub=Text(f,self:T("subtitle"),9,false); sub:SetPoint("LEFT",title,"RIGHT",10,0); sub:SetTextColor(unpack(C.dim)); f._subtitle=sub
    local close=Button(f,"X",pw-42,-12,28,function() MP:Hide() end); close:ClearAllPoints(); close:SetPoint("TOPRIGHT",-10,-10); close:SetSize(28,28)

    local h=f:CreateTexture(nil,"ARTWORK"); h:SetPoint("TOPLEFT",0,-HEADER_H); h:SetPoint("TOPRIGHT",0,-HEADER_H); h:SetHeight(1); h:SetColorTexture(unpack(C.border)); f._headerLine=h
    local side=CreateFrame("Frame",nil,f,"BackdropTemplate"); side:SetPoint("TOPLEFT",3,-HEADER_H-1); side:SetPoint("BOTTOMLEFT",3,1); side:SetWidth(SIDE_W-3); Backdrop(side,{0.043,0.050,0.064,1},{0,0,0,0}); f._side=side
    local vsep=f:CreateTexture(nil,"ARTWORK"); vsep:SetPoint("TOPLEFT",SIDE_W,-HEADER_H); vsep:SetPoint("BOTTOMLEFT",SIDE_W,0); vsep:SetWidth(1); vsep:SetColorTexture(unpack(C.border)); f._vsep=vsep

    content=CreateFrame("Frame",nil,f); content:SetPoint("TOPLEFT",SIDE_W+1,-HEADER_H-1); content:SetPoint("BOTTOMRIGHT",-1,1)
    pageBin=CreateFrame("Frame",nil,f); pageBin:Hide()

    local NAV={ {"dashboard","dashboard"},{"tracker","tracker"},{"score","score"},{"keys","keys"},{"history","history"},{"statistics","statistics"},{"weekly","weekly_planner"},{"scoreplanner","score_planner"},{"analysis","level_analysis"},{"goals","season_goals"},{"appearance","appearance"},{"modules","modules"} }
    local ny=-18
    for _,def in ipairs(NAV) do
        local key,labelKey=def[1],def[2]
        local b=CreateFrame("Button",nil,side,"BackdropTemplate"); b:SetPoint("TOPLEFT",8,ny); b:SetPoint("TOPRIGHT",-8,ny); b:SetHeight(36); Backdrop(b,{0,0,0,0},{0,0,0,0})
        local txt=Text(b,self:T(labelKey),10,true); txt:SetPoint("LEFT",12,0); txt:SetTextColor(0.70,0.73,0.77,1); b._text=txt
        b:SetScript("OnClick",function() MP:SelectPage(key) end)
        navButtons[key]=b; ny=ny-38
    end

    local ver=Text(side,"TomoMod Mythic+  V1.1.4",8,false); ver:SetPoint("BOTTOMLEFT",12,12); ver:SetTextColor(unpack(C.dim)); f._version=ver
    self:ApplyStudioAppearance()
    f:Hide()
    return f
end
