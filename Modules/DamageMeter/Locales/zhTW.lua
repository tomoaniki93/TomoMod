local ADDON_NAME, TomoMod = ...

-- [MERGE] Standalone, `ns` was this addon's own private table. Embedded, the
-- vararg hands over TomoMod's, which every other file in the suite shares --
-- so 157 generic names (db, L, FONT, BG, ACCENT, Refresh, windows, inCombat)
-- would sit in the same table as everything TomoMod ever adds. Nothing
-- collides today, but the first core file that reaches for `ns.db` would
-- find this module's and neither would know.
--
-- One sub-table keeps the module's world to itself, and leaves every `ns.X`
-- below untouched.
local ns = TomoMod.DM

----------------------------------------------------------------------
-- Localization: Traditional Chinese
----------------------------------------------------------------------

if GetLocale() ~= "zhTW" then return end

local L = ns.L

-- General
L["ADDON_NAME"] = "TomoDamageMeter"
L["ADDON_SHORT"] = "Tomo"

-- Meter types
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["DAMAGE_TAKEN"] = "承受傷害"
L["AVOIDABLE"] = "可避免傷害"
L["ENEMY_DAMAGE"] = "敵人傷害"
L["ABSORBS"] = "吸收"
L["INTERRUPTS"] = "中斷"
L["DISPELS"] = "驅散"
L["DEATHS"] = "死亡"

-- Categories
L["DAMAGE"] = "傷害"
L["HEALING"] = "治療"
L["ACTIONS"] = "動作"

-- Sessions
L["CURRENT"] = "目前"
L["OVERALL"] = "總計"

-- Header / UI
L["RESET"] = "重置"
L["LOCK"] = "鎖定"
L["UNLOCK"] = "解鎖"
L["SETTINGS"] = "設定"
L["REPORT"] = "回報"
L["CLOSE"] = "關閉"

-- Format labels
L["FMT_COMPACT"] = "精簡"
L["FMT_1DEC"] = "1位小數"
L["FMT_2DEC"] = "2位小數"
L["FMT_REGULAR"] = "標準"
L["FMT_INT"] = "整數"
L["FMT_DEC"] = "小數"

-- Report
L["REPORT_HEADER"] = "TomoDamageMeter：%s (%s)"
L["REPORT_NO_TARGET"] = "沒有密語對象。請先選擇一名玩家。"
L["REPORT_NO_DATA"] = "沒有可回報的資料。"
L["REPORT_CHANNEL_SAY"] = "說話"
L["REPORT_CHANNEL_PARTY"] = "隊伍"
L["REPORT_CHANNEL_RAID"] = "團隊"
L["REPORT_CHANNEL_GUILD"] = "公會"
L["REPORT_CHANNEL_WHISPER"] = "密語"
L["REPORT_CHANNEL_AUTO"] = "自動（隊伍）"
L["REPORT_CHANNEL_INSTANCE"] = "副本"
L["REPORT_CHANNEL_SELF"] = "僅自己可見"
L["REPORT_CHANNEL_RESTRICTED"] = "「說話」和「大喊」受遊戲限制：每次點擊只能送出一則插件訊息。請在設定中選擇隊伍頻道。"

-- Settings
L["SETTINGS_TITLE"] = "TomoDamageMeter 設定"
L["SETTINGS_GENERAL"] = "一般"
L["SETTINGS_APPEARANCE"] = "外觀"
L["SETTINGS_SKIN"] = "樣式"
L["SETTINGS_BAR_TEXTURE"] = "狀態條材質"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "極簡"
L["SKIN_GLOSSY"] = "光澤"
L["SKIN_EMBER"] = "餘燼"
L["SKIN_FROST"] = "霜"
L["SKIN_TERMINAL"] = "終端"
L["SKIN_VOID"] = "虛空"
L["SKIN_PARCHMENT"] = "羊皮紙"
L["SETTINGS_COLUMNS"] = "欄位"
L["SETTINGS_FONT_SIZE"] = "字型大小"
L["SETTINGS_FONT_FACE"] = "字型"
L["SETTINGS_BAR_HEIGHT"] = "長條高度"
L["SETTINGS_BG_OPACITY"] = "背景不透明度"
L["SETTINGS_OOC_OPACITY"] = "脫離戰鬥不透明度"
L["SETTINGS_BREAKDOWN_OPACITY"] = "技能詳情不透明度"
L["SETTINGS_OPACITY"] = "不透明度"
L["SETTINGS_RECAPS"] = "回顧"
L["SETTINGS_SHOW_SELF"] = "永遠顯示我的條目"
L["SETTINGS_BAR_TOOLTIPS"] = "條目提示"
L["SETTINGS_TIMER_POS"] = "計時器位置"
L["SETTINGS_TIMER_LEFT"] = "左側"
L["SETTINGS_TIMER_RIGHT"] = "右側"
L["SETTINGS_AUTO_RESET"] = "進入副本時重置"
L["SETTINGS_DEATH_RECAP_AUTO"] = "自動顯示死亡回顧"
L["DM_STANDALONE"] = "已安裝獨立的 TomoDamageMeter 插件並由其接管；其設定在它自己的視窗中。內建模組保持停用。"
L["DM_UNAVAILABLE"] = "此客戶端不提供暴雪傷害統計，模組未啟用。"
L["DM_WINDOWS_HINT"] = "欄位、新增視窗與分類篩選在統計視窗中設定。"
L["DM_OPEN_WINDOW_SETTINGS"] = "視窗設定"
L["DM_TOGGLE_WINDOWS"] = "顯示 / 隱藏"
L["SETTINGS_STRIP_REALM"] = "隱藏伺服器名稱"
L["SETTINGS_ACCENT_COLOR"] = "主題色"
L["SETTINGS_USE_CLASS_COLOR"] = "使用職業顏色"
L["SETTINGS_REPORT_CHANNEL"] = "回報頻道"
L["SETTINGS_REPORT_LINES"] = "回報行數"
L["SETTINGS_WINDOWS"] = "視窗"
L["SETTINGS_ADD_WINDOW"] = "+ 新增"
L["SETTINGS_REMOVE_WINDOW"] = "- 移除"
L["SETTINGS_WINDOW_COUNT"] = "視窗：%d / %d"
L["SETTINGS_COL_RATE"] = "速率 (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "總計"
L["SETTINGS_COL_PCT"] = "百分比"
L["SETTINGS_TAB_GENERAL"] = "一般"
L["SETTINGS_TAB_WINDOW"] = "視窗 %d"
L["SETTINGS_METER_TYPE"] = "統計類型"
L["SETTINGS_SESSION_TYPE"] = "階段類型"
L["SETTINGS_LOCKED"] = "鎖定位置"

-- Slash commands
L["CMD_RESET"] = "資料已重置。"
L["CMD_LOCKED"] = "已鎖定"
L["CMD_UNLOCKED"] = "已解鎖"
L["CMD_HELP_HEADER"] = "指令："
L["CMD_HELP_TOGGLE"] = "  /tdm — 開啟設定"
L["CMD_HELP_TOGGLE_VIS"] = "  /tdm toggle — 切換視窗顯示"
L["CMD_HELP_RESET"] = "  /tdm reset — 重置所有戰鬥資料"
L["CMD_HELP_LOCK"] = "  /tdm lock — 鎖定/解鎖視窗位置"
L["CMD_HELP_HELP"] = "  /tdm help — 顯示此訊息"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "進入副本時自動重置"
L["SETTINGS_COMBAT_TIMER"] = "戰鬥計時器 (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "釘選我的條目"
L["SETTINGS_BAR_TOOLTIPS"] = "長條提示（懸停）"
L["SETTINGS_MODULES"] = "模組"
L["SETTINGS_DEATH_RECAP_AUTO"] = "死亡時彈出死亡回顧"
L["SETTINGS_TIMER_POSITION"] = "戰鬥計時器位置"
L["TIMER_POS_RIGHT"] = "右"
L["TIMER_POS_LEFT"] = "左"
L["SETTINGS_CATEGORIES"] = "類別"
L["SETTINGS_CATEGORIES_MIN"] = "至少需保留一個類別。"
L["AUTO_RESET_MSG"] = "資料已自動重置（進入副本）。"

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "戰鬥中無法使用設定。"
L["WAITING_COMBAT_END"] = "戰鬥結束後才可使用"

-- Detail
L["SPELL_BREAKDOWN"] = "技能詳情"
L["NO_DATA"] = "沒有可用資料"
L["DEATH_RECAP"] = "死亡回顧"
L["DEATH_RECAP_NO_DATA"] = "沒有死亡記錄"
L["RECAP_HEAL"] = "治療"
L["RECAP_MELEE"] = "近戰"
L["RECAP_UNKNOWN"] = "未知"
L["BREAKDOWN_SPELLS_LABEL"] = "技能"
L["BREAKDOWN_CRITS_LABEL"] = "爆擊"
L["BREAKDOWN_CRIT_RATE_LABEL"] = "爆擊"
L["BREAKDOWN_COL_SPELL"] = "技能"
L["BREAKDOWN_COL_TOTAL"] = "總計"

-- Segments / Target Breakdown
L["SEGMENTS"] = "戰鬥階段"
L["SEGMENT"] = "階段"
L["SEGMENT_COL_NAME"] = "遭遇戰"
L["TARGET_BREAKDOWN"] = "目標詳情"
L["TARGET_COL_NAME"] = "目標"

-- Tooltips
L["TIP_SETTINGS"] = "開啟設定"
L["TIP_TARGET"] = "目標詳情"
L["TIP_DETAILS"] = "技能詳情"
L["TIP_LOCK"] = "鎖定/解鎖位置"
L["TIP_REPORT"] = "回報到聊天"
L["TIP_RESET"] = "重置所有資料"
L["TIP_CATEGORY"] = "點擊切換類別"
L["TIP_TYPE"] = "點擊切換統計類型"
L["TIP_SESSION"] = "點擊切換階段"

-- 懸停提示
L["TIP_TOP_SPELLS"] = "主要技能"
L["TIP_TOTAL"] = "總計"
L["TIP_OVERKILL"] = "溢出傷害"
L["TIP_AVOIDABLE"] = "可避免傷害"
L["TIP_KILLING_BLOW"] = "致命一擊"
L["TIP_CAST_BY"] = "由 %s 施放"
L["TIP_CLICK_BREAKDOWN"] = "點擊查看技能詳情"
L["TIP_LEFT_EXPAND"] = "左鍵：內嵌顯示技能"
L["TIP_RIGHT_WINDOW"] = "右鍵：開啟詳情視窗"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"
L["FILTER_PLAYERS"] = "篩選..."

L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

L["FMT_3DEC"] = "3位小數"
L["SETTINGS_FORMAT"] = "格式"
L["SETTINGS_SNAP"] = "視窗互相吸附"
L["SETTINGS_RUN_RECAP_AUTO"] = "副本結束時顯示總結"
L["RUN_RECAP"] = "本次總結"
L["RUN_RECAP_NO_DATA"] = "沒有紀錄"
L["RECAP_COL_INT"] = "打斷"
L["RECAP_COL_DEATHS"] = "死亡"
L["RECAP_COL_AVOIDABLE"] = "可避免"
L["CMD_HELP_RECAP"] = "  /tdm recap — 顯示上次總結"
L["CMD_HELP_DIAG"] = "  /tdm diag — 檢測 C_DamageMeter 數值可讀性"
L["CMD_DIAG_ARMED"] = "診斷已就緒 — 等待下一次戰鬥資料更新。"

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — 將死亡回顧移回中央"
L["CMD_POS_RESET"] = "死亡回顧位置已重置。"
