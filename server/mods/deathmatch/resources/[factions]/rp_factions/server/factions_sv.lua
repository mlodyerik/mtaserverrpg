--[[
    rp_factions – System frakcji (serwer)
    Duty, chat frakcyjny, rangi, zarządzanie
--]]

-- Cache danych frakcyjnych: [player] = { fractionId, rankId, rankName, onDuty, fractionName }
local fracData = {}

-- ============================================================
--  WCZYTAJ DANE PO SPAWNIE
-- ============================================================
addEventHandler("onCharacterLoaded", root, function(player, c)
    local row = exports.rp_database:dbGetRow(
        [[SELECT fm.fraction_id, fm.rank_id, fm.on_duty,
                 fr_name.name as fraction_name, fr_rank.name as rank_name, fr_rank.salary
          FROM fraction_members fm
          JOIN fractions fr_name ON fr_name.id = fm.fraction_id
          JOIN fraction_ranks fr_rank ON fr_rank.id = fm.rank_id
          WHERE fm.char_id = ?]],
        c.id
    )

    if row then
        fracData[player] = {
            fractionId   = row.fraction_id,
            rankId       = row.rank_id,
            fractionName = row.fraction_name,
            rankName     = row.rank_name,
            salary       = row.salary,
            onDuty       = row.on_duty == 1,
        }
        triggerClientEvent(player, "rpFrac:setData", player,
            row.fraction_name, row.rank_name, row.on_duty == 1)
    end
end)

addEventHandler("onPlayerQuit", root, function()
    fracData[source] = nil
end)

-- ============================================================
--  DUTY
-- ============================================================
addEvent("rpFrac:toggleDuty", true)
addEventHandler("rpFrac:toggleDuty", root, function()
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not fracData[player] then
        triggerClientEvent(player,"rpNotif:send",player,"error","Frakcja","Nie jesteś w żadnej frakcji.")
        return
    end

    local d = fracData[player]
    d.onDuty = not d.onDuty

    local charId = exports.rp_characters:getCharId(player)
    exports.rp_database:dbExecute(
        "UPDATE fraction_members SET on_duty=? WHERE char_id=?",
        d.onDuty and 1 or 0, charId
    )

    triggerClientEvent(player,"rpFrac:setData",player,
        d.fractionName, d.rankName, d.onDuty)
    triggerClientEvent(player,"rpNotif:send",player,
        d.onDuty and "success" or "info","Frakcja",
        d.onDuty and ("Jesteś na służbie: "..d.fractionName) or "Zszedłeś ze służby.")
end)

-- ============================================================
--  FRAKCYJNY CHAT (F8)
-- ============================================================
addEvent("rpFrac:chat", true)
addEventHandler("rpFrac:chat", root, function(msg)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not fracData[player] then return end

    msg = tostring(msg or ""):sub(1,200)
    if #msg == 0 then return end

    local d = fracData[player]
    local c = exports.rp_characters:getCharacter(player)
    local formatted = string.format("[%s] %s [%s]: %s",
        d.fractionName, d.rankName, c.name, msg)

    -- Wyślij do wszystkich członków frakcji on-duty
    for _, p in ipairs(getElementsByType("player")) do
        if fracData[p] and fracData[p].fractionId == d.fractionId then
            triggerClientEvent(p,"rpFrac:receiveChat",p, formatted, d.fractionId)
        end
    end

    exports.rp_logs:logChat(c.name, msg, "frac_"..d.fractionName)
end)

-- ============================================================
--  ZAPROSZENIE DO FRAKCJI (przez admina lub przełożonego)
-- ============================================================
addEvent("rpFrac:invite", true)
addEventHandler("rpFrac:invite", root, function(targetName, fractionId, rankId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not fracData[player] then return end

    local d = fracData[player]
    -- Tylko lider (rank >= 8) lub admin
    if d.fractionId ~= tonumber(fractionId) or d.rankId < 8 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Frakcja","Brak uprawnień.")
        return
    end

    local target = findPlayerByName and findPlayerByName(targetName) or nil
    if not target then
        triggerClientEvent(player,"rpNotif:send",player,"error","Frakcja","Nie znaleziono gracza.")
        return
    end

    if fracData[target] then
        triggerClientEvent(player,"rpNotif:send",player,"error","Frakcja","Gracz jest już w frakcji.")
        return
    end

    local targetCharId = exports.rp_characters:getCharId(target)
    if not targetCharId then return end

    rankId = tonumber(rankId) or 1
    exports.rp_database:dbExecute(
        "INSERT INTO fraction_members (char_id, fraction_id, rank_id) VALUES (?,?,?)",
        targetCharId, d.fractionId, rankId
    )

    local tc = exports.rp_characters:getCharacter(target)
    fracData[target] = {
        fractionId   = d.fractionId,
        fractionName = d.fractionName,
        rankId       = rankId,
        rankName     = "Nowy",
        salary       = 1000,
        onDuty       = false,
    }

    triggerClientEvent(target,"rpFrac:setData",target, d.fractionName, "Rekrut", false)
    triggerClientEvent(target,"rpNotif:send",target,"success","Frakcja",
        "Dołączyłeś do frakcji: " .. d.fractionName)
    triggerClientEvent(player,"rpNotif:send",player,"success","Frakcja",
        "Zaproszono: " .. (tc and tc.name or targetName))
end)

-- ============================================================
--  ZWOLNIENIE Z FRAKCJI
-- ============================================================
addEvent("rpFrac:fire", true)
addEventHandler("rpFrac:fire", root, function(targetName)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not fracData[player] or fracData[player].rankId < 8 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Frakcja","Brak uprawnień.")
        return
    end

    local target = findPlayerByName and findPlayerByName(targetName) or nil
    if not target then return end

    local targetCharId = exports.rp_characters:getCharId(target)
    exports.rp_database:dbExecute(
        "DELETE FROM fraction_members WHERE char_id=?", targetCharId
    )
    fracData[target] = nil
    triggerClientEvent(target,"rpFrac:setData",target,"","",false)
    triggerClientEvent(target,"rpNotif:send",target,"error","Frakcja","Zostałeś zwolniony z frakcji.")
    triggerClientEvent(player,"rpNotif:send",player,"success","Frakcja","Zwolniono: "..targetName)
end)

-- ============================================================
--  EKSPORTY
-- ============================================================
function isInFraction(player) return fracData[player] ~= nil end
function getFractionId(player) return fracData[player] and fracData[player].fractionId end
function isOnDuty(player) return fracData[player] and fracData[player].onDuty or false end
function getRank(player) return fracData[player] and fracData[player].rankId or 0 end

-- Komenda /duty
addCommandHandler("duty", function(player)
    triggerEvent("rpFrac:toggleDuty", player)
end)

-- Frakcyjny chat
addCommandHandler("fc", function(player, cmd, ...)
    local msg = table.concat({...}, " ")
    triggerEvent("rpFrac:chat", player, msg)
end)
