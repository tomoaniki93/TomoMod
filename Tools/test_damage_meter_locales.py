import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DM_LOCALES = ("enUS", "frFR", "deDE", "esES", "itIT", "ptBR")
DM_NEW_KEYS = {
    "BENCHMARK_TITLE",
    "BENCHMARK_TIP",
    "BENCHMARK_READY",
    "BENCHMARK_ARMED",
    "BENCHMARK_WAIT_DATA",
    "BENCHMARK_RUNNING",
    "BENCHMARK_COMPLETE",
    "BENCHMARK_CANCELLED",
    "BENCHMARK_NO_DAMAGE",
    "BENCHMARK_DURATION",
    "BENCHMARK_AUTO_DUMMY_ON",
    "BENCHMARK_AUTO_DUMMY_OFF",
    "BENCHMARK_START",
    "BENCHMARK_STOP",
    "BENCHMARK_DPS",
    "BENCHMARK_DAMAGE",
    "BENCHMARK_TOP5",
    "BENCHMARK_CLEAR",
    "BENCHMARK_EMPTY",
    "BENCHMARK_COL_PLAYER",
    "BENCHMARK_COL_SPEC",
    "BENCHMARK_COL_ILVL",
    "BENCHMARK_COL_TIME",
    "BENCHMARK_COL_DATE",
    "CMD_HELP_BENCHMARK",
    "FIGHT_HISTORY",
    "FIGHT_HISTORY_TIP",
    "FIGHT_HISTORY_ALL",
    "FIGHT_HISTORY_BOSSES",
    "FIGHT_HISTORY_CLEAR",
    "FIGHT_HISTORY_EMPTY",
    "FIGHT_HISTORY_DAMAGE",
    "FIGHT_HISTORY_HEALING",
    "FIGHT_HISTORY_BOSS",
    "FIGHT_HISTORY_TRASH",
    "FIGHT_HISTORY_PLAYER",
    "FIGHT_HISTORY_INTERRUPTS",
    "FIGHT_HISTORY_DEATHS",
    "FIGHT_HISTORY_PREV",
    "FIGHT_HISTORY_NEXT",
    "FIGHT_HISTORY_KILL",
    "FIGHT_HISTORY_WIPE",
    "HISTORY_GUI",
    "HISTORY_GUI_DESC",
    "DM_HISTORY_BENCHMARK",
    "DM_HISTORY_BENCHMARK_DESC",
}
WHATS_NEW_KEYS = {
    "wn_406_damage_benchmark",
    "wn_406_fight_history",
    "wn_406_damage_tools_access",
}


def locale_keys(path):
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r'^L\["([^"]+)"\]\s*=', text, re.MULTILINE))


class DamageMeterLocaleTests(unittest.TestCase):
    def test_all_six_damage_meter_locales_have_matching_keys(self):
        key_sets = {
            locale: locale_keys(ROOT / "Modules" / "DamageMeter" / "Locales" / f"{locale}.lua")
            for locale in DM_LOCALES
        }
        english = key_sets["enUS"]
        for locale, keys in key_sets.items():
            self.assertEqual(english, keys, locale)
            self.assertTrue(DM_NEW_KEYS <= keys, locale)

    def test_whats_new_highlights_exist_in_every_locale(self):
        locale_text = (ROOT / "Locales" / "Locale_406.lua").read_text(encoding="utf-8")
        whats_new_text = (ROOT / "Core" / "WhatsNew.lua").read_text(encoding="utf-8")
        for key in WHATS_NEW_KEYS:
            self.assertEqual(6, locale_text.count(f'["{key}"] ='), key)
            self.assertEqual(1, whats_new_text.count(f'L["{key}"]'), key)


if __name__ == "__main__":
    unittest.main()
