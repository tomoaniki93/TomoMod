local ADDON, ns = ...

local UF = {}
ns:RegisterModule("UnitFrames", UF)

UF.frame = CreateFrame("Frame")
UF.units = { "player", "target" }
UF.objects = {}

local function MakeBar(parent)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
  bar.bg = bar:CreateTexture(nil, "BACKGROUND")
  bar.bg:SetAllPoints(true)
  bar.bg:SetColorTexture(0, 0, 0, 0.35)
  return bar
end

local function ApplyColor(bar, col)
  if not bar then return end
  col = (type(col) == "table") and col or { r=1, g=1, b=1, a=1 }
  local r = ns.Util.Clamp(col.r, 0, 1, 1)
  local g = ns.Util.Clamp(col.g, 0, 1, 1)
  local b = ns.Util.Clamp(col.b, 0, 1, 1)
  local a = ns.Util.Clamp(col.a, 0, 1, 1)
  bar:SetStatusBarColor(r, g, b, a)
end

local function UpdateUnit(obj, unit)
  if not obj or not unit then return end
  if not UnitExists(unit) then
    if obj.nameText then obj.nameText:SetText("") end
    if obj.healthBar then obj.healthBar:SetMinMaxValues(0, 1); obj.healthBar:SetValue(0) end
    if obj.powerBar  then obj.powerBar:SetMinMaxValues(0, 1);  obj.powerBar:SetValue(0) end
    return
  end

  local name = UnitName(unit) or ""
  if obj.nameText then obj.nameText:SetText(name) end

  local curH = UnitHealth(unit) or 0
  local maxH = UnitHealthMax(unit) or 1
  if maxH <= 0 then maxH = 1 end
  obj.healthBar:SetMinMaxValues(0, maxH)
  obj.healthBar:SetValue(curH)

  local powType = UnitPowerType(unit) or 0
  local curP = UnitPower(unit, powType) or 0
  local maxP = UnitPowerMax(unit, powType) or 1
  if maxP <= 0 then maxP = 1 end
  obj.powerBar:SetMinMaxValues(0, maxP)
  obj.powerBar:SetValue(curP)
end

local function SavePos(key, anchor)
  local _, _, _, x, y = anchor:GetPoint(1)
  x = ns.Util.Num(x, 0)
  y = ns.Util.Num(y, 0)
  ns.DB:Set("unitframes." .. key .. ".x", x)
  ns.DB:Set("unitframes." .. key .. ".y", y)
end

local function MakeAnchor(key)
  local a = CreateFrame("Frame", ns:UniqueName("MidnightUFAnchor"), UIParent)
  a:SetSize(240, 46)
  a:SetClampedToScreen(true)
  a:SetMovable(true)

  a:EnableMouse(false)
  a:RegisterForDrag("LeftButton")

  a:SetScript("OnDragStart", function(self)
    if not ns.DB:Get("unitframes.unlocked", false) then return end
    if InCombatLockdown and InCombatLockdown() then
      ns.Log.Warn("Déplacement bloqué en combat.")
      return
    end
    self:StartMoving()
  end)

  a:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePos(key, self)
  end)

  return a
end

local function MakeSecureUnitButton(anchor, unit)
  local b = CreateFrame("Button", ns:UniqueName("MidnightUFBtn"), anchor, "SecureUnitButtonTemplate")
  b:SetAllPoints(anchor)
  b:RegisterForClicks("AnyUp")

  b:SetAttribute("unit", unit)
  b:SetAttribute("*type1", "target")
  b:SetAttribute("*type2", "togglemenu")

  RegisterUnitWatch(b)

  -- Visuals
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints(true)
  b.bg:SetColorTexture(0, 0, 0, 0.55)

  b.healthBar = MakeBar(b)
  b.powerBar  = MakeBar(b)

  b.healthBar:SetPoint("TOPLEFT", 2, -2)
  b.healthBar:SetPoint("TOPRIGHT", -2, -2)
  b.healthBar:SetHeight(34)

  b.powerBar:SetPoint("TOPLEFT", b.healthBar, "BOTTOMLEFT", 0, -2)
  b.powerBar:SetPoint("TOPRIGHT", b.healthBar, "BOTTOMRIGHT", 0, -2)
  b.powerBar:SetHeight(8)

  b.nameText = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  b.nameText:SetPoint("CENTER", b.healthBar, "CENTER", 0, 0)
  b.nameText:SetJustifyH("CENTER")

  return b
end

function UF:OnInit()
  -- Unit events
  self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  self.frame:RegisterEvent("UNIT_NAME_UPDATE")
  self.frame:RegisterEvent("UNIT_HEALTH")
  self.frame:RegisterEvent("UNIT_MAXHEALTH")
  self.frame:RegisterEvent("UNIT_POWER_UPDATE")
  self.frame:RegisterEvent("UNIT_MAXPOWER")
  self.frame:RegisterEvent("UNIT_DISPLAYPOWER")

  self.frame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
      local obj = self.objects.target
      if obj then UpdateUnit(obj, "target") end
      return
    end

    if unit == "player" then
      local obj = self.objects.player
      if obj then UpdateUnit(obj, "player") end
    elseif unit == "target" then
      local obj = self.objects.target
      if obj then UpdateUnit(obj, "target") end
    end
  end)

  -- Refresh when DB changes
  ns.Events:RegisterMessage("MIDNIGHT_DB_CHANGED", function()
    self:Refresh()
  end)
  ns.Events:RegisterMessage("MIDNIGHT_PROFILE_CHANGED", function()
    self:Refresh()
  end)
end

function UF:OnEnable()
  -- Create objects once
  if not self.objects.player then
    local a = MakeAnchor("player")
    local b = MakeSecureUnitButton(a, "player")
    self.objects.player = b
    self.objects.player.anchor = a
  end

  if not self.objects.target then
    local a = MakeAnchor("target")
    local b = MakeSecureUnitButton(a, "target")
    self.objects.target = b
    self.objects.target.anchor = a
  end
end

function UF:Refresh()
  if not self.objects.player or not self.objects.target then return end

  local enabled = ns.DB:Get("unitframes.enabled", true)
  local scale = ns.Util.Clamp(ns.DB:Get("unitframes.scale", 1.0), 0.60, 1.60, 1.0)

  local function Apply()
    for _, key in ipairs(self.units) do
      local obj = self.objects[key]
      local anchor = obj and obj.anchor
      if anchor then
        local x = ns.Util.Num(ns.DB:Get("unitframes." .. key .. ".x"), (key=="player") and -250 or 250)
        local y = ns.Util.Num(ns.DB:Get("unitframes." .. key .. ".y"), -200)

        anchor:ClearAllPoints()
        anchor:SetPoint("CENTER", UIParent, "CENTER", x, y)
        anchor:SetScale(scale)

        local unlocked = ns.DB:Get("unitframes.unlocked", false)
        anchor:EnableMouse(unlocked and true or false)

        if enabled then
          anchor:Show()
        else
          anchor:Hide()
        end
      end
    end

    -- colors
    local hc = ns.DB:Get("unitframes.colors.health")
    local pc = ns.DB:Get("unitframes.colors.power")
    ApplyColor(self.objects.player.healthBar, hc)
    ApplyColor(self.objects.player.powerBar,  pc)
    ApplyColor(self.objects.target.healthBar, hc)
    ApplyColor(self.objects.target.powerBar,  pc)

    -- update displayed values
    UpdateUnit(self.objects.player, "player")
    UpdateUnit(self.objects.target, "target")
  end

  -- Secure/layout changes must be out of combat
  ns.Core:RunOutOfCombat(Apply)
end