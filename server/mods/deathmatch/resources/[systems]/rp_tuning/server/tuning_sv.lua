--[[
    rp_tuning – Warsztaty (serwer)
    Lokalizacje warsztatów: SF (2), LS (1), LV (1)
--]]

local WORKSHOPS = {
    { id=1, name="Warsztat Mechanika – SF Centrum",   x=-2025.0, y=290.0, z=35.2 },
    { id=2, name="Tuning Shop – SF Zachód",           x=-2373.0, y=601.0, z=35.2 },
    { id=3, name="Auto Tuning – Los Santos",          x=612.0,  y=-583.0, z=17.3 },
    { id=4, name="LS Motors – Las Venturas",          x=2381.0, y=1983.0, z=10.8 },
}

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    for _, w in ipairs(WORKSHOPS) do
        local m = createMarker(w.x, w.y, w.z-1, "cylinder", 2.0, 255, 140, 0, 150)
        local b = createBlip(w.x, w.y, w.z, 446, 2, 255,140,0,255)
        setBlipName(b, w.name)
        setElementData(m, "workshopId", w.id, false)
    end
end)

addEventHandler("onMarkerHit", root, function(hitPlayer, dim)
    if getElementType(hitPlayer) ~= "player" then return end
    if not exports.rp_characters:isSpawned(hitPlayer) then return end
    local wId = getElementData(source, "workshopId")
    if not wId then return end

    local veh = getPedOccupiedVehicle(hitPlayer)
    if not veh then
        triggerClientEvent(hitPlayer,"rpNotif:send",hitPlayer,"error","Warsztat","Musisz być w pojeździe.")
        return
    end

    local vData = exports.rp_vehicles:getVehicleData(veh)
    if not vData then return end

    local charId = exports.rp_characters:getCharId(hitPlayer)
    if vData.ownerId ~= charId then
        triggerClientEvent(hitPlayer,"rpNotif:send",hitPlayer,"error","Warsztat","To nie Twój pojazd.")
        return
    end

    -- Pobierz zainstalowane ulepszenia
    local installed = exports.rp_database:dbGetAll(
        "SELECT upgrade_id FROM vehicle_upgrades WHERE vehicle_id=?", vData.id
    )

    local c = exports.rp_characters:getCharacter(hitPlayer)
    triggerClientEvent(hitPlayer, "rpTuning:openShop", hitPlayer,
        vData, TUNING_ITEMS, PAINT_JOBS, PAINT_PRICE, installed or {}, c.cash)
end)

-- ============================================================
--  ZAKUP ULEPSZENIA
-- ============================================================
addEvent("rpTuning:buyUpgrade", true)
addEventHandler("rpTuning:buyUpgrade", root, function(upgradeId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "tuning_buy", 1500) then return end

    upgradeId = tonumber(upgradeId)
    if not upgradeId then return end

    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    local vData = exports.rp_vehicles:getVehicleData(veh)
    if not vData then return end
    local charId = exports.rp_characters:getCharId(player)
    if vData.ownerId ~= charId then return end

    -- Znajdź cenę
    local item = nil
    for _, ti in ipairs(TUNING_ITEMS) do
        if ti.id == upgradeId then item = ti break end
    end
    if not item then
        triggerClientEvent(player,"rpNotif:send",player,"error","Tuning","Nieznane ulepszenie.")
        return
    end

    -- Sprawdź czy już zainstalowane
    local existing = exports.rp_database:dbGetRow(
        "SELECT id FROM vehicle_upgrades WHERE vehicle_id=? AND upgrade_id=?",
        vData.id, upgradeId
    )
    if existing then
        triggerClientEvent(player,"rpNotif:send",player,"info","Tuning","To ulepszenie jest już zainstalowane.")
        return
    end

    local ok, err = exports.rp_economy:takeCash(player, item.price, "tuning_buy")
    if not ok then
        triggerClientEvent(player,"rpNotif:send",player,"error","Tuning", err)
        return
    end

    addVehicleUpgrade(veh, upgradeId)
    exports.rp_database:dbExecute(
        "INSERT INTO vehicle_upgrades (vehicle_id, upgrade_id) VALUES (?,?)",
        vData.id, upgradeId
    )

    -- Nitro
    if tableContains(NITRO_IDS, upgradeId) then
        exports.rp_database:dbExecute(
            "UPDATE vehicles SET nitro_installed=1 WHERE id=?", vData.id
        )
    end

    triggerClientEvent(player,"rpNotif:send",player,"success","Tuning",
        "Zainstalowano: " .. item.name)
end)

-- ============================================================
--  DEMONTAŻ ULEPSZENIA
-- ============================================================
addEvent("rpTuning:removeUpgrade", true)
addEventHandler("rpTuning:removeUpgrade", root, function(upgradeId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    upgradeId = tonumber(upgradeId)
    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    local vData = exports.rp_vehicles:getVehicleData(veh)
    if not vData then return end
    local charId = exports.rp_characters:getCharId(player)
    if vData.ownerId ~= charId then return end

    removeVehicleUpgrade(veh, upgradeId)
    exports.rp_database:dbExecute(
        "DELETE FROM vehicle_upgrades WHERE vehicle_id=? AND upgrade_id=?",
        vData.id, upgradeId
    )

    -- Zwrot 30% ceny
    for _, ti in ipairs(TUNING_ITEMS) do
        if ti.id == upgradeId then
            local refund = math.floor(ti.price * 0.3)
            exports.rp_economy:giveCash(player, refund, "tuning_refund")
            triggerClientEvent(player,"rpNotif:send",player,"info","Tuning",
                "Zdemontowano: "..ti.name.." (zwrot: "..formatMoney(refund)..")")
            break
        end
    end
end)

-- ============================================================
--  ZMIANA LAKIERU
-- ============================================================
addEvent("rpTuning:paint", true)
addEventHandler("rpTuning:paint", root, function(paintId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "tuning_paint", 1500) then return end

    paintId = tonumber(paintId)
    local paint = nil
    for _, p in ipairs(PAINT_JOBS) do
        if p.id == paintId then paint = p break end
    end
    if not paint then return end

    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    local vData = exports.rp_vehicles:getVehicleData(veh)
    if not vData then return end
    local charId = exports.rp_characters:getCharId(player)
    if vData.ownerId ~= charId then return end

    local ok, err = exports.rp_economy:takeCash(player, PAINT_PRICE, "tuning_paint")
    if not ok then
        triggerClientEvent(player,"rpNotif:send",player,"error","Lakiernia", err)
        return
    end

    -- Ustaw kolor (uproszczone, GTA używa indeksów kolorów 0-255)
    -- Tutaj konwertujemy RGB do najbliższego indeksu GTA (dla uproszczenia używamy pary 0/0)
    setVehicleColor(veh, 0, 0, 0, 0)

    -- Zapisz w DB
    exports.rp_database:dbExecute(
        "UPDATE vehicles SET color1=0, color2=0 WHERE id=?", vData.id
    )

    triggerClientEvent(player,"rpNotif:send",player,"success","Lakiernia",
        "Pojazd przemalowany na: " .. paint.name)
end)

-- ============================================================
--  NAPRAWA W WARSZTACIE
-- ============================================================
addEvent("rpTuning:repair", true)
addEventHandler("rpTuning:repair", root, function()
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    local veh = getPedOccupiedVehicle(player)
    if not veh then return end
    local vData = exports.rp_vehicles:getVehicleData(veh)
    if not vData then return end
    local charId = exports.rp_characters:getCharId(player)
    if vData.ownerId ~= charId then return end

    local hp  = getElementHealth(veh)
    local dmg = 1000 - hp
    local cost = math.max(200, math.floor(dmg * 0.8))

    local ok, err = exports.rp_economy:takeCash(player, cost, "workshop_repair")
    if not ok then
        triggerClientEvent(player,"rpNotif:send",player,"error","Warsztat", err)
        return
    end

    fixVehicle(veh)
    exports.rp_vehicles:setVehicleFuel(veh, FUEL_MAX)

    triggerClientEvent(player,"rpNotif:send",player,"success","Warsztat",
        "Pojazd naprawiony i zatankowany. Koszt: " .. formatMoney(cost))
end)
