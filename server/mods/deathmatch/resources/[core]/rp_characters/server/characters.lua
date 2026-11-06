--[[
    rp_characters – Zarządzanie postaciami (serwer)
--]]

-- [player] = { id, name, cash, bank, level, xp, ... }
local chars = {}

-- ============================================================
--  WCZYTANIE POSTACI PO ZALOGOWANIU
-- ============================================================
addEvent("rpAccount:loadCharacter", true)
addEventHandler("rpAccount:loadCharacter", root, function(player, accountId)
    -- Pobierz postacie powiązane z kontem
    local rows = exports.rp_database:dbGetAll(
        "SELECT id, name, level, skin_id FROM characters WHERE account_id = ? LIMIT 3",
        accountId
    )

    if not rows then rows = {} end

    -- Wyślij listę postaci do klienta (panel wyboru)
    triggerClientEvent(player, "rpChar:showSelect", player, rows, accountId)
end)

-- ============================================================
--  TWORZENIE POSTACI
-- ============================================================
addEvent("rpChar:create", true)
addEventHandler("rpChar:create", root, function(accountId, charName, skinId, sex)
    local player = client
    if not player then return end
    if not exports.rp_accounts:isLoggedIn(player) then return end

    -- Walidacja
    if not exports.rp_core:isValidName(charName, 3, 40) then
        triggerClientEvent(player, "rpChar:createResult", player, false, "Nieprawidłowa nazwa postaci (3-40 znaków, tylko litery i spacje).")
        return
    end

    skinId = tonumber(skinId)
    if not skinId then
        triggerClientEvent(player, "rpChar:createResult", player, false, "Nieprawidłowy skin.")
        return
    end

    sex = tonumber(sex) or 0
    if sex ~= 0 and sex ~= 1 then sex = 0 end

    -- Limit 3 postaci na konto
    local count = exports.rp_database:dbGetRow(
        "SELECT COUNT(*) as cnt FROM characters WHERE account_id = ?", accountId
    )
    if count and count.cnt >= 3 then
        triggerClientEvent(player, "rpChar:createResult", player, false, "Możesz mieć maksymalnie 3 postacie.")
        return
    end

    -- Sprawdź unikalność imienia
    local existing = exports.rp_database:dbGetRow(
        "SELECT id FROM characters WHERE name = ?", charName
    )
    if existing then
        triggerClientEvent(player, "rpChar:createResult", player, false, "Ta nazwa postaci jest już zajęta.")
        return
    end

    local ok = exports.rp_database:dbExecute(
        [[INSERT INTO characters (account_id, name, skin_id, sex, cash, bank,
          spawn_x, spawn_y, spawn_z, spawn_rot)
          VALUES (?,?,?,?,?,?,?,?,?,?)]],
        accountId, charName, skinId, sex,
        exports.rp_core:getConfig("startCash") or STARTING_CASH,
        0,
        SPAWN_SF.x, SPAWN_SF.y, SPAWN_SF.z, SPAWN_SF.rot
    )

    if ok then
        triggerClientEvent(player, "rpChar:createResult", player, true, "Postać " .. charName .. " utworzona!")
        -- Odśwież listę postaci
        local acId = exports.rp_accounts:getAccountId(player)
        local rows = exports.rp_database:dbGetAll(
            "SELECT id, name, level, skin_id FROM characters WHERE account_id = ?", acId
        )
        triggerClientEvent(player, "rpChar:showSelect", player, rows or {}, acId)
    else
        triggerClientEvent(player, "rpChar:createResult", player, false, "Błąd bazy danych.")
    end
end)

-- ============================================================
--  WYBÓR I SPAWN POSTACI
-- ============================================================
addEvent("rpChar:select", true)
addEventHandler("rpChar:select", root, function(charId)
    local player = client
    if not player then return end
    if not exports.rp_accounts:isLoggedIn(player) then return end

    charId = tonumber(charId)
    if not charId then return end

    local accountId = exports.rp_accounts:getAccountId(player)

    -- Sprawdź czy postać należy do gracza
    local row = exports.rp_database:dbGetRow(
        "SELECT * FROM characters WHERE id = ? AND account_id = ?",
        charId, accountId
    )

    if not row then
        triggerClientEvent(player, "rpChar:createResult", player, false, "Nieprawidłowa postać.")
        return
    end

    -- Załaduj dane do pamięci
    chars[player] = {
        id           = row.id,
        accountId    = accountId,
        name         = row.name,
        skinId       = row.skin_id,
        sex          = row.sex,
        spawnX       = row.spawn_x,
        spawnY       = row.spawn_y,
        spawnZ       = row.spawn_z,
        spawnRot     = row.spawn_rot,
        interior     = row.interior,
        dimension    = row.dimension,
        hp           = row.hp,
        armour       = row.armour,
        hunger       = row.hunger,
        thirst       = row.thirst,
        cash         = row.cash,
        bank         = row.bank,
        level        = row.level,
        xp           = row.xp,
        totalMinutes = row.total_minutes,
        jobId        = row.job_id,
        jobLevel     = row.job_level,
        jobXp        = row.job_xp,
        speedoId     = row.speedometer_id,
        speedoColor  = row.speedometer_color,
        licenceCar   = row.licence_car == 1,
        licenceTruck = row.licence_truck == 1,
        licenceBike  = row.licence_bike == 1,
    }

    -- Spawn
    spawnPlayer(player, row.spawn_x, row.spawn_y, row.spawn_z, row.spawn_rot,
        row.skin_id, row.interior, row.dimension)

    setPlayerAlpha(player, 255)
    freezePlayer(player, false)
    setCameraTarget(player, player)

    setPedArmor(player, row.armour)
    setElementHealth(player, row.hp)

    -- Nickname nad głową
    setPlayerName(player, row.name)

    exports.rp_logs:logSystem("CHARS", "Spawn: " .. row.name .. " (" .. row.id .. ")")

    -- Powiadom inne systemy
    triggerEvent("onCharacterLoaded", root, player, chars[player])
    triggerClientEvent(player, "rpChar:onSpawn", player, chars[player])
end)

-- ============================================================
--  ZAPIS CO 5 MINUT + PRZY WYJŚCIU
-- ============================================================
local function saveCharacterToDB(player)
    local c = chars[player]
    if not c then return end

    local x, y, z = getElementPosition(player)
    local rot      = getPedRotation(player)
    local interior = getElementInterior(player)
    local dim      = getElementDimension(player)
    local hp       = getElementHealth(player)
    local armour   = getPedArmor(player)

    exports.rp_database:dbExecute(
        [[UPDATE characters SET
            spawn_x=?, spawn_y=?, spawn_z=?, spawn_rot=?,
            interior=?, dimension=?,
            hp=?, armour=?,
            cash=?, bank=?,
            level=?, xp=?,
            total_minutes=?,
            job_id=?, job_level=?, job_xp=?,
            speedometer_id=?, speedometer_color=?
          WHERE id=?]],
        x, y, z, rot, interior, dim,
        hp, armour,
        c.cash, c.bank,
        c.level, c.xp,
        c.totalMinutes,
        c.jobId, c.jobLevel, c.jobXp,
        c.speedoId, c.speedoColor,
        c.id
    )
end

function saveCharacter(player)
    saveCharacterToDB(player)
end

-- Autosave co 5 minut
setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        if chars[player] then
            saveCharacterToDB(player)
        end
    end
end, 300000, 0)

-- Zapis przy wyjściu
addEventHandler("onPlayerQuit", root, function()
    if chars[source] then
        saveCharacterToDB(source)
        chars[source] = nil
    end
end)

-- Odliczanie minut online
setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        if chars[player] then
            chars[player].totalMinutes = chars[player].totalMinutes + 1
        end
    end
end, 60000, 0)

-- ============================================================
--  EKSPORTY
-- ============================================================
function getCharacter(player)
    return chars[player]
end

function getCharId(player)
    if chars[player] then return chars[player].id end
    return nil
end

function isSpawned(player)
    return chars[player] ~= nil
end

function giveXP(player, amount)
    local c = chars[player]
    if not c then return false end
    amount = math.max(0, math.floor(amount))
    c.xp = c.xp + amount

    -- Sprawdź awans poziomu
    local nextXP = getXPForLevel(c.level)
    while c.xp >= nextXP and c.level < MAX_LEVEL do
        c.xp    = c.xp - nextXP
        c.level = c.level + 1
        nextXP  = getXPForLevel(c.level)
        triggerClientEvent(player, "rpChar:levelUp", player, c.level)
        exports.rp_logs:logSystem("XP", c.name .. " awansował na poziom " .. c.level)
    end

    triggerClientEvent(player, "rpChar:updateHUD", player, c)
    return true
end
