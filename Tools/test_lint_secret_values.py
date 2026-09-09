#!/usr/bin/env python3
# =====================================================================
# Tools/test_lint_secret_values.py -- banc de non-regression du linter
#
# A linter nobody trusts gets ignored, and a linter that goes quiet
# after a refactor is worse than none: it reports "0 findings" and
# everyone believes it. So this suite checks both directions.
#
#   - Detection: each violation shape is caught.
#   - Silence: each guard shape actually silences it.
#   - Mutation: the guards are load-bearing. Every "clean" fixture is
#     re-run with its guard stripped, and the suite fails if the linter
#     stays quiet. A test that passes for the wrong reason is exactly
#     what mutation testing exists to expose.
#
# Usage:  python3 Tools/test_lint_secret_values.py
# =====================================================================

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lint_secret_values as L  # noqa: E402


# ---------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------

SECRET = {"UnitHealth", "UnitHealthMax", "C_Thing.Get", "UnitClass"}


def run(src, secret=None, geometry=False):
    """Lint a source string; return the list of findings.

    `secret` is compared against None rather than tested for truth: an
    empty set is a legitimate argument ("nothing is secret") and `or`
    would quietly swap it for the default, which is how the mutation
    test below first failed.
    """
    tokens, suppressed = L.tokenize(src)
    if secret is None:
        secret = SECRET
    return L.analyse("t.lua", tokens, suppressed, secret, geometry)


def kinds(src, **kw):
    return sorted(f.kind for f in run(src, **kw))


def evidence(src):
    tokens, suppressed = L.tokenize(src)
    return L.harvest_evidence([("t.lua", tokens, suppressed)])


# ---------------------------------------------------------------------
# lexer
# ---------------------------------------------------------------------

class TestLexer(unittest.TestCase):

    def test_short_comment_is_dropped(self):
        toks, _ = L.tokenize("local a = 1 -- local b = 2\nlocal c = 3")
        names = [t.value for t in toks if t.kind == "NAME"]
        self.assertEqual(names, ["a", "c"])

    def test_long_comment_is_dropped_including_end_keyword(self):
        # An `end` inside a comment would close a block that never
        # opened, and every scope after it would be wrong.
        toks, _ = L.tokenize("--[[ end end end ]]\nlocal a = 1")
        self.assertEqual([t.value for t in toks if t.kind == "KEYWORD"], ["local"])

    def test_long_comment_with_level(self):
        toks, _ = L.tokenize("--[==[ ]] still comment ]==]\nlocal a = 1")
        self.assertEqual([t.value for t in toks if t.kind == "NAME"], ["a"])

    def test_double_dash_inside_string_is_not_a_comment(self):
        toks, _ = L.tokenize('local s = "-- not a comment"\nlocal b = 1')
        self.assertIn("b", [t.value for t in toks if t.kind == "NAME"])

    def test_long_string_is_one_token(self):
        toks, _ = L.tokenize("local s = [[ end end ]]\nlocal b = 1")
        self.assertEqual([t.value for t in toks if t.kind == "KEYWORD"], ["local", "local"])

    def test_escaped_quote_does_not_end_string(self):
        toks, _ = L.tokenize('local s = "a\\"b"\nlocal c = 1')
        self.assertIn("c", [t.value for t in toks if t.kind == "NAME"])

    def test_operator_longest_match(self):
        toks, _ = L.tokenize("a <= b")
        self.assertIn("<=", [t.value for t in toks if t.kind == "OP"])

    def test_suppression_marker_is_recorded(self):
        _, sup = L.tokenize("local a = 1 -- @secret-ok\n")
        self.assertIn(1, sup)

    def test_unterminated_long_bracket_raises(self):
        with self.assertRaises(L.LuaLexError):
            L.tokenize("--[[ never closed")

    def test_line_numbers_survive_long_comments(self):
        toks, _ = L.tokenize("--[[\n\n\n]]\nlocal a = 1")
        a = [t for t in toks if t.value == "a"][0]
        self.assertEqual(a.line, 5)


# ---------------------------------------------------------------------
# block scoping
# ---------------------------------------------------------------------

class TestScoping(unittest.TestCase):

    def _depth(self, src):
        st = L.ScopeStack()
        for t in L.tokenize(src)[0]:
            st.feed(t)
        return len(st.frames)

    def test_balanced_function(self):
        self.assertEqual(self._depth("function f() end"), 1)

    def test_for_do_end_counts_once(self):
        # `for ... do ... end` has one `end` for two keywords. Counting
        # the `do` separately leaves the stack permanently deeper.
        self.assertEqual(self._depth("for i = 1, 10 do end"), 1)

    def test_while_do_end_counts_once(self):
        self.assertEqual(self._depth("while x do end"), 1)

    def test_bare_do_block_counts(self):
        self.assertEqual(self._depth("do end"), 1)

    def test_repeat_until(self):
        self.assertEqual(self._depth("repeat x = 1 until x"), 1)

    def test_nested_mix_is_balanced(self):
        src = """
        function f()
            for i = 1, 3 do
                if x then
                    while y do end
                else
                    do end
                end
            end
            repeat until true
        end
        """
        self.assertEqual(self._depth(src), 1)

    def test_taint_dies_with_its_block(self):
        src = """
        function a()
            local hp = UnitHealth("player")
        end
        function b()
            local x = hp + 1
        end
        """
        self.assertEqual(run(src), [])


# ---------------------------------------------------------------------
# detection
# ---------------------------------------------------------------------

class TestDetection(unittest.TestCase):

    def test_arithmetic(self):
        self.assertEqual(kinds('local hp = UnitHealth("p")\nlocal x = hp + 1'),
                         ["arithmetic"])

    def test_division(self):
        self.assertEqual(kinds('local hp = UnitHealth("p")\nlocal x = hp / 2'),
                         ["arithmetic"])

    def test_ordering_comparison(self):
        self.assertEqual(kinds('local hp = UnitHealth("p")\nif hp > 0 then end'),
                         ["ordering comparison"])

    def test_equality_is_allowed(self):
        # Equality on a secret leaks no ordering and does not throw.
        # Reporting it would bury the findings that matter.
        self.assertEqual(run('local hp = UnitHealth("p")\nif hp == 0 then end'), [])

    def test_concatenation(self):
        self.assertEqual(kinds('local hp = UnitHealth("p")\nlocal s = "hp: " .. hp'),
                         ["concatenation"])

    def test_table_index(self):
        self.assertEqual(kinds('local c = UnitClass("p")\nlocal x = COLORS[c]'),
                         ["table index"])

    def test_length_operator(self):
        self.assertEqual(kinds('local c = UnitClass("p")\nlocal n = #c'),
                         ["length operator"])

    def test_unsafe_consumer_tonumber(self):
        self.assertEqual(kinds('local v = C_Thing.Get()\nlocal n = tonumber(v)'),
                         ["unsafe consumer"])

    def test_unsafe_consumer_math_floor(self):
        self.assertEqual(kinds('local v = C_Thing.Get()\nlocal n = math.floor(v)'),
                         ["unsafe consumer"])

    def test_unsafe_consumer_string_format(self):
        self.assertEqual(kinds('local v = C_Thing.Get()\nlocal s = string.format("%d", v)'),
                         ["unsafe consumer"])

    def test_inline_call_into_comparison(self):
        self.assertEqual(kinds('if UnitHealth("p") > 0 then end'),
                         ["ordering comparison"])

    def test_multiple_returns_are_all_tainted(self):
        src = 'local a, b = UnitClass("p")\nlocal x = T[b]'
        self.assertEqual(kinds(src), ["table index"])

    def test_plain_call_is_not_a_source(self):
        self.assertEqual(run('local x = SomethingElse()\nlocal y = x + 1'), [])

    def test_one_report_per_variable_per_block(self):
        # Repeating the same variable ten times says nothing new and
        # would hide the next distinct problem underneath it.
        src = 'local hp = UnitHealth("p")\nlocal a = hp + 1\nlocal b = hp + 2\nlocal c = hp + 3'
        self.assertEqual(len(run(src)), 1)


# ---------------------------------------------------------------------
# guards and silence
# ---------------------------------------------------------------------

class TestGuards(unittest.TestCase):

    def test_issecretvalue_silences(self):
        src = ('local hp = UnitHealth("p")\n'
               'if issecretvalue(hp) then return end\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])

    def test_lowercase_local_alias_silences(self):
        # ResourceBars.lua spells it `issecret`; a fixed name list would
        # have missed every guard in that file.
        src = ('local hp = UnitHealth("p")\n'
               'if not issecret(hp) then local x = hp + 1 end')
        self.assertEqual(run(src), [])

    def test_underscore_alias_silences(self):
        src = ('local hp = UnitHealth("p")\n'
               'if _issecret(hp) then return end\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])

    def test_namespaced_guard_silences(self):
        src = ('local hp = UnitHealth("p")\n'
               'if U.IsSecret(hp) then return end\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])

    def test_has_secret_value_silences(self):
        src = ('local hp = UnitHealth("p")\n'
               'if Helpers.HasSecretValue(hp) then return end\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])

    def test_sanitiser_result_is_clean(self):
        src = ('local hp = Plain(UnitHealth("p"))\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])

    def test_sanitiser_pattern_matches_new_helpers(self):
        src = ('local hp = U.SafeWhateverNew(UnitHealth("p"))\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])

    def test_passing_into_a_sanitiser_is_not_a_finding(self):
        src = ('local hp = UnitHealth("p")\n'
               'local clean = SafeToNumber(hp, 0)\n'
               'local x = clean + 1')
        self.assertEqual(run(src), [])

    def test_suppression_comment_on_same_line(self):
        src = ('local hp = UnitHealth("p")\n'
               'local x = hp + 1 -- @secret-ok\n')
        self.assertEqual(run(src), [])

    def test_suppression_comment_on_previous_line(self):
        src = ('local hp = UnitHealth("p")\n'
               '-- @secret-ok\n'
               'local x = hp + 1\n')
        self.assertEqual(run(src), [])

    def test_reassignment_from_plain_call_clears_taint(self):
        src = ('local hp = UnitHealth("p")\n'
               'hp = Fallback()\n'
               'local x = hp + 1')
        self.assertEqual(run(src), [])


# ---------------------------------------------------------------------
# geometry tier
# ---------------------------------------------------------------------

class TestGeometryTier(unittest.TestCase):

    SRC = 'local l = frame:GetLeft()\nlocal x = l - 1'

    def test_geometry_is_quiet_by_default(self):
        self.assertEqual(run(self.SRC), [])

    def test_geometry_reports_when_asked(self):
        self.assertEqual(kinds(self.SRC, geometry=True), ["arithmetic"])

    def test_geometry_call_is_consumed_once(self):
        # `frame:GetWidth() * 2` must not report twice, once for the
        # receiver and once for the method.
        src = "local x = frame:GetWidth() * 2"
        self.assertEqual(len(run(src, geometry=True)), 1)


# ---------------------------------------------------------------------
# evidence harvesting
# ---------------------------------------------------------------------

class TestEvidence(unittest.TestCase):

    def test_guarded_result_marks_its_source(self):
        src = ('local hp = UnitHealth("p")\n'
               'if issecretvalue(hp) then return end\n')
        self.assertIn("UnitHealth", evidence(src))

    def test_pcall_is_unwrapped_to_the_real_call(self):
        # Without this the harvest reports `pcall` as the addon's most
        # secret-bearing call and nothing else.
        src = ('local ok, hp = pcall(UnitHealth, "player")\n'
               'if issecretvalue(hp) then return end\n')
        ev = evidence(src)
        self.assertIn("UnitHealth", ev)
        self.assertNotIn("pcall", ev)

    def test_pcall_with_anonymous_function_yields_nothing(self):
        src = ('local ok, v = pcall(function() return 1 end)\n'
               'if issecretvalue(v) then return end\n')
        self.assertEqual(evidence(src), {})

    def test_generic_calls_are_not_harvested(self):
        src = ('local v = select(1, ...)\n'
               'if issecretvalue(v) then return end\n')
        self.assertNotIn("select", evidence(src))

    def test_unguarded_result_is_not_evidence(self):
        self.assertEqual(evidence('local hp = UnitHealth("p")\nlocal x = hp'), {})


# ---------------------------------------------------------------------
# mutation
#
# Every fixture above that asserts silence is re-run with its guard
# removed. If the linter still says nothing, the original test was
# passing for the wrong reason and proved nothing.
# ---------------------------------------------------------------------

class TestMutation(unittest.TestCase):

    MUTANTS = [
        ("issecretvalue guard",
         'local hp = UnitHealth("p")\nif issecretvalue(hp) then return end\nlocal x = hp + 1',
         'local hp = UnitHealth("p")\nlocal x = hp + 1'),
        ("lowercase issecret guard",
         'local hp = UnitHealth("p")\nif not issecret(hp) then local x = hp + 1 end',
         'local hp = UnitHealth("p")\nif true then local x = hp + 1 end'),
        ("namespaced guard",
         'local hp = UnitHealth("p")\nif U.IsSecret(hp) then return end\nlocal x = hp + 1',
         'local hp = UnitHealth("p")\nlocal x = hp + 1'),
        ("sanitiser wrapper",
         'local hp = Plain(UnitHealth("p"))\nlocal x = hp + 1',
         'local hp = UnitHealth("p")\nlocal x = hp + 1'),
        ("suppression comment",
         'local hp = UnitHealth("p")\nlocal x = hp + 1 -- @secret-ok\n',
         'local hp = UnitHealth("p")\nlocal x = hp + 1\n'),
        ("block scope boundary",
         'function a()\n local hp = UnitHealth("p")\nend\nfunction b()\n local x = hp + 1\nend',
         'local hp = UnitHealth("p")\nlocal x = hp + 1'),
    ]

    def test_clean_fixtures_are_load_bearing(self):
        for label, clean, mutated in self.MUTANTS:
            with self.subTest(label):
                self.assertEqual(run(clean), [],
                                 "%s: fixture should be silent" % label)
                self.assertNotEqual(run(mutated), [],
                                    "%s: removing the guard produced no finding, so "
                                    "the silent fixture proved nothing" % label)

    def test_detection_depends_on_the_secret_set(self):
        # If findings appear for a call nobody marked secret, the report
        # is noise rather than evidence.
        src = 'local hp = UnitHealth("p")\nlocal x = hp + 1'
        self.assertNotEqual(run(src, secret={"UnitHealth"}), [])
        self.assertEqual(run(src, secret=set()), [])


# ---------------------------------------------------------------------
# reference file
# ---------------------------------------------------------------------

class TestReference(unittest.TestCase):

    def test_missing_file_is_not_an_error(self):
        calls, meta = L.load_reference(Path("/nonexistent/apidoc_secrets.txt"))
        self.assertEqual(calls, set())
        self.assertEqual(meta, {})

    def test_parses_header_and_functions(self):
        import tempfile
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False,
                                         encoding="utf-8") as fh:
            fh.write("# comment\n")
            fh.write("H|12.1.0.62000|120100|2026-09-09\n")
            fh.write("F|C_UnitAuras.GetAuraDataByIndex|AllowedWhenSecret|UnitData||\n")
            fh.write("S|AuraData|name|ConditionalSecret\n")
            path = Path(fh.name)
        try:
            calls, meta = L.load_reference(path)
            self.assertIn("C_UnitAuras.GetAuraDataByIndex", calls)
            self.assertEqual(meta["interface"], "120100")
            self.assertEqual(meta["build"], "12.1.0.62000")
        finally:
            path.unlink()


# ---------------------------------------------------------------------
# importer
#
# The dump is written by the client, not by us, so the parser has to
# cope with its shape rather than an idealised one. The trailing
# `-- [1]` index comment on every array entry is the detail that broke
# this on first contact with a real file.
# ---------------------------------------------------------------------

import apidoc_import as I  # noqa: E402

SV_SAMPLE = '''
TomoAPIDumpDB = {
\t["generated"] = "2026-09-09 14:02:11",
\t["records"] = {
\t\t"H|12.1.0.62431|120100|2026-09-09", -- [1]
\t\t"F|C_UnitAuras.GetAuraDataByIndex|UnitData|AuraData", -- [2]
\t\t"A|C_Spell.GetSpellInfo|AllowedWhenSecret|", -- [3]
\t\t"S|AuraData|name|ConditionalSecret", -- [4]
\t\t"nonsense", -- [5]
\t},
\t["build"] = "12.1.0.62431",
}
'''


class TestImporter(unittest.TestCase):

    def test_trailing_index_comment_is_tolerated(self):
        recs = I.extract_records(SV_SAMPLE)
        self.assertEqual(len(recs), 5)

    def test_bracketed_key_form_is_tolerated(self):
        sv = 'X = {\n["records"] = {\n[1] = "H|b|120100|d",\n[2] = "F|Foo||",\n},\n}\n'
        self.assertEqual(len(I.extract_records(sv)), 2)

    def test_non_record_lines_are_ignored(self):
        recs = I.extract_records(SV_SAMPLE)
        self.assertNotIn("12.1.0.62431", recs)  # the ["build"] entry

    def test_validate_splits_header_from_body(self):
        header, good, rejected = I.validate(I.extract_records(SV_SAMPLE))
        self.assertTrue(header.startswith("H|"))
        self.assertEqual(len(good), 3)
        self.assertEqual(rejected, ["nonsense"])

    def test_missing_records_table_is_an_error(self):
        with self.assertRaises(ValueError):
            I.extract_records("TomoAPIDumpDB = { }")

    def test_unescape_handles_quotes_and_newlines(self):
        self.assertEqual(I.unescape('a\\"b\\nc'), 'a"b\nc')

    def test_round_trip_feeds_the_linter(self):
        import tempfile
        d = Path(tempfile.mkdtemp())
        (d / "TomoAPIDump.lua").write_text(SV_SAMPLE, encoding="utf-8")
        out = d / "apidoc_secrets.txt"

        header, good, _ = I.validate(I.extract_records(SV_SAMPLE))
        out.write_text("\n".join([header] + sorted(good)) + "\n", encoding="utf-8")

        calls, meta = L.load_reference(out)
        self.assertEqual(calls, {"C_UnitAuras.GetAuraDataByIndex"})
        self.assertEqual(meta["interface"], "120100")

        # And the call the reference names must actually taint.
        src = ('local a = C_UnitAuras.GetAuraDataByIndex("player", 1)\n'
               'local x = a + 1')
        self.assertNotEqual(run(src, secret=calls), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
