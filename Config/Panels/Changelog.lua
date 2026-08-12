-- Panels/Changelog.lua
--
-- Every release TomoMod has shipped, as an accordion. The "what's new"
-- popup only ever shows the version you just updated to, and once it is
-- dismissed the text is gone; this page is the archive.
--
-- The release list is read from Core/WhatsNew.lua rather than duplicated:
-- one table, two readers.

local W = TomoMod_Widgets
local L = TomoMod_L

local function LT(key, fallback)
    local v = L and L[key]
    if v == nil or v == key then return fallback end
    return v
end

-- Which versions are open. Kept at file scope so the state survives the
-- panel rebuild that every toggle triggers.
local expanded = {}

-- Every toggle rebuilds the page. SwitchCategory is the switch the sidebar
-- uses, and "changelog" is in NO_CACHE, so it rebuilds rather than showing
-- a stale copy.
local function Rebuild()
    if TomoMod_Config and TomoMod_Config.SwitchCategory then
        TomoMod_Config.SwitchCategory("changelog")
    end
end

function TomoMod_ConfigPanel_Changelog(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    local releases = TomoMod_WhatsNew and TomoMod_WhatsNew.GetChangelog
        and TomoMod_WhatsNew.GetChangelog()

    if type(releases) ~= "table" or #releases == 0 then
        local card, cy = W.CreateCard(c, LT("cl_title", "Journal des versions"), y)
        _, cy = W.CreateInfoText(card.inner, LT("cl_unavailable",
            "Le journal des versions n'a pas pu etre charge."), cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    -- ── Header: search and bulk toggles ──────────────────────────────
    local card, cy = W.CreateCard(c, LT("cl_title", "Journal des versions"), y)

    _, cy = W.CreateInfoText(card.inner, string.format(
        LT("cl_intro", "%d versions. Clique sur un numero pour lire ses notes."),
        #releases), cy)

    _, cy = W.CreateButtonRow(card.inner, {
        { text = LT("cl_expand_all", "Tout ouvrir"), width = 150, callback = function()
            for _, rel in ipairs(releases) do expanded[rel.version] = true end
            Rebuild()
        end },
        { text = LT("cl_collapse_all", "Tout fermer"), width = 150, callback = function()
            wipe(expanded)
            Rebuild()
        end },
    }, cy)

    y = W.FinalizeCard(card, cy)

    -- ── One accordion row per release ────────────────────────────────
    for _, rel in ipairs(releases) do
        local highlights = rel.highlights or {}
        local isOpen = expanded[rel.version] == true

        local label = string.format("%s  %s  (%d)", isOpen and "-" or "+",
            tostring(rel.version), #highlights)

        local relCard, rcy = W.CreateCard(c, label, y)

        _, rcy = W.CreateButton(relCard.inner,
            isOpen and LT("cl_close", "Fermer") or LT("cl_open", "Lire les notes"),
            200, rcy, function()
                -- nil rather than false: the table only ever holds what is
                -- open, so it does not grow with every version ever clicked.
                expanded[rel.version] = (not isOpen) or nil
                Rebuild()
            end)

        if isOpen then
            if #highlights == 0 then
                _, rcy = W.CreateInfoText(relCard.inner,
                    LT("cl_empty", "Aucune note pour cette version."), rcy)
            else
                for _, line in ipairs(highlights) do
                    -- A missing locale string comes back as the key itself;
                    -- printing "wn_342_astralforge" would be worse than
                    -- skipping the line.
                    if type(line) == "string" and line ~= ""
                        and not line:match("^wn_[%w_]+$") then
                        _, rcy = W.CreateInfoText(relCard.inner, line, rcy)
                    end
                end
            end
        end

        y = W.FinalizeCard(relCard, rcy)
    end

    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end
