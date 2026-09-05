-- =====================================================================
-- BFElements.lua — Astral Forge descriptors for the Boss Frames domain
--
-- Boss Frames do not share the normal UnitFrame widget tree: nameText and
-- healthText live directly on the boss frame, while the normal UnitFrame
-- domain resolves them below health. Keeping a dedicated domain avoids
-- false resolutions and makes saved Boss layouts apply even when Astral
-- Forge itself has not been loaded in the current session.
-- =====================================================================

local Forge = TomoMod_Forge
if not (Forge and Forge.Registry) then return end

local R = Forge.Registry

TomoMod_BossFrameElements = TomoMod_BossFrameElements or {}
local BFE = TomoMod_BossFrameElements

BFE.DOMAIN = "bossframe"
local DOMAIN = BFE.DOMAIN

R.DefineHost(DOMAIN, {
    id = "frame",
    labelKey = "anchor_host_frame",
    resolve = function(frame) return frame end,
})

R.DefineHost(DOMAIN, {
    id = "health",
    labelKey = "anchor_host_health",
    resolve = function(frame) return frame and frame.health end,
})

R.Define(DOMAIN, {
    id = "name",
    kind = "fontstring",
    labelKey = "elem_name",
    order = 10,
    anchorMode = "inside",
    default = {
        point = "LEFT", relTo = "health", relPoint = "LEFT", x = 22, y = 0,
    },
    resolve = function(frame) return frame and frame.nameText end,
})

R.Define(DOMAIN, {
    id = "healthText",
    kind = "fontstring",
    labelKey = "elem_health_text",
    order = 20,
    anchorMode = "inside",
    default = {
        point = "RIGHT", relTo = "health", relPoint = "RIGHT", x = -6, y = 0,
    },
    resolve = function(frame) return frame and frame.healthText end,
})

R.Define(DOMAIN, {
    id = "raidIcon",
    kind = "texture",
    labelKey = "elem_raid_icon",
    order = 30,
    anchorMode = "inside",
    default = {
        point = "LEFT", relTo = "health", relPoint = "LEFT", x = 4, y = 0,
    },
    resolve = function(frame) return frame and frame.raidIcon end,
})

function BFE.List()
    return R.List(DOMAIN)
end

function BFE.ListHosts()
    return R.ListHosts(DOMAIN)
end

function BFE.AllowedTargets(id, store)
    return R.AllowedTargets(DOMAIN, id, store)
end

function BFE.Defaults()
    local out = {}
    for _, desc in ipairs(R.List(DOMAIN)) do
        out[desc.id] = R.Default(DOMAIN, desc.id)
    end
    return out
end

function BFE.Ensure(store)
    return R.Ensure(DOMAIN, store)
end

function BFE.ApplyAll(frame, store)
    return R.ApplyAll(DOMAIN, frame, store)
end
