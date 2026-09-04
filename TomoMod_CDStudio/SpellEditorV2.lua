-- =====================================================================
-- TomoMod Cooldown Studio -- Spell Editor V2
-- Visual icon-based ordering + drag & drop + click-to-edit inspector.
--
-- Loaded after CDStudio.lua. The integration is deliberately isolated:
-- it swaps only the "spells" builder when the shared tab panel belongs to
-- TomoModCDStudioFrame. Existing CooldownForge data stays untouched.
-- =====================================================================

local W   = TomoMod_Widgets
local S   = TomoMod_CDStudio
local CDF = TomoMod_CooldownForge
if not (W and S and CDF) then return end

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"
local QUESTION  = "Interface\\Icons\\INV_Misc_QuestionMark"

-- TomoMod visual identity from this version onward: Azure + white.
local AZURE = { 0.23, 0.65, 1.00 }
local WHITE = { 0.96, 0.98, 1.00 }

local function Loc(key, fallback)
    local L = TomoMod_L
    local v = L and L[key]
    if not v or v == key then return fallback end
    return v
end

local function SelectedBar()
    return S.state.barId and CDF.GetBar(S.state.class, S.state.barId) or nil
end

local function Apply()
    if CDF.RefreshAll then CDF.RefreshAll() end
end

local function readPositiveInt(text)
    local n = tonumber(text)
    if n and n > 0 then return math.floor(n) end
    return nil
end

local function colorProxy(arr)
    return { r = arr[1] or 1, g = arr[2] or 1, b = arr[3] or 1 }
end

local function writeColor(arr, r, g, b)
    arr[1], arr[2], arr[3] = r, g, b
end

local function SpecOptions(class)
    local opts = {
        { text = Loc("cds_v2_all_specs", "All specializations"), value = 0 },
    }
    if class == CDF.PlayerClass() and GetNumSpecializations then
        for i = 1, (GetNumSpecializations() or 0) do
            local id, name = GetSpecializationInfo(i)
            if id then
                opts[#opts + 1] = { text = name or ("Spec " .. i), value = id }
            end
        end
    end
    return opts
end

local TRI_OPTS = {
    { text = Loc("cds_v2_inherit", "Inherit from bar"), value = "inherit" },
    { text = Loc("cds_v2_yes", "Yes"),                value = "on" },
    { text = Loc("cds_v2_no", "No"),                  value = "off" },
}

local function triVal(v)
    if v == nil then return "inherit" end
    return v and "on" or "off"
end

local function triSet(t, key, value)
    if value == "inherit" then
        t[key] = nil
    else
        t[key] = value == "on"
    end
end

local GLOW_COND_OPTS_ENTRY = {
    { text = Loc("cds_v2_inherit", "Inherit from bar"),              value = "inherit" },
    { text = Loc("cds_v2_glow_ready", "When the spell is ready"),    value = "ready" },
    { text = Loc("cds_v2_glow_usable", "When the spell is usable"),  value = "usable" },
    { text = Loc("cds_v2_glow_aura", "When the buff is active"),     value = "aura" },
    { text = Loc("cds_v2_glow_maxcharges", "When all charges are restored"), value = "maxCharges" },
    { text = Loc("cds_v2_glow_stacks", "When the buff reaches N stacks"), value = "stacks" },
    { text = Loc("cds_v2_glow_always", "Always"),                    value = "always" },
}

local UNUSABLE_OPTS_ENTRY = {
    { text = Loc("cds_v2_inherit", "Inherit from bar"),            value = "inherit" },
    { text = Loc("cds_v2_unusable_none", "No effect"),             value = "off" },
    { text = Loc("cds_v2_unusable_dim", "Dim"),                    value = "dim" },
    { text = Loc("cds_v2_unusable_resource", "Dim + blue resource tint"), value = "resource" },
}

local function EntryVisual(entry)
    if not entry then return QUESTION, "?" end

    if entry.kind == "spell" and entry.id then
        local tex  = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(entry.id)
        local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(entry.id)
        return tex or QUESTION, name or string.format(Loc("cds_v2_spell", "Spell %s"), tostring(entry.id))
    end

    if entry.kind == "item" and entry.id then
        local tex  = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry.id)
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(entry.id)
        return tex or QUESTION, name or string.format(Loc("cds_v2_item", "Item %s"), tostring(entry.id))
    end

    if entry.kind == "itemPreset" then
        local itemID = CDF.ResolvePresetItemID and CDF.ResolvePresetItemID(entry.preset)
        local tex = itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)
        local name = itemID and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
        if not name then
            local preset = CDF.PRESETS and CDF.PRESETS[entry.preset]
            name = preset and preset.name
        end
        return tex or QUESTION, name or string.format(Loc("cds_v2_preset", "Preset %s"), tostring(entry.preset or "?"))
    end

    if entry.kind == "equippedTrinket" then
        local slot = tonumber(entry.slot) or 0
        local itemID = GetInventoryItemID and GetInventoryItemID("player", slot)
        local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", slot)
        local name = itemID and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
        return tex or QUESTION,
            name or string.format(Loc("cds_v2_trinket_slot", "Trinket (slot %s)"), tostring(slot))
    end

    if entry.kind == "racial" then
        local spellID = CDF.ResolveRacialSpell and CDF.ResolveRacialSpell()
        local tex  = spellID and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID)
        local name = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
        return tex or QUESTION, name or Loc("cds_v2_racial", "Racial")
    end

    return QUESTION, tostring(entry.kind or "?")
end

-- Direct move API used only by the editor for now. Keeping it here avoids a
-- schema change and keeps the LoadOnDemand feature self-contained. If another
-- module needs arbitrary entry moves later this can migrate to CDF_API.lua.
if not CDF.MoveEntryTo then
    function CDF.MoveEntryTo(class, barId, fromIndex, toIndex)
        local bar = CDF.GetBar(class, barId)
        local entries = bar and bar.entries
        fromIndex = tonumber(fromIndex)
        toIndex   = tonumber(toIndex)
        if not entries or not fromIndex or not toIndex then return false end
        fromIndex = math.floor(fromIndex)
        toIndex   = math.floor(toIndex)
        if not entries[fromIndex] or toIndex < 1 or toIndex > #entries then return false end
        if fromIndex == toIndex then return true end
        local entry = table.remove(entries, fromIndex)
        table.insert(entries, toIndex, entry)
        return true
    end
end

local function RemapSelectedIndex(selected, fromIndex, toIndex)
    if not selected then return nil end
    if selected == fromIndex then return toIndex end
    if fromIndex < toIndex and selected > fromIndex and selected <= toIndex then
        return selected - 1
    end
    if toIndex < fromIndex and selected >= toIndex and selected < fromIndex then
        return selected + 1
    end
    return selected
end

local function AddEntry(data)
    if not S.state.barId then return end
    if CDF.AddEntry(S.state.class, S.state.barId, data) then
        Apply()
        S.RebuildContent()
    end
end

local function BuildIconOrderCard(parent, y, bar)
    local card, cy = W.CreateCard(parent, Loc("cds_v2_order_title", "Spell order"), y)
    local entries = bar.entries or {}

    _, cy = W.CreateInfoText(card.inner,
        Loc("cds_v2_drag_hint", "Click an icon to edit it. Drag and drop icons to change their order."), cy)

    if #entries == 0 then
        _, cy = W.CreateInfoText(card.inner,
            Loc("cds_v2_empty", "This bar has no entries yet. Add a spell below or from the Library."), cy)
        return card, W.FinalizeCard(card, cy)
    end

    local CELL_W, CELL_H, ICON = 92, 86, 52
    local available = math.max(720, (parent.GetWidth and parent:GetWidth() or 0) - 64)
    local cols = math.max(4, math.min(10, math.floor(available / CELL_W)))
    local rows = math.ceil(#entries / cols)
    local gridH = rows * CELL_H + 8

    local grid = CreateFrame("Frame", nil, card.inner)
    grid:SetPoint("TOPLEFT", 16, cy - 2)
    grid:SetPoint("TOPRIGHT", -16, cy - 2)
    grid:SetHeight(gridH)

    local buttons = {}
    local drag = { active = false, target = nil, suppressClick = false }

    local marker = CreateFrame("Frame", nil, grid, "BackdropTemplate")
    marker:SetBackdrop({ edgeFile = WHITE8, edgeSize = 2 })
    marker:SetBackdropColor(0, 0, 0, 0)
    marker:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 1)
    marker:Hide()

    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetSize(ICON + 8, ICON + 8)
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    ghost:SetBackdropColor(0.02, 0.05, 0.09, 0.92)
    ghost:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.95)
    ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
    ghost.icon:SetPoint("TOPLEFT", 4, -4)
    ghost.icon:SetPoint("BOTTOMRIGHT", -4, 4)
    ghost.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ghost:Hide()

    local driver = CreateFrame("Frame", nil, UIParent)

    local function CursorUI()
        local x, yy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        if not scale or scale <= 0 then scale = 1 end
        return x / scale, yy / scale
    end

    local function FindTarget()
        local x, yy = CursorUI()
        local left, right, top, bottom = grid:GetLeft(), grid:GetRight(), grid:GetTop(), grid:GetBottom()
        if not (left and right and top and bottom) then return nil end
        if x < left - 12 or x > right + 12 or yy < bottom - 12 or yy > top + 12 then return nil end

        local best, bestDist
        for i, btn in ipairs(buttons) do
            local bx, by = btn:GetCenter()
            if bx and by then
                local dx, dy = x - bx, yy - by
                local d = dx * dx + dy * dy
                if not bestDist or d < bestDist then
                    best, bestDist = i, d
                end
            end
        end
        return best
    end

    local function UpdateDrag()
        if not drag.active then return end
        local x, yy = CursorUI()
        ghost:ClearAllPoints()
        ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + 16, yy - 16)

        local target = FindTarget()
        drag.target = target
        if target and buttons[target] then
            marker:ClearAllPoints()
            marker:SetPoint("TOPLEFT", buttons[target], "TOPLEFT", -3, 3)
            marker:SetPoint("BOTTOMRIGHT", buttons[target], "BOTTOMRIGHT", 3, -3)
            marker:SetFrameLevel(buttons[target]:GetFrameLevel() + 8)
            marker:Show()
        else
            marker:Hide()
        end
    end

    local function StopDrag(source)
        if not drag.active then return end
        local fromIndex = source.entryIndex
        local toIndex = drag.target
        drag.active = false
        drag.suppressClick = true
        driver:SetScript("OnUpdate", nil)
        ghost:Hide()
        marker:Hide()
        source:SetAlpha(1)

        if toIndex and fromIndex and toIndex ~= fromIndex
            and CDF.MoveEntryTo(S.state.class, S.state.barId, fromIndex, toIndex) then
            S.state.fxIdx = RemapSelectedIndex(S.state.fxIdx, fromIndex, toIndex)
            Apply()
            S.RebuildContent()
        end

        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() drag.suppressClick = false end)
        else
            drag.suppressClick = false
        end
    end

    for i, entry in ipairs(entries) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local tex, name = EntryVisual(entry)

        local btn = CreateFrame("Button", nil, grid, "BackdropTemplate")
        btn:SetSize(CELL_W - 8, CELL_H - 8)
        btn:SetPoint("TOPLEFT", col * CELL_W + 4, -(row * CELL_H) - 4)
        btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        btn.entryIndex = i
        btn.entryName = name
        btn.entryTexture = tex or QUESTION
        btn:RegisterForClicks("LeftButtonUp")
        btn:RegisterForDrag("LeftButton")
        buttons[i] = btn

        local selected = S.state.fxIdx == i
        btn:SetBackdropColor(selected and 0.045 or 0.025, selected and 0.10 or 0.045, selected and 0.17 or 0.075, 0.98)
        if selected then
            btn:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 1)
        else
            btn:SetBackdropBorderColor(0.32, 0.40, 0.50, 0.36)
        end

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON, ICON)
        icon:SetPoint("TOP", 0, -5)
        icon:SetTexture(btn.entryTexture)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local number = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        number:SetSize(18, 18)
        number:SetPoint("TOPLEFT", 2, -2)
        number:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        number:SetBackdropColor(0.02, 0.05, 0.09, 0.94)
        number:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.75)
        local nt = number:CreateFontString(nil, "OVERLAY")
        nt:SetFont(FONT_BOLD, 9, "")
        nt:SetPoint("CENTER")
        nt:SetTextColor(WHITE[1], WHITE[2], WHITE[3], 1)
        nt:SetText(i)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetFont(FONT, 9, "")
        label:SetPoint("TOPLEFT", 4, -(ICON + 10))
        label:SetPoint("TOPRIGHT", -4, -(ICON + 10))
        label:SetJustifyH("CENTER")
        label:SetWordWrap(false)
        label:SetTextColor(selected and WHITE[1] or 0.72, selected and WHITE[2] or 0.77, selected and WHITE[3] or 0.84, 1)
        label:SetText(name or "?")

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.95)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.entryName or "?", WHITE[1], WHITE[2], WHITE[3])
            GameTooltip:AddLine(Loc("cds_v2_tooltip", "Click to edit • Drag to reorder"), AZURE[1], AZURE[2], AZURE[3])
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            if S.state.fxIdx == self.entryIndex then
                self:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 1)
            else
                self:SetBackdropBorderColor(0.32, 0.40, 0.50, 0.36)
            end
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function(self)
            if drag.suppressClick then return end
            S.state.fxIdx = self.entryIndex
            S.RebuildContent()
        end)
        btn:SetScript("OnDragStart", function(self)
            drag.active = true
            drag.target = self.entryIndex
            self:SetAlpha(0.38)
            ghost.icon:SetTexture(self.entryTexture)
            ghost:Show()
            driver:SetScript("OnUpdate", UpdateDrag)
            UpdateDrag()
        end)
        btn:SetScript("OnDragStop", function(self)
            StopDrag(self)
        end)
    end

    cy = cy - gridH - 8
    return card, W.FinalizeCard(card, cy)
end

local function BuildSelectedEntryCard(parent, y, bar)
    local entries = bar.entries or {}
    local idx = tonumber(S.state.fxIdx)
    local entry = idx and entries[idx]
    if not entry then return y end

    local _, name = EntryVisual(entry)
    local card, cy = W.CreateCard(parent,
        Loc("cds_v2_selected_title", "Selected entry") .. " — " .. tostring(name or idx), y)

    entry.override = entry.override or {}
    local o = entry.override

    _, cy = W.CreateDropdown(card.inner, Loc("cds_v2_spec_visibility", "Specialization visibility"),
        SpecOptions(S.state.class), entry.spec or 0, cy, function(v)
            CDF.SetEntrySpec(S.state.class, S.state.barId, idx, v)
            Apply()
            S.RebuildContent()
        end)
    _, cy = W.CreateInfoText(card.inner, Loc("cds_v2_spec_info",
        "All specializations shows the icon regardless of your current spec."), cy)

    _, cy = W.CreateCheckbox(card.inner, Loc("cds_v2_follow_aura", "Track a buff/proc instead of the cooldown"),
        entry.mode == "aura", cy, function(v)
            entry.mode = v and "aura" or nil
            if not v then entry.auraID = nil end
            Apply()
            S.RebuildContent()
        end)

    if entry.mode == "aura" then
        _, cy = W.CreateInfoText(card.inner, Loc("cds_v2_aura_info",
            "The icon is shown while the tracked buff is active."), cy)
        local box
        box, cy = W.CreateMultiLineEditBox(card.inner, Loc("cds_v2_aura_id",
            "Buff spell ID (empty = tracked spell ID)"), 24, cy, {
            onTextChanged = function(t)
                entry.auraID = readPositiveInt(t)
                Apply()
            end,
        })
        if box and box.editBox and entry.auraID then
            box.editBox:SetText(tostring(entry.auraID))
        end
    end

    _, cy = W.CreateDropdown(card.inner, Loc("cds_v2_talent_condition", "Talent condition"), {
        { text = Loc("cds_v2_talent_none", "None"), value = "off" },
        { text = Loc("cds_v2_talent_known", "Only when the talent is selected"), value = "known" },
        { text = Loc("cds_v2_talent_unknown", "Only when the talent is NOT selected"), value = "unknown" },
    }, entry.talentID and (entry.talentMode == "unknown" and "unknown" or "known") or "off",
    cy, function(v)
        if v == "off" then
            entry.talentID, entry.talentMode = nil, nil
        else
            entry.talentMode = v == "unknown" and "unknown" or nil
            entry.talentID = entry.talentID or 0
        end
        Apply()
        S.RebuildContent()
    end)

    if entry.talentID ~= nil then
        local tBox
        tBox, cy = W.CreateMultiLineEditBox(card.inner,
            Loc("cds_v2_talent_spell_id", "Spell ID granted by the talent"), 24, cy, {
            onTextChanged = function(t)
                entry.talentID = readPositiveInt(t)
                Apply()
            end,
        })
        if tBox and tBox.editBox and entry.talentID and entry.talentID > 0 then
            tBox.editBox:SetText(tostring(entry.talentID))
        end
        _, cy = W.CreateInfoText(card.inner, Loc("cds_v2_talent_info",
            "Use the spell granted by the talent rather than a talent-node ID."), cy)
    end

    local function tri(labelKey, fallback, key)
        _, cy = W.CreateDropdown(card.inner, Loc(labelKey, fallback), TRI_OPTS, triVal(o[key]), cy, function(v)
            triSet(o, key, v)
            Apply()
        end)
    end

    tri("cds_v2_glow", "Glow", "glow")
    _, cy = W.CreateDropdown(card.inner, Loc("cds_v2_glow_condition", "Glow condition"),
        GLOW_COND_OPTS_ENTRY, o.glowCondition or "inherit", cy, function(v)
            o.glowCondition = v ~= "inherit" and v or nil
            Apply()
            S.RebuildContent()
        end)

    if o.glowCondition == "stacks" then
        _, cy = W.CreateSlider(card.inner, Loc("cds_v2_glow_stacks_required", "Required stacks"),
            tonumber(o.glowStacks) or tonumber(bar.glow and bar.glow.stacks) or 2,
            2, 20, 1, cy, function(v)
                o.glowStacks = v
                Apply()
            end)
    end

    if o.glowCondition == "aura" then
        local box
        box, cy = W.CreateMultiLineEditBox(card.inner, Loc("cds_v2_aura_id",
            "Buff spell ID (empty = tracked spell ID)"), 24, cy, {
            onTextChanged = function(t)
                o.auraSpellID = readPositiveInt(t)
                Apply()
            end,
        })
        if box and box.editBox and o.auraSpellID then
            box.editBox:SetText(tostring(o.auraSpellID))
        end
    end

    local hasGlowColor = o.glowColor ~= nil
    _, cy = W.CreateCheckbox(card.inner, Loc("cds_v2_glow_custom_color", "Custom glow color"),
        hasGlowColor, cy, function(v)
            o.glowColor = v and (o.glowColor or { 1, 0.85, 0.2, 1 }) or nil
            Apply()
            S.RebuildContent()
        end)
    if hasGlowColor then
        _, cy = W.CreateColorPicker(card.inner, Loc("cds_v2_glow_color", "Glow color"),
            colorProxy(o.glowColor), cy, function(r, g, b)
                writeColor(o.glowColor, r, g, b)
                Apply()
            end)
    end

    tri("cds_v2_desat", "Desaturate during cooldown", "desat")
    _, cy = W.CreateDropdown(card.inner, Loc("cds_v2_unusable", "Insufficient resource"),
        UNUSABLE_OPTS_ENTRY, o.unusableMode or "inherit", cy, function(v)
            o.unusableMode = v ~= "inherit" and v or nil
            Apply()
        end)
    tri("cds_v2_swipe", "Swipe", "swipe")
    tri("cds_v2_timer", "Timer", "timer")
    tri("cds_v2_stacks", "Stacks / charges", "stacks")

    _, cy = W.CreateSlider(card.inner, Loc("cds_v2_emphasis", "Emphasis (relative size)"),
        math.floor(((tonumber(o.emphasis) or 1) * 100) + 0.5), 100, 130, 5, cy, function(v)
            o.emphasis = v > 100 and (v / 100) or nil
            Apply()
        end, "%d %%")

    _, cy = W.CreateInfoText(card.inner, Loc("cds_v2_inherit_info",
        "Inherit follows the bar settings. Emphasis enlarges this icon without breaking the layout."), cy)

    _, cy = W.CreateButton(card.inner, Loc("cds_v2_remove", "Remove from bar"), 180, cy, function()
        CDF.RemoveEntry(S.state.class, S.state.barId, idx)
        S.state.fxIdx = nil
        Apply()
        S.RebuildContent()
    end)

    return W.FinalizeCard(card, cy)
end

local addState = { kind = "spell", id = "", spec = 0 }

local function BuildAddCard(parent, y)
    local card, cy = W.CreateCard(parent, Loc("cds_v2_add_title", "Add an entry"), y)

    _, cy = W.CreateDropdown(card.inner, Loc("cds_v2_type", "Type"), {
        { text = Loc("cds_v2_type_spell", "Spell (spellID)"), value = "spell" },
        { text = Loc("cds_v2_type_item", "Item (itemID)"), value = "item" },
        { text = Loc("cds_v2_type_trinket", "Equipped trinket (slot)"), value = "equippedTrinket" },
    }, addState.kind, cy, function(v)
        addState.kind = v
    end)

    _, cy = W.CreateMultiLineEditBox(card.inner, Loc("cds_v2_id_slot", "ID / slot"), 24, cy, {
        onTextChanged = function(t) addState.id = t end,
    })

    _, cy = W.CreateDropdown(card.inner, Loc("cds_v2_spec_visibility", "Specialization visibility"),
        SpecOptions(S.state.class), addState.spec, cy, function(v)
            addState.spec = v
        end)

    _, cy = W.CreateButton(card.inner, Loc("cds_v2_add", "Add"), 130, cy, function()
        local data = { kind = addState.kind, spec = addState.spec }
        if addState.kind == "equippedTrinket" then
            data.slot = tonumber(addState.id)
        else
            data.id = tonumber(addState.id)
        end
        if CDF.AddEntry(S.state.class, S.state.barId, data) then
            addState.id = ""
            Apply()
            S.RebuildContent()
        end
    end)

    _, cy = W.CreateSubLabel(card.inner, Loc("cds_v2_quick_presets", "Quick presets"), cy)
    _, cy = W.CreateButtonRow(card.inner, {
        { text = Loc("cds_v2_trinket13", "Trinket (13)"), callback = function()
            AddEntry({ kind = "equippedTrinket", slot = 13 })
        end },
        { text = Loc("cds_v2_trinket14", "Trinket (14)"), callback = function()
            AddEntry({ kind = "equippedTrinket", slot = 14 })
        end },
        { text = Loc("cds_v2_racial", "Racial"), callback = function()
            AddEntry({ kind = "racial" })
        end },
    }, cy)

    local keys = {}
    for key in pairs(CDF.PRESETS or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local presetKey = key
        local preset = CDF.PRESETS[presetKey]
        _, cy = W.CreateButton(card.inner,
            string.format(Loc("cds_v2_preset_prefix", "Preset: %s"), (preset and preset.name) or presetKey),
            220, cy, function()
                AddEntry({ kind = "itemPreset", preset = presetKey })
            end)
    end

    return W.FinalizeCard(card, cy)
end

local function BuildResyncCard(parent, y, bar)
    if not (bar.viewerSource and CDF.ResyncBarFromViewer) then return y end
    local srcName = (CDF.VIEWER_IMPORTS and CDF.VIEWER_IMPORTS[bar.viewerSource]
        and CDF.VIEWER_IMPORTS[bar.viewerSource].name) or bar.viewerSource
    local card, cy = W.CreateCard(parent,
        string.format(Loc("cds_v2_imported_bar", "Imported bar — %s"), tostring(srcName)), y)

    _, cy = W.CreateInfoText(card.inner, Loc("cds_v2_resync_info",
        "Resync reads Blizzard's current list again while preserving your per-entry settings."), cy)
    _, cy = W.CreateButton(card.inner, Loc("cds_v2_resync", "Resync"), 190, cy, function()
        local added, removed, kept = CDF.ResyncBarFromViewer(S.state.class, S.state.barId)
        if not added then
            if removed == "noapi" then
                print("|cff3aa7ffCooldown Studio|r: " .. Loc("cds_v2_no_blizzard_api",
                    "Blizzard tracking is unavailable on this client."))
            else
                print("|cff3aa7ffCooldown Studio|r: " .. Loc("cds_v2_no_tracked",
                    "No tracked abilities are available for this specialization."))
            end
            return
        end
        S.state.fxIdx = nil
        print("|cff3aa7ffCooldown Studio|r: " .. string.format(
            Loc("cds_v2_resync_result", "%d added, %d removed, %d kept."), added, removed, kept))
        Apply()
        S.RebuildContent()
    end)
    return W.FinalizeCard(card, cy)
end

local function TabSortsV2(parent)
    local scroll = W.CreateScrollPanel(parent)
    local content, y = scroll.child, -12
    local bar = SelectedBar()
    if not bar then return scroll end

    y = BuildResyncCard(content, y, bar)
    local _, nextY = BuildIconOrderCard(content, y, bar)
    y = nextY
    y = BuildSelectedEntryCard(content, y, bar)
    y = BuildAddCard(content, y)

    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end

local function IsInsideCooldownStudio(frame)
    local studio = _G.TomoModCDStudioFrame
    if not studio or not frame then return false end
    local node = frame
    while node do
        if node == studio then return true end
        node = node.GetParent and node:GetParent() or nil
    end
    return false
end

-- Swap only the Cooldown Studio's "spells" builder. Other panels that use the
-- shared widget kit are untouched.
if not W._TomoCDStudioSpellEditorV2Wrapped then
    W._TomoCDStudioSpellEditorV2Wrapped = true
    local OriginalCreateTabPanel = W.CreateTabPanel
    W.CreateTabPanel = function(parent, tabs, ...)
        if IsInsideCooldownStudio(parent) and type(tabs) == "table" then
            for _, tab in ipairs(tabs) do
                if tab.key == "spells" then
                    tab.builder = TabSortsV2
                    break
                end
            end
        end
        return OriginalCreateTabPanel(parent, tabs, ...)
    end
end

-- The shared shell is created only when the Studio is first opened, so this
-- hook can safely move the Cooldown Studio chrome to the new Azure + white
-- identity without changing other Studio consumers.
local Forge = TomoMod_Forge
if Forge and Forge.Studio and Forge.Studio.CreateShell
    and not Forge.Studio._TomoCDStudioAzureWrapped then
    Forge.Studio._TomoCDStudioAzureWrapped = true
    local OriginalCreateShell = Forge.Studio.CreateShell
    Forge.Studio.CreateShell = function(opts)
        if opts and opts.name == "TomoModCDStudioFrame" then
            opts.accent = AZURE
            opts.title = "|cff3aa7ffCooldown|r |cffffffffStudio|r"
        end
        return OriginalCreateShell(opts)
    end
end


-- =====================================================================
-- Cooldown Studio Library V2 (embedded hotfix)
-- Kept in SpellEditorV2.lua to avoid extra LoD file loading.
-- =====================================================================
do
-- =====================================================================
-- TomoMod Cooldown Studio -- Library V2
-- Visual spell library: search, quick filters, grouped spell tiles and
-- one-click group installation. Loaded after CDStudio.lua / SpellEditorV2.
-- =====================================================================

local W   = TomoMod_Widgets
local S   = TomoMod_CDStudio
local CDF = TomoMod_CooldownForge
if not (W and S and CDF) then return end

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"
local QUESTION  = "Interface\\Icons\\INV_Misc_QuestionMark"

local AZURE = { 0.23, 0.65, 1.00 }
local WHITE = { 0.96, 0.98, 1.00 }
local TEXT  = { 0.86, 0.89, 0.94 }
local DIM   = { 0.46, 0.49, 0.58 }
local BG    = { 0.050, 0.052, 0.070 }
local BG2   = { 0.070, 0.075, 0.100 }

local function Loc(key, fallback)
    local L = TomoMod_L
    local v = L and L[key]
    if not v or v == key then return fallback end
    return v
end

local function SelectedBar()
    return S.state.barId and CDF.GetBar(S.state.class, S.state.barId) or nil
end

local function Apply()
    if CDF.RefreshAll then CDF.RefreshAll() end
end

local function Fold(text)
    local Forge = TomoMod_Forge
    if Forge and Forge.Util and Forge.Util.Fold then
        return Forge.Util.Fold(text)
    end
    return tostring(text or ""):lower()
end

local function IsInsideCooldownStudio(frame)
    local studio = _G.TomoModCDStudioFrame
    if not studio or not frame then return false end
    local node = frame
    while node do
        if node == studio then return true end
        node = node.GetParent and node:GetParent() or nil
    end
    return false
end

local function BuildInBarMap(bar)
    local map = {}
    for i, entry in ipairs((bar and bar.entries) or {}) do
        if entry.kind == "spell" and entry.id then
            map[entry.id] = i
        end
    end
    return map
end

local function CreateSearchBox(parent, y, onChanged)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 16, y)
    frame:SetPoint("TOPRIGHT", -16, y)
    frame:SetHeight(54)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_BOLD, 10, "")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 1)
    label:SetText(Loc("cds_lib_search", "Search the library"))

    local boxFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    boxFrame:SetPoint("TOPLEFT", 0, -18)
    boxFrame:SetPoint("TOPRIGHT", 0, -18)
    boxFrame:SetHeight(30)
    boxFrame:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    boxFrame:SetBackdropColor(BG[1], BG[2], BG[3], 1)
    boxFrame:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.32)

    local edit = CreateFrame("EditBox", nil, boxFrame)
    edit:SetPoint("LEFT", 10, 0)
    edit:SetPoint("RIGHT", -34, 0)
    edit:SetHeight(26)
    edit:SetFont(FONT, 11, "")
    edit:SetTextColor(WHITE[1], WHITE[2], WHITE[3], 1)
    edit:SetAutoFocus(false)

    local placeholder = boxFrame:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(FONT, 10, "")
    placeholder:SetPoint("LEFT", 10, 0)
    placeholder:SetTextColor(DIM[1], DIM[2], DIM[3], 1)
    placeholder:SetText(Loc("cds_lib_search_hint", "Spell name or ID"))

    local clear = CreateFrame("Button", nil, boxFrame)
    clear:SetPoint("RIGHT", -5, 0)
    clear:SetSize(24, 24)
    local clearText = clear:CreateFontString(nil, "OVERLAY")
    clearText:SetFont(FONT_BOLD, 14, "")
    clearText:SetPoint("CENTER", 0, 0)
    clearText:SetText("×")
    clearText:SetTextColor(DIM[1], DIM[2], DIM[3], 1)

    local function RefreshHint()
        local empty = (edit:GetText() or "") == ""
        placeholder:SetShown(empty and not edit:HasFocus())
        clear:SetShown(not empty)
    end

    edit:SetScript("OnTextChanged", function(self, userInput)
        RefreshHint()
        if userInput and onChanged then onChanged(self:GetText() or "") end
    end)
    edit:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
        boxFrame:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.85)
    end)
    edit:SetScript("OnEditFocusLost", function()
        RefreshHint()
        boxFrame:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.32)
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    clear:SetScript("OnClick", function()
        edit:SetText("")
        if onChanged then onChanged("") end
        edit:SetFocus()
    end)
    clear:SetScript("OnEnter", function()
        clearText:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 1)
    end)
    clear:SetScript("OnLeave", function()
        clearText:SetTextColor(DIM[1], DIM[2], DIM[3], 1)
    end)

    RefreshHint()
    frame.editBox = edit
    return frame, y - 60
end

local function CreateSummary(parent, y)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", 16, y)
    frame:SetPoint("TOPRIGHT", -16, y)
    frame:SetHeight(24)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont(FONT, 10, "")
    text:SetPoint("LEFT", 0, 0)
    text:SetTextColor(DIM[1], DIM[2], DIM[3], 1)

    frame.text = text
    return frame, y - 30
end

local function CreateActionButton(parent, width, text)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
    btn:SetBackdropColor(AZURE[1] * 0.13, AZURE[2] * 0.13, AZURE[3] * 0.13, 0.95)
    btn:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.45)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_BOLD, 9, "")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(WHITE[1], WHITE[2], WHITE[3], 1)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        if self._disabled then return end
        self:SetBackdropColor(AZURE[1], AZURE[2], AZURE[3], 0.95)
        label:SetTextColor(0.04, 0.06, 0.09, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        if self._disabled then return end
        self:SetBackdropColor(AZURE[1] * 0.13, AZURE[2] * 0.13, AZURE[3] * 0.13, 0.95)
        label:SetTextColor(WHITE[1], WHITE[2], WHITE[3], 1)
    end)

    btn.SetDisabled = function(self, disabled)
        self._disabled = disabled and true or false
        self:EnableMouse(not self._disabled)
        if self._disabled then
            self:SetBackdropColor(BG2[1], BG2[2], BG2[3], 0.65)
            self:SetBackdropBorderColor(DIM[1], DIM[2], DIM[3], 0.25)
            label:SetTextColor(DIM[1], DIM[2], DIM[3], 0.7)
        else
            self:SetBackdropColor(AZURE[1] * 0.13, AZURE[2] * 0.13, AZURE[3] * 0.13, 0.95)
            self:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.45)
            label:SetTextColor(WHITE[1], WHITE[2], WHITE[3], 1)
        end
    end
    return btn
end

local function TabLibraryV2(parent)
    local scroll = W.CreateScrollPanel(parent)
    local content = scroll.child
    local y = -12
    local bar = SelectedBar()

    if S.state.class ~= CDF.PlayerClass() then
        local card, cy = W.CreateCard(content,
            Loc("cds_lib_title", "Spell library"), y)
        _, cy = W.CreateInfoText(card.inner,
            Loc("cds_lib_wrong_class", "The library scans the spellbook of the character currently logged in. Select that character's class to browse it."), cy)
        W.FinalizeCard(card, cy)
        content:SetHeight(math.max(220, math.abs(y) + 180))
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    if not bar then
        local card, cy = W.CreateCard(content,
            Loc("cds_lib_title", "Spell library"), y)
        _, cy = W.CreateInfoText(card.inner,
            Loc("cds_lib_no_bar", "Select or create a bar before adding spells from the library."), cy)
        W.FinalizeCard(card, cy)
        content:SetHeight(math.max(220, math.abs(y) + 180))
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    local groups = CDF.ScanSpellbook and CDF.ScanSpellbook() or {}
    if #groups == 0 then
        local card, cy = W.CreateCard(content,
            Loc("cds_lib_title", "Spell library"), y)
        _, cy = W.CreateInfoText(card.inner,
            Loc("cds_lib_empty", "The spellbook is empty or unavailable on this client."), cy)
        W.FinalizeCard(card, cy)
        content:SetHeight(math.max(220, math.abs(y) + 180))
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    local query = ""
    local filter = "all"
    local inBar = BuildInBarMap(bar)
    local groupFrames = {}
    local Reflow

    local search
    search, y = CreateSearchBox(content, y, function(text)
        query = Fold(text)
        if Reflow then Reflow() end
    end)

    local filterControl
    filterControl, y = W.CreateSegmentedControl(content,
        Loc("cds_lib_filter", "Show"), {
            { text = Loc("cds_lib_filter_all", "All"),       value = "all" },
            { text = Loc("cds_lib_filter_available", "To add"), value = "available" },
            { text = Loc("cds_lib_filter_inbar", "In bar"), value = "inbar" },
        }, filter, y, function(value)
            filter = value
            if Reflow then Reflow() end
        end, 3)

    local summary
    summary, y = CreateSummary(content, y)
    local groupsStartY = y

    local function RefreshInBar()
        inBar = BuildInBarMap(SelectedBar())
    end

    local function SpellVisible(spell)
        local present = inBar[spell.spellID] ~= nil
        if filter == "available" and present then return false end
        if filter == "inbar" and not present then return false end
        if query ~= "" then
            local hay = Fold((spell.name or "") .. " " .. tostring(spell.spellID or ""))
            if not hay:find(query, 1, true) then return false end
        end
        return true
    end

    local function AddSpell(group, spell, deferApply)
        if inBar[spell.spellID] then return false end
        local ok = CDF.AddEntry(S.state.class, S.state.barId, {
            kind = "spell",
            id = spell.spellID,
            spec = group.offSpecID or 0,
        })
        if ok then
            RefreshInBar()
            if not deferApply then Apply() end
            return true
        end
        return false
    end

    local function CreateGroup(group)
        local frame = CreateFrame("Frame", nil, content, "BackdropTemplate")
        frame:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        frame:SetBackdropColor(BG[1], BG[2], BG[3], 0.98)
        frame:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.24)

        local accent = frame:CreateTexture(nil, "ARTWORK")
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT", 0, -1)
        accent:SetPoint("BOTTOMLEFT", 0, 1)
        accent:SetColorTexture(AZURE[1], AZURE[2], AZURE[3], 0.9)

        local header = CreateFrame("Frame", nil, frame)
        header:SetPoint("TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", -1, -1)
        header:SetHeight(34)

        local headerBg = header:CreateTexture(nil, "BACKGROUND")
        headerBg:SetAllPoints()
        headerBg:SetColorTexture(AZURE[1] * 0.06, AZURE[2] * 0.06, AZURE[3] * 0.08, 0.95)

        local title = header:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_BOLD, 11, "")
        title:SetPoint("LEFT", 12, 0)
        title:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 1)
        title:SetText(string.upper(group.name or ""))

        local count = header:CreateFontString(nil, "OVERLAY")
        count:SetFont(FONT, 9, "")
        count:SetPoint("LEFT", title, "RIGHT", 8, 0)
        count:SetTextColor(DIM[1], DIM[2], DIM[3], 1)

        local addGroup = CreateActionButton(header, 150,
            Loc("cds_lib_add_group", "Add group"))
        addGroup:SetPoint("RIGHT", -8, 0)

        local tiles = {}
        for _, spell in ipairs(group.spells or {}) do
            local tile = CreateFrame("Button", nil, frame, "BackdropTemplate")
            tile:SetHeight(50)
            tile:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })

            local icon = tile:CreateTexture(nil, "ARTWORK")
            icon:SetSize(34, 34)
            icon:SetPoint("LEFT", 8, 0)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            icon:SetTexture(spell.icon or QUESTION)

            local name = tile:CreateFontString(nil, "OVERLAY")
            name:SetFont(FONT, 10, "")
            name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
            name:SetPoint("RIGHT", -86, 0)
            name:SetJustifyH("LEFT")
            name:SetWordWrap(false)
            name:SetText(spell.name or tostring(spell.spellID))

            local id = tile:CreateFontString(nil, "OVERLAY")
            id:SetFont(FONT, 8, "")
            id:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
            id:SetTextColor(DIM[1], DIM[2], DIM[3], 1)
            id:SetText("ID " .. tostring(spell.spellID or "?"))

            local state = tile:CreateFontString(nil, "OVERLAY")
            state:SetFont(FONT_BOLD, 9, "")
            state:SetPoint("RIGHT", -9, 0)
            state:SetJustifyH("RIGHT")

            tile.spell = spell
            tile.nameText = name
            tile.stateText = state
            tile.icon = icon

            tile.Paint = function(self)
                local present = inBar[self.spell.spellID] ~= nil
                if present then
                    self:SetBackdropColor(AZURE[1] * 0.08, AZURE[2] * 0.08, AZURE[3] * 0.10, 0.96)
                    self:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.36)
                    self.nameText:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 0.72)
                    self.stateText:SetText(Loc("cds_lib_added", "Added"))
                    self.stateText:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 0.78)
                    self.icon:SetDesaturated(false)
                else
                    self:SetBackdropColor(BG2[1], BG2[2], BG2[3], 0.82)
                    self:SetBackdropBorderColor(0.18, 0.22, 0.30, 0.9)
                    self.nameText:SetTextColor(WHITE[1], WHITE[2], WHITE[3], 1)
                    self.stateText:SetText("+ " .. Loc("cds_lib_add", "Add"))
                    self.stateText:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 1)
                    self.icon:SetDesaturated(false)
                end
            end

            tile:SetScript("OnEnter", function(self)
                if not inBar[self.spell.spellID] then
                    self:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], 0.85)
                    self:SetBackdropColor(AZURE[1] * 0.10, AZURE[2] * 0.10, AZURE[3] * 0.14, 0.96)
                end
                if GameTooltip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.spell.name or tostring(self.spell.spellID), 1, 1, 1)
                    if inBar[self.spell.spellID] then
                        GameTooltip:AddLine(Loc("cds_lib_tip_added", "Already in the selected bar."),
                            DIM[1], DIM[2], DIM[3], true)
                    else
                        GameTooltip:AddLine(Loc("cds_lib_tip_add", "Click to add this spell to the selected bar."),
                            AZURE[1], AZURE[2], AZURE[3], true)
                    end
                    GameTooltip:Show()
                end
            end)
            tile:SetScript("OnLeave", function(self)
                self:Paint()
                if GameTooltip then GameTooltip:Hide() end
            end)
            tile:SetScript("OnClick", function(self)
                if AddSpell(group, self.spell) then
                    if Reflow then Reflow() end
                end
            end)

            tiles[#tiles + 1] = tile
        end

        addGroup:SetScript("OnClick", function()
            local changed = false
            for _, spell in ipairs(group.spells or {}) do
                if not inBar[spell.spellID] and AddSpell(group, spell, true) then
                    changed = true
                end
            end
            if changed then
                Apply()
                if Reflow then Reflow() end
            end
        end)

        frame.group = group
        frame.tiles = tiles
        frame.title = title
        frame.count = count
        frame.addGroup = addGroup
        return frame
    end

    for _, group in ipairs(groups) do
        groupFrames[#groupFrames + 1] = CreateGroup(group)
    end

    Reflow = function()
        local curY = groupsStartY
        local totalVisible, totalInBar = 0, 0

        for _, groupFrame in ipairs(groupFrames) do
            local group = groupFrame.group
            local visible = {}
            local inGroup = 0
            local groupTotal = #(group.spells or {})

            for _, tile in ipairs(groupFrame.tiles) do
                tile:Paint()
                if inBar[tile.spell.spellID] then inGroup = inGroup + 1 end
                if SpellVisible(tile.spell) then
                    visible[#visible + 1] = tile
                    totalVisible = totalVisible + 1
                else
                    tile:Hide()
                end
            end
            totalInBar = totalInBar + inGroup

            if #visible == 0 then
                groupFrame:Hide()
            else
                groupFrame:Show()
                groupFrame:ClearAllPoints()
                groupFrame:SetPoint("TOPLEFT", 8, curY)
                groupFrame:SetPoint("TOPRIGHT", -8, curY)

                local rows = math.ceil(#visible / 2)
                local height = 34 + 8 + rows * 56
                groupFrame:SetHeight(height)

                groupFrame.count:SetText(string.format(
                    Loc("cds_lib_group_count", "%d/%d in bar"), inGroup, groupTotal))
                groupFrame.addGroup:SetDisabled(inGroup >= groupTotal)

                for pos, tile in ipairs(visible) do
                    local col = (pos - 1) % 2
                    local row = math.floor((pos - 1) / 2)
                    tile:ClearAllPoints()
                    if col == 0 then
                        tile:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 10, -(42 + row * 56))
                        tile:SetPoint("TOPRIGHT", groupFrame, "TOP", -4, -(42 + row * 56))
                    else
                        tile:SetPoint("TOPLEFT", groupFrame, "TOP", 4, -(42 + row * 56))
                        tile:SetPoint("TOPRIGHT", groupFrame, "TOPRIGHT", -10, -(42 + row * 56))
                    end
                    tile:Show()
                end

                curY = curY - height - 8
            end
        end

        summary.text:SetText(string.format(
            Loc("cds_lib_summary", "%d shown • %d already in this bar"), totalVisible, totalInBar))

        if totalVisible == 0 then
            summary.text:SetText(Loc("cds_lib_no_results", "No spell matches the current search and filter."))
        end

        content:SetHeight(math.max(1, math.abs(curY) + 18))
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function()
                if scroll and scroll.UpdateScroll then scroll.UpdateScroll() end
            end)
        end
    end

    Reflow()
    return scroll
end

-- Swap only Cooldown Studio's library builder. The SpellEditorV2 wrapper is
-- already installed when this file loads; chaining the wrapper preserves both.
if not W._TomoCDStudioLibraryV2Wrapped then
    W._TomoCDStudioLibraryV2Wrapped = true
    local OriginalCreateTabPanel = W.CreateTabPanel
    W.CreateTabPanel = function(parent, tabs, ...)
        if IsInsideCooldownStudio(parent) and type(tabs) == "table" then
            for _, tab in ipairs(tabs) do
                if tab.key == "library" then
                    tab.builder = TabLibraryV2
                    break
                end
            end
        end
        return OriginalCreateTabPanel(parent, tabs, ...)
    end
end

end

-- =====================================================================
-- Cooldown Studio Presets V3 -- contextual class/spec pack
-- One install creates Minimal / Mythic+ / Raid bars for the active spec.
-- Their visibility switches automatically from the existing CDF conditions.
-- =====================================================================
do
local W   = TomoMod_Widgets
local S   = TomoMod_CDStudio
local CDF = TomoMod_CooldownForge
if not (W and S and CDF) then return end

local FONT      = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-Medium.ttf"
local FONT_BOLD = "Interface\\AddOns\\TomoMod\\Assets\\Fonts\\Poppins-SemiBold.ttf"
local WHITE8    = "Interface\\Buttons\\WHITE8x8"
local QUESTION  = "Interface\\Icons\\INV_Misc_QuestionMark"
local AZURE     = { 0.23, 0.65, 1.00 }
local TEXT      = { 0.90, 0.93, 0.98 }
local DIM       = { 0.48, 0.52, 0.62 }

local function Loc(key, fallback)
    local L = TomoMod_L
    local v = L and L[key]
    if not v or v == key then return fallback end
    return v
end

local function IsInsideCooldownStudio(frame)
    local studio = _G.TomoModCDStudioFrame
    if not studio or not frame then return false end
    local node = frame
    while node do
        if node == studio then return true end
        node = node.GetParent and node:GetParent() or nil
    end
    return false
end

local function CurrentContext()
    if IsInRaid and IsInRaid() then return "raid" end
    if IsInGroup and IsInGroup() then return "party" end
    return "solo"
end

local function CurrentSpec()
    local idx = GetSpecialization and GetSpecialization()
    if not idx then return 0, nil end
    local id, name = GetSpecializationInfo(idx)
    return tonumber(id) or 0, name
end

local PROFILE_UI = {
    solo = {
        titleKey = "cds_p3_minimal",
        titleFallback = "Minimal",
        descKey = "cds_p3_minimal_desc",
        descFallback = "Essential cooldowns only. Compact for solo play and open world.",
        sourceKey = "cds_p3_minimal_sources",
        sourceFallback = "Blizzard source: Essentials",
    },
    party = {
        titleKey = "cds_p3_mythic",
        titleFallback = "Mythic+",
        descKey = "cds_p3_mythic_desc",
        descFallback = "Essentials plus utility for dungeons and non-raid groups.",
        sourceKey = "cds_p3_mythic_sources",
        sourceFallback = "Blizzard sources: Essentials + Utility",
    },
    raid = {
        titleKey = "cds_p3_raid",
        titleFallback = "Raid",
        descKey = "cds_p3_raid_desc",
        descFallback = "Complete raid view with essentials, utility and tracked buffs.",
        sourceKey = "cds_p3_raid_sources",
        sourceFallback = "Blizzard sources: Essentials + Utility + Tracked Buffs",
    },
}
local PROFILE_ORDER = { "solo", "party", "raid" }

local function ProfileTitle(key)
    local d = PROFILE_UI[key]
    return Loc(d.titleKey, d.titleFallback)
end

local function PackNames(specName)
    specName = specName or Loc("cds_p3_unknown_spec", "Current spec")
    return {
        solo  = string.format(Loc("cds_p3_bar_minimal", "Minimal - %s"), specName),
        party = string.format(Loc("cds_p3_bar_mythic", "Mythic+ - %s"), specName),
        raid  = string.format(Loc("cds_p3_bar_raid", "Raid - %s"), specName),
    }
end

local function CreateProfilePreviewRow(parent, y, previews, activeKey)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", 8, y)
    row:SetPoint("TOPRIGHT", -8, y)
    row:SetHeight(218)

    local cards = {}
    for i, key in ipairs(PROFILE_ORDER) do
        local ui = PROFILE_UI[key]
        local card = CreateFrame("Frame", nil, row, "BackdropTemplate")
        card:SetBackdrop({ bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 })
        card:SetBackdropColor(0.045, 0.050, 0.070, 0.98)
        card:SetBackdropBorderColor(AZURE[1], AZURE[2], AZURE[3], key == activeKey and 0.95 or 0.30)
        cards[i] = card

        local top = card:CreateTexture(nil, "ARTWORK")
        top:SetHeight(2)
        top:SetPoint("TOPLEFT", 1, -1)
        top:SetPoint("TOPRIGHT", -1, -1)
        top:SetColorTexture(AZURE[1], AZURE[2], AZURE[3], key == activeKey and 1 or 0.35)

        local title = card:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_BOLD, 12, "")
        title:SetPoint("TOPLEFT", 12, -12)
        title:SetPoint("TOPRIGHT", -12, -12)
        title:SetJustifyH("LEFT")
        title:SetText(ProfileTitle(key))
        title:SetTextColor(key == activeKey and AZURE[1] or TEXT[1],
                           key == activeKey and AZURE[2] or TEXT[2],
                           key == activeKey and AZURE[3] or TEXT[3], 1)

        if key == activeKey then
            local badge = card:CreateFontString(nil, "OVERLAY")
            badge:SetFont(FONT_BOLD, 9, "")
            badge:SetPoint("TOPRIGHT", -12, -13)
            badge:SetText(Loc("cds_p3_active", "ACTIVE NOW"))
            badge:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 1)
        end

        local desc = card:CreateFontString(nil, "OVERLAY")
        desc:SetFont(FONT, 9, "")
        desc:SetPoint("TOPLEFT", 12, -34)
        desc:SetPoint("TOPRIGHT", -12, -34)
        desc:SetJustifyH("LEFT")
        desc:SetWordWrap(true)
        desc:SetText(Loc(ui.descKey, ui.descFallback))
        desc:SetTextColor(DIM[1], DIM[2], DIM[3], 1)

        local source = card:CreateFontString(nil, "OVERLAY")
        source:SetFont(FONT, 8, "")
        source:SetPoint("TOPLEFT", 12, -70)
        source:SetPoint("TOPRIGHT", -12, -70)
        source:SetJustifyH("LEFT")
        source:SetText(Loc(ui.sourceKey, ui.sourceFallback))
        source:SetTextColor(AZURE[1], AZURE[2], AZURE[3], 0.82)

        local data = previews[key]
        local count = card:CreateFontString(nil, "OVERLAY")
        count:SetFont(FONT_BOLD, 9, "")
        count:SetPoint("TOPLEFT", 12, -90)
        count:SetText(string.format(Loc("cds_p3_spell_count", "%d spells"), data and #data or 0))
        count:SetTextColor(TEXT[1], TEXT[2], TEXT[3], 1)

        if data and #data > 0 then
            local maxIcons = math.min(#data, 12)
            for n = 1, maxIcons do
                local entry = data[n]
                local icon = card:CreateTexture(nil, "ARTWORK")
                icon:SetSize(28, 28)
                local col = (n - 1) % 6
                local rr  = math.floor((n - 1) / 6)
                icon:SetPoint("TOPLEFT", 12 + col * 33, -(112 + rr * 34))
                icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(entry.id)
                icon:SetTexture(tex or QUESTION)
            end
            if #data > 12 then
                local more = card:CreateFontString(nil, "OVERLAY")
                more:SetFont(FONT_BOLD, 9, "")
                more:SetPoint("BOTTOMRIGHT", -12, 12)
                more:SetText("+" .. tostring(#data - 12))
                more:SetTextColor(DIM[1], DIM[2], DIM[3], 1)
            end
        else
            local empty = card:CreateFontString(nil, "OVERLAY")
            empty:SetFont(FONT, 9, "")
            empty:SetPoint("TOPLEFT", 12, -118)
            empty:SetPoint("TOPRIGHT", -12, -118)
            empty:SetText(Loc("cds_p3_preview_unavailable", "Preview unavailable for this profile."))
            empty:SetTextColor(DIM[1], DIM[2], DIM[3], 1)
        end
    end

    local function Layout(_, width)
        width = width or row:GetWidth() or 0
        if width <= 0 then return end
        local gap = 8
        local cardW = math.max(150, (width - gap * 2) / 3)
        for i, card in ipairs(cards) do
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", row, "TOPLEFT", (i - 1) * (cardW + gap), 0)
            card:SetSize(cardW, 218)
        end
    end
    row:SetScript("OnSizeChanged", Layout)
    row:SetScript("OnShow", Layout)
    Layout(row, row:GetWidth())
    return y - 226
end

local function TabPresetsV3(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c, y = scroll.child, -12
    local selectedClass = S.state.class
    local playerClass = CDF.PlayerClass and CDF.PlayerClass()
    local specID, specName = CurrentSpec()
    local activeKey = CurrentContext()

    local card, cy = W.CreateCard(c, Loc("cds_p3_title", "Contextual cooldown presets"), y)
    _, cy = W.CreateInfoText(card.inner,
        Loc("cds_p3_intro", "Install one contextual pack for the active specialization. TomoMod then switches automatically between Minimal when solo, Mythic+ in a non-raid group, and Raid when in a raid."), cy)
    _, cy = W.CreateInfoText(card.inner,
        string.format(Loc("cds_p3_current", "Current context: %s - profile: %s"),
            (activeKey == "raid" and Loc("cds_p3_context_raid", "Raid"))
            or (activeKey == "party" and Loc("cds_p3_context_party", "Group"))
            or Loc("cds_p3_context_solo", "Solo"),
            ProfileTitle(activeKey)), cy)
    y = W.FinalizeCard(card, cy)

    if selectedClass ~= playerClass or specID == 0 then
        card, cy = W.CreateCard(c, Loc("cds_p3_unavailable_title", "Preset unavailable"), y)
        _, cy = W.CreateInfoText(card.inner,
            Loc("cds_p3_wrong_class", "The contextual preset reads Blizzard's live cooldown categories for the character currently logged in. Select that character's class and an active specialization to install it."), cy)
        W.FinalizeCard(card, cy)
        c:SetHeight(math.max(1, math.abs(y) + 180))
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    local previews = {}
    local previewStatus
    for _, key in ipairs(PROFILE_ORDER) do
        local data, status = CDF.GetContextPresetProfileData and CDF.GetContextPresetProfileData(key)
        previews[key] = data
        if not data then previewStatus = previewStatus or status end
    end

    local _, py = W.CreateSubLabel(c,
        string.format(Loc("cds_p3_spec", "Specialization: %s"), specName or tostring(specID)), y)
    y = py - 4
    y = CreateProfilePreviewRow(c, y, previews, activeKey)

    card, cy = W.CreateCard(c, Loc("cds_p3_install_title", "Contextual pack"), y)
    local pack = CDF.FindContextPresetPack and CDF.FindContextPresetPack(selectedClass, specID) or {}
    local installed = 0
    for _, key in ipairs(PROFILE_ORDER) do if pack[key] then installed = installed + 1 end end

    if installed > 0 then
        _, cy = W.CreateInfoText(card.inner,
            string.format(Loc("cds_p3_installed", "%d/3 contextual bars are installed for this specialization. Updating keeps your per-spell settings and manual additions."), installed), cy)
    else
        _, cy = W.CreateInfoText(card.inner,
            Loc("cds_p3_install_info", "Installation creates three linked bars at the same position. Their visibility changes automatically with your group context."), cy)
    end

    if previewStatus and not (previews.solo or previews.party or previews.raid) then
        _, cy = W.CreateInfoText(card.inner,
            previewStatus == "noapi"
                and Loc("cds_p3_noapi", "Blizzard's cooldown category API is unavailable on this client.")
                or Loc("cds_p3_empty", "Blizzard has not provided cooldown entries for this specialization yet."), cy)
    else
        _, cy = W.CreateButton(card.inner,
            installed > 0 and Loc("cds_p3_update", "Update contextual pack")
                          or Loc("cds_p3_install", "Install contextual pack"),
            230, cy, function()
                local bars, statsOrErr = CDF.InstallContextPresetPack(
                    selectedClass, specID, PackNames(specName))
                if not bars then
                    local msg = (statsOrErr == "noapi")
                        and Loc("cds_p3_noapi", "Blizzard's cooldown category API is unavailable on this client.")
                        or Loc("cds_p3_install_failed", "The contextual pack could not be installed yet. Try again after the spellbook and Cooldown Manager have finished loading.")
                    print("|cff3aa7ffCooldown Studio|r: " .. msg)
                    return
                end
                local target = bars[CurrentContext()] or bars.solo or bars.party or bars.raid
                if target then S.state.barId = target.id end
                S.state.fxIdx = nil
                if CDF.RefreshAll then CDF.RefreshAll() end
                S.RebuildSidebar()
                S.RebuildContent()
                print("|cff3aa7ffCooldown Studio|r: " .. Loc("cds_p3_install_done", "Contextual preset pack updated."))
            end)
    end
    _, cy = W.CreateInfoText(card.inner,
        Loc("cds_p3_linked_position", "The three bars share their position in Edit Mode: moving the contextual preset moves the whole pack. Their visual styles remain independent, so you may customize Solo, Mythic+ and Raid differently."), cy)
    y = W.FinalizeCard(card, cy)

    card, cy = W.CreateCard(c, Loc("cds_p3_blizzard_title", "Blizzard imports"), y)
    _, cy = W.CreateInfoText(card.inner,
        Loc("cds_p3_blizzard_info", "These create a normal standalone bar from one Blizzard Cooldown Manager category. Use them when you do not want automatic context switching."), cy)
    local function ImportViewer(key)
        local id, info = CDF.CreateBarFromViewer and CDF.CreateBarFromViewer(selectedClass, key)
        if not id then
            print("|cff3aa7ffCooldown Studio|r: " .. ((info == "noapi")
                and Loc("cds_p3_noapi", "Blizzard's cooldown category API is unavailable on this client.")
                or Loc("cds_p3_empty", "Blizzard has not provided cooldown entries for this specialization yet.")))
            return
        end
        S.state.barId = id
        if CDF.RefreshAll then CDF.RefreshAll() end
        S.RebuildSidebar(); S.RebuildContent()
    end
    _, cy = W.CreateButtonRow(card.inner, {
        { text = Loc("cds_p3_import_essential", "Import Essentials"), width = 170, callback = function() ImportViewer("essential") end },
        { text = Loc("cds_p3_import_utility", "Import Utility"), width = 170, callback = function() ImportViewer("utility") end },
        { text = Loc("cds_p3_import_buffs", "Import Tracked Buffs"), width = 180, callback = function() ImportViewer("buff") end },
    }, cy)
    y = W.FinalizeCard(card, cy)

    c:SetHeight(math.max(1, math.abs(y) + 18))
    if scroll.UpdateScroll then scroll.UpdateScroll() end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if scroll and scroll.UpdateScroll then scroll.UpdateScroll() end
        end)
    end
    return scroll
end

-- Insert the new Presets tab between Library and Visibility. The shared tab
-- panel is wrapped only inside Cooldown Studio; all other TomoMod panels keep
-- their original tab lists.
if not W._TomoCDStudioPresetsV3Wrapped then
    W._TomoCDStudioPresetsV3Wrapped = true
    local OriginalCreateTabPanel = W.CreateTabPanel
    W.CreateTabPanel = function(parent, tabs, ...)
        if IsInsideCooldownStudio(parent) and type(tabs) == "table" then
            local hasPreset = false
            local libraryIndex
            for i, tab in ipairs(tabs) do
                if tab.key == "presets" then hasPreset = true end
                if tab.key == "library" then libraryIndex = i end
            end
            if not hasPreset then
                table.insert(tabs, (libraryIndex or #tabs) + 1, {
                    key = "presets",
                    label = Loc("cds_p3_tab", "Presets"),
                    builder = TabPresetsV3,
                })
            end
        end
        return OriginalCreateTabPanel(parent, tabs, ...)
    end
end

end
