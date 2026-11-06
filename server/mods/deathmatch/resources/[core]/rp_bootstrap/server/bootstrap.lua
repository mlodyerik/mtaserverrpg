--[[
    rp_bootstrap – sekwencer startowy
    Uruchamia zasoby w prawidłowej kolejności.
    Jeśli zasób krytyczny nie uruchomi się, zatrzymuje dalszy start.
--]]

local RESOURCES = {
    -- { name, critical }
    { "rp_core",        true  },
    { "rp_database",    true  },
    { "rp_logs",        true  },
    { "rp_accounts",    true  },
    { "rp_permissions", true  },
    { "rp_characters",  true  },
    -- Interfejs (klient)
    { "rp_ui",          false },
    { "rp_notifications",false},
    { "rp_hud",         false },
    -- Systemy ekonomiczne
    { "rp_economy",     true  },
    { "rp_bank",        false },
    { "rp_inventory",   false },
    { "rp_shops",       false },
    -- Pojazdy
    { "rp_vehicles",    false },
    { "rp_dealership",  false },
    { "rp_garages",     false },
    { "rp_tuning",      false },
    { "rp_speedometer", false },
    -- Świat i interakcje
    { "rp_world",       false },
    { "rp_interact",    false },
    -- Prace
    { "rp_jobs",        false },
    -- Nieruchomości / handel
    { "rp_houses",      false },
    { "rp_trade",       false },
    { "rp_auction",     false },
    -- Frakcje
    { "rp_factions",    false },
    { "rp_police",      false },
    { "rp_ems",         false },
    { "rp_mechanic",    false },
    -- Telefon
    { "rp_phone",       false },
    { "rp_phone_ui",    false },
    -- Osiągnięcia
    { "rp_achievements",false },
    -- Admin
    { "rp_admin",       false },
    { "rp_anticheat",   false },
}

local function log(msg)
    outputServerLog("[BOOTSTRAP] " .. tostring(msg))
    outputConsole("[BOOTSTRAP] " .. tostring(msg))
end

local function startNext(index)
    if index > #RESOURCES then
        log("=== Wszystkie zasoby uruchomione. Serwer gotowy! ===")
        return
    end

    local entry    = RESOURCES[index]
    local resName  = entry[1]
    local critical = entry[2]
    local res      = getResourceFromName(resName)

    if not res then
        if critical then
            log("BLAD KRYTYCZNY: Zasob '" .. resName .. "' nie istnieje! Zatrzymuję start.")
            return
        else
            log("OSTRZEZENIE: Zasob '" .. resName .. "' nie istnieje, pomijam.")
            startNext(index + 1)
            return
        end
    end

    if getResourceState(res) == "running" then
        log("OK (juz dziala): " .. resName)
        startNext(index + 1)
        return
    end

    local ok = startResource(res)
    if ok then
        log("START OK: " .. resName)
        -- dajemy 50ms przerwy między zasobami (bezpieczne dla DB)
        setTimer(startNext, 50, 1, index + 1)
    else
        if critical then
            log("BLAD KRYTYCZNY: Nie udalo sie uruchomic '" .. resName .. "'! Zatrzymuję start.")
        else
            log("BLAD (niekrytyczny): Nie udalo sie uruchomic '" .. resName .. "', pomijam.")
            setTimer(startNext, 50, 1, index + 1)
        end
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    log("=== SAN ANDREAS RPG – SEKWENCER STARTOWY ===")
    log("MTA version: " .. getVersion().mta)
    log("Uruchamiam " .. #RESOURCES .. " zasobow...")
    setTimer(startNext, 500, 1, 1)
end)
