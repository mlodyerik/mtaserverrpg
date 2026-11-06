--[[
    rp_characters – Panel wyboru/tworzenia postaci (klient DX)
--]]

local W, H   = guiGetScreenSize()
local PW,PH  = 560, 440
local PX     = (W - PW)/2
local PY     = (H - PH)/2

local STATE       = "none"  -- none / select / create
local ALPHA       = 0
local ANIM        = false
local charList    = {}
local accountId   = nil
local selectedIdx = 1

-- Kreator postaci
local cName, cSkin, cSex
local skinList    = {}
local skinPage    = 1
local SKINS_PER_PAGE = 8

local edtName
local msgText  = ""
local msgColor = {220,60,60}

-- ============================================================
--  ZDARZENIE SERWERA
-- ============================================================
addEvent("rpChar:showSelect", true)
addEventHandler("rpChar:showSelect", root, function(list, acId)
    charList  = list or {}
    accountId = acId
    STATE     = "select"
    ALPHA     = 0
    ANIM      = true
    msgText   = ""
    addEventHandler("onClientRender", root, renderPanel)
    guiSetInputEnabled(false)
end)

-- ============================================================
--  RENDER
-- ============================================================
function renderPanel()
    if ANIM then
        ALPHA = math.min(255, ALPHA + 8)
        if ALPHA >= 255 then ANIM = false end
    end
    if STATE == "none" or ALPHA <= 0 then return end

    local a  = math.floor(ALPHA)
    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(30,144,255,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)

    dxDrawRectangle(PX,PY,PW,PH,bg)
    dxDrawRectangle(PX,PY,PW,4,ac)

    if STATE == "select" then
        dxDrawText("WYBIERZ POSTAĆ", PX,PY+14,PX+PW,PY+44,ac,1.5,"default-bold","center","top")
        dxDrawRectangle(PX+30,PY+48,PW-60,1,tocolor(40,45,55,a))

        -- Sloty postaci
        for i = 1, 3 do
            local slotX = PX + 30 + (i-1)*((PW-60)/3)
            local slotW = (PW-60)/3 - 10
            local slotY = PY + 60
            local slotH = 240

            local ch = charList[i]
            local isSel = (selectedIdx == i)
            local borderColor = isSel and ac or tocolor(40,45,55,a)

            dxDrawRectangle(slotX, slotY, slotW, slotH, tocolor(22,25,32,a))
            dxDrawRectangle(slotX, slotY, slotW, 2, borderColor)
            dxDrawRectangle(slotX, slotY+slotH-2, slotW, 2, borderColor)
            dxDrawRectangle(slotX, slotY, 2, slotH, borderColor)
            dxDrawRectangle(slotX+slotW-2, slotY, 2, slotH, borderColor)

            if ch then
                -- Miniatura skina (placeholder prostokąt)
                dxDrawRectangle(slotX+slotW/2-20, slotY+20, 40, 80, tocolor(30,40,55,a))
                dxDrawText(tostring(ch.skin_id or 0),
                    slotX,slotY+60,slotX+slotW,slotY+100,
                    dm,0.9,"default","center","top")
                dxDrawText(ch.name or "?",
                    slotX,slotY+110,slotX+slotW,slotY+130,
                    tx,1.0,"default-bold","center","top")
                dxDrawText("Poziom " .. (ch.level or 1),
                    slotX,slotY+130,slotX+slotW,slotY+150,
                    dm,0.9,"default","center","top")
                -- Przycisk Graj
                dxDrawRectangle(slotX+10,slotY+190,slotW-20,34,ac)
                dxDrawText("GRAJ", slotX+10,slotY+190,slotX+slotW-10,slotY+224,
                    tocolor(255,255,255,a),1.0,"default-bold","center","center")
                -- Przycisk Usuń
                dxDrawRectangle(slotX+10,slotY+228,slotW-20,24,tocolor(80,20,20,a))
                dxDrawText("USUŃ", slotX+10,slotY+228,slotX+slotW-10,slotY+252,
                    tocolor(220,60,60,a),0.85,"default","center","center")
            else
                dxDrawText("+\nNowa postać",
                    slotX,slotY+80,slotX+slotW,slotY+160,
                    dm,1.1,"default","center","top")
            end
        end

        if msgText ~= "" then
            dxDrawText(msgText, PX,PY+PH-36,PX+PW,PY+PH-16,
                tocolor(msgColor[1],msgColor[2],msgColor[3],a),0.95,"default","center","top")
        end

    elseif STATE == "create" then
        drawCreatePanel(a, ac, tx, dm)
    end
end

function drawCreatePanel(a, ac, tx, dm)
    dxDrawText("NOWA POSTAĆ", PX,PY+14,PX+PW,PY+44,ac,1.5,"default-bold","center","top")
    dxDrawRectangle(PX+30,PY+48,PW-60,1,tocolor(40,45,55,a))

    -- Nazwa
    dxDrawText("Imię i Nazwisko:", PX+40,PY+70,PX+220,PY+90,tx,1.0,"default","left","center")
    dxDrawRectangle(PX+220,PY+66,PW-260,28,tocolor(22,25,32,a))

    -- Płeć
    dxDrawText("Płeć:", PX+40,PY+110,PX+220,PY+130,tx,1.0,"default","left","center")
    local maleColor  = (cSex==0) and ac or tocolor(40,45,55,a)
    local femColor   = (cSex==1) and ac or tocolor(40,45,55,a)
    dxDrawRectangle(PX+220,PY+106,100,28,tocolor(22,25,32,a))
    dxDrawRectangle(PX+220,PY+106,2,28,maleColor)
    dxDrawText("Mężczyzna", PX+226,PY+106,PX+320,PY+134,maleColor,0.9,"default","left","center")
    dxDrawRectangle(PX+330,PY+106,100,28,tocolor(22,25,32,a))
    dxDrawRectangle(PX+330,PY+106,2,28,femColor)
    dxDrawText("Kobieta", PX+336,PY+106,PX+430,PY+134,femColor,0.9,"default","left","center")

    -- Wybór skina
    dxDrawText("Wygląd:", PX+40,PY+150,PX+220,PY+170,tx,1.0,"default","left","center")
    local list = (cSex==0) and CHAR_SKINS_MALE or CHAR_SKINS_FEMALE
    local startIdx = (skinPage-1)*SKINS_PER_PAGE + 1
    for i = 0, SKINS_PER_PAGE-1 do
        local idx = startIdx + i
        local sk  = list[idx]
        if not sk then break end
        local sx = PX + 40 + i*58
        local sy = PY + 175
        local isSel = (sk == cSkin)
        dxDrawRectangle(sx, sy, 52, 80, isSel and tocolor(20,60,100,a) or tocolor(22,25,32,a))
        dxDrawRectangle(sx, sy, 52, 2, isSel and ac or tocolor(40,45,55,a))
        dxDrawText("ID:" .. sk, sx, sy+60, sx+52, sy+80, dm, 0.7,"default","center","top")
    end
    -- Strzałki stron
    dxDrawText("◄", PX+30,PY+195,PX+50,PY+235,tx,1.2,"default","center","center")
    dxDrawText("►", PX+PW-50,PY+195,PX+PW-30,PY+235,tx,1.2,"default","center","center")

    -- Przycisk Utwórz
    dxDrawRectangle(PX+40,PY+280,PW-80,38,ac)
    dxDrawText("UTWÓRZ POSTAĆ", PX+40,PY+280,PX+PW-40,PY+318,
        tocolor(255,255,255,a),1.1,"default-bold","center","center")

    -- Przycisk Wróć
    dxDrawRectangle(PX+40,PY+326,PW-80,28,tocolor(40,45,55,a))
    dxDrawText("◄ Wróć", PX+40,PY+326,PX+PW-40,PY+354,dm,0.95,"default","center","center")

    if msgText ~= "" then
        dxDrawText(msgText, PX,PY+PH-30,PX+PW,PY+PH-10,
            tocolor(msgColor[1],msgColor[2],msgColor[3],a),0.95,"default","center","top")
    end
end

-- ============================================================
--  KLIKNIĘCIA
-- ============================================================
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if STATE == "none" or ALPHA < 200 then return end

    if STATE == "select" then
        handleSelectClick(cx, cy)
    elseif STATE == "create" then
        handleCreateClick(cx, cy)
    end
end)

function handleSelectClick(cx, cy)
    for i = 1, 3 do
        local slotX = PX + 30 + (i-1)*((PW-60)/3)
        local slotW = (PW-60)/3 - 10
        local slotY = PY + 60

        -- Kliknięcie w slot
        if cx >= slotX and cx <= slotX+slotW and cy >= slotY and cy <= slotY+300 then
            selectedIdx = i
            local ch = charList[i]
            if ch then
                -- Przycisk GRAJ
                if cy >= slotY+190 and cy <= slotY+224 then
                    triggerServerEvent("rpChar:select", localPlayer, ch.id)
                    hidePanel()
                end
            else
                -- Nowa postać
                openCreate()
            end
        end
    end
end

function handleCreateClick(cx, cy)
    local list = (cSex==0) and CHAR_SKINS_MALE or CHAR_SKINS_FEMALE
    local startIdx = (skinPage-1)*SKINS_PER_PAGE + 1

    -- Skiny
    for i = 0, SKINS_PER_PAGE-1 do
        local sk = list[startIdx + i]
        if sk then
            local sx = PX + 40 + i*58
            local sy = PY + 175
            if cx >= sx and cx <= sx+52 and cy >= sy and cy <= sy+80 then
                cSkin = sk
            end
        end
    end

    -- Płeć
    if cx >= PX+220 and cx <= PX+320 and cy >= PY+106 and cy <= PY+134 then
        cSex = 0; cSkin = CHAR_SKINS_MALE[1]; skinPage = 1
    end
    if cx >= PX+330 and cx <= PX+430 and cy >= PY+106 and cy <= PY+134 then
        cSex = 1; cSkin = CHAR_SKINS_FEMALE[1]; skinPage = 1
    end

    -- Strzałki
    if cx >= PX+30 and cx <= PX+50 and cy >= PY+195 and cy <= PY+235 then
        if skinPage > 1 then skinPage = skinPage - 1 end
    end
    if cx >= PX+PW-50 and cx <= PX+PW-30 and cy >= PY+195 and cy <= PY+235 then
        local maxPages = math.ceil(#list / SKINS_PER_PAGE)
        if skinPage < maxPages then skinPage = skinPage + 1 end
    end

    -- Utwórz
    if cx >= PX+40 and cx <= PX+PW-40 and cy >= PY+280 and cy <= PY+318 then
        submitCreate()
    end

    -- Wróć
    if cx >= PX+40 and cx <= PX+PW-40 and cy >= PY+326 and cy <= PY+354 then
        STATE   = "select"
        msgText = ""
        guiSetInputEnabled(false)
        if edtName then destroyElement(edtName) edtName = nil end
    end
end

function openCreate()
    STATE   = "create"
    msgText = ""
    cSex    = 0
    cSkin   = CHAR_SKINS_MALE[1]
    skinPage= 1

    if edtName then destroyElement(edtName) end
    edtName = guiCreateEdit("", PX+222, PY+67, PW-262, 26, false)
    guiSetInputEnabled(true)
    guiFocus(edtName)
end

function submitCreate()
    local name = edtName and guiGetText(edtName) or ""
    name = name:match("^%s*(.-)%s*$")  -- trim
    triggerServerEvent("rpChar:create", localPlayer, accountId, name, cSkin, cSex)
end

-- ============================================================
--  ODPOWIEDŹ SERWERA
-- ============================================================
addEvent("rpChar:createResult", true)
addEventHandler("rpChar:createResult", root, function(ok, msg)
    msgText  = msg or ""
    msgColor = ok and {60,200,100} or {220,60,60}
end)

addEvent("rpChar:onSpawn", true)
addEventHandler("rpChar:onSpawn", root, function(charData)
    hidePanel()
    -- Zapisz lokalne dane postaci
    localCharData = charData
    triggerEvent("onLocalCharSpawn", localPlayer, charData)
end)

-- ============================================================
--  POMOCNICZE
-- ============================================================
function hidePanel()
    STATE   = "none"
    ALPHA   = 0
    msgText = ""
    removeEventHandler("onClientRender", root, renderPanel)
    guiSetInputEnabled(false)
    if edtName then destroyElement(edtName) edtName = nil end
end
