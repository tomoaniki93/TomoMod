-- =====================================================================
-- GearAdvisorScales.lua — TomoGear role-safe starter weights
-- ---------------------------------------------------------------------
-- These are intentionally conservative generic presets, not simulator
-- results and not data copied from Pawn. Custom weights are stored per
-- specialization by GearAdvisor.lua and always override these defaults.
-- =====================================================================

TomoMod_GearAdvisorScales = {
    DAMAGER = {
        primary = 1.00,
        stamina = 0.00,
        crit = 0.70,
        haste = 0.70,
        mastery = 0.70,
        versatility = 0.65,
    },
    HEALER = {
        primary = 1.00,
        stamina = 0.05,
        crit = 0.65,
        haste = 0.75,
        mastery = 0.70,
        versatility = 0.60,
    },
    TANK = {
        primary = 1.00,
        stamina = 0.35,
        crit = 0.50,
        haste = 0.65,
        mastery = 0.70,
        versatility = 0.75,
    },
    NONE = {
        primary = 1.00,
        stamina = 0.05,
        crit = 0.65,
        haste = 0.65,
        mastery = 0.65,
        versatility = 0.65,
    },
}
