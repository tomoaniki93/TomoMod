-- Execute the real codecs and profile import paths against adversarial data.
-- WoW-only APIs are stubbed; no game UI or SavedVariables files are touched.
local count = 0
local function check(label, value, detail)
    count = count + 1
    assert(value, label .. (detail and (": " .. tostring(detail)) or ""))
end
GetLocale = function() return "frFR" end
GetPhysicalScreenSize = function() return 2560, 1440 end
UIParent = { GetWidth = function() return 2560 end, GetHeight = function() return 1440 end }
CreateFrame = function()
    return setmetatable({}, { __index = function() return function() end end })
end
local combat, queue = false, {}
InCombatLockdown = function() return combat end
C_Timer = { After = function(_, fn) queue[#queue + 1] = fn end }
local function drain()
    while #queue > 0 do table.remove(queue, 1)() end
end
UnitClass = function() return "Mage", "MAGE" end
GetSpecialization = function() return nil end
GetNumSpecializations = function() return 0 end
issecretvalue = function() return false end
date = function() return "2026-09-12 12:00:00" end
abs = math.abs
strmatch = string.match
StaticPopupDialogs, SlashCmdList = {}, {}
TomoMod_L = setmetatable({}, { __index = function(_, key) return key end })
dofile("Libs/LibStub/LibStub.lua")
dofile("Libs/LibDeflate/LibDeflate.lua")
dofile("Libs/libserialize/serializer.lua")
dofile("Core/Utils.lua")
dofile("Core/Database.lua")
dofile("Core/ModuleRegistry.lua")
dofile("Core/ModuleManifest.lua")
dofile("Core/ProfileSafety.lua")
dofile("Core/Profiles.lua")
dofile("Core/SelectiveImport.lua")
dofile("Core/LayoutEngine.lua")
dofile("Core/ResolutionPresets.lua")
dofile("Core/LayoutShare.lua")
local S, P, SI, LS = TomoMod_ProfileSafety, TomoMod_Profiles, TomoMod_SelectiveImport, TomoMod_LayoutShare
local def, ser = LibStub("LibDeflate"), LibStub("TomoSerialize-1.0")
local function copy(v) return assert(S.Copy(v)) end
CopyTable = copy
local function same(a, b) return not SI.Differs(a, b) end
local normalize = TomoMod_NormalizeAllElements
local function reset()
    TomoModDB = copy(TomoMod_Defaults)
    TomoMod_NormalizeAllElements = normalize
    combat, queue = false, {}
    P.EnsureProfilesDB()
end
local function encodeRaw(raw, level)
    return def:EncodeForPrint(def:CompressDeflate(raw, { level = level or 1 }))
end
local function encode(settings, version)
    return encodeRaw(ser:Serialize({ _header = "TMOD", _version = version or 1, settings = settings }))
end
local function rejected(str, label)
    local before, profiles = copy(S.Snapshot()), copy(TomoModDB._profiles)
    local backups = TomoModDB._profileBackups
    local ok, why = P.Import(str)
    check(label .. " rejected with reason", not ok and type(why) == "string")
    check(label .. " settings unchanged", same(before, S.Snapshot()))
    check(label .. " profiles unchanged", same(profiles, TomoModDB._profiles))
    check(label .. " no backup/write", backups == TomoModDB._profileBackups)
end

reset()
check("all real defaults pass", S.ValidateSettings(TomoMod_Defaults) ~= nil)
local exported = assert(P.Export())
check("current profile format roundtrips", P.DecodeImport(exported) ~= nil)
check("valid full import", P.Import(exported))
check("backup before full import", #S.ListBackups() == 1)
local future = encode({ nameplates = { enabled = false }, futureModule = { setting = 7 } })
local decodedFuture = assert(P.DecodeImport(future))
local _, _, unknown = SI.Inspect(decodedFuture.settings)
check("unknown module still reported in selector", #unknown == 1 and unknown[1] == "futureModule")
check("known portion importable", P.Import(future))
check("unknown module never written", TomoModDB.futureModule == nil)
rejected(encode({ nameplates = { enabled = "false" } }), "string boolean")
rejected(encode({ nameplates = { fontSize = -999 } }), "invalid font")
rejected(encode({ classReminder = { position = false } }), "invalid optional position")
rejected(encode({ nameplates = { elements = { extra = { fontSize = false } } } }), "invalid optional font")
rejected(encode({ nameplates = { enabled = false }, [1] = {}, futureModule = {} }), "mixed module key types")
rejected(encode({ minimap = { scale = 0 } }), "invalid scale")
rejected(encode({ nameplates = { enabled = false } }, 99), "future version")
rejected(encode({ installer = { completed = false } }), "internal only")
rejected("abcd!", "malformed codec")
rejected(string.rep("a", S.MAX_ENCODED + 1), "encoded size limit")
rejected(encodeRaw("~V5~Dmalicious~v"), "function tag")
rejected(encodeRaw(ser:Serialize({ _header = "TMOD", _version = 1, _date = {},
    settings = { nameplates = { enabled = false } } })), "invalid preview metadata")
rejected(encodeRaw("~V5" .. string.rep("~T", 100) .. string.rep("~t", 100) .. "~v"), "deep nesting")
local circular = {}; circular.self = circular
check("cycles refused", S.Copy(circular) == nil)
check("NaN refused", S.Copy({ v = 0/0 }) == nil)
check("infinity refused", S.Copy({ v = math.huge }) == nil)
check("functions refused", S.Copy({ v = function() end }) == nil)
check("metatables refused", S.Copy(setmetatable({}, {})) == nil)

-- Verify the limit INSIDE the inflater, including multiple 32 KiB flushes,
-- stored blocks (level 0), compressed blocks and an exact boundary.
for _, level in ipairs({ 0, 1, 9 }) do
    local plain = string.rep("abcdefgh", 17000)
    local packed = def:CompressDeflate(plain, { level = level })
    local decoded, status = TomoMod_InflateBounded(packed, #plain)
    check("inflate boundary level " .. level, decoded == plain and status == 0)
    decoded, status = TomoMod_InflateBounded(packed, #plain - 1)
    check("inflate overflow level " .. level, decoded == nil and status == -100)
end
rejected(encodeRaw(string.rep("x", S.MAX_DECODED + 1)), "compressed expansion limit")
local newer = LibStub:NewLibrary("LibDeflate", 999999)
newer.CompressDeflate, newer.DecodeForPrint, newer.EncodeForPrint = def.CompressDeflate, def.DecodeForPrint, def.EncodeForPrint
local previous = LibStub("LibDeflate")
TomoMod_InflateBounded = nil
dofile("Libs/LibDeflate/LibDeflate.lua")
check("private inflater survives another addon's newer library", type(TomoMod_InflateBounded) == "function")
check("shared library not replaced", LibStub("LibDeflate") == previous)
check("codec still compatible", P.DecodeImport(exported) ~= nil)

reset()
TomoModDB.nameplates.fontSize = 19
TomoModDB.unitFrames.fontSize = 21
local untouched = copy(TomoModDB.unitFrames)
local report = SI.Apply({ nameplates = { enabled = false, fontSize = 25 }, unitFrames = { fontSize = 30 } }, { "nameplates" }, "Essai")
check("selective named import", report.applied == 1 and not report.err)
check("unselected module unchanged", same(TomoModDB.unitFrames, untouched))
check("previous named profile saved BEFORE applying", TomoModDB._profiles.named.Default.nameplates.fontSize == 19)
check("new profile saved and active", P.GetActiveProfileName() == "Essai" and TomoModDB._profiles.named.Essai.nameplates.fontSize == 25)
local current = copy(S.Snapshot())
local ok = P.ImportAsProfile(exported, "Essai")
check("existing profile name refused", not ok and same(current, S.Snapshot()))
check("invalid name refused", not P.ImportAsProfile(exported, "   "))
check("restore previous settings", S.RestoreBackup(1))
check("restored font and active profile", TomoModDB.nameplates.fontSize == 19 and P.GetActiveProfileName() == "Default")
check("restore itself is recoverable", #S.ListBackups() == 2)

reset()
local before = copy(S.Snapshot())
local beforeProfiles = copy(TomoModDB._profiles)
local identity = TomoModDB
TomoMod_NormalizeAllElements = function() error("injected normalization error") end
ok = P.ApplyImportedSettings({ nameplates = { fontSize = 24 } }, { "nameplates" }, "MustNotExist")
check("failed application rolled back", not ok and same(before, S.Snapshot()))
check("named profiles rolled back", same(beforeProfiles, TomoModDB._profiles))
check("global DB identity preserved", TomoModDB == identity)
check("backup independent of live tables", TomoModDB.nameplates ~= TomoModDB._profileBackups[1].settings.nameplates)
TomoMod_NormalizeAllElements = normalize
check("subsequent import still works", P.ImportAsProfile(exported, "WorksAfterRollback"))

reset()
combat = true
rejected(exported, "combat import")
report = SI.Apply({ nameplates = { enabled = false } }, { "nameplates" })
check("combat selective import refused", report.applied == 0 and report.err ~= nil)
combat = false
local asyncOK, asyncError
P.ImportAsync(exported, function(a, b) asyncOK, asyncError = a, b end)
check("async import deferred", asyncOK == nil)
combat = true
drain()
check("combat rechecked at async application", asyncOK == false and type(asyncError) == "string")
combat = false
P.ImportAsProfileAsync(exported, "Async", function(a, b) asyncOK, asyncError = a, b end)
drain()
check("async named success signature", asyncOK == true and asyncError == nil and P.GetActiveProfileName() == "Async")

reset()
local position = copy(TomoModDB.minimap.position)
report = LS.Import({ positions = { ["minimap.position"] = { point = "WRONG", x = 0, y = 0 } } })
check("invalid layout rejected before mutation", not report.ok and report.err and same(position, TomoModDB.minimap.position))
local layout = assert(LS.Export())
check("layout codec unchanged", LS.Decode(layout) ~= nil)
check("layout import creates backup", LS.Import(assert(LS.Decode(layout))).ok and #S.ListBackups() == 1)

reset()
TomoModDB.nameplates.fontSize = 23
P.SaveActiveAs("KeepMe")
check("full reset succeeds", TomoMod_ResetDatabase())
check("full reset preserves recovery ring", #S.ListBackups() == 1)
check("full reset recoverable", S.RestoreBackup(1))
check("named profiles recovered after reset", P.GetActiveProfileName() == "KeepMe" and TomoModDB.nameplates.fontSize == 23)
for i = 1, 8 do check("create bounded backup " .. i, S.CreateBackup("test " .. i) ~= nil) end
check("only five backups retained", #S.ListBackups() == 5)
TomoModDB._profileSafetyMigrationBackup = true
local payload = assert(S.Decode(assert(P.Export()), "TMOD", 1))
check("backups never exported", payload.settings._profileBackups == nil)
check("migration backup marker never exported", payload.settings._profileSafetyMigrationBackup == nil)
print("PASS: " .. count .. " profile safety assertions")
