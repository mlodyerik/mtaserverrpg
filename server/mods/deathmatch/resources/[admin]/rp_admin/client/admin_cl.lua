--[[
    rp_admin – Panel admina (klient DX)
--]]

local W, H = guiGetScreenSize()
local PW,PH = 700, 480
local PX = (W-PW)/2
local PY = (H-PH)/2

local panelOpen  = false
local panelAlpha = 0
local players    = {}
local selectedP  = 1
local noclipOn   = false

addEvent("rpAdmin:openPanel", true)
addEventHandler("rpAdmin:openPanel", root, function(pList)
    players   = pList or {}
    selectedP = 1
    panelOpen = true
    panelAlpha = 0
    showCursor(true)
    addEventHandler("onClientRender", root, renderAdminPanel)
end)

addEvent("rpAdmin:toggleNoclip", true)
addEventHandler("rpAdmin:toggleNoclip", root, function()
    noclipOn = not noclipOn
    setPlayerNoclip(localPlayer, noclipOn)
    triggerEvent("rpNotif:local", localPlayer, noclipOn and "warning" or "info","Admin",
        "NoClip: " .. (noclipOn and "WŁĄCZONY" or "WYŁĄCZONY"))
end)

function renderAdminPanel()
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
    dxDrawText("PANEL ADMINISTRACYJNY ["..#players.." graczy]",
        PX+12,PY+10,PX+PW-40,PY+36,ac,1.2,"default-bold","left","top")
    dxDrawText("✕",PX+PW-34,PY+8,PX+PW-8,PY+34,tocolor(220,60,60,a),1.2,"default-bold","center","center")

    dxDrawRectangle(PX+12,PY+44,PW-24,1,tocolor(40,45,55,a))

    -- Lista graczy (lewa)
    for i, p in ipairs(players) do
        local ry = PY + 50 + (i-1)*38
        if ry > PY+PH-60 then break end
        local isSel = (selectedP == i)
        dxDrawRectangle(PX+12,ry,280,34,isSel and tocolor(22,25,40,a) or tocolor(18,18,24,a))
        if isSel then dxDrawRectangle(PX+12,ry,3,34,ac) end
        dxDrawText(p.name,PX+20,ry+4,PX+200,ry+22,isSel and tx or dm,0.9,isSel and "default-bold" or "default","left","top")
        dxDrawText("Lvl."..p.level.."  Ping:"..p.ping,PX+20,ry+20,PX+290,ry+36,dm,0.8,"default","left","top")
    end

    -- Akcje (prawa)
    if selectedP and players[selectedP] then
        local p = players[selectedP]
        local ax = PX+310
        dxDrawText("Gracz: "..p.name,ax,PY+54,PX+PW-12,PY+76,tx,1.1,"default-bold","left","top")
        dxDrawText("Gotówka: "..formatMoney(p.cash),ax,PY+78,PX+PW-12,PY+96,gr,0.9,"default","left","top")
        dxDrawText("Serial: "..p.serial,ax,PY+96,PX+PW-12,PY+114,dm,0.8,"default","left","top")

        local btnY = PY + 124
        local actions = {
            {"Teleportuj do gracza",    "tp"},
            {"Teleportuj gracza do mnie","tphere"},
            {"Napraw pojazd gracza",     "repair"},
            {"Zamroź",                  "freeze"},
            {"Odmroź",                  "unfreeze"},
            {"Kick",                    "kick"},
        }
        for j, act in ipairs(actions) do
            local by = btnY + (j-1)*38
            dxDrawRectangle(ax,by,PW-330,30,tocolor(22,25,32,a))
            dxDrawText(act[1],ax+8,by+4,ax+PW-340,by+26,dm,0.9,"default","left","top")
        end
    end

    dxDrawText("/adminpanel | /kick | /ban | /setcash | /setlevel | /tp | /tphere | /announce | /spawnveh",
        PX,PY+PH-18,PX+PW,PY+PH-4,dm,0.75,"default","center","top")
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 150 then return end

    if cx>=PX+PW-34 and cx<=PX+PW-8 and cy>=PY+8 and cy<=PY+34 then
        closeAdmin() return
    end

    for i, p in ipairs(players) do
        local ry = PY+50+(i-1)*38
        if ry > PY+PH-60 then break end
        if cx>=PX+12 and cx<=PX+292 and cy>=ry and cy<=ry+34 then
            selectedP = i return
        end
    end

    if selectedP and players[selectedP] then
        local ax  = PX+310
        local btnY= PY+124
        local acts= {"tp","tphere","repair","freeze","unfreeze","kick"}
        for j, act in ipairs(acts) do
            local by = btnY+(j-1)*38
            if cx>=ax and cx<=ax+PW-330 and cy>=by and cy<=by+30 then
                local pname = players[selectedP].name
                executeCommandHandler(act, localPlayer, act, pname)
                closeAdmin()
            end
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if key == "escape" and press and panelOpen then closeAdmin() end
    if key == "F10" and press then
        triggerServerEvent("rpAdmin:requestPanel", localPlayer)
    end
end)

-- F10 żądanie panelu
addEvent("rpAdmin:requestPanel", true)

function closeAdmin()
    panelOpen = false
    panelAlpha = 0
    removeEventHandler("onClientRender", root, renderAdminPanel)
    showCursor(false)
end

addEventHandler("onClientResourceStop", resourceRoot, function()
    removeEventHandler("onClientRender", root, renderAdminPanel)
end)
