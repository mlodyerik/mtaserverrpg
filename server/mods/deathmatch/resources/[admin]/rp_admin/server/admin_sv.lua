--[[
    rp_admin – Panel administracyjny (serwer)
    Uprawnienia: ACL "Admin" lub "SuperAdmin"
--]]

local function isAdmin(player)
    return isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)),
        aclGetGroup("Admin")) or
    isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)),
        aclGetGroup("SuperAdmin"))
end

local function isSuperAdmin(player)
    return isObjectInACLGroup("user." .. getAccountName(getPlayerAccount(player)),
        aclGetGroup("SuperAdmin"))
end

local function adminName(player)
    local c = exports.rp_characters:getCharacter(player)
    return c and c.name or getPlayerName(player)
end

-- ============================================================
--  KOMENDY ADMINISTRACYJNE
-- ============================================================

-- /kick <gracz> [powód]
addCommandHandler("kick", function(player, cmd, targetName, ...)
    if not isAdmin(player) then return end
    local reason = table.concat({...}, " ") or "Brak powodu"
    local target = findPlayerByName(targetName)
    if not target then
        triggerClientEvent(player,"rpNotif:send",player,"error","Admin","Nie znaleziono gracza.")
        return
    end
    exports.rp_logs:logAdmin(adminName(player), targetName, "kick", reason)
    kickPlayer(target, "Kick przez admina: " .. reason)
end)

-- /ban <gracz> <powód>
addCommandHandler("ban", function(player, cmd, targetName, ...)
    if not isAdmin(player) then return end
    local reason = table.concat({...}, " ") or "Ban"

    local target = findPlayerByName(targetName)
    if target then
        -- Ban konta
        local acc = getPlayerAccount(target)
        if acc then
            setAccountPassword(acc, "BANNED")
        end
        exports.rp_database:dbExecute(
            "UPDATE accounts SET banned=1, ban_reason=? WHERE username=?",
            reason, targetName
        )
        exports.rp_logs:logAdmin(adminName(player), targetName, "ban", reason)
        kickPlayer(target, "Zostałeś zbanowany. Powód: " .. reason)
    else
        exports.rp_database:dbExecute(
            "UPDATE accounts SET banned=1, ban_reason=? WHERE username=?",
            reason, targetName
        )
        exports.rp_logs:logAdmin(adminName(player), targetName, "ban_offline", reason)
    end
    triggerClientEvent(player,"rpNotif:send",player,"success","Admin","Zbanowano: " .. targetName)
end)

-- /setcash <gracz> <kwota>
addCommandHandler("setcash", function(player, cmd, targetName, amount)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    local amt = tonumber(amount)
    if not amt then return end
    local c = exports.rp_characters:getCharacter(target)
    if not c then return end
    c.cash = clamp(amt, 0, MAX_CASH)
    exports.rp_database:dbExecute("UPDATE characters SET cash=? WHERE id=?", c.cash, c.id)
    triggerClientEvent(target,"rpEconomy:update",target,c.cash,c.bank)
    exports.rp_logs:logAdmin(adminName(player), targetName, "setcash", tostring(amt))
    triggerClientEvent(player,"rpNotif:send",player,"success","Admin","Gotówka ustawiona.")
end)

-- /setbank <gracz> <kwota>
addCommandHandler("setbank", function(player, cmd, targetName, amount)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    local amt = tonumber(amount)
    if not amt then return end
    local c = exports.rp_characters:getCharacter(target)
    if not c then return end
    c.bank = clamp(amt, 0, MAX_BANK)
    exports.rp_database:dbExecute("UPDATE characters SET bank=? WHERE id=?", c.bank, c.id)
    triggerClientEvent(target,"rpEconomy:update",target,c.cash,c.bank)
    exports.rp_logs:logAdmin(adminName(player), targetName, "setbank", tostring(amt))
end)

-- /setlevel <gracz> <poziom>
addCommandHandler("setlevel", function(player, cmd, targetName, level)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    local lvl = tonumber(level)
    if not lvl or lvl < 1 or lvl > MAX_LEVEL then return end
    local c = exports.rp_characters:getCharacter(target)
    if not c then return end
    c.level = lvl; c.xp = 0
    exports.rp_database:dbExecute("UPDATE characters SET level=?,xp=0 WHERE id=?", lvl, c.id)
    triggerClientEvent(target,"rpChar:updateHUD",target,c)
    exports.rp_logs:logAdmin(adminName(player), targetName, "setlevel", tostring(lvl))
    triggerClientEvent(player,"rpNotif:send",player,"success","Admin","Poziom ustawiony na "..lvl)
end)

-- /tp <gracz>  – teleportuj się do gracza
addCommandHandler("tp", function(player, cmd, targetName)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    local x,y,z = getElementPosition(target)
    setElementPosition(player, x+2, y, z)
    exports.rp_logs:logAdmin(adminName(player), targetName, "teleport_to", "")
end)

-- /tphere <gracz> – teleportuj gracza do siebie
addCommandHandler("tphere", function(player, cmd, targetName)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    local x,y,z = getElementPosition(player)
    setElementPosition(target, x+2, y, z)
    exports.rp_logs:logAdmin(adminName(player), targetName, "teleport_here", "")
end)

-- /repair <gracz> – napraw pojazd
addCommandHandler("repair", function(player, cmd, targetName)
    if not isAdmin(player) then return end
    local target = targetName and findPlayerByName(targetName) or player
    local veh = getPedOccupiedVehicle(target)
    if veh then fixVehicle(veh) end
end)

-- /freeze <gracz>
addCommandHandler("freeze", function(player, cmd, targetName)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    freezePlayer(target, true)
    exports.rp_logs:logAdmin(adminName(player), targetName, "freeze", "")
end)

-- /unfreeze <gracz>
addCommandHandler("unfreeze", function(player, cmd, targetName)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    freezePlayer(target, false)
end)

-- /setskin <gracz> <skinid>
addCommandHandler("setskin", function(player, cmd, targetName, skinId)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    local sk = tonumber(skinId)
    if not sk then return end
    setElementModel(target, sk)
    exports.rp_logs:logAdmin(adminName(player), targetName, "setskin", tostring(sk))
end)

-- /announce <wiadomość>
addCommandHandler("announce", function(player, cmd, ...)
    if not isAdmin(player) then return end
    local msg = table.concat({...}, " ")
    for _, p in ipairs(getElementsByType("player")) do
        triggerClientEvent(p,"rpNotif:send",p,"warning","Ogłoszenie", msg)
    end
    exports.rp_logs:logAdmin(adminName(player), nil, "announce", msg)
end)

-- /spawnveh <model>
addCommandHandler("spawnveh", function(player, cmd, model)
    if not isAdmin(player) then return end
    model = tonumber(model)
    if not model then return end
    local x,y,z = getElementPosition(player)
    local veh = createVehicle(model, x+4, y, z)
    if veh then
        exports.rp_logs:logAdmin(adminName(player), nil, "spawnveh", tostring(model))
    end
end)

-- /giveveh <gracz> <model>
addCommandHandler("giveveh", function(player, cmd, targetName, model)
    if not isAdmin(player) then return end
    local target = findPlayerByName(targetName)
    if not target then return end
    model = tonumber(model)
    if not model then return end
    local charId = exports.rp_characters:getCharId(target)
    if not charId then return end
    local x,y,z = getElementPosition(target)
    local plate  = "ADM" .. tostring(math.random(100,999))
    exports.rp_database:dbExecute(
        "INSERT INTO vehicles (owner_id,model,plate,pos_x,pos_y,pos_z,rot,fuel,price) VALUES(?,?,?,?,?,?,0,100,0)",
        charId, model, plate, x+5, y, z
    )
    exports.rp_logs:logAdmin(adminName(player), targetName, "giveveh", tostring(model))
    triggerClientEvent(target,"rpNotif:send",target,"success","Admin","Otrzymałeś pojazd od admina.")
end)

-- /noclip
addCommandHandler("noclip", function(player, cmd)
    if not isAdmin(player) then return end
    triggerClientEvent(player, "rpAdmin:toggleNoclip", player)
end)

-- /adminpanel
addCommandHandler("adminpanel", function(player, cmd)
    if not isAdmin(player) then return end
    local players = {}
    for _, p in ipairs(getElementsByType("player")) do
        local c = exports.rp_characters:getCharacter(p)
        table.insert(players, {
            name  = c and c.name or getPlayerName(p),
            level = c and c.level or 0,
            cash  = c and c.cash  or 0,
            ping  = getPlayerPing(p),
            serial= getPlayerSerial(p):sub(1,8),
        })
    end
    triggerClientEvent(player, "rpAdmin:openPanel", player, players)
end)

-- ============================================================
--  HELPER: Znajdź gracza po nazwie (częściowo)
-- ============================================================
function findPlayerByName(name)
    if not name then return nil end
    local lower = name:lower()
    for _, p in ipairs(getElementsByType("player")) do
        local c = exports.rp_characters:getCharacter(p)
        if c and c.name:lower():find(lower, 1, true) then return p end
        if getPlayerName(p):lower():find(lower, 1, true) then return p end
    end
    return nil
end
