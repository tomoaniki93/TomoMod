-- =====================================
-- Modules/Housing/DecorHover.lua
-- Adapté de Plumber/HouseEditor_BasicDecorMode.lua
--
-- Ce que fait ce module :
--   - En mode "Basic Decor" de l'éditeur, quand le curseur survole un décor
--     placé, affiche une instruction en haut à droite avec :
--       * le nom du décor
--       * le coût de placement (budget)
--       * le stock restant
--   - Raccourci "dupliquer" : appuyer sur Ctrl ou Alt pendant le survol pour
--     démarrer immédiatement le placement d'un nouvel exemplaire.
-- =====================================

TomoMod_Housing = TomoMod_Housing or {}
local H = TomoMod_Housing
local L = TomoMod_L

local Controller = H.Controller
if not Controller then return end

-- Create the mode handler for BasicDecor mode
local Handler = Controller.CreateModeHandler("BasicDecor")
Handler.dbKey = "decorHover"
H.Handlers = H.Handlers or {}
H.Handlers.DecorHover = Handler

-- =====================================
-- DISPLAY FRAME
-- Lightweight overlay anchored to the Basic Decor mode frame.
-- We DON'T use PlumberHouseEditorInstructionTemplate (that's Plumber's
-- XML template); we build the frame programmatically instead.
-- =====================================

local DisplayFrame

local function CreateDisplayFrame(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(45, 45)
    f:SetPoint("RIGHT", parent, "RIGHT", -30, 0)
    f:SetAlpha(0)
    f.alpha = 0

    -- Main instruction text (decor name / action label)
    f.InstructionText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    f.InstructionText:SetJustifyH("RIGHT")
    f.InstructionText:SetWordWrap(false)
    f.InstructionText:SetPoint("RIGHT", f, "RIGHT", -55, 0)

    -- Item stock count (above the instruction text)
    f.ItemCountText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    f.ItemCountText:SetPoint("BOTTOM", f.InstructionText, "TOPRIGHT", 2, 2)

    -- Budget icon (coin/credit) + value
    f.BudgetIcon = f:CreateTexture(nil, "ARTWORK")
    f.BudgetIcon:SetSize(22, 22)
    f.BudgetIcon:SetAtlas("housing-hotkey-icon-key-9slice") -- may fail silently pre-Midnight
    f.BudgetIcon:SetPoint("RIGHT", f.InstructionText, "LEFT", -4, 0)

    f.BudgetValue = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.BudgetValue:SetPoint("CENTER", f.BudgetIcon, "CENTER", 0, 0)
    f.BudgetValue:SetTextColor(232/255, 215/255, 140/255)

    -- Duplicate hint (sub-frame below)
    local sub = CreateFrame("Frame", nil, f)
    sub:SetSize(45, 20)
    sub:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, -4)
    sub:Hide()
    sub.HintText = sub:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub.HintText:SetJustifyH("RIGHT")
    sub.HintText:SetPoint("RIGHT", sub, "RIGHT", -55, 0)
    sub.KeyLabel = sub:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    sub.KeyLabel:SetJustifyH("CENTER")
    sub.KeyLabel:SetPoint("RIGHT", sub, "RIGHT", -5, 0)
    sub.KeyLabel:SetTextColor(0.05, 0.82, 0.62) -- teal accent
    f.SubFrame = sub

    return f
end

-- Fade animations (no per-frame cost when not fading)
local function FadeIn_OnUpdate(self, elapsed)
    self.alpha = self.alpha + 5 * elapsed
    if self.alpha >= 1 then
        self.alpha = 1
        self:SetScript("OnUpdate", nil)
    end
    self:SetAlpha(self.alpha)
end

local function FadeOut_OnUpdate(self, elapsed)
    self.alpha = self.alpha - 2 * elapsed
    if self.alpha <= 0 then
        self.alpha = 0
        self:SetScript("OnUpdate", nil)
    end
    if self.alpha > 1 then
        self:SetAlpha(1)
    else
        self:SetAlpha(self.alpha)
    end
end

local function FadeIn(f)  f:SetScript("OnUpdate", FadeIn_OnUpdate) end
local function FadeOut(f, delay)
    if delay then f.alpha = 2 end
    f:SetScript("OnUpdate", FadeOut_OnUpdate)
end

local function SetDecorInfo(f, decorInstanceInfo)
    f.InstructionText:SetText(decorInstanceInfo.name or "")
    local decorID = decorInstanceInfo.decorID
    local entryInfo = decorID and H.API.GetCatalogDecorInfo(decorID)
    if entryInfo then
        local stored = (entryInfo.quantity or 0) + (entryInfo.remainingRedeemable or 0)
        f.ItemCountText:SetText(stored)
        f.ItemCountText:SetShown(stored > 0)
        f.BudgetValue:SetText(entryInfo.placementCost or 0)
        -- Show dup hint if duplication enabled AND there's stock
        f.SubFrame:SetShown(Handler.dupeEnabled and stored > 0)
    else
        f.ItemCountText:Hide()
        f.BudgetValue:SetText("?")
        f.SubFrame:Hide()
    end
end

-- =====================================
-- HANDLER LIFECYCLE
-- =====================================

Handler.DuplicateKeyOptions = {
    { name = CTRL_KEY_TEXT or "Ctrl", key = "LCTRL" },
    { name = ALT_KEY_TEXT  or "Alt",  key = "LALT"  },
}

function Handler:GetDupeKeyName()
    return self.currentDupeKeyName or (self.DuplicateKeyOptions[2] and self.DuplicateKeyOptions[2].name) or "Alt"
end

function Handler:LoadSettings()
    local db = TomoModDB and TomoModDB.housing or nil
    local dupeEnabled = db and db.decorHover_enableDupe and true or false
    local dupeKeyIndex = db and db.decorHover_duplicateKey or 2
    if type(dupeKeyIndex) ~= "number" or not self.DuplicateKeyOptions[dupeKeyIndex] then
        dupeKeyIndex = 2
    end

    self.dupeEnabled        = dupeEnabled
    self.dupeKey            = self.DuplicateKeyOptions[dupeKeyIndex].key
    self.currentDupeKeyName = self.DuplicateKeyOptions[dupeKeyIndex].name

    if DisplayFrame and DisplayFrame.SubFrame then
        DisplayFrame.SubFrame.HintText:SetText(L and L["housing_duplicate"] or "Duplicate")
        DisplayFrame.SubFrame.KeyLabel:SetText(self:GetDupeKeyName())
        if not dupeEnabled then
            DisplayFrame.SubFrame:Hide()
        end
    end
end

function Handler:Init()
    self.Init = nil

    if not (HouseEditorFrame and HouseEditorFrame.BasicDecorModeFrame) then
        -- Blizzard addon not yet loaded; retry later
        return
    end

    local modeFrame = HouseEditorFrame.BasicDecorModeFrame
    local container = modeFrame.Instructions or modeFrame

    if not DisplayFrame then
        DisplayFrame = CreateDisplayFrame(container)
    end

    self:LoadSettings()

    -- Hide native "select" instructions so we don't stack text
    if modeFrame.Instructions and modeFrame.Instructions.UnselectedInstructions then
        for _, v in ipairs(modeFrame.Instructions.UnselectedInstructions) do
            if v and v ~= DisplayFrame and v.Hide then v:Hide() end
        end
    end
end

function Handler:BlizzardHouseEditorLoaded()
    -- Called when Blizzard_HouseEditor finishes loading; allows deferred Init
    if self.activated and self.Init then self:Init() end
end

Handler.dynamicEvents = {
    "HOUSE_EDITOR_MODE_CHANGED",
    "HOUSING_BASIC_MODE_HOVERED_TARGET_CHANGED",
}

function Handler:OnActivated()
    for _, ev in ipairs(self.dynamicEvents) do self:RegisterEvent(ev) end
    self:SetScript("OnEvent", self.OnEvent)
    if DisplayFrame then DisplayFrame:Show() end
    self:LoadSettings()
    self:RequestUpdateHover()
end

function Handler:OnDeactivated()
    for _, ev in ipairs(self.dynamicEvents) do self:UnregisterEvent(ev) end
    self:UnregisterEvent("MODIFIER_STATE_CHANGED")
    self:UnregisterEvent("HOUSING_STORAGE_ENTRY_UPDATED")
    self:SetScript("OnUpdate", nil)
    self.t = 0
    self.isUpdating = nil
    if DisplayFrame then DisplayFrame:Hide() end
end

function Handler:OnEvent(event, ...)
    if event == "HOUSING_BASIC_MODE_HOVERED_TARGET_CHANGED" then
        self:OnHoveredTargetChanged(...)
    elseif event == "HOUSE_EDITOR_MODE_CHANGED" then
        -- no-op here; Controller already routes this
    elseif event == "MODIFIER_STATE_CHANGED" then
        if not H.API.IsHouseEditorActive() then
            self:UnregisterEvent(event)
        end
        self:OnModifierStateChanged(...)
    elseif event == "HOUSING_STORAGE_ENTRY_UPDATED" then
        self:RequestUpdateHover()
    end
end

function Handler:OnHoveredTargetChanged(hasHoveredTarget, targetType)
    if hasHoveredTarget then
        self.t = 0
        self.isUpdating = true
        self:SetScript("OnUpdate", self.OnUpdate)
        self:UnregisterEvent("MODIFIER_STATE_CHANGED")
        self.lastHoveredTargetType = targetType
    else
        self.decorInstanceInfo = nil
        if DisplayFrame then FadeOut(DisplayFrame, 0.5) end
    end
end

function Handler:OnUpdate(elapsed)
    self.t = (self.t or 0) + elapsed
    if self.t > 0.05 then
        self.t = 0
        self.isUpdating = nil
        self:SetScript("OnUpdate", nil)
        self:ProcessHoveredDecor()
    end
end

function Handler:RequestUpdateHover()
    self.t = 0
    self:SetScript("OnUpdate", self.OnUpdate)
end

function Handler:ProcessHoveredDecor()
    self.decorInstanceInfo = nil

    local C_HousingDecor = C_HousingDecor
    if C_HousingDecor and C_HousingDecor.IsHoveringDecor and C_HousingDecor.IsHoveringDecor() then
        local info = C_HousingDecor.GetHoveredDecorInfo and C_HousingDecor.GetHoveredDecorInfo()
        if info then
            if self.dupeEnabled then
                self:RegisterEvent("MODIFIER_STATE_CHANGED")
            end
            self.decorInstanceInfo = info
            if DisplayFrame then
                SetDecorInfo(DisplayFrame, info)
                FadeIn(DisplayFrame)
                self:RegisterEvent("HOUSING_STORAGE_ENTRY_UPDATED")
            end
            return true
        end
    end

    self:UnregisterEvent("MODIFIER_STATE_CHANGED")
    self:UnregisterEvent("HOUSING_STORAGE_ENTRY_UPDATED")
    if DisplayFrame then FadeOut(DisplayFrame) end
end

-- =====================================
-- DUPLICATE SHORTCUT
-- =====================================

function Handler:GetHoveredDecorEntryID()
    if not self.decorInstanceInfo then return nil end
    local decorID = self.decorInstanceInfo.decorID
    if not decorID then return nil end
    local entryInfo = H.API.GetCatalogDecorInfo(decorID)
    return entryInfo and entryInfo.entryID
end

function Handler:TryDuplicateItem()
    if not self.dupeEnabled then return end
    if not H.API.IsHouseEditorActive() then return end
    if C_HousingBasicMode and C_HousingBasicMode.IsDecorSelected and C_HousingBasicMode.IsDecorSelected() then
        return
    end

    local entryID = self:GetHoveredDecorEntryID()
    if not entryID then return end

    -- Respect max placement budget
    if C_HousingDecor and C_HousingDecor.HasMaxPlacementBudget and C_HousingDecor.HasMaxPlacementBudget() then
        local placed = C_HousingDecor.GetSpentPlacementBudget and C_HousingDecor.GetSpentPlacementBudget() or 0
        local max    = C_HousingDecor.GetMaxPlacementBudget  and C_HousingDecor.GetMaxPlacementBudget()  or 0
        if placed >= max then return end
    end

    if C_HousingBasicMode and C_HousingBasicMode.StartPlacingNewDecor then
        C_HousingBasicMode.StartPlacingNewDecor(entryID)
    end
end

function Handler:OnModifierStateChanged(key, down)
    if key == self.dupeKey and down == 0 then
        self:TryDuplicateItem()
    end
end