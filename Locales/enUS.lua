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
    ["cat_profiles"]        = "Profiles",

    -- =====================
    -- CONFIG: General Panel
    -- =====================
    ["section_about"]                   = "About",
    ["about_text"]                      = "|cff0cd29fTomoMod|r v2.1.10 by TomoAniki\nLightweight interface with QOL, UnitFrames and Nameplates.\nType /tm help for the command list.",
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
    ["btn_reset_position"]              = "Reset Position",

    -- Cursor Ring
    ["section_cursor_ring"]             = "Cursor Ring",
    ["opt_class_color"]                 = "Class color",
    ["opt_anchor_tooltip_ring"]         = "Anchor Tooltip + Show Ring",

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
    ["opt_show_threat"]                 = "Threat indicator",
    ["opt_show_leader_icon"]            = "Leader icon",
    ["opt_leader_icon_x"]               = "Leader icon X",
    ["opt_leader_icon_y"]               = "Leader icon Y",

    -- Castbar
    ["opt_castbar_enable"]              = "Enable castbar",
    ["opt_castbar_width"]               = "Castbar width",
    ["opt_castbar_height"]              = "Castbar height",
    ["opt_castbar_show_icon"]           = "Show icon",
    ["opt_castbar_show_timer"]          = "Show timer",

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
    ["info_cdm_description"]            = "Reskins Blizzard CooldownManager icons: 1px borders, class overlay when active, custom CD text, centered buff alignment. Placement via Blizzard Edit Mode.",
    ["opt_cdm_show_hotkeys"]            = "Show hotkeys",
    ["opt_cdm_combat_alpha"]            = "Modify opacity (combat / target)",
    ["opt_cdm_alpha_combat"]            = "In-combat alpha",
    ["opt_cdm_alpha_target"]            = "With target alpha (out of combat)",
    ["opt_cdm_alpha_ooc"]               = "Out of combat alpha",
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
    ["opt_skyride_bar_height"]          = "Bar height",
    ["opt_font_size"]                   = "Font size",
    ["btn_reset_skyride"]               = "Reset SkyRide Position",

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
    ["btn_reset_all_reload"]            = "⚠ RESET ALL + Reload",
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
    ["msg_help_cr"]                     = "Lock/unlock Combat Res Tracker",
    ["msg_help_cs"]                     = "Lock/unlock Character Sheet position",
    ["msg_help_cs_reset"]               = "Reset Character Sheet to default position",

    -- CharacterSheet
    ["tab_qol_charsheet"]               = "Char Sheet",
    ["section_charsheet"]               = "Character Sheet",
    ["opt_cs_enabled"]                  = "Enable Character Sheet enhancements",
    ["opt_cs_dark_mode"]                = "Dark mode (clean visual)",
    ["opt_cs_scale"]                    = "Window scale",
    ["btn_cs_reset_pos"]                = "Reset position",
    ["cat_char_sheet"]                  = "Character Sheet",
    ["section_cs_item_overlay"]         = "Item Overlay",
    ["opt_cs_show_item_name"]           = "Show item name",
    ["opt_cs_show_ilvl"]                = "Show item level & upgrade track",
    ["opt_cs_show_enchant"]             = "Show enchantment text",
    ["opt_cs_show_gems"]                = "Show gem icons",
    ["opt_cs_show_missing"]             = "Highlight missing enchants & gems (red)",
    ["cs_drag_to_move"]                 = "Drag to move",
    ["cs_lock_hint"]                    = "/tm cs to lock",
    ["cs_locked"]                       = "Character Sheet |cffff5555locked|r",
    ["cs_unlocked"]                     = "Character Sheet |cff00ff00unlocked|r — drag title bar to move",
    ["cs_pos_reset"]                    = "Character Sheet position reset",

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
})