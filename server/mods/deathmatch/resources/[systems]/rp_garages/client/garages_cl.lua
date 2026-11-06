--[[
    rp_garages – Panel garażu (klient DX)
--]]

local W, H = guiGetScreenSize()
local PW,PH = 480, 400
local PX,PY = (W-PW)/2, (H-PH)/2

local panelOpen  = false
local panelAlpha = 0
local vehList    = {}
local selectedIdx= 1

addEvent("rpGarage:openPanel", true)
addEventHandler("rpGarage:openPanel", root, function(vehicles, garId, pubId)
    vehList     = vehicles or {}
    selectedIdx = 1
    panelOpen   = true
    panelAlpha  = 0
    showCursor(true)
    addEventHandler("onClientRender", root, renderGarage)
end)

function renderGarage()
    panelAlpha = math.min(255, panelAlpha+10)
    if not panelOpen then return end

    local a  = math.floor(panelAlpha)
    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(255,180,0,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)
    local gr = tocolor(60,200,100,a)

    dxDrawRectangle(PX,PY,PW,PH,bg)
    dxDrawRectangle(PX,PY,PW,3,ac)
    dxDrawText("🚗 GARAŻ / PARKING", PX+12,PY+10,PX+PW-40,PY+36,ac,1.2,"default-bold","left","top")
    dxDrawText("Pojazdy: " .. #vehList,PX,PY+10,PX+PW-12,PY+36,dm,0.9,"default","right","top")
    dxDrawText("✕",PX+PW-34,PY+8,PX+PW-8,PY+34,tocolor(220,60,60,a),1.2,"default-bold","center","center")
    dxDrawRectangle(PX+12,PY+44,PW-24,1,tocolor(40,45,55,a))

    if #vehList == 0 then
        dxDrawText("Nie posiadasz żadnych pojazdów.",PX,PY+160,PX+PW,PY+190,dm,1.0,"default","center","top")
    else
        for i, v in ipairs(vehList) do
            local ry = PY+52+(i-1)*54
            if ry > PY+PH-70 then break end
            local isSel = selectedIdx == i
            dxDrawRectangle(PX+12,ry,PW-24,48,isSel and tocolor(22,25,40,a) or tocolor(18,18,24,a))
            if isSel then dxDrawRectangle(PX+12,ry,3,48,ac) end

            dxDrawText(v.name,PX+20,ry+4,PX+200,ry+24,isSel and tx or dm,1.0,isSel and "default-bold" or "default","left","top")
            dxDrawText("TAB: "..v.plate,PX+20,ry+24,PX+200,ry+44,dm,0.8,"default","left","top")

            -- Paliwo
            local fuelPct = (v.fuel or 100)/100
            dxDrawText("Paliwo:", PX+200,ry+4,PX+260,ry+24,dm,0.8,"default","left","top")
            dxDrawRectangle(PX+260,ry+8,100,10,tocolor(25,25,35,a))
            dxDrawRectangle(PX+260,ry+8,math.floor(100*fuelPct),10,
                fuelPct>0.25 and tocolor(30,144,255,200) or tocolor(220,60,60,200))

            local btnX = PX+PW-170
            if v.inGarage then
                dxDrawRectangle(btnX,ry+8,74,30,gr)
                dxDrawText("WYWOŁAJ",btnX,ry+8,btnX+74,ry+38,tocolor(255,255,255,a),0.85,"default-bold","center","center")
            else
                dxDrawRectangle(btnX,ry+8,74,30,tocolor(40,45,55,a))
                dxDrawText("SCHOWAJ",btnX,ry+8,btnX+74,ry+38,dm,0.85,"default","center","center")
            end
        end
    end

    dxDrawText("[↑↓] Nawigacja  [ENTER] Akcja  [ESC] Zamknij",
        PX,PY+PH-18,PX+PW,PY+PH-4,dm,0.75,"default","center","top")
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 150 then return end

    if cx>=PX+PW-34 and cx<=PX+PW-8 and cy>=PY+8 and cy<=PY+34 then closeGarage() return end

    for i, v in ipairs(vehList) do
        local ry  = PY+52+(i-1)*54
        local btnX= PX+PW-170
        if cx>=btnX and cx<=btnX+74 and cy>=ry+8 and cy<=ry+38 then
            selectedIdx = i
            if v.inGarage then
                triggerServerEvent("rpGarage:spawnVehicle", localPlayer, v.id)
            else
                triggerServerEvent("rpGarage:storeVehicle", localPlayer, v.id)
            end
            closeGarage()
            return
        end
        if cx>=PX+12 and cx<=PX+PW-12 and cy>=ry and cy<=ry+48 then
            selectedIdx = i
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not panelOpen or not press then return end
    if key == "arrow_u" or key == "up" then selectedIdx = math.max(1, selectedIdx-1) end
    if key == "arrow_d" or key == "down" then selectedIdx = math.min(#vehList, selectedIdx+1) end
    if key == "return" then
        local v = vehList[selectedIdx]
        if v then
            if v.inGarage then triggerServerEvent("rpGarage:spawnVehicle",localPlayer,v.id)
            else triggerServerEvent("rpGarage:storeVehicle",localPlayer,v.id) end
            closeGarage()
        end
    end
    if key == "escape" then closeGarage() end
end)

function closeGarage()
    panelOpen = false
    removeEventHandler("onClientRender", root, renderGarage)
    showCursor(false)
end
