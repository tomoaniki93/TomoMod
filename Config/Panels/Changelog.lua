-- Panels/Changelog.lua
--
-- Every release TomoMod has shipped. The "what's new" popup only ever shows
-- the version you just updated to, and once dismissed the text is gone;
-- this page is the archive.
--
-- The notes are not rendered here. They are handed to the same popup that
-- appears after an update, which already has a scroll frame sized to its
-- content -- the first version of this page laid them out inline and the
-- paragraphs overlapped, because the info-text widget measures its height
-- immediately after SetText, before the frame has a width, so a wrapped
-- paragraph is measured as a single line.
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

local PER_ROW = 4

function TomoMod_ConfigPanel_Changelog(parent)
    local scroll = W.CreateScrollPanel(parent)
    local c = scroll.child
    local y = -12

    local WN = TomoMod_WhatsNew
    local releases = WN and WN.GetChangelog and WN.GetChangelog()

    if type(releases) ~= "table" or #releases == 0 then
        local card, cy = W.CreateCard(c, LT("cl_title", "Journal des versions"), y)
        _, cy = W.CreateInfoText(card.inner, LT("cl_unavailable",
            "Le journal des versions n'a pas pu etre charge."), cy)
        W.FinalizeCard(card, cy)
        if scroll.UpdateScroll then scroll.UpdateScroll() end
        return scroll
    end

    local card, cy = W.CreateCard(c, LT("cl_title", "Journal des versions"), y)

    _, cy = W.CreateInfoText(card.inner, string.format(
        LT("cl_intro", "%d versions. Clique sur un numero pour lire ses notes."),
        #releases), cy)

    -- The newest release first, four per row: 59 buttons in one column
    -- would be a very long page for what is essentially an index.
    local i = 1
    while i <= #releases do
        local row = {}
        for _ = 1, PER_ROW do
            local rel = releases[i]
            if not rel then break end
            local version = tostring(rel.version)
            local count = #(rel.highlights or {})
            row[#row + 1] = {
                text = string.format("%s  (%d)", version, count),
                width = 116,
                callback = function()
                    if WN.ShowVersion then WN.ShowVersion(version) end
                end,
            }
            i = i + 1
        end
        _, cy = W.CreateButtonRow(card.inner, row, cy)
    end

    y = W.FinalizeCard(card, cy)

    if scroll.UpdateScroll then scroll.UpdateScroll() end
    return scroll
end
