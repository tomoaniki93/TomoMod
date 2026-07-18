-- =====================================================================
-- TomoMod Forge -- Schema (L2)
-- Generic stepwise schema migration with pre-migration auto-backup,
-- promoted from CooldownForge. Any versioned store (CDF bars today,
-- AstralForge frame schemas tomorrow) registers the same way:
--   Forge.Schema.Migrate{ root, target, migrations, dataKeys }
--   Forge.Schema.Restore{ root, target, migrations, dataKeys }
-- Backup retention = 1 (overwrites previous), restore is always manual.
-- =====================================================================

local Forge = TomoMod_Forge
if not Forge then return end

Forge.Schema = Forge.Schema or {}
local S = Forge.Schema

-- opts:
--   root       : the versioned table (e.g. TomoModDB.cooldownForge)
--   target     : CURRENT_SCHEMA of the owner
--   migrations : { [v] = function(root) } transforming v-1 -> v IN PLACE
--   dataKeys   : array of root keys snapshotted into the backup
--   versionKey : default "schemaVersion"
--   backupKey  : default "_backup"
-- Returns ok (boolean), fromVersion.
function S.Migrate(opts)
    local root = opts and opts.root
    if type(root) ~= "table" then return false end
    local vk = opts.versionKey or "schemaVersion"
    local bk = opts.backupKey or "_backup"
    local target = tonumber(opts.target) or 1
    local from = tonumber(root[vk]) or 1

    if from >= target then
        root[vk] = target
        return true, from
    end

    -- Auto-backup BEFORE migrating (retention = 1; overwrites previous).
    local backup = { [vk] = from, date = date("%Y-%m-%d %H:%M") }
    for _, k in ipairs(opts.dataKeys or {}) do
        backup[k] = CopyTable(root[k] or {})
    end
    root[bk] = backup

    for v = from + 1, target do
        local m = opts.migrations and opts.migrations[v]
        if type(m) == "function" then
            local ok, err = pcall(m, root)
            if not ok then
                -- Migration failed: keep the backup, leave version at `from`.
                root[vk] = from
                if geterrorhandler then geterrorhandler()(err) end
                return false, from
            end
        end
    end
    root[vk] = target
    return true, from
end

-- Manual restore from the backup (never automatic). Restores dataKeys,
-- then re-runs Migrate so restored (older) data comes back up to target.
-- Returns true on success.
function S.Restore(opts)
    local root = opts and opts.root
    if type(root) ~= "table" then return false end
    local vk = opts.versionKey or "schemaVersion"
    local bk = opts.backupKey or "_backup"
    local backup = root[bk]
    if type(backup) ~= "table" then return false end

    for _, k in ipairs(opts.dataKeys or {}) do
        root[k] = CopyTable(backup[k] or {})
    end
    root[vk] = tonumber(backup[vk]) or (tonumber(opts.target) or 1)
    S.Migrate(opts)
    return true
end
