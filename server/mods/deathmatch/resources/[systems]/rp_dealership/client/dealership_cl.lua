--[[
    rp_dealership – klient: panel zakupu DX
--]]

local W, H  = guiGetScreenSize()
local PW,PH = 640, 480
local PX = (W-PW)/2
local PY = (H-PH)/2

local panelOpen  = false
local panelAlpha = 0
local panelAnim  = false

local dealerData   = nil
local vehicleList  = {}
local playerCash   = 0
local selectedIdx  = 1
local listOffset   = 0
local ROWS_VISIBLE = 8
local previewVeh   = nil

addEvent("rpDealer:showPanel", true)
addEventHandler("rpDealer:showPanel", root, function(dealer, vehicles, cash)
    dealerData   = dealer
    vehicleList  = vehicles
    playerCash   = cash
    selectedIdx  = 1
    listOffset   = 0
    panelOpen    = true
    panelAlpha   = 0
    panelAnim    = true
    showCursor(true)
    addEventHandler("onClientRender", root, renderDealer)
end)

function renderDealer()
    if panelAnim then
        panelAlpha = math.min(255, panelAlpha + 10)
        if panelAlpha >= 255 then panelAnim = false end
    end
    if not panelOpen or panelAlpha <= 0 then return end

    local a  = math.floor(panelAlpha)
    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(30,144,255,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)
    local gr = tocolor(60,200,100,a)

    -- Tło
    dxDrawRectangle(PX, PY, PW, PH, bg)
    dxDrawRectangle(PX, PY, PW, 3, ac)

    -- Nagłówek
    dxDrawText(dealerData and dealerData.name or "Salon", PX,PY+10,PX+PW-60,PY+38,ac,1.3,"default-bold","left","top")
    dxDrawText(formatMoney(playerCash), PX,PY+10,PX+PW-12,PY+38,gr,1.0,"default-bold","right","top")

    -- Zamknij
    dxDrawRectangle(PX+PW-38,PY+8,28,28,tocolor(50,20,20,a))
    dxDrawText("✕",PX+PW-38,PY+8,PX+PW-10,PY+36,tocolor(220,60,60,a),1.2,"default-bold","center","center")

    dxDrawRectangle(PX+12,PY+44,PW-24,1,tocolor(40,45,55,a))

    -- Kolumny
    dxDrawText("POJAZD",  PX+16, PY+50, PX+200, PY+68, dm, 0.85,"default","left","top")
    dxDrawText("KAT.",    PX+200,PY+50, PX+280, PY+68, dm, 0.85,"default","left","top")
    dxDrawText("CENA",    PX+280,PY+50, PX+400, PY+68, dm, 0.85,"default","right","top")
    dxDrawText("AKCJA",   PX+400,PY+50, PX+PW-12,PY+68,dm, 0.85,"default","right","top")
    dxDrawRectangle(PX+12,PY+68,PW-24,1,tocolor(40,45,55,a))

    -- Lista pojazdów
    for i = 1, ROWS_VISIBLE do
        local idx = listOffset + i
        local v   = vehicleList[idx]
        if not v then break end

        local ry  = PY + 72 + (i-1)*46
        local isSel = (idx == selectedIdx)

        if isSel then
            dxDrawRectangle(PX+12, ry, PW-24, 44, tocolor(22,25,40,a))
            dxDrawRectangle(PX+12, ry, 3, 44, ac)
        end

        dxDrawText(v.name, PX+20,ry+4,PX+200,ry+28,isSel and tx or dm,1.0,isSel and "default-bold" or "default","left","top")
        dxDrawText(v.cat,  PX+200,ry+4,PX+280,ry+28,dm,0.85,"default","left","top")

        local canAfford = playerCash >= v.price
        dxDrawText(formatMoney(v.price),
            PX+280,ry+4,PX+400,ry+28,
            canAfford and gr or tocolor(220,60,60,a),
            1.0,"default-bold","right","top")

        if canAfford then
            dxDrawRectangle(PX+PW-100,ry+8,80,28,ac)
            dxDrawText("KUP",PX+PW-100,ry+8,PX+PW-20,ry+36,tocolor(255,255,255,a),1.0,"default-bold","center","center")
        else
            dxDrawText("Za mało $",PX+PW-120,ry+4,PX+PW-12,ry+28,tocolor(220,60,60,a),0.85,"default","right","top")
        end
    end

    -- Scroll info
    if #vehicleList > ROWS_VISIBLE then
        dxDrawText(string.format("▲▼ [%d/%d]", selectedIdx, #vehicleList),
            PX, PY+PH-24, PX+PW, PY+PH-8, dm, 0.85,"default","center","top")
    end
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 200 then return end

    -- Zamknij
    if cx >= PX+PW-38 and cx <= PX+PW-10 and cy >= PY+8 and cy <= PY+36 then
        closeDealer()
        return
    end

    -- Wiersze listy
    for i = 1, ROWS_VISIBLE do
        local idx = listOffset + i
        local v   = vehicleList[idx]
        if not v then break end
        local ry = PY + 72 + (i-1)*46

        if cx >= PX+12 and cx <= PX+PW-12 and cy >= ry and cy <= ry+44 then
            selectedIdx = idx
            -- Kliknięcie w KUP
            if cx >= PX+PW-100 and cx <= PX+PW-20 and playerCash >= v.price then
                triggerServerEvent("rpDealer:buy", localPlayer, dealerData.id, v.model)
                closeDealer()
            end
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not panelOpen or not press then return end
    if key == "arrow_u" or key == "arrow_up" then
        selectedIdx = math.max(1, selectedIdx-1)
        if selectedIdx < listOffset+1 then listOffset = listOffset-1 end
    elseif key == "arrow_d" or key == "arrow_down" then
        selectedIdx = math.min(#vehicleList, selectedIdx+1)
        if selectedIdx > listOffset+ROWS_VISIBLE then listOffset = listOffset+1 end
    elseif key == "escape" then
        closeDealer()
    end
end)

function closeDealer()
    panelOpen  = false
    panelAlpha = 0
    removeEventHandler("onClientRender", root, renderDealer)
    showCursor(false)
end
