-- Real command/loader/drag functions; small extracted UI callbacks avoid
-- pretending that a headless runner can render the WoW configuration window.
local total = 0
local function check(label, condition)
    total = total + 1
    assert(condition, label)
end
local function read(path)
    local f = assert(io.open(path, "rb")); local s = f:read("*a"); f:close()
    return (s:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end
local function fragment(path, pattern, result, env)
    local block = assert(read(path):match(pattern), "source fragment missing: " .. path)
    local fn = assert(loadstring(block .. "\nreturn " .. result, "@" .. path .. ":fragment"))
    setfenv(fn, setmetatable(env or {}, { __index = _G }))
    return fn()
end
CreateFrame = function()
    return setmetatable({}, { __index = function() return function() end end })
end
UIParent, StaticPopupDialogs, SlashCmdList = {}, {}, {}
C_Timer = { After = function() end }
InCombatLockdown = function() return false end
TomoMod_L = setmetatable({}, { __index = function(_, key) return key end })
ReloadUI = function() end
local say = print
print = function() end
local received, toggled, waypoint
TomoMod_LayoutShare = { Decode = function(str) received = str; return nil, "test stops before apply" end }
TomoMod_Registry = {
    Has = function(key) return key == "unitFrames" end,
    ListAll = function() return { { key = "unitFrames" } } end,
}
TomoMod_Lifecycle = { Toggle = function(key)
    toggled = key
    return { value = true, cascade = {}, missingDeps = {} }
end }
TomoMod_Waypoint = { HandleSlashCommand = function(str) waypoint = str end }
assert(loadfile("Core/Init.lua"))("TomoMod")
SlashCmdList.TOMOMOD("  LaYoUt IMPORT AbCdEfG(ZxY)  ")
check("encoded layout casing preserved", received == "AbCdEfG(ZxY)")
SlashCmdList.TOMOMOD("MODULES UNITFRAMES")
check("camelCase registry key resolved", toggled == "unitFrames")
SlashCmdList.TOMOMOD("Way 42 57 Portail Valdrakken")
check("waypoint label preserved", waypoint == "42 57 Portail Valdrakken")

local loads, shows, hides, invalidations = 0, 0, 0, 0
TomoMod_Config = nil
C_AddOns = {
    IsAddOnLoaded = function() return loads > 0 end,
    LoadAddOn = function()
        loads = loads + 1
        TomoMod_Config.Show = function(arg) shows = shows + 1; return arg end
        TomoMod_Config.Hide = function() hides = hides + 1 end
        TomoMod_Config.InvalidatePanels = function() invalidations = invalidations + 1 end
        return true
    end,
}
dofile("Core/OptionsLoader.lua")
TomoMod_Config.Hide(); TomoMod_Config.InvalidatePanels()
check("passive operations do not load options", loads == 0)
check("first explicit show loads and forwards", TomoMod_Config.Show("profiles") == "profiles" and loads == 1)
TomoMod_Config.Show(); TomoMod_Config.Hide(); TomoMod_Config.InvalidatePanels()
check("loaded options keep their real methods", loads == 1 and shows == 2 and hides == 1 and invalidations == 1)
local saves = 0
local body = assert(read("TomoMod_Options/Config/ConfigUI.lua"):match('configFrame:SetScript%("OnHide", (function%(self%).-\n    end)%)'))
local make = assert(loadstring("return " .. body))
local env = { C = { isOpen = true }, StopPerfTicker = function() end, CloseOptionsHelp = function() end,
    TomoMod_Profiles = { AutoSaveActiveProfile = function() saves = saves + 1 end } }
setfenv(make, setmetatable(env, { __index = _G }))
make()({})
check("closing loaded window saves current profile", saves == 1 and env.C.isOpen == false)

UF_Elements = {}
TomoMod_UFElements = { DOMAIN = "test", Ensure = function() end }
TomoMod_Forge = { Registry = { ResolveTarget = function(_, _, parent) return parent end } }
dofile("Modules/Interface/UnitFrames/Elements/Auras.lua")
local settings = { elements = { auras = { point = "CENTER", relPoint = "CENTER", relTo = "frame" } } }
local drag = { GetCenter = function() return 100, 220 end, ClearAllPoints = function() end,
    SetPoint = function() end }
local parent = { GetCenter = function() return 70, 180 end }
check("aura fallback drag succeeds", UF_Elements.SaveContainerDrag(drag, parent, "auras", settings))
check("both center coordinates preserved", settings.elements.auras.x == 30 and settings.elements.auras.y == 40)
parent.GetCenter = function() return 70, nil end
check("missing vertical coordinate refused", UF_Elements.SaveContainerDrag(drag, parent, "auras", settings) == false)

local corner, scale, x, y = fragment("TomoMod_Options/Config/Panels/General.lua",
    "(local iC, iS, iX, iY.-)\n    %-%- Coin", "iC, iS, iX, iY",
    { selKey = "tracking", TomoMod_Minimap = { GetIndicatorCfg = function() return "BOTTOMRIGHT", 1.6, -23, 41 end } })
check("all minimap indicator values preserved", corner == "BOTTOMRIGHT" and scale == 1.6 and x == -23 and y == 41)
local data, status = fragment("TomoMod_CDStudio/SpellEditorV2.lua",
    "(local data, status.-)\n        previews", "data, status",
    { key = "essential", CDF = { GetContextPresetProfileData = function() return nil, "noapi" end } })
check("cooldown preview status preserved", data == nil and status == "noapi")
local id, info = fragment("TomoMod_CDStudio/SpellEditorV2.lua",
    "(local id, info.-)\n        if not id", "id, info",
    { CDF = { CreateBarFromViewer = function() return nil, "noapi" end } })
check("cooldown creation error preserved", id == nil and info == "noapi")
local ok, result = fragment("TomoMod_Options/Config/Panels/CooldownForge.lua",
    "(local okI, res.-)\n        if okI", "okI, res",
    { state = {}, CDF = { Import = function() return true, { class = "MONK" } end } })
check("cooldown import result preserved", ok and result.class == "MONK")
print = say
print("PASS: " .. total .. " local regression assertions")
