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
    ["cat_diagnostics"]     = "Diagnostics",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "About",
    ["about_text"]                      = "|cff2ed884TomoMod|r %s by TomoAniki\nLightweight interface with QOL, UnitFrames and Nameplates.\nType /tm help for the command list.",
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
    ["opt_cursor_ring_texture"]         = "Texture",
    ["cursor_tex_ring"]                 = "Ring",
    ["cursor_tex_glow"]                 = "Glow",
    ["cursor_tex_cygle"]                = "Cygle",
    ["cursor_tex_heart"]                = "Heart",

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
    ["res_icicles"]                      = "Icicles",

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
    ["opt_cdm_bufficon_direction"]        = "Buff icon direction",
    ["opt_cdm_buffbar_direction"]         = "BuffBar direction",
    ["opt_cdm_buffbar_width"]             = "Bar width (horizontal)",
    ["buffbar_vertical"]                  = "Vertical",
    ["buffbar_horizontal"]                = "Horizontal",
    ["dir_centered"]                      = "Centered (horizontal)",
    ["dir_left"]                          = "Left",
    ["dir_right"]                         = "Right",
    ["dir_up"]                            = "Up",
    ["dir_down"]                          = "Down",

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
    ["section_ab_system"]               = "Action Bar System",
    ["opt_ab_system_enable"]            = "Enable TomoMod Action Bar system (requires reload)",
    ["opt_ab_system_reload"]            = "Disabling this fully restores Blizzard action bars after /reload.",
    ["section_ab_skin"]                 = "Visual Skin",
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
    ["opt_obj_tracker_buckets"]         = "Group quests into collapsible categories",
    ["opt_obj_tracker_header_size"]     = "Header font size",
    ["opt_obj_tracker_cat_size"]        = "Category font size",
    ["opt_obj_tracker_quest_size"]      = "Quest title font size",
    ["opt_obj_tracker_obj_size"]        = "Objective font size",
    ["opt_obj_tracker_max_quests"]       = "Max quests displayed (0 = no limit)",
    ["ot_overflow_text"]                 = "%d more quest(s) hidden...",
    ["info_obj_tracker"]                = "Reskins the Blizzard Objective Tracker with a dark panel, custom fonts and colored category headers.",
    ["ot_header_title"]                 = "OBJECTIVES",
    ["ot_header_options"]               = "Options",
    ["ot_bucket_complete"]              = "Ready to Turn In",
    ["ot_bucket_campaign"]              = "Campaign",
    ["ot_bucket_important"]             = "Important",
    ["ot_bucket_legendary"]             = "Legendary",
    ["ot_bucket_weekly"]                = "Weekly",
    ["ot_bucket_daily"]                 = "Daily",
    ["ot_bucket_world"]                 = "World Quests",
    ["ot_bucket_dungeon"]               = "Dungeons",
    ["ot_bucket_raid"]                  = "Raids",
    ["ot_bucket_profession"]            = "Professions",
    ["ot_bucket_achievement"]           = "Achievements",
    ["ot_bucket_quests"]                = "Quests",
    ["ot_bucket_other"]                 = "Other",

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

    -- Auto Vendor / Repair
    ["sublabel_auto_vendor_repair"]     = "— Auto Vendor / Repair —",
    ["opt_avr_auto_repair"]             = "Auto repair on merchant",
    ["opt_avr_sell_grays"]              = "Auto sell gray (poor) items",

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
    ["popup_rename_profile"]            = "|cff2ed884TomoMod|r\n\nNew name for '%s':",
    ["popup_duplicate_profile"]         = "|cff2ed884TomoMod|r\n\nDuplicate '%s' as:",
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
    ["time_tooltip_left_click"]         = "|cff2ed884Left-click:|r Calendar",
    ["time_tooltip_right_click"]        = "|cff2ed884Right-click:|r Server / Local",
    ["time_tooltip_shift_right"]        = "|cff2ed884Shift + Right-click:|r 12h / 24h",
    ["time_format_msg"]                 = "Format: %s",
    ["time_mode_msg"]                   = "Time: %s",

    -- =====================
    -- ENABLED / DISABLED (generic)
    -- =====================
    ["enabled"]                         = "Enabled",
    ["disabled"]                        = "Disabled",

    -- Static Popups
    ["popup_reset_text"]                = "|cff2ed884TomoMod|r\n\nReset ALL settings?\nThis will reload your UI.",
    ["popup_confirm"]                   = "Confirm",
    ["popup_cancel"]                    = "Cancel",
    ["popup_import_text"]               = "|cff2ed884TomoMod|r\n\nImport settings?\nThis will OVERWRITE all your current settings and reload the UI.",
    ["popup_profile_reload"]            = "|cff2ed884TomoMod|r\n\nProfile mode changed.\nReload UI to apply?",
    ["popup_delete_profile"]            = "|cff2ed884TomoMod|r\n\nDelete profile '%s'?\nThis cannot be undone.",

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
    ["btn_layout"]                      = "EditMode",
    ["btn_layout_tooltip"]              = "EditMode: unlock all UI elements to drag & reposition them.",
    ["btn_reload_ui"]                   = "Reload UI",
    ["layout_mode_title"]               = "TomoMod — EditMode",
    ["layout_mode_hint"]                = "Drag elements to reposition — click Lock when done",
    ["layout_btn_lock"]                 = "Lock",
    ["layout_btn_reload"]               = "RL",
    ["layout_btn_gui"]                  = "GUI",
    ["grid_dimmed"]                    = "Grid",
    ["grid_bright"]                    = "Grid +",
    ["grid_disabled"]                  = "Grid OFF",
    ["layout_unlocked"]                 = "EditMode ON — drag elements to reposition. Click Lock or /tm layout when done.",
    ["layout_locked"]                   = "EditMode OFF — positions saved.",
    ["msg_help_layout"]                 = "Toggle EditMode (move all UI elements)",
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
    ["mover_objectivetracker"]          = "Objective Tracker",
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

    -- Chat Frame UI (multi-position containers — adapted from MayronUI)
    ["tab_skin_chatframeui"]             = "Chat Frame UI",
    ["sublabel_chatframeui"]             = "— Multi-Position Chat Frame UI —",
    ["opt_cfui_enable"]                  = "Enable Chat Frame UI",
    ["opt_cfui_enable_desc"]             = "Adds decorative containers, button bar, sidebar icons, and layout switching (MayronUI style).",
    ["opt_cfui_frame_topleft"]           = "Top-Left Frame",
    ["opt_cfui_frame_topright"]          = "Top-Right Frame",
    ["opt_cfui_frame_bottomleft"]        = "Bottom-Left Frame",
    ["opt_cfui_frame_bottomright"]       = "Bottom-Right Frame",
    ["opt_cfui_show_tab_bar"]            = "Show Tab Bar",
    ["opt_cfui_tab_bar_offset"]          = "Tab Bar Y-Offset",
    ["opt_cfui_window_offset"]           = "Window Y-Offset",
    ["opt_cfui_x_offset"]               = "X-Offset",
    ["opt_cfui_y_offset"]               = "Y-Offset",
    ["opt_cfui_icons_anchor"]            = "Sidebar Icons Anchor",
    ["opt_cfui_raid_frame_mgr"]          = "Reskin Raid Frame Manager",
    ["opt_cfui_editbox_position"]        = "Edit Box Position",
    ["opt_cfui_editbox_height"]          = "Edit Box Height",
    ["opt_cfui_swap_in_combat"]          = "Allow button swap in combat",
    ["cfui_show_chat_menu"]              = "Show Chat Menu",
    ["cfui_show_professions"]            = "Show Professions",
    ["cfui_show_shortcuts"]              = "Show AddOn Shortcuts",
    ["cfui_copy_chat"]                   = "Copy Chat Text",
    ["cfui_click_toggle_status"]         = "Click to toggle AFK",
    ["cfui_layout_button"]               = "TomoMod Layout",
    ["cfui_left_click"]                  = "Left Click:",
    ["cfui_switch_layout"]               = "Switch Layout",
    ["cfui_no_layouts"]                  = "No saved layouts. Use /tm layout save <name>",
    ["cfui_no_professions"]              = "You have no professions.",
    ["cfui_config_menu"]                 = "Config",
    ["cfui_profiles"]                    = "Profiles",
    ["cfui_clear_chat"]                  = "Clear Chat",
    ["cfui_reload_ui"]                   = "Reload UI",
    ["cfui_btn_character"]               = "Character",
    ["cfui_btn_bags"]                    = "Bags",
    ["cfui_btn_friends"]                 = "Friends",
    ["cfui_btn_guild"]                   = "Guild",
    ["cfui_btn_help"]                    = "Help Menu",
    ["cfui_btn_pvp"]                     = "PVP",
    ["cfui_btn_spellbook"]               = "Spell Book",
    ["cfui_btn_talents"]                 = "Talents",
    ["cfui_btn_achievements"]            = "Achievements",
    ["cfui_btn_calendar"]                = "Calendar",
    ["cfui_btn_lfd"]                     = "LFD",
    ["cfui_btn_raid"]                    = "Raid",
    ["cfui_btn_encounter"]               = "Encounter Journal",
    ["cfui_btn_collections"]             = "Collections Journal",
    ["cfui_btn_macros"]                  = "Macros",
    ["cfui_btn_worldmap"]                = "World Map",
    ["cfui_btn_questlog"]                = "Quest Log",
    ["cfui_btn_reputation"]              = "Reputation",
    ["cfui_btn_pvpscore"]                = "PVP Score",
    ["cfui_btn_currency"]                = "Currency",

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
    ["tmt_unlock_msg"]              = "|cff2ed884TomoMod|r M+ Tracker: Frame unlocked \226\128\148 drag to reposition.",
    ["tmt_lock_msg"]                = "|cff2ed884TomoMod|r M+ Tracker: Frame locked.",
    ["tmt_reset_msg"]               = "|cff2ed884TomoMod|r M+ Tracker: Position reset.",
    ["tmt_unknown_cmd"]             = "|cff2ed884TomoMod|r M+ Tracker: Unknown command.",
    ["tmt_key_level"]               = "+%d",
    ["tmt_dungeon_unknown"]         = "Mythic+",
    ["tmt_overtime"]                = "OVERTIME",
    ["tmt_completed_on_time"]       = "COMPLETED",
    ["tmt_completed_depleted"]      = "DEPLETED",
    ["tmt_forces"]                  = "FORCES",
    ["tmt_forces_done"]             = "COMPLETE",
    ["tmt_forces_pct"]              = "%.1f%%",
    ["tmt_forces_count"]            = "%d / %d",
    ["tmt_preview_active"]          = "|cff2ed884TomoMod|r M+ Tracker: Preview mode active.",
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
    ["tmt_preview_active"]          = "|cff2ed884TomoMod|r M+ Tracker: Preview active \226\128\148 |cFF55B400/tmt lock|r to lock.",

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
    ["ts_reset_msg"]                = "|cff2ed884TomoMod|r Scoreboard: Position reset.",
    ["ts_no_data"]                  = "|cff2ed884TomoMod|r Scoreboard: No dungeon data available.",
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
    ["mhub_tp_not_learned"]          = "|cff2ed884TomoMod|r: Teleport spell not learned.",
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
    ["ins_header_title"]             = "|cff2ed884Tomo|r|cffe4e4e4Mod|r  —  Setup Wizard",
    ["ins_step_counter"]             = "Step %d / %d",
    ["ins_btn_prev"]                 = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage:0|t Previous",
    ["ins_btn_next"]                 = "Next |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_finish"]               = "Finish |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t",
    ["ins_btn_skip"]                 = "Skip installation",

    -- Step 1: Welcome
    ["ins_step1_title"]              = "Welcome to TomoMod",
    ["ins_subtitle"]                 = "Interface & QOL suite for The War Within",
    ["ins_welcome_desc"]             = "This wizard will guide you through |cff2ed88416 steps|r to configure TomoMod to\nyour preferences: unit frames, party frames, castbars, nameplates, action bars,\nresources, skins, sound, Mythic+, QOL, optimizations and SkyRide.\n\nAll these options can be changed anytime via |cff2ed884/tm|r.",

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
    ["ins_ab_system_section"]        = "Action Bar System",
    ["ins_ab_system_info"]           = "TomoMod replaces Blizzard's action bars with custom containers,\npositioning, fade system and display conditions.\nDisable this to fully restore the default Blizzard action bars.",
    ["ins_ab_system_enable"]         = "Enable TomoMod Action Bar system",
    ["ins_ab_system_reload_info"]    = "Requires a /reload to take effect.",
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
    ["ins_done_recap"]               = "Your TomoMod configuration is saved. Here are some reminders:\n\n|cff2ed884/tm|r              |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Open the configuration panel\n|cff2ed884/tm sr|r           |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Unlock and move elements\n|cff2ed884/tm install|r      |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage:0|t  Relaunch this installer\n\nAll options configured here can be changed anytime\nfrom the corresponding panels in the TomoMod GUI.\n\nA |cff2ed884UI reload|r is required to apply certain changes\n(nameplates, skins, UnitFrames).",
    ["ins_done_reload"]              = "Reload UI",

    -- Step NEW: Unit Frames
    ["ins_uf_title"]                 = "Unit Frames",
    ["ins_uf_info"]                  = "TomoMod replaces the default Blizzard unit frames (player, target, focus, pet)\nwith modern, customizable frames.",
    ["ins_uf_section"]               = "General",
    ["ins_uf_enable"]                = "Enable TomoMod unit frames",
    ["ins_uf_hide_blizzard"]         = "Hide Blizzard default frames",
    ["ins_uf_reload_info"]           = "A reload is required to apply changes to unit frames.",

    -- Step NEW: Party Frames
    ["ins_pf_title"]                 = "Party Frames",
    ["ins_pf_info"]                  = "Custom party frames with role icons, dispel highlights,\nand cooldown tracking for group play.",
    ["ins_pf_section"]               = "General",
    ["ins_pf_enable"]                = "Enable TomoMod party frames",
    ["ins_pf_hide_blizzard"]         = "Hide Blizzard party frames",
    ["ins_pf_cd_section"]            = "Cooldown Trackers",
    ["ins_pf_cd_info"]               = "Track your group members' interrupt and battle rez cooldowns\ndirectly on their party frames.",
    ["ins_pf_show_interrupt"]        = "Show interrupt cooldown tracker",
    ["ins_pf_show_brez"]             = "Show battle rez cooldown tracker",
    ["ins_pf_reload_info"]           = "A reload is required to apply changes to party frames.",

    -- Step 5: Raid Frames
    ["ins_rf_title"]                 = "Raid Frames",
    ["ins_rf_info"]                  = "Custom raid frames for groups of 6-40 players.\nGrid or list layout with dispel highlights, HoT tracking, and debuff icons.",
    ["ins_rf_section"]               = "General",
    ["ins_rf_enable"]                = "Enable TomoMod raid frames",
    ["ins_rf_hide_blizzard"]         = "Hide Blizzard raid frames",
    ["ins_rf_features_section"]      = "Features",
    ["ins_rf_show_dispel"]           = "Dispel highlight (border glow by debuff type)",
    ["ins_rf_show_hots"]             = "HoT tracking (healer spell indicators)",
    ["ins_rf_show_debuffs"]          = "Show debuff icons on raid members",
    ["ins_rf_show_defensives"]       = "Show defensive cooldown icons",
    ["ins_rf_layout_section"]        = "Layout",
    ["ins_rf_layout"]                = "Raid layout mode",
    ["ins_rf_reload_info"]           = "A reload is required to apply changes to raid frames.",

    -- Step NEW: Castbars
    ["ins_cb_title"]                 = "Castbars",
    ["ins_cb_info"]                  = "Custom castbars for player, target, focus and pet\nwith spark animation and interrupt feedback.",
    ["ins_cb_section"]               = "General",
    ["ins_cb_enable"]                = "Enable TomoMod castbars",
    ["ins_cb_hide_blizzard"]         = "Hide Blizzard default castbar",
    ["ins_cb_class_color"]           = "Use class color for cast bar fill",
    ["ins_cb_reload_info"]           = "A reload is required to apply changes to castbars.",

    -- Step NEW: Resource Bars & Cooldown Manager
    ["ins_res_title"]                = "Resources & Cooldowns",
    ["ins_res_info"]                 = "Class power display (combo points, runes, soul shards, etc.)\nwith icon or bar mode.",
    ["ins_res_section"]              = "Resource Bars",
    ["ins_res_enable"]               = "Enable resource bars",
    ["ins_res_display"]              = "Display mode",
    ["ins_cdm_section"]              = "Cooldown Manager",
    ["ins_cdm_info"]                 = "Overlay cooldown spiral on action buttons with\ncombat-aware alpha and GCD filtering.",
    ["ins_cdm_enable"]               = "Enable cooldown manager",
    ["ins_cdm_hide_gcd"]             = "Hide GCD spiral",
    ["ins_cdm_desat"]                = "Desaturate buttons on cooldown",

    -- Enhanced Skins
    ["ins_skin_bag"]                 = "Bag skin",
    ["ins_skin_tooltip"]             = "Tooltip skin",
    ["ins_skin_objective"]           = "Objective Tracker skin (color-coded quest types)",
    ["ins_skin_mail"]                = "Mail skin",
    ["ins_skin_reputation"]          = "Reputation bar",

    -- Enhanced QOL
    ["ins_qol_interface_section"]    = "Interface",
    ["ins_qol_minimap"]              = "Custom minimap (border & scaling)",
    ["ins_qol_cursor"]               = "Cursor ring highlight",
    ["ins_qol_afk"]                  = "Custom AFK screen with 3D model",
    ["ins_qol_diag"]                 = "Diagnostics (error capture without popups)",
    ["ins_qol_aura_tracker"]         = "Aura Tracker (trinkets, buffs, defensives)",
    ["ins_qol_auto_summon"]          = "Auto-accept summons",
    ["ins_qol_auto_fill_delete"]     = "Auto-fill DELETE in destroy popups",
    ["ins_qol_auto_quest"]           = "Auto accept/turn in quests (Shift to override)",
    ["ins_qol_class_reminder"]       = "Class buff reminder (Fortitude, Intellect, etc.)",
    ["ins_qol_leveling_bar"]         = "Leveling bar (XP/hour, rested XP overlay)",
    ["ins_qol_waypoint"]             = "Waypoint navigation system",
    ["ins_qol_world_quest_tab"]      = "World Quest browser on World Map",
    ["ins_qol_frame_anchors"]        = "Movable frame anchors (Alert, Loot)",
    ["ins_qol_profession_helper"]    = "Profession Helper (batch disenchant)",

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
    ["btn_abs_layout"]               = "EditMode (/tm layout)",
    ["info_abs_layout"]              = "Use EditMode to move bars.\nDrag the overlays to reposition.",
    ["tab_abs_skin"]                 = "Button skin",
    ["tab_abs_bars"]                 = "Bar management",
    -- Per-bar config
    ["opt_bar_enabled"]              = "Enabled",
    ["opt_bar_orientation"]          = "Orientation",
    ["opt_bar_grow_dir"]             = "Grow direction",
    ["opt_bar_columns"]              = "Columns",
    ["opt_bar_button_size"]          = "Button size",
    ["opt_bar_spacing"]              = "Spacing",
    ["opt_bar_alpha"]                = "Alpha",
    ["opt_bar_scale"]                = "Scale",
    ["opt_bar_display_cond"]         = "Display condition",
    ["opt_bar_fade"]                 = "Enable fade",
    ["opt_bar_fade_out_alpha"]       = "Fade-out alpha",
    ["opt_bar_fade_out_delay"]       = "Fade-out delay",
    ["opt_bar_fade_out_dur"]         = "Fade-out duration",
    ["opt_bar_fade_in_dur"]          = "Fade-in duration",
    ["opt_bar_click_through"]        = "Click-through",
    ["opt_bar_show_empty"]           = "Show empty buttons",
    ["opt_bar_show_hotkey"]          = "Show hotkey text",
    ["opt_bar_disabled"]             = "Disabled",
    -- Bar names
    ["bar_name_bar1"]                = "Bar 1 (Main)",
    ["bar_name_bar2"]                = "Bar 2",
    ["bar_name_bar3"]                = "Bar 3",
    ["bar_name_bar4"]                = "Bar 4",
    ["bar_name_bar5"]                = "Bar 5",
    ["bar_name_bar6"]                = "Bar 6",
    ["bar_name_bar7"]                = "Bar 7",
    ["bar_name_bar8"]                = "Bar 8",
    ["bar_name_pet"]                 = "Pet Bar",
    ["bar_name_stance"]              = "Stance Bar",
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
    ["preview_click_isolate"]         = "click to isolate",
    ["preview_click_show_all"]        = "click to show all",
    ["preview_show_all"]              = "Show All",
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
    ["bagskin_de_tooltip"]               = "|cff2ed884[Right-click]|r Disenchant",
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
    ["opt_tooltip_bg_color"]              = "Background color",
    ["opt_tooltip_border_color"]          = "Border color",
    ["opt_tooltip_font_size"]             = "Font size",
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
    ["btn_cb_toggle_preview"]            = "Show / Hide Preview",
    ["info_cb_preview_hint"]             = "Unlocks every castbar and shows a live mock spell so you can see your tweaks instantly.",
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
    ["pf_opt_readycheck_size"]            = "Ready check icon size",
    ["pf_opt_summon_size"]               = "Summon indicator size",

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
    ["pf_info_cooldowns"]                = "Interrupts are detected via UNIT_SPELLCAST_SUCCEEDED. Battle rez reads the shared combat-res charge pool, so the icon greys out for everyone whenever a brez is used in the instance (no COMBAT_LOG_EVENT_UNFILTERED).",

    -- Resurrection indicator (party)
    ["pf_section_resurrect"]             = "Resurrection Indicator",
    ["pf_opt_show_resurrect"]            = "Show incoming-resurrect icon",
    ["pf_opt_resurrect_size"]            = "Resurrect icon size",
    ["pf_info_resurrect"]                = "Shows a rez icon on a member while a resurrection is being cast on them.",

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
    -- Raid Frames
    -- ═══════════════════════════════════
    ["cat_raidframes"]                   = "Raid Frames",
    ["mover_raidframes"]                 = "Raid Frames",

    -- Tabs
    ["rf_tab_general"]                   = "General",
    ["rf_tab_features"]                  = "Features",

    -- General
    ["rf_section_general"]               = "General",
    ["rf_opt_enable"]                    = "Enable Raid Frames",
    ["rf_info_description"]              = "Custom raid frames with health, absorb, heal prediction, HoTs, debuffs, dispel highlight, defensive CDs, and range check.",
    ["rf_opt_hide_blizzard"]             = "Hide Blizzard raid frames",
    ["rf_opt_sort_role"]                 = "Sort by role (Tank > Healer > DPS)",

    -- Layout
    ["rf_section_layout"]                = "Layout",
    ["rf_opt_layout_mode"]               = "Layout mode",
    ["rf_layout_grid"]                   = "Grid (groups as columns)",
    ["rf_layout_list"]                   = "List (single column)",
    ["rf_opt_width"]                     = "Frame width",
    ["rf_opt_height"]                    = "Frame height",
    ["rf_opt_spacing"]                   = "Spacing",
    ["rf_opt_group_spacing"]             = "Group spacing",

    -- Display
    ["rf_section_display"]               = "Display",
    ["rf_opt_show_name"]                 = "Show name",
    ["rf_opt_name_max_length"]           = "Name max letters",
    ["rf_opt_show_health_text"]          = "Show health text",
    ["rf_opt_health_format"]             = "Health format",
    ["rf_opt_health_color"]              = "Health color mode",
    ["rf_opt_show_role"]                 = "Show role icon",
    ["rf_opt_show_marker"]               = "Show raid marker",
    ["rf_opt_readycheck_size"]            = "Ready check icon size",
    ["rf_opt_summon_size"]               = "Summon indicator size",

    -- Font
    ["rf_section_font"]                  = "Font",
    ["rf_opt_font_size"]                 = "Font size",

    -- Position
    ["rf_section_position"]              = "Position",
    ["rf_info_position"]                 = "Use /tm layout to unlock and drag raid frames.",
    ["rf_btn_reset_position"]            = "Reset Position",
    ["rf_info_test_raid"]                = "Simulate a 20-player raid to preview the layout outside of combat.",
    ["rf_btn_test_raid"]                 = "Simulate 20 Players",
    ["rf_btn_test_raid_stop"]            = "Stop Simulation",
    ["rf_preview_group"]                 = "G",
    ["rf_mode_raid"]                     = "Raid",
    ["rf_mode_solo"]                     = "Solo",

    -- Features: Health
    ["rf_section_health_extras"]         = "Health Features",
    ["rf_opt_show_power"]                = "Show power bar (healers only)",
    ["rf_opt_power_height"]              = "Power bar height",
    ["rf_opt_show_absorb"]               = "Show absorb bar",
    ["rf_opt_show_heal_pred"]            = "Show heal prediction",

    -- Features: Range
    ["rf_section_range"]                 = "Range Check",
    ["rf_opt_show_range"]                = "Fade out-of-range members",
    ["rf_opt_oor_alpha"]                 = "Out-of-range opacity",

    -- Features: Dispel
    ["rf_section_dispel"]                = "Dispel Highlight",
    ["rf_opt_show_dispel"]               = "Highlight dispellable debuffs",

    -- Features: HoTs
    ["rf_section_hots"]                  = "HoT Tracking",
    ["rf_opt_show_hots"]                 = "Show HoT indicators",
    ["rf_opt_hot_size"]                  = "HoT icon size",
    ["rf_opt_max_hots"]                  = "Max HoTs shown",

    -- Features: Debuffs
    ["rf_section_debuffs"]               = "Debuff Tracking",
    ["rf_opt_show_debuffs"]              = "Show debuff icons",
    ["rf_opt_debuff_size"]               = "Debuff icon size",
    ["rf_opt_max_debuffs"]               = "Max debuffs shown",

    -- Features: Defensives
    ["rf_section_defensives"]            = "Defensive Cooldowns",
    ["rf_opt_show_defensives"]           = "Show active defensive buffs",
    ["rf_opt_defensive_size"]            = "Defensive icon size",
    ["rf_info_defensives"]               = "Displays active defensive cooldowns (e.g. Pain Suppression, Ironbark, Divine Shield) on each raid member.",

    -- Resurrection indicator (raid)
    ["rf_section_resurrect"]             = "Resurrection Indicator",
    ["rf_opt_show_resurrect"]            = "Show incoming-resurrect icon",
    ["rf_opt_resurrect_size"]            = "Resurrect icon size",
    ["rf_info_resurrect"]                = "Shows a rez icon on a member while a resurrection is being cast on them (combat-res or normal).",

    -- Battle Rez counter
    ["rf_section_battlerez"]             = "Battle Rez Counter",
    ["rf_opt_br_enable"]                 = "Show battle-rez counter",
    ["rf_opt_br_only_instance"]          = "Only inside dungeons/raids",
    ["rf_opt_br_size"]                   = "Counter size",
    ["rf_opt_br_font"]                   = "Counter font size",
    ["rf_info_battlerez"]                = "A movable counter showing how many battle resurrections are available and the time to the next charge. Reads the shared combat-res pool, so it works on any class. Use /tm layout to move it.",

    -- Per-size layout overrides
    ["rf_section_size_overrides"]        = "Per-Size Layout (10/25/40)",
    ["rf_opt_overrides_enable"]          = "Enable per-size overrides",
    ["rf_info_size_overrides"]           = "When enabled, frame size adapts to the current group size (spacing auto-adjusts per bracket).",
    ["rf_ov_small"]                      = "Small  (up to 10)",
    ["rf_ov_medium"]                     = "Medium  (up to 25)",
    ["rf_ov_large"]                      = "Large  (26-40)",
    ["rf_ov_width"]                      = "Width",
    ["rf_ov_height"]                     = "Height",

    -- ═══════════════════════════════════
    -- Aura Tracker
    -- ═══════════════════════════════════
    ["tab_qol_aura_tracker"]             = "Aura Tracker",
    ["mover_auratracker"]                = "Aura Tracker",
    ["mover_battlerez"]                  = "Battle Rez",

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

    -- =====================
    -- CONFIG: Diagnostics Panel
    -- =====================
    ["section_diagnostics"]              = "Diagnostics",
    ["opt_diag_enabled"]                 = "Enable Error Capture",
    ["opt_diag_capture_all"]             = "Capture All Addons",
    ["opt_diag_suppress_popups"]         = "Suppress Error Popups",
    ["opt_diag_auto_open"]               = "Auto-Open on TomoMod Error",
    ["btn_diag_open_console"]            = "Open Console",
    ["btn_diag_clear"]                   = "Clear Errors",
    ["btn_diag_export"]                  = "Copy Report",
    ["btn_diag_export_tracker"]          = "Export for Tracker",
    ["info_diag_desc"]                   = "Captures Lua errors in the background with zero combat popups. Use /tmdiag to toggle the console.",
    ["info_diag_session"]                = "Session: #%d — %d errors captured (%d TomoMod)",
    ["info_diag_capture_all_desc"]       = "When disabled, only TomoMod errors are captured. Enable to capture all addon errors.",

    -- =====================
    -- HOUSING
    -- =====================
    ["cat_housing"]                  = "Housing",
    ["section_housing_general"]      = "Housing — General",
    ["section_housing_hover"]        = "Decor Info (Hover)",
    ["section_housing_clock"]        = "Editor Clock",
    ["section_housing_teleport"]     = "Teleportation",
    ["section_housing_commands"]     = "Commands",

    ["info_housing_desc"]            = "Housing module: enhances the house editor and adds teleport shortcuts. Requires Midnight / The War Within.",
    ["info_housing_hover"]           = "In Basic Decor mode, shows the name, placement cost and remaining stock of the hovered decor. Also lets you duplicate a decor using a modifier key.",
    ["info_housing_clock"]           = "Displays a clock and tracks time spent in the house editor. Right-click the clock to toggle analog/digital.",
    ["info_housing_teleport"]        = "Enables the /tm home command: teleports you home, or leaves the house automatically if you're visiting.",
    ["info_housing_commands"]        = "• /tm home — teleport to your house (or leave it)\n• /tm housing — open this panel\n• Right-click the clock — toggle analog/digital",

    ["opt_housing_enable"]           = "Enable Housing module",
    ["opt_housing_decorhover"]       = "Enable decor info",
    ["opt_housing_dupe"]             = "Enable quick duplicate (modifier)",
    ["opt_housing_dupekey"]          = "Duplicate key",
    ["opt_housing_clock"]            = "Enable clock",
    ["opt_housing_clock_analog"]     = "Analog mode (otherwise digital)",
    ["opt_housing_teleport"]         = "Enable /tm home teleport",

    ["btn_housing_tp_home"]          = "Teleport (test)",
    ["btn_housing_refresh"]          = "Refresh houses",

    ["housing_duplicate"]            = "Duplicate",
    ["housing_alliance_zone"]        = "Founder's Point",
    ["housing_horde_zone"]           = "Razorwind Shores",
    ["housing_clock_title"]          = "TomoMod — Clock",
    ["housing_clock_time"]           = "Time",
    ["housing_clock_local"]          = "Local time:",
    ["housing_clock_realm"]          = "Realm time:",
    ["housing_clock_time_spent"]     = "Time spent in editor",
    ["housing_clock_session"]        = "This session:",
    ["housing_clock_total"]          = "Total:",
    ["housing_clock_rightclick"]     = "Right-click to toggle analog / digital",
    
    ["msg_help_home"]                = "Teleport to your house (or leave it)",
    ["msg_help_housing"]             = "Open the Housing panel",
    ["msg_housing_refresh"]          = "House information requested.",
    ["msg_housing_unavailable"]      = "Housing module unavailable on this client.",

    -- =========== What's New Popup ===========
    ["wn_title"]                         = "What's New",
    ["wn_version"]                       = "Version %s",
    ["wn_subtitle"]                      = "Here's what changed since your last update:",
    ["wn_btn_ok"]                        = "Got it!",
    ["wn_footer"]                        = "All settings can be changed anytime via |cff2ed884/tm|r.",

    -- 2.9.8
    ["wn_298_housing"]                   = "New Housing module: decoration hover, editor clock and /tm home teleport (Midnight+).",
    ["wn_298_housing_hover"]             = "Decor Hover: shows name, placement cost and remaining stock on hovered decor; modifier key to duplicate.",
    ["wn_298_housing_clock"]             = "Editor Clock: analog/digital clock with per-session and lifetime time tracking.",
    ["wn_298_housing_teleport"]          = "/tm home: teleports to your house or auto-leaves if visiting.",
    ["wn_298_icons"]                     = "New config sidebar icons: house icon for Housing, monitor icon for Diagnostics.",
    ["wn_298_locales"]                   = "Housing + Diagnostics panel: full locale support in frFR, deDE, esES, itIT, ptBR.",

    -- 2.9.6
    ["wn_296_raid_frames"]               = "New Raid Frames module: custom raid frames with grid or list layout.",
    ["wn_296_raid_health"]               = "Health, absorb & heal prediction bars + power bar (healers only).",
    ["wn_296_raid_auras"]                = "Debuff & HoT tracking with type/class colored borders.",
    ["wn_296_raid_utilities"]            = "Defensive CD icons, dispel highlight, range fade, role icons, raid markers & ready check.",
    ["wn_296_raid_config"]               = "Full config panel with General & Features tabs, 80+ locale keys in 6 languages.",

    -- 2.9.7
    ["wn_297_rf_live_preview"]           = "Raid Frames: live preview strip in the config panel — 20 simulated members update in real time.",
    ["wn_297_rf_preview_layout"]         = "Preview shows all layout options: grid (G1–G4 labels) or list (2 columns), with correct roles and HoTs.",
    ["wn_297_rf_preview_scaling"]        = "Preview auto-scales to the panel width; reflects width, height, spacing, color mode, name, power bar and more.",
    ["wn_297_taint_blizzard"]            = "Raid Frames: Blizzard frame hiding rewritten (SetAlpha+SetScale) — fixes CompactPartyFrame & ArenaFrame taint.",
    ["wn_297_range_fix"]                 = "Raid Frames: fade distance fixed for Midnight+ secret booleans (SetAlphaFromBoolean).",
    ["wn_297_actionbars_fix"]            = "Action Bars: initialization deferred past combat lockdown — fixes SecureStateDriver taint on login.",
    ["wn_297_mp_tracker"]                = "Mythic+: ObjectiveTrackerFrame now properly hidden during challenge mode.",
    ["wn_297_role_icon"]                 = "Raid Frames: default role icon size doubled (10 → 20).",
    ["wn_297_castbar_fix"]               = "Castbars: player castbar no longer vanishes mid-combat — FadeOut is now idempotent and transient nil cast info no longer hides the bar.",
    ["wn_297_diag_exclusions"]           = "Diagnostics: mount restriction and battle pet cap messages excluded from error capture.",

    -- 2.9.5
    ["wn_295_taint_fix"]                 = "CooldownTrackers: removed COMBAT_LOG_EVENT_UNFILTERED to fix taint (ADDON_ACTION_FORBIDDEN).",
    ["wn_295_diag_taint"]                = "Diagnostics: taint errors now always captured, even with diagnostics disabled.",
    ["wn_295_tooltip_ids_moved"]         = "Tooltip IDs options moved from QOL panel to Skins > Tooltip tab.",
    ["wn_295_chat_text_offset"]          = "Chat Frame Skin: text slightly shifted right to clear the sidebar.",

    -- 2.9.4
    ["wn_294_installer"]                 = "Installer expanded from 12 to 16 guided steps.",
    ["wn_294_uf_pf"]                     = "New steps: Unit Frames & Party Frames configuration.",
    ["wn_294_cb_res"]                    = "New steps: Castbars & Resources / Cooldown Manager.",
    ["wn_294_skins_qol"]                 = "Enhanced Skins step (bags, tooltips) and QOL step (minimap, cursor, AFK, diagnostics, aura tracker).",
    ["wn_294_bugfixes"]                  = "Secret value fixes for TooltipIDs & CooldownTrackers (Midnight taint).",
    ["wn_294_locales"]                   = "50+ new locale keys across all 6 languages.",

    -- 2.9.3
    ["wn_293_partyframe"]                = "Party Frames: ready check icons, tooltip on hover, raid marker rewrite.",
    ["wn_293_actionbar_fix"]             = "ActionBars: bars 1-4 interactivity fix, show empty buttons fix.",
    ["wn_293_chat_taint"]                = "Chat Frame Skin: Midnight taint fixes (secret GUID/BN guards).",
    ["wn_293_diagnostics"]               = "Diagnostics: pattern-based exclusion, 6-locale keyword fallback.",
    ["wn_293_autofill"]                  = "AutoFillDelete: Midnight STATICPOPUP_NUMDIALOGS fix.",

    -- 2.9.2
    ["wn_292_actionbar"]                 = "Complete ActionBars rewrite: container architecture, fade system, display conditions.",
    ["wn_292_diagnostics"]               = "New Diagnostics Console: background error capture, export, /tmdiag.",

    -- ═══════════════════════════════════
    -- Merchant Tools (2.9.9)
    -- ═══════════════════════════════════
    ["wn_299_merchant_tools"]             = "New Vendor Tools module: Already Known + Extended Vendor Pages (QOL tab).",
    ["wn_299_already_known"]              = "Already Known: grays out or tints vendor/buyback items you already own (mounts, pets, toys, transmog, recipes).",
    ["wn_299_extend_pages"]               = "Extended Pages: expands the merchant window to show up to 4 columns of 10 items each.",
    ["wn_299_locales"]                    = "Vendor Tools: full locale support in all 6 languages.",
    ["wn_299_lustsound"]                   = "LustSound: fixed false sound alert triggered by brief Sated flicker during server resync or zone transitions.",

    ["tab_qol_merchant_tools"]           = "Vendor Tools",

    -- Consumable Bar (3.0.4)
    ["tab_qol_consumable_bar"]           = "Consumables",
    ["section_consumable_bar"]           = "Consumable Bar",
    ["info_cb_desc"]                     = "Shows an icon + timer for each active consumable: flask (1h), well fed (1h), and weapon oil (2h). The off-hand oil slot is shown only when a weapon is equipped in the off-hand.",
    ["opt_cb_enable"]                    = "Enable consumable bar",
    ["opt_cb_show_missing"]              = "Show missing buffs (dimmed ghost)",
    ["opt_cb_icon_size"]                 = "Icon size",
    ["opt_cb_gap"]                       = "Gap between icons",
    ["opt_cb_orientation"]               = "Orientation",
    ["cb_orient_horizontal"]             = "Horizontal",
    ["cb_orient_vertical"]               = "Vertical",
    ["opt_cb_timer_pos"]                 = "Timer position",
    ["cb_timerpos_below"]                = "Below (horizontal)",
    ["cb_timerpos_above"]                = "Above (horizontal)",
    ["cb_timerpos_right"]                = "Right (vertical)",
    ["cb_timerpos_left"]                 = "Left (vertical)",
    ["mover_consumable_bar"]             = "Consumable Bar",

    ["section_already_known"]            = "Already Known",
    ["info_already_known"]               = "Desaturates or tints vendor/buyback items you already own (mounts, pets, toys, transmog sets, recipes).",
    ["opt_ak_enable"]                    = "Enable Already Known",
    ["opt_ak_mode"]                      = "Display mode",
    ["ak_mode_mono"]                     = "Monochrome (gray)",
    ["ak_mode_color"]                    = "Color tint",
    ["opt_ak_color"]                     = "Tint color",

    ["section_extend_pages"]             = "Extend Vendor Pages",
    ["info_extend_pages"]                = "Adds extra columns to the merchant window to show more items per page.\nRequires a UI reload after enabling or changing column count.",
    ["opt_ep_enable"]                    = "Enable extended vendor pages",
    ["opt_ep_columns"]                   = "Number of columns",

    -- Presets
    ["preset_complet_name"]  = "Recommended",
    ["preset_complet_tag"]   = "The full TomoMod experience",
    ["preset_complet_desc"]  = "Enables every core module with sensible defaults: unit frames, party & raid frames, nameplates, castbars, resources, action bar skin, all visual skins, Mythic+ tools and the most useful quality-of-life features. The best starting point for most players.",
    ["preset_tank_name"]     = "Tank",
    ["preset_tank_tag"]      = "Threat-focused, wider nameplates",
    ["preset_tank_desc"]     = "The Recommended setup, tuned for tanking: threat-colored nameplates (Tank Mode) and slightly wider plates for better threat readability, plus the target threat indicator.",
    ["preset_healer_name"]   = "Healer",
    ["preset_healer_tag"]    = "Bigger raid frames, mana visible",
    ["preset_healer_desc"]   = "The Recommended setup, tuned for healing: larger, more clickable raid & party frames with power (mana) bars shown, HoT tracking, dispel highlights and defensive cooldowns front and center.",
    ["preset_dps_name"]      = "DPS",
    ["preset_dps_tag"]       = "Emphasized resources & cooldowns",
    ["preset_dps_desc"]      = "The Recommended setup, tuned for damage: a more prominent resource bar, target buff tracking for enemy defensives, and clean nameplates without tank threat coloring.",
    ["preset_minimal_name"]  = "Minimal",
    ["preset_minimal_tag"]   = "Just the essentials",
    ["preset_minimal_desc"]  = "A lightweight footprint: keeps unit frames, party & raid frames, castbars, resource bars, the minimap and the most essential automations — everything cosmetic (skins, chat, bags, nameplates, extra panels) stays off. Closest to a vanilla feel.",
    ["preset_custom_name"]   = "Custom",
    ["preset_custom_tag"]    = "Configure everything yourself",
    ["preset_custom_desc"]   = "Skip the presets and walk through every category step by step to enable exactly what you want. You can always change anything later from /tm.",
    ["preset_applied"]       = "Preset applied: %s — type /reload to see the result.",
    ["preset_unknown"]       = "Unknown preset '%s'. Available: complet, tank, healer, dps, minimal.",
    ["preset_usage"]         = "Usage: /tmpreset <complet|tank|healer|dps|minimal>",
    -- Installeur v3
    ["ins_v3_welcome_desc"]      = "Welcome! This quick setup gets you a clean, complete interface in seconds.\n\nPick a setup that matches how you play — you can fine-tune everything afterwards from |cff2ed884/tm|r. Prefer to choose every option yourself? Pick |cffc89530Custom|r.",
    ["ins_pick_title"]           = "Choose your setup",
    ["ins_pick_subtitle"]        = "Select a play style below. Everything stays adjustable later via /tm.",
    ["ins_pick_recommended"]     = "Recommended",
    ["ins_custom_frames_title"]  = "Frames",
    ["ins_custom_barsskins_title"] = "Bars & Skins",
    ["ins_custom_mythicqol_title"] = "Mythic+ & Comfort",
    ["ins_custom_frames_intro"]  = "Enable the frames you want. Sensible options are pre-selected.",
    ["ins_custom_barsskins_intro"] = "Action bar skin and the visual skins for chat, bags, tooltips and more.",
    ["ins_custom_mythicqol_intro"] = "Mythic+ tools, interface extras, automations and sound.",
    ["ins_recap_title"]          = "All set",
    ["ins_recap_preset"]         = "Setup applied: |cff2ed884%s|r",
    ["ins_recap_custom"]         = "Your custom setup is ready",
    ["ins_recap_desc"]           = "Reload your interface to apply everything. You can reopen this assistant anytime with |cff2ed884/tm install|r, and open the full configuration panel with |cff2ed884/tm|r.",
    -- Accueil / recherche
    ["cat_accueil"]              = "Home",
    ["ui_search_placeholder"]    = "Search modules...",
    ["dash_welcome"]             = "Quick overview of TomoMod. Toggle modules, apply a setup, switch profile, or relaunch the setup assistant.",
    ["dash_modules_section"]     = "Modules",
    ["dash_quickcfg_section"]    = "Quick configuration",
    ["dash_profile_section"]     = "Profile",
    ["dash_maint_section"]       = "Maintenance",
    ["dash_reload_hint"]         = "Toggling modules writes your settings — reload to apply module changes.",
    ["dash_reload_now"]          = "Reload now",
    ["dash_apply_preset"]        = "Setup preset",
    ["dash_apply_preset_btn"]    = "Apply this preset",
    ["dash_apply_preset_info"]   = "Applying a preset resets which modules are on or off, then reloads.",
    ["dash_active_profile"]      = "Active profile",
    ["dash_manage_profiles"]     = "Manage profiles",
    ["dash_profile_info"]        = "Switching profile reloads the interface to apply it.",
    ["dash_relaunch_info"]       = "Reopens the presets-first setup assistant.",
    ["dash_mod_resources"]       = "Resources",
    ["dash_mod_cdm"]             = "Cooldown Manager",
    ["dash_mod_abskin"]          = "Action bar skin",
    ["dash_mod_chatskin"]        = "Chat skin",
    ["dash_mod_bagskin"]         = "Bag skin",
    ["dash_mod_mtracker"]        = "Mythic+ tracker",
    ["dash_mod_score"]           = "Mythic+ score",
    ["dash_reload_popup"]        = "Reload the interface now to apply your changes?",

    -- ═══════════════════════════════════
    -- MythicTracker EJ Boss Names (2.9.10)
    -- ═══════════════════════════════════
    -- ═══════════════════════════════════
    -- Smart Waypoint (2.9.20)
    -- ═══════════════════════════════════
    ["wn_2920_waypoint_redirect"]       = "Smart Waypoint — cross-zone redirect: the waypoint now tracks the next path step on your current map (portal, dungeon entrance) via C_SuperTrack.GetNextWaypointForMap(), updated on SUPER_TRACKING_PATH_UPDATED and zone changes.",
    ["wn_2920_waypoint_blob"]           = "Smart Waypoint — stuck 0 m fix: the beacon now hides automatically when the player is inside the quest objective area (C_Minimap.IsInsideQuestBlob), preventing the waypoint from freezing at 0 m.",
    ["wn_2920_waypoint_label"]          = "Smart Waypoint — dynamic label: the destination now shows the redirect step description (e.g. 'Travel to Durotar') or the tracked quest title instead of a blank field.",

    -- ═══════════════════════════════════
    -- Objective Tracker Stability (2.9.19)
    -- ═══════════════════════════════════
    ["wn_2919_antiflicker"]             = "Anti-flicker — eliminated the visible 'trembling' of the Objective Tracker caused by a feedback loop between TomoMod's bucket layout and Blizzard's native Update / MarkDirty hooks. New re-entry guard, deferred pump coalescing, and a 0.20 s post-layout silence window break the recursion.",
    ["wn_2919_collapsed_persist"]       = "Collapsed bucket persistence — quest blocks under a collapsed bucket header no longer reappear when Blizzard re-runs its layout; each block gets a one-time Show hook that re-hides it while its bucket is folded.",
    ["wn_2919_header_detection"]        = "Module header detection — accent- and case-insensitive matching (Métier / métier / MÉTIER all resolve to the same keyword) and added singular variants. Quest titles and objective lines are now explicitly excluded so the full quest description is never accidentally hidden.",
    ["wn_2919_recipe_height"]           = "Recipe block height — Profession recipe blocks no longer overlap the next quest. The deepest-descendant measurement now runs unconditionally and walks 8 levels deep to reach reagent FontStrings (TrackedRecipe → Lines → Line[i]).",
    ["wn_2919_reward_preview"]          = "Reward preview exclusion — Delves (e.g. 'La Sombrevoie'), M+ scenarios, world quest reward popups and weekly vault reward blocks (e.g. 'Halte de l'Ombre-Garde' with ilvl preview) are now skipped from the bucket system. They stay in Blizzard's native location and no longer overlap our quests.",

    -- ═══════════════════════════════════
    -- Objective Tracker Quest Buckets (2.9.18)
    -- ═══════════════════════════════════
    ["wn_2918_buckets"]                 = "Objective Tracker quest buckets — quests, world quests, weeklies, dailies, dungeons, raids, professions and achievements are now grouped into collapsible categories with colored headers and live count badges.",
    ["wn_2918_bucket_toggle"]           = "New 'Group quests into collapsible categories' checkbox in Config → Skins → Objective Tracker; disabling it instantly restores Blizzard's native module layout, no /reload required.",
    ["wn_2918_tracker_width"]           = "Tracker panel widened by 10 px so quest item icons no longer clip against the right edge.",
    ["wn_2918_layout_fix"]              = "Re-parented quest blocks now anchor both TOPLEFT and TOPRIGHT to prevent width collapse, and stale heights after collapse/expand are corrected via multi-pass layout.",

    -- ═══════════════════════════════════
    -- Installer Overhaul & AB Toggle (2.9.17)
    -- ═══════════════════════════════════
    ["wn_2917_ab_master_toggle"]        = "Action Bar master toggle — a new 'Enable TomoMod Action Bar system' checkbox in the Installer and Config Panel lets you fully disable bar management; after /reload, Blizzard's default action bars are fully restored.",
    ["wn_2917_installer_raid"]          = "Installer step 5 — Raid Frames: enable/disable, hide Blizzard frames, dispel highlights, HoT tracking, debuff icons, defensive CDs, and grid/list layout selection.",
    ["wn_2917_installer_coverage"]      = "Installer expanded — Skins step now includes Objective Tracker, Mail, and Reputation Bar; QOL step adds Auto Summon, Auto Quest, Class Reminder, Leveling Bar, Waypoint, World Quests, Frame Anchors, and Profession Helper.",
    ["wn_2917_chat_skin_fix"]           = "Chat Skin fix — the installer was writing to an orphan 'chatSkin' key instead of the actual 'chatFrameSkin' key, making the toggle non-functional.",
    ["wn_2917_talking_head_fix"]        = "HideTalkingHead fix — the module now checks its DB toggle before suppressing the TalkingHead frame, instead of applying unconditionally.",
    ["wn_2917_minimal_style"]           = "Action Bar 'Minimal' style — the 5th skin style (borderless with inner shadows) was missing from the Installer dropdown despite being implemented; now selectable.",

    -- ═══════════════════════════════════
    -- AuctionRecipeTracker (2.9.15)
    -- ═══════════════════════════════════
    ["wn_2916_layout_fix"]              = "Layout button silent failure fixed — on a fresh install, clicking 'Layout' did nothing because the mover system never completed initialization. Toggle now lazy-initializes via pcall and surfaces any error to chat instead of failing silently.",
    ["wn_2916_safe_init"]               = "Module init chain hardening — every TomoMod module Initialize() call is now wrapped in xpcall via a safeInit helper; a single failing module no longer breaks the ~45 modules that init after it, and the offending module is reported in chat.",
    ["wn_2916_art_total"]               = "AuctionRecipeTracker — each tracked recipe header now shows the global total cost of its reagents on the right side; if at least one reagent has no recorded price, a grey (~) suffix indicates the total is a partial estimate.",
    ["wn_2916_avr_gui"]                 = "Auto Vendor / Repair GUI — two new checkboxes in Config → QOL → Automations let you toggle auto-repair on merchant and auto-sale of gray (poor) items independently; settings are persisted in TomoModDB and apply live without /reload.",
    ["wn_2915_art_module"]              = "New QOL module — AuctionRecipeTracker: a GUI opens automatically at the auctioneer when at least one crafting recipe is tracked; reagent rows show '14x icon Item name price' with click-to-search and a manual full AH scan button.",
    ["wn_2915_art_tooltip"]             = "TomoHDV tooltip line — after a scan, every item tooltip (bags, bank, chat links, equipment) shows the recorded unit price plus the full stack price when stack > 1, and how long ago the scan was made.",
    ["wn_2915_art_scrollbar"]           = "Modern TomoMod scrollbar — the default Blizzard scrollbar is replaced by a 4px slim track with an accent-coloured thumb sized proportionally to the content; supports drag, click-on-track to jump, mouse wheel, and auto-hides when content fits.",
    ["wn_2915_art_anchor"]              = "AuctionRecipeTracker default anchor — the frame attaches to the right edge of the Auction House window (TOPLEFT, AuctionHouseFrame, TOPRIGHT, 8, 0); user-dragged positions remain persisted and override the default.",
    ["wn_2915_art_scan_fix"]            = "Scan button reliability — OnShow now resets scanInProgress, re-enables the button and restores its label; silent early-returns (scan in progress, AH closed, API missing) now display a red status message instead of doing nothing.",

    -- ═══════════════════════════════════
    -- MythicTracker Boss Names Fix (2.9.13)
    -- ═══════════════════════════════════
    ["wn_2913_boss_names"]               = "MythicTracker: boss names now display correctly instead of \"Boss 1\", \"Boss 2\" etc. — in WoW 12.x the scenario criteria field was renamed from criteriaString to description; TomoMod now reads description first with a criteriaString fallback.",
    ["wn_2913_boss_checkmark"]           = "MythicTracker: Blizzard's leading checkmark prefix (added to completed boss objectives in 12.x) is now stripped before display.",
    ["wn_2913_ej_pcall"]                 = "MythicTracker: EncounterJournal_OpenJournal call in FetchEJBossNames is now wrapped in pcall to prevent potential taint in 12.x.",

    -- ═══════════════════════════════════
    -- PartyFrame CD Fix + Performance (2.9.12)
    -- ═══════════════════════════════════
    ["wn_2912_party_cd_fix"]             = "PartyFrame: interrupt & battle-rez CD tracking now uses UNIT_SPELLCAST_SUCCEEDED with taint-safe spellID resolution (string.format strip); COMBAT_LOG_EVENT_UNFILTERED removed — registering it from addon code causes taint in 12.x.",
    ["wn_2912_healer_interrupt"]         = "PartyFrame: interrupt tracker icon now hidden for healers — since patch 12.x healers no longer have an interrupt ability.",
    ["wn_2912_perf_cdm"]                 = "CooldownManager: UpdateButtonState now caches GetCooldownTimes, GetCachedCooldownID and GetCooldownViewerCooldownInfo once per button per tick instead of calling each twice; ~50% fewer API calls in the main update loop.",
    ["wn_2912_perf_aura"]                = "AuraTracker: timer refresh rate reduced from 10 fps (0.1 s) to 5 fps (0.2 s); no visible difference on screen, halves ticker overhead.",
    ["wn_2912_perf_resbars"]             = "ResourceBars: DK rune / Monk stagger OnUpdate threshold raised from 50 ms to 100 ms; halves execution frequency with no perceptible impact on display.",

    -- ═══════════════════════════════════
    -- CooldownManager / ProcGlow / BuffSkin Fixes (2.9.11)
    -- ═══════════════════════════════════
    ["wn_2911_cdm_hooks"]                = "CooldownManager: swipe colors + GCD hiding merged into a single hook per button; GCD detection now uses Scanner cache instead of pcall(C_CooldownViewer).",
    ["wn_2911_procglow_fixes"]           = "CDMProcGlow: glow applied synchronously in ShowAlert to prevent race with same-frame HideAlert; per-frame tickers replaced by a single global persistence ticker; RefreshAll now correctly filters live procs.",
    ["wn_2911_buffskin_fixes"]           = "BuffSkin: SkinButton re-applies icon anchors/masks on Blizzard-recycled frames; hooks installed once via hooksInstalled guard (toggle enable/disable now works); TemporaryEnchantFrame hooked for weapon enchant updates; hooks installed immediately.",

    -- ═══════════════════════════════════
    -- MythicTracker EJ Boss Names (2.9.10)
    -- ═══════════════════════════════════
    ["wn_2910_ej_boss_names"]            = "MythicTracker: boss names resolved via the Encounter Journal — localised, accent-safe, covering all dungeons from Cata to The War Within.",
    ["wn_2910_ej_fallback"]              = "MythicTracker: 3-level name resolution — dungeonEncounterID > EJ index > filtered criteriaString, with automatic retry (\195\2275) if the EJ isn't loaded yet.",

    -- =====================
    -- AuctionRecipeTracker
    -- =====================
    ["art_title"]            = "Recipe Tracker",
    ["art_no_recipes"]       = "No tracked recipes — track a recipe in your profession window.",
    ["art_status_idle"]      = "Click an ingredient to search the AH.",
    ["art_scan_btn"]         = "Scan Auction House",
    ["art_scan_running"]     = "Scanning...",
    ["art_scan_started"]     = "Scan started — please wait...",
    ["art_scan_done"]        = "Scan finished: %d items recorded.",
    ["art_scan_failed"]      = "Scan failed or interrupted.",
    ["art_scan_cooldown"]    = "Next scan available in %dm %ds.",
    ["art_scan_tip_title"]   = "Full Auction House scan",
    ["art_scan_tip_desc"]    = "Records the lowest buyout per item. Limited to once every 15 minutes.",
    ["art_only_at_ah"]       = "Open the Auction House first.",
    ["art_scan_already"]     = "A scan is already in progress.",
    ["art_tt_stack"]         = "Stack",
    ["art_tt_scanned"]       = "Scanned",
    ["art_tt_just_now"]      = "just now",
    ["art_tt_min_ago"]       = "%dm ago",
    ["art_tt_hour_ago"]      = "%dh ago",
    ["art_tt_day_ago"]       = "%dd ago",

    -- Player Auras Mover (v2.9.5)
    ["mover_player_auras"]       = "Player Auras",
    ["opt_auras_spacing"]        = "Icon Spacing",
    ["btn_reset_aura_position"]  = "Reset Aura Position",

    -- Module Reload Safety (v2.9.21)
    ["msg_module_reload"]        = "This change requires a UI reload to take effect.\nReload now?",
    ["info_module_reload"]       = "Requires /reload to take effect.",
    ["wn_2921_aura_mover"]       = "Player auras now have their own mover in Layout mode (tinted overlay, label, independent drag & drop).",
    ["wn_2921_aura_gui"]         = "New aura spacing slider and position reset button in the Auras GUI tab.",
    ["wn_2921_reload_safety"]    = "Enabling/disabling a major module (UnitFrames, Nameplates, Castbars, ActionBars, Party, Raid) now prompts an automatic /reload.",

    -- Waypoint Arrow Reversed (v2.9.22)
    ["wn_2922_waypoint_arrow"]    = "Off-screen waypoint navigator arrow is now on the opposite side of the orbit: when your goal is ahead, the arrow sits at the bottom and points up toward it.",

    -- What's New 3.0.4
    ["wn_304_consumable_bar"]    = "ConsumableBar — new QOL module showing Flask and Well Fed buff icons with countdown timers. Fully configurable (size, gap, orientation, timer position) and draggable in Layout Mode.",
    ["wn_304_cursor_textures"]   = "Cursor Ring — two new textures added (Cygle and Heart). Texture selector available in General → Cursor Ring.",
    ["wn_304_mythichub_tp"]      = "MythicHub teleport fixed — no more taint (ADDON_ACTION_FORBIDDEN) or anchor errors when clicking dungeon rows. Spell IDs for Maisara Caverns and Windrunner Spire also corrected.",

    -- What's New 3.0.3
    ["wn_303_tracking_panel"]    = "Custom tracking panel — clicking the tracking button now opens a TomoMod-styled panel to the left of the minimap instead of the native Blizzard dropdown.",
    ["wn_303_collector_panel"]   = "Collector panel redesign — addon buttons are now grouped in a proper TomoMod panel (dark bg, teal title, class-color border) anchored left of the minimap.",
    ["wn_303_collector_autoclose"] = "Collector auto-closes 0.5 s after login/reload once buttons are captured — the panel stays clean on entry and reopens normally on click.",
    ["wn_303_tooltip_fix"]       = "Tooltip skin fix — the large black rectangle that appeared when hovering units or spells has been resolved.",
    ["wn_303_coords_pos"]        = "Minimap coordinates moved to bottom-center for better readability.",

    -- What's New 3.0
    ["wn_300_installer"]  = "Brand-new setup assistant — presets-first: pick Recommended, Tank, Healer, DPS, Minimal or Custom and you're set up in seconds.",
    ["wn_300_presets"]    = "Setup presets — one click applies a coherent, role-tuned configuration across every module; reusable anytime from /tm.",
    ["wn_300_dashboard"]  = "New Home dashboard in /tm — quick module toggles, relaunch the assistant, apply a preset, switch profile and reset, all in one place.",
    ["wn_300_search"]     = "Searchable sidebar — filter config categories by name or keyword (type 'heal', 'cd', 'bag'…).",
    ["wn_300_minimap"]    = "Minimap button — quick access to TomoMod features and settings.",
    ["wn_300_buttonbag"]  = "Button Bag — consolidate and manage your action buttons efficiently.",

    -- =====================
    -- QOL: Rare Alert (RareAlert.lua)
    -- =====================
    ["tab_qol_rare_alert"]       = "Rare Alert",
    ["section_rare_alert"]       = "Rare Alert",
    ["opt_rare_alert_enable"]    = "Enable rare proximity alerts",
    ["opt_rare_alert_sound"]     = "Play alert sound",
    ["opt_rare_alert_duration"]  = "Banner display duration (s)",
    ["btn_reset_rare_alert_pos"] = "Reset banner position",
    ["rare_alert_info"]          = "Alerts you when a rare NPC is nearby. Click the banner to target it, place the skull marker and set a waypoint. Right-click to dismiss. Use /tm layout to move the banner.",
    ["rare_alert_tooltip"]       = "Left-click: target + place skull + waypoint. Right-click: dismiss.",

    -- 3.0.5
    ["wn_305_rare_alert"]        = "RareAlert — new QOL module: a sound and a clickable banner when a rare NPC is nearby (vignette-based). Open-world only — never in dungeons or raids.",
    ["wn_305_rare_alert_marker"] = "Click the rare banner to target it, place the Skull marker and set a waypoint. Configurable sound and duration; draggable in Layout Mode.",
    ["wn_305_tm_fix"]            = "Fixed — clicking a RareScanner rare alert no longer opens the TomoMod config (the /tm slash-command collision is resolved).",

    -- =====================
    -- Extra Action Button (v3.0.6)
    -- =====================
    ["mover_ab_extra"] = "Extra Action",
    ["section_extra_button"] = "Extra Action Button",
    ["opt_extra_enabled"] = "Manage the Extra Action Button (reload to release)",
    ["opt_extra_scale"] = "Extra button scale",
    ["btn_extra_reset_pos"] = "Reset position",
    ["info_extra_button"] = "Position the extra action button in Layout Mode. It appears during quests and encounters. Disabling releases it back to Blizzard after a /reload.",
    ["wn_306_extra_button"] = "New — the Extra Action Button is now part of the TomoMod action bar system.",
    ["wn_306_extra_mover"] = "New — reposition the extra action button (and the zone-ability button) in Layout Mode, just like any other bar. Position and scale are saved to your profile.",
    ["wn_306_extra_scale"] = "New — Extra Action Button options under Action Bars, Bar Management tab: enable, scale and reset position.",
    ["wn_306_compass"] = "Fix — Compass: corrected a high-frequency Lua error (x417) in the world-coordinate conversion (C_Map.GetWorldPosFromMapPos returns continentID + worldPosition; the continentID is now correctly discarded).",
    ["wn_306_bagskin"] = "BagSkin — slot buttons now use Blizzard's native ContainerFrameItemButtonTemplate: click, use, pickup and split are handled by secure native code (no more taint-prone PreClick). Slots deferred during combat are replayed automatically when combat ends.",
    -- 3.0.7
    ["wn_307_objective_tracker"] = "Objective Tracker — World Quest blocks are now sorted into the World Quests bucket instead of floating above the tracker. Progress bars (enemy forces, weekly %) are hidden when their bucket is collapsed.",
    ["wn_307_guardian_rage"]     = "ResourceBars — Guardian Druids now see their Rage bar centered on screen by default. Mana stays as the secondary bar. The UnitFrame power bar is hidden automatically.",
    ["wn_307_resource_bars"]     = "ResourceBars — Fixed: class power and druid mana height sliders now apply correctly (global frame name conflict resolved). New slider for centered primary power bar height. New checkbox in UnitFrames › Player › Dimensions to route the power bar to the center.",
    ["wn_310_brez_counter"]       = "Battle Rez Counter — New movable HUD showing how many combat resurrections are available and the time to the next charge. Reads the shared pool, works on any class. Configure in Raid Frames → Features.",
    ["wn_310_resurrect"]          = "Resurrection Indicator — A rez icon now appears on a party or raid member while a resurrection is being cast on them.",
    ["wn_310_raid_sizes"]         = "Raid Frames — New optional per-size layouts (10 / 25 / 40): frame width and height adapt automatically to the current group size. Configure in Raid Frames → Features.",
    ["wn_310_brez_fix"]           = "Party Frames — Fixed the battle rez cooldown tracker: the icon now correctly greys out and shows the recharge timer whenever a brez is consumed by anyone in the instance.",

    -- 3.1.1
    ["art_searching"]        = "Searching: %s",
    ["art_searching_qty"]    = "Searching: %s × %d",
    ["wn_311_icicles"]        = "Frost Mage: new Icicles tracker in the Resource Bar (5 segments + Glacial Spike glow when full). Custom color available in CD & Resource → Colors.",
    ["wn_311_taint_money"]   = "Fixed a Midnight taint error: hovering items in the Encounter Journal no longer throws a 'secret number' error on the gold value — TomoMod no longer taints item-comparison tooltips.",
    ["wn_311_art_qty"]       = "AuctionRecipeTracker: clicking a reagent searches the Auction House and shows the required quantity in the status bar (e.g. Searching: Awakened Fire × 14).",

    -- 3.1.2
    ["wn_312_brand"]         = "Brand color updated from #0cd29f to #2ed884 (mint green) across the entire UI — title bar, panels, chat messages, popups and default color values.",
    ["wn_312_brand_api"]     = "New TomoMod_Utils.BRAND / BRAND_DARK / BRAND_HOVER constants centralise the accent color: Config panels and the Widget theme now read from a single source of truth.",
    ["wn_312_companion_fix"] = "CompanionStatus: fixed a global variable leak (UpdateIcon was declared without 'local').",

    -- 3.1.3
    ["wn_313_nav"]        = "Config UI redesigned: 16 panels consolidated into 6 grouped categories (Interface, Units, Combat, Comfort, Tools), each with its own accent color and a page header.",
    ["wn_313_accent"]     = "Widgets now auto-adopt the accent color of their host panel — cards, headers, separators, checkboxes, buttons and tabs all react to the active category context.",
    ["wn_313_segmented"]  = "New SegmentedControl widget replaces short dropdowns (Bag Bar, Micro Menu, Chat Skin, Bag Layout, Sort, Audio Channel).",
    ["wn_313_dashboard"]  = "Accueil dashboard rewritten: hero banner with live diagnostics status, quick-action shortcuts (Installer, Profiles, Diagnostics, Reload) and redesigned module toggles.",
    ["wn_313_np_preview"] = "Nameplates: new live preview panel at the top of the config — shows ally, hostile and boss plates, updates in real-time as you adjust width, height, cast bar and font size.",
    ["wn_313_loot_filter"] = "Loot class filter fix: items missing from the IDB (e.g. new raid drops) now fall back to armor-type matching instead of being shown for all classes.",
    ["wn_313_sporefall"]   = "Loot data: Sporefall raid (ejEncounterID 2711) added with 15 items from KeystoneLoot build 12.0.7.",
    ["wn_313_diag"]       = "Diagnostics: 7 new UIError exclusion keywords (merchant, mount, inventory, delete, upgrade, appearance, duel) + console now always appears above the config menu.",
    ["wn_313_tooltip_anchor"] = "Tooltip position: new 4-mode anchor system — Default, Cursor (follows mouse), Corner (pinned to a screen corner) and Custom (drag-to-place frame).",

    -- Tooltip anchor
    ["opt_tooltip_anchor"]        = "Tooltip position",
    ["tooltip_anchor_default"]    = "Default",
    ["tooltip_anchor_cursor"]     = "Cursor",
    ["tooltip_anchor_corner"]     = "Screen corner",
    ["tooltip_anchor_custom"]     = "Custom",
    ["opt_tooltip_anchor_corner"] = "Corner (corner mode)",
    ["corner_br"]                 = "Bottom right",
    ["corner_bl"]                 = "Bottom left",
    ["corner_tr"]                 = "Top right",
    ["corner_tl"]                 = "Top left",
    ["info_tooltip_anchor"]       = "Custom: select this mode then drag the teal frame to the desired position.",

    -- Nameplates preview
    ["np_preview_title"]   = "Nameplate Preview",
    ["np_preview_hint"]    = "Quick readability: color, cast bar, auras and threat all in one place.",
    ["preview_np_friendly"] = "Ally",
    ["preview_np_target"]  = "Hostile target",
    ["preview_np_boss"]    = "Marked boss",

    -- 3.1.4
    ["wn_314_tooltip_anchor"] = "Tooltip position: new 4-mode anchor — Default, Cursor (follows mouse), Corner (screen corner) and Custom (drag-to-place frame). Configure in Skins → Tooltip.",
    ["wn_314_locale_fix"]     = "Fixed missing tooltip color labels: background and border color pickers in Skins → Tooltip now display correctly in all languages.",
})
