--[[
    rp_accounts – Rejestracja, logowanie, sesje
    Hasła: passwordHash/passwordVerify (MTA built-in, bcrypt)
    Wszystkie dane walidowane po stronie serwera.
--]]

-- Mapa: player element → dane konta
local sessions = {} -- [player] = { id, username, charId, ... }

-- ============================================================
--  POMOCNICZE
-- ============================================================
local function getSerial(player)
    return getPlayerSerial(player) or ""
end

local function getIP(player)
    return getPlayerIP(player) or ""
end

-- ============================================================
--  REJESTRACJA
-- ============================================================
addEvent("rpAccount:register", true)
addEventHandler("rpAccount:register", root, function(username, password)
    local player = client
    if not player then return end

    -- Rate limit
    if not exports.rp_core:rateLimitCheck(player, "register", 3000) then
        triggerClientEvent(player, "rpAccount:registerResult", player, false, "Zbyt szybko. Poczekaj chwilę.")
        return
    end

    -- Walidacja
    if not exports.rp_core:isValidName(username, 3, 24) then
        triggerClientEvent(player, "rpAccount:registerResult", player, false, "Login: 3-24 znaków, tylko litery, cyfry, _ i -")
        return
    end
    if type(password) ~= "string" or #password < 6 or #password > 64 then
        triggerClientEvent(player, "rpAccount:registerResult", player, false, "Hasło: minimum 6 znaków, maksimum 64.")
        return
    end

    -- Sprawdź czy login zajęty
    local existing = exports.rp_database:dbGetRow(
        "SELECT id FROM accounts WHERE username = ?", username
    )
    if existing then
        triggerClientEvent(player, "rpAccount:registerResult", player, false, "Ten login jest już zajęty.")
        return
    end

    local hash = passwordHash(password, "bcrypt", {})
    if not hash then
        triggerClientEvent(player, "rpAccount:registerResult", player, false, "Błąd serwera (hash). Spróbuj ponownie.")
        return
    end

    local ok = exports.rp_database:dbExecute(
        "INSERT INTO accounts (username, password, serial, last_ip) VALUES (?,?,?,?)",
        username, hash, getSerial(player), getIP(player)
    )

    if ok then
        exports.rp_logs:logSystem("ACCOUNTS", "Rejestracja: " .. username .. " [" .. getSerial(player) .. "]")
        triggerClientEvent(player, "rpAccount:registerResult", player, true, "Konto założone! Możesz się teraz zalogować.")
    else
        triggerClientEvent(player, "rpAccount:registerResult", player, false, "Błąd bazy danych. Spróbuj ponownie.")
    end
end)

-- ============================================================
--  LOGOWANIE
-- ============================================================
addEvent("rpAccount:login", true)
addEventHandler("rpAccount:login", root, function(username, password)
    local player = client
    if not player then return end

    if not exports.rp_core:rateLimitCheck(player, "login", 2000) then
        triggerClientEvent(player, "rpAccount:loginResult", player, false, "Zbyt szybko.")
        return
    end

    if type(username) ~= "string" or type(password) ~= "string" then
        triggerClientEvent(player, "rpAccount:loginResult", player, false, "Nieprawidłowe dane.")
        return
    end

    local row = exports.rp_database:dbGetRow(
        "SELECT id, username, password, banned, ban_reason FROM accounts WHERE username = ?",
        username
    )

    if not row then
        triggerClientEvent(player, "rpAccount:loginResult", player, false, "Nieprawidłowy login lub hasło.")
        return
    end

    if row.banned == 1 then
        kickPlayer(player, "Konto zbanowane. Powód: " .. (row.ban_reason or "naruszenie regulaminu"))
        return
    end

    local verified = passwordVerify(password, row.password)
    if not verified then
        triggerClientEvent(player, "rpAccount:loginResult", player, false, "Nieprawidłowy login lub hasło.")
        return
    end

    -- Zaktualizuj last_login, serial, ip
    exports.rp_database:dbExecute(
        "UPDATE accounts SET last_login = NOW(), serial = ?, last_ip = ? WHERE id = ?",
        getSerial(player), getIP(player), row.id
    )

    sessions[player] = { id = row.id, username = row.username }

    exports.rp_logs:logSystem("ACCOUNTS", "Logowanie: " .. row.username .. " [" .. getSerial(player) .. "]")
    triggerClientEvent(player, "rpAccount:loginResult", player, true, row.username)

    -- Załaduj postać
    triggerEvent("rpAccount:loadCharacter", root, player, row.id)
end)

-- ============================================================
--  WYLOGOWANIE / DISCONNECT
-- ============================================================
addEventHandler("onPlayerQuit", root, function()
    if sessions[source] then
        exports.rp_logs:logSystem("ACCOUNTS", "Rozłączenie: " .. sessions[source].username)
    end
    sessions[source] = nil
end)

-- ============================================================
--  EKSPORTY
-- ============================================================
function getAccount(player)
    return sessions[player]
end

function isLoggedIn(player)
    return sessions[player] ~= nil
end

function getAccountId(player)
    if sessions[player] then return sessions[player].id end
    return nil
end

-- ============================================================
--  SPAWN PO POŁĄCZENIU → pokaż panel logowania
-- ============================================================
addEventHandler("onPlayerConnect", root, function()
    -- source = nowy gracz
    -- Spawnuj gracza w miejscu spawnu (niewidoczny), pokaż UI logowania
    spawnPlayer(source, SPAWN_SF.x, SPAWN_SF.y, SPAWN_SF.z, SPAWN_SF.rot)
    setPlayerAlpha(source, 0)  -- ukryj gracza
    freezePlayer(source, true)
    setCameraMatrix(source, 2168.0, 922.0, 20.0, 2171.0, 933.0, 11.0)
    triggerClientEvent(source, "rpAccount:showLogin", source)
end)
