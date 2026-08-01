-- =====================================
-- TooltipInfo.lua
-- Unit information layer for the GameTooltip.
--
-- TooltipSkin.lua styles the tooltip; this file is what puts information in
-- it. The feature set is modelled on what TipTac Reborn shows, but nothing
-- here is derived from its code: TipTac is GPL-3.0 and TomoMod is not, so
-- everything below is written against Blizzard's public API only.
--
-- Health/power bars are deliberately NOT implemented. TooltipSkin hides
-- Blizzard's own StatusBar (hideHealthBar), and no bar is added back.
--
-- Compatible with WoW 12.x (Midnight).
-- =====================================

TomoMod_TooltipInfo = TomoMod_TooltipInfo or {}
local TI = TomoMod_TooltipInfo
local L  = TomoMod_L

-- =====================================
-- LOCALS
-- =====================================

local ROLE_TEX = "|TInterface/AddOns/TomoMod/Assets/Textures/Roles/%s.tga:%d:%d:0:0:64:64:2:56:2:56|t "
local MARKER_TEX = "|TInterface/TargetingFrame/UI-RaidTargetingIcon_%d:%d:%d|t "

local isInitialized = false

-- Dynamic lines (target, speed) are refreshed in place while the tooltip
-- stays open. We keep the FontString index we wrote to, per tooltip, and
-- rewrite that line rather than rebuilding the tooltip.
local dynamicIdx  = {}
local currentUnit = nil
local currentGUID = nil
local refresher   = nil

-- Mythic+ score tiers, loosely following Blizzard's own rating colours.
local MPLUS_TIERS = {
    { 3000, 1.00, 0.50, 0.00 },
    { 2500, 0.64, 0.21, 0.93 },
    { 2000, 0.00, 0.44, 0.87 },
    { 1500, 0.12, 1.00, 0.00 },
    { 750,  1.00, 1.00, 1.00 },
    { 0,    0.62, 0.62, 0.62 },
}

-- =====================================
-- SETTINGS
-- =====================================

local function S()
    return (TomoModDB and TomoModDB.tooltipSkin) or {}
end

local function IsEnabled()
    local s = S()
    return s.enabled and s.showUnitInfo ~= false
end

-- =====================================
-- SAFE HELPERS (Midnight secret-value proof)
-- =====================================

-- Midnight can hand back "secret" values for unit data. Branching on one
-- raises, so every read goes through here and a doubtful value simply means
-- the line is skipped -- never a guess, never a partial string.
local function IsSecret(v)
    return (type(issecretvalue) == "function" and issecretvalue(v))
        or (type(issecurevalue) == "function" and issecurevalue(v))
        or false
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function SafeStr(v)
    if type(v) ~= "string" or v == "" then return nil end
    if IsSecret(v) then return nil end
    return v
end

local function SafeNum(v)
    if type(v) ~= "number" then return nil end
    if IsSecret(v) then return nil end
    return v
end

local function ClassColor(unit)
    local _, token = SafeCall(UnitClass, unit)
    if type(token) ~= "string" then return nil end
    local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[token])
              or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[token])
    if not c then return nil end
    return c.r, c.g, c.b
end

-- Reaction colour, used both for the border and for target names. Players get
-- their class colour; NPCs fall back to the standard hostile/neutral/friendly
-- triple rather than Blizzard's full reaction table, which is finer-grained
-- than a border can usefully express.
local function ReactionColor(unit)
    local isPlayer = SafeCall(UnitIsPlayer, unit)
    if isPlayer == true then
        local r, g, b = ClassColor(unit)
        if r then return r, g, b end
    end

    if SafeCall(UnitIsDeadOrGhost, unit) == true then
        return 0.55, 0.55, 0.55
    end

    local reaction = SafeNum(SafeCall(UnitReaction, unit, "player"))
    if not reaction then return nil end
    if reaction <= 3 then
        return 0.85, 0.20, 0.20          -- hostile
    elseif reaction == 4 then
        return 0.95, 0.82, 0.20          -- neutral
    end
    return 0.25, 0.80, 0.35              -- friendly
end
TI.ReactionColor = ReactionColor

-- =====================================
-- NAME LINE ICONS
-- =====================================

-- Icons ride inline on the name line as texture escapes rather than as
-- anchored textures: the tooltip resizes itself around its text, so inline
-- keeps the layout correct without measuring anything by hand.
local function BuildNameIcons(unit, s)
    local size = s.infoIconSize or 14
    local out = ""

    if s.showTooltipRaidMarker ~= false then
        local idx = SafeNum(SafeCall(GetRaidTargetIndex, unit))
        if idx and idx >= 1 and idx <= 8 then
            out = out .. string.format(MARKER_TEX, idx, size, size)
        end
    end

    local isPlayer = SafeCall(UnitIsPlayer, unit)

    if s.showTooltipRoleIcon ~= false and isPlayer == true then
        local role = SafeStr(SafeCall(UnitGroupRolesAssigned, unit))
        if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
            out = out .. string.format(ROLE_TEX, role, size, size)
        end
    end

    if s.showTooltipClassIcon and isPlayer == true then
        local _, token = SafeCall(UnitClass, unit)
        local coords = type(token) == "string"
                       and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[token]
        if coords then
            -- CLASS_ICON_TCOORDS is 0-1; the texture escape wants pixels on a
            -- 256x256 sheet.
            out = out .. string.format(
                "|TInterface/TargetingFrame/UI-Classes-Circles:%d:%d:0:0:256:256:%d:%d:%d:%d|t ",
                size, size,
                coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256)
        end
    end

    return out
end

-- =====================================
-- EXISTING-LINE ENHANCEMENTS
-- =====================================

-- Recolour the level line by difficulty instead of rewriting it. Rewriting
-- means reconstructing "Level 80 Blood Elf Paladin" from parts, which is
-- exactly where a secret level or a localised classification would produce a
-- mangled line. Recolouring the line Blizzard already built cannot.
local function ColorLevelLine(tooltip, unit, s)
    if not s.colorTooltipLevel then return end

    local level = SafeNum(SafeCall(UnitLevel, unit))
    if not level then return end

    local r, g, b
    if level < 0 then
        r, g, b = 0.85, 0.20, 0.20       -- "??" / boss
    else
        local c = SafeCall(GetCreatureDifficultyColor, level)
        if type(c) == "table" and type(c.r) == "number" then
            r, g, b = c.r, c.g, c.b
        end
    end
    if not r then return end

    local name = tooltip:GetName()
    if not name then return end
    local levelWord = type(LEVEL) == "string" and LEVEL or "Level"

    for i = 2, math.min(tooltip:NumLines(), 5) do
        local line = _G[name .. "TextLeft" .. i]
        local text = line and SafeStr(line:GetText())
        if text and text:find(levelWord, 1, true) then
            line:SetTextColor(r, g, b)
            return
        end
    end
end

-- =====================================
-- APPENDED INFORMATION LINES
-- =====================================

local function AddGuildRank(tooltip, unit, s)
    if not s.showTooltipGuildRank then return end
    if SafeCall(UnitIsPlayer, unit) ~= true then return end

    local guild, rank, rankIndex, realm = SafeCall(GetGuildInfo, unit)
    guild = SafeStr(guild)
    rank  = SafeStr(rank)
    if not guild or not rank then return end

    local label = rank
    if s.showTooltipGuildRankIndex and SafeNum(rankIndex) then
        label = string.format("%s (%d)", rank, rankIndex + 1)
    end

    local realmStr = SafeStr(realm)
    if s.showTooltipGuildRealm and realmStr then
        label = label .. " - " .. realmStr
    end

    tooltip:AddDoubleLine(L["tt_guild_rank"], label, 0.65, 0.65, 0.70, 0.047, 0.824, 0.624)
end

-- Returns the display string for the unit's target, or nil.
local function TargetText(unit)
    local tUnit = unit .. "target"
    if SafeCall(UnitExists, tUnit) ~= true then return nil end

    local name = SafeStr(SafeCall(UnitName, tUnit))
    if not name then return nil end

    if SafeCall(UnitIsUnit, tUnit, "player") == true then
        return "|cffff4040" .. L["tt_target_you"] .. "|r"
    end

    local r, g, b = ReactionColor(tUnit)
    if not r then return name end
    return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, name)
end

local function AddTarget(tooltip, unit, s)
    if s.showTooltipTarget == false then return end
    local text = TargetText(unit)
    if not text then return end
    tooltip:AddDoubleLine(L["tt_target"], text, 0.65, 0.65, 0.70, 1, 1, 1)
    dynamicIdx.target = tooltip:NumLines()
end

local function MythicScoreText(unit)
    if SafeCall(UnitIsPlayer, unit) ~= true then return nil end
    if not (C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then
        return nil
    end

    local summary = SafeCall(C_PlayerInfo.GetPlayerMythicPlusRatingSummary, unit)
    if type(summary) ~= "table" then return nil end
    local score = SafeNum(summary.currentSeasonScore)
    if not score or score <= 0 then return nil end

    for _, tier in ipairs(MPLUS_TIERS) do
        if score >= tier[1] then
            return tostring(math.floor(score)), tier[2], tier[3], tier[4]
        end
    end
    return tostring(math.floor(score)), 1, 1, 1
end

local function AddMythicScore(tooltip, unit, s)
    if s.showTooltipMythicScore == false then return end
    local text, r, g, b = MythicScoreText(unit)
    if not text then return end
    tooltip:AddDoubleLine(L["tt_mythic_score"], text, 0.65, 0.65, 0.70, r, g, b)
end

-- Speed as a percentage of the base run speed, matching how the game talks
-- about movement everywhere else ("+70% speed").
local function SpeedText(unit)
    local BASE = 7
    local current = SafeNum(SafeCall(GetUnitSpeed, unit))
    if not current then return nil end
    local pct = (current / BASE) * 100
    if pct < 1 then return nil end
    return string.format("%.0f%%", pct)
end

local function AddSpeed(tooltip, unit, s)
    if not s.showTooltipSpeed then return end
    local text = SpeedText(unit)
    if not text then return end
    tooltip:AddDoubleLine(L["tt_speed"], text, 0.65, 0.65, 0.70, 1, 1, 1)
    dynamicIdx.speed = tooltip:NumLines()
end

-- The mount is an aura on the unit. C_MountJournal.GetMountFromSpell turns an
-- aura's spellID straight into a mount, so no spellID table has to be built
-- or maintained here.
local function AddMount(tooltip, unit, s)
    if s.showTooltipMount == false then return end
    if SafeCall(UnitIsPlayer, unit) ~= true then return end
    if not (C_MountJournal and C_MountJournal.GetMountFromSpell) then return end
    if not (C_UnitAuras and C_UnitAuras.GetBuffDataByIndex) then return end

    for i = 1, 40 do
        local aura = SafeCall(C_UnitAuras.GetBuffDataByIndex, unit, i)
        if type(aura) ~= "table" then break end

        local spellID = SafeNum(aura.spellId)
        if spellID then
            local mountID = SafeNum(SafeCall(C_MountJournal.GetMountFromSpell, spellID))
            if mountID then
                local name, _, icon = SafeCall(C_MountJournal.GetMountInfoByID, mountID)
                name = SafeStr(name)
                if name then
                    local prefix = ""
                    if SafeNum(icon) then
                        prefix = string.format("|T%d:%d:%d|t ", icon,
                                               s.infoIconSize or 14, s.infoIconSize or 14)
                    end
                    tooltip:AddDoubleLine(L["tt_mount"], prefix .. name,
                                          0.65, 0.65, 0.70, 1, 1, 1)
                end
                return
            end
        end
    end
end

-- Location is only meaningful for units the client actually has map data for:
-- yourself and your party. C_Map.GetBestMapForUnit returns nothing for an
-- arbitrary target, so the line is deliberately limited rather than sometimes
-- silently wrong.
local function AddLocation(tooltip, unit, s)
    if not s.showTooltipLocation then return end
    if not C_Map or not C_Map.GetBestMapForUnit then return end

    local isPlayer = SafeCall(UnitIsUnit, unit, "player") == true
    local inParty  = SafeCall(UnitPlayerOrPetInParty, unit) == true
    if not (isPlayer or inParty) then return end

    local mapID = SafeNum(SafeCall(C_Map.GetBestMapForUnit, unit))
    if not mapID then return end

    local info = SafeCall(C_Map.GetMapInfo, mapID)
    local zone = type(info) == "table" and SafeStr(info.name) or nil
    if not zone then return end

    if isPlayer then
        local sub = SafeStr(SafeCall(GetSubZoneText))
        if sub and sub ~= zone then zone = zone .. " - " .. sub end
    end

    tooltip:AddDoubleLine(L["tt_location"], zone, 0.65, 0.65, 0.70, 0.55, 0.75, 0.95)
end

-- =====================================
-- INSPECT LINES (item level + specialization)
-- =====================================
-- The engine in TooltipInspect.lua answers asynchronously, so the lines are
-- written immediately with a placeholder and rewritten in place when the
-- result lands. Rebuilding the tooltip instead would make it jump under the
-- cursor a second after it appeared.

local function ItemLevelColor(ilvl)
    -- Deliberately NOT hardcoded season thresholds: those rot at every patch
    -- (CharacterSkin.lua still carries TWW numbers). Colouring by the gap to
    -- your own item level stays correct forever and is the comparison a
    -- player actually makes when inspecting someone.
    local mine = SafeNum(select(2, SafeCall(GetAverageItemLevel)))
    if not mine or mine <= 0 then return 1, 1, 1 end
    local delta = ilvl - mine
    if delta >= 15 then return 1.00, 0.50, 0.00
    elseif delta >= 5 then return 0.12, 1.00, 0.00
    elseif delta > -5 then return 1.00, 1.00, 1.00
    elseif delta > -15 then return 0.75, 0.75, 0.75
    end
    return 0.55, 0.55, 0.55
end

local function ItemLevelText(data)
    local ilvl = data and SafeNum(data.ilvl)
    if not ilvl or ilvl <= 0 then return nil end
    local r, g, b = ItemLevelColor(ilvl)
    return string.format("|cff%02x%02x%02x%d|r", r * 255, g * 255, b * 255, ilvl)
end

local function SpecText(data, s)
    local name = data and SafeStr(data.specName)
    if not name then return nil end
    local prefix = ""
    if s.showTooltipSpecIcon ~= false and SafeNum(data.specIcon) then
        prefix = string.format("|T%d:%d:%d|t ", data.specIcon,
                               s.infoIconSize or 14, s.infoIconSize or 14)
    end
    return prefix .. name
end

local function AddInspectLines(tooltip, unit, s)
    local wantIlvl = s.showTooltipItemLevel ~= false
    local wantSpec = s.showTooltipSpec ~= false
    if not (wantIlvl or wantSpec) then return end
    if SafeCall(UnitIsPlayer, unit) ~= true then return end
    if not (TomoMod_TooltipInspect and TomoMod_TooltipInspect.Query) then return end

    local data, status = TomoMod_TooltipInspect.Query(unit)

    -- Out of inspect range, offline, or otherwise unknowable. Showing an
    -- "out of range" placeholder in that case just adds noise to every
    -- tooltip in the open world, so the lines are simply omitted.
    if status == "unavailable" then return end

    local pending = (status ~= "ready")
    local wait = s.inspectPendingText ~= false and L["tt_loading"] or " "

    if wantIlvl then
        local text = (not pending) and ItemLevelText(data) or nil
        if text or pending then
            tooltip:AddDoubleLine(L["tt_item_level"], text or wait,
                                  0.65, 0.65, 0.70, 1, 1, 1)
            dynamicIdx.ilvl = tooltip:NumLines()
        end
    end

    if wantSpec then
        local text = (not pending) and SpecText(data, s) or nil
        if text or pending then
            tooltip:AddDoubleLine(L["tt_spec"], text or wait,
                                  0.65, 0.65, 0.70, 1, 1, 1)
            dynamicIdx.spec = tooltip:NumLines()
        end
    end
end

-- Fired by the engine once a request answers. Only touches the tooltip if it
-- is still showing the very unit that was asked about.
local function OnInspectResult(guid, data)
    if not guid or guid ~= currentGUID then return end
    if not GameTooltip:IsShown() then return end

    local name = GameTooltip:GetName()
    if not name then return end
    local s = S()

    if dynamicIdx.ilvl then
        local line = _G[name .. "TextRight" .. dynamicIdx.ilvl]
        if line then line:SetText(ItemLevelText(data) or " ") end
    end
    if dynamicIdx.spec then
        local line = _G[name .. "TextRight" .. dynamicIdx.spec]
        if line then line:SetText(SpecText(data, s) or " ") end
    end
end

-- =====================================
-- DYNAMIC REFRESH
-- =====================================

-- Target and speed change while the tooltip is still on screen. Rebuilding the
-- tooltip for that would fight Blizzard's own refresh, so the stored line is
-- rewritten in place instead. The frame only runs while there is something to
-- refresh -- nothing to poll, no OnUpdate.
local function StopRefresher()
    if refresher then refresher:Hide() end
    currentUnit, currentGUID = nil, nil
    dynamicIdx.target, dynamicIdx.speed = nil, nil
    dynamicIdx.ilvl, dynamicIdx.spec = nil, nil
end
TI.StopRefresher = StopRefresher

local function EnsureRefresher()
    if refresher then return refresher end

    refresher = CreateFrame("Frame")
    refresher:Hide()
    refresher.elapsed = 0
    refresher:SetScript("OnUpdate", function(self, e)
        self.elapsed = self.elapsed + e
        if self.elapsed < 0.25 then return end
        self.elapsed = 0

        if not currentUnit or not GameTooltip:IsShown() then
            StopRefresher()
            return
        end
        if SafeCall(UnitExists, currentUnit) ~= true then
            StopRefresher()
            return
        end

        local name = GameTooltip:GetName()
        if not name then return end

        if dynamicIdx.target then
            local line = _G[name .. "TextRight" .. dynamicIdx.target]
            if line then line:SetText(TargetText(currentUnit) or "") end
        end
        if dynamicIdx.speed then
            local line = _G[name .. "TextRight" .. dynamicIdx.speed]
            if line then line:SetText(SpeedText(currentUnit) or "") end
        end
    end)
    return refresher
end

-- =====================================
-- MAIN ENTRY
-- =====================================

local function OnUnitTooltip(tooltip)
    if not IsEnabled() then return end
    if tooltip ~= GameTooltip then return end
    if tooltip.IsForbidden and tooltip:IsForbidden() then return end

    dynamicIdx.target, dynamicIdx.speed = nil, nil
    dynamicIdx.ilvl, dynamicIdx.spec = nil, nil
    currentUnit, currentGUID = nil, nil

    local _, unit = SafeCall(tooltip.GetUnit, tooltip)
    unit = SafeStr(unit)
    if not unit then return end
    if SafeCall(UnitExists, unit) ~= true then return end

    local s = S()

    -- 1. enhance what Blizzard already wrote
    ColorLevelLine(tooltip, unit, s)

    local icons = BuildNameIcons(unit, s)
    if icons ~= "" then
        local nameLine = _G[tooltip:GetName() .. "TextLeft1"]
        local text = nameLine and SafeStr(nameLine:GetText())
        if text then nameLine:SetText(icons .. text) end
    end

    -- 2. append our own lines
    AddGuildRank(tooltip, unit, s)
    AddMythicScore(tooltip, unit, s)
    AddMount(tooltip, unit, s)
    AddLocation(tooltip, unit, s)
    AddTarget(tooltip, unit, s)
    AddSpeed(tooltip, unit, s)
    AddInspectLines(tooltip, unit, s)

    -- currentGUID gates the deferred inspect fill: the tooltip may have moved
    -- on to another unit by the time the server answers.
    currentGUID = SafeStr(SafeCall(UnitGUID, unit))

    if dynamicIdx.target or dynamicIdx.speed then
        currentUnit = unit
        EnsureRefresher():Show()
    end

    tooltip:Show()   -- re-measure after the appended lines
end

-- =====================================
-- PUBLIC API
-- =====================================

function TI.ApplySettings()
    if not IsEnabled() then StopRefresher() end
end

function TI.Initialize()
    if isInitialized then return end
    if not (TooltipDataProcessor and Enum and Enum.TooltipDataType) then return end

    -- The unit post-call is the supported way to append lines. The old
    -- hooksecurefunc(GameTooltip, "Show") path cannot be used for this: each
    -- AddLine resizes the tooltip and re-fires Show.
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnitTooltip)

    if TomoMod_TooltipInspect then
        TomoMod_TooltipInspect.Initialize()
        TomoMod_TooltipInspect.RegisterCallback(OnInspectResult)
    end

    GameTooltip:HookScript("OnHide", StopRefresher)

    isInitialized = true
end
