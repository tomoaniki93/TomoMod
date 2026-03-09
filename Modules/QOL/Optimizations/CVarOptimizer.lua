-- =====================================
-- TomoMod — CVarOptimizer.lua
-- Optimisation graphique / réseau via CVars
-- Inspiré de NaowhQOL Optimizations
-- =====================================

TomoMod_CVarOptimizer = TomoMod_CVarOptimizer or {}
local OPT = TomoMod_CVarOptimizer

-- =====================================
-- TABLE DES CVARS
-- =====================================
-- { cvar, optimal, labelKey, category }
-- category : "render" | "graphics" | "detail" | "advanced" | "fps" | "post"

OPT.CVARS = {
    -- Render & Display
    { cvar = "renderScale",             optimal = "1",      labelKey = "opt_cvar_render_scale",       category = "render"   },
    { cvar = "VSync",                   optimal = "0",      labelKey = "opt_cvar_vsync",              category = "render"   },
    { cvar = "MSAAQuality",             optimal = "0",      labelKey = "opt_cvar_msaa",               category = "render"   },
    { cvar = "LowLatencyMode",          optimal = "3",      labelKey = "opt_cvar_low_latency",        category = "render"   },
    { cvar = "ffxAntiAliasingMode",     optimal = "4",      labelKey = "opt_cvar_anti_aliasing",      category = "render"   },
    -- Graphics Quality
    { cvar = "graphicsShadowQuality",   optimal = "1",      labelKey = "opt_cvar_shadow",             category = "graphics" },
    { cvar = "graphicsSSAO",            optimal = "0",      labelKey = "opt_cvar_ssao",               category = "graphics" },
    { cvar = "graphicsDepthEffects",    optimal = "0",      labelKey = "opt_cvar_depth",              category = "graphics" },
    { cvar = "graphicsComputeEffects",  optimal = "0",      labelKey = "opt_cvar_compute",            category = "graphics" },
    { cvar = "graphicsParticleDensity", optimal = "3",      labelKey = "opt_cvar_particle",           category = "graphics" },
    { cvar = "graphicsLiquidDetail",    optimal = "2",      labelKey = "opt_cvar_liquid",             category = "graphics" },
    { cvar = "graphicsSpellDensity",    optimal = "0",      labelKey = "opt_cvar_spell_density",      category = "graphics" },
    { cvar = "graphicsProjectedTextures",optimal = "1",     labelKey = "opt_cvar_projected",          category = "graphics" },
    { cvar = "graphicsOutlineMode",     optimal = "2",      labelKey = "opt_cvar_outline",            category = "graphics" },
    { cvar = "graphicsTextureResolution",optimal = "2",     labelKey = "opt_cvar_texture_res",        category = "graphics" },
    -- View Distance & Detail
    { cvar = "graphicsViewDistance",    optimal = "3",      labelKey = "opt_cvar_view_distance",      category = "detail"   },
    { cvar = "graphicsEnvironmentDetail",optimal = "3",     labelKey = "opt_cvar_env_detail",         category = "detail"   },
    { cvar = "graphicsGroundClutter",   optimal = "0",      labelKey = "opt_cvar_ground",             category = "detail"   },
    -- Advanced
    { cvar = "GxApi",                   optimal = "D3D12",  labelKey = "opt_cvar_gfx_api",            category = "advanced" },
    { cvar = "GxMaxFrameLatency",       optimal = "2",      labelKey = "opt_cvar_triple_buffering",   category = "advanced" },
    { cvar = "TextureFilteringMode",    optimal = "5",      labelKey = "opt_cvar_texture_filtering",  category = "advanced" },
    { cvar = "shadowRt",                optimal = "0",      labelKey = "opt_cvar_rt_shadows",         category = "advanced" },
    { cvar = "ResampleQuality",         optimal = "3",      labelKey = "opt_cvar_resample_quality",   category = "advanced" },
    { cvar = "physicsLevel",            optimal = "1",      labelKey = "opt_cvar_physics",            category = "advanced" },
    -- FPS Limits
    { cvar = "useTargetFPS",            optimal = "0",      labelKey = "opt_cvar_target_fps",         category = "fps"      },
    { cvar = "useMaxFPSBk",             optimal = "1",      labelKey = "opt_cvar_bg_fps_enable",      category = "fps"      },
    { cvar = "maxFPSBk",                optimal = "30",     labelKey = "opt_cvar_bg_fps",             category = "fps"      },
    -- Post Processing
    { cvar = "ResampleSharpness",       optimal = "0",      labelKey = "opt_cvar_resample_sharpness", category = "post"     },
    { cvar = "cameraShake",             optimal = "0",      labelKey = "opt_cvar_camera_shake",       category = "post"     },
}

OPT.CATEGORIES = {
    { key = "render",   labelKey = "opt_cat_render"   },
    { key = "graphics", labelKey = "opt_cat_graphics"  },
    { key = "detail",   labelKey = "opt_cat_detail"    },
    { key = "advanced", labelKey = "opt_cat_advanced"  },
    { key = "fps",      labelKey = "opt_cat_fps"       },
    { key = "post",     labelKey = "opt_cat_post"      },
}

-- =====================================
-- HELPERS VALEUR LISIBLE
-- =====================================
-- Retourne une chaîne lisible pour affichage (pas de secret values, tout est string)
function OPT.FormatValue(cvar, rawVal)
    if rawVal == nil or rawVal == "" then return "?" end

    local n = tonumber(rawVal)

    if cvar == "VSync" or cvar == "useTargetFPS" or cvar == "useMaxFPSBk"
        or cvar == "graphicsProjectedTextures" or cvar == "cameraShake" then
        return (rawVal == "1" or rawVal == "true") and "ON" or "OFF"

    elseif cvar == "renderScale" then
        return math.floor((n or 1) * 100) .. "%"

    elseif cvar == "maxFPSBk" then
        return rawVal .. " FPS"

    elseif cvar == "LowLatencyMode" then
        local t = { [0]="None", [1]="Built-In", [2]="Reflex", [3]="Reflex+Boost" }
        return t[n] or rawVal

    elseif cvar == "ffxAntiAliasingMode" then
        local t = { [0]="None", [1]="Image-Based", [2]="Multisample", [4]="CMAA2" }
        return t[n] or rawVal

    elseif cvar == "MSAAQuality" then
        local t = { [0]="None", [1]="2x", [2]="4x", [3]="8x" }
        return t[n] or rawVal

    elseif cvar == "graphicsShadowQuality" then
        local t = { [0]="Low", [1]="Fair", [2]="Good", [3]="High", [4]="Ultra", [5]="Ultra+" }
        return t[n] or rawVal

    elseif cvar == "graphicsLiquidDetail" then
        local t = { [0]="Low", [1]="Fair", [2]="Good", [3]="High" }
        return t[n] or rawVal

    elseif cvar == "graphicsParticleDensity" then
        local t = { [0]="Off", [1]="Low", [2]="Fair", [3]="Good", [4]="High", [5]="Ultra" }
        return t[n] or rawVal

    elseif cvar == "graphicsSSAO" or cvar == "graphicsDepthEffects"
        or cvar == "graphicsComputeEffects" then
        local t = { [0]="Off", [1]="Low", [2]="Good", [3]="High" }
        return t[n] or rawVal

    elseif cvar == "graphicsSpellDensity" then
        local t = { [0]="Essential", [1]="Low", [2]="Fair", [3]="Good", [4]="High", [5]="Ultra" }
        return t[n] or rawVal

    elseif cvar == "graphicsOutlineMode" then
        local t = { [1]="Low", [2]="High", [3]="Ultra" }
        return t[n] or rawVal

    elseif cvar == "graphicsTextureResolution" then
        local t = { [1]="Low", [2]="High", [3]="Ultra" }
        return t[n] or rawVal

    elseif cvar == "graphicsViewDistance" or cvar == "graphicsEnvironmentDetail"
        or cvar == "graphicsGroundClutter" then
        return "Level " .. tostring((n or 0) + 1)

    elseif cvar == "GxApi" then
        local u = string.upper(rawVal or "")
        if u == "D3D12" then return "DX12"
        elseif u == "D3D11" then return "DX11"
        else return rawVal end

    elseif cvar == "GxMaxFrameLatency" then
        return (n == 3) and "Triple buf." or "Disabled"

    elseif cvar == "TextureFilteringMode" then
        local t = { [0]="Bilinear", [1]="Trilinear", [2]="2x Aniso",
                    [3]="4x Aniso", [4]="8x Aniso", [5]="16x Aniso" }
        return t[n] or rawVal

    elseif cvar == "shadowRt" then
        local t = { [0]="Off", [1]="Low", [2]="Good", [3]="High", [4]="Ultra" }
        return t[n] or rawVal

    elseif cvar == "ResampleQuality" then
        local t = { [0]="Point", [1]="Bilinear", [2]="Bicubic", [3]="FidelityFX SR 1.0" }
        return t[n] or rawVal

    elseif cvar == "physicsLevel" then
        local t = { [0]="None", [1]="Player Only", [2]="Full" }
        return t[n] or rawVal

    elseif cvar == "ResampleSharpness" then
        return (n == 0) and "Off" or tostring(n)
    end

    return rawVal
end

-- Lit la valeur actuelle d'une CVar (safe via pcall)
function OPT.GetRaw(cvar)
    local ok, val = pcall(GetCVar, cvar)
    return (ok and val) and val or nil
end

-- Vérifie si une CVar est déjà à la valeur optimale
function OPT.IsOptimal(cvar, optimal)
    local raw = OPT.GetRaw(cvar)
    if not raw then return false end
    local n1, n2 = tonumber(raw), tonumber(optimal)
    if n1 and n2 then return n1 == n2 end
    return string.lower(tostring(raw)) == string.lower(tostring(optimal))
end

-- =====================================
-- APPLY ALL
-- =====================================
function OPT.ApplyAll()
    local db = TomoModDB and TomoModDB.cvarOptimizer
    if not db then return end

    -- Sauvegarder les valeurs actuelles (une seule fois)
    if not db.backup then
        db.backup = {}
        for _, entry in ipairs(OPT.CVARS) do
            local raw = OPT.GetRaw(entry.cvar)
            if raw then db.backup[entry.cvar] = raw end
        end
    end

    local ok, fail = 0, 0
    for _, entry in ipairs(OPT.CVARS) do
        if pcall(SetCVar, entry.cvar, entry.optimal) then
            ok = ok + 1
        else
            fail = fail + 1
        end
    end

    local msg = string.format("|cff0cd29fTomoMod:|r %s (%d ok", TomoMod_L["msg_cvar_applied"], ok)
    if fail > 0 then msg = msg .. ", " .. fail .. " ignorés" end
    print(msg .. ")")

    -- Proposer un reload
    StaticPopup_Show("TOMOMOD_CVAR_RELOAD")
end

-- =====================================
-- REVERT ALL
-- =====================================
function OPT.RevertAll()
    local db = TomoModDB and TomoModDB.cvarOptimizer
    if not db or not db.backup then
        print("|cff0cd29fTomoMod:|r " .. TomoMod_L["msg_cvar_no_backup"])
        return
    end

    local ok = 0
    for cvar, val in pairs(db.backup) do
        if pcall(SetCVar, cvar, val) then ok = ok + 1 end
    end

    db.backup = nil

    print(string.format("|cff0cd29fTomoMod:|r %s (%d restaurées)", TomoMod_L["msg_cvar_reverted"], ok))
    StaticPopup_Show("TOMOMOD_CVAR_RELOAD")
end

-- =====================================
-- APPLY / REVERT INDIVIDUEL
-- =====================================
function OPT.ApplyOne(cvar, optimal)
    local db = TomoModDB and TomoModDB.cvarOptimizer
    if not db then return false end

    if not db.individualBackup then db.individualBackup = {} end

    -- Sauvegarder uniquement si pas déjà backup
    if not db.individualBackup[cvar] then
        local raw = OPT.GetRaw(cvar)
        if raw then db.individualBackup[cvar] = raw end
    end

    return pcall(SetCVar, cvar, optimal)
end

function OPT.RevertOne(cvar)
    local db = TomoModDB and TomoModDB.cvarOptimizer
    if not db or not db.individualBackup or not db.individualBackup[cvar] then
        return false
    end

    local ok = pcall(SetCVar, cvar, db.individualBackup[cvar])
    if ok then db.individualBackup[cvar] = nil end
    return ok
end

function OPT.HasIndividualBackup(cvar)
    local db = TomoModDB and TomoModDB.cvarOptimizer
    return db and db.individualBackup and db.individualBackup[cvar] ~= nil
end

function OPT.HasGlobalBackup()
    local db = TomoModDB and TomoModDB.cvarOptimizer
    return db and db.backup ~= nil
end

-- =====================================
-- DIALOG RELOAD UI
-- =====================================
local dialogRegistered = false
local function RegisterDialog()
    if dialogRegistered then return end
    dialogRegistered = true
    StaticPopupDialogs["TOMOMOD_CVAR_RELOAD"] = {
        text = "|cff0cd29fTomoMod — CVars|r\n\n"
            .. "Paramètres appliqués.\n\n"
            .. "|cffffaa00Un ReloadUI est recommandé pour activer certains changements.|r",
        button1 = "ReloadUI",
        button2 = "Plus tard",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

-- =====================================
-- INITIALISATION
-- =====================================
function OPT.Initialize()
    if not TomoModDB then return end

    if not TomoModDB.cvarOptimizer then
        TomoModDB.cvarOptimizer = {
            backup           = nil,  -- backup global (Apply All)
            individualBackup = nil,  -- backup par CVar
        }
    end

    RegisterDialog()
end

_G.TomoMod_CVarOptimizer = OPT
