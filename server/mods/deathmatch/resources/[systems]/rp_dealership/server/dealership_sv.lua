--[[
    rp_dealership – Salony samochodowe
    Lokalizacje: San Fierro (główny), Los Santos, Las Venturas
--]]

-- Salony (pozycja NPC/markera)
local DEALERS = {
    {
        id    = 1,
        name  = "SF Motors – San Fierro",
        x     = -1940.8, y = 298.5, z = 35.2,
        categories = {"car","sedan","sport","super","suv","classic","lowrider"},
    },
    {
        id    = 2,
        name  = "LS AutoHaus – Los Santos",
        x     = 521.8,  y = -1289.8, z = 17.2,
        categories = {"car","sedan","sport","super","suv","classic"},
    },
    {
        id    = 3,
        name  = "LV Motors – Las Venturas",
        x     = 2437.3, y = 1996.8,  z = 10.8,
        categories = {"car","sedan","sport","super","offroad"},
    },
    {
        id    = 4,
        name  = "SF Trucking – San Fierro",
        x     = -1892.1, y = 40.5,  z = 35.2,
        categories = {"truck","van"},
    },
    {
        id    = 5,
        name  = "SF Bikes – San Fierro",
        x     = -1960.2, y = 356.1, z = 35.2,
        categories = {"bike"},
    },
}

-- ============================================================
--  MARKERY I NPC PRZY STARCIE
-- ============================================================
addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    for _, d in ipairs(DEALERS) do
        local marker = createMarker(d.x, d.y, d.z - 1, "cylinder", 1.8, 0, 144, 255, 150)
        local blip   = createBlipAttachedTo(marker, 326, 2, 0, 0, 255, 255)
        setBlipName(blip, d.name)
        setElementData(marker, "dealerId", d.id, false)
    end
    outputServerLog("[rp_dealership] " .. #DEALERS .. " salonów załadowanych.")
end)

-- ============================================================
--  OTWIERANIE SALONU
-- ============================================================
addEvent("rpDealer:open", true)
addEventHandler("rpDealer:open", root, function(dealerId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "dealer_open", 1000) then return end

    dealerId = tonumber(dealerId)
    local dealer = nil
    for _, d in ipairs(DEALERS) do
        if d.id == dealerId then dealer = d break end
    end
    if not dealer then return end

    -- Zbierz pojazdy dla tego salonu
    local vehicles = {}
    for model, info in pairs(VEHICLE_CATALOG) do
        if tableContains(dealer.categories, info.cat) and info.price > 0 then
            table.insert(vehicles, {
                model = model,
                name  = info.name,
                cat   = info.cat,
                price = info.price,
            })
        end
    end
    table.sort(vehicles, function(a,b) return a.price < b.price end)

    local c = exports.rp_characters:getCharacter(player)
    triggerClientEvent(player, "rpDealer:showPanel", player, dealer, vehicles, c.cash)
end)

-- ============================================================
--  ZAKUP POJAZDU
-- ============================================================
addEvent("rpDealer:buy", true)
addEventHandler("rpDealer:buy", root, function(dealerId, model)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "dealer_buy", 3000) then return end

    dealerId = tonumber(dealerId)
    model    = tonumber(model)

    -- Sprawdź dealer
    local dealer = nil
    for _, d in ipairs(DEALERS) do
        if d.id == dealerId then dealer = d break end
    end
    if not dealer then return end

    local info = VEHICLE_CATALOG[model]
    if not info or info.price <= 0 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Salon","Nieprawidłowy pojazd.")
        return
    end
    if not tableContains(dealer.categories, info.cat) then
        triggerClientEvent(player,"rpNotif:send",player,"error","Salon","Ten salon nie sprzedaje tego pojazdu.")
        return
    end

    -- Limit pojazdów (max 3 na gracza na start)
    local charId = exports.rp_characters:getCharId(player)
    local count  = exports.rp_database:dbGetRow(
        "SELECT COUNT(*) as cnt FROM vehicles WHERE owner_id=?", charId
    )
    if count and count.cnt >= 5 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Salon","Możesz posiadać maksymalnie 5 pojazdów.")
        return
    end

    -- Odejmij kasę
    local ok, err = exports.rp_economy:takeCash(player, info.price, "buy_vehicle")
    if not ok then
        triggerClientEvent(player,"rpNotif:send",player,"error","Salon", err)
        return
    end

    -- Wygeneruj tablicę rejestracyjną
    local plate = generatePlate()

    -- Spawn obok gracza
    local px, py, pz = getElementPosition(player)
    exports.rp_database:dbExecute(
        [[INSERT INTO vehicles
            (owner_id, model, plate, color1, color2, pos_x, pos_y, pos_z, rot, fuel, price)
          VALUES (?,?,?,0,0,?,?,?,0,100,?)]],
        charId, model, plate, px+5, py, pz, info.price
    )

    local vehRow = exports.rp_database:dbGetRow(
        "SELECT * FROM vehicles WHERE plate=?", plate
    )
    if vehRow then
        exports.rp_vehicles:spawnPlayerVehicle and nil  -- spawnujemy bezpośrednio
        local veh = exports.rp_vehicles:spawnPlayerVehicle(player, vehRow.id)
    end

    triggerClientEvent(player,"rpNotif:send",player,"success","Salon",
        "Zakupiono: " .. info.name .. " za " .. formatMoney(info.price))
    exports.rp_logs:logAdmin(
        exports.rp_characters:getCharacter(player).name,
        nil, "buy_vehicle",
        info.name .. " | " .. plate .. " | " .. info.price
    )
end)

-- ============================================================
--  POMOCNICZE
-- ============================================================
function generatePlate()
    local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    local nums  = "0123456789"
    local plate = ""
    for i = 1, 3 do
        plate = plate .. chars:sub(math.random(#chars), math.random(#chars))
    end
    for i = 1, 3 do
        plate = plate .. nums:sub(math.random(#nums), math.random(#nums))
    end
    return plate
end

-- Marker wejścia → otwórz salon
addEventHandler("onMarkerHit", root, function(hitPlayer, dim)
    if getElementType(hitPlayer) ~= "player" then return end
    if not exports.rp_characters:isSpawned(hitPlayer) then return end
    local dId = getElementData(source, "dealerId")
    if dId then
        addEvent("rpDealer:open", true)
        triggerEvent("rpDealer:open", hitPlayer, dId)
    end
end)
