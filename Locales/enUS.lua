-- =====================================
-- enUS.lua — English (default fallback)
-- =====================================

TomoMod_RegisterLocale("enUS", {

    -- =====================
    -- CONFIG: Categories (ConfigUI.lua)
    -- =====================
    ["cat_general"]         = "General",
    ["cat_unitframes"]      = "UnitFrames",
    ["cat_nameplates"]      = "Nameplates",
    ["cat_cd_resource"]     = "CD & Resource",
    ["cat_qol"]             = "QOL / Auto",
    ["cat_mythicplus"]      = "Mythic+",
    ["cat_profiles"]        = "Profiles",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "About",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.5.0 by TomoAniki\nLightweight interface with QOL, UnitFrames and Nameplates.\nType /tm help for the command list.",
    ["section_general"]                 = "General",
    ["btn_reset_all"]                   = "Reset All",
    ["info_reset_all"]                  = "This will reset ALL settings and reload the UI.",

    -- Minimap
    ["section_minimap"]                 = "Minimap",
    ["opt_minimap_enable"]              = "Enable custom minimap",
    ["opt_size"]                        = "Size",
    ["opt_scale"]                       = "Scale",
    ["opt_border"]                      = "Border",
    ["border_class"]                    = "Class color",
    ["border_black"]                    = "Black",

    -- Info Panel
    ["section_info_panel"]              = "Info Panel",
    ["opt_enable"]                      = "Enable",
    ["opt_durability"]                  = "Durability (Gear)",
    ["opt_time"]                        = "Time",
    ["opt_24h_format"]                  = "24h format",
    ["opt_show_coords"]                 = "Show coordinates",
    ["btn_reset_position"]              = "Reset Position",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Cursor Ring",
    ["opt_class_color"]                 = "Class color",
    ["opt_anchor_tooltip_ring"]         = "Anchor Tooltip to cursor",

    -- =====================
    -- CONFIG: UnitFrames Panel
    -- =====================
    -- Tabs
    ["tab_general"]                     = "General",
    ["tab_player"]                      = "Player",
    ["tab_target"]                      = "Target",
    ["tab_tot"]                         = "ToT",
    ["tab_pet"]                         = "Pet",
    ["tab_focus"]                       = "Focus",
    ["tab_colors"]                      = "Colors",

    -- Sub-tabs (Player, Target, Focus)
    ["subtab_dimensions"]               = "Dimensions",
    ["subtab_display"]                  = "Display",
    ["subtab_auras"]                    = "Auras",
    ["subtab_positioning"]              = "Position",

    -- Sub-labels
    ["sublabel_dimensions"]             = "— Dimensions —",
    ["sublabel_display"]                = "— Display —",
    ["sublabel_castbar"]                = "— Castbar —",
    ["sublabel_auras"]                  = "— Auras —",
    ["sublabel_element_offsets"]        = "— Element Positions —",

    -- Unit display names (used in print messages and reset buttons)
    ["unit_player"]                     = "Player",
    ["unit_target"]                     = "Target",
    ["unit_tot"]                        = "Target of Target",
    ["unit_pet"]                        = "Pet",
    ["unit_focus"]                      = "Focus",

    -- General tab
    ["section_general_settings"]        = "General Settings",
    ["opt_uf_enable"]                   = "Enable TomoMod UnitFrames",
    ["opt_hide_blizzard"]               = "Hide Blizzard frames",
    ["opt_global_font_size"]            = "Global font size",
    ["sublabel_font"]                   = "— Font —",
    ["opt_font_family"]                 = "Font family",

    -- Castbar colors
    ["section_castbar_colors"]          = "Castbar Colors",
    ["info_castbar_colors"]             = "Customize castbar colors for interruptible, non-interruptible, and interrupted casts.",
    ["opt_castbar_color"]               = "Interruptible cast",
    ["opt_castbar_ni_color"]            = "Non-interruptible cast",
    ["opt_castbar_interrupt_color"]     = "Interrupted cast",
    ["info_castbar_colors_reload"]      = "Color changes apply to new casts. Reload UI for full effect.",
    ["btn_toggle_lock"]                 = "Toggle Lock/Unlock (/tm uf)",
    ["info_unlock_drag"]                = "Unlock to move frames. Positions are saved automatically.",

    -- Per-unit options
    ["opt_width"]                       = "Width",
    ["opt_health_height"]               = "Health height",
    ["opt_power_height"]                = "Resource height",
    ["opt_show_name"]                   = "Show name",
    ["opt_name_truncate"]               = "Truncate long names",
    ["opt_name_truncate_length"]        = "Max name length",
    ["opt_show_level"]                  = "Show level",
    ["opt_show_health_text"]            = "Show health text",
    ["opt_health_format"]               = "Health format",
    ["fmt_current"]                     = "Current (25.3K)",
    ["fmt_percent"]                     = "Percentage (75%)",
    ["fmt_current_percent"]             = "Current + % (25.3K | 75%)",
    ["fmt_current_max"]                 = "Current / Max",
    ["opt_class_color_uf"]              = "Class color",
    ["opt_faction_color"]               = "Faction color (NPCs)",
    ["opt_use_nameplate_colors"]        = "Use Nameplate colors (NPC type)",
    ["opt_show_absorb"]                 = "Absorb bar",
    ["opt_show_threat"]                 = "Threat indicator (border glow)",
    ["section_threat_text"]             = "Threat % Text",
    ["opt_threat_text_enable"]          = "Show threat % on target",
    ["opt_threat_text_font_size"]       = "Font size",
    ["opt_threat_text_offset_x"]        = "Offset X",
    ["opt_threat_text_offset_y"]        = "Offset Y",
    ["info_threat_text"]                = "Green = tanking (+% lead), yellow = warning, red = aggro pulled",
    ["opt_show_leader_icon"]            = "Leader icon",
    ["opt_leader_icon_x"]               = "Leader icon X",
    ["opt_leader_icon_y"]               = "Leader icon Y",
    ["opt_raid_icon_x"]                 = "Raid marker X",
    ["opt_raid_icon_y"]                 = "Raid marker Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Enable castbar",
    ["opt_castbar_width"]               = "Castbar width",
    ["opt_castbar_height"]              = "Castbar height",
    ["opt_castbar_show_icon"]           = "Show icon",
    ["opt_castbar_show_timer"]          = "Show timer",
    ["info_castbar_drag"]               = "Position: use /tm sr to unlock and drag the castbar.",
    ["btn_reset_castbar_position"]      = "Reset Castbar Position",
    ["opt_castbar_show_latency"]        = "Show latency",

    -- Auras
    ["opt_auras_enable"]                = "Enable auras",
    ["opt_auras_max"]                   = "Max auras",
    ["opt_auras_size"]                  = "Icon size",
    ["opt_auras_type"]                  = "Aura type",
    ["aura_harmful"]                    = "Debuffs (harmful)",
    ["aura_helpful"]                    = "Buffs (beneficial)",
    ["aura_all"]                        = "All",
    ["opt_auras_direction"]             = "Growth direction",
    ["aura_dir_right"]                  = "Rightward",
    ["aura_dir_left"]                   = "Leftward",
    ["opt_auras_only_mine"]             = "Only my auras",

    -- Element offsets
    ["elem_name"]                       = "Name",
    ["elem_level"]                      = "Level",
    ["elem_health_text"]                = "Health text",
    ["elem_power"]                      = "Resource bar",
    ["elem_castbar"]                    = "Castbar",
    ["elem_auras"]                      = "Auras",

    -- =====================
    -- CONFIG: Nameplates Panel
    -- =====================
    -- Nameplate tabs
    ["tab_np_auras"]                    = "Auras",
    ["tab_np_advanced"]                 = "Advanced",
    ["info_np_colors_custom"]           = "Each color can be customized to your preference by clicking the color swatch.",

    ["section_np_general"]              = "General Settings",
    ["opt_np_enable"]                   = "Enable TomoMod Nameplates",
    ["info_np_description"]             = "Replaces Blizzard nameplates with a customizable minimalist style.",
    ["section_dimensions"]              = "Dimensions",
    ["opt_np_name_font_size"]           = "Name font size",

    -- Display
    ["section_display"]                 = "Display",
    ["opt_np_show_classification"]      = "Show classification (elite, rare, boss)",
    ["opt_np_show_absorb"]               = "Show absorb bar",
    ["opt_np_class_colors"]             = "Class colors (players)",
    ["opt_np_friendly_name_only"]       = "Friendly: name only (no health bar)",
    ["opt_np_friendly_role_icons"]      = "Show role icons (dungeon/delve)",
    ["opt_np_role_show_tank"]           = "Show Tank icon",
    ["opt_np_role_show_healer"]         = "Show Healer icon",
    ["opt_np_role_show_dps"]            = "Show DPS icon",
    ["opt_np_role_icon_size"]           = "Role icon size",

    -- Raid Marker
    ["section_raid_marker"]             = "Raid Marker",
    ["opt_np_raid_icon_anchor"]         = "Icon position",
    ["opt_np_raid_icon_x"]              = "Offset X",
    ["opt_np_raid_icon_y"]              = "Offset Y",
    ["opt_np_raid_icon_size"]           = "Icon size",

    -- Castbar
    ["section_castbar"]                 = "Castbar",
    ["opt_np_show_castbar"]             = "Show castbar",
    ["opt_np_castbar_height"]           = "Castbar height",
    ["color_castbar"]                   = "Castbar (interruptible)",
    ["color_castbar_uninterruptible"]   = "Castbar (non-interruptible)",

    -- Auras
    ["section_auras"]                   = "Auras",
    ["opt_np_show_auras"]               = "Show auras",
    ["opt_np_aura_size"]                = "Icon size",
    ["opt_np_max_auras"]                = "Max count",
    ["opt_np_only_my_debuffs"]          = "Only my debuffs",

    -- Enemy Buffs
    ["section_enemy_buffs"]              = "Enemy Buffs",
    ["sublabel_enemy_buffs"]             = "— Enemy Buffs —",
    ["opt_enemy_buffs_enable"]           = "Show enemy buffs",
    ["opt_enemy_buffs_max"]              = "Max buffs",
    ["opt_enemy_buffs_size"]             = "Buff icon size",
    ["info_enemy_buffs"]                 = "Displays active buffs (Enrage, shields...) on hostile units. Icons appear top-right, stacking upward.",
    ["opt_np_show_enemy_buffs"]          = "Show enemy buffs",
    ["opt_np_enemy_buff_size"]           = "Buff icon size",
    ["opt_np_max_enemy_buffs"]           = "Max enemy buffs",
    ["opt_np_enemy_buff_y_offset"]       = "Enemy buff Y offset",

    -- Transparency
    ["section_transparency"]            = "Transparency",
    ["opt_np_selected_alpha"]           = "Selected alpha",
    ["opt_np_unselected_alpha"]         = "Unselected alpha",

    -- Stacking
    ["section_stacking"]                = "Stacking",
    ["opt_np_overlap"]                  = "Vertical overlap",
    ["opt_np_top_inset"]                = "Screen top limit",

    -- Colors
    ["section_colors"]                  = "Colors",
    ["color_hostile"]                   = "Hostile (Enemy)",
    ["color_neutral"]                   = "Neutral",
    ["color_friendly"]                  = "Friendly",
    ["color_tapped"]                    = "Tapped",
    ["color_focus"]                     = "Focus target",

    -- NPC Type Colors (Ellesmere-style)
    ["section_npc_type_colors"]         = "NPC Type Colors",
    ["color_caster"]                    = "Caster",
    ["color_miniboss"]                  = "Mini-boss (elite + higher level)",
    ["color_enemy_in_combat"]           = "Enemy (default)",
    ["info_np_darken_ooc"]              = "Out-of-combat enemies are automatically dimmed.",

    -- Classification colors
    ["section_classification_colors"]   = "Classification Colors",
    ["opt_np_use_classification"]       = "Colors by enemy type",
    ["color_boss"]                      = "Boss",
    ["color_elite"]                     = "Elite / Mini-boss",
    ["color_rare"]                      = "Rare",
    ["color_normal"]                    = "Normal",
    ["color_trivial"]                   = "Trivial",

    -- Tank mode
    ["section_tank_mode"]               = "Tank Mode",
    ["opt_np_tank_mode"]                = "Enable Tank Mode (threat coloring)",
    ["color_no_threat"]                 = "No threat",
    ["color_low_threat"]                = "Low threat",
    ["color_has_threat"]                = "Holding threat",
    ["color_dps_has_aggro"]             = "DPS/Healer has aggro",
    ["color_dps_near_aggro"]            = "DPS/Healer near aggro",

    -- NP health format
    ["np_fmt_percent"]                  = "Percentage (75%)",
    ["np_fmt_current"]                  = "Current (25.3K)",
    ["np_fmt_current_percent"]          = "Current + %",

    -- Reset
    ["btn_reset_nameplates"]            = "Reset Nameplates",

    -- =====================
    -- CONFIG: CD & Resource Panel
    -- =====================
    -- Resource colors
    ["section_resource_colors"]         = "Resource Colors",
    ["res_mana"]                        = "Mana",
    ["res_rage"]                        = "Rage",
    ["res_energy"]                      = "Energy",
    ["res_focus"]                       = "Focus",
    ["res_runic_power"]                 = "Runic Power",
    ["res_runes_ready"]                 = "Runes (ready)",
    ["res_runes_cd"]                    = "Runes (cooldown)",
    ["res_soul_shards"]                 = "Soul Shards",
    ["res_astral_power"]                = "Astral Power",
    ["res_holy_power"]                  = "Holy Power",
    ["res_maelstrom"]                   = "Maelstrom",
    ["res_chi"]                         = "Chi",
    ["res_insanity"]                    = "Insanity",
    ["res_fury"]                        = "Fury",
    ["res_combo_points"]                = "Combo Points",
    ["res_arcane_charges"]              = "Arcane Charges",
    ["res_essence"]                     = "Essence",
    ["res_stagger"]                     = "Stagger",
    ["res_soul_fragments"]              = "Soul Fragments",
    ["res_tip_of_spear"]                = "Tip of the Spear",
    ["res_maelstrom_weapon"]            = "Maelstrom Weapon",

    -- Cooldown Manager
    -- CD & Resource tabs
    ["tab_cdm"]                         = "Cooldowns",
    ["tab_resource_bars"]               = "Resource Bars",
    ["tab_text_position"]               = "Text & Position",
    ["tab_rb_colors"]                   = "Colors",
    ["info_rb_colors_custom"]           = "Each color can be customized to your preference by clicking the color swatch.",

    ["section_cdm"]                     = "Cooldown Manager",
    ["opt_cdm_enable"]                  = "Enable Cooldown Manager",
    ["info_cdm_description"]            = "Reskins Blizzard CooldownManager icons: rounded borders, class overlay on active auras, custom swipe colors, utility dimming, centered layout. Placement via Blizzard Edit Mode.",
    ["opt_cdm_show_hotkeys"]            = "Show hotkeys",
    ["opt_cdm_combat_alpha"]            = "Modify opacity (combat / target)",
    ["opt_cdm_alpha_combat"]            = "In-combat alpha",
    ["opt_cdm_alpha_target"]            = "With target alpha (out of combat)",
    ["opt_cdm_alpha_ooc"]               = "Out of combat alpha",
    ["section_cdm_overlay"]             = "Overlay & Borders",
    ["opt_cdm_custom_overlay"]          = "Use custom overlay color",
    ["opt_cdm_overlay_color"]           = "Overlay color",
    ["opt_cdm_custom_swipe"]            = "Custom active swipe color",
    ["opt_cdm_swipe_color"]             = "Swipe color",
    ["opt_cdm_swipe_alpha"]             = "Swipe opacity",
    ["section_cdm_utility"]             = "Utility",
    ["opt_cdm_dim_utility"]             = "Dim utility icons when off cooldown",
    ["opt_cdm_dim_opacity"]             = "Dim opacity",
    ["info_cdm_editmode"]               = "Placement is done via Blizzard Edit Mode (Esc → Edit Mode).",

    -- Resource Bars
    ["section_resource_bars"]           = "Resource Bars",
    ["opt_rb_enable"]                   = "Enable resource bars",
    ["info_rb_description"]             = "Displays class resources (Mana, Rage, Energy, Combo Points, Runes, etc.) with adaptive Druid support.",
    ["section_visibility"]              = "Visibility",
    ["opt_rb_visibility_mode"]          = "Visibility mode",
    ["vis_always"]                      = "Always visible",
    ["vis_combat"]                      = "Combat only",
    ["vis_target"]                      = "Combat or target",
    ["vis_hidden"]                      = "Hidden",
    ["opt_rb_combat_alpha"]             = "In-combat alpha",
    ["opt_rb_ooc_alpha"]                = "Out of combat alpha",
    ["opt_rb_width"]                    = "Width",
    ["opt_rb_primary_height"]           = "Primary bar height",
    ["opt_rb_secondary_height"]         = "Secondary bar height",
    ["opt_rb_global_scale"]             = "Global scale",
    ["opt_rb_sync_width"]               = "Sync width with Essential Cooldowns",
    ["btn_sync_now"]                    = "Sync now",
    ["info_rb_sync"]                    = "Aligns width with Blizzard CooldownManager's EssentialCooldownViewer.",

    -- Text & Font
    ["section_text_font"]               = "Text & Font",
    ["opt_rb_show_text"]                = "Show text on bars",
    ["opt_rb_text_align"]               = "Text alignment",
    ["align_left"]                      = "Left",
    ["align_center"]                    = "Center",
    ["align_right"]                     = "Right",
    ["opt_rb_font_size"]                = "Font size",
    ["opt_rb_font"]                     = "Font",
    ["font_default_wow"]                = "Default WoW",

    -- Position
    ["section_position"]                = "Position",
    ["info_rb_position"]                = "Use /tm uf to unlock and move bars. Position is saved automatically.",
    ["info_rb_druid"]                   = "Bars automatically adapt to your class and spec.\nDruid: resource changes with form (Bear → Rage, Cat → Energy, Moonkin → Astral Power).",

    -- =====================
    -- CONFIG: QOL Panel
    -- =====================
    -- Cinematic Skip
    -- QOL tabs
    ["tab_qol_cinematic"]               = "Cinematic",
    ["tab_qol_auto_quest"]              = "Auto Quest",
    ["tab_qol_automations"]             = "Automations",
    ["tab_qol_mythic_keys"]             = "M+ Keys",
    ["tab_qol_skyride"]                 = "SkyRide",
    ["tab_qol_action_bars"]             = "Action Bars",
    ["section_action_bars"]             = "Action Bar Skin",
    ["cat_action_bars"]                 = "Action Bars",
    ["opt_abs_enable"]                  = "Enable Action Bar Skin",
    ["opt_abs_class_color"]             = "Use class color for borders",
    ["opt_abs_shift_reveal"]            = "Hold Shift to reveal hidden bars",
    ["sublabel_bar_opacity"]            = "— Per-Bar Opacity —",
    ["opt_abs_select_bar"]              = "Select Action Bar",
    ["opt_abs_opacity"]                 = "Opacity",
    ["btn_abs_apply_all_opacity"]       = "Apply to all bars",
    ["msg_abs_all_opacity"]             = "Opacity set to %d%% on all bars",
    ["sublabel_bar_combat"]             = "— Combat Visibility —",
    ["opt_abs_combat_show"]             = "Show only in combat",

    ["section_cinematic"]               = "Cinematic Skip",
    ["opt_cinematic_auto_skip"]         = "Auto-skip after first viewing",
    ["info_cinematic_viewed"]           = "Cinematics already viewed: %s\nHistory is shared across characters.",
    ["btn_clear_history"]               = "Clear history",

    -- Auto Quest
    ["section_auto_quest"]              = "Auto Quest",
    ["opt_quest_auto_accept"]           = "Auto-accept quests",
    ["opt_quest_auto_turnin"]           = "Auto-complete quests",
    ["opt_quest_auto_gossip"]           = "Auto-select dialogue options",
    ["info_quest_shift"]                = "Hold SHIFT to temporarily disable.\nQuests with multiple rewards are not auto-completed.",

    -- Objective Tracker Skin
    ["tab_qol_obj_tracker"]             = "Tracker Skin",
    ["section_obj_tracker"]             = "Objective Tracker Skin",
    ["opt_obj_tracker_enable"]          = "Enable tracker skin",
    ["opt_obj_tracker_bg_alpha"]        = "Background opacity",
    ["opt_obj_tracker_border"]          = "Show border",
    ["opt_obj_tracker_hide_empty"]      = "Hide when empty",
    ["opt_obj_tracker_header_size"]     = "Header font size",
    ["opt_obj_tracker_cat_size"]        = "Category font size",
    ["opt_obj_tracker_quest_size"]      = "Quest title font size",
    ["opt_obj_tracker_obj_size"]        = "Objective font size",
    ["opt_obj_tracker_max_quests"]       = "Max quests displayed (0 = no limit)",
    ["ot_overflow_text"]                 = "%d more quest(s) hidden...",
    ["info_obj_tracker"]                = "Reskins the Blizzard Objective Tracker with a dark panel, custom fonts and colored category headers.",
    ["ot_header_title"]                 = "OBJECTIVES",
    ["ot_header_options"]               = "Options",

    -- Automatisations
    ["section_automations"]             = "Automations",
    ["opt_hide_blizzard_castbar"]       = "Hide Blizzard cast bar",

    -- Auto Accept Invite
    ["sublabel_auto_accept_invite"]     = "— Auto Accept Invite —",
    ["sublabel_auto_skip_role"]         = "— Auto Skip Role Check —",
    ["sublabel_tooltip_ids"]            = "— Tooltip IDs —",
    ["sublabel_combat_res_tracker"]     = "— Combat Res Tracker —",
    ["opt_cr_show_rating"]              = "Show M+ Rating",
    ["opt_show_messages"]               = "Show chat messages",
    ["opt_tid_spell"]                   = "Spell / Aura ID",
    ["opt_tid_item"]                    = "Item ID",
    ["opt_tid_npc"]                     = "NPC ID",
    ["opt_tid_quest"]                   = "Quest ID",
    ["opt_tid_mount"]                   = "Mount ID",
    ["opt_tid_currency"]                = "Currency ID",
    ["opt_tid_achievement"]             = "Achievement ID",
    ["opt_accept_friends"]              = "Accept from friends",
    ["opt_accept_guild"]                = "Accept from guild",

    -- Auto Summon
    ["sublabel_auto_summon"]            = "— Auto Summon —",
    ["opt_summon_delay"]                = "Delay (seconds)",

    -- Auto Fill Delete
    ["sublabel_auto_fill_delete"]       = "— Auto Fill Delete —",
    ["opt_focus_ok_button"]             = "Focus OK button after fill",

    -- Mythic+ Keys
    ["section_mythic_keys"]             = "Mythic+ Keys",
    ["opt_keys_enable_tracker"]         = "Enable tracker",
    ["opt_keys_mini_frame"]             = "Mini-frame on M+ UI",
    ["opt_keys_auto_refresh"]           = "Auto-refresh",

    -- SkyRide
    ["section_skyride"]                 = "SkyRide",
    ["opt_skyride_enable"]              = "Enable (in-flight display)",
    ["section_skyride_dims"]            = "Dimensions",
    ["opt_skyride_bar_height"]          = "Speed bar height",
    ["opt_skyride_charge_height"]       = "Charge bar height",
    ["opt_skyride_charge_gap"]          = "Gap between segments",
    ["section_skyride_text"]            = "Text",
    ["opt_skyride_show_speed_text"]     = "Show speed percentage",
    ["opt_skyride_speed_font_size"]     = "Speed text font size",
    ["opt_skyride_show_charge_timer"]   = "Show charge timer",
    ["opt_skyride_charge_font_size"]    = "Charge timer font size",
    ["btn_reset_skyride"]               = "Reset SkyRide Position",

    -- =====================
    -- CONFIG: QOL — CVar Optimizer
    -- =====================
    ["tab_qol_cvar_opt"]                = "Perf CVars",
    ["section_cvar_optimizer"]          = "CVar Optimizer",
    ["info_cvar_optimizer"]             = "Apply recommended graphic/performance settings. Your current values are saved and can be restored at any time.",
    ["btn_cvar_apply_all"]              = ">> Apply All",
    ["btn_cvar_revert_all"]             = "<< Revert All",
    ["btn_cvar_apply"]                  = "Apply",
    ["btn_cvar_revert"]                 = "Revert",
    -- Categories
    ["opt_cat_render"]                  = "Render & Display",
    ["opt_cat_graphics"]                = "Graphics Quality",
    ["opt_cat_detail"]                  = "View Distance & Detail",
    ["opt_cat_advanced"]                = "Advanced",
    ["opt_cat_fps"]                     = "FPS Limits",
    ["opt_cat_post"]                    = "Post Processing",
    -- CVar labels
    ["opt_cvar_render_scale"]           = "Render Scale",
    ["opt_cvar_vsync"]                  = "VSync",
    ["opt_cvar_msaa"]                   = "Multisampling (MSAA)",
    ["opt_cvar_low_latency"]            = "Low Latency Mode",
    ["opt_cvar_anti_aliasing"]          = "Anti-Aliasing",
    ["opt_cvar_shadow"]                 = "Shadow Quality",
    ["opt_cvar_ssao"]                   = "SSAO",
    ["opt_cvar_depth"]                  = "Depth Effects",
    ["opt_cvar_compute"]                = "Compute Effects",
    ["opt_cvar_particle"]               = "Particle Density",
    ["opt_cvar_liquid"]                 = "Liquid Detail",
    ["opt_cvar_spell_density"]          = "Spell Density",
    ["opt_cvar_projected"]              = "Projected Textures",
    ["opt_cvar_outline"]                = "Outline Mode",
    ["opt_cvar_texture_res"]            = "Texture Resolution",
    ["opt_cvar_view_distance"]          = "View Distance",
    ["opt_cvar_env_detail"]             = "Environment Detail",
    ["opt_cvar_ground"]                 = "Ground Clutter",
    ["opt_cvar_gfx_api"]                = "Graphics API",
    ["opt_cvar_triple_buffering"]       = "Triple Buffering",
    ["opt_cvar_texture_filtering"]      = "Texture Filtering",
    ["opt_cvar_rt_shadows"]             = "Ray Traced Shadows",
    ["opt_cvar_resample_quality"]       = "Resample Quality",
    ["opt_cvar_physics"]                = "Physics Level",
    ["opt_cvar_target_fps"]             = "Target FPS",
    ["opt_cvar_bg_fps_enable"]          = "Background FPS Limit",
    ["opt_cvar_bg_fps"]                 = "Background FPS Value",
    ["opt_cvar_resample_sharpness"]     = "Resample Sharpness",
    ["opt_cvar_camera_shake"]           = "Camera Shake",
    -- Messages
    ["msg_cvar_applied"]                = "CVars applied",
    ["msg_cvar_reverted"]               = "CVars restored",
    ["msg_cvar_no_backup"]              = "No backup found — apply first.",
    ["tab_qol_leveling"]                = "Leveling",
    ["section_leveling_bar"]            = "Leveling Bar",
    ["opt_leveling_enable"]             = "Enable Leveling Bar",
    ["opt_leveling_width"]              = "Bar width",
    ["opt_leveling_height"]             = "Bar height",
    ["btn_reset_leveling_pos"]          = "Reset Position",
    ["leveling_bar_title"]              = "Leveling Bar",
    ["leveling_level"]                  = "Level",
    ["leveling_progress"]               = "Progress:",
    ["leveling_rested"]                 = "Rested",
    ["leveling_last_quest"]             = "Last quest:",
    ["leveling_ttl"]                    = "Time to level:",
    ["leveling_drag_hint"]              = "/tm sr to unlock & drag",

    -- =====================
    -- CONFIG: Profiles Panel (3 Tabs)
    -- =====================
    -- Tab labels
    ["tab_profiles"]                    = "Profiles",
    ["tab_import_export"]               = "Import/Export",
    ["tab_resets"]                      = "Resets",

    -- Tab 1: Named profiles & specializations
    ["section_named_profiles"]          = "Profiles",
    ["info_named_profiles"]             = "Create and manage named profiles. Each profile saves a complete snapshot of your settings.",
    ["profile_active_label"]            = "Active profile",
    ["opt_select_profile"]              = "Choose a profile",
    ["sublabel_create_profile"]         = "— Create New Profile —",
    ["placeholder_profile_name"]        = "Profile name...",
    ["btn_create_profile"]              = "Create Profile",
    ["btn_delete_named_profile"]        = "Delete profile",
    ["btn_save_profile"]                = "Save Current Profile",
    ["info_save_profile"]               = "Saves all current settings to the active profile. This is done automatically when switching profiles.",

    ["section_profile_mode"]            = "Profile Mode",
    ["info_spec_profiles"]              = "Enable per-specialization profiles to automatically save and load settings when you switch specs.\nEach spec gets its own independent configuration.",
    ["opt_enable_spec_profiles"]        = "Enable per-specialization profiles",
    ["profile_status"]                  = "Active profile",
    ["profile_global"]                  = "Global (single profile)",
    ["section_spec_list"]               = "Specializations",
    ["profile_badge_active"]            = "Active",
    ["profile_badge_saved"]             = "Saved",
    ["profile_badge_none"]              = "No profile",
    ["btn_copy_to_spec"]                = "Copy current",
    ["btn_delete_profile"]              = "Delete",
    ["info_spec_reload"]                = "Switching spec with profiles enabled will automatically reload your UI to apply the corresponding profile.",
    ["info_global_mode"]                = "All specializations share the same settings. Enable per-spec profiles above to use different configs for each spec.",

    -- Tab 2: Import / Export
    ["section_export"]                  = "Export Settings",
    ["info_export"]                     = "Generate a compressed string of all your current settings.\nCopy it to share with others or as a backup.",
    ["label_export_string"]             = "Export string (click to select all)",
    ["btn_export"]                      = "Generate Export String",
    ["btn_copy_clipboard"]              = "📋 Copy Text",
    ["section_import"]                  = "Import Settings",
    ["info_import"]                     = "Paste an export string below. The string will be validated before applying.",
    ["label_import_string"]             = "Paste import string here",
    ["btn_import"]                      = "Import & Apply",
    ["btn_paste_clipboard"]             = "📋 Paste Text",
    ["import_preview"]                  = "Class: %s | Modules: %s | Date: %s",
    ["import_preview_valid"]            = "✓ Valid string",
    ["import_preview_invalid"]          = "Invalid or corrupted string",
    ["info_import_warning"]             = "Importing will OVERWRITE all your current settings and reload the UI. This cannot be undone.",

    -- Tab 3: Resets
    ["section_profile_mgmt"]            = "Profile Management",
    ["info_profiles"]                   = "Reset individual modules or export/import your settings.\nExport copies settings to clipboard (requires LibSerialize + LibDeflate).",
    ["section_reset_module"]            = "Reset a Module",
    ["btn_reset_prefix"]                = "Reset: ",
    ["btn_reset_all_reload"]            = "(!) RESET ALL + Reload",
    ["section_reset_all"]               = "Full Reset",
    ["info_resets"]                     = "Reset an individual module to its default values. The module will be reloaded with factory settings.",
    ["info_reset_all_warning"]          = "This will reset ALL modules and ALL settings back to factory defaults, then reload the UI.",

    -- =====================
    -- PRINT MESSAGES: Core
    -- =====================
    ["msg_db_reset"]                    = "Database reset",
    ["msg_module_reset"]                = "Module '%s' reset",
    ["msg_db_not_init"]                 = "Database not initialized",
    ["msg_loaded"]                      = "v2.0 loaded — %s for config",
    ["msg_help_title"]                  = "v2.0 — Commands:",
    ["msg_help_open"]                   = "Open config",
    ["msg_help_reset"]                  = "Reset all + reload",
    ["msg_help_uf"]                     = "Toggle Lock/Unlock UnitFrames + Resources",
    ["msg_help_uf_reset"]               = "Reset UnitFrames",
    ["msg_help_rb"]                     = "Toggle Lock/Unlock Resource Bars",
    ["msg_help_rb_sync"]                = "Sync width with Essential Cooldowns",
    ["msg_help_np"]                     = "Toggle Nameplates on/off",
    ["msg_help_minimap"]                = "Reset minimap",
    ["msg_help_panel"]                  = "Reset info panel",
    ["msg_help_cursor"]                 = "Reset cursor ring",
    ["msg_help_clearcinema"]            = "Clear cinematic history",
    ["msg_help_sr"]                     = "Toggle SkyRide + Anchors lock",
    ["msg_help_key"]                    = "Open Mythic+ Keys",
    ["msg_help_help"]                   = "This help",

    -- =====================
    -- PRINT MESSAGES: Modules
    -- =====================
    -- CDM
    ["msg_cdm_status"]                  = "Enabled",
    ["msg_cdm_disabled"]                = "Disabled",

    -- Nameplates
    ["msg_np_enabled"]                  = "Enabled",
    ["msg_np_disabled"]                 = "Disabled",

    -- UnitFrames
    ["msg_uf_locked"]                   = "Locked",
    ["msg_uf_unlocked"]                 = "Unlocked — Drag to reposition",
    ["msg_uf_initialized"]              = "Initialized — /tm uf to lock/unlock",
    ["msg_uf_enabled"]                  = "enabled (reload required)",
    ["msg_uf_disabled"]                 = "disabled (reload required)",
    ["msg_uf_position_reset"]           = "position reset",

    -- ResourceBars
    ["msg_rb_width_synced"]             = "Width synced (%dpx)",
    ["msg_rb_locked"]                   = "Locked",
    ["msg_rb_unlocked"]                 = "Unlocked — Drag to reposition",
    ["msg_rb_position_reset"]           = "Resource bars position reset",

    -- SkyRide
    ["msg_sr_pos_saved"]                = "SkyRide position saved",
    ["msg_sr_locked"]                   = "SkyRide locked",
    ["msg_sr_unlock"]                   = "SkyRide move mode enabled - Click and drag",
    ["msg_sr_pos_reset"]                = "SkyRide position reset",
    ["msg_sr_db_not_init"]              = "TomoModDB not initialized",
    ["msg_sr_initialized"]              = "SkyRide module initialized",

    -- FrameAnchors
    ["anchor_alert"]                    = "Alerts",
    ["anchor_loot"]                     = "Loot",
    ["msg_anchors_locked"]              = "Locked",
    ["msg_anchors_unlocked"]            = "Unlocked — move anchors",

    -- AutoVendorRepair
    ["msg_avr_header"]                  = "[AutoVendorRepair]",
    ["msg_avr_sold"]                    = " Sold gray items for |cffffff00%s|r",
    ["msg_avr_repaired"]                = " Repaired gear for |cffffff00%s|r",

    -- AutoFillDelete
    ["msg_afd_filled"]                  = "Text 'DELETE' auto-filled - Click OK to confirm",
    ["msg_afd_db_not_init"]             = "TomoModDB not initialized",
    ["msg_afd_initialized"]             = "AutoFillDelete module initialized",
    ["msg_afd_enabled"]                 = "Auto-fill DELETE enabled",
    ["msg_afd_disabled"]                = "Auto-fill DELETE disabled (hook remains active)",

    -- HideCastBar
    ["msg_hcb_db_not_init"]             = "TomoModDB not initialized",
    ["msg_hcb_initialized"]             = "HideCastBar module initialized",
    ["msg_hcb_hidden"]                  = "Cast bar hidden",
    ["msg_hcb_shown"]                   = "Cast bar shown",

    -- AutoAcceptInvite
    ["msg_aai_accepted"]                = "Invitation accepted from ",
    ["msg_aai_ignored"]                 = "Invitation ignored from ",
    ["msg_aai_enabled"]                 = "Auto-accept invitations enabled",
    ["msg_aai_disabled"]                = "Auto-accept invitations disabled",
    ["msg_asr_lfg_accepted"]            = "Role check auto-confirmed",
    ["msg_asr_poll_accepted"]           = "Role poll auto-confirmed",
    ["msg_asr_enabled"]                 = "Auto skip role check enabled",
    ["msg_asr_disabled"]                = "Auto skip role check disabled",
    ["msg_tid_enabled"]                 = "Tooltip IDs enabled",
    ["msg_tid_disabled"]                = "Tooltip IDs disabled",
    ["msg_cr_enabled"]                  = "Combat Res Tracker enabled",
    ["msg_cr_disabled"]                 = "Combat Res Tracker disabled",
    ["msg_cr_locked"]                   = "Combat Res Tracker locked",
    ["msg_cr_unlock"]                   = "Combat Res Tracker unlocked — drag to move",
    ["msg_abs_enabled"]                 = "Action Bar Skin enabled (reload for best results)",
    ["msg_abs_disabled"]                = "Action Bar Skin disabled",
    ["opt_buffskin_enable"]             = "Enable Buff Skin",
    ["opt_buffskin_desc"]               = "Adds black borders and colored duration timer on player buffs/debuffs",
    ["msg_buffskin_enabled"]            = "Buff Skin enabled",
    ["msg_buffskin_disabled"]           = "Buff Skin disabled",
    ["msg_help_cr"]                     = "Lock/unlock Combat Res Tracker",
    ["msg_help_cs"]                     = "Lock/unlock Character Sheet position",
    ["msg_help_cs_reset"]               = "Reset Character Sheet to default position",

    -- CinematicSkip
    ["msg_cin_skipped"]                 = "Cinematic skipped (already viewed)",
    ["msg_vid_skipped"]                 = "Video skipped (already viewed)",
    ["msg_vid_id_skipped"]              = "Video #%d skipped",
    ["msg_cin_cleared"]                 = "Cinematic history cleared",

    -- AutoSummon
    ["msg_sum_accepted"]                = "Summon accepted from %s to %s (%s)",
    ["msg_sum_ignored"]                 = "Summon ignored from %s (not trusted)",
    ["msg_sum_enabled"]                 = "Auto-summon enabled",
    ["msg_sum_disabled"]                = "Auto-summon disabled",
    ["msg_sum_manual"]                  = "Summon accepted manually",
    ["msg_sum_no_pending"]              = "No pending summon",

    -- MythicKeys
    ["msg_keys_no_key"]                 = "No key to send.",
    ["msg_keys_not_in_group"]           = "You must be in a group.",
    ["msg_keys_reload"]                 = "Change applied on next /reload.",
    ["mk_not_in_group"]                 = "You're not in a group.",
    ["mk_not_in_group_short"]           = "Not in group.",
    ["mk_no_key_self"]                  = "No keystone found.",
    ["mk_title"]                        = "TM — Mythic Keys",
    ["mk_btn_send"]                     = "Send to chat",
    ["mk_btn_refresh"]                  = "Refresh",
    ["mk_tab_keys"]                     = "Keys",
    ["mk_tab_tp"]                       = "TP",
    ["mk_tp_click_to_tp"]              = "Click to teleport",
    ["mk_tp_not_unlocked"]             = "Not unlocked",
    ["msg_tp_not_owned"]               = "You don't have the teleport for %s",
    ["msg_tp_combat"]                  = "Cannot update teleports during combat.",

    -- =====================
    -- PRINT MESSAGES: Config Panels
    -- =====================
    ["msg_np_reset"]                    = "Nameplates reset (reload recommended)",
    ["msg_uf_toggle"]                   = "UnitFrames %s (reload)",
    ["msg_profile_reset"]               = "%s reset",
    ["msg_profile_copied"]              = "Current settings copied to '%s'",
    ["msg_profile_deleted"]             = "Profile deleted for '%s'",
    ["msg_profile_loaded"]              = "Profile '%s' loaded — reload to apply",
    ["msg_profile_load_failed"]         = "Failed to load profile '%s'",
    ["msg_profile_created"]             = "Profile '%s' created with current settings",
    ["msg_profile_name_empty"]          = "Please enter a profile name",
    ["msg_profile_saved"]               = "Settings saved to profile '%s'",

    -- New profile keys v2.3.0
    ["btn_rename_profile"]              = "Rename",
    ["btn_duplicate_profile"]           = "Duplicate",
    ["btn_load_profile"]                = "Load",
    ["btn_close"]                       = "Close",
    ["btn_cancel"]                      = "Cancel",
    ["section_spec_assign"]             = "Per-Specialization Profiles",
    ["info_spec_assign"]                = "Assign each specialization to a named profile. TomoMod will automatically switch profiles when you change spec.",
    ["spec_profile_none"]               = "— None —",
    ["popup_rename_profile"]            = "|cff0cd29fTomoMod|r\n\nNew name for '%s':",
    ["popup_duplicate_profile"]         = "|cff0cd29fTomoMod|r\n\nDuplicate '%s' as:",
    ["msg_profile_renamed"]             = "Profile '%s' renamed to '%s'",
    ["msg_profile_duplicated"]          = "Profile '%s' duplicated as '%s'",
    ["msg_import_as_profile"]           = "Profile imported as '%s'",
    ["popup_export_title"]              = "Export Profile",
    ["popup_export_hint"]               = "Select all (Ctrl+A) and copy (Ctrl+C)",
    ["popup_import_title"]              = "Import Profile",
    ["popup_import_hint"]               = "Paste a TomoMod export string, then click Import",
    ["label_import_profile_name"]       = "Save as profile name:",
    ["placeholder_import_profile_name"] = "Profile name (optional)...",
    ["msg_profile_name_deleted"]        = "Profile '%s' deleted",
    ["msg_export_success"]              = "Export string generated — select all and copy",
    ["msg_import_success"]              = "Settings imported successfully — reloading...",
    ["msg_import_empty"]                = "Nothing to import — paste a string first",
    ["msg_copy_hint"]                   = "Text selected — press Ctrl+C to copy",
    ["msg_copy_empty"]                  = "Generate an export string first",
    ["msg_paste_hint"]                  = "Press Ctrl+V to paste your import string",
    ["msg_spec_changed_reload"]         = "Specialization changed — reloading profile...",

    -- =====================
    -- INFO PANEL (Minimap)
    -- =====================
    ["time_server"]                     = "Server",
    ["time_local"]                      = "Local",
    ["time_tooltip_title"]              = "Time (%s - %s)",
    ["time_tooltip_left_click"]         = "|cff0cd29fLeft-click:|r Calendar",
    ["time_tooltip_right_click"]        = "|cff0cd29fRight-click:|r Server / Local",
    ["time_tooltip_shift_right"]        = "|cff0cd29fShift + Right-click:|r 12h / 24h",
    ["time_format_msg"]                 = "Format: %s",
    ["time_mode_msg"]                   = "Time: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Enabled",
    ["disabled"]                        = "Disabled",

    -- Static Popups
    ["popup_reset_text"]                = "|cff0cd29fTomoMod|r\n\nReset ALL settings?\nThis will reload your UI.",
    ["popup_confirm"]                   = "Confirm",
    ["popup_cancel"]                    = "Cancel",
    ["popup_import_text"]               = "|cff0cd29fTomoMod|r\n\nImport settings?\nThis will OVERWRITE all your current settings and reload the UI.",
    ["popup_profile_reload"]            = "|cff0cd29fTomoMod|r\n\nProfile mode changed.\nReload UI to apply?",
    ["popup_delete_profile"]            = "|cff0cd29fTomoMod|r\n\nDelete profile '%s'?\nThis cannot be undone.",

    -- FPS element
    ["label_fps"]                       = "Fps",

    -- =====================
    -- BOSS FRAMES
    -- =====================
    ["tab_boss"]                        = "Boss",
    ["section_boss_frames"]             = "Boss Frames",
    ["opt_boss_enable"]                 = "Enable Boss Frames",
    ["opt_boss_height"]                 = "Bar Height",
    ["opt_boss_spacing"]                = "Spacing Between Bars",
    ["info_boss_drag"]                  = "Unlock frames (/tm uf) to move. Drag Boss 1 to reposition all 5 bars together.",
    ["info_boss_colors"]                = "Bar colors use Nameplate classification colors (Boss = red, Mini-boss = purple).",
    ["msg_boss_initialized"]            = "Boss frames loaded.",

    -- =====================
    -- SOUND / LUST DETECTION
    -- =====================
    ["cat_sound"]                       = "Son",
    ["section_sound_general"]           = "Son de Bloodlust",
    ["info_sound_desc"]                 = "Joue un son personnalisé quand un effet de type Bloodlust est détecté sur votre personnage. La détection vérifie directement les buffs de Lust et les debuffs Sated/Exhaustion.",
    ["opt_sound_enable"]                = "Activer la détection de Bloodlust",
    ["sublabel_sound_choice"]           = "Son & Canal",
    ["opt_sound_file"]                  = "Son à jouer",
    ["opt_sound_channel"]               = "Canal audio",
    ["btn_sound_preview"]               = ">> Ecouter le son",
    ["btn_sound_stop"]                  = "■  Arrêter",
    ["opt_sound_chat"]                  = "Afficher les messages en chat",
    ["opt_sound_debug"]                 = "Mode debug",

    -- =====================
    -- BAG & MICRO MENU
    -- =====================
    ["tab_qol_bag_micro"]               = "Bag & Menu",
    ["section_bag_micro"]               = "Bag Bar & Micro Menu",
    ["info_bag_micro"]                  = "Choose whether to always show or reveal on mouse hover.",
    ["sublabel_bag_bar"]                = "— Bag Bar —",
    ["sublabel_micro_menu"]             = "— Micro Menu —",
    ["opt_bag_bar_mode"]                = "Bag Bar",
    ["opt_micro_menu_mode"]             = "Micro Menu",
    ["mode_show"]                       = "Always visible",
    ["mode_hover"]                      = "Show on hover",

    -- =====================
    -- CHARACTER SKIN
    -- =====================
    ["tab_qol_char_skin"]               = "Character Skin",
    ["section_char_skin"]               = "Character Sheet Skin",
    ["info_char_skin_desc"]             = "Reskins the Character Frame, Reputation, Currency and Inspect windows to match the TomoMod dark theme.",
    ["opt_char_skin_enable"]            = "Enable Character Skin",
    ["opt_char_skin_character"]         = "Skin Character / Reputation / Currency",
    ["opt_char_skin_inspect"]           = "Skin Inspect Frame",
    ["opt_char_skin_iteminfo"]          = "Show Item Info on Slots",
    ["opt_char_skin_gems"]              = "Show Gem Sockets on Slots",
    ["opt_char_skin_midnight"]          = "Midnight Enchant Slots (Head/Shoulder instead of Wrist/Back)",
    ["opt_char_skin_scale"]             = "Window Scale",
    ["msg_char_skin_reload"]            = "Character Skin: /reload to apply changes.",

    -- =====================
    -- LAYOUT / MOVERS SYSTEM
    -- =====================
    ["btn_layout"]                      = "Layout",
    ["btn_layout_tooltip"]              = "Layout Mode: unlock all UI elements to drag & reposition them.",
    ["btn_reload_ui"]                   = "Reload UI",
    ["layout_mode_title"]               = "TomoMod — Layout Mode",
    ["layout_mode_hint"]                = "Drag elements to reposition — click Lock when done",
    ["layout_btn_lock"]                 = "Lock",
    ["layout_btn_reload"]               = "RL",
    ["grid_dimmed"]                    = "Grid",
    ["grid_bright"]                    = "Grid +",
    ["grid_disabled"]                  = "Grid OFF",
    ["layout_unlocked"]                 = "Layout Mode ON — drag elements to reposition. Click Lock or /tm layout when done.",
    ["layout_locked"]                   = "Layout Mode OFF — positions saved.",
    ["msg_help_layout"]                 = "Toggle Layout Mode (move all UI elements)",
    ["mover_unitframes"]                = "Unit Frames",
    ["mover_resources"]                 = "Resource Bars",
    ["mover_skyriding"]                 = "Skyriding Bar",
    ["mover_levelingbar"]               = "XP / Leveling Bar",
    ["mover_anchors"]                   = "Alert & Loot Anchors",
    ["mover_cotank"]                    = "CoTank Tracker",
    ["mover_repbar"]                    = "Reputation Bar",
    ["mover_castbar"]                   = "Player Castbar",
    ["mover_mythictracker"]             = "M+ Tracker",
    -- =====================
    -- COMBAT TEXT
    -- =====================
    ["sublabel_combat_text"]             = "— Combat Text —",
    ["opt_combat_text_enable"]           = "Enable combat text",
    ["opt_combat_text_offset_x"]         = "Offset X",
    ["opt_combat_text_offset_y"]         = "Offset Y",

    -- =====================
    -- SKINS (Chat)
    -- =====================
    ["tab_qol_skins"]                    = "Skins",
    ["section_skins"]                    = "UI Skins",
    ["info_skins_desc"]                  = "Apply the TomoMod dark theme to various Blizzard UI elements. Reload may be needed to fully revert.",
    ["sublabel_chat_skin"]               = "— Chat Frame —",
    ["opt_chat_skin_enable"]             = "Skin Chat Frame",
    ["opt_chat_skin_bg_alpha"]           = "Background opacity",
    ["opt_chat_skin_font_size"]          = "Chat font size",

    -- Buff Skin
    ["sublabel_buff_skin"]               = "— Buff / Debuff Skin —",
    ["opt_buff_skin_enable"]             = "Skin Buff/Debuff Icons",
    ["opt_buff_skin_buffs"]              = "Apply to Buffs",
    ["opt_buff_skin_debuffs"]            = "Apply to Debuffs",
    ["opt_buff_skin_glow"]               = "Buff glow effect",
    ["opt_buff_skin_hide_buffs"]         = "Hide Buff Frame",
    ["opt_buff_skin_hide_debuffs"]       = "Hide Debuff Frame",
    ["opt_buff_skin_font_size"]          = "Timer font size",

    -- Game Menu Skin
    ["sublabel_game_menu_skin"]          = "— Game Menu (Escape) —",
    ["opt_game_menu_skin_enable"]        = "Skin Game Menu",
    ["info_game_menu_skin_reload"]       = "Reload UI to fully revert this skin.",
    ["msg_chat_skin_enabled"]            = "Chat Frame Skin enabled",
    ["msg_chat_skin_disabled"]           = "Chat Frame Skin disabled (reload to revert)",
    ["sublabel_mail_skin"]               = "— Mail Frame —",
    ["opt_mail_skin_enable"]             = "Skin Mail Frame",
    ["msg_mail_skin_enabled"]            = "Mail Skin enabled",
    ["msg_mail_skin_disabled"]           = "Mail Skin disabled (reload to revert)",

    -- =====================
    -- WORLD QUEST TAB
    -- =====================
    ["tab_qol_world_quests"]             = "World Quests",
    ["section_wq_tab"]                   = "World Quest Tab",
    ["info_wq_tab_desc"]                 = "Displays a list of available World Quests beside the World Map with details on rewards, zone, faction, and time remaining. Click a quest to navigate to its zone, Shift-Click to super-track.",
    ["opt_wq_enable"]                    = "Enable World Quest Tab",
    ["opt_wq_auto_show"]                 = "Auto-show when opening the map",
    ["opt_wq_max_quests"]                = "Max quests shown (0 = unlimited)",
    ["opt_wq_min_time"]                  = "Min. time remaining (minutes, 0 = all)",
    ["section_wq_filters"]               = "Reward Filters",
    ["opt_wq_filter_gold"]               = "Show Gold rewards",
    ["opt_wq_filter_gear"]               = "Show Gear rewards",
    ["opt_wq_filter_rep"]                = "Show Reputation rewards",
    ["opt_wq_filter_currency"]           = "Show Currency rewards",
    ["opt_wq_filter_anima"]              = "Show Anima rewards",
    ["opt_wq_filter_pet"]                = "Show Pet rewards",
    ["opt_wq_filter_other"]              = "Show Other rewards",
    ["wq_tab_title"]                     = "WQ List",
    ["wq_panel_title"]                   = "World Quests",
    ["wq_col_name"]                      = "Name",
    ["wq_col_zone"]                      = "Zone",
    ["wq_col_reward"]                    = "Reward",
    ["wq_col_time"]                      = "Time",
    ["wq_zone"]                          = "Zone",
    ["wq_faction"]                       = "Faction",
    ["wq_reward"]                        = "Reward",
    ["wq_time_left"]                     = "Time left",
    ["wq_elite"]                         = "Elite World Quest",
    ["wq_sort_time"]                     = "Time",
    ["wq_sort_zone"]                     = "Zone",
    ["wq_sort_name"]                     = "Name",
    ["wq_sort_reward"]                   = "Reward",
    ["wq_sort_faction"]                  = "Faction",
    ["wq_status_count"]                  = "Showing %d / %d quests",

    -- =====================
    -- PROFESSION HELPER
    -- =====================
    ["tab_qol_prof_helper"]              = "Professions",
    ["section_prof_helper"]              = "Profession Helper",
    ["info_prof_helper_desc"]            = "Batch Disenchant, Mill, and Prospect items from your bags. Open the helper window to select items and process them in bulk.",
    ["opt_prof_helper_enable"]           = "Enable Profession Helper",
    ["sublabel_prof_de_filters"]         = "— Disenchant Quality Filters —",
    ["opt_prof_filter_green"]            = "Include Uncommon (Green) items",
    ["opt_prof_filter_blue"]             = "Include Rare (Blue) items",
    ["opt_prof_filter_epic"]             = "Include Epic (Purple) items",
    ["btn_prof_open_helper"]             = "Open Profession Helper",
    ["ph_title"]                         = "Profession Helper",
    ["ph_tab_disenchant"]                = "Disenchant",
    ["ph_filter_quality"]                = "Quality:",
    ["ph_quality_green"]                 = "Green",
    ["ph_quality_blue"]                  = "Blue",
    ["ph_quality_epic"]                  = "Epic",
    ["ph_select_all"]                    = "Select All",
    ["ph_deselect_all"]                  = "Deselect All",
    ["ph_btn_process"]                   = "Process Selected",
    ["ph_btn_click_process"]              = "Click to Process",
    ["ph_btn_stop"]                      = "Stop",
    ["ph_status_idle"]                   = "Select items and click Process",
    ["ph_status_processing"]             = "Processing %d/%d: %s",
    ["ph_status_done"]                   = "Done! All items processed.",
    ["ph_item_count"]                    = "%d items available",
    ["ph_ilvl"]                          = "iLvl %d",

    -- =====================
    -- CLASS REMINDER
    -- =====================
    ["tab_qol_class_reminder"]            = "Class Reminder",
    ["section_class_reminder"]            = "Class Buff / Form Reminder",
    ["info_class_reminder"]               = "Displays a pulsing text warning when you are missing your class buff, form, stance, or aura.",
    ["opt_class_reminder_enable"]         = "Enable Class Reminder",
    ["opt_class_reminder_scale"]          = "Text Scale",
    ["opt_class_reminder_color"]          = "Text Color",
    ["sublabel_class_reminder_pos"]       = "— Position Offset —",
    ["opt_class_reminder_x"]             = "Offset X",
    ["opt_class_reminder_y"]             = "Offset Y",

    -- Class Reminder: buff/form names
    ["cr_fortitude"]                     = "Power Word: Fortitude",
    ["cr_shadowform"]                    = "Shadowform",
    ["cr_arcane_intellect"]              = "Arcane Intellect",
    ["cr_skyfury"]                       = "Skyfury",
    ["cr_mark_of_the_wild"]              = "Mark of the Wild",
    ["cr_cat_form"]                      = "Cat Form",
    ["cr_bear_form"]                     = "Bear Form",
    ["cr_moonkin_form"]                  = "Moonkin Form",
    ["cr_battle_shout"]                  = "Battle Shout",
    ["cr_stance"]                        = "Stance",
    ["cr_aura"]                          = "Aura",
    ["cr_blessing_bronze"]               = "Blessing of the Bronze",

    -- =====================
    -- MYTHIC TRACKER (TomoMythic integration)
    -- =====================
    ["tmt_cmd_usage"]               = "|cFF55B400/tmt|r : config  |  |cFF55B400unlock|r : drag  |  |cFF55B400lock|r : lock  |  |cFF55B400preview|r : preview  |  |cFF55B400key|r : party keys  |  |cFF55B400kr|r : roulette",
    ["tmt_unlock_msg"]              = "|cff0cd29fTomoMod|r M+ Tracker: Frame unlocked \226\128\148 drag to reposition.",
    ["tmt_lock_msg"]                = "|cff0cd29fTomoMod|r M+ Tracker: Frame locked.",
    ["tmt_reset_msg"]               = "|cff0cd29fTomoMod|r M+ Tracker: Position reset.",
    ["tmt_unknown_cmd"]             = "|cff0cd29fTomoMod|r M+ Tracker: Unknown command.",
    ["tmt_key_level"]               = "+%d",
    ["tmt_dungeon_unknown"]         = "Mythic+",
    ["tmt_overtime"]                = "OVERTIME",
    ["tmt_completed_on_time"]       = "COMPLETED",
    ["tmt_completed_depleted"]      = "DEPLETED",
    ["tmt_forces"]                  = "FORCES",
    ["tmt_forces_done"]             = "COMPLETE",
    ["tmt_forces_pct"]              = "%.1f%%",
    ["tmt_forces_count"]            = "%d / %d",
    ["tmt_cfg_title"]               = "Mythic",
    ["tmt_cfg_panel_enable"]         = "Enable M+ Tracker",
    ["tmt_cfg_show_timer"]          = "Show Timer Bar",
    ["tmt_cfg_show_forces"]         = "Show Enemy Forces",
    ["tmt_cfg_show_bosses"]         = "Show Boss Timers",
    ["tmt_cfg_hide_blizzard"]       = "Hide Blizzard Tracker",
    ["tmt_cfg_lock"]                = "Lock Frame",
    ["tmt_cfg_scale"]               = "Scale",
    ["tmt_cfg_alpha"]               = "Background Opacity",
    ["tmt_cfg_reset_pos"]           = "Reset Position",
    ["tmt_cfg_preview"]             = "Preview",
    ["tmt_cfg_section_display"]     = "Display",
    ["tmt_cfg_section_frame"]       = "Frame",
    ["tmt_cfg_section_actions"]     = "Actions",
    ["tmt_key_not_available"]       = "not available.",
    ["tmt_key_not_in_group"]        = "You are not in a group.",
    ["tmt_key_none_found"]          = "No keystones found.",
    ["tmt_kr_spin"]                 = "|TInterface\\Icons\\INV_Misc_Dice_02:14|t  Spin!",
    ["tmt_preview_active"]          = "|cff0cd29fTomoMod|r M+ Tracker: Preview active \226\128\148 |cFF55B400/tmt lock|r to lock.",

    -- =====================
    -- TOMOSCORE (Scoreboard)
    -- =====================
    ["ts_cfg_title"]                = "Scoreboard",
    ["ts_cfg_enable"]               = "Enable Dungeon Scoreboard",
    ["ts_cfg_auto_show_mplus"]      = "Auto-show for Mythic+",
    ["ts_cfg_scale"]                = "Scale",
    ["ts_cfg_alpha"]                = "Background Opacity",
    ["ts_cfg_section_display"]      = "Display",
    ["ts_cfg_section_frame"]        = "Frame",
    ["ts_cfg_section_actions"]      = "Actions",
    ["ts_cfg_preview"]              = "Preview",
    ["ts_cfg_last_run"]             = "Show Last Run",
    ["ts_cfg_reset_pos"]            = "Reset Position",
    ["ts_reset_msg"]                = "|cff0cd29fTomoMod|r Scoreboard: Position reset.",
    ["ts_no_data"]                  = "|cff0cd29fTomoMod|r Scoreboard: No dungeon data available.",
    ["ts_mythic_zero"]              = "Mythic",
    ["ts_key_level"]                = "+%d",
    ["ts_completed"]                = "COMPLETED",
    ["ts_depleted"]                 = "DEPLETED",
    ["ts_duration"]                 = "Duration",
    ["ts_col_player"]               = "Player",
    ["ts_col_rating"]               = "M+",
    ["ts_col_damage"]               = "Damage",
    ["ts_col_healing"]              = "Healing",
    ["ts_col_interrupts"]           = "Interrupts",
    ["ts_footer_total"]             = "Total",
    ["ts_footer_players"]           = "%d players",

    -- =====================
    -- MYTHIC HUB (M+ Overview Panel)
    -- =====================
    ["mhub_title"]                  = "Mythic+ Rating",
    ["mhub_col_dungeon"]            = "Dungeon",
    ["mhub_col_level"]              = "Level",
    ["mhub_col_rating"]             = "Rating",
    ["mhub_col_best"]               = "Best",
    ["mhub_tp_click"]               = "Click to teleport",
    ["mhub_tp_not_available"]        = "Teleport not learned",
    ["mhub_tp_not_learned"]          = "|cff0cd29fTomoMod|r: Teleport spell not learned.",
    ["mhub_vault_title"]            = "Great Vault",
    ["mhub_vault_dungeons"]         = "Dungeons",
    ["mhub_vault_raids"]            = "Raids",
    ["mhub_vault_world"]            = "Delves",
    ["mhub_vault_ilvl"]             = "Item Level",
    ["mhub_vault_locked"]           = "Locked",
    ["mhub_vault_claim"]            = "Return to the Great Vault to Claim your Reward",
})