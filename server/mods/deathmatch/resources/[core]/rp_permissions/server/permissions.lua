--[[
    rp_permissions – Uprawnienia w grze
    Sprawdzamy ACL MTA dla kluczowych operacji administracyjnych.
    Uprawnienia frakcyjne i graczy przechowywane w bazie.
--]]

-- Cache uprawnień: [accountId] = { "admin", "support", ... }
local perms = {}

local function loadPerms(accountId)
    -- Tutaj możemy rozszerzyć o tabelę uprawnień w DB
    -- Na start uprawnienia = role ACL
    perms[accountId] = {}
end

function hasPermission(player, permission)
    -- Sprawdź ACL
    local acc = getPlayerAccount(player)
    if not acc then return false end
    local username = getAccountName(acc)

    if permission == "admin" or permission == "admin.*" then
        return isObjectInACLGroup("user."..username, aclGetGroup("Admin")) or
               isObjectInACLGroup("user."..username, aclGetGroup("SuperAdmin"))
    end
    if permission == "superadmin" then
        return isObjectInACLGroup("user."..username, aclGetGroup("SuperAdmin"))
    end

    return false
end

function grantPermission(player, permission)
    local acc = getPlayerAccount(player)
    if not acc then return false end
    local username = getAccountName(acc)
    local group = aclGetGroup("Admin")
    if group then
        aclGroupAddObject(group, "user."..username)
        return true
    end
    return false
end

addEventHandler("onPlayerQuit", root, function()
    local acc = getPlayerAccount(source)
    if acc then perms[tonumber(getAccountName(acc))] = nil end
end)
