--[[
    rp_core – Konfiguracja serwera
    Odczytuje dane z mtaserver.conf przez get()
--]]

local _config = {}

local function loadConfig()
    -- Dane bazy danych z mtaserver.conf
    _config.dbHost   = get("dbhost") or "127.0.0.1"
    _config.dbPort   = tonumber(get("dbport")) or 3306
    _config.dbName   = get("dbname") or "sarpg"
    _config.dbUser   = get("dbuser") or "root"
    _config.dbPass   = get("dbpass") or ""

    -- Ustawienia gry
    _config.startCash   = tonumber(get("start_cash"))   or STARTING_CASH
    _config.startBank   = tonumber(get("start_bank"))   or STARTING_BANK
    _config.maxPlayers  = tonumber(get("maxplayers"))   or 100
    _config.serverName  = get("servername") or "San Andreas RPG"

    -- Praca / ekonomia
    _config.salaryInterval = tonumber(get("salary_interval")) or 30  -- minuty
    _config.taxRate        = tonumber(get("tax_rate"))         or 5   -- %
end

loadConfig()

-- Eksport: pobranie wartości konfiguracyjnej
function getConfig(key)
    return _config[key]
end
