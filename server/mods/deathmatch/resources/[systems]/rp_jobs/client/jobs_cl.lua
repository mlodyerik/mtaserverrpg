--[[
    rp_jobs – Klient: panel wyboru pracy, minimap marker, kierownica GPS
--]]

local W, H   = guiGetScreenSize()
local PW,PH  = 420, 320
local PX = (W-PW)/2
local PY = (H-PH)/2

local panelOpen  = false
local panelAlpha = 0
local jobInfo    = nil
local myJobId    = 0
local myJobLvl   = 0

local targetBlip    = nil
local missionActive = false
local missionData   = nil

-- ============================================================
--  PANEL PRACY (z markera)
-- ============================================================
addEvent("rpJobs:showPanel", true)
addEventHandler("rpJobs:showPanel", root, function(job, currentJobId, jobLevel, jobXp)
    jobInfo  = job
    myJobId  = currentJobId
    myJobLvl = jobLevel
    panelOpen = true
    panelAlpha = 0
    showCursor(true)
    addEventHandler("onClientRender", root, renderJobPanel)
end)

function renderJobPanel()
    local a = panelAlpha
    a = math.min(255, a + 10)
    panelAlpha = a
    if not panelOpen then return end

    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(30,144,255,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)

    dxDrawRectangle(PX,PY,PW,PH,bg)
    dxDrawRectangle(PX,PY,PW,3,ac)

    dxDrawText(jobInfo.icon.." "..jobInfo.name, PX+12,PY+12,PX+PW-40,PY+40,ac,1.3,"default-bold","left","top")
    dxDrawText("✕",PX+PW-32,PY+10,PX+PW-8,PY+36,tocolor(220,60,60,a),1.2,"default-bold","center","center")

    dxDrawRectangle(PX+12,PY+44,PW-24,1,tocolor(40,45,55,a))
    dxDrawText(jobInfo.desc,PX+12,PY+50,PX+PW-12,PY+100,dm,0.95,"default","left","top")

    dxDrawText("Bazowe wynagrodzenie: " .. formatMoney(jobInfo.basePay) .. " / misja",
        PX+12,PY+106,PX+PW-12,PY+126,tx,0.95,"default","left","top")
    dxDrawText("XP: +" .. jobInfo.xpPer .. " / misja",
        PX+12,PY+128,PX+PW-12,PY+148,dm,0.9,"default","left","top")
    dxDrawText("Poziom pracy: " .. myJobLvl,
        PX+12,PY+148,PX+PW-12,PY+168,dm,0.9,"default","left","top")

    dxDrawRectangle(PX+12,PY+170,PW-24,1,tocolor(40,45,55,a))

    if myJobId == jobInfo.id then
        -- Już pracuje
        dxDrawRectangle(PX+12,PY+180,PW-24,38,tocolor(200,60,60,150))
        dxDrawText("ZREZYGNUJ Z PRACY",PX+12,PY+180,PX+PW-12,PY+218,
            tocolor(255,255,255,a),1.1,"default-bold","center","center")
    else
        dxDrawRectangle(PX+12,PY+180,PW-24,38,ac)
        dxDrawText("ZATRUDNIJ SIĘ",PX+12,PY+180,PX+PW-12,PY+218,
            tocolor(255,255,255,a),1.1,"default-bold","center","center")
    end

    dxDrawRectangle(PX+12,PY+226,PW-24,30,tocolor(30,30,40,a))
    dxDrawText("ZAMKNIJ",PX+12,PY+226,PX+PW-12,PY+256,dm,1.0,"default","center","center")
end

addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 150 then return end

    if cx >= PX+PW-32 and cx <= PX+PW-8 and cy >= PY+10 and cy <= PY+36 then
        closeJobPanel() return
    end
    if cx >= PX+12 and cx <= PX+PW-12 and cy >= PY+180 and cy <= PY+218 then
        if myJobId == jobInfo.id then
            triggerServerEvent("rpJobs:quit", localPlayer)
        else
            triggerServerEvent("rpJobs:takeJob", localPlayer, jobInfo.id)
        end
        closeJobPanel()
    end
    if cx >= PX+12 and cx <= PX+PW-12 and cy >= PY+226 and cy <= PY+256 then
        closeJobPanel()
    end
end)

function closeJobPanel()
    panelOpen = false
    removeEventHandler("onClientRender", root, renderJobPanel)
    showCursor(false)
end

-- ============================================================
--  NOWA MISJA – marker celu
-- ============================================================
addEvent("rpJobs:newMission", true)
addEventHandler("rpJobs:newMission", root, function(data)
    missionData   = data
    missionActive = true

    if targetBlip then destroyElement(targetBlip) end
    targetBlip = createBlip(data.targetX, data.targetY, data.targetZ, 0, 2, 255,100,0,255)
    setBlipName(targetBlip, data.title)
    setBlipOrdering(targetBlip, 999)

    triggerEvent("rpNotif:local",localPlayer,"info", data.title, data.desc)
    setGpsDestination(data.targetX, data.targetY)
end)

addEvent("rpJobs:updateTarget", true)
addEventHandler("rpJobs:updateTarget", root, function(x, y, z, title)
    if targetBlip then destroyElement(targetBlip) end
    targetBlip = createBlip(x, y, z, 0, 2, 255,100,0,255)
    setBlipName(targetBlip, title or "Cel")
    setGpsDestination(x, y)
    triggerEvent("rpNotif:local",localPlayer,"info","Następny cel",title or "")
end)

addEvent("rpJobs:clearTarget", true)
addEventHandler("rpJobs:clearTarget", root, function()
    if targetBlip then destroyElement(targetBlip) targetBlip = nil end
    missionActive = false
    missionData   = nil
end)

-- ============================================================
--  STREFY CELU (wykrywa dotarcie klienta-side)
-- ============================================================
addEventHandler("onClientRender", root, function()
    if not missionActive or not missionData then return end
    local px, py, pz = getElementPosition(localPlayer)
    local d = dist3D(px,py,pz, missionData.targetX, missionData.targetY, missionData.targetZ)
    if d < 8 then
        triggerServerEvent("rpJobs:reachedTarget", localPlayer)
        missionActive = false
        missionData   = nil
        if targetBlip then destroyElement(targetBlip) targetBlip = nil end
    end
end)
