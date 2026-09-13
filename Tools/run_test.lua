-- WoW accepts a UTF-8 BOM; stock Lua 5.1 does not. Preserve source names
-- and return values while normalising only that prefix in headless tests.
local originalLoadfile = loadfile
function loadfile(path)
    if path == nil then return originalLoadfile(path) end
    local f, err = io.open(path, "rb")
    if not f then return nil, err end
    local source = f:read("*a"); f:close()
    source = source:gsub("^\239\187\191", "")
    return loadstring(source, "@" .. path)
end
function dofile(path) return assert(loadfile(path))() end
assert(arg[1], "Usage: lua5.1 Tools/run_test.lua Tools/test_name.lua")
assert(loadfile(arg[1]))()
