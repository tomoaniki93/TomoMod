-- =====================================
-- Movers.lua — Unified Layout Manager
-- Remplace tous les /tm uf, /tm sr, /tm rb, etc.
-- Un seul toggle pour déplacer tous les éléments de l'interface.
-- Bouton "Layout" dans le GUI + header bar flottant en mode déplacement.
-- Grille d'alignement avec effet flashlight curseur (inspiré d'EllesmereUI).
-- =====================================

TomoMod_Movers = TomoMod_Movers or {}
local M = TomoMod_Movers
local L  -- assigned in Initialize

-- [PERF] Hoist math functions used in the grid-flashlight OnUpdate (line ~455).
-- That OnUpdate is throttled to ~20 FPS, but still iterates many grid lines and
-- calls sqrt/abs/min/max per segment — no reason to re-localize them each tick.
local math_sqrt = math.sqrt
local math_abs  = math.abs
local math_min  = math.min
local math_max  = math.max

-- =====================================
-- STATE
-- =====================================

local isUnlocked  = false
local headerBar   = nil
local lockBtn     = nil
local gridBtn     = nil
local initialized = false
local moduleEntries = {}

-- =====================================
-- REGISTRATION API
-- =====================================

function M.RegisterEntry(entry)
    table.insert(moduleEntries, entry)
end

-- =====================================
-- BUILT-IN ENTRIES
-- =====================================

local function BuildEntries()
    table.insert(moduleEntries, {
        label    = L["mover_unitframes"],
        unlock   = function()
            if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
                if TomoMod_UnitFrames.IsLocked and TomoMod_UnitFrames.IsLocked() then TomoMod_UnitFrames.ToggleLock() end
            end
            if TomoMod_BossFrames and TomoMod_BossFrames.ToggleLock then
                if TomoMod_BossFrames.IsLocked and TomoMod_BossFrames.IsLocked() then TomoMod_BossFrames.ToggleLock() end
            end
        end,
        lock     = function()
            if TomoMod_UnitFrames and TomoMod_UnitFrames.ToggleLock then
                if TomoMod_UnitFrames.IsLocked and not TomoMod_UnitFrames.IsLocked() then TomoMod_UnitFrames.ToggleLock() end
            end
            if TomoMod_BossFrames and TomoMod_BossFrames.ToggleLock then
                if TomoMod_BossFrames.IsLocked and not TomoMod_BossFrames.IsLocked() then TomoMod_BossFrames.ToggleLock() end
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.unitFrames and TomoModDB.unitFrames.player and TomoModDB.unitFrames.player.enabled
        end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_resources"],
        unlock   = function()
            if TomoMod_ResourceBars and TomoMod_ResourceBars.IsLocked and TomoMod_ResourceBars.IsLocked() then TomoMod_ResourceBars.ToggleLock() end
        end,
        lock     = function()
            if TomoMod_ResourceBars and TomoMod_ResourceBars.IsLocked and not TomoMod_ResourceBars.IsLocked() then TomoMod_ResourceBars.ToggleLock() end
        end,
        isActive = function() return TomoModDB and TomoModDB.resourceBars and TomoModDB.resourceBars.enabled end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_skyriding"],
        unlock   = function()
            if TomoMod_SkyRide and TomoMod_SkyRide.IsLocked and TomoMod_SkyRide.IsLocked() then TomoMod_SkyRide.ToggleLock() end
        end,
        lock     = function()
            if TomoMod_SkyRide and TomoMod_SkyRide.IsLocked and not TomoMod_SkyRide.IsLocked() then TomoMod_SkyRide.ToggleLock() end
        end,
        isActive = function() return TomoModDB and TomoModDB.skyRide and TomoModDB.skyRide.enabled end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_levelingbar"],
        unlock   = function()
            if TomoMod_LevelingBar and TomoMod_LevelingBar.IsLocked and TomoMod_LevelingBar.IsLocked() then TomoMod_LevelingBar.ToggleLock() end
        end,
        lock     = function()
            if TomoMod_LevelingBar and TomoMod_LevelingBar.IsLocked and not TomoMod_LevelingBar.IsLocked() then TomoMod_LevelingBar.ToggleLock() end
        end,
        isActive = function() return TomoModDB and TomoModDB.levelingBar and TomoModDB.levelingBar.enabled end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_anchors"],
        unlock   = function()
            if TomoMod_FrameAnchors and TomoMod_FrameAnchors.IsLocked and TomoMod_FrameAnchors.IsLocked() then TomoMod_FrameAnchors.ToggleLock() end
        end,
        lock     = function()
            if TomoMod_FrameAnchors and TomoMod_FrameAnchors.IsLocked and not TomoMod_FrameAnchors.IsLocked() then TomoMod_FrameAnchors.ToggleLock() end
        end,
        isActive = function() return TomoModDB and TomoModDB.frameAnchors and TomoModDB.frameAnchors.enabled end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_cotank"],
        unlock   = function()
            if TomoMod_CombatResTracker and TomoMod_CombatResTracker.IsLocked and TomoMod_CombatResTracker.IsLocked() then TomoMod_CombatResTracker.ToggleLock() end
        end,
        lock     = function()
            if TomoMod_CombatResTracker and TomoMod_CombatResTracker.IsLocked and not TomoMod_CombatResTracker.IsLocked() then TomoMod_CombatResTracker.ToggleLock() end
        end,
        isActive = function() return true end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_repbar"],
        unlock   = function()
            if TomoMod_ReputationBar and TomoMod_ReputationBar.IsLocked and TomoMod_ReputationBar.IsLocked() then
                TomoMod_ReputationBar.ToggleLock()
            end
        end,
        lock     = function()
            if TomoMod_ReputationBar and TomoMod_ReputationBar.IsLocked and not TomoMod_ReputationBar.IsLocked() then
                TomoMod_ReputationBar.ToggleLock()
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.reputationBar and TomoModDB.reputationBar.enabled
        end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_castbar"],
        unlock   = function()
            if TomoMod_Castbar and TomoMod_Castbar.UnlockPlayerCastbar then
                TomoMod_Castbar.UnlockPlayerCastbar()
            end
        end,
        lock     = function()
            if TomoMod_Castbar and TomoMod_Castbar.LockPlayerCastbar then
                TomoMod_Castbar.LockPlayerCastbar()
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.castbars and TomoModDB.castbars.enabled and TomoModDB.castbars.player and TomoModDB.castbars.player.enabled
        end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_partyframes"] or "Party Frames",
        unlock   = function()
            if TomoMod_PartyFrames and TomoMod_PartyFrames.ToggleLock then
                if TomoMod_PartyFrames.IsLocked and TomoMod_PartyFrames.IsLocked() then TomoMod_PartyFrames.ToggleLock() end
            end
            if TomoMod_ArenaFrames and TomoMod_ArenaFrames.ToggleLock then
                if TomoMod_ArenaFrames.IsLocked and TomoMod_ArenaFrames.IsLocked() then TomoMod_ArenaFrames.ToggleLock() end
            end
        end,
        lock     = function()
            if TomoMod_PartyFrames and TomoMod_PartyFrames.ToggleLock then
                if TomoMod_PartyFrames.IsLocked and not TomoMod_PartyFrames.IsLocked() then TomoMod_PartyFrames.ToggleLock() end
            end
            if TomoMod_ArenaFrames and TomoMod_ArenaFrames.ToggleLock then
                if TomoMod_ArenaFrames.IsLocked and not TomoMod_ArenaFrames.IsLocked() then TomoMod_ArenaFrames.ToggleLock() end
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.partyFrames and TomoModDB.partyFrames.enabled
        end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_auratracker"],
        unlock   = function()
            if TomoMod_AuraTracker and TomoMod_AuraTracker.ToggleLock then
                if TomoMod_AuraTracker.IsLocked and TomoMod_AuraTracker.IsLocked() then TomoMod_AuraTracker.ToggleLock() end
            end
        end,
        lock     = function()
            if TomoMod_AuraTracker and TomoMod_AuraTracker.ToggleLock then
                if TomoMod_AuraTracker.IsLocked and not TomoMod_AuraTracker.IsLocked() then TomoMod_AuraTracker.ToggleLock() end
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.auraTracker and TomoModDB.auraTracker.enabled
        end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_mythictracker"],
        unlock   = function()
            if TomoMod_MythicTracker then
                TomoMod_MythicTracker:SetMovable(true)
                if not TomoMod_MythicTracker.Frame then
                    TomoMod_MythicTracker:BuildFrame()
                    local db = TomoModDB and TomoModDB.MythicTracker
                    if db then
                        local p = db.position
                        TomoMod_MythicTracker.Frame:ClearAllPoints()
                        TomoMod_MythicTracker.Frame:SetPoint(p.anchor, UIParent, p.relTo, p.x, p.y)
                        TomoMod_MythicTracker.Frame:SetScale(db.scale)
                    end
                end
                TomoMod_MythicTracker:Preview()
            end
        end,
        lock     = function()
            if TomoMod_MythicTracker then
                TomoMod_MythicTracker:SetMovable(false)
                if TomoMod_MythicTracker.Frame and not C_ChallengeMode.IsChallengeModeActive() then
                    TomoMod_MythicTracker:HideFrame()
                end
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.MythicTracker and TomoModDB.MythicTracker.enabled
        end,
    })
    table.insert(moduleEntries, {
        label    = L["mover_minimap"],
        unlock   = function()
            if TomoMod_Minimap and TomoMod_Minimap.IsLocked and TomoMod_Minimap.IsLocked() then
                TomoMod_Minimap.ToggleLock()
            end
        end,
        lock     = function()
            if TomoMod_Minimap and TomoMod_Minimap.IsLocked and not TomoMod_Minimap.IsLocked() then
                TomoMod_Minimap.ToggleLock()
            end
        end,
        isActive = function()
            return TomoModDB and TomoModDB.minimap and TomoModDB.minimap.enabled
        end,
    })
end

-- =====================================
-- IsLocked helpers (patch modules manquants)
-- =====================================

local function PatchIsLocked()
    local patches = {
        { TomoMod_SkyRide,          "IsLocked" },
        { TomoMod_LevelingBar,      "IsLocked" },
        { TomoMod_FrameAnchors,     "IsLocked" },
        { TomoMod_ResourceBars,     "IsLocked" },
        { TomoMod_BossFrames,       "IsLocked" },
        { TomoMod_UnitFrames,       "IsLocked" },
        { TomoMod_CombatResTracker, "IsLocked" },
    }
    for _, p in ipairs(patches) do
        if p[1] and not p[1][p[2]] then p[1][p[2]] = function() return true end end
    end
end

-- =====================================
-- CONSTANTS (shared par Grid + Header)
-- =====================================

local FONT   = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Tomo.ttf"
local ACCENT = { 0.05, 0.82, 0.62 }
local BG     = { 0.04, 0.04, 0.06, 0.92 }
local BORDER = { 0.08, 0.25, 0.20, 1 }

-- =====================================
-- GRID OVERLAY
-- Grille d'alignement plein écran + cursor flashlight.
-- Trois modes : "disabled" | "dimmed" | "bright"
-- =====================================

local GRID_SPACING      = 32     -- px entre les lignes
local GRID_ALPHA_DIM    = 0.12
local GRID_ALPHA_BRIGHT = 0.28
local GRID_CENTER_DIM   = 0.22
local GRID_CENTER_BRT   = 0.50
local LIGHT_RADIUS      = 200    -- px rayon flashlight
local LIGHT_BOOST       = 0.65   -- alpha max boost
local SEG_SIZE          = 8      -- taille d'un segment flashlight (px)

local gridFrame = nil
local gridMode  = "dimmed"

local function GridBaseAlpha()
    return gridMode == "bright" and GRID_ALPHA_BRIGHT or GRID_ALPHA_DIM
end
local function GridCenterAlpha()
    return gridMode == "bright" and GRID_CENTER_BRT or GRID_CENTER_DIM
end
local function CycleGridMode()
    if     gridMode == "dimmed"   then gridMode = "bright"
    elseif gridMode == "bright"   then gridMode = "disabled"
    else                               gridMode = "dimmed" end
end
local function GridBtnLabel()
    if gridMode == "bright"   then return L and L["grid_bright"]   or "Grille +" end
    if gridMode == "dimmed"   then return L and L["grid_dimmed"]   or "Grille"   end
    return                              L and L["grid_disabled"]   or "Grille OFF"
end

-- Sync couleurs du bouton grille selon l'état actif/inactif
local function SyncGridBtn()
    if not gridBtn then return end
    local active = (gridMode ~= "disabled")
    local r, g, b = ACCENT[1], ACCENT[2], ACCENT[3]
    if active then
        gridBtn:SetBackdropBorderColor(r, g, b, 0.7)
        gridBtn._txt:SetTextColor(r, g, b)
        gridBtn._ico:SetVertexColor(r, g, b)
        gridBtn._normalBorder   = { r, g, b, 0.7 }
        gridBtn._normalTxtColor = { r, g, b }
    else
        gridBtn:SetBackdropBorderColor(0.30, 0.30, 0.30, 0.5)
        gridBtn._txt:SetTextColor(0.45, 0.45, 0.45)
        gridBtn._ico:SetVertexColor(0.45, 0.45, 0.45)
        gridBtn._normalBorder   = { 0.30, 0.30, 0.30, 0.5 }
        gridBtn._normalTxtColor = { 0.45, 0.45, 0.45 }
    end
    gridBtn._txt:SetText(GridBtnLabel())
end

local function ApplyGridMode()
    if not gridFrame then return end
    if gridMode == "disabled" or not isUnlocked then
        gridFrame:Hide()
    else
        gridFrame:Rebuild()
        gridFrame:Show()
    end
    SyncGridBtn()
end

local function CreateGridOverlay()
    if gridFrame then return gridFrame end

    gridFrame = CreateFrame("Frame", "TomoModLayoutGrid", UIParent)
    gridFrame:SetFrameStrata("BACKGROUND")
    gridFrame:SetAllPoints(UIParent)
    gridFrame:SetFrameLevel(1)
    gridFrame:EnableMouse(false)
    gridFrame._lines = {}
    gridFrame._glows = {}

    -- ── Rebuild : reconstruction complète des lignes ──────────────────────────
    function gridFrame:Rebuild()
        for _, tex in ipairs(self._lines) do tex:Hide() end

        local w    = UIParent:GetWidth()
        local h    = UIParent:GetHeight()
        local ar   = ACCENT[1]; local ag = ACCENT[2]; local ab = ACCENT[3]
        local baseA = GridBaseAlpha()
        local centA = GridCenterAlpha()
        local cx   = math.floor(w / 2)
        local cy   = math.floor(h / 2)
        local idx  = 0

        local function AddLine(isVert, pos, alpha)
            idx = idx + 1
            local tex = self._lines[idx]
            if not tex then
                tex = self:CreateTexture(nil, "BACKGROUND", nil, -7)
                self._lines[idx] = tex
            end
            tex:SetColorTexture(ar, ag, ab, alpha)
            tex._baseAlpha = alpha
            tex._isVert    = isVert
            tex._pos       = pos   -- 0 = ligne centrale
            tex:ClearAllPoints()
            if isVert then
                tex:SetSize(1, h)
                tex:SetPoint("TOPLEFT", UIParent, "TOPLEFT", pos, 0)
            else
                tex:SetSize(w, 1)
                tex:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -pos)
            end
            tex:Show()
        end

        -- Verticales gauche/droite du centre
        local x = cx - GRID_SPACING
        while x > 0              do AddLine(true,  x, baseA); x = x - GRID_SPACING end
        x = cx + GRID_SPACING
        while x < w              do AddLine(true,  x, baseA); x = x + GRID_SPACING end

        -- Horizontales au-dessus/en-dessous du centre (pos = dist depuis le haut)
        local y = cy - GRID_SPACING
        while y > 0              do AddLine(false, y, baseA); y = y - GRID_SPACING end
        y = cy + GRID_SPACING
        while y < h              do AddLine(false, y, baseA); y = y + GRID_SPACING end

        -- Croix centrale (level -6, plus visible)
        for _, isVert in ipairs({true, false}) do
            idx = idx + 1
            local tex = self._lines[idx]
            if not tex then
                tex = self:CreateTexture(nil, "BACKGROUND", nil, -6)
                self._lines[idx] = tex
            end
            tex:SetColorTexture(ar, ag, ab, centA)
            tex._baseAlpha = centA
            tex._isVert    = isVert
            tex._pos       = 0   -- marqueur ligne centrale
            tex:ClearAllPoints()
            if isVert then
                tex:SetSize(1, h); tex:SetPoint("TOP", UIParent, "TOP", 0, 0)
            else
                tex:SetSize(w, 1); tex:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
            end
            tex:Show()
        end

        self._lineCount = idx
    end

    -- ── Cursor flashlight OnUpdate ─────────────────────────────────────────────
    -- Algorithme EllesmereUI : subdivise les lignes proches en segments SEG_SIZE,
    -- calcule la distance 2D curseur→milieu du segment, applique alpha quadratique.
    -- Pool de textures pré-alloué (_glows), aucune allocation chaque frame.

    local function GetGlow(i)
        local g = gridFrame._glows[i]
        if not g then
            g = gridFrame:CreateTexture(nil, "BACKGROUND", nil, -5)
            gridFrame._glows[i] = g
        end
        return g
    end

    gridFrame._gridElapsed = 0
    gridFrame:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then return end
        self._gridElapsed = self._gridElapsed + elapsed
        if self._gridElapsed < 0.05 then return end  -- [PERF] throttle to ~20fps (plenty for glow effect)
        self._gridElapsed = 0

        local ar2 = ACCENT[1]; local ag2 = ACCENT[2]; local ab2 = ACCENT[3]
        local uiH   = UIParent:GetHeight()
        local uiW   = UIParent:GetWidth()
        local scale = UIParent:GetEffectiveScale()
        local mcx, mcy = GetCursorPosition()
        -- Coordonnées dans l'espace virtual UIParent
        -- X depuis la gauche, Y depuis le bas → convertir Y depuis le haut
        local curX   = mcx / scale
        local curY   = mcy / scale              -- depuis le bas
        local curYt  = uiH - curY              -- depuis le haut (même repère que _pos horizontal)

        local R2     = LIGHT_RADIUS * LIGHT_RADIUS
        local gIdx   = 0
        local lc     = self._lineCount or #self._lines
        -- [PERF] math_sqrt/abs/min/max are now hoisted to module scope — see top of file.
        local sqrt2, abs2, min2, max2 = math_sqrt, math_abs, math_min, math_max

        for i = 1, lc do
            local tex = self._lines[i]
            if tex and tex:IsShown() and tex._baseAlpha then
                tex:SetColorTexture(ar2, ag2, ab2, tex._baseAlpha)

                -- Position réelle de la ligne en coordonnées virtuelles
                local lineX, lineY  -- lineX pour verticales, lineY (depuis haut) pour horizontales
                local perpDist
                if tex._isVert then
                    lineX    = (tex._pos == 0) and (uiW * 0.5) or tex._pos
                    perpDist = abs2(lineX - curX)
                else
                    lineY    = (tex._pos == 0) and (uiH * 0.5) or tex._pos
                    perpDist = abs2(lineY - curYt)
                end

                if perpDist < LIGHT_RADIUS then
                    local halfSpan = sqrt2(R2 - perpDist * perpDist)

                    if tex._isVert then
                        -- Segments le long de l'axe Y (coord depuis bas)
                        local startY = curY - halfSpan
                        local endY   = curY + halfSpan
                        local segY   = startY
                        while segY < endY do
                            local segEnd = min2(segY + SEG_SIZE, endY)
                            local midY   = (segY + segEnd) * 0.5
                            local dx = lineX - curX
                            local dy = midY  - curY
                            local d2 = dx*dx + dy*dy
                            if d2 < R2 then
                                local t     = 1 - sqrt2(d2) / LIGHT_RADIUS
                                local alpha = LIGHT_BOOST * t * t
                                if alpha > 0.004 then
                                    gIdx = gIdx + 1
                                    local g = GetGlow(gIdx)
                                    g:SetColorTexture(ar2, ag2, ab2, alpha)
                                    g:ClearAllPoints()
                                    g:SetSize(1, segEnd - segY)
                                    -- SetPoint depuis BOTTOMLEFT : Y depuis le bas = segY
                                    g:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                                        lineX, max2(0, segY))
                                    g:Show()
                                end
                            end
                            segY = segEnd
                        end
                    else
                        -- Segments le long de l'axe X
                        local startX = curX - halfSpan
                        local endX   = curX + halfSpan
                        local segX   = startX
                        while segX < endX do
                            local segEnd = min2(segX + SEG_SIZE, endX)
                            local midX   = (segX + segEnd) * 0.5
                            local dx = midX  - curX
                            local dy = lineY - curYt
                            local d2 = dx*dx + dy*dy
                            if d2 < R2 then
                                local t     = 1 - sqrt2(d2) / LIGHT_RADIUS
                                local alpha = LIGHT_BOOST * t * t
                                if alpha > 0.004 then
                                    gIdx = gIdx + 1
                                    local g = GetGlow(gIdx)
                                    g:SetColorTexture(ar2, ag2, ab2, alpha)
                                    g:ClearAllPoints()
                                    g:SetSize(segEnd - segX, 1)
                                    -- SetPoint depuis TOPLEFT : Y offset négatif depuis le haut
                                    g:SetPoint("TOPLEFT", UIParent, "TOPLEFT",
                                        max2(0, segX), -lineY)
                                    g:Show()
                                end
                            end
                            segX = segEnd
                        end
                    end
                end
            end
        end

        -- Éteindre les segments de lueur non utilisés ce frame
        for j = gIdx + 1, #self._glows do
            if self._glows[j] then self._glows[j]:Hide() end
        end
    end)

    gridFrame:Hide()
    return gridFrame
end

-- =====================================
-- HEADER BAR
-- Row 1 gauche : icône + titre
-- Row 1 droite : [Grille] [Verrouiller] [RL]
-- Row 2        : hint text
-- =====================================

local function MakeBtn(parent, w, iconPath, iconColor, label, bgColor, borderColor)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, 26)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.8)
    btn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 0.7)

    local ico = btn:CreateTexture(nil, "OVERLAY")
    ico:SetSize(13, 13)
    ico:SetPoint("LEFT", btn, "LEFT", 7, 0)
    ico:SetTexture(iconPath)
    ico:SetVertexColor(iconColor[1], iconColor[2], iconColor[3])
    btn._ico = ico

    local txt = btn:CreateFontString(nil, "OVERLAY")
    txt:SetFont(FONT, 11, "")
    txt:SetPoint("LEFT", ico, "RIGHT", 5, 0)
    txt:SetText(label)
    txt:SetTextColor(iconColor[1], iconColor[2], iconColor[3])
    btn._txt = txt

    btn._normalBorder   = { borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 0.7 }
    btn._normalTxtColor = { iconColor[1],   iconColor[2],   iconColor[3] }

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 0.9)
        self._txt:SetTextColor(1, 1, 1)
        self._ico:SetVertexColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(self._normalBorder))
        self._txt:SetTextColor(unpack(self._normalTxtColor))
        self._ico:SetVertexColor(unpack(self._normalTxtColor))
    end)

    return btn
end

local function CreateHeaderBar()
    if headerBar then return end

    local BAR_W = 720
    local BAR_H = 62
    local ROW1_Y =  15
    local ROW2_Y = -13

    headerBar = CreateFrame("Frame", "TomoModLayoutHeader", UIParent, "BackdropTemplate")
    headerBar:SetSize(BAR_W, BAR_H)
    headerBar:SetPoint("TOP", UIParent, "TOP", 0, -6)
    headerBar:SetFrameStrata("DIALOG")
    headerBar:SetFrameLevel(600)
    headerBar:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    headerBar:SetBackdropColor(unpack(BG))
    headerBar:SetBackdropBorderColor(unpack(BORDER))
    headerBar:Hide()

    -- Accent line
    local accent = headerBar:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(2)
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("TOPRIGHT", 0, 0)
    accent:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)

    -- Icône + titre (row 1, gauche)
    local iconTex = headerBar:CreateTexture(nil, "OVERLAY")
    iconTex:SetSize(16, 16)
    iconTex:SetPoint("LEFT", 12, ROW1_Y)
    iconTex:SetTexture("Interface\\AddOns\\TomoMod\\Assets\\Textures\\icon_layout.tga")
    iconTex:SetVertexColor(ACCENT[1], ACCENT[2], ACCENT[3])

    local titleLbl = headerBar:CreateFontString(nil, "OVERLAY")
    titleLbl:SetFont(FONT, 13, "")
    titleLbl:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
    titleLbl:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
    titleLbl:SetText(L["layout_mode_title"])

    -- Hint text (row 2, gauche)
    local hint = headerBar:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 10, "")
    hint:SetPoint("LEFT", 34, ROW2_Y)
    hint:SetTextColor(0.50, 0.50, 0.50)
    hint:SetText(L["layout_mode_hint"])

    -- RL (row 1, extrême droite)
    local rlBtn = MakeBtn(headerBar, 52,
        "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icon_reload.tga",
        { 0.9, 0.7, 0.2 }, "RL",
        { 0.10, 0.08, 0.04 }, { 0.7, 0.5, 0.1 }
    )
    rlBtn:SetPoint("RIGHT", headerBar, "RIGHT", -4, ROW1_Y)
    rlBtn:SetScript("OnClick", function() ReloadUI() end)

    -- Lock (row 1, à gauche de RL)
    lockBtn = MakeBtn(headerBar, 100,
        "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icon_lock.tga",
        { ACCENT[1], ACCENT[2], ACCENT[3] }, L["layout_btn_lock"],
        { ACCENT[1]*0.2, ACCENT[2]*0.2, ACCENT[3]*0.2 },
        { ACCENT[1],     ACCENT[2],     ACCENT[3]      }
    )
    lockBtn:SetPoint("RIGHT", rlBtn, "LEFT", -6, 0)
    lockBtn:SetScript("OnClick", function() M.SetUnlocked(false) end)

    -- Grid (row 1, à gauche de Lock)
    gridBtn = MakeBtn(headerBar, 84,
        "Interface\\AddOns\\TomoMod\\Assets\\Textures\\icon_layout.tga",
        { ACCENT[1], ACCENT[2], ACCENT[3] }, GridBtnLabel(),
        { 0.04, 0.10, 0.08 }, { ACCENT[1], ACCENT[2], ACCENT[3] }
    )
    gridBtn:SetPoint("RIGHT", lockBtn, "LEFT", -6, 0)
    gridBtn:SetScript("OnClick", function()
        CycleGridMode()
        ApplyGridMode()
    end)
    -- Override OnLeave : resync couleurs selon état actif
    gridBtn:SetScript("OnLeave", function()
        SyncGridBtn()
    end)
end

-- =====================================
-- CORE: SetUnlocked
-- =====================================

function M.SetUnlocked(unlock)
    if not initialized then return end
    isUnlocked = unlock

    PatchIsLocked()

    for _, entry in ipairs(moduleEntries) do
        local active = not entry.isActive or entry.isActive()
        if active then
            if unlock then entry.unlock() else entry.lock() end
        end
    end

    if headerBar then
        if unlock then headerBar:Show() else headerBar:Hide() end
    end

    -- Grille
    if unlock then
        ApplyGridMode()
    else
        if gridFrame then gridFrame:Hide() end
    end

    if unlock then
        print("|cff0cd29fTomoMod Layout:|r " .. L["layout_unlocked"])
    else
        print("|cff0cd29fTomoMod Layout:|r " .. L["layout_locked"])
    end
end

function M.Toggle()
    M.SetUnlocked(not isUnlocked)
end

function M.IsUnlocked()
    return isUnlocked
end

-- =====================================
-- INITIALIZE
-- =====================================

function M.Initialize()
    L = TomoMod_L
    CreateGridOverlay()   -- pré-alloue le frame (pas visible)
    CreateHeaderBar()
    BuildEntries()
    initialized = true
    isUnlocked  = false
end
