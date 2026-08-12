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
-- Localization: Russian
----------------------------------------------------------------------

if GetLocale() ~= "ruRU" then return end

local L = ns.L

-- General
L["ADDON_NAME"] = "TomoDamageMeter"
L["ADDON_SHORT"] = "Tomo"

-- Meter types
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["DAMAGE_TAKEN"] = "Полученный урон"
L["AVOIDABLE"] = "Избегаемый"
L["ENEMY_DAMAGE"] = "Урон по врагам"
L["ABSORBS"] = "Поглощение"
L["INTERRUPTS"] = "Прерывания"
L["DISPELS"] = "Рассеивания"
L["DEATHS"] = "Смерти"

-- Categories
L["DAMAGE"] = "Урон"
L["HEALING"] = "Исцеление"
L["ACTIONS"] = "Действия"

-- Sessions
L["CURRENT"] = "Текущий"
L["OVERALL"] = "Общий"

-- Header / UI
L["RESET"] = "Сброс"
L["LOCK"] = "Закрепить"
L["UNLOCK"] = "Открепить"
L["SETTINGS"] = "Настройки"
L["REPORT"] = "Отчет"
L["CLOSE"] = "Закрыть"

-- Format labels
L["FMT_COMPACT"] = "Компактный"
L["FMT_1DEC"] = "1 знак"
L["FMT_2DEC"] = "2 знака"
L["FMT_REGULAR"] = "Обычный"
L["FMT_INT"] = "Цел."
L["FMT_DEC"] = "Дроб."

-- Report
L["REPORT_HEADER"] = "TomoDamageMeter: %s (%s)"
L["REPORT_NO_TARGET"] = "Нет цели для шепота. Сначала выберите игрока."
L["REPORT_NO_DATA"] = "Нет данных для отчета."
L["REPORT_CHANNEL_SAY"] = "Сказать"
L["REPORT_CHANNEL_PARTY"] = "Группа"
L["REPORT_CHANNEL_RAID"] = "Рейд"
L["REPORT_CHANNEL_GUILD"] = "Гильдия"
L["REPORT_CHANNEL_WHISPER"] = "Шепот"
L["REPORT_CHANNEL_AUTO"] = "Авто (группа)"
L["REPORT_CHANNEL_INSTANCE"] = "Подземелье"
L["REPORT_CHANNEL_SELF"] = "Только для себя"
L["REPORT_CHANNEL_RESTRICTED"] = "Каналы «Сказать» и «Кричать» ограничены игрой: за одно нажатие проходит только одно сообщение. Выберите групповой канал в настройках."

-- Settings
L["SETTINGS_TITLE"] = "Настройки TomoDamageMeter"
L["SETTINGS_GENERAL"] = "Общие"
L["SETTINGS_APPEARANCE"] = "Внешний вид"
L["SETTINGS_SKIN"] = "Скин"
L["SETTINGS_BAR_TEXTURE"] = "Текстура полос"
L["SKIN_DARK"] = "Tomo Dark"
L["SKIN_NEON"] = "Tomo Neon"
L["SKIN_MINIMAL"] = "Минимал"
L["SKIN_GLOSSY"] = "Глянец"
L["SKIN_EMBER"] = "Уголь"
L["SKIN_FROST"] = "Иней"
L["SKIN_TERMINAL"] = "Терминал"
L["SKIN_VOID"] = "Бездна"
L["SKIN_PARCHMENT"] = "Пергамент"
L["SETTINGS_COLUMNS"] = "Столбцы"
L["SETTINGS_FONT_SIZE"] = "Размер шрифта"
L["SETTINGS_FONT_FACE"] = "Шрифт"
L["SETTINGS_BAR_HEIGHT"] = "Высота полос"
L["SETTINGS_BG_OPACITY"] = "Непрозрачность фона"
L["SETTINGS_OOC_OPACITY"] = "Непрозрачность вне боя"
L["SETTINGS_BREAKDOWN_OPACITY"] = "Непрозрачность детализации"
L["SETTINGS_STRIP_REALM"] = "Скрывать имена миров"
L["SETTINGS_ACCENT_COLOR"] = "Акцентный цвет"
L["SETTINGS_USE_CLASS_COLOR"] = "Цвет класса"
L["SETTINGS_REPORT_CHANNEL"] = "Канал отчета"
L["SETTINGS_REPORT_LINES"] = "Строк в отчете"
L["SETTINGS_WINDOWS"] = "Окна"
L["SETTINGS_ADD_WINDOW"] = "+ Добавить"
L["SETTINGS_REMOVE_WINDOW"] = "- Удалить"
L["SETTINGS_WINDOW_COUNT"] = "Окна: %d / %d"
L["SETTINGS_COL_RATE"] = "Темп (DPS/HPS)"
L["SETTINGS_COL_TOTAL"] = "Всего"
L["SETTINGS_COL_PCT"] = "Процент"
L["SETTINGS_TAB_GENERAL"] = "Общие"
L["SETTINGS_TAB_WINDOW"] = "Окно %d"
L["SETTINGS_METER_TYPE"] = "Тип счетчика"
L["SETTINGS_SESSION_TYPE"] = "Тип сессии"
L["SETTINGS_LOCKED"] = "Закрепить положение"

-- Slash commands
L["CMD_RESET"] = "Данные сброшены."
L["CMD_LOCKED"] = "Закреплено"
L["CMD_UNLOCKED"] = "Откреплено"
L["CMD_HELP_HEADER"] = "Команды:"
L["CMD_HELP_TOGGLE"] = "  /tdm — открыть настройки"
L["CMD_HELP_TOGGLE_VIS"] = "  /tdm toggle — показать/скрыть окно"
L["CMD_HELP_RESET"] = "  /tdm reset — сбросить все данные боя"
L["CMD_HELP_LOCK"] = "  /tdm lock — закрепить/открепить положение окна"
L["CMD_HELP_HELP"] = "  /tdm help — это сообщение"

-- Auto-reset
L["SETTINGS_AUTO_RESET_INSTANCE"] = "Автосброс при входе в подземелье"
L["SETTINGS_COMBAT_TIMER"] = "Таймер боя (DPS/HPS)"
L["SETTINGS_SELF_BAR"] = "Закрепить свою строку"
L["SETTINGS_BAR_TOOLTIPS"] = "Подсказки полос (наведение)"
L["SETTINGS_MODULES"] = "Модули"
L["SETTINGS_DEATH_RECAP_AUTO"] = "Показывать разбор смерти при смерти"
L["SETTINGS_TIMER_POSITION"] = "Положение таймера боя"
L["TIMER_POS_RIGHT"] = "Справа"
L["TIMER_POS_LEFT"] = "Слева"
L["SETTINGS_CATEGORIES"] = "Категории"
L["SETTINGS_CATEGORIES_MIN"] = "Хотя бы одна категория должна оставаться включенной."
L["AUTO_RESET_MSG"] = "Данные сброшены автоматически (вход в подземелье)."

-- Combat
L["COMBAT_SETTINGS_UNAVAILABLE"] = "Настройки недоступны в бою."
L["WAITING_COMBAT_END"] = "Недоступно до окончания боя"

-- Detail
L["SPELL_BREAKDOWN"] = "Детализация заклинаний"
L["NO_DATA"] = "Нет данных"
L["DEATH_RECAP"] = "Разбор смерти"
L["DEATH_RECAP_NO_DATA"] = "Смертей не зафиксировано"
L["RECAP_HEAL"] = "Лечение"
L["RECAP_MELEE"] = "Ближний бой"
L["RECAP_UNKNOWN"] = "Неизвестно"
L["BREAKDOWN_SPELLS_LABEL"] = "закл."
L["BREAKDOWN_CRITS_LABEL"] = "крит."
L["BREAKDOWN_CRIT_RATE_LABEL"] = "крит"
L["BREAKDOWN_COL_SPELL"] = "Заклинание"
L["BREAKDOWN_COL_TOTAL"] = "Всего"

-- Segments / Target Breakdown
L["SEGMENTS"] = "Сегменты"
L["SEGMENT"] = "Сегмент"
L["SEGMENT_COL_NAME"] = "Бой"
L["TARGET_BREAKDOWN"] = "Детализация целей"
L["TARGET_COL_NAME"] = "Цель"

-- Tooltips
L["TIP_SETTINGS"] = "Открыть настройки"
L["TIP_TARGET"] = "Детализация целей"
L["TIP_DETAILS"] = "Детализация заклинаний"
L["TIP_LOCK"] = "Закрепить/открепить положение"
L["TIP_REPORT"] = "Отчет в чат"
L["TIP_RESET"] = "Сбросить все данные"
L["TIP_CATEGORY"] = "Нажмите, чтобы сменить категорию"
L["TIP_TYPE"] = "Нажмите, чтобы сменить тип"
L["TIP_SESSION"] = "Нажмите, чтобы сменить сессию"

-- Подсказки при наведении
L["TIP_TOP_SPELLS"] = "Лучшие способности"
L["TIP_TOTAL"] = "Всего"
L["TIP_OVERKILL"] = "Избыточный урон"
L["TIP_AVOIDABLE"] = "Избегаемый урон"
L["TIP_KILLING_BLOW"] = "Смертельный удар"
L["TIP_CAST_BY"] = "Применил: %s"
L["TIP_CLICK_BREAKDOWN"] = "Нажмите для разбора способностей"
L["TIP_LEFT_EXPAND"] = "ЛКМ: показать способности в строке"
L["TIP_RIGHT_WINDOW"] = "ПКМ: открыть окно разбора"

-- Font names
L["FONT_FRIZ"] = "Fritz Quadrata"
L["FONT_ARIAL"] = "Arial Narrow"
L["FONT_2002"] = "2002"
L["FONT_MORPHEUS"] = "Morpheus"
L["FONT_SKURRI"] = "Skurri"
L["FILTER_PLAYERS"] = "Фильтр..."

L["ADDON_PREFIX"] = "|cffe0115fTomo DM :|r "

L["FMT_3DEC"] = "3 знака"
L["SETTINGS_FORMAT"] = "Формат"
L["SETTINGS_SNAP"] = "Прикреплять окна друг к другу"
L["SETTINGS_RUN_RECAP_AUTO"] = "Показывать итоги в конце подземелья"
L["RUN_RECAP"] = "Итоги забега"
L["RUN_RECAP_NO_DATA"] = "Забег не записан"
L["RECAP_COL_INT"] = "Преры."
L["RECAP_COL_DEATHS"] = "Смерти"
L["RECAP_COL_AVOIDABLE"] = "Изб."
L["CMD_HELP_RECAP"] = "  /tdm recap — показать последние итоги забега"
L["CMD_HELP_DIAG"] = "  /tdm diag — проверить читаемость значений C_DamageMeter"
L["CMD_DIAG_ARMED"] = "Диагностика активна — ожидание следующего обновления боевых данных."

L["CMD_HELP_RESETPOS"] = "  /tdm resetpos — вернуть обзор смерти в центр"
L["CMD_POS_RESET"] = "Положение обзора смерти сброшено."
