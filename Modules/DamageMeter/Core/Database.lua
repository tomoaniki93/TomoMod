local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM

----------------------------------------------------------------------
-- SavedVariables & Events
----------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    -- [MERGE] Standalone addon present: do not build anything, do not
    -- touch the CVar, do not claim the saved variables.
    if ns.Blocked and ns.Blocked() then return end
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Hide Blizzard's built-in damage meter UI (data collection stays active)
        C_CVar.SetCVar("damageMeterEnabled", "0")

        -- [MERGE] The embedded copy uses its own saved variable. Sharing
        -- TomoDamageMeterDB with the standalone addon would mean two addons
        -- declaring one global: WoW writes a file per addon and the second
        -- to load silently overwrites the first on every logout.
        --
        -- On first run, adopt the standalone's settings if they exist, so a
        -- player moving from the standalone to the suite keeps their layout.
        TomoModDamageMeterDB = TomoModDamageMeterDB or {}
        if not TomoModDamageMeterDB._adopted then
            TomoModDamageMeterDB._adopted = true
            if type(TomoDamageMeterDB) == "table" then
                for k, v in pairs(TomoDamageMeterDB) do
                    if TomoModDamageMeterDB[k] == nil then
                        TomoModDamageMeterDB[k] = v
                    end
                end
            end
        end
        ns.db = TomoModDamageMeterDB

        -- Global defaults
        if ns.db.stripRealm == nil then ns.db.stripRealm = true end
        ns.db.fontSize   = ns.db.fontSize   or ns.BAR_FONT_SIZE
        ns.db.barHeight  = ns.db.barHeight  or ns.BAR_HEIGHT
        ns.db.fontNudge  = ns.db.fontNudge  or 0
        ns.db.fontPath   = ns.db.fontPath   or ns.FONT
        ns.db.bgAlpha    = ns.db.bgAlpha    or ns.BG[4]
        ns.db.oocAlpha   = ns.db.oocAlpha   or 1
        ns.db.accentColor = ns.db.accentColor or { ns.ACCENT[1], ns.ACCENT[2], ns.ACCENT[3] }
        if ns.db.skin == nil then ns.db.skin = "DARK" end
        ns.db.barTexture = ns.db.barTexture or (ns.TEX_FLAT or "Tomo Flat")
        ns.db.reportChannel = ns.db.reportChannel or "AUTO"
        -- One-time migration off SAY. It was the factory default rather than
        -- anyone's choice, and it cannot work: SAY is gated behind a hardware
        -- event and only passes one message per event, so a multi-line report
        -- always lost everything after its first line to ADDON_ACTION_BLOCKED.
        if not ns.db.reportChannelMigrated then
            if ns.RESTRICTED_CHANNELS[ns.db.reportChannel] then
                ns.db.reportChannel = "AUTO"
            end
            ns.db.reportChannelMigrated = true
        end
        ns.db.reportLines   = ns.db.reportLines   or 5
        ns.db.breakdownAlpha = ns.db.breakdownAlpha or 0.85
        if ns.db.autoResetOnInstance == nil then ns.db.autoResetOnInstance = true end
        if ns.db.showCombatTimer == nil then ns.db.showCombatTimer = true end
        if ns.db.showSelfBar == nil then ns.db.showSelfBar = false end
        if ns.db.showBarTooltips == nil then ns.db.showBarTooltips = true end
        if ns.db.combatTimerPos == nil then ns.db.combatTimerPos = "RIGHT" end

        -- Optional modules
        if ns.db.deathRecapAutoShow == nil then ns.db.deathRecapAutoShow = false end

        -- Category visibility (empty = all enabled)
        if not ns.db.disabledCategories then ns.db.disabledCategories = {} end

        ns.ApplyAccentColor()

        -- Apply the saved skin's structural look before any window is built
        -- (honours saved per-setting tweaks; see Modules/Skins.lua).
        if ns.ApplySkin then ns.ApplySkin(ns.db.skin, false) end

        -- Column config
        if not ns.db.columns then
            ns.db.columns = CopyTable(ns.DEFAULT_COLUMNS)
        end
        -- Legacy rows predate the fmt field. Seed from ns.DEFAULT_COLUMNS (the
        -- single source of truth) rather than a divergent inline table, and drop
        -- any saved fmt that is no longer a valid option for that column.
        local defaultFmt = {}
        for _, col in ipairs(ns.DEFAULT_COLUMNS) do
            defaultFmt[col.key] = col.fmt
        end
        for _, col in ipairs(ns.db.columns) do
            local allowed = ns.FORMAT_OPTIONS[col.key]
            local valid = false
            if col.fmt and allowed then
                for _, opt in ipairs(allowed) do
                    if opt == col.fmt then valid = true; break end
                end
            end
            if not valid then
                col.fmt = defaultFmt[col.key] or "1dec"
            elseif col.fmt == "full" and not ns.db.fmtFullMigrated then
                -- One-time migration. "full" was never a deliberate choice: the
                -- broken legacy seeding above assigned it, and it rendered
                -- through AbbreviateLargeNumbers as "16156 K" — unit pinned at
                -- K, digits piling up. "3dec" shows the same precision as
                -- "16.156M". Anyone who genuinely wants raw digits can pick
                -- "full" again; the flag makes sure we only do this once.
                col.fmt = "3dec"
            end
        end
        ns.db.fmtFullMigrated = true

        -- Migrate legacy single-window config to multi-window array
        if ns.db.window and not ns.db.windowConfigs then
            ns.db.windowConfigs = { ns.db.window }
            ns.db.window = nil
        end
        if not ns.db.windowConfigs or #ns.db.windowConfigs == 0 then
            ns.db.windowConfigs = { {} }
        end

        -- Backfill stable ids on configs saved before docking existed, and
        -- keep the counter ahead of the highest one in use.
        for _, cfg in ipairs(ns.db.windowConfigs) do
            if type(cfg.id) == "number" and cfg.id > (ns.db.nextWindowId or 0) then
                ns.db.nextWindowId = cfg.id
            end
        end
        for _, cfg in ipairs(ns.db.windowConfigs) do
            if type(cfg.id) ~= "number" then cfg.id = ns.NextWindowId() end
        end

        -- Create all saved windows
        for _, cfg in ipairs(ns.db.windowConfigs) do
            for k, v in pairs(ns.DEFAULTS) do
                if cfg[k] == nil then cfg[k] = type(v) == "table" and CopyTable(v) or v end
            end
            local win = ns.CreateMeterWindow(cfg)
            table.insert(ns.windows, win)
            win.Refresh()
            C_Timer.After(0, win.UpdateHeader)
        end

        -- Second pass: a window cannot anchor to one that does not exist yet,
        -- so docks are re-applied only once every window has been created.
        if ns.RestoreSnaps then ns.RestoreSnaps() end

        -- Enforce: switch any window showing a disabled category
        ns.EnforceEnabledTypes()

    elseif event == "PLAYER_LEAVING_WORLD" then
        -- Save positions on every zone transition (in case of crash)
        if ns.db then
            for _, win in ipairs(ns.windows) do
                win.SavePosition()
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        if ns.db then
            for _, win in ipairs(ns.windows) do
                win.SavePosition()
            end
        end
        -- Clean up event listeners only on actual logout
        eventFrame:UnregisterAllEvents()
        if ns._instanceFrame then ns._instanceFrame:UnregisterAllEvents() end
        if ns._dmEventFrame then ns._dmEventFrame:UnregisterAllEvents() end
        if ns._deathRecapFrame then ns._deathRecapFrame:UnregisterAllEvents() end
        -- Cancel any running tickers
        if ns._timerTicker then ns._timerTicker:Cancel(); ns._timerTicker = nil end
        if ns._refreshTicker then ns._refreshTicker:Cancel(); ns._refreshTicker = nil end
    end
end)

----------------------------------------------------------------------
-- Multi-Window Management
----------------------------------------------------------------------

-- Stable per-window identity. Dock relations are stored by id, not by array
-- index: RemoveWindow shifts every index after the removed one, which would
-- silently repoint a saved dock at the wrong window.
function ns.NextWindowId()
    ns.db.nextWindowId = (ns.db.nextWindowId or 0) + 1
    return ns.db.nextWindowId
end

function ns.CreateNewWindow()
    if #ns.windows >= ns.MAX_WINDOWS then return false end
    local cfg = {}
    for k, v in pairs(ns.DEFAULTS) do
        cfg[k] = type(v) == "table" and CopyTable(v) or v
    end
    -- Offset new windows so they don't stack exactly on top
    cfg.id = ns.NextWindowId()
    cfg.x = cfg.x + 30 * #ns.windows
    cfg.y = cfg.y - 30 * #ns.windows
    table.insert(ns.db.windowConfigs, cfg)
    local win = ns.CreateMeterWindow(cfg)
    table.insert(ns.windows, win)
    win.Refresh()
    C_Timer.After(0, win.UpdateHeader)
    return true
end

function ns.RemoveWindow(index)
    if #ns.windows <= 1 then return false end
    index = index or #ns.windows
    local win = ns.windows[index]
    if not win then return false end
    -- Followers first: leaving them anchored to a hidden frame would strand
    -- them off-screen with no way to grab them.
    if ns.SnapDetachChildrenOf then ns.SnapDetachChildrenOf(win) end
    if ns.SnapDetachFrame then ns.SnapDetachFrame(win.frame) end
    win.frame:Hide()
    table.remove(ns.windows, index)
    table.remove(ns.db.windowConfigs, index)
    return true
end

----------------------------------------------------------------------
-- Auto-Reset on Instance Entry
----------------------------------------------------------------------

-- The reset has to fire when the player walks into a new instance, and never
-- when the UI is reloaded inside one.
--
-- It used to do both. `wasInInstance` was a plain local, so /reload brought it
-- back as false; the PLAYER_ENTERING_WORLD that always follows a reload then
-- read as a fresh entry and called ResetAllCombatSessions(). The combat
-- sessions themselves live on the client side and survive a reload perfectly
-- well — the addon was throwing away data the game had kept, which is why a
-- reload mid-key wiped the whole dungeon.
--
-- The instance identity is now stored in SavedVariables, which does survive
-- the reload, and the reset only fires when that identity actually changes.
local instanceFrame = CreateFrame("Frame")
ns._instanceFrame = instanceFrame
instanceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
instanceFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)
    if ns.Blocked and ns.Blocked() then return end
    if not ns.db then return end

    local key = ns.GetInstanceKey()

    if not key then
        -- Outside a tracked instance: forget the last one, so walking back into
        -- the same dungeon later still counts as a new entry and still resets.
        ns.db.activeInstanceKey = nil
        return
    end

    -- A reload keeps the client's sessions intact, so it can only ever mean
    -- "still here" — adopt the key without touching the data.
    if isReloadingUi then
        ns.db.activeInstanceKey = key
        return
    end

    if ns.db.activeInstanceKey == key then return end
    ns.db.activeInstanceKey = key

    -- On a fresh login the sessions are empty anyway; resetting would only
    -- risk discarding data if the client kept any across the reconnect.
    if ns.db.autoResetOnInstance and not isInitialLogin then
        C_DamageMeter.ResetAllCombatSessions()
    end
end)

----------------------------------------------------------------------
-- Combat Events
----------------------------------------------------------------------

local dmEventFrame = CreateFrame("Frame")
ns._dmEventFrame = dmEventFrame
dmEventFrame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
dmEventFrame:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
dmEventFrame:RegisterEvent("DAMAGE_METER_RESET")
dmEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
dmEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local timerTicker = nil
local refreshTicker = nil
ns._timerTicker = nil
ns._refreshTicker = nil

-- Returns true if any visible window is showing an ACTIONS-type meter
-- (Interrupts, Dispels, Deaths) — these don't fire DAMAGE_METER_* update events
-- and require a periodic refresh. Other types are event-driven and don't need it.
local function NeedsPeriodicRefresh()
    for _, win in ipairs(ns.windows) do
        if ns.ACTIONS_TYPES[win.GetMeterType()] then return true end
    end
    return false
end

----------------------------------------------------------------------
-- Throttled Refresh (combat-only, 150ms interval)
----------------------------------------------------------------------

local lastRefreshTime = 0
local REFRESH_INTERVAL = 0.15
local TARGET_INTERVAL = 1.0   -- segment browser: much heavier, much less urgent
local lastTargetTime = 0
local refreshing = false

-- The single data pass. Every caller must reach this from inside an event
-- handler: C_DamageMeter returns readable values there and secret values from a
-- timer callback, so anything deferred loses the ability to do Lua-side maths.
local function DoRefresh()
    if refreshing then return end
    refreshing = true
    lastRefreshTime = GetTime()

    for _, win in ipairs(ns.windows) do win.Refresh() end

    -- The segment browser re-queries one session per segment and rebuilds its
    -- whole data provider, so it gets its own, slower gate. On the old deferred
    -- path this cost was hidden in a timer; running in-handler it would stall
    -- the event at 6.6 Hz.
    if ns.RefreshTargetBreakdown then
        local now = GetTime()
        if now - lastTargetTime >= TARGET_INTERVAL then
            lastTargetTime = now
            ns.RefreshTargetBreakdown()
        end
    end

    refreshing = false
end

-- Leading-edge throttle. An update arriving inside the interval is dropped
-- outright rather than deferred to a timer: during combat the DAMAGE_METER_*
-- stream is continuous, so the next event past the interval carries the same
-- state, and PLAYER_REGEN_ENABLED guarantees a final pass on the trailing edge.
local function ThrottledRefresh()
    if GetTime() - lastRefreshTime < REFRESH_INTERVAL then return end
    DoRefresh()
end

----------------------------------------------------------------------
-- Combat Events
----------------------------------------------------------------------

dmEventFrame:SetScript("OnEvent", function(self, event)
    if ns.Blocked and ns.Blocked() then return end
    if event == "DAMAGE_METER_RESET" then
        print(ns.L["ADDON_PREFIX"] .. ns.L["CMD_RESET"])
        if ns.ResetSpellData then ns.ResetSpellData() end
        if ns.HideTargetBreakdown then ns.HideTargetBreakdown() end
        for _, win in ipairs(ns.windows) do
            win.BumpGeneration()
            win.Refresh()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.inCombat = true
        for _, win in ipairs(ns.windows) do
            win.SetCombatAlpha(true)
        end
        if not timerTicker then
            timerTicker = C_Timer.NewTicker(1, function()
                for _, win in ipairs(ns.windows) do win.UpdateTimer() end
            end)
            ns._timerTicker = timerTicker
        end
        -- The one data pass that cannot run in-handler: ACTIONS meters
        -- (Interrupts / Dispels / Deaths) emit no DAMAGE_METER_* event, so there
        -- is nothing to hook. Values read here are secret, which is tolerable
        -- because that category renders its total through SetFormattedText — a
        -- C-side setter that accepts secrets. Everything else is event-driven.
        if not refreshTicker and NeedsPeriodicRefresh() then
            refreshTicker = C_Timer.NewTicker(1, function()
                for _, win in ipairs(ns.windows) do win.Refresh() end
            end)
            ns._refreshTicker = refreshTicker
        end
        for _, win in ipairs(ns.windows) do win.UpdateTimer() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.inCombat = false
        for _, win in ipairs(ns.windows) do
            win.SetCombatAlpha(false)
        end
        if timerTicker then timerTicker:Cancel(); timerTicker = nil; ns._timerTicker = nil end
        if refreshTicker then refreshTicker:Cancel(); refreshTicker = nil; ns._refreshTicker = nil end
        for _, win in ipairs(ns.windows) do win.UpdateTimer() end
        -- Trailing-edge pass: picks up whatever the throttle dropped in the
        -- last interval of the fight, and re-renders now that names resolve.
        lastRefreshTime = 0
        DoRefresh()
        -- Capture the run totals while still inside this handler. Nothing
        -- outside a handler can read these values; see Modules/RunRecap.lua.
        if ns.RunRecapSnapshot then ns.RunRecapSnapshot() end
    else
        -- DAMAGE_METER_COMBAT_SESSION_UPDATED / CURRENT_SESSION_UPDATED
        -- → throttled to REFRESH_INTERVAL (150ms) rather than every frame
        if diagArmed then
            diagArmed = false
            ProbeSession("in-handler   ")
            C_Timer.After(0, function() ProbeSession("C_Timer.After") end)
        end
        ThrottledRefresh()
    end
end)

----------------------------------------------------------------------
-- Readability probe (/tdm diag)
----------------------------------------------------------------------
-- Reports whether C_DamageMeter fields come back readable or as secret values,
-- reading the exact same session twice: once synchronously inside the event
-- handler, once from a C_Timer.After(0) callback. That contrast is the whole
-- reason the refresh path is structured the way it is, so it is worth being
-- able to re-check it against any future build rather than assuming.

local diagArmed = false

local function ProbeSession(label)
    local prefix = ns.L["ADDON_PREFIX"]
    local ok, session = pcall(C_DamageMeter.GetCombatSessionFromType,
        Enum.DamageMeterSessionType.Current, Enum.DamageMeterType.Dps)
    if not ok or not session then
        print(prefix .. label .. ": no session")
        return
    end
    if issecretvalue(session) then
        print(prefix .. label .. ": session = SECRET")
        return
    end
    local sources = session.combatSources
    if not sources or issecretvalue(sources) or #sources == 0 then
        print(prefix .. label .. ": no combat sources")
        return
    end

    local function tag(v)
        if v == nil then return "nil" end
        if issecretvalue(v) then return "|cffff5555SECRET|r" end
        return "|cff55ff55readable|r"
    end

    local first = sources[1]
    print(string.format("%s%s: name=%s total=%s rate=%s duration=%s",
        prefix, label,
        tag(first.name), tag(first.totalAmount),
        tag(first.amountPerSecond), tag(session.durationSeconds)))
end

----------------------------------------------------------------------
-- Slash Commands
----------------------------------------------------------------------

-- [MERGE] The standalone addon owns /tdm when it is installed; taking the
-- name here would leave whichever loaded last in charge, at random.
if not (ns.Blocked and ns.Blocked()) then
SLASH_TDM1 = "/tdm"
SLASH_TDM2 = "/tomodm"
SlashCmdList["TDM"] = function(msg)
    local L = ns.L
    if msg == "reset" then
        C_DamageMeter.ResetAllCombatSessions()
    elseif msg == "lock" then
        -- Single target state for every window: avoids windows with mixed
        -- lock states drifting further apart on each toggle.
        local target = not (ns.windows[1] and ns.windows[1].cfg.locked)
        for _, win in ipairs(ns.windows) do
            win.cfg.locked = target
            if win.RefreshLockIcon then win.RefreshLockIcon() end
        end
        print(L["ADDON_PREFIX"] .. (target and L["CMD_LOCKED"] or L["CMD_UNLOCKED"]))
    elseif msg == "toggle" then
        for _, win in ipairs(ns.windows) do
            win.frame:SetShown(not win.frame:IsShown())
        end
    elseif msg == "recap" then
        if ns.ToggleRunRecap then ns.ToggleRunRecap() end
    elseif msg == "resetpos" then
        if ns.ResetDeathRecapPosition then ns.ResetDeathRecapPosition() end
        print(L["ADDON_PREFIX"] .. L["CMD_POS_RESET"])
    elseif msg == "diag" then
        diagArmed = true
        print(L["ADDON_PREFIX"] .. L["CMD_DIAG_ARMED"])
    elseif msg == "help" then
        print(L["ADDON_PREFIX"] .. L["CMD_HELP_HEADER"])
        print(L["CMD_HELP_TOGGLE"])
        print(L["CMD_HELP_TOGGLE_VIS"])
        print(L["CMD_HELP_RESET"])
        print(L["CMD_HELP_LOCK"])
        print(L["CMD_HELP_RECAP"])
        print(L["CMD_HELP_RESETPOS"])
        print(L["CMD_HELP_DIAG"])
        print(L["CMD_HELP_HELP"])
    else
        if ns.ToggleSettings then
            ns.ToggleSettings()
        end
    end
end
end
