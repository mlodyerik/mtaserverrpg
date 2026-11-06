--[[
    rp_garages – Garaże: wywołaj/schowaj pojazd
--]]

-- Publiczne miejsca wywołania pojazdów (bez kupowania garażu)
local PUBLIC_SPAWN_POINTS = {
    { id=99, name="Parking SF Centrum",  x=-2000.0, y=200.0, z=35.2 },
    { id=98, name="Parking LS",          x=700.0,   y=-620.0,z=16.3 },
    { id=97, name="Parking LV",          x=2250.0,  y=2460.0,z=10.8 },
}

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end

    -- Garaże z bazy
    local rows = exports.rp_database:dbGetAll("SELECT * FROM garages")
    if rows then
        for _, g in ipairs(rows) do
            local m = createMarker(g.pos_x, g.pos_y, g.pos_z-1, "cylinder", 2.0, 255,180,0,150)
            setElementData(m, "garageId", g.id, false)
            local b = createBlip(g.pos_x, g.pos_y, g.pos_z, 50, 2, 255,180,0,255)
            setBlipName(b, g.name .. (g.owner_id and " [ZAJĘTY]" or " [NA SPRZEDAŻ]"))
        end
    end

    -- Publiczne parkingi
    for _, p in ipairs(PUBLIC_SPAWN_POINTS) do
        local m = createMarker(p.x, p.y, p.z-1, "cylinder", 2.0, 30,144,255,130)
        setElementData(m, "publicParkId", p.id, false)
        local b = createBlip(p.x, p.y, p.z, 50, 1.5, 30,144,255,200)
        setBlipName(b, p.name)
    end
end)

addEventHandler("onMarkerHit", root, function(hitPlayer, dim)
    if getElementType(hitPlayer) ~= "player" then return end
    if not exports.rp_characters:isSpawned(hitPlayer) then return end

    local garId  = getElementData(source, "garageId")
    local pubId  = getElementData(source, "publicParkId")

    if not garId and not pubId then return end

    local charId = exports.rp_characters:getCharId(hitPlayer)
    local vehicles = exports.rp_database:dbGetAll(
        "SELECT v.id, v.model, v.plate, v.fuel, v.health, v.in_garage FROM vehicles v WHERE v.owner_id=?",
        charId
    )

    local catalog = VEHICLE_CATALOG
    local vehList = {}
    for _, v in ipairs(vehicles or {}) do
        local info = catalog[v.model]
        table.insert(vehList, {
            id      = v.id,
            name    = info and info.name or ("Model #"..v.model),
            plate   = v.plate,
            fuel    = v.fuel,
            health  = v.health,
            inGarage= v.in_garage == 1,
        })
    end

    triggerClientEvent(hitPlayer, "rpGarage:openPanel", hitPlayer, vehList, garId, pubId)
end)

-- Wywołaj pojazd z garażu
addEvent("rpGarage:spawnVehicle", true)
addEventHandler("rpGarage:spawnVehicle", root, function(vehicleId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "garage_spawn", 2000) then return end

    vehicleId = tonumber(vehicleId)
    local charId = exports.rp_characters:getCharId(player)

    local ok, veh = exports.rp_vehicles:spawnPlayerVehicle(player, vehicleId)
    if ok then
        triggerClientEvent(player,"rpNotif:send",player,"success","Garaż","Pojazd wywołany.")
    else
        triggerClientEvent(player,"rpNotif:send",player,"error","Garaż", tostring(veh))
    end
end)

-- Schowaj pojazd
addEvent("rpGarage:storeVehicle", true)
addEventHandler("rpGarage:storeVehicle", root, function(vehicleId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "garage_store", 2000) then return end

    vehicleId = tonumber(vehicleId)
    local charId = exports.rp_characters:getCharId(player)

    local row = exports.rp_database:dbGetRow(
        "SELECT id FROM vehicles WHERE id=? AND owner_id=?", vehicleId, charId
    )
    if not row then
        triggerClientEvent(player,"rpNotif:send",player,"error","Garaż","Nie jesteś właścicielem.")
        return
    end

    -- Zniszcz element w świecie
    for _, veh in ipairs(getElementsByType("vehicle")) do
        if getElementData(veh, "vehId") == vehicleId then
            local vx,vy,vz = getElementPosition(veh)
            exports.rp_database:dbExecute(
                "UPDATE vehicles SET in_garage=1, pos_x=?,pos_y=?,pos_z=? WHERE id=?",
                vx,vy,vz, vehicleId
            )
            destroyElement(veh)
            break
        end
    end

    triggerClientEvent(player,"rpNotif:send",player,"success","Garaż","Pojazd schowany.")
end)
