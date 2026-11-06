--[[
    rp_houses – Nieruchomości (serwer)
    Kupno, sprzedaż, wejście/wyjście, schowek
--]]

-- Cache nieruchomości
local houses = {}
-- Cache: [player] = houseId (gracz wewnątrz)
local insideHouse = {}

local function loadHouses()
    local rows = exports.rp_database:dbGetAll("SELECT * FROM houses")
    if not rows then return end
    for _, row in ipairs(rows) do
        houses[row.id] = {
            id       = row.id,
            ownerId  = row.owner_id,
            name     = row.name,
            pos      = {x=row.pos_x,  y=row.pos_y,  z=row.pos_z },
            int_pos  = {x=row.int_x,  y=row.int_y,  z=row.int_z },
            interior = row.interior,
            price    = row.price,
            forSale  = row.for_sale == 1,
            locked   = row.locked   == 1,
            rent     = row.rent_price,
        }
    end
    outputServerLog("[rp_houses] " .. #houses .. " domów załadowanych.")
end

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    loadHouses()

    -- Utwórz markery
    for id, h in pairs(houses) do
        local col = h.forSale and tocolor(60,200,100,180) or tocolor(30,144,255,180)
        local m = createMarker(h.pos.x, h.pos.y, h.pos.z-1, "cylinder", 1.5, 30,144,255,160)
        setElementData(m, "houseId", id, false)
        local b = createBlip(h.pos.x, h.pos.y, h.pos.z, 31, 1.5, 30,144,255,255)
        setBlipName(b, h.name .. (h.forSale and " [NA SPRZEDAŻ]" or ""))
    end
end)

-- Marker wejście → pokazanie panelu domu
addEventHandler("onMarkerHit", root, function(hitPlayer, dim)
    if getElementType(hitPlayer) ~= "player" then return end
    if not exports.rp_characters:isSpawned(hitPlayer) then return end

    local houseId = getElementData(source, "houseId")
    if not houseId then return end
    local h = houses[houseId]
    if not h then return end

    local charId = exports.rp_characters:getCharId(hitPlayer)
    local c      = exports.rp_characters:getCharacter(hitPlayer)

    triggerClientEvent(hitPlayer, "rpHouse:showPanel", hitPlayer, h, c.cash, charId == h.ownerId)
end)

-- ============================================================
--  KUPNO
-- ============================================================
addEvent("rpHouse:buy", true)
addEventHandler("rpHouse:buy", root, function(houseId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "house_buy", 3000) then return end

    houseId = tonumber(houseId)
    local h = houses[houseId]
    if not h or not h.forSale then
        triggerClientEvent(player,"rpNotif:send",player,"error","Dom","Nieruchomość nie jest na sprzedaż.")
        return
    end

    local charId = exports.rp_characters:getCharId(player)

    -- Max 2 domy
    local count = exports.rp_database:dbGetRow(
        "SELECT COUNT(*) as cnt FROM houses WHERE owner_id=?", charId
    )
    if count and count.cnt >= 2 then
        triggerClientEvent(player,"rpNotif:send",player,"error","Dom","Możesz posiadać maksymalnie 2 domy.")
        return
    end

    local ok, err = exports.rp_economy:takeCash(player, h.price, "buy_house")
    if not ok then
        triggerClientEvent(player,"rpNotif:send",player,"error","Dom", err)
        return
    end

    h.ownerId = charId
    h.forSale = false
    h.locked  = true

    exports.rp_database:dbExecute(
        "UPDATE houses SET owner_id=?, for_sale=0, locked=1 WHERE id=?",
        charId, houseId
    )

    local c = exports.rp_characters:getCharacter(player)
    triggerClientEvent(player,"rpNotif:send",player,"success","Dom",
        "Zakupiono: " .. h.name .. " za " .. formatMoney(h.price))
    exports.rp_logs:logAdmin(c.name, nil, "buy_house", h.name .. " | " .. h.price)
end)

-- ============================================================
--  SPRZEDAŻ (gracz → serwer, 70% ceny)
-- ============================================================
addEvent("rpHouse:sell", true)
addEventHandler("rpHouse:sell", root, function(houseId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end

    houseId = tonumber(houseId)
    local h = houses[houseId]
    if not h then return end

    local charId = exports.rp_characters:getCharId(player)
    if h.ownerId ~= charId then
        triggerClientEvent(player,"rpNotif:send",player,"error","Dom","To nie Twój dom.")
        return
    end

    local sellPrice = math.floor(h.price * 0.7)
    exports.rp_economy:giveCash(player, sellPrice, "sell_house")

    h.ownerId = nil
    h.forSale = true
    h.locked  = true

    exports.rp_database:dbExecute(
        "UPDATE houses SET owner_id=NULL, for_sale=1 WHERE id=?", houseId
    )

    triggerClientEvent(player,"rpNotif:send",player,"success","Dom",
        "Sprzedano: " .. h.name .. " za " .. formatMoney(sellPrice))
end)

-- ============================================================
--  ZAMKNIJ / OTWÓRZ DOM
-- ============================================================
addEvent("rpHouse:toggleLock", true)
addEventHandler("rpHouse:toggleLock", root, function(houseId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end

    houseId = tonumber(houseId)
    local h = houses[houseId]
    if not h then return end
    local charId = exports.rp_characters:getCharId(player)
    if h.ownerId ~= charId then
        triggerClientEvent(player,"rpNotif:send",player,"error","Dom","To nie Twój dom.")
        return
    end

    h.locked = not h.locked
    exports.rp_database:dbExecute("UPDATE houses SET locked=? WHERE id=?", h.locked and 1 or 0, houseId)
    triggerClientEvent(player,"rpNotif:send",player,"info","Dom",
        h.locked and "Dom zamknięty." or "Dom otwarty.")
end)

-- ============================================================
--  WEJŚCIE / WYJŚCIE
-- ============================================================
addEvent("rpHouse:enter", true)
addEventHandler("rpHouse:enter", root, function(houseId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end

    houseId = tonumber(houseId)
    local h = houses[houseId]
    if not h then return end

    local charId = exports.rp_characters:getCharId(player)

    if h.locked and h.ownerId ~= charId then
        triggerClientEvent(player,"rpNotif:send",player,"error","Dom","Dom jest zamknięty.")
        return
    end

    setElementPosition(player, h.int_pos.x, h.int_pos.y, h.int_pos.z)
    setElementInterior(player, h.interior)
    setElementDimension(player, houseId + 1000)
    insideHouse[player] = houseId

    triggerClientEvent(player,"rpNotif:send",player,"info","Dom","Weszłeś do domu. /wyjdz aby wyjść.")
end)

addCommandHandler("wyjdz", function(player)
    local houseId = insideHouse[player]
    if not houseId then return end
    local h = houses[houseId]
    if not h then return end

    setElementPosition(player, h.pos.x, h.pos.y, h.pos.z)
    setElementInterior(player, 0)
    setElementDimension(player, 0)
    insideHouse[player] = nil
end)

-- Czyszczenie przy wyjściu
addEventHandler("onPlayerQuit", root, function()
    insideHouse[source] = nil
end)
