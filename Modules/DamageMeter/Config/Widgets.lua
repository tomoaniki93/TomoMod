local ADDON_NAME, ns = ...

----------------------------------------------------------------------
-- Reusable Settings Widget Factories
----------------------------------------------------------------------

ns.Widgets = {}

-- Slider widget
--
-- OptionsSliderTemplate rather than MinimalSliderTemplate. The minimal variant
-- is driven by a mixin that expects to own its own value plumbing, and it is
-- not a supported target for a factory that configures the Slider directly;
-- OptionsSliderTemplate is a plain Slider carrying three FontStrings, which is
-- exactly what is wanted. Those labels are blanked because this widget draws
-- its own title and value above the bar.
--
-- The template names those FontStrings "$parentLow" and friends, so the slider
-- itself needs a name for the substitution to resolve against — hence the
-- counter. Passing nil leaves $parent with nothing to expand to.
local sliderCount = 0

function ns.Widgets.CreateSlider(parent, label, min, max, step, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(50)

    local title = frame:CreateFontString(nil, "ARTWORK")
    title:SetFont(ns.GetFont(), 11, "OUTLINE")
    title:SetTextColor(0.75, 0.75, 0.78)
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText(label)

    local valueText = frame:CreateFontString(nil, "ARTWORK")
    valueText:SetFont(ns.GetFont(), 11, "OUTLINE")
    valueText:SetTextColor(1.00, 1.00, 1.00)
    valueText:SetPoint("TOPRIGHT", 0, 0)

    sliderCount = sliderCount + 1
    local slider = CreateFrame("Slider", "TomoDMSettingsSlider" .. sliderCount,
        frame, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    slider:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    slider:SetHeight(16)
    slider:SetObeyStepOnDrag(true)
    if slider.Low  then slider.Low:SetText("")  end
    if slider.High then slider.High:SetText("") end
    if slider.Text then slider.Text:SetText("") end

    local fmtStr = step < 1 and "%.2f" or "%.0f"
    valueText:SetText(string.format(fmtStr, getter()))

    -- The template's own OnLoad and OnShow run after this function returns and
    -- put the range back to the template default, so the real values are
    -- applied again on the next frame. `initializing` keeps that second pass
    -- from writing a template-clamped value back through the setter.
    local initializing = false
    local function ApplyRange()
        initializing = true
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        slider:SetValue(getter())
        initializing = false
    end
    ApplyRange()
    C_Timer.After(0, ApplyRange)

    slider:SetScript("OnValueChanged", function(self, val)
        if initializing then return end
        val = math.floor(val / step + 0.5) * step
        valueText:SetText(string.format(fmtStr, val))
        setter(val)
    end)

    frame.slider = slider
    frame.Refresh = function()
        initializing = true
        slider:SetValue(getter())
        initializing = false
        valueText:SetText(string.format(fmtStr, getter()))
    end

    return frame
end

-- Checkbox widget
function ns.Widgets.CreateCheckbox(parent, label, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(24)

    local btn = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    btn:SetSize(24, 24)
    btn:SetPoint("LEFT", 0, 0)

    local title = frame:CreateFontString(nil, "ARTWORK")
    title:SetFont(ns.GetFont(), 11, "OUTLINE")
    title:SetTextColor(0.75, 0.75, 0.78)
    title:SetPoint("LEFT", btn, "RIGHT", 4, 0)
    title:SetText(label)

    btn:SetChecked(getter())
    btn:SetScript("OnClick", function(self)
        setter(self:GetChecked())
    end)

    frame.Refresh = function()
        btn:SetChecked(getter())
    end

    return frame
end

-- Dropdown button (simple text cycling)
-- `options` accepts either a static array of { value, label [, fontPath] } or a
-- function returning one. Passing a function keeps the list live: option sets
-- that change after the panel is built (LibSharedMedia textures registered by
-- addons loading later, meter types gated by category toggles) no longer need a
-- panel rebuild to show up.
function ns.Widgets.CreateDropdown(parent, label, options, getter, setter)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(30)

    local function GetOptions()
        if type(options) == "function" then return options() or {} end
        return options
    end

    local title = frame:CreateFontString(nil, "ARTWORK")
    title:SetFont(ns.GetFont(), 11, "OUTLINE")
    title:SetTextColor(0.75, 0.75, 0.78)
    title:SetPoint("LEFT", 0, 0)
    title:SetText(label)

    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(120, 22)
    btn:SetPoint("RIGHT", frame, "RIGHT", 0, 0)

    local btnBG = btn:CreateTexture(nil, "BACKGROUND")
    btnBG:SetTexture(ns.FLAT)
    btnBG:SetVertexColor(0.05, 0.12, 0.26, 0.92)
    btnBG:SetAllPoints()

    local btnText = btn:CreateFontString(nil, "ARTWORK")
    btnText:SetFont(ns.GetFont(), 10, "OUTLINE")
    btnText:SetTextColor(1.00, 1.00, 1.00)
    btnText:SetPoint("CENTER")

    local function UpdateText()
        local current = getter()
        for _, opt in ipairs(GetOptions()) do
            if opt.value == current then
                btnText:SetText(opt.label)
                -- Apply font preview if option has a fontPath
                if opt.fontPath then
                    btnText:SetFont(opt.fontPath, 10, "OUTLINE")
                end
                return
            end
        end
        btnText:SetText(tostring(current))
    end
    UpdateText()

    btn:SetScript("OnClick", function()
        local opts = GetOptions()
        if #opts == 0 then return end
        local current = getter()
        local idx = 1
        for i, opt in ipairs(opts) do
            if opt.value == current then idx = i; break end
        end
        local nextIdx = (idx % #opts) + 1
        setter(opts[nextIdx].value)
        UpdateText()
    end)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(ns.FLAT); hl:SetVertexColor(1, 1, 1, 0.08)
    hl:SetAllPoints()

    frame.Refresh = UpdateText
    return frame
end