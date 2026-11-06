--[[
    rp_vehicles – Zarządzanie pojazdami (serwer)
    Zapis stanu: paliwo, przebieg, zdrowie, pozycja, kolor, ulepszenia
    Bezpieczeństwo: wszystkie akcje walidowane po stronie serwera
--]]

-- Mapa: vehicleElement → dane pojazdu z DB
local vehMap = {}
-- Mapa: player → vehicleId (aktualnie prowadzony pojazd gracza)
local playerVeh = {}

-- ============================================================
--  ŁADOWANIE POJAZDÓW GRACZA
-- ============================================================
addEventHandler("onCharacterLoaded", root, function(player, charData)
    local charId = charData.id
    local rows = exports.rp_database:dbGetAll(
        "SELECT * FROM vehicles WHERE owner_id=? AND in_garage=0",
        charId
    )
    if not rows then return end

    for _, row in ipairs(rows) do
        spawnVehicleFromDB(row, player)
    end
end)

function spawnVehicleFromDB(row, owner)
    if not VEHICLE_CATALOG[row.model] then return end

    local veh = createVehicle(row.model, row.pos_x, row.pos_y, row.pos_z, 0, 0, row.rot)
    if not veh then return end

    setVehicleColor(veh, row.color1, row.color2)
    setVehiclePlateText(veh, row.plate or "")
    setVehicleLocked(veh, row.locked == 1)
    setVehicleEngineState(veh, false)
    setElementInterior(veh, row.interior or 0)
    setElementDimension(veh, row.dimension or 0)

    -- Dane elementu (do odczytu klienta)
    setElementData(veh, "fuel",     row.fuel    or 100, false)
    setElementData(veh, "mileage",  row.mileage or 0,   false)
    setElementData(veh, "vehId",    row.id,              false)
    setElementData(veh, "ownerId",  row.owner_id or 0,  false)

    -- Załaduj ulepszenia
    local upgrades = exports.rp_database:dbGetAll(
        "SELECT upgrade_id FROM vehicle_upgrades WHERE vehicle_id=?", row.id
    )
    if upgrades then
        for _, u in ipairs(upgrades) do
            addVehicleUpgrade(veh, u.upgrade_id)
        end
    end

    vehMap[veh] = {
        id       = row.id,
        ownerId  = row.owner_id,
        model    = row.model,
        plate    = row.plate,
        fuel     = row.fuel    or 100,
        mileage  = row.mileage or 0,
        health   = row.health  or 1000,
        locked   = row.locked  == 1,
        lights   = row.lights  == 1,
        engine   = false,
        color1   = row.color1,
        color2   = row.color2,
        nitro    = row.nitro_installed == 1,
    }

    return veh
end

-- ============================================================
--  SPAWN NA ŻĄDANIE (z garażu)
-- ============================================================
function spawnPlayerVehicle(player, vehicleId)
    local charId = exports.rp_characters:getCharId(player)
    if not charId then return false, "Brak postaci" end

    vehicleId = tonumber(vehicleId)
    local row = exports.rp_database:dbGetRow(
        "SELECT * FROM vehicles WHERE id=? AND owner_id=?",
        vehicleId, charId
    )
    if not row then return false, "Nie jesteś właścicielem tego pojazdu" end

    if not row.in_garage then
        -- Już spawniony – sprawdź czy element istnieje
        for v, d in pairs(vehMap) do
            if d.id == vehicleId and isElement(v) then
                return true, v
            end
        end
    end

    local px, py, pz = getElementPosition(player)
    row.pos_x = px + 4
    row.pos_y = py
    row.pos_z = pz

    local veh = spawnVehicleFromDB(row, player)
    if veh then
        exports.rp_database:dbExecute(
            "UPDATE vehicles SET in_garage=0, pos_x=?,pos_y=?,pos_z=? WHERE id=?",
            row.pos_x, row.pos_y, row.pos_z, vehicleId
        )
        return true, veh
    end
    return false, "Błąd spawnu"
end

-- ============================================================
--  ZAPIS STANU POJAZDU
-- ============================================================
local function saveVehicle(veh)
    local d = vehMap[veh]
    if not d then return end

    local x, y, z = getElementPosition(veh)
    local _, _, rz = getElementRotation(veh)
    local hp = getElementHealth(veh)

    exports.rp_database:dbExecute(
        [[UPDATE vehicles SET
            pos_x=?,pos_y=?,pos_z=?,rot=?,
            fuel=?,mileage=?,health=?,
            locked=?,lights=?,
            interior=?,dimension=?
          WHERE id=?]],
        x, y, z, rz,
        d.fuel, d.mileage, hp,
        d.locked and 1 or 0,
        d.lights and 1 or 0,
        getElementInterior(veh), getElementDimension(veh),
        d.id
    )
end

-- Autosave co 3 minuty
setTimer(function()
    for veh, _ in pairs(vehMap) do
        if isElement(veh) then
            saveVehicle(veh)
        else
            vehMap[veh] = nil
        end
    end
end, 180000, 0)

-- ============================================================
--  PALIWO
-- ============================================================
-- Odliczanie paliwa w ruchu (timer co 5s)
setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        local veh = getPedOccupiedVehicle(player)
        if veh and vehMap[veh] then
            local d = vehMap[veh]
            if d.engine then
                local vx, vy, vz = getElementVelocity(veh)
                local spd = math.sqrt(vx^2 + vy^2 + vz^2)
                local fuelUsed = spd * FUEL_RATE * 5  -- 5 sekund
                d.fuel = math.max(0, d.fuel - fuelUsed)
                setElementData(veh, "fuel", d.fuel, false)

                -- Przebieg
                local dist = spd * 180 * 5 / 1000  -- km
                d.mileage = d.mileage + dist
                setElementData(veh, "mileage", math.floor(d.mileage), false)

                if d.fuel <= 0 then
                    setVehicleEngineState(veh, false)
                    d.engine = false
                    triggerClientEvent(player, "rpNotif:send", player,
                        "warning","Pojazd","Brak paliwa! Silnik zgasł.")
                elseif d.fuel <= 15 then
                    triggerClientEvent(player, "rpNotif:send", player,
                        "warning","Pojazd","Niski poziom paliwa!")
                end
            end
        end
    end
end, 5000, 0)

function setVehicleFuel(veh, fuel)
    if vehMap[veh] then
        vehMap[veh].fuel = clamp(fuel, 0, FUEL_MAX)
        setElementData(veh, "fuel", vehMap[veh].fuel, false)
    end
end

function addMileage(veh, km)
    if vehMap[veh] then
        vehMap[veh].mileage = vehMap[veh].mileage + km
        setElementData(veh, "mileage", math.floor(vehMap[veh].mileage), false)
    end
end

-- ============================================================
--  SILNIK, ŚWIATŁA, ZAMKI (eventy klientów)
-- ============================================================
addEvent("rpVeh:toggleEngine", true)
addEventHandler("rpVeh:toggleEngine", root, function()
    local player = client
    local veh    = getPedOccupiedVehicle(player)
    if not veh then return end
    local d = vehMap[veh]
    if not d then return end

    -- Tylko właściciel lub mający klucz
    local charId = exports.rp_characters:getCharId(player)
    if d.ownerId ~= charId then
        triggerClientEvent(player,"rpNotif:send",player,"error","Pojazd","To nie Twój pojazd.")
        return
    end

    if d.fuel <= 0 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Pojazd","Brak paliwa.")
        return
    end

    d.engine = not d.engine
    setVehicleEngineState(veh, d.engine)
    triggerClientEvent(player,"rpVeh:engineState",player, d.engine)
end)

addEvent("rpVeh:toggleLights", true)
addEventHandler("rpVeh:toggleLights", root, function()
    local player = client
    local veh    = getPedOccupiedVehicle(player)
    if not veh then return end
    local d = vehMap[veh]
    if not d then return end
    d.lights = not d.lights
    setVehicleLightState(veh, 0, d.lights and 1 or 0)
    setVehicleLightState(veh, 1, d.lights and 1 or 0)
    setVehicleLightState(veh, 2, d.lights and 1 or 0)
    setVehicleLightState(veh, 3, d.lights and 1 or 0)
end)

addEvent("rpVeh:toggleLock", true)
addEventHandler("rpVeh:toggleLock", root, function()
    local player = client
    if not exports.rp_core:rateLimitCheck(player, "veh_lock", 500) then return end

    -- Znajdź najbliższy pojazd gracza w promieniu 10m
    local px, py, pz = getElementPosition(player)
    local charId = exports.rp_characters:getCharId(player)

    for veh, d in pairs(vehMap) do
        if isElement(veh) and d.ownerId == charId then
            local vx, vy, vz = getElementPosition(veh)
            if dist3D(px,py,pz,vx,vy,vz) <= 10 then
                d.locked = not d.locked
                setVehicleLocked(veh, d.locked)
                triggerClientEvent(player,"rpNotif:send",player,"info","Pojazd",
                    d.locked and "Pojazd zamknięty 🔒" or "Pojazd otwarty 🔓")
                break
            end
        end
    end
end)

-- ============================================================
--  HOLOWANIE (naprawa przez pomoc drogową)
-- ============================================================
addEvent("rpVeh:repair", true)
addEventHandler("rpVeh:repair", root, function(vehId)
    local player = client
    local charId = exports.rp_characters:getCharId(player)
    vehId = tonumber(vehId)
    if not vehId then return end

    for veh, d in pairs(vehMap) do
        if isElement(veh) and d.id == vehId and d.ownerId == charId then
            -- Koszt naprawy zależy od stanu
            local hp = getElementHealth(veh)
            local dmg = math.max(0, 1000 - hp)
            local cost = math.floor(dmg * 0.5)  -- 0.5$ za punkt uszkodzenia
            if cost < 100 then cost = 100 end

            local ok, err = exports.rp_economy:takeCash(player, cost, "vehicle_repair")
            if not ok then
                triggerClientEvent(player,"rpNotif:send",player,"error","Naprawa", err)
                return
            end
            fixVehicle(veh)
            d.fuel = math.min(FUEL_MAX, d.fuel + 30)
            setElementData(veh, "fuel", d.fuel, false)
            triggerClientEvent(player,"rpNotif:send",player,"success","Naprawa",
                "Pojazd naprawiony. Koszt: " .. formatMoney(cost))
            break
        end
    end
end)

-- ============================================================
--  SPRZEDAŻ POJAZDU (giełda)
-- ============================================================
addEvent("rpVeh:sellToDealer", true)
addEventHandler("rpVeh:sellToDealer", root, function(vehId)
    local player = client
    local charId = exports.rp_characters:getCharId(player)
    vehId = tonumber(vehId)
    if not vehId then return end

    local row = exports.rp_database:dbGetRow(
        "SELECT * FROM vehicles WHERE id=? AND owner_id=?", vehId, charId
    )
    if not row then
        triggerClientEvent(player,"rpNotif:send",player,"error","Sprzedaż","Nie jesteś właścicielem.")
        return
    end

    local catalog = VEHICLE_CATALOG[row.model]
    if not catalog then return end

    -- Salon skupuje za 60% ceny katalogowej, minus stan
    local hp = 1000
    for veh, d in pairs(vehMap) do
        if isElement(veh) and d.id == vehId then
            hp = getElementHealth(veh)
            -- Zniszcz element
            destroyElement(veh)
            vehMap[veh] = nil
            break
        end
    end
    local hpPct  = hp / 1000
    local sellPrice = math.floor(catalog.price * 0.6 * hpPct)

    exports.rp_database:dbExecute(
        "DELETE FROM vehicles WHERE id=?", vehId
    )
    exports.rp_economy:giveCash(player, sellPrice, "sell_vehicle")
    triggerClientEvent(player,"rpNotif:send",player,"success","Sprzedaż",
        "Pojazd sprzedany za " .. formatMoney(sellPrice))
end)

-- ============================================================
--  EKSPORTY
-- ============================================================
function getVehicleData(veh)
    return vehMap[veh]
end

addEventHandler("onResourceStop", resourceRoot, function()
    if source ~= getThisResource() then return end
    for veh, _ in pairs(vehMap) do
        if isElement(veh) then saveVehicle(veh) end
    end
end)
