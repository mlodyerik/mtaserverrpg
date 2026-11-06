--[[
    rp_houses – Klient: panel nieruchomości
--]]

local W, H = guiGetScreenSize()
local PW,PH = 400,300
local PX,PY = (W-PW)/2, (H-PH)/2

local panelOpen = false
local panelAlpha= 0
local houseInfo = nil
local isOwner   = false
local playerCash= 0

addEvent("rpHouse:showPanel", true)
addEventHandler("rpHouse:showPanel", root, function(h, cash, ownerFlag)
    houseInfo  = h
    isOwner    = ownerFlag
    playerCash = cash
    panelOpen  = true
    panelAlpha = 0
    showCursor(true)
    addEventHandler("onClientRender", root, renderHousePanel)
end)

function renderHousePanel()
    panelAlpha = math.min(255, panelAlpha+10)
    if not panelOpen then return end

    local a  = math.floor(panelAlpha)
    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(30,144,255,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)
    local gr = tocolor(60,200,100,a)

    dxDrawRectangle(PX,PY,PW,PH,bg)
    dxDrawRectangle(PX,PY,PW,3,ac)

    local icon = houseInfo.forSale and "🏠 NA SPRZEDAŻ" or (isOwner and "🏠 TWÓJ DOM" or "🏠 DOM")
    dxDrawText(icon,PX+12,PY+10,PX+PW-40,PY+36,ac,1.2,"default-bold","left","top")
    dxDrawText("✕",PX+PW-34,PY+8,PX+PW-8,PY+34,tocolor(220,60,60,a),1.2,"default-bold","center","center")

    dxDrawRectangle(PX+12,PY+44,PW-24,1,tocolor(40,45,55,a))

    dxDrawText(houseInfo.name,PX+12,PY+52,PX+PW-12,PY+74,tx,1.1,"default-bold","left","top")
    dxDrawText("Cena: " .. formatMoney(houseInfo.price),PX+12,PY+78,PX+PW-12,PY+98,gr,1.0,"default","left","top")
    dxDrawText("Czynsz miesięczny: " .. formatMoney(houseInfo.rent or 0),
        PX+12,PY+100,PX+PW-12,PY+120,dm,0.9,"default","left","top")

    dxDrawRectangle(PX+12,PY+124,PW-24,1,tocolor(40,45,55,a))

    local btnY = PY+132

    if houseInfo.forSale and not isOwner then
        local canBuy = playerCash >= houseInfo.price
        dxDrawRectangle(PX+12,btnY,PW-24,38,canBuy and ac or tocolor(40,40,50,a))
        dxDrawText("KUP DOM (" .. formatMoney(houseInfo.price) .. ")",
            PX+12,btnY,PX+PW-12,btnY+38,
            canBuy and tocolor(255,255,255,a) or tocolor(100,100,120,a),
            1.1,"default-bold","center","center")
        btnY = btnY + 46
    end

    if isOwner then
        dxDrawRectangle(PX+12,btnY,PW-24,34,ac)
        dxDrawText("WEJDŹ",PX+12,btnY,PX+PW-12,btnY+34,tocolor(255,255,255,a),1.0,"default-bold","center","center")
        btnY = btnY + 42

        dxDrawRectangle(PX+12,btnY,(PW-30)/2,30,tocolor(22,25,32,a))
        dxDrawText(houseInfo.locked and "🔒 OTWÓRZ" or "🔓 ZAMKNIJ",
            PX+12,btnY,PX+12+(PW-30)/2,btnY+30,dm,0.9,"default","center","center")

        dxDrawRectangle(PX+18+(PW-30)/2,btnY,(PW-30)/2,30,tocolor(80,20,20,a))
        dxDrawText("SPRZEDAJ (70%)",
            PX+18+(PW-30)/2,btnY,PX+PW-12,btnY+30,tocolor(220,60,60,a),0.9,"default","center","center")
        btnY = btnY + 38
    end

    if not houseInfo.forSale and not isOwner then
        dxDrawText("Dom prywatny. Właściciel: #" .. (houseInfo.ownerId or "?"),
            PX+12,btnY,PX+PW-12,btnY+24,dm,0.9,"default","center","top")
    end
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 150 then return end
    if not houseInfo then return end

    if cx>=PX+PW-34 and cx<=PX+PW-8 and cy>=PY+8 and cy<=PY+34 then closeHouse() return end

    local btnY = PY+132
    if houseInfo.forSale and not isOwner then
        if cx>=PX+12 and cx<=PX+PW-12 and cy>=btnY and cy<=btnY+38 then
            if playerCash >= houseInfo.price then
                triggerServerEvent("rpHouse:buy", localPlayer, houseInfo.id)
            end
            closeHouse()
            return
        end
        btnY = btnY + 46
    end

    if isOwner then
        if cx>=PX+12 and cx<=PX+PW-12 and cy>=btnY and cy<=btnY+34 then
            triggerServerEvent("rpHouse:enter", localPlayer, houseInfo.id)
            closeHouse() return
        end
        btnY = btnY + 42

        local halfW = (PW-30)/2
        if cx>=PX+12 and cx<=PX+12+halfW and cy>=btnY and cy<=btnY+30 then
            triggerServerEvent("rpHouse:toggleLock", localPlayer, houseInfo.id)
            closeHouse() return
        end
        if cx>=PX+18+halfW and cx<=PX+PW-12 and cy>=btnY and cy<=btnY+30 then
            triggerServerEvent("rpHouse:sell", localPlayer, houseInfo.id)
            closeHouse() return
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if key=="escape" and press and panelOpen then closeHouse() end
end)

function closeHouse()
    panelOpen = false
    removeEventHandler("onClientRender", root, renderHousePanel)
    showCursor(false)
end
