-- =====================================
-- HideCastBar.lua
-- Cache la barre de cast du joueur
-- Utilise uniquement SetAlpha pour etre reversible
-- sans necessiter de /reload.
-- =====================================

TomoMod_HideCastBar = TomoMod_HideCastBar or {}
local HCB = TomoMod_HideCastBar

-- =====================================
-- VARIABLES
-- =====================================
local isHooked = false

-- =====================================
-- FONCTION PRINCIPALE
-- =====================================
local function ApplyHideCastBar()
    local settings = TomoModDB and TomoModDB.hideCastBar
    if not settings then return end
    if not PlayerCastingBarFrame then return end

    if settings.enabled then
        PlayerCastingBarFrame:SetAlpha(0)

        -- Hook OnShow une seule fois pour re-cacher a chaque apparition
        if not isHooked then
            PlayerCastingBarFrame:HookScript("OnShow", function(self)
                local s = TomoModDB and TomoModDB.hideCastBar
                if s and s.enabled then
                    self:SetAlpha(0)
                end
            end)
            isHooked = true
        end
    else
        PlayerCastingBarFrame:SetAlpha(1)
    end
end

-- =====================================
-- FONCTIONS PUBLIQUES
-- =====================================
function HCB.Initialize()
    if not TomoModDB or not TomoModDB.hideCastBar then return end

    -- Attendre que l'interface soit chargee
    C_Timer.After(1, ApplyHideCastBar)
end

function HCB.SetEnabled(enabled)
    if not TomoModDB or not TomoModDB.hideCastBar then return end

    TomoModDB.hideCastBar.enabled = enabled
    ApplyHideCastBar()

    if enabled then
        print("|cff0cd29fTomoMod:|r Barre de cast cachee")
    else
        print("|cff0cd29fTomoMod:|r Barre de cast affichee")
    end
end

function HCB.Toggle()
    if not TomoModDB or not TomoModDB.hideCastBar then return end
    HCB.SetEnabled(not TomoModDB.hideCastBar.enabled)
end

-- Export
_G.TomoMod_HideCastBar = HCB
