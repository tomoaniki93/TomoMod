-- =====================================
-- MicroBar.lua — Custom micro menu bar
--
-- Builds a standalone bar of buttons that FORWARD their click to the native
-- Blizzard micro buttons instead of reimplementing what those buttons do.
-- The forwarders are SecureActionButtons with type="click" / clickbutton=<native>,
-- so every entry keeps working in combat without a single protected call of ours.
--
-- The native MicroMenu is not hidden with Hide(): it stays shown (its buttons are
-- our click targets, and a hidden protected button cannot be clicked from secure
-- code), it is only made invisible and mouse-transparent. That also keeps
-- EditMode's layout manager from fighting us.
--
-- Icon art is READ FROM the native buttons at runtime rather than shipped as
-- files. No assets to maintain, and the bar follows whatever Blizzard ships next
-- patch for free.
-- =====================================

TomoMod_MicroBar = TomoMod_MicroBar or {}
local MB = TomoMod_MicroBar
local L = TomoMod_L

local FONT_LABEL = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local TEAL       = { r = 0.18, g = 0.85, b = 0.62 }
local FALLBACK_ICON = 134400   -- inv_misc_questionmark

local Glow     = TomoMod_NativeGlow
local GLOW_KEY = "TomoModMicroBar"

-- Same vocabulary as ClassReminder so a player meets one set of glow names
-- across the addon, and so a profile stays readable.
local GLOW_NONE     = "None"
local GLOW_PIXEL    = "Pixel Glow"
local GLOW_AUTOCAST = "Autocast Shine"
local GLOW_BUTTON   = "Action Button Glow"
local GLOW_PROC     = "Proc Glow"

MB.GLOW_TYPES = { GLOW_NONE, GLOW_PIXEL, GLOW_AUTOCAST, GLOW_BUTTON, GLOW_PROC }

-- =====================================
-- BUTTON DEFINITIONS
-- =====================================
-- `native` is resolved lazily: HousingMicroButton only exists on 12.x, and a
-- future patch may retire any of these. A def whose native frame is absent is
-- skipped entirely rather than rendered as a dead button.
--
-- `bindings` lists candidate binding actions, first match wins. The micro
-- buttons bake their keybind into tooltipText but never expose the action name,
-- so this is the one place the lot has to name Blizzard identifiers. An entry
-- that stops resolving degrades to "no hotkey shown", never to an error.

local BUTTON_DEFS = {
    { key = "character",   native = "CharacterMicroButton",      labelKey = "microbar_btn_character",
      bindings = { "TOGGLECHARACTER0" } },
    { key = "spells",      native = "PlayerSpellsMicroButton",   labelKey = "microbar_btn_spells",
      bindings = { "TOGGLEPLAYERSPELLS", "TOGGLESPELLBOOK", "TOGGLETALENTS" } },
    { key = "profession",  native = "ProfessionMicroButton",     labelKey = "microbar_btn_profession",
      bindings = { "TOGGLEPROFESSIONBOOK" } },
    { key = "achievement", native = "AchievementMicroButton",    labelKey = "microbar_btn_achievement",
      bindings = { "TOGGLEACHIEVEMENT" } },
    { key = "quest",       native = "QuestLogMicroButton",       labelKey = "microbar_btn_quest",
      bindings = { "TOGGLEQUESTLOG" } },
    { key = "guild",       native = "GuildMicroButton",          labelKey = "microbar_btn_guild",
      bindings = { "TOGGLEGUILDTAB" } },
    { key = "lfd",         native = "LFDMicroButton",            labelKey = "microbar_btn_lfd",
      bindings = { "TOGGLEGROUPFINDER", "TOGGLELFGPARENT" } },
    { key = "collections", native = "CollectionsMicroButton",    labelKey = "microbar_btn_collections",
      bindings = { "TOGGLECOLLECTIONS" } },
    { key = "ej",          native = "EJMicroButton",             labelKey = "microbar_btn_ej",
      bindings = { "TOGGLEENCOUNTERJOURNAL" } },
    { key = "housing",     native = "HousingMicroButton",        labelKey = "microbar_btn_housing" },
    { key = "social",      native = "QuickJoinToastButton",      labelKey = "microbar_btn_social",
      bindings = { "TOGGLESOCIAL", "TOGGLEFRIENDSTAB" } },
    { key = "store",       native = "StoreMicroButton",          labelKey = "microbar_btn_store"       },
    { key = "bags",        native = "MainMenuBarBackpackButton", labelKey = "microbar_btn_bags",
      bindings = { "OPENALLBAGS", "TOGGLEBACKPACK" } },
    { key = "mainmenu",    native = "MainMenuMicroButton",       labelKey = "microbar_btn_mainmenu",
      bindings = { "TOGGLEGAMEMENU" }, memory = true },
}

local DEF_BY_KEY = {}
for _, def in ipairs(BUTTON_DEFS) do DEF_BY_KEY[def.key] = def end

-- Native regions we mute when the bar takes over. MicroMenu covers the micro
-- buttons; the backpack lives on its own bar and is left to BagMicroMenu.
local NATIVE_BUTTONS = {
    "CharacterMicroButton", "PlayerSpellsMicroButton", "ProfessionMicroButton",
    "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
    "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
    "HousingMicroButton", "StoreMicroButton", "MainMenuMicroButton",
    "QuickJoinToastButton",
}

-- =====================================
-- STATE
-- =====================================

local anchor          -- created at file scope below
local buttons         = {}     -- [key] = our forwarder button
local placed          = {}     -- ordered list of the buttons currently laid out
local isLocked        = true
local dragOverlay, dragLabel
local nativeMuted     = false
local pendingRebuild  = false
local pendingNative   = false
local refreshThrottled = false
local initialized     = false
local pulsing         = {}     -- [native button name] = true while it alerts

local function GetDB()
    return TomoModDB and TomoModDB.microBar
end

-- =====================================
-- ANCHOR
-- =====================================
-- Shown once and never hidden again: it parents protected buttons, and hiding
-- the parent of a protected frame in combat is exactly the call that propagates
-- taint. Visibility rides on alpha instead.

anchor = CreateFrame("Frame", "TomoMod_MicroBarFrame", UIParent)
anchor:SetSize(1, 1)
anchor:SetFrameStrata("MEDIUM")
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:EnableMouse(false)
anchor:Show()
anchor:SetAlpha(0)

-- =====================================
-- POSITION
-- =====================================
-- Screen-absolute coordinates read from GetLeft/GetBottom. GetPoint after
-- StartMoving hands back the engine's re-anchor point, not the placement the
-- user actually intended.

local function SavePosition()
    local db = GetDB()
    if not db then return end
    local left, bottom = anchor:GetLeft(), anchor:GetBottom()
    if not left or not bottom then return end
    local s = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    db.position = {
        point         = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x             = left * s,
        y             = bottom * s,
    }
end

local function ApplyPosition()
    if InCombatLockdown() then return end
    local db = GetDB()
    anchor:ClearAllPoints()
    local p = db and db.position
    if p and p.point then
        anchor:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 180)
    end
end

-- =====================================
-- ICON RESOLUTION
-- =====================================

local function ResolveArt(native)
    if not native then return nil end

    local tex = native.GetNormalTexture and native:GetNormalTexture()
    if tex then
        local atlas = tex.GetAtlas and tex:GetAtlas()
        if atlas and atlas ~= "" then return "atlas", atlas end
        local file = tex.GetTexture and tex:GetTexture()
        if file and file ~= "" then return "texture", file end
    end

    -- QuickJoinToastButton and friends carry their art on a child region.
    local icon = native.Icon or native.icon or native.Background
    if icon then
        local atlas = icon.GetAtlas and icon:GetAtlas()
        if atlas and atlas ~= "" then return "atlas", atlas end
        local file = icon.GetTexture and icon:GetTexture()
        if file and file ~= "" then return "texture", file end
    end

    return nil
end

local function ApplyArt(icon, native, key)
    -- CharacterMicroButton carries no atlas and no static file: its art is the
    -- player portrait, pushed in by SetPortraitTexture. Reading GetTexture on
    -- it hands back a portrait texture ID that does not reproduce on another
    -- region, which renders as a plain square -- exactly what players report
    -- for the character sheet button and nothing else.
    if key == "character" and SetPortraitTexture then
        -- CharacterMicroButton has no atlas and no static file: its art is the
        -- player portrait, and Blizzard shapes it with a mask region --
        -- visible in a frame stack as
        --   CharacterMicroButton.PortraitMask : UI-HUD-MicroMenu-Portrait-Mask
        -- Applying the portrait alone gave a raw square that read bigger than
        -- its neighbours; a texcoord crop only approximated the shape. Reusing
        -- Blizzard's own mask gives the same silhouette as the native button,
        -- with no magic numbers to retune when the art changes.
        local ok = pcall(SetPortraitTexture, icon, "player")
        if ok then
            icon:SetTexCoord(0, 1, 0, 1)
            local parent = icon:GetParent()
            if parent and parent.CreateMaskTexture and not icon._mbPortraitMask then
                local mask = parent:CreateMaskTexture()
                mask:SetAllPoints(icon)
                local okMask = pcall(mask.SetAtlas, mask, "UI-HUD-MicroMenu-Portrait-Mask")
                if okMask then
                    pcall(icon.AddMaskTexture, icon, mask)
                    icon._mbPortraitMask = mask
                end
            elseif icon._mbPortraitMask then
                icon._mbPortraitMask:SetAllPoints(icon)
            end

            -- Blizzard also drops a shadow under the portrait
            -- (CharacterMicroButton.Shadow : UI-HUD-MicroMenu-Portrait-Shadow).
            -- Without it the masked portrait sits flat against the bar while
            -- the native button has depth. BACKGROUND so it stays under the
            -- portrait, and slightly oversized because the shadow atlas is
            -- drawn larger than the shape it sits behind.
            if parent and parent.CreateTexture and not icon._mbPortraitShadow then
                local shadow = parent:CreateTexture(nil, "BACKGROUND")
                local okShadow = pcall(shadow.SetAtlas, shadow, "UI-HUD-MicroMenu-Portrait-Shadow")
                if okShadow then
                    shadow:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
                    shadow:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
                    icon._mbPortraitShadow = shadow
                else
                    shadow:Hide()
                end
            end
            if icon._mbPortraitShadow then icon._mbPortraitShadow:Show() end

            return
        end
    end

    -- Any other button reaching here must not keep a shadow left over from a
    -- previous rebuild in which it was the character slot.
    if icon._mbPortraitShadow then icon._mbPortraitShadow:Hide() end

    local kind, value = ResolveArt(native)
    if kind == "atlas" then
        icon:SetAtlas(value, false)
    elseif kind == "texture" then
        icon:SetTexture(value)
    else
        icon:SetTexture(FALLBACK_ICON)
    end
end

local function GetTintColor()
    local db = GetDB()
    local mode = db and db.colorMode or "class"
    if mode == "native" then
        return 1, 1, 1
    elseif mode == "custom" then
        local c = db and db.color
        return (c and c.r) or 1, (c and c.g) or 1, (c and c.b) or 1
    end
    local r, g, b = TomoMod_Utils.GetClassColor("player")
    return r, g, b
end

-- =====================================
-- STATE PARITY — alert glow
-- =====================================
-- The bar's whole premise is that the native buttons keep running underneath.
-- That means their alert logic (new talent point, unread adventure guide entry,
-- LFD eligibility...) still fires; it just fires on a button nobody can see.
-- MicroButtonPulse / MicroButtonPulseStop are the two globals every one of those
-- code paths funnels through, so hooking them mirrors the signal without
-- depending on which texture Blizzard flashes this expansion.

local function StopGlow(f)
    if not (Glow and f) then return end
    Glow.PixelGlow_Stop(f, GLOW_KEY)
    Glow.AutoCastGlow_Stop(f, GLOW_KEY)
    Glow.ProcGlow_Stop(f, GLOW_KEY)
    Glow.ButtonGlow_Stop(f, GLOW_KEY)
end

local function StartGlow(f)
    StopGlow(f)
    if not (Glow and f) then return end
    local db = GetDB()
    local kind = (db and db.alertStyle) or GLOW_PIXEL
    if kind == GLOW_NONE then return end

    local c = db and db.alertColor
    local col = f._mbGlowColor
    if not col then col = {}; f._mbGlowColor = col end
    col[1] = (c and c.r) or 1.0
    col[2] = (c and c.g) or 0.82
    col[3] = (c and c.b) or 0.20
    col[4] = 1

    if kind == GLOW_PIXEL then
        Glow.PixelGlow_Start(f, col, 8, 0.25, nil, 2, 0, 0, false, GLOW_KEY)
    elseif kind == GLOW_AUTOCAST then
        Glow.AutoCastGlow_Start(f, col, 4, 0.25, 1, 0, 0, GLOW_KEY)
    elseif kind == GLOW_BUTTON then
        Glow.ButtonGlow_Start(f, col, 0.125, GLOW_KEY)
    elseif kind == GLOW_PROC then
        Glow.ProcGlow_Start(f, {
            color = col, startAnim = false, xOffset = 0, yOffset = 0, key = GLOW_KEY,
        })
    end
end

-- =====================================
-- STATE PARITY — keybind hints
-- =====================================

local function AbbreviateBinding(key)
    if not key or key == "" then return nil end
    key = key:upper()
    key = key:gsub("ALT%-", "a")
    key = key:gsub("CTRL%-", "c")
    key = key:gsub("SHIFT%-", "s")
    key = key:gsub("META%-", "m")
    key = key:gsub("MOUSEWHEELUP", "WU")
    key = key:gsub("MOUSEWHEELDOWN", "WD")
    key = key:gsub("NUMPAD", "N")
    key = key:gsub("BUTTON", "M")
    key = key:gsub("BACKSPACE", "BS")
    key = key:gsub("CAPSLOCK", "Cp")
    key = key:gsub("PAGEUP", "PU")
    key = key:gsub("PAGEDOWN", "PD")
    key = key:gsub("DELETE", "Del")
    key = key:gsub("INSERT", "Ins")
    key = key:gsub("SPACE", "Sp")
    return key
end

local function ResolveBinding(def)
    if not (def.bindings and GetBindingKey) then return nil end
    for _, action in ipairs(def.bindings) do
        local key = GetBindingKey(action)
        if key then return AbbreviateBinding(key) end
    end
    return nil
end

-- =====================================
-- STATE PARITY — refresh
-- =====================================
-- Disabled mirroring is deliberately visual only. Enable()/Disable() on a
-- protected button is a restricted call, and it would buy nothing: forwarding a
-- click to a disabled native button already does nothing, because its OnClick
-- never fires. So we dim, and let the engine keep owning the actual gate.

local function RefreshStates()
    local db = GetDB()
    if not db or not db.enabled then return end

    local dim      = db.dimDisabled
    local dimAlpha = db.disabledAlpha or 0.35
    local desat    = db.desaturate and true or false

    for i = 1, #placed do
        local btn = placed[i]
        local def = btn._def
        local native = def and _G[def.native]

        local enabled = true
        if native and native.IsEnabled then
            enabled = native:IsEnabled() and true or false
        end

        if dim and not enabled then
            btn:SetAlpha(dimAlpha)
            btn.icon:SetDesaturated(true)
        else
            btn:SetAlpha(1)
            btn.icon:SetDesaturated(desat)
        end

        -- A disabled button has nothing to alert about; drop the glow with it.
        if def and pulsing[def.native] and enabled then
            if not btn._mbGlowing then
                btn._mbGlowing = true
                StartGlow(btn)
            end
        elseif btn._mbGlowing then
            btn._mbGlowing = false
            StopGlow(btn)
        end
    end
end

local function SetPulse(native, on, duration)
    if type(native) ~= "table" or not native.GetName then return end
    local name = native:GetName()
    if not name then return end

    pulsing[name] = on or nil
    RefreshStates()

    -- MicroButtonPulse takes an optional duration and simply lets the flash
    -- expire; no Stop call ever arrives. Expire our glow on the same clock.
    if on and duration and duration > 0 then
        C_Timer.After(duration, function()
            if pulsing[name] then
                pulsing[name] = nil
                RefreshStates()
            end
        end)
    end
end

if type(MicroButtonPulse) == "function" then
    hooksecurefunc("MicroButtonPulse", function(native, duration)
        SetPulse(native, true, duration)
    end)
end

if type(MicroButtonPulseStop) == "function" then
    hooksecurefunc("MicroButtonPulseStop", function(native)
        SetPulse(native, false)
    end)
end

-- =====================================
-- ADDON MEMORY (tooltip on the menu button)
-- =====================================

local MEM_TTL = 5
local memCache = { total = 0, list = {}, stamp = -1 }

local function FormatMemory(kb)
    if kb >= 1024 then return string.format("%.2f MB", kb / 1024) end
    return string.format("%d KB", math.floor(kb + 0.5))
end

-- scriptProfile is a CVar the player sets and reloads into; when it is off,
-- GetAddOnCPUUsage answers zero for everything and a CPU column would be a
-- row of lies. Read once here and reported as "disabled" rather than 0.
local cpuProfiling = false
local cpuCache = { total = 0, stamp = -1, list = {} }

local function RefreshCPU()
    cpuProfiling = (GetCVar and GetCVar("scriptProfile") == "1") and true or false
    if not cpuProfiling or not UpdateAddOnCPUUsage then return end

    local now = GetTime()
    if cpuCache.stamp >= 0 and (now - cpuCache.stamp) < MEM_TTL then return end
    UpdateAddOnCPUUsage()

    local count = (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns())
        or (GetNumAddOns and GetNumAddOns()) or 0
    local total = 0
    for i = 1, count do
        total = total + ((GetAddOnCPUUsage and GetAddOnCPUUsage(i)) or 0)
    end
    cpuCache.total = total
    cpuCache.stamp = now
end

local function RefreshMemory()
    local now = GetTime()
    if memCache.stamp >= 0 and (now - memCache.stamp) < MEM_TTL then return end
    if not UpdateAddOnMemoryUsage then return end
    UpdateAddOnMemoryUsage()

    local count = (C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns())
        or (GetNumAddOns and GetNumAddOns()) or 0
    local total, list = 0, {}
    for i = 1, count do
        local name, title
        if C_AddOns and C_AddOns.GetAddOnInfo then
            name, title = C_AddOns.GetAddOnInfo(i)
        end
        local mem = GetAddOnMemoryUsage and GetAddOnMemoryUsage(i) or 0
        if name and mem and mem > 0 then
            total = total + mem
            list[#list + 1] = { name = title or name, mem = mem }
        end
    end
    table.sort(list, function(a, b) return a.mem > b.mem end)

    memCache.total = total
    memCache.list  = list
    memCache.stamp = now
end

-- =====================================
-- TOOLTIP
-- =====================================

local function ShowTooltip(self)
    local def = self._def
    if not def then return end
    local native = _G[def.native]

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    -- The native button already builds a localized title WITH its keybind
    -- appended, so prefer it and fall back to our own label only if absent.
    local title = (native and native.tooltipText) or L[def.labelKey]
    GameTooltip:AddLine(title, 1, 1, 1, true)

    if def.memory and (GetDB() or {}).memoryTooltip then
        RefreshMemory()
        RefreshCPU()

        -- Performance block above the per-addon list: framerate and latency
        -- are what a player actually wants when they hover this button, and
        -- both are cheap. CPU is only meaningful when the client is recording
        -- it, which is off by default -- say so instead of showing zeroes.
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["microbar_tt_perf"], 0.4, 0.8, 1)
        GameTooltip:AddDoubleLine(L["microbar_tt_fps"],
            string.format("%.0f", GetFramerate and GetFramerate() or 0),
            1, 0.82, 0, 1, 1, 1)
        local home, world = 0, 0
        if GetNetStats then
            local _, _, h, w = GetNetStats()
            home, world = h or 0, w or 0
        end
        GameTooltip:AddDoubleLine(L["microbar_tt_latency"],
            string.format("%d / %d ms", home, world), 1, 0.82, 0, 1, 1, 1)

        if cpuProfiling then
            GameTooltip:AddDoubleLine(L["microbar_tt_cpu"],
                string.format("%.1f ms", cpuCache.total), 1, 0.82, 0, 1, 1, 1)
        else
            GameTooltip:AddDoubleLine(L["microbar_tt_cpu"], L["microbar_tt_cpu_off"],
                1, 0.82, 0, 0.6, 0.6, 0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["microbar_tt_memory"], 0.4, 0.8, 1)
        GameTooltip:AddDoubleLine(L["microbar_tt_total"], FormatMemory(memCache.total),
            1, 0.82, 0, 1, 0.82, 0)
        for i = 1, math.min(15, #memCache.list) do
            local a = memCache.list[i]
            GameTooltip:AddDoubleLine(a.name, FormatMemory(a.mem), 1, 1, 1, 0.8, 0.8, 0.8)
        end
    end

    GameTooltip:Show()
end

-- =====================================
-- FADE
-- =====================================

local hovered = false

local function TargetAlpha()
    local db = GetDB()
    if not db or not db.enabled then return 0 end
    local shown = db.alpha or 1
    local mode  = db.fadeMode or "always"

    if mode == "always" then return shown end
    if hovered then return shown end
    if mode == "hovercombat" and UnitAffectingCombat("player") then return shown end
    return db.fadeAlpha or 0
end

local function ApplyAlpha(instant)
    local db = GetDB()
    local target = TargetAlpha()
    local current = anchor:GetAlpha()
    if instant or math.abs(current - target) < 0.01 then
        anchor:SetAlpha(target)
        return
    end
    -- UIFrameFadeIn calls frame:Show() unconditionally. OnButtonEnter/OnButtonLeave
    -- run as OnEnter/OnLeave script handlers on a SecureActionButtonTemplate button,
    -- so that Show() executes as a protected call and gets blocked in combat
    -- (ADDON_ACTION_BLOCKED on TomoMod_MicroBarFrame:Show()). Snap instead of
    -- animating while locked down: no fade, but no blocked call either.
    if InCombatLockdown() then
        anchor:SetAlpha(target)
        return
    end
    local dur = (target > current) and (db and db.fadeIn or 0.15) or (db and db.fadeOut or 0.25)
    if dur <= 0 then
        anchor:SetAlpha(target)
    else
        UIFrameFadeIn(anchor, dur, current, target)
    end
end

local function OnButtonEnter(self)
    hovered = true
    ApplyAlpha()
    ShowTooltip(self)
    local db = GetDB()
    if db and db.hoverZoom and self.icon then
        local s = (db.iconSize or 26) * 1.18
        self.icon:SetSize(s, s)
    end
end

local function OnButtonLeave(self)
    GameTooltip:Hide()
    local db = GetDB()
    if db and db.hoverZoom and self.icon then
        local s = db.iconSize or 26
        self.icon:SetSize(s, s)
    end
    C_Timer.After(0.1, function()
        if anchor:IsMouseOver() then return end
        hovered = false
        ApplyAlpha()
    end)
end

-- =====================================
-- BUTTON POOL
-- =====================================

local function AcquireButton(def)
    local btn = buttons[def.key]
    if btn then return btn end

    btn = CreateFrame("Button", "TomoMod_MicroBarButton_" .. def.key, anchor,
        "SecureActionButtonTemplate")
    btn:RegisterForClicks("AnyUp")
    btn:SetAttribute("useOnKeyDown", false)
    btn._def = def

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetPoint("CENTER")

    -- OVERLAY so it survives the hover zoom, which only resizes the icon.
    btn.hotkey = btn:CreateFontString(nil, "OVERLAY")
    btn.hotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 1, 1)
    btn.hotkey:SetJustifyH("RIGHT")
    btn.hotkey:Hide()

    btn:SetScript("OnEnter", OnButtonEnter)
    btn:SetScript("OnLeave", OnButtonLeave)

    btn:Hide()
    buttons[def.key] = btn
    return btn
end

-- =====================================
-- ORDER / SELECTION
-- =====================================

local function BuildOrderedList()
    local db = GetDB()
    if not db then return {} end

    local seen, list = {}, {}

    for _, key in ipairs(db.order or {}) do
        local def = DEF_BY_KEY[key]
        if def and not seen[key] then
            seen[key] = true
            if db.buttons and db.buttons[key] and _G[def.native] then
                list[#list + 1] = def
            end
        end
    end
    -- Defs added by a later version are not in a saved order yet; append them
    -- so an upgrade never silently drops a button.
    for _, def in ipairs(BUTTON_DEFS) do
        if not seen[def.key] and db.buttons and db.buttons[def.key] and _G[def.native] then
            list[#list + 1] = def
        end
    end

    return list
end

-- =====================================
-- REBUILD
-- =====================================

local function Rebuild()
    local db = GetDB()
    if not db then return end

    -- Everything below touches secure buttons: attributes, Show/Hide, parenting.
    -- All of it is out-of-combat only; the request is replayed on REGEN_ENABLED.
    if InCombatLockdown() then
        pendingRebuild = true
        -- Alpha is not a protected call, so visibility settings still take
        -- effect immediately; only the secure work waits for REGEN_ENABLED.
        ApplyAlpha()
        return
    end
    pendingRebuild = false

    for _, btn in pairs(buttons) do
        btn:Hide()
        btn:ClearAllPoints()
        -- A glow is a child frame of the button; leaving one running on a
        -- button we just removed from the layout would keep animating offscreen.
        if btn._mbGlowing then
            btn._mbGlowing = false
            StopGlow(btn)
        end
    end
    wipe(placed)

    if not db.enabled then
        anchor:SetAlpha(0)
        return
    end

    local list = BuildOrderedList()
    if #list == 0 then
        anchor:SetAlpha(0)
        return
    end

    local size    = db.iconSize or 26
    local spacing = db.spacing or 4
    local r, g, b = GetTintColor()

    for _, def in ipairs(list) do
        local native = _G[def.native]
        local btn = AcquireButton(def)

        btn:SetAttribute("type1", "click")
        btn:SetAttribute("clickbutton1", native)

        btn:SetSize(size, size)
        btn.icon:SetSize(size, size)
        ApplyArt(btn.icon, native, def.key)
        btn.icon:SetDesaturated(db.desaturate and true or false)
        btn.icon:SetVertexColor(r, g, b)

        local hotkey = db.showKeybind and ResolveBinding(def) or nil
        if hotkey then
            btn.hotkey:SetFont(FONT_LABEL, db.keybindSize or 10, "OUTLINE")
            btn.hotkey:SetText(hotkey)
            btn.hotkey:SetTextColor(1, 1, 1, 0.9)
            btn.hotkey:Show()
        else
            btn.hotkey:Hide()
        end

        placed[#placed + 1] = btn
    end

    -- Grid. perLine == 0 means a single row (horizontal) or column (vertical).
    local vertical = (db.orientation == "vertical")
    local perLine  = db.perLine or 0
    if perLine <= 0 then perLine = #placed end

    local lines = math.ceil(#placed / perLine)
    local step  = size + spacing

    for i, btn in ipairs(placed) do
        local slot = (i - 1) % perLine          -- position along the line
        local line = math.floor((i - 1) / perLine)
        local x, y
        if vertical then
            x = line * step
            y = -slot * step
        else
            x = slot * step
            y = -line * step
        end
        btn:SetPoint("TOPLEFT", anchor, "TOPLEFT", x, y)
        btn:Show()
    end

    local along  = math.min(perLine, #placed)
    local across = lines
    local w = along * size + math.max(0, along - 1) * spacing
    local h = across * size + math.max(0, across - 1) * spacing
    if vertical then w, h = h, w end
    anchor:SetSize(math.max(1, w), math.max(1, h))
    anchor:SetScale(db.scale or 1.0)

    ApplyPosition()
    ApplyAlpha(true)
    RefreshStates()
end

-- =====================================
-- NATIVE MICRO MENU
-- =====================================

-- Blizzard has moved the micro menu's container more than once, and the frame
-- was looked up by one hardcoded name with an early return when it was missing
-- -- so on a client where that name no longer resolves, ticking "hide the
-- Blizzard micro menu" did nothing at all, not even to the buttons.
local NATIVE_CONTAINERS = { "MicroMenu", "MicroMenuContainer", "MicroButtonAndBagsBar" }

-- QueueStatusButton hangs off MicroMenu/MicroMenuContainer on current Retail,
-- so MuteNative's alpha 0 on the container hides the Group Finder eye along
-- with it -- which is why the eye stopped appearing when queueing.
--
-- Reparent it to UIParent while we own the micro menu, so it survives the
-- mute, and hand it back untouched when the option is turned off. The real
-- Blizzard button is kept throughout: its click handlers and right-click
-- teleport menu come along for free.
--
-- POSITION IS DELIBERATELY NOT SET HERE. FrameAnchors already owns a
-- "queueStatus" anchor, and two systems calling ClearAllPoints/SetPoint on the
-- same frame from different triggers fight each other -- the frame jumps on
-- whichever fires last. This function does parent, scale, alpha and mouse;
-- FrameAnchors does placement.
local lfgEyeOriginalParent
local lfgEyeManaged = false
local lfgEyeHooked = false

local function ApplyLFGEye()
    if InCombatLockdown() then return end

    local btn = _G["QueueStatusButton"]
    if not btn then return end

    local db = GetDB() or {}
    local wantVisible = db.lfgEyeEnabled ~= false
    local wantDetached = (db.enabled and db.hideNative == true and wantVisible) and true or false

    -- Scale applies regardless of detachment: leaving it gated behind
    -- wantDetached meant the size slider silently did nothing unless Micro
    -- Bar was enabled AND "hide native micro menu" was on, since the other
    -- branch below unconditionally reset it back to 1 every time.
    btn:SetScale(tonumber(db.lfgEyeScale) or 1.0)

    if wantDetached then
        if not lfgEyeManaged then
            lfgEyeOriginalParent = btn:GetParent()
            if not pcall(btn.SetParent, btn, UIParent) then return end
            lfgEyeManaged = true
        end
        btn:SetAlpha(1)
        btn:EnableMouse(true)

        local FA = TomoMod_FrameAnchors
        if FA and FA.ApplyAnchorByKey then FA.ApplyAnchorByKey("queueStatus") end
    else
        btn:SetAlpha(wantVisible and 1 or 0)
        btn:EnableMouse(wantVisible and true or false)

        if lfgEyeManaged and lfgEyeOriginalParent then
            local parent = lfgEyeOriginalParent
            lfgEyeManaged = false
            pcall(btn.SetParent, btn, parent)
            -- Let Blizzard put it back where it belongs rather than guessing.
            if type(btn.UpdatePosition) == "function" then
                pcall(btn.UpdatePosition, btn)
            end
        end
    end
end

local function HookLFGEye()
    if lfgEyeHooked then return end
    local btn = _G["QueueStatusButton"]
    if not btn or type(btn.UpdatePosition) ~= "function" then return end
    lfgEyeHooked = true

    -- MicroMenuMixin:Layout -> UpdateQueueStatusAnchors -> UpdatePosition
    -- re-anchors the eye without changing its parent, so our placement has to
    -- be re-asserted after Blizzard's pass. Deferred a frame so we run after it.
    hooksecurefunc(btn, "UpdatePosition", function()
        if not lfgEyeManaged or InCombatLockdown() then return end
        C_Timer.After(0, function()
            if not lfgEyeManaged or InCombatLockdown() then return end
            local FA = TomoMod_FrameAnchors
            if FA and FA.ApplyAnchorByKey then FA.ApplyAnchorByKey("queueStatus") end
        end)
    end)
end


local function MuteNative(mute)
    local a = mute and 0 or 1
    local touched = false

    for _, name in ipairs(NATIVE_CONTAINERS) do
        local mm = _G[name]
        if mm and mm.SetAlpha then
            mm:SetAlpha(a)
            if mm.EnableMouse then mm:EnableMouse(not mute) end
            touched = true
        end
    end

    -- The buttons are handled whether or not a container was found: they are
    -- what the player actually sees, and they answer to their own names.
    for _, name in ipairs(NATIVE_BUTTONS) do
        local btn = _G[name]
        if btn then
            btn:SetAlpha(a)
            btn:EnableMouse(not mute)
            touched = true
        end
    end

    return touched
end

local nativeMuteWarned = false

-- True while Blizzard's own Edit Mode window is open. `UpdateMicroButtons`
-- fires constantly (bag changes, talent points, LFD eligibility...) and its
-- hook below re-mutes the native containers on every call -- including,
-- reportedly, while Edit Mode's own setup is mid-refresh. Repeatedly
-- touching a frame Edit Mode also manages from ordinary Lua is exactly the
-- kind of taint that later shows up as an unrelated blocked call deep in
-- Blizzard's own code (e.g. `RefreshTargetAndFocus` -> `TargetUnit()`), so
-- the mute stands down entirely while Edit Mode owns the screen.
local function IsEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
        and EditModeManagerFrame:IsEditModeActive()
end

local function ApplyNative()
    if InCombatLockdown() then
        pendingNative = true
        return
    end
    pendingNative = false

    local db = GetDB()
    local shouldMute = (db and db.enabled and db.hideNative) and true or false
    -- Nothing to do, and nothing to give back: never touched the native bar.
    if not shouldMute and not nativeMuted then
        -- Still reconcile the eye: its own option can change while the native
        -- menu was never muted.
        HookLFGEye()
        ApplyLFGEye()
        return
    end

    if shouldMute and IsEditModeActive() then
        -- Leave the native bar alone for now; the ExitEditMode hook below
        -- re-applies the mute the moment Edit Mode closes.
        return
    end

    local touched = MuteNative(shouldMute)
    nativeMuted = shouldMute

    -- Say so when the option was asked for and nothing answered to it. A
    -- silent no-op here is exactly what made this bug take a report and a
    -- round trip to find: the box ticked, the bar stayed, nothing to go on.
    -- Warned once per session, since UpdateMicroButtons re-enters this often.
    HookLFGEye()
    ApplyLFGEye()

    if shouldMute and not touched and not nativeMuteWarned then
        nativeMuteWarned = true
        print("|cff2ed884TomoMod|r " ..
            (TomoMod_L and TomoMod_L["microbar_native_not_found"] or
             "could not find Blizzard's micro menu to hide"))
    end

    -- BagMicroMenu also drives the native menu's alpha; hand it back cleanly.
    if not shouldMute and TomoMod_BagMicroMenu and TomoMod_BagMicroMenu.ApplySettings then
        TomoMod_BagMicroMenu.ApplySettings()
    end
end

-- Blizzard re-asserts micro button state constantly (bag changes, talent
-- points, LFD eligibility...). UpdateMicroButtons is the single funnel for all
-- of it, so both the re-mute and the enabled/disabled mirroring ride on it
-- instead of polling.
if type(UpdateMicroButtons) == "function" then
    hooksecurefunc("UpdateMicroButtons", function()
        if refreshThrottled then return end
        local db = GetDB()
        if not nativeMuted and not (db and db.enabled) then return end
        refreshThrottled = true
        C_Timer.After(0.1, function()
            refreshThrottled = false
            if nativeMuted and not IsEditModeActive() then MuteNative(true) end
            RefreshStates()
        end)
    end)
end

-- Blizzard's real Edit Mode manages the native micro menu as one of its own
-- systems; if we keep re-muting it out from under Edit Mode's setup (the
-- UpdateMicroButtons hook above did exactly that), later Blizzard-internal
-- calls in that same setup pass (e.g. RefreshTargetAndFocus's TargetUnit())
-- can get blamed on TomoMod and blocked. Stand down for the duration and let
-- ExitEditMode put the mute back.
--
-- Deferred to Initialize (not file-load time): Blizzard_EditMode's load
-- timing relative to a regular addon isn't guaranteed the way UpdateMicroButtons
-- (a base FrameXML global) is.
local editModeHooksInstalled = false
local function InstallEditModeHooks()
    if editModeHooksInstalled or not EditModeManagerFrame then return end
    editModeHooksInstalled = true

    if type(EditModeManagerFrame.EnterEditMode) == "function" then
        hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
            if nativeMuted then MuteNative(false) end
        end)
    end
    if type(EditModeManagerFrame.ExitEditMode) == "function" then
        hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
            C_Timer.After(0, ApplyNative)
        end)
    end
end

-- Exposed so BagMicroMenu can stand down instead of fighting us over alpha.
function MB.OwnsNativeMenu()
    return nativeMuted
end

-- =====================================
-- PLACEMENT MODE
-- =====================================

local function CreateDragOverlay()
    if dragOverlay then return end
    dragOverlay = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
    dragOverlay:SetPoint("TOPLEFT", -4, 4)
    dragOverlay:SetPoint("BOTTOMRIGHT", 4, -4)
    dragOverlay:SetFrameLevel(anchor:GetFrameLevel() + 30)
    dragOverlay:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dragOverlay:SetBackdropColor(TEAL.r, TEAL.g, TEAL.b, 0.18)
    dragOverlay:SetBackdropBorderColor(TEAL.r, TEAL.g, TEAL.b, 0.80)
    dragOverlay:EnableMouse(true)
    dragOverlay:RegisterForDrag("LeftButton")
    dragOverlay:SetScript("OnDragStart", function() anchor:StartMoving() end)
    dragOverlay:SetScript("OnDragStop", function()
        anchor:StopMovingOrSizing()
        SavePosition()
    end)

    dragLabel = dragOverlay:CreateFontString(nil, "OVERLAY")
    dragLabel:SetFont(FONT_LABEL, 9, "OUTLINE")
    dragLabel:SetPoint("BOTTOM", dragOverlay, "TOP", 0, 3)
    dragLabel:SetTextColor(TEAL.r, TEAL.g, TEAL.b)
    dragLabel:SetText(L["mover_microbar"])
    dragOverlay:Hide()
end

local function SetLockedInternal(locked)
    -- Placement drags a frame that parents protected buttons: out of combat only.
    if InCombatLockdown() then return end
    isLocked = locked and true or false

    if isLocked then
        if dragOverlay then dragOverlay:Hide() end
        ApplyAlpha(true)
        return
    end

    CreateDragOverlay()
    Rebuild()
    anchor:SetAlpha(1)
    dragOverlay:Show()
end

function MB.SetLocked(locked) SetLockedInternal(locked) end
function MB.ToggleLock() SetLockedInternal(not isLocked); return isLocked end
function MB.IsLocked() return isLocked end

function MB.ResetPosition()
    local db = GetDB()
    if db then db.position = nil end
    ApplyPosition()
end

-- =====================================
-- PUBLIC API
-- =====================================

function MB.SetLFGEyeEnabled(v)
    local db = GetDB()
    if not db then return end
    db.lfgEyeEnabled = v and true or false
    MB.Refresh()
end

function MB.SetLFGEyeScale(v)
    local db = GetDB()
    if not db then return end
    db.lfgEyeScale = tonumber(v) or 1.0
    MB.Refresh()
end

function MB.Refresh()
    Rebuild()
    ApplyNative()
end

function MB.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v and true or false
    if not db.enabled and isLocked == false then
        SetLockedInternal(true)
    end
    MB.Refresh()
end

function MB.GetButtonDefs()
    return BUTTON_DEFS
end

-- =====================================
-- EVENTS
-- =====================================

local ev = CreateFrame("Frame", "TomoMod_MicroBarEvents")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
ev:RegisterEvent("UPDATE_BINDINGS")
ev:RegisterEvent("LFG_UPDATE")
ev:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
ev:SetScript("OnEvent", function(_, event)
    if not initialized then return end

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingRebuild then Rebuild() end
        if pendingNative then ApplyNative() end
        ApplyAlpha()
        ApplyLFGEye()
        -- Leaving combat re-enables a batch of native buttons (group finder,
        -- talents...). Blizzard does call UpdateMicroButtons here, but the bar
        -- should not depend on that to stop showing them greyed out.
        RefreshStates()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        ApplyAlpha()
        return
    end

    -- Handled before the generic path below, and returning: LFG_UPDATE fires
    -- repeatedly while queued, and letting it fall through would schedule a
    -- full MB.Refresh -- a whole bar rebuild -- every half second in a queue.
    if event == "LFG_UPDATE" or event == "LFG_QUEUE_STATUS_UPDATE" then
        C_Timer.After(0, ApplyLFGEye)
        return
    end

    -- PLAYER_ENTERING_WORLD / EDIT_MODE_LAYOUTS_UPDATED / UPDATE_BINDINGS:
    -- Blizzard may have rebuilt or re-shown the native bar underneath us.
    C_Timer.After(0.5, function()
        if not initialized then return end
        MB.Refresh()
    end)
end)

-- =====================================
-- INITIALIZE
-- =====================================

function MB.Initialize()
    if not TomoModDB then return end
    L = TomoMod_L

    local db = GetDB()
    if not db then return end

    initialized = true

    -- The micro buttons get their art from FrameXML during load; give the
    -- frames a beat to exist before we read textures off them.
    C_Timer.After(1, function()
        MB.Refresh()
        InstallEditModeHooks()

        if TomoMod_Movers and TomoMod_Movers.RegisterEntry and not MB._moverRegistered then
            MB._moverRegistered = true
            TomoMod_Movers.RegisterEntry({
                label    = L["mover_microbar"],
                unlock   = function() if MB.IsLocked() then SetLockedInternal(false) end end,
                lock     = function() if not MB.IsLocked() then SetLockedInternal(true) end end,
                isActive = function()
                    return TomoModDB and TomoModDB.microBar and TomoModDB.microBar.enabled
                end,
            })
        end
    end)
end

_G.TomoMod_MicroBar = MB
