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
    ["about_text"]                      = "|cff0cd29fTomoMod|r %s by TomoAniki\nLightweight interface with QOL, UnitFrames and Nameplates.\nType /tm help for the command list.",
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
    -- Resource colors (class powers only — primary power in UF info bar)
    ["section_resource_colors"]         = "Class Power Colors",
    ["res_mana"]                        = "Mana (Druid)",
    ["res_runes_ready"]                 = "Runes (ready)",
    ["res_runes_cd"]                    = "Runes (cooldown)",
    ["res_soul_shards"]                 = "Soul Shards",
    ["res_holy_power"]                  = "Holy Power",
    ["res_chi"]                         = "Chi",
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
    ["info_cdm_editmode"]               = "Placement is done via Blizzard Edit Mode (Esc |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Edit Mode).",

    -- CDM V3: CD Swipe
    ["opt_cdm_custom_cd_swipe"]          = "Custom CD swipe color",
    ["opt_cdm_cd_swipe_color"]           = "CD swipe color",
    ["opt_cdm_cd_swipe_alpha"]           = "CD swipe opacity",

    -- CDM V3: Advanced
    ["section_cdm_advanced"]             = "Advanced",
    ["opt_cdm_hide_gcd"]                 = "Hide GCD",
    ["opt_cdm_desaturate"]               = "Desaturate on CD",
    ["opt_cdm_buff_alignment"]           = "Buff alignment",
    ["align_center_outward"]             = "Center → Outward",
    ["align_start"]                      = "Start (left)",
    ["align_end"]                        = "End (right)",

    -- CDM V3: Visibility Rules
    ["section_cdm_visibility"]           = "Visibility Rules",
    ["info_cdm_visibility"]              = "Priority hiding rules. 'Show' conditions override 'Hide' conditions.",
    ["opt_cdm_hide_mounted"]             = "Hide when mounted",
    ["opt_cdm_hide_vehicle"]             = "Hide in vehicle",
    ["opt_cdm_hide_ooc"]                 = "Hide out of combat (no target)",
    ["opt_cdm_show_combat"]              = "Always show in combat",
    ["opt_cdm_show_instance"]            = "Always show in instance",
    ["opt_cdm_show_enemy"]               = "Show with enemy target",

    -- CDM V3.1: Sound / Pandemic / Range
    ["section_cdm_extras"]               = "Sound / Pandemic / Range",
    ["opt_cdm_sound_alert"]              = "Sound when spell is ready",
    ["opt_cdm_sound_file"]               = "Sound file",
    ["opt_cdm_pandemic"]                 = "Pandemic (refresh border)",
    ["opt_cdm_pandemic_threshold"]       = "Pandemic threshold (%)",
    ["opt_cdm_range_check"]              = "Tint red when out of range",

    -- Resource Bars
    ["section_resource_bars"]           = "Class Powers",
    ["opt_rb_enable"]                   = "Enable class power display",
    ["opt_rb_display_mode"]             = "Display mode",
    ["display_mode_icons"]              = "Icons (TUI textures)",
    ["display_mode_bars"]               = "Bars (flat colors)",
    ["info_rb_description"]             = "Shows class-specific resources (Combo Points, Runes, Soul Shards, Holy Power, etc.). Primary power (Mana, Rage, Energy...) is now in the UnitFrame info bar.",
    ["section_visibility"]              = "Visibility",
    ["opt_rb_visibility_mode"]          = "Visibility mode",
    ["vis_always"]                      = "Always visible",
    ["vis_combat"]                      = "Combat only",
    ["vis_target"]                      = "Combat or target",
    ["vis_hidden"]                      = "Hidden",
    ["opt_rb_combat_alpha"]             = "In-combat alpha",
    ["opt_rb_ooc_alpha"]                = "Out of combat alpha",
    ["opt_rb_width"]                    = "Width",
    ["opt_rb_classpower_height"]        = "Class power height",
    ["opt_rb_druidmana_height"]         = "Druid mana height",
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
    ["info_rb_druid"]                   = "Bars automatically adapt to your class and spec.\nDruid: resource changes with form (Bear |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Rage, Cat |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Energy, Moonkin |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Astral Power).",

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
    ["import_preview_valid"]            = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t Valid string",
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
    ["msg_report_issue"]                = "If you encounter any issue, please leave a comment on CurseForge.",
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
    ["opt_sound_force"]                 = "Forcer le son même si le jeu est muet",
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
    ["mover_minimap"]                   = "Minimap & Panel",
    ["mover_chatframe"]                 = "Chat Frame",
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
    ["opt_chat_skin_style"]              = "Skin Style",
    ["opt_chat_skin_style_tui"]          = "TUI (Sidebar + Window)",
    ["opt_chat_skin_style_classic"]      = "Classic (Framed)",
    ["opt_chat_skin_style_glass"]        = "Glass (Frosted)",
    ["opt_chat_skin_style_minimal"]      = "Minimal (Borderless)",
    ["opt_chat_skin_bg_alpha"]           = "Background opacity",
    ["opt_chat_skin_font_size"]          = "Chat font size",
    ["opt_chat_skin_fade"]               = "Fade chat when inactive",
    ["opt_chat_skin_short_channels"]     = "Short channel names (G, P, R…)",
    ["opt_chat_skin_timestamp"]          = "Show timestamps",
    ["opt_chat_skin_url"]                = "Clickable URLs",
    ["opt_chat_skin_emoji"]              = "Replace text emoticons with emoji",
    ["opt_chat_skin_class_colors"]       = "Class-color player names in chat",
    ["opt_chat_skin_history"]            = "Restore chat history on login",
    ["opt_chat_skin_copy_lines"]         = "Show copy icon per message",

    -- Buff Skin
    ["sublabel_buff_skin"]               = "— Buff / Debuff Skin —",
    ["opt_buff_skin_enable"]             = "Skin Buff/Debuff Icons",
    ["opt_buff_skin_buffs"]              = "Apply to Buffs",
    ["opt_buff_skin_debuffs"]            = "Apply to Debuffs",
    ["opt_buff_skin_color_by_type"]       = "Color border by debuff type (Magic/Poison/Curse…)",
    ["opt_buff_skin_teal_border"]         = "Teal border on buffs",
    ["opt_buff_skin_desaturate"]          = "Desaturate debuff icons",
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
    ["tmt_preview_active"]          = "|cff0cd29fTomoMod|r M+ Tracker: Preview mode active.",
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
    ["ts_col_key_level"]            = "Key",
    ["ts_col_key_name"]             = "Dungeon",
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

    -- =====================
    -- INSTALLER
    -- =====================
    ["ins_header_title"]             = "|cff0cd29fTomo|r|cffe4e4e4Mod|r  —  Setup Wizard",
    ["ins_step_counter"]             = "Step %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Previous",
    ["ins_btn_next"]                 = "Next |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Finish |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Skip installation",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Welcome to TomoMod",
    ["ins_subtitle"]                 = "Interface & QOL suite for The War Within",
    ["ins_welcome_desc"]             = "This wizard will guide you through |cff0cd29f12 steps|r to configure TomoMod to\nyour preferences: profile, skins, nameplates, action bars, sound, Mythic+,\noptimizations, QOL and SkyRide.\n\nAll these options can be changed anytime via |cff0cd29f/tm|r.",

    -- Step 2: Profile
    ["ins_step2_title"]              = "Game Profile",
    ["ins_profile_info"]             = "Create a named profile to save your configuration.",
    ["ins_profile_section"]          = "Profile Name",
    ["ins_profile_placeholder"]      = "My profile",
    ["ins_profile_create"]           = "Create Profile",
    ["ins_profile_created"]          = "Profile created: ",
    ["ins_spec_section"]             = "Specialization Assignment",
    ["ins_spec_info"]                = "You can assign this profile to your specs from the Profiles panel (/tm).\nEach spec can use a different configuration.",

    -- Step 3: Visual Skins
    ["ins_step3_title"]              = "Visual Skins",
    ["ins_skins_info"]               = "Customize the Blizzard UI with TomoMod's dark theme.",
    ["ins_skins_section"]            = "Available Skins",
    ["ins_skin_gamemenu"]            = "Game Menu skin (Escape menu)",
    ["ins_skin_actionbar"]           = "Action bar button skin",
    ["ins_skin_buffs"]               = "Buff / debuff skin",
    ["ins_skin_chat"]                = "Chat frame skin",
    ["ins_skin_character"]           = "Character sheet skin",
    ["ins_skin_style_section"]       = "Action Bar Button Style",
    ["ins_skin_style"]               = "Visual style",

    -- Step 4: Tank Mode
    ["ins_step4_title"]              = "Tank Mode",
    ["ins_tank_info"]                = "In tank mode, nameplates and UnitFrames display\nthreat status by color for each enemy.",
    ["ins_tank_np_section"]          = "Nameplates — Threat Colors",
    ["ins_tank_enable_np"]           = "Enable tank mode (nameplates)",
    ["ins_tank_colors_info"]         = "Green = you have aggro  ·  Orange = close to losing  ·  Red = aggro lost",
    ["ins_tank_uf_section"]          = "UnitFrames — Threat Indicator",
    ["ins_tank_threat_indicator"]    = "Show threat indicator on target",
    ["ins_tank_threat_text"]         = "Show threat % text on target",
    ["ins_tank_cotank_section"]      = "CoTank Tracker",
    ["ins_tank_cotank_enable"]       = "Enable co-tank tracking",
    ["ins_tank_cotank_info"]         = "Displays the second tank's threat in instances.",

    -- Step 5: Nameplates
    ["ins_step5_title"]              = "Nameplates",
    ["ins_np_general"]               = "General",
    ["ins_np_enable"]                = "Enable TomoMod nameplates",
    ["ins_np_reload_info"]           = "A reload is required to enable/disable nameplates.",
    ["ins_np_display"]               = "Display",
    ["ins_np_class_colors"]          = "Class colors",
    ["ins_np_castbar"]               = "Show castbar",
    ["ins_np_health_text"]           = "Show health text (percentage)",
    ["ins_np_auras"]                 = "Show auras (debuffs)",
    ["ins_np_role_icons"]            = "Show role icons (dungeon)",
    ["ins_np_dimensions"]            = "Dimensions",
    ["ins_np_width"]                 = "Width",

    -- Step 6: Action Bars
    ["ins_step6_title"]              = "Action Bars",
    ["ins_ab_skin_section"]          = "Button Skin",
    ["ins_ab_enable"]                = "Enable skin on action buttons",
    ["ins_ab_class_color"]           = "Border color = class color",
    ["ins_ab_shift_reveal"]          = "Hold Shift to reveal hidden bars",
    ["ins_ab_opacity_section"]       = "Global Bar Opacity",
    ["ins_ab_opacity"]               = "Opacity",
    ["ins_ab_manage_section"]        = "Bar Management",
    ["ins_ab_manage_info"]           = "Use the Action Bars panel (/tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Action Bars |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Management)\nto unlock and reposition each bar independently.",

    -- Step 7: LustSound
    ["ins_step7_title"]              = "Sound — Heroism / Bloodlust",
    ["ins_sound_info"]               = "Play a custom sound when Heroism or Bloodlust is cast\nby any group member.",
    ["ins_sound_activation"]         = "Activation",
    ["ins_sound_enable"]             = "Enable lust sound",
    ["ins_sound_choice"]             = "Sound Selection",
    ["ins_sound_sound"]              = "Sound",
    ["ins_sound_channel"]            = "Audio Channel",
    ["ins_sound_default"]            = "Default",
    ["ins_sound_preview_section"]    = "Preview",
    ["ins_sound_preview_btn"]        = "|TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t Preview",

    -- Step 8: Mythic+
    ["ins_step8_title"]              = "Mythic+ — Tracker & Scoreboard",
    ["ins_mplus_tracker_section"]    = "M+ Tracker",
    ["ins_mplus_tracker_info"]       = "Displays a timer, forces, bosses and progress\nof your Mythic+ dungeon in real-time.",
    ["ins_mplus_tracker_enable"]     = "Enable M+ Tracker",
    ["ins_mplus_show_timer"]         = "Show timer",
    ["ins_mplus_show_forces"]        = "Show forces (%)",
    ["ins_mplus_hide_blizzard"]      = "Hide Blizzard UI in Mythic+",
    ["ins_mplus_score_section"]      = "TomoScore — Scoreboard",
    ["ins_mplus_score_info"]         = "Displays personal and group scores at the end of a Mythic+.",
    ["ins_mplus_score_enable"]       = "Enable TomoScore",
    ["ins_mplus_score_auto"]         = "Show automatically in M+",

    -- Step 9: CVars
    ["ins_step9_title"]              = "System Optimizations (CVars)",
    ["ins_cvar_info"]                = "TomoMod can apply a set of recommended WoW CVars\nto improve performance and responsiveness.",
    ["ins_cvar_section"]             = "Included Optimizations",
    ["ins_cvar_opt1"]                = "Reduce unnecessary Level of Detail (LOD)",
    ["ins_cvar_opt2"]                = "Optimize frustum culling",
    ["ins_cvar_opt3"]                = "Disable excessive temporal AA",
    ["ins_cvar_opt4"]                = "Improve network responsiveness",
    ["ins_cvar_opt5"]                = "Disable unnecessary UI animations",
    ["ins_cvar_opt6"]                = "Optimize texture streaming",
    ["ins_cvar_success"]             = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0|t  CVars applied successfully!",
    ["ins_cvar_apply_btn"]           = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t Apply all CVars",
    ["ins_cvar_applied"]             = "Optimized CVars applied.",

    -- Step 10: QOL
    ["ins_step10_title"]             = "Quality of Life (QOL)",
    ["ins_qol_info"]                 = "Enable the QOL modules you want.\nAll are accessible separately in /tm |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t QOL.",
    ["ins_qol_auto_section"]         = "Automations",
    ["ins_qol_auto_repair"]          = "Auto-repair at vendors",
    ["ins_qol_fast_loot"]            = "Fast loot (quick item pickup)",
    ["ins_qol_skip_cinematics"]      = "Auto-skip already seen cinematics",
    ["ins_qol_hide_talking_head"]    = "Hide Talking Head (scroll dialogues)",
    ["ins_qol_auto_accept"]          = "Auto-accept group invites (friends & guild)",
    ["ins_qol_tooltip_ids"]          = "Show IDs in tooltips (spell ID, item ID...)",
    ["ins_qol_combat_section"]       = "Combat",
    ["ins_qol_combat_text"]          = "Custom floating combat text",
    ["ins_qol_hide_castbar"]         = "Hide Blizzard castbar (use TomoMod's)",

    -- Step 11: SkyRide
    ["ins_step11_title"]             = "SkyRide — Dragonriding Bar",
    ["ins_skyride_info"]             = "SkyRide displays a Vigor bar (6 charges) and a\nSecond Wind bar (3 charges) for dragonriding.",
    ["ins_skyride_activation"]       = "Activation",
    ["ins_skyride_enable"]           = "Enable SkyRide bar",
    ["ins_skyride_auto_info"]        = "The bar shows automatically in dragonriding mode\nand hides outside of it.",
    ["ins_skyride_dimensions"]       = "Dimensions",
    ["ins_skyride_width"]            = "Width",
    ["ins_skyride_height"]           = "Height",
    ["ins_skyride_reset_section"]    = "Reset Position",
    ["ins_skyride_reset_btn"]        = "Reset Position",

    -- Step 12: Done
    ["ins_step12_title"]             = "Setup Complete!",
    ["ins_done_check"]               = "All set!",
    ["ins_done_recap"]               = "Your TomoMod configuration is saved. Here are some reminders:\n\n|cff0cd29f/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Open the configuration panel\n|cff0cd29f/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Unlock and move elements\n|cff0cd29f/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Relaunch this installer\n\nAll options configured here can be changed anytime\nfrom the corresponding panels in the TomoMod GUI.\n\nA |cff0cd29fUI reload|r is required to apply certain changes\n(nameplates, skins, UnitFrames).",
    ["ins_done_reload"]              = "Reload UI",

    -- ═══════════ Config Panels — i18n ═══════════
    -- ActionBars panel
    ["opt_abs_style"]                = "Visual style",
    ["section_bar_opacity"]          = "Per-bar opacity",
    ["opt_abs_bar_select"]           = "Bar to configure",
    ["opt_abs_opacity"]              = "Opacity",
    ["btn_abs_apply_all"]            = "Apply to all bars",
    ["opt_abs_combat_only_label"]    = "Show only in combat:",
    ["opt_abs_combat_only"]          = "Bar visible in combat only",
    ["section_bar_management"]       = "Action bar management",
    ["btn_abs_unlock"]               = "Unlock bars",
    ["info_abs_unlock"]              = "Unlock bars to reveal drag handles.\nRight-click a handle to configure a bar individually.",
    ["section_bar_quick"]            = "Quick settings",
    ["tab_abs_skin"]                 = "Button skin",
    ["tab_abs_bars"]                 = "Bar management",
    -- General panel
    ["btn_relaunch_installer"]       = "Relaunch installer",
    ["info_relaunch_installer"]      = "Launches the 12-step setup wizard.",
    -- Sound panel
    ["section_sound_preview"]        = "Preview & options",
    -- UFPreview
    ["preview_header"]               = "LIVE PREVIEW",
    ["preview_player"]               = "Player",
    ["preview_target_name"]          = "Taurache",
    ["preview_focus_name"]           = "Priestella",
    ["preview_pet_name"]             = "Water Wolf",
    ["preview_tot_name"]             = "Target-of-target",
    ["preview_cast_player"]          = "Frostbolt",
    ["preview_cast_target"]          = "Fireball",
    ["preview_lbl_player"]           = "PLAYER",
    ["preview_lbl_target"]           = "TARGET",
    ["preview_lbl_focus"]            = "FOCUS",
    ["preview_lbl_pet"]              = "PET",
    ["preview_lbl_tot"]              = "TOT",
    ["preview_click_nav"]            = "click to navigate",
    -- ConfigUI footer
    ["ui_footer_hint"]               = "/tm  ·  /tm sr to move elements",

    -- =====================
    -- SKINS CATEGORY (top-level)
    -- =====================
    ["cat_skins"]                        = "Skins",

    -- Skins > Chat Frame V2 — tab labels & UI strings
    ["chatv2_tab_general"]               = "General",
    ["chatv2_tab_instance"]              = "Instance",
    ["chatv2_tab_chucho"]                = "Chucho",
    ["chatv2_tab_personnel"]             = "Personal",
    ["chatv2_tab_combat"]                = "Combat",
    ["chatv2_sidebar_title"]             = "CHAT",
    ["chatv2_expand_btn"]                = "Chat",
    ["chatv2_mover_label"]               = "Chat Frame V2",
    ["chatv2_input_hint"]                = "Press Enter to type...",

    -- Skins > Chat Frame tab (config panel)
    ["tab_skin_chatframe"]               = "Chat Frame",
    ["section_skin_chatframe"]           = "Chat Frame Skin",
    ["info_skin_chatframe_desc"]         = "Sidebar chat panel — General, Instance, Chucho, Personal, Combat — with unread badges and pin indicators.",
    ["opt_skin_chatframe_enable"]        = "Enable Chat Frame Skin",
    ["opt_skin_chatframe_width"]         = "Width",
    ["opt_skin_chatframe_height"]        = "Height",
    ["opt_skin_chatframe_scale"]         = "Scale %",
    ["opt_skin_chatframe_opacity"]       = "Background opacity",
    ["opt_skin_chatframe_font_size"]     = "Font size",
    ["opt_skin_chatframe_timestamp"]     = "Show timestamp",

    -- Skins > Bags tab (config panel)
    ["tab_skin_bags"]                    = "Bags",
    ["section_skin_bags"]                = "Bag Skin",
    ["info_skin_bags_desc"]              = "Combined/category/per-bag layouts with quality borders, search, item-level badges, junk icons, bag bar, and resizable frame.",
    ["opt_skin_bags_enable"]             = "Enable Bag Skin",
    -- Bag skin — extra features
    ["bagskin_de_badge"]                 = "DE",
    ["bagskin_de_tooltip"]               = "|cff0cd29f[Right-click]|r Disenchant",
    ["bagskin_currencies_none"]          = "No tracked currencies (right-click a currency → Show in Backpack)",
    ["opt_skin_bags_stack_merge"]        = "Merge identical item stacks",
    ["opt_skin_bags_show_empty"]         = "Show free slots section",
    ["opt_skin_bags_show_recent"]        = "Show recent items section",
    ["opt_skin_bags_columns"]            = "Columns",
    ["opt_skin_bags_slot_size"]          = "Slot size",
    ["opt_skin_bags_slot_spacing"]       = "Slot spacing",
    ["opt_skin_bags_slot_spacing_x"]     = "Slot Spacing X",
    ["opt_skin_bags_slot_spacing_y"]     = "Slot Spacing Y",
    ["opt_skin_bags_scale"]              = "Scale %",
    ["opt_skin_bags_opacity"]            = "Background opacity",
    ["opt_skin_bags_quality_borders"]    = "Show quality borders",
    ["opt_skin_bags_cooldowns"]          = "Show cooldown overlays",
    ["opt_skin_bags_quantity"]           = "Show quantity badges",
    ["opt_skin_bags_search"]             = "Show search bar",
    ["opt_skin_bags_show_ilvl"]          = "Show item level on equipment",
    ["opt_skin_bags_show_junk_icon"]     = "Show junk coin icon",
    ["opt_skin_bags_layout_mode"]        = "Layout mode",
    ["opt_skin_bags_layout_combined"]    = "Combined Grid",
    ["opt_skin_bags_layout_categories"]  = "Categories",
    ["opt_skin_bags_layout_separate"]    = "Separate Bags",
    ["opt_skin_bags_reverse_order"]      = "Reverse bag order",
    ["opt_skin_bags_show_bag_bar"]       = "Show bag bar",
    ["opt_skin_bags_settings"]           = "Bag Settings",
    ["opt_skin_bags_sort_mode"]          = "Sort mode",
    ["opt_skin_bags_sort_none"]          = "Manual",
    ["opt_skin_bags_sort_quality"]       = "Quality",
    ["opt_skin_bags_sort_name"]          = "Name",
    ["opt_skin_bags_sort_type"]          = "Type",
    ["opt_skin_bags_sort_ilvl"]          = "Item Level",
    ["opt_skin_bags_sort_recent"]        = "Recent",
    ["opt_skin_bags_show_gold"]          = "Show gold (footer)",
    ["opt_skin_bags_show_currencies"]    = "Show tracked currencies (footer)",
    -- Bag skin — category names
    ["bagskin_cat_recent"]               = "Recent Items",
    ["bagskin_cat_equipment"]            = "Equipment",
    ["bagskin_cat_consumables"]          = "Consumables",
    ["bagskin_cat_quest"]                = "Quest Items",
    ["bagskin_cat_tradegoods"]           = "Trade Goods",
    ["bagskin_cat_reagents"]             = "Reagents",
    ["bagskin_cat_gems"]                 = "Gems & Enhancements",
    ["bagskin_cat_recipes"]              = "Recipes",
    ["bagskin_cat_pets"]                 = "Battle Pets",
    ["bagskin_cat_junk"]                 = "Junk",
    ["bagskin_cat_misc"]                 = "Miscellaneous",
    ["bagskin_cat_free"]                 = "Free Slots",

    -- Skins > Objective Tracker tab
    ["tab_skin_objtracker"]              = "Obj. Tracker",

    -- Skins > Character tab
    ["tab_skin_character"]               = "Character",

    -- Skins > Buffs tab
    ["tab_skin_buffs"]                   = "Buffs",

    -- Skins > Game Menu tab
    ["tab_skin_gamemenu"]                = "Game Menu",

    -- Skins > Tooltip tab
    ["tab_skin_tooltip"]                 = "Tooltip",
    ["section_tooltip_skin"]             = "Tooltip Skin",
    ["opt_tooltip_skin_enable"]          = "Enable tooltip skin",
    ["info_tooltip_skin_reload"]         = "Some changes require hovering a new target.",
    ["opt_tooltip_bg_alpha"]             = "Background opacity",
    ["opt_tooltip_border_alpha"]         = "Border opacity",
    ["opt_tooltip_font_size"]            = "Font size",
    ["opt_tooltip_hide_healthbar"]       = "Hide health bar",
    ["opt_tooltip_class_color"]          = "Class-colored player names",
    ["opt_tooltip_hide_server"]          = "Hide server in player names",
    ["opt_tooltip_hide_title"]           = "Hide title in player names",
    ["opt_tooltip_guild_color"]          = "Custom guild name color",
    ["opt_tooltip_guild_color_pick"]     = "Guild name color",

    -- Skins > Mail tab
    ["tab_skin_mail"]                    = "Game Menu",

        -- =====================
    -- WAYPOINT MODULE (/tm way)
    -- =====================
    -- GUI
    ["tab_qol_waypoint"]                  = "Waypoint",
    ["section_waypoint"]                  = "Waypoint",
    ["opt_way_zone_only"]                 = "Show only in current zone",
    ["opt_way_size"]                      = "Beacon size",
    ["opt_way_shape"]                     = "Shape",
    ["way_shape_ring"]                    = "Ring",
    ["way_shape_arrow"]                   = "Arrow",
    ["opt_way_color"]                     = "Waypoint color",
    -- Slash
    ["msg_help_way"]                     = "Place a waypoint at your current position",
    ["msg_help_way_coords"]              = "Place a waypoint at (x, y) on the current map",
    ["msg_help_way_clear"]               = "Clear the active waypoint",
    ["way_cleared"]                      = "Waypoint cleared.",
    ["way_set"]                          = "Waypoint set to %s%s.",
    ["way_here"]                         = "Waypoint placed at current position.",
    ["way_no_map"]                       = "Cannot determine current map.",
    ["way_no_pos"]                       = "Cannot determine player position.",
    ["way_bad_map"]                      = "Cannot place a waypoint on this map.",
    ["way_bad_coords"]                   = "Coordinates must be between 0 and 100.",
    ["way_usage"]                        = "Usage: /tm way [mapID] x y [name]  |  /tm way clear",

    -- =====================
    -- CASTBARS (standalone module)
    -- =====================
    ["cat_castbars"]                     = "Castbars",

    -- General section
    ["cb_section_general"]               = "General",
    ["opt_cb_enable"]                    = "Enable Standalone Castbars",
    ["info_cb_description"]              = "Replaces Blizzard castbars with fully customizable standalone bars for Player, Target, Focus, Pet and Boss.",
    ["opt_cb_hide_blizzard"]             = "Hide Blizzard castbars",
    ["opt_cb_class_color"]               = "Use class color",
    ["opt_cb_show_transitions"]          = "Cast start/end animations",
    ["opt_cb_show_channel_ticks"]        = "Show channel tick markers",
    ["opt_cb_timer_format"]              = "Timer format",
    ["cb_timer_remaining"]               = "Remaining (1.5)",
    ["cb_timer_remaining_total"]         = "Remaining / Total (1.5 / 3.0)",
    ["cb_timer_elapsed"]                 = "Elapsed (1.5)",
    ["opt_cb_spell_max_len"]             = "Spell name max length (0 = no limit)",

    -- Appearance
    ["cb_section_appearance"]            = "Appearance",
    ["opt_cb_bar_texture"]               = "Bar texture",
    ["cb_tex_blizzard"]                  = "Blizzard",
    ["cb_tex_smooth"]                    = "Smooth",
    ["cb_tex_flat"]                      = "Flat",
    ["opt_cb_font_size"]                 = "Font size",
    ["opt_cb_bg_mode"]                   = "Background mode",
    ["cb_bg_black"]                      = "Black",
    ["cb_bg_transparent"]                = "Transparent",
    ["cb_bg_custom"]                     = "Custom texture",

    -- Colors
    ["cb_section_colors"]                = "Colors",
    ["opt_cb_cast_color"]                = "Cast color",
    ["opt_cb_ni_color"]                  = "Non-interruptible overlay",
    ["opt_cb_interrupt_color"]           = "Interrupted color",

    -- Spark
    ["cb_section_spark"]                 = "Spark",
    ["opt_cb_show_spark"]                = "Show spark animation",
    ["opt_cb_spark_style"]               = "Spark style",
    ["opt_cb_spark_color"]               = "Spark color",
    ["opt_cb_spark_glow_color"]          = "Spark glow color",
    ["opt_cb_spark_tail_color"]          = "Spark tail color",
    ["opt_cb_spark_glow_alpha"]          = "Glow opacity",
    ["opt_cb_spark_tail_alpha"]          = "Tail opacity",

    -- GCD
    ["cb_section_gcd"]                   = "GCD Spark",
    ["opt_cb_show_gcd"]                  = "Show GCD bar below player castbar",
    ["opt_cb_gcd_height"]                = "GCD bar height",
    ["opt_cb_gcd_color"]                 = "GCD color",

    -- Interrupt feedback
    ["cb_section_interrupt"]             = "Interrupt Feedback",
    ["opt_cb_show_interrupt_feedback"]   = "Show interrupt feedback text",
    ["opt_cb_interrupt_fb_color"]        = "Feedback text color",
    ["opt_cb_interrupt_fb_size"]         = "Feedback font size",
    ["cb_interrupt_feedback_text"]       = "INTERRUPTED!",
    ["cb_interrupt_feedback_full"]       = "INTERRUPTED: %s",
    ["cb_interrupted"]                   = "Interrupted",

    -- Per-unit tabs
    ["cb_tab_general"]                   = "General",
    ["cb_tab_player"]                    = "Player",
    ["cb_tab_target"]                    = "Target",
    ["cb_tab_focus"]                     = "Focus",
    ["cb_tab_pet"]                       = "Pet",
    ["cb_tab_boss"]                      = "Boss",

    -- Per-unit options
    ["cb_section_unit"]                  = "%s Castbar",
    ["opt_cb_unit_enable"]               = "Enable",
    ["opt_cb_unit_width"]                = "Width",
    ["opt_cb_unit_height"]               = "Height",
    ["opt_cb_unit_show_icon"]            = "Show icon",
    ["opt_cb_unit_icon_side"]            = "Icon side",
    ["cb_icon_left"]                     = "Left",
    ["cb_icon_right"]                    = "Right",
    ["opt_cb_unit_show_timer"]           = "Show timer",
    ["opt_cb_unit_show_latency"]         = "Show latency",
    ["info_cb_latency"]                  = "Displays a dark overlay showing network latency at the end of the bar.",
    ["info_cb_position"]                 = "Use /tm layout to unlock and drag this castbar.",
    ["btn_cb_reset_position"]            = "Reset Position",
    ["cb_move_label"]                    = "(Drag to move)",
    ["cb_preview_castbar"]               = "Preview: %s",

    -- Mover
    ["mover_castbar_standalone"]         = "Castbars",

    -- ═══════════════════════════════════
    -- Party Frames
    -- ═══════════════════════════════════
    ["cat_partyframes"]                  = "Party Frames",
    ["mover_partyframes"]                = "Party Frames",

    -- Tabs
    ["pf_tab_general"]                   = "General",
    ["pf_tab_features"]                  = "Features",
    ["pf_tab_cooldowns"]                 = "Cooldowns",
    ["pf_tab_arena"]                     = "Arena",

    -- General tab
    ["pf_section_general"]               = "General",
    ["pf_opt_enable"]                    = "Enable Party Frames",
    ["pf_info_description"]              = "Custom party frames for M+ and Arena with health, absorb, heal prediction, HoTs, interrupt/brez CD tracking, and dispel highlights.",
    ["pf_opt_hide_blizzard"]             = "Hide Blizzard party frames",
    ["pf_opt_sort_role"]                 = "Sort by role (Tank > Healer > DPS)",

    ["pf_section_dimensions"]            = "Dimensions",
    ["pf_opt_width"]                     = "Frame width",
    ["pf_opt_height"]                    = "Frame height",
    ["pf_opt_spacing"]                   = "Spacing",
    ["pf_opt_grow_direction"]            = "Growth direction",
    ["pf_dir_down"]                      = "Down",
    ["pf_dir_up"]                        = "Up",
    ["pf_dir_right"]                     = "Right",
    ["pf_dir_left"]                      = "Left",

    ["pf_section_display"]               = "Display",
    ["pf_opt_show_name"]                 = "Show name",
    ["pf_opt_show_health_text"]          = "Show health text",
    ["pf_opt_health_format"]             = "Health format",
    ["pf_fmt_deficit"]                   = "Deficit",
    ["pf_opt_health_color"]              = "Health color mode",
    ["pf_color_green"]                   = "Green",
    ["pf_color_gradient"]                = "Gradient",
    ["pf_opt_show_power"]                = "Show power bar",
    ["pf_opt_power_height"]              = "Power bar height",
    ["pf_opt_name_max_length"]           = "Name max letters (0 = no limit)",
    ["pf_opt_show_role"]                 = "Show role icon",
    ["pf_opt_role_size"]                 = "Role icon size",
    ["pf_opt_show_marker"]               = "Show raid marker",

    ["pf_section_font"]                  = "Font",
    ["pf_opt_font_size"]                 = "Font size",

    ["pf_section_position"]              = "Position",
    ["pf_info_position"]                 = "Use /tm layout to unlock and drag party frames.",
    ["pf_btn_reset_position"]            = "Reset Position",

    -- Features tab
    ["pf_section_health_extras"]         = "Health Features",
    ["pf_opt_show_absorb"]               = "Show absorb bar",
    ["pf_opt_absorb_color"]              = "Absorb color",
    ["pf_opt_show_heal_pred"]            = "Show heal prediction",

    ["pf_section_range"]                 = "Range Check",
    ["pf_opt_show_range"]                = "Fade out-of-range members",
    ["pf_opt_oor_alpha"]                 = "Out-of-range opacity",

    ["pf_section_dispel"]                = "Dispel Highlight",
    ["pf_opt_show_dispel"]               = "Highlight dispellable debuffs",
    ["pf_info_dispel"]                   = "Border glows by debuff type: Magic (blue), Curse (purple), Disease (brown), Poison (green).",

    ["pf_section_hots"]                  = "HoT Tracking",
    ["pf_opt_show_hots"]                 = "Show HoT indicators",
    ["pf_opt_hot_size"]                  = "HoT icon size",
    ["pf_opt_max_hots"]                  = "Max HoTs shown",
    ["pf_info_hots"]                     = "Displays healing-over-time effects with class-colored borders. Supports Priest, Druid, Paladin, Shaman, Monk, and Evoker HoTs.",

    -- Cooldowns tab
    ["pf_section_cooldowns"]             = "Cooldown Trackers",
    ["pf_opt_show_kick"]                 = "Show interrupt cooldown",
    ["pf_opt_show_brez"]                 = "Show battle rez cooldown",
    ["pf_opt_cd_size"]                   = "CD icon size",
    ["pf_opt_cd_layout"]                 = "CD icon layout",
    ["pf_cd_vertical"]                   = "Vertical (on frame)",
    ["pf_cd_horizontal"]                 = "Horizontal (below)",
    ["pf_info_cooldowns"]                = "Tracks interrupt and battle rez cooldowns for each party member. Detected via UNIT_SPELLCAST_SUCCEEDED (no COMBAT_LOG_EVENT_UNFILTERED).",

    -- Arena tab
    ["pf_section_arena"]                 = "Arena Enemy Frames",
    ["pf_opt_arena_enable"]              = "Enable Arena Frames",
    ["pf_info_arena"]                    = "Displays enemy team health, power, and PvP trinket cooldowns in Arena (2v2/3v3).",
    ["pf_section_arena_dims"]            = "Arena Dimensions",
    ["pf_opt_arena_width"]               = "Width",
    ["pf_opt_arena_height"]              = "Height",
    ["pf_opt_arena_spacing"]             = "Spacing",
    ["pf_section_arena_trinket"]         = "PvP Trinket",
    ["pf_opt_show_trinket"]              = "Show trinket cooldown",
    ["pf_opt_trinket_size"]              = "Trinket icon size",
    ["pf_opt_show_spec"]                 = "Show spec icon",
    ["pf_section_arena_pos"]             = "Arena Position",
    ["pf_info_arena_pos"]                = "Use /tm layout to unlock and drag arena frames.",
    ["pf_btn_reset_arena_pos"]           = "Reset Position",

    -- ═══════════════════════════════════
    -- Aura Tracker
    -- ═══════════════════════════════════
    ["tab_qol_aura_tracker"]             = "Aura Tracker",
    ["mover_auratracker"]                = "Aura Tracker",

    ["at_section_general"]               = "General",
    ["at_opt_enable"]                    = "Enable Aura Tracker",
    ["at_info_description"]              = "Tracks important buffs: trinket procs, weapon enchant procs, self-buffs, and defensives in a simple icon overlay.",

    ["at_section_appearance"]            = "Appearance",
    ["at_opt_icon_size"]                 = "Icon size",
    ["at_opt_spacing"]                   = "Spacing",
    ["at_opt_max_icons"]                 = "Max icons",
    ["at_opt_grow_direction"]            = "Growth direction",
    ["at_opt_font_size"]                 = "Font size",

    ["at_section_display"]               = "Display",
    ["at_opt_show_timer"]                = "Show timer",
    ["at_opt_show_stacks"]               = "Show stack count",
    ["at_opt_show_glow"]                 = "Glow on new proc",
    ["at_opt_timer_threshold"]           = "Timer flash threshold (sec)",

    ["at_section_categories"]            = "Categories",
    ["at_info_categories"]               = "Choose which aura categories to track.",
    ["at_cat_trinkets"]                  = "Trinket procs",
    ["at_cat_enchants"]                  = "Weapon enchant procs",
    ["at_cat_selfbuffs"]                 = "Self-buffs (cooldowns)",
    ["at_cat_raidbuffs"]                 = "Raid buffs",
    ["at_cat_defensives"]                = "Defensives (external + personal)",

    ["at_section_position"]              = "Position",
    ["at_info_position"]                 = "Use /tm layout to unlock and drag the aura tracker.",
    ["at_btn_reset_position"]            = "Reset Position",

    -- ═══════════════════════════════════
    -- Battle Text
    -- ═══════════════════════════════════
    ["cat_battletext"]                   = "Battle Text",
    ["mover_battletext"]                 = "Battle Text",

    ["bt_section_general"]               = "General",
    ["bt_info_description"]              = "Scrolling combat text: damage and healing, incoming and outgoing.",
    ["bt_opt_enable"]                    = "Enable Battle Text",

    ["bt_section_display"]               = "Display",
    ["bt_opt_outgoing"]                  = "Show outgoing damage",
    ["bt_opt_incoming"]                  = "Show incoming damage",
    ["bt_opt_overheal"]                  = "Show overhealing",
    ["bt_opt_throttle"]                  = "Merge DoT/HoT ticks",

    ["bt_section_appearance"]            = "Appearance",
    ["bt_opt_font_size"]                 = "Font size",
    ["bt_opt_throttle_window"]           = "Merge window (sec)",

    ["bt_section_position"]              = "Position",
    ["bt_info_position"]                 = "Use /tm layout to unlock and drag the battle text zones.",
    ["bt_btn_reset_position"]            = "Reset Positions",

    ["bt_zone_outgoing"]                 = "Outgoing",
    ["bt_zone_incoming"]                 = "Incoming",
    ["bt_zone_heal_out"]                 = "Heal Out",
    ["bt_zone_heal_in"]                  = "Heal In",

    ["bt_cmd_help"]                      = "/tm bt <cmd>",
    ["bt_enabled"]                       = "enabled",
    ["bt_disabled"]                      = "disabled",
    ["bt_crit"]                          = "!",
    ["bt_zones_locked"]                  = "zones locked",
    ["bt_zones_unlocked"]                = "zones unlocked",
    ["bt_reset_done"]                    = "positions reset.",
    ["bt_miss_miss"]                     = "Miss",
    ["bt_miss_dodge"]                    = "Dodge",
    ["bt_miss_parry"]                    = "Parry",
    ["bt_miss_block"]                    = "Block",
    ["bt_miss_resist"]                   = "Resist",
    ["bt_miss_absorb"]                   = "Absorb",
    ["bt_miss_immune"]                   = "Immune",
    ["bt_miss_evade"]                    = "Evade",
    ["bt_miss_deflect"]                  = "Deflect",
    ["bt_miss_reflect"]                  = "Reflect",
})