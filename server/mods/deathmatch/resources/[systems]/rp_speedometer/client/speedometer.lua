--[[
    rp_speedometer – klient
    Styl inspirowany 4Life: ciemny pasek na dole ekranu
    Lewy blok: prędkość (duża cyfra), km/h pod spodem
    Środkowy blok: ikona biegu, ikona silnika, ikona świateł, ikona pasa
    Prawy blok: pasek paliwa, przebieg
    Kolor akcentu: konfigurowalny
--]]

local W, H = guiGetScreenSize()

local speedoActive  = false
local speedoModel   = 1
local accentColor   = {30, 144, 255}
local colorMap      = {}

-- ============================================================
--  DANE POJAZDU (aktualizowane co klatkę)
-- ============================================================
local vData = {
    speed   = 0,
    gear    = 0,
    fuel    = 100,
    mileage = 0,
    engine  = false,
    lights  = false,
    locked  = false,
    seatbelt= false,
    health  = 1000,
}

local BAR_W  = 520
local BAR_H  = 64
local BAR_X  = (W - BAR_W) / 2
local BAR_Y  = H - BAR_H - 12

-- ============================================================
--  RENDER CO KLATKĘ
-- ============================================================
addEventHandler("onClientRender", root, function()
    if not speedoActive then return end

    local veh = getPedOcciedVehicle and getPedOccupiedVehicle(localPlayer)
                or getPedOccupiedVehicle(localPlayer)
    if not veh then return end

    -- Zebranie danych
    local vx, vy, vz = getElementVelocity(veh)
    local spd = math.floor(math.sqrt(vx*vx + vy*vy + vz*vz) * 200.0 * 0.621371 * 1.60934)
    -- poprawka: 1 unit/s ≈ ~3 km/h w MTA (zależy od pojazdu), empirycznie:
    spd = math.floor(math.sqrt(vx*vx + vy*vy + vz*vz) * 100 * 1.60934 * 2.23694 * 0.44704 * 3.6)
    -- Prosta formuła używana na większości serwerów MTA:
    spd = math.floor(math.sqrt(vx^2 + vy^2 + vz^2) * 180)
    spd = math.max(0, spd)

    vData.speed  = spd
    vData.fuel   = getElementData(veh, "fuel") or 100
    vData.mileage= getElementData(veh, "mileage") or 0
    vData.engine = isVehicleEngineOn(veh)
    vData.lights = getVehicleLightState(veh)
    vData.locked = isVehicleLocked(veh)
    vData.gear   = getVehicleCurrentGear(veh) or 0
    vData.health = getElementHealth(veh)

    drawSpeedometer()
end)

function drawSpeedometer()
    local ac  = accentColor
    local aR, aG, aB = ac[1], ac[2], ac[3]

    -- Tło główne
    dxDrawRectangle(BAR_X, BAR_Y, BAR_W, BAR_H, tocolor(12,12,18,215))
    -- Górna linia akcentu
    dxDrawRectangle(BAR_X, BAR_Y, BAR_W, 2, tocolor(aR,aG,aB,200))

    -- ======== SEKCJA LEWA: PRĘDKOŚĆ ========
    local speedStr = tostring(vData.speed)
    dxDrawText(speedStr,
        BAR_X + 10, BAR_Y + 2, BAR_X + 120, BAR_Y + BAR_H - 4,
        tocolor(aR,aG,aB,255), 2.8,"default-bold","left","center")
    dxDrawText("km/h",
        BAR_X + 10, BAR_Y + BAR_H - 18, BAR_X + 110, BAR_Y + BAR_H - 4,
        tocolor(140,148,160,200), 0.85,"default","left","bottom")

    -- Separator
    dxDrawRectangle(BAR_X + 120, BAR_Y + 8, 1, BAR_H - 16, tocolor(40,45,55,220))

    -- ======== SEKCJA ŚRODKOWA: IKONY STANU ========
    local iconX = BAR_X + 132
    local iconY = BAR_Y + 8
    local iconSize = BAR_H - 16

    -- Bieg
    local gearStr = vData.gear == 0 and "N" or tostring(vData.gear)
    dxDrawText("⚙", iconX, iconY, iconX+28, iconY+iconSize,
        tocolor(140,148,160,200), 0.85,"default","center","center")
    dxDrawText(gearStr, iconX+28, iconY, iconX+60, iconY+iconSize,
        tocolor(220,225,235,230), 1.1,"default-bold","left","center")

    -- Silnik
    local engColor = vData.engine and tocolor(aR,aG,aB,230) or tocolor(80,85,95,200)
    dxDrawText("ENG", iconX+70, iconY, iconX+110, iconY+iconSize,
        engColor, 0.85,"default-bold","center","center")

    -- Światła
    local lgtColor = (vData.lights > 0) and tocolor(255,220,40,230) or tocolor(80,85,95,200)
    dxDrawText("LGT", iconX+118, iconY, iconX+158, iconY+iconSize,
        lgtColor, 0.85,"default-bold","center","center")

    -- Zamek
    local lckColor = vData.locked and tocolor(220,60,60,230) or tocolor(60,200,100,230)
    dxDrawText(vData.locked and "🔒" or "🔓",
        iconX+165, iconY, iconX+195, iconY+iconSize,
        lckColor, 0.85,"default","center","center")

    -- Stan pojazdu (kolor zdrowia)
    local hpPct = vData.health / 1000
    local hpR,hpG = math.floor(255*(1-hpPct)), math.floor(255*hpPct)
    dxDrawText("⬛",iconX+200, iconY, iconX+220, iconY+iconSize,
        tocolor(hpR,hpG,20,200), 0.85,"default","center","center")

    -- Separator
    dxDrawRectangle(BAR_X + 355, BAR_Y + 8, 1, BAR_H - 16, tocolor(40,45,55,220))

    -- ======== SEKCJA PRAWA: PALIWO + PRZEBIEG ========
    local rx = BAR_X + 365
    local fuelPct = math.max(0, math.min(1, vData.fuel / 100))
    local fuelColor = fuelPct > 0.25 and tocolor(aR,aG,aB,200) or tocolor(220,60,60,200)

    dxDrawText("PALIWO", rx, BAR_Y+6, rx+150, BAR_Y+22, tocolor(140,148,160,200), 0.8,"default","left","top")
    -- Pasek paliwa
    dxDrawRectangle(rx, BAR_Y+24, 148, 10, tocolor(25,25,35,220))
    dxDrawRectangle(rx, BAR_Y+24, math.floor(148*fuelPct), 10, fuelColor)
    dxDrawText(string.format("%.0f%%", fuelPct*100),
        rx, BAR_Y+36, rx+148, BAR_Y+52, fuelColor, 0.85,"default","left","top")

    -- Przebieg
    dxDrawText(string.format("%d km", vData.mileage),
        rx+90, BAR_Y+36, rx+150, BAR_Y+52,
        tocolor(140,148,160,200), 0.8,"default","right","top")

    -- Prędkość wizualna: pasek liniowy
    local maxSpd = 260
    local spdPct = math.min(1, vData.speed / maxSpd)
    local barColors = {
        {0,   tocolor(60,200,100,200)},
        {0.6, tocolor(255,180,40,200)},
        {0.85,tocolor(220,60,60,200)},
    }
    local barColor = barColors[1][2]
    for _, bc in ipairs(barColors) do
        if spdPct >= bc[1] then barColor = bc[2] end
    end
    dxDrawRectangle(BAR_X + 2, BAR_Y + BAR_H - 4, BAR_W - 4, 2, tocolor(25,25,35,220))
    dxDrawRectangle(BAR_X + 2, BAR_Y + BAR_H - 4,
        math.floor((BAR_W-4)*spdPct), 2, barColor)
end

-- ============================================================
--  EVENTY AKTYWACJI
-- ============================================================
addEvent("rpSpeedo:activate", true)
addEventHandler("rpSpeedo:activate", root, function(id, colorId, colors)
    speedoModel  = id or 1
    colorMap     = colors or {}
    local col    = colors and colors[colorId]
    if col then
        accentColor = {col.r, col.g, col.b}
    else
        accentColor = {30,144,255}
    end
    speedoActive = true
end)

-- Wyjście z pojazdu → schowaj ale zostaw aktywny
addEventHandler("onClientVehicleExit", root, function()
    -- prędkościomierz nadal "aktywny", po prostu nie rysuje gdy nie w aucie
end)

-- ============================================================
--  SKLEP PRĘDKOŚCIOMIERZY (DX UI)
-- ============================================================
local shopState  = false
local shopData   = { items={}, colors={}, owned={}, activeId=0, activeColor=1, cash=0 }
local shopAlpha  = 0
local shopAnim   = false
local shopTab    = "buy"  -- buy / color
local shopSelId  = 0
local shopSelClr = 1

addEvent("rpSpeedo:showShop", true)
addEventHandler("rpSpeedo:showShop", root, function(items, colors, owned, activeId, activeColor, cash)
    shopData.items       = items      or {}
    shopData.colors      = colors     or {}
    shopData.owned       = owned      or {}
    shopData.activeId    = activeId   or 0
    shopData.activeColor = activeColor or 1
    shopData.cash        = cash       or 0
    shopSelId  = activeId  or 0
    shopSelClr = activeColor or 1
    shopTab    = "buy"
    shopState  = true
    shopAlpha  = 0
    shopAnim   = true
    showCursor(true)
    addEventHandler("onClientRender", root, renderShop)
end)

local SW, SH = guiGetScreenSize()
local SPW, SPH = 480, 380
local SPX = (SW - SPW) / 2
local SPY = (SH - SPH) / 2

function renderShop()
    if shopAnim then
        shopAlpha = math.min(255, shopAlpha + 10)
        if shopAlpha >= 255 then shopAnim = false end
    end
    if not shopState or shopAlpha <= 0 then return end

    local a  = math.floor(shopAlpha)
    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(30,144,255,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)

    dxDrawRectangle(SPX, SPY, SPW, SPH, bg)
    dxDrawRectangle(SPX, SPY, SPW, 3, ac)
    dxDrawText("SKLEP PRĘDKOŚCIOMIERZY",SPX,SPY+8,SPX+SPW,SPY+34,ac,1.3,"default-bold","center","top")
    dxDrawText(formatMoney(shopData.cash),SPX,SPY+8,SPX+SPW-12,SPY+34,tocolor(60,200,100,a),1.0,"default-bold","right","top")

    -- Zakładki
    local tab1Color = shopTab=="buy"   and ac or tocolor(40,45,55,a)
    local tab2Color = shopTab=="color" and ac or tocolor(40,45,55,a)
    dxDrawRectangle(SPX+20, SPY+40, 100, 26, tocolor(22,25,32,a))
    dxDrawRectangle(SPX+20, SPY+64, 100, 2, tab1Color)
    dxDrawText("KUP", SPX+20,SPY+40,SPX+120,SPY+66,shopTab=="buy" and tx or dm,1.0,"default","center","center")
    dxDrawRectangle(SPX+128, SPY+40, 100, 26, tocolor(22,25,32,a))
    dxDrawRectangle(SPX+128, SPY+64, 100, 2, tab2Color)
    dxDrawText("KOLOR", SPX+128,SPY+40,SPX+228,SPY+66,shopTab=="color" and tx or dm,1.0,"default","center","center")

    dxDrawRectangle(SPX+20,SPY+72,SPW-40,1,tocolor(40,45,55,a))

    if shopTab == "buy" then
        drawShopBuy(a, ac, tx, dm)
    else
        drawShopColor(a, ac, tx, dm)
    end

    -- Zamknij
    dxDrawRectangle(SPX+SPW-34, SPY+6, 26, 26, tocolor(50,20,20,a))
    dxDrawText("✕", SPX+SPW-34,SPY+6,SPX+SPW-8,SPY+32,tocolor(220,60,60,a),1.2,"default-bold","center","center")
end

function drawShopBuy(a,ac,tx,dm)
    local row = 0
    for id, item in pairs(shopData.items) do
        local ry = SPY + 84 + row * 52
        -- Sprawdź czy posiadane
        local owned = false
        for _, o in ipairs(shopData.owned) do
            if o.speedo_id == id then owned = true break end
        end
        local isActive = (shopData.activeId == id)
        local borderC  = isActive and ac or tocolor(40,45,55,a)
        dxDrawRectangle(SPX+20, ry, SPW-40, 44, tocolor(22,25,32,a))
        dxDrawRectangle(SPX+20, ry, SPW-40, 2, borderC)
        dxDrawText(item.name, SPX+30,ry+6,SPX+200,ry+30,isActive and ac or tx,1.0,"default-bold","left","top")
        dxDrawText(formatMoney(item.price),SPX+200,ry+6,SPX+340,ry+30,tocolor(60,200,100,a),1.0,"default","right","top")
        if owned then
            dxDrawText("✔ POSIADANY",SPX+340,ry+6,SPX+SPW-24,ry+30,tocolor(60,200,100,a),0.9,"default","right","top")
        else
            dxDrawRectangle(SPX+SPW-90,ry+8,68,28,ac)
            dxDrawText("KUP",SPX+SPW-90,ry+8,SPX+SPW-22,ry+36,tocolor(255,255,255,a),1.0,"default-bold","center","center")
        end
        row = row + 1
        if row >= 5 then break end
    end
end

function drawShopColor(a,ac,tx,dm)
    if shopData.activeId == 0 then
        dxDrawText("Najpierw kup prędkościomierz.",SPX,SPY+120,SPX+SPW,SPY+150,dm,1.0,"default","center","top")
        return
    end
    local row = 0
    for cid, col in pairs(shopData.colors) do
        local cx = SPX + 30 + (row % 3) * 140
        local cy = SPY + 90 + math.floor(row/3) * 80
        local isActive = (shopSelClr == cid)
        dxDrawRectangle(cx, cy, 120, 60, tocolor(22,25,32,a))
        dxDrawRectangle(cx, cy, 120, 4, tocolor(col.r,col.g,col.b,isActive and 255 or 120))
        dxDrawText(col.name, cx,cy+10,cx+120,cy+40, tocolor(col.r,col.g,col.b,a),0.95,"default-bold","center","top")
        if isActive then
            dxDrawText("AKTYWNY",cx,cy+38,cx+120,cy+58,tocolor(col.r,col.g,col.b,a),0.8,"default","center","top")
        else
            dxDrawRectangle(cx+30,cy+38,60,20,ac)
            dxDrawText("WYBIERZ",cx+30,cy+38,cx+90,cy+58,tocolor(255,255,255,a),0.8,"default-bold","center","center")
        end
        row = row + 1
    end
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not shopState then return end

    -- Zamknij
    if cx >= SPX+SPW-34 and cx <= SPX+SPW-8 and cy >= SPY+6 and cy <= SPY+32 then
        closeShop()
        return
    end

    -- Zakładki
    if cy >= SPY+40 and cy <= SPY+66 then
        if cx >= SPX+20 and cx <= SPX+120 then shopTab = "buy" end
        if cx >= SPX+128 and cx <= SPX+228 then shopTab = "color" end
        return
    end

    if shopTab == "buy" then
        local row = 0
        for id, item in pairs(shopData.items) do
            local ry = SPY + 84 + row * 52
            local owned = false
            for _, o in ipairs(shopData.owned) do
                if o.speedo_id == id then owned = true break end
            end
            if not owned then
                if cx >= SPX+SPW-90 and cx <= SPX+SPW-22 and cy >= ry+8 and cy <= ry+36 then
                    triggerServerEvent("rpSpeedo:buy", localPlayer, id)
                    closeShop()
                    return
                end
            end
            row = row + 1
        end
    elseif shopTab == "color" then
        if shopData.activeId == 0 then return end
        local row = 0
        for cid, col in pairs(shopData.colors) do
            local px = SPX + 30 + (row % 3) * 140
            local py = SPY + 90 + math.floor(row/3) * 80
            if cx >= px+30 and cx <= px+90 and cy >= py+38 and cy <= py+58 then
                shopSelClr = cid
                triggerServerEvent("rpSpeedo:setColor", localPlayer, cid)
                shopData.activeColor = cid
                return
            end
            row = row + 1
        end
    end
end)

function closeShop()
    shopState = false
    shopAlpha = 0
    removeEventHandler("onClientRender", root, renderShop)
    showCursor(false)
end
