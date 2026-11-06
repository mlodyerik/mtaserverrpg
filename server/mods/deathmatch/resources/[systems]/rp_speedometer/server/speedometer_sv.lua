--[[
    rp_speedometer – serwer: zakup i zarządzanie prędkościomierzami
--]]

-- Katalog modeli prędkościomierzy
local SPEEDO_SHOP = {
    [1] = { name = "Classic SF",    price = 500  },
    [2] = { name = "Night Edition", price = 1200 },
    [3] = { name = "Sport Carbon",  price = 2500 },
    [4] = { name = "Premium Gold",  price = 5000 },
}

-- Dostępne kolory (id → nazwa, kolor akcentu)
local SPEEDO_COLORS = {
    [1] = { name = "Niebieski",  r=30,  g=144, b=255 },
    [2] = { name = "Zielony",    r=60,  g=200, b=100 },
    [3] = { name = "Czerwony",   r=220, g=60,  b=60  },
    [4] = { name = "Biały",      r=220, g=225, b=235 },
    [5] = { name = "Pomarańczowy",r=255,g=140, b=30  },
    [6] = { name = "Złoty",      r=255, g=210, b=40  },
}

-- ============================================================
--  ZAKUP PRĘDKOŚCIOMIERZA
-- ============================================================
addEvent("rpSpeedo:buy", true)
addEventHandler("rpSpeedo:buy", root, function(speedoId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "speedo_buy", 2000) then return end

    speedoId = tonumber(speedoId)
    local item = SPEEDO_SHOP[speedoId]
    if not item then
        triggerClientEvent(player,"rpNotif:send",player,"error","Sklep","Nieznany prędkościomierz.")
        return
    end

    local charId = exports.rp_characters:getCharId(player)

    -- Sprawdź czy już posiada
    local existing = exports.rp_database:dbGetRow(
        "SELECT id FROM char_speedometers WHERE char_id=? AND speedo_id=?", charId, speedoId
    )
    if existing then
        triggerClientEvent(player,"rpNotif:send",player,"info","Sklep","Masz już ten prędkościomierz.")
        return
    end

    -- Odejmij kasę
    local ok, err = exports.rp_economy:takeCash(player, item.price, "buy_speedometer")
    if not ok then
        triggerClientEvent(player,"rpNotif:send",player,"error","Sklep", err)
        return
    end

    -- Zapisz zakup
    exports.rp_database:dbExecute(
        "INSERT INTO char_speedometers (char_id, speedo_id, color_id) VALUES (?,?,1)",
        charId, speedoId
    )

    -- Ustaw aktywny
    local c = exports.rp_characters:getCharacter(player)
    c.speedoId    = speedoId
    c.speedoColor = 1

    exports.rp_database:dbExecute(
        "UPDATE characters SET speedometer_id=?, speedometer_color=1 WHERE id=?",
        speedoId, charId
    )

    triggerClientEvent(player,"rpNotif:send",player,"success","Sklep",
        "Zakupiono prędkościomierz: " .. item.name)
    triggerClientEvent(player,"rpSpeedo:activate",player, speedoId, 1, SPEEDO_COLORS)
end)

-- ============================================================
--  ZMIANA KOLORU
-- ============================================================
addEvent("rpSpeedo:setColor", true)
addEventHandler("rpSpeedo:setColor", root, function(colorId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end

    colorId = tonumber(colorId)
    if not SPEEDO_COLORS[colorId] then return end

    local c = exports.rp_characters:getCharacter(player)
    if not c or c.speedoId == 0 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Prędkościomierz","Brak zakupionego prędkościomierza.")
        return
    end

    c.speedoColor = colorId
    exports.rp_database:dbExecute(
        "UPDATE char_speedometers SET color_id=? WHERE char_id=? AND speedo_id=?",
        colorId, c.id, c.speedoId
    )
    exports.rp_database:dbExecute(
        "UPDATE characters SET speedometer_color=? WHERE id=?", colorId, c.id
    )

    triggerClientEvent(player,"rpSpeedo:activate",player, c.speedoId, colorId, SPEEDO_COLORS)
    triggerClientEvent(player,"rpNotif:send",player,"success","Prędkościomierz",
        "Kolor zmieniony na: " .. SPEEDO_COLORS[colorId].name)
end)

-- ============================================================
--  WYŚLIJ DANE PO SPAWNIE
-- ============================================================
addEventHandler("onCharacterLoaded", root, function(player, c)
    if c.speedoId and c.speedoId > 0 then
        local colors = SPEEDO_COLORS
        triggerClientEvent(player,"rpSpeedo:activate",player, c.speedoId, c.speedoColor, colors)
    end
end)

-- ============================================================
--  EKSPORT OTWIERANIA SKLEPU
-- ============================================================
addEvent("rpSpeedo:openShop", true)
addEventHandler("rpSpeedo:openShop", root, function()
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    local c = exports.rp_characters:getCharacter(player)
    -- Pobierz zakupione
    local owned = exports.rp_database:dbGetAll(
        "SELECT speedo_id, color_id FROM char_speedometers WHERE char_id=?", c.id
    )
    triggerClientEvent(player,"rpSpeedo:showShop",player, SPEEDO_SHOP, SPEEDO_COLORS, owned or {},
        c.speedoId, c.speedoColor, c.cash)
end)

function buySpeedometer(player, id)
    triggerEvent("rpSpeedo:buy", player, id)
end
function setSpeedometerColor(player, colorId)
    triggerEvent("rpSpeedo:setColor", player, colorId)
end
