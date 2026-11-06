--[[
    rp_tuning – Klient: panel warsztatu DX
    Zakładki: Ulepszenia | Lakiernia | Naprawa
--]]

local W, H   = guiGetScreenSize()
local PW,PH  = 580, 460
local PX = (W-PW)/2
local PY = (H-PH)/2

local panelOpen   = false
local panelAlpha  = 0
local panelTab    = "upgrades"  -- upgrades / paint / repair
local tuningItems = {}
local paintJobs   = {}
local installed   = {}
local playerCash  = 0
local vehData     = nil
local listOffset  = 0
local ROWS        = 7

addEvent("rpTuning:openShop", true)
addEventHandler("rpTuning:openShop", root, function(vData, items, paints, paintPrice, inst, cash)
    vehData       = vData
    tuningItems   = items or {}
    paintJobs     = paints or {}
    installed     = inst  or {}
    playerCash    = cash  or 0
    panelTab      = "upgrades"
    listOffset    = 0
    panelOpen     = true
    panelAlpha    = 0
    showCursor(true)
    addEventHandler("onClientRender", root, renderTuning)
end)

function isInstalled(upgradeId)
    for _, u in ipairs(installed) do
        if u.upgrade_id == upgradeId then return true end
    end
    return false
end

function renderTuning()
    panelAlpha = math.min(255, panelAlpha+10)
    if not panelOpen then return end
    local a   = math.floor(panelAlpha)
    local bg  = tocolor(15,15,20,math.min(a,220))
    local ac  = tocolor(30,144,255,a)
    local tx  = tocolor(220,225,235,a)
    local dm  = tocolor(140,148,160,a)
    local gr  = tocolor(60,200,100,a)
    local or2 = tocolor(255,140,30,a)

    dxDrawRectangle(PX,PY,PW,PH,bg)
    dxDrawRectangle(PX,PY,PW,3,or2)
    dxDrawText("WARSZTAT TUNINGOWY",PX,PY+10,PX+PW-40,PY+36,or2,1.3,"default-bold","left","top")
    dxDrawText(formatMoney(playerCash),PX,PY+10,PX+PW-12,PY+36,gr,1.0,"default-bold","right","top")
    dxDrawText("✕",PX+PW-34,PY+8,PX+PW-8,PY+34,tocolor(220,60,60,a),1.2,"default-bold","center","center")

    -- Zakładki
    local tabs = {{"upgrades","Ulepszenia"},{"paint","Lakier"},{"repair","Naprawa"}}
    for i, tab in ipairs(tabs) do
        local tx2 = PX + 12 + (i-1)*130
        local isActive = panelTab == tab[1]
        dxDrawRectangle(tx2, PY+42, 122, 26, tocolor(22,25,32,a))
        dxDrawRectangle(tx2, PY+66, 122, 2, isActive and or2 or tocolor(40,45,55,a))
        dxDrawText(tab[2],tx2,PY+42,tx2+122,PY+68,
            isActive and tx or dm,0.95,isActive and "default-bold" or "default","center","center")
    end
    dxDrawRectangle(PX+12,PY+70,PW-24,1,tocolor(40,45,55,a))

    if panelTab == "upgrades" then
        drawUpgrades(a,or2,tx,dm,gr)
    elseif panelTab == "paint" then
        drawPaint(a,or2,tx,dm,gr)
    elseif panelTab == "repair" then
        drawRepair(a,or2,tx,dm,gr)
    end
end

function drawUpgrades(a,or2,tx,dm,gr)
    for i = 1, ROWS do
        local idx = listOffset + i
        local item = tuningItems[idx]
        if not item then break end
        local ry = PY + 76 + (i-1)*48
        local inst = isInstalled(item.id)
        local canAfford = playerCash >= item.price

        dxDrawRectangle(PX+12,ry,PW-24,42,tocolor(22,25,32,a))

        -- Kategoria
        dxDrawText("["..item.cat.."]",PX+18,ry+4,PX+130,ry+20,dm,0.8,"default","left","top")
        dxDrawText(item.name,PX+18,ry+20,PX+250,ry+42,tx,0.95,"default-bold","left","top")
        dxDrawText(formatMoney(item.price),PX+250,ry+20,PX+350,ry+42,
            canAfford and gr or tocolor(220,60,60,a),0.95,"default-bold","right","top")

        if inst then
            dxDrawText("✔ ZAINSTALOWANE",PX+360,ry+10,PX+PW-16,ry+30,gr,0.85,"default","right","top")
            dxDrawRectangle(PX+PW-90,ry+26,76,14,tocolor(80,20,20,a))
            dxDrawText("USUŃ",PX+PW-90,ry+26,PX+PW-14,ry+40,tocolor(220,60,60,a),0.75,"default","center","center")
        else
            if canAfford then
                dxDrawRectangle(PX+PW-90,ry+8,76,28,or2)
                dxDrawText("KUP",PX+PW-90,ry+8,PX+PW-14,ry+36,tocolor(255,255,255,a),0.95,"default-bold","center","center")
            else
                dxDrawText("Za mało $",PX+PW-100,ry+10,PX+PW-14,ry+30,tocolor(220,60,60,a),0.8,"default","right","top")
            end
        end
    end
    -- Scroll
    if #tuningItems > ROWS then
        dxDrawText(string.format("▲▼ Scroll (%d/%d)",listOffset+1,#tuningItems),
            PX,PY+PH-20,PX+PW,PY+PH-4,dm,0.8,"default","center","top")
    end
end

function drawPaint(a,or2,tx,dm,gr)
    dxDrawText("Zmiana koloru: " .. formatMoney(PAINT_PRICE or 500),
        PX+12,PY+76,PX+PW-12,PY+96,dm,0.9,"default","left","top")
    local row = 0
    for _, paint in ipairs(paintJobs) do
        local px2 = PX + 16 + (row%3)*185
        local py2 = PY + 102 + math.floor(row/3)*68
        local canA = playerCash >= (PAINT_PRICE or 500)
        dxDrawRectangle(px2,py2,175,60,tocolor(22,25,32,a))
        dxDrawRectangle(px2,py2,175,4,tocolor(paint.r,paint.g,paint.b,200))
        dxDrawText(paint.name,px2,py2+8,px2+175,py2+30,tx,0.9,"default-bold","center","top")
        if canA then
            dxDrawRectangle(px2+20,py2+34,135,22,or2)
            dxDrawText("LAKIERUJ",px2+20,py2+34,px2+155,py2+56,tocolor(255,255,255,a),0.85,"default-bold","center","center")
        else
            dxDrawText("Za mało $",px2,py2+34,px2+175,py2+56,tocolor(220,60,60,a),0.8,"default","center","top")
        end
        row = row + 1
    end
end

function drawRepair(a,or2,tx,dm,gr)
    local veh = getPedOccupiedVehicle(localPlayer)
    local hp  = veh and getElementHealth(veh) or 1000
    local dmg = 1000 - hp
    local cost= math.max(200, math.floor(dmg * 0.8))
    local pct = hp/1000

    dxDrawText("Stan pojazdu",PX+12,PY+86,PX+PW-12,PY+106,dm,0.95,"default","left","top")
    dxDrawRectangle(PX+12,PY+110,PW-24,14,tocolor(25,25,35,a))
    dxDrawRectangle(PX+12,PY+110,math.floor((PW-24)*pct),14,
        pct>0.6 and tocolor(60,200,100,a) or pct>0.3 and tocolor(255,180,40,a) or tocolor(220,60,60,a))
    dxDrawText(string.format("%.0f%%",pct*100),PX+12,PY+126,PX+PW-12,PY+144,tx,0.9,"default","left","top")

    dxDrawText("Koszt naprawy: " .. formatMoney(cost),PX+12,PY+152,PX+PW-12,PY+172,tx,1.0,"default","left","top")
    dxDrawText("(pełne paliwo gratis!)",PX+12,PY+172,PX+PW-12,PY+190,dm,0.85,"default","left","top")

    local canRepair = playerCash >= cost and hp < 1000
    if canRepair then
        dxDrawRectangle(PX+12,PY+200,PW-24,42,or2)
        dxDrawText("NAPRAW POJAZD",PX+12,PY+200,PX+PW-12,PY+242,
            tocolor(255,255,255,a),1.2,"default-bold","center","center")
    else
        dxDrawText(hp >= 1000 and "Pojazd jest sprawny!" or "Za mało gotówki",
            PX+12,PY+200,PX+PW-12,PY+242,dm,1.0,"default","center","center")
    end
end

-- ============================================================
--  KLIKNIĘCIA
-- ============================================================
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 150 then return end

    -- Zamknij
    if cx >= PX+PW-34 and cx <= PX+PW-8 and cy >= PY+8 and cy <= PY+34 then
        closeTuning() return
    end

    -- Zakładki
    local tabs = {"upgrades","paint","repair"}
    for i, tab in ipairs(tabs) do
        local tx2 = PX + 12 + (i-1)*130
        if cx >= tx2 and cx <= tx2+122 and cy >= PY+42 and cy <= PY+68 then
            panelTab = tab return
        end
    end

    if panelTab == "upgrades" then
        for i = 1, ROWS do
            local idx = listOffset + i
            local item = tuningItems[idx]
            if not item then break end
            local ry = PY + 76 + (i-1)*48
            -- Kup
            if cx >= PX+PW-90 and cx <= PX+PW-14 and cy >= ry+8 and cy <= ry+36 then
                if not isInstalled(item.id) and playerCash >= item.price then
                    triggerServerEvent("rpTuning:buyUpgrade", localPlayer, item.id)
                    closeTuning()
                end
            end
            -- Usuń
            if cx >= PX+PW-90 and cx <= PX+PW-14 and cy >= ry+26 and cy <= ry+40 then
                if isInstalled(item.id) then
                    triggerServerEvent("rpTuning:removeUpgrade", localPlayer, item.id)
                    closeTuning()
                end
            end
        end
    elseif panelTab == "paint" then
        local row = 0
        for _, paint in ipairs(paintJobs) do
            local px2 = PX + 16 + (row%3)*185
            local py2 = PY + 102 + math.floor(row/3)*68
            if cx >= px2+20 and cx <= px2+155 and cy >= py2+34 and cy <= py2+56 then
                if playerCash >= (PAINT_PRICE or 500) then
                    triggerServerEvent("rpTuning:paint", localPlayer, paint.id)
                    closeTuning()
                end
            end
            row = row + 1
        end
    elseif panelTab == "repair" then
        if cx >= PX+12 and cx <= PX+PW-12 and cy >= PY+200 and cy <= PY+242 then
            triggerServerEvent("rpTuning:repair", localPlayer)
            closeTuning()
        end
    end
end)

-- Scroll
addEventHandler("onClientKey", root, function(key, press)
    if not panelOpen or not press then return end
    if key == "mouse_wheel_up"   then listOffset = math.max(0, listOffset-1) end
    if key == "mouse_wheel_down" then listOffset = math.min(math.max(0,#tuningItems-ROWS), listOffset+1) end
    if key == "escape" then closeTuning() end
end)

function closeTuning()
    panelOpen = false
    panelAlpha = 0
    removeEventHandler("onClientRender", root, renderTuning)
    showCursor(false)
end
