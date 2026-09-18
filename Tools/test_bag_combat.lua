-- Bags V4 must keep its prepared combined window available during combat,
-- while retaining the native fallback for a container Blizzard creates late.

local total = 0
local function check(label, condition)
    total = total + 1
    assert(condition, label)
end

local timerQueue = {}
C_Timer = {
    After = function(_, fn) timerQueue[#timerQueue + 1] = fn end,
}

local inCombat = false
InCombatLockdown = function() return inCombat end
UIParent = { name = "UIParent" }
TomoModDB = {
    bagsV4 = {
        enabled = true,
        _legacyMigrated = true,
        layout = { mode = "combined" },
    },
}

local function Frame(parent, shown)
    return {
        parent = parent,
        shown = shown and true or false,
        GetParent = function(self) return self.parent end,
        SetParent = function(self, value) self.parent = value end,
        IsShown = function(self) return self.shown end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
    }
end

dofile("Modules/QOL/Bags/BagCore.lua")
local Bags = TomoMod_BagSkin
local custom = Frame(UIParent, false)
Bags.Modules.Layout = { frame = custom }
Bags.Modules.Slots = {}
Bags.Modules.Sidebar = {}

dofile("Modules/QOL/Bags/BagBridge.lua")
local Bridge = Bags.Modules.Bridge
local sink = Frame(UIParent, false)
Bridge.hiddenParent = sink

local native = Frame(sink, true)
ContainerFrame1 = native
Bridge.nativeParents[native] = UIParent

inCombat = true
Bridge:SyncFromBlizzard()
check("prepared combined bag opens in combat", custom.shown and Bags.State.visible)
check("combined mode is replayed after combat", Bridge.pendingMode == "combined")

native.shown = false
Bridge:SyncFromBlizzard()
check("prepared combined bag closes in combat", not custom.shown and not Bags.State.visible)

native.parent = UIParent
native.shown = true
custom.shown = true
Bags.State.visible = true
Bridge:SyncFromBlizzard()
check("late native container keeps safe fallback", native.shown and not custom.shown and not Bags.State.visible)

-- In separate mode the steady state has no frame left in the hidden sink, so
-- direct module toggles may use Blizzard's normal bag functions in combat.
TomoModDB.bagsV4.layout.mode = "separate"
Bridge.nativeParents[native] = nil
native.parent = UIParent
local opened, toggled = 0, 0
OpenAllBags = function() opened = opened + 1 end
ToggleAllBags = function() toggled = toggled + 1 end
Bridge:ShowSeparate()
Bridge:ToggleSeparate()
check("separate bags open in combat", opened == 1)
check("separate bags toggle in combat", toggled == 1)

-- A refresh refused by lockdown must leave the layout request pending for the
-- PLAYER_REGEN_ENABLED handler instead of losing it in the timer callback.
timerQueue = {}
Bags.State.initialized = true
Bags.State.refreshPending = false
Bags.State.layoutPending = false
local requested
Bags.Modules.Slots.Refresh = function(_, layoutToo)
    requested = layoutToo
    Bags.State.layoutPending = true
end
Bags.RequestRefresh(true)
check("bag refresh is queued", #timerQueue > 0)
table.remove(timerQueue, 1)()
check("combat layout was requested", requested == true)
check("combat layout remains deferred", Bags.State.layoutPending == true)

print(("Bag combat tests passed: %d"):format(total))
