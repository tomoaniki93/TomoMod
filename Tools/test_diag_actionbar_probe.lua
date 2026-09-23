-- Sonde « Action Bars » du rapport Diagnostics : banc headless.
--
-- Sur WoW: Forever 1.60.1, un joueur n'avait aucune barre visible et un
-- rapport Diagnostics parfaitement propre : 0 erreur. Les décisions qui
-- masquent une barre sont sécurisées (un state driver cache le conteneur)
-- ou passent par SafeCall, qui fait taire les échecs « attendus ». La
-- section « Action Bars » existe pour que le rapport dise enfin ce que le
-- client a décidé.
--
-- Ce banc extrait le bloc ACTION BAR PROBE de Diagnostics.lua et le fait
-- tourner sur des bouchons. Il vérifie :
--   1. un conteneur caché par le driver est décrit comme tel, avec la
--      condition fautive à YES et le driver évalué à « hide » ;
--   2. le premier bouton est décrit (slot, hasAction, texture) ;
--   3. les échecs silencieux de SafeCall sont comptés ;
--   4. la sonde ne lève jamais : moteur absent, SecureCmdOptionParse
--      absent, méthodes qui lèvent, valeurs secrètes ;
--   5. le câblage sécurisé est rapporté (frame refs du layout handler,
--      attributs action/index), et l'auto-test Execute / SetFrameRef /
--      GetFrameRef distingue un client sain d'un client où ils échouent.
--
-- Rapport Forever 1.60.1 qui a motivé les points 5 et 6 : conteneurs en
-- 1x1, boutons sans aucun point d'ancrage, action=nil, et toujours 0
-- erreur. Les barres construisent tout à ADDON_LOADED, avant que
-- Diagnostics n'installe son gestionnaire (PLAYER_LOGIN).
--   6. la capture précoce (EARLY CAPTURE) : installée au chargement du
--      fichier, elle transmet au gestionnaire précédent, puis à
--      PLAYER_LOGIN classe les erreurs TomoMod et celles du code
--      restreint (meta.phase=load) et rend la chaîne de gestionnaires.
--
-- Usage : lua5.1 Tools/run_test.lua Tools/test_diag_actionbar_probe.lua

local ok = true
local function fail(m) ok = false; print("  ÉCHEC " .. m) end
local function pass(m) print("  OK    " .. m) end
local function expect(label, cond) if cond then pass(label) else fail(label) end end

local function read(path)
    local fh = assert(io.open(path, "rb"))
    local s = fh:read("*a"); fh:close()
    return (s:gsub("^\239\187\191", ""):gsub("\r\n", "\n"))
end

local src = read("Modules/QOL/Diagnostics/Diagnostics.lua")
local s = src:find("local ABProbe = {}", 1, true)
local e = src:find("-- REPORT BUILDERS", 1, true)
assert(s and e and s < e, "bloc ACTION BAR PROBE introuvable")
local block = src:sub(s, e - 1):gsub("%-%- =+%s*$", "")
    .. "\nreturn DescribeActionBars, ABProbe\n"

-- ---------------------------------------------------------------------
-- Bouchons
-- ---------------------------------------------------------------------
local SECRET = setmetatable({}, { __tostring = function() return "SECRET" end })

local function Frame(t)
    t = t or {}
    local f = {
        _shown = t.shown ~= false, _visible = t.visible, _alpha = t.alpha or 1,
        _name = t.name, _attrs = t.attrs or {}, _parent = t.parent,
    }
    function f:IsShown() return self._shown end
    function f:IsVisible() if self._visible == nil then return self._shown end return self._visible end
    function f:GetAlpha() return self._alpha end
    function f:GetEffectiveAlpha() return self._alpha end
    function f:GetScale() return 1 end
    function f:GetSize() return 400, 40 end
    function f:GetFrameStrata() return "MEDIUM" end
    function f:GetFrameLevel() return 3 end
    function f:GetNumPoints() return 1 end
    function f:GetPoint() return "BOTTOM", t.rel end
    function f:GetName() return self._name end
    function f:GetParent() return self._parent end
    function f:GetAttribute(k) return self._attrs[k] end
    function f:GetTexture() return t.texture end
    return f
end

local function MakeEnv(opts)
    local conds = opts.conds or {}
    local env = {
        issecretvalue = function(v) return v == SECRET end,
        pcall = pcall, type = type, tostring = tostring, string = string,
        math = math, ipairs = ipairs, pairs = pairs, table = table, rawget = rawget,
        C_InputInterfaceStyle = { GetCurrentStyle = function() return 0 end },
        C_ActionBar = {
            HasOverrideActionBar = function() return false end,
            IsPossessBarVisible = function() return conds["[possessbar]"] == true end,
            HasVehicleActionBar = function() return false end,
            HasBonusActionBar = function() return false end,
            GetBonusBarOffset = function() return 0 end,
            GetActionBarPage = function() return 1 end,
            HasAction = function(slot) return slot == 1 end,
        },
    }
    if not opts.noParser then
        -- Minimal evaluator of "[c1][c2] X; Y; Z": clauses are tried in
        -- order, bracket groups in one clause are OR-ed, a clause without
        -- brackets always matches. Enough for the drivers the probe reads.
        env.SecureCmdOptionParse = function(expr)
            for clause in (expr .. ";"):gmatch("([^;]+);") do
                local rest = clause:gsub("^%s+", "")
                local matched, hasCond = false, false
                while rest:sub(1, 1) == "[" do
                    local cond = rest:match("^%b[]")
                    hasCond = true
                    if conds[cond] then matched = true end
                    rest = rest:sub(#cond + 1)
                end
                if matched or not hasCond then
                    return (rest:gsub("^%s+", ""):gsub("%s+$", ""))
                end
            end
            return nil
        end
    end
    -- Secure-handler stubs for the self-test. `opts.secureBroken` makes
    -- every primitive a no-op, like a client where they silently fail.
    env.select = select
    env.InCombatLockdown = function() return opts.combat == true end
    env.UIParent = {}
    env.CreateFrame = function(_, _, _, template)
        local fr = { attrs = {}, refs = {} }
        function fr:GetAttribute(k) return self.attrs[k] end
        function fr:SetAttribute(k, v) self.attrs[k] = v end
        function fr:SetFrameRef(label, ref)
            if opts.secureBroken then return end
            self.attrs["frameref-" .. label] = ref
        end
        function fr:Execute(body)
            if opts.secureBroken then return end
            -- Tiny interpreter for the two probe bodies.
            local k, v = body:match('^self:SetAttribute%("([^"]+)", "([^"]+)"%)$')
            if k then self.attrs[k] = v; return end
            local label, ok = body:match('GetFrameRef%("([^"]+)"%).-r and "([^"]+)"')
            if label then
                self.attrs["tomo-probe-ref"] = self.attrs["frameref-" .. label] and ok or "none"
            end
        end
        return fr
    end
    env._G = env
    return env
end

local function Run(env)
    local chunk = assert(loadstring(block, "=ACTION BAR PROBE"))
    setfenv(chunk, env)
    local describe = chunk()
    local lines = {}
    local okCall, err = pcall(describe, lines)
    return okCall, err, table.concat(lines, "\n")
end

-- ---------------------------------------------------------------------
-- 1-3. Conteneur caché par le driver, premier bouton, SafeCall
-- ---------------------------------------------------------------------
print("Scénario Forever : conteneur caché par [possessbar]")
do
    local env = MakeEnv({ conds = { ["[possessbar]"] = true } })
    local container = Frame({ shown = false, name = "TUI_ActionBar_bar1",
        attrs = { ["qui-user-shown"] = true, ["state-tuivis"] = "hide" },
        rel = Frame({ name = "UIParent" }) })
    local icon = Frame({ texture = 135274 })
    local btn = Frame({ name = "TUI_Bar1Button1", parent = container, visible = false })
    btn.icon = icon
    local mover = Frame({ name = "TomoMod_ActionBarMover_bar1" })
    mover.IsMouseEnabled = function() return true end
    local states = {}
    env.TomoModDB = { actionBars = { enabled = true, engine = "owned" } }
    env.TomoMod_TuiNS = {
        ActionBarsOwned = {
            initialized = true, editModeActive = false,
            containers = { bar1 = container }, nativeButtons = { bar1 = { btn } },
            editOverlays = { bar1 = mover },
        },
        ActionBarsEnv = {
            ALL_MANAGED_BAR_KEYS = { "bar1", "bar2" },
            GetFrameState = function(f)
                states[f] = states[f] or { visibilityDriver = "[overridebar][vehicleui][possessbar][petbattle] hide; show" }
                return states[f]
            end,
            GetSafeActionSlot = function() return 1 end,
        },
        SafeCallStats = function()
            return { badpolicy = 0, ["best-effort-style"] = { expected = 3, unexpected = 0, secretErr = 1 } }
        end,
    }
    local good, err, out = Run(env)
    expect("la sonde ne lève pas", good)
    if not good then print("    " .. tostring(err)) end
    expect("en-tête présent", out:find("--- Action Bars ---", 1, true) ~= nil)
    expect("module décrit", out:find("Module: enabled=true engine=owned initialized=true", 1, true) ~= nil)
    expect("possessbar à YES", out:find("possessbar=YES", 1, true) ~= nil)
    expect("overridebar à no", out:find("overridebar=no", 1, true) ~= nil)
    expect("bar1 : conteneur non montré", out:find("bar1: shown=false", 1, true) ~= nil)
    expect("bar1 : driver évalué à hide", out:find("-> hide", 1, true) ~= nil)
    expect("bar1 : state-tuivis=hide", out:find("state-tuivis=hide", 1, true) ~= nil)
    expect("bar1 : ancre vers UIParent", out:find("anchor=BOTTOM->UIParent", 1, true) ~= nil)
    expect("boutons comptés", out:find("buttons: 1 total, 1 shown, 0 visible", 1, true) ~= nil)
    expect("btn1 : slot, hasAction, texture", out:find("slot=1 hasAction=true iconShown=true iconTex=135274", 1, true) ~= nil)
    expect("bar2 absente signalée", out:find("bar2: no container", 1, true) ~= nil)
    expect("SafeCall compté", out:find("best-effort-style=3/0/1", 1, true) ~= nil)
    expect("mover décrit", out:find("mover: shown=true", 1, true) ~= nil and out:find("mouse=true", 1, true) ~= nil)
    expect("refs du layout handler absents signalés", out:find("layoutRef=no-handler", 1, true) ~= nil)
    expect("auto-test sécurisé OK sur client sain",
        out:find("Secure handler self-test: Execute=ok SetFrameRef=ok GetFrameRef=ok", 1, true) ~= nil)
    if os.getenv("PROBE_PRINT") then print(out) end
end

-- ---------------------------------------------------------------------
-- 4. Robustesse
-- ---------------------------------------------------------------------
print("Robustesse")
do
    local env = MakeEnv({})
    local good, _, out = Run(env)
    expect("moteur absent : pas d'erreur", good)
    expect("moteur absent : signalé", out:find("(action bar engine not loaded)", 1, true) ~= nil)
end
do
    local env = MakeEnv({ noParser = true })
    local throwing = Frame({ name = "Boom" })
    throwing.IsShown = function() error("boom") end
    throwing.GetAttribute = function() error("boom") end
    env.TomoMod_TuiNS = {
        ActionBarsOwned = { initialized = true, containers = { bar1 = throwing },
                            nativeButtons = { bar1 = { throwing } } },
        ActionBarsEnv = { ALL_MANAGED_BAR_KEYS = { "bar1" },
                          GetSafeActionSlot = function() return SECRET end },
    }
    env.C_ActionBar = nil
    local good, err, out = Run(env)
    expect("méthodes qui lèvent, parseur absent : pas d'erreur", good)
    if not good then print("    " .. tostring(err)) end
    expect("parseur absent : conditions à ?", out:find("overridebar=?", 1, true) ~= nil)
    expect("slot secret masqué", out:find("slot=<secret>", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------
-- 5. Câblage sécurisé : cas Forever
-- ---------------------------------------------------------------------
print("Câblage sécurisé (cas Forever : refs manquants, action=nil)")
do
    local env = MakeEnv({ secureBroken = true })
    local container = Frame({ name = "TUI_ActionBar_bar1" })
    container.IsProtected = function() return true, true end
    container.IsForbidden = function() return false end
    local btn = Frame({ name = "TUI_Bar1Button1", parent = container, attrs = { index = 1 } })
    env.TUI_ActionBarLayoutHandler = Frame({ name = "TUI_ActionBarLayoutHandler", attrs = {} })
    env.TomoMod_TuiNS = {
        ActionBarsOwned = { initialized = true, containers = { bar1 = container },
                            nativeButtons = { bar1 = { btn } } },
        ActionBarsEnv = { ALL_MANAGED_BAR_KEYS = { "bar1" } },
    }
    local good, err, out = Run(env)
    expect("pas d'erreur", good)
    if not good then print("    " .. tostring(err)) end
    expect("layoutRef MISSING", out:find("layoutRef=MISSING btn1Ref=MISSING", 1, true) ~= nil)
    expect("protected / forbidden lus", out:find("protected=true forbidden=false", 1, true) ~= nil)
    expect("action nil, index 1", out:find("btn1.action=nil btn1.index=1", 1, true) ~= nil)
    expect("auto-test en échec signalé",
        out:find("Execute=FAILED SetFrameRef=FAILED GetFrameRef=FAILED", 1, true) ~= nil)
end
do
    local env = MakeEnv({ combat = true })
    env.TomoMod_TuiNS = { ActionBarsOwned = { initialized = true, containers = {} },
                          ActionBarsEnv = { ALL_MANAGED_BAR_KEYS = {} } }
    local _, _, out = Run(env)
    expect("auto-test sauté en combat", out:find("self-test: skipped (in combat)", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------
-- 6. Capture précoce
-- ---------------------------------------------------------------------
print("Capture précoce des erreurs (avant PLAYER_LOGIN)")
do
    local es = src:find("local EARLY_LIMIT", 1, true)
    local ee = src:find("-- BOOT", es or 1, true)
    assert(es and ee and es < ee, "bloc EARLY CAPTURE introuvable")
    local early = src:sub(es, ee - 1):gsub("%-%- =+%s*$", "")
        .. "\nreturn EarlyErrorHandler, ReleaseEarlyCapture, earlyErrors\n"

    local forwarded = {}
    local original = function(m) forwarded[#forwarded + 1] = m end
    local handler = original
    local captured = {}
    local stacks = {
        ["boom"] = "Interface/AddOns/TomoMod/Modules/Interface/ActionBars/tui/actionbars_builder.lua:171",
        ["restricted"] = "Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua:58",
        ["other"] = "Interface/AddOns/SomeAddon/core.lua:3",
    }
    local current
    local env = {
        pcall = pcall, ipairs = ipairs, tostring = tostring, type = type,
        geterrorhandler = function() return handler end,
        seterrorhandler = function(h) handler = h end,
        debugstack = function() return stacks[current] or "" end,
        debuglocals = function() return "" end,
        wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
        SafeToString = tostring,
        IsStackOverflow = function() return false end,
        IsTomoModError = function(m, s) return ((m or "") .. (s or "")):find("TomoMod") ~= nil end,
        IsBlizzardOnlyError = function() return false end,
        IsTaintMessage = function() return false end,
        KIND_TAINT = "Taint", KIND_LUA_ERROR = "LuaError",
        CaptureEntry = function(kind, msg, stack, locals, meta)
            captured[#captured + 1] = { kind = kind, msg = msg, meta = meta }
        end,
        db = nil,
    }
    env.pairs = pairs
    local chunk = assert(loadstring(early, "=EARLY CAPTURE"))
    setfenv(chunk, env)
    local early_h, release = chunk()
    expect("installé dès le chargement", handler == early_h)

    for _, m in ipairs({ "boom", "restricted", "other" }) do
        current = m
        handler(m)
    end
    expect("transmis au gestionnaire précédent", #forwarded == 3)

    release(true)
    expect("gestionnaire précédent rendu", handler == original)
    expect("2 erreurs classées (TomoMod + code restreint)", #captured == 2)
    expect("marquées phase=load", captured[1] and captured[1].meta and captured[1].meta.phase == "load")
    local sawOther = false
    for _, c in ipairs(captured) do if c.msg == "other" then sawOther = true end end
    expect("erreur d'un autre addon ignorée (captureAll off)", not sawOther)

    -- A second release must not file anything again nor touch the chain.
    local replaced = function() end
    handler = replaced
    release(true)
    expect("pas de double classement", #captured == 2)
    expect("gestionnaire remplacé par un tiers laissé en place", handler == replaced)
end

print(ok and "\nTOUT EST VERT" or "\nDES TESTS ONT ÉCHOUÉ")
os.exit(ok and 0 or 1)
