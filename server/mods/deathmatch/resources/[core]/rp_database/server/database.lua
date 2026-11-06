--[[
    rp_database – Zarządzanie bazą danych
    Jedyny zasób w projekcie używający dbConnect.
    Obsługuje MySQL/MariaDB.
    Wszystkie zapytania są parametryzowane (ochrona przed SQL Injection).
--]]

local db = nil

local function connect()
    local host  = exports.rp_core:getConfig("dbHost") or "127.0.0.1"
    local port  = exports.rp_core:getConfig("dbPort") or 3306
    local name  = exports.rp_core:getConfig("dbName") or "sarpg"
    local user  = exports.rp_core:getConfig("dbUser") or "root"
    local pass  = exports.rp_core:getConfig("dbPass") or ""

    local connStr = string.format("host=%s;port=%d;dbname=%s;charset=utf8mb4", host, port, name)

    db = dbConnect("mysql", connStr, user, pass, "autoreconnect=1;share=1")

    if db then
        outputServerLog("[rp_database] Połączono z MySQL: " .. host .. "/" .. name)
        -- Ustaw tryb UTF8 i strefę czasową
        dbExec(db, "SET NAMES 'utf8mb4'")
        dbExec(db, "SET time_zone = '+00:00'")
    else
        outputServerLog("[rp_database] BLAD: Nie udalo sie polaczyc z baza danych!")
        outputServerLog("[rp_database] Sprawdz mtaserver.conf: dbhost, dbname, dbuser, dbpass")
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    connect()
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if source ~= getThisResource() then return end
    -- destroyElement(db) -- MTA czyści automatycznie
    outputServerLog("[rp_database] Rozłączono z bazą danych.")
end)

-- Eksport: pobranie obiektu połączenia (do zaawansowanego użytku)
function getDB()
    return db
end

--[[
    dbQuery(sql, ...) – wykonuje zapytanie SELECT, zwraca tablicę wierszy
    Przykład: local rows = exports.rp_database:dbGetAll("SELECT * FROM accounts WHERE id = ?", charId)
--]]
function dbGetAll(sql, ...)
    if not db then return nil end
    local qh = dbQuery(db, sql, ...)
    if not qh then return nil end
    local result, num = dbPoll(qh, -1)
    if not result then return {} end
    return result
end

--[[
    dbGetRow(sql, ...) – zwraca pierwszy wiersz lub nil
--]]
function dbGetRow(sql, ...)
    local rows = dbGetAll(sql, ...)
    if rows and #rows > 0 then return rows[1] end
    return nil
end

--[[
    dbExecute(sql, ...) – wykonuje INSERT/UPDATE/DELETE, zwraca true/false
--]]
function dbExecute(sql, ...)
    if not db then return false end
    local qh = dbQuery(db, sql, ...)
    if not qh then return false end
    local ok = dbFree(qh)
    return ok ~= false
end

--[[
    dbEscape(str) – escape stringa (zapasowe, preferuj parametryzowane zapytania)
--]]
function dbEscape(str)
    if not db then return tostring(str) end
    return dbQueryEscape(db, tostring(str))
end
