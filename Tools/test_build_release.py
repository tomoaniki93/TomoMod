"""Exercise the release gate with broken packages, not just the real tree."""
import tempfile
import unittest
from pathlib import Path
import build_release


class LoadGraphTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.addon = self.root / "TomoMod"
        (self.addon / "Core").mkdir(parents=True)
        self.files = ["ProfileSafety", "LayoutShare", "Profiles", "Init"]
        for name in self.files:
            (self.addon / "Core" / (name + ".lua")).write_text("-- fixture\n")
        self.toc = self.addon / "TomoMod.toc"
        self.toc.write_text("## Version: test\n" + "\n".join("Core\\%s.lua" % n for n in self.files))

    def problems(self):
        return build_release.validate(self.root)[1]

    def test_complete(self):
        self.assertEqual(self.problems(), [])

    def test_missing_lua(self):
        (self.addon / "Core/Profiles.lua").unlink()
        self.assertTrue(any("missing" in p for p in self.problems()))

    def test_xml_nested_missing_reference(self):
        (self.addon / "embeds.xml").write_text('<Ui><Include file="nested.xml"/></Ui>')
        self.toc.write_text(self.toc.read_text() + "\nembeds.xml")
        self.assertTrue(any("nested.xml" in p for p in self.problems()))

    def test_wrong_case(self):
        self.toc.write_text(self.toc.read_text().replace("Profiles.lua", "profiles.lua"))
        self.assertTrue(any("miscased" in p for p in self.problems()))

    def test_wrong_order(self):
        self.toc.write_text("\n".join("Core/%s.lua" % n for n in reversed(self.files)))
        self.assertTrue(any("order" in p for p in self.problems()))

    def test_cycle(self):
        (self.addon / "cycle.xml").write_text('<Ui><Include file="cycle.xml"/></Ui>')
        self.toc.write_text(self.toc.read_text() + "\ncycle.xml")
        self.assertTrue(any("cyclic" in p for p in self.problems()))

    def test_escape(self):
        self.toc.write_text(self.toc.read_text() + "\n../../outside.lua")
        self.assertTrue(any("escapes" in p for p in self.problems()))

    def test_nested_addon(self):
        child = self.addon / "Nested"
        child.mkdir()
        (child / "Nested.toc").write_text("")
        self.assertTrue(any("nested addon" in p for p in self.problems()))

    def test_malformed_xml(self):
        (self.addon / "bad.xml").write_text("<Ui>")
        self.toc.write_text(self.toc.read_text() + "\nbad.xml")
        self.assertTrue(any("invalid XML" in p for p in self.problems()))


if __name__ == "__main__":
    unittest.main()
