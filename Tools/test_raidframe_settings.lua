-- Regression harness for RaidFrame live settings.
-- Reproduces the resize path without rendering WoW frames.

local ok = true
local function check(label, got, want)
    local good = got == want
    if not good then ok = false end
    print(("  %s %-46s expected=%-8s got=%s"):format(
        good and "OK  " or "FAIL", label, tostring(want), tostring(got)))
end

local eventFrame
local function MockFrame()
    local f = { scripts = {} }
    return setmetatable(f, { __index = function(_, key)
        if key == "SetScript" then
            return function(self, event, fn) self.scripts[event] = fn end
        end
        return function() end
    end })
end

CreateFrame = function()
    local f = MockFrame()
    eventFrame = eventFrame or f
    return f
end
UIParent = MockFrame()
C_Timer = { After = function(_, fn) if fn then fn() end end }
local inCombat = false
InCombatLockdown = function() return inCombat end
IsInRaid = function() return false end
IsInGroup = function() return false end
GetNumGroupMembers = function() return 0 end

TomoModDB = {
    raidFrames = {
        enabled = true,
        width = 74,
        height = 40,
        position = {
            v = 2,
            point = "BOTTOMLEFT",
            anchor = "BOTTOMLEFT",
            relativePoint = "TOPLEFT",
            x = 514,
            y = 140,
        },
    },
}
TomoMod_Defaults = {
    raidFrames = {
        position = { point = "TOPLEFT", anchor = "TOPLEFT", x = 20, y = -200 },
    },
}

local applied, appliedPosition
TomoMod_Layout = {
    Apply = function(position)
        applied = (applied or 0) + 1
        appliedPosition = position
        return true
    end,
}

assert(loadfile("Modules/Interface/RaidFrame/Core.lua"))()
local RF = TomoMod_RaidFrames
RF.anchor = MockFrame()
RF.frames = {}

local layouts = 0
RF.LayoutFrames = function() layouts = layouts + 1 end

check("live update succeeds out of combat", RF.ApplySettings(), true)
check("layout refreshed once", layouts, 1)
check("position restored through Layout.Apply", applied, 1)
check("v2 position is the source", appliedPosition.anchor, "BOTTOMLEFT")

inCombat = true
check("combat update is deferred", RF.ApplySettings(), false)
check("pending settings flag set", RF._pendingSettings, true)
check("no protected layout in combat", layouts, 1)
check("no position update in combat", applied, 1)

-- The real event handler must replay the complete settings update after combat,
-- not only LayoutFrames, otherwise fonts/children could remain half-updated.
local file = assert(io.open("Modules/Interface/RaidFrame/Core.lua", "rb"))
local source = file:read("*a")
file:close()
check("regen handles pending settings", source:find("if RF._pendingSettings then", 1, true) ~= nil, true)
check("regen replays ApplySettings", source:find("            RF.ApplySettings()", 1, true) ~= nil, true)
check("raid anchor is clamped", source:find("anchor:SetClampedToScreen(true)", 1, true) ~= nil, true)

print(ok and "PASS: RaidFrame live settings" or "FAIL: RaidFrame live settings")
os.exit(ok and 0 or 1)
