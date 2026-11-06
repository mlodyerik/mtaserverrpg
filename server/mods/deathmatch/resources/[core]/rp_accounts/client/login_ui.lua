--[[
    rp_accounts – Panel logowania / rejestracji (DX UI)
    Styl: ciemny grafit, niebieski akcent, animacja fade-in
--]]

local W, H    = guiGetScreenSize()
local PW, PH  = 460, 340
local PX      = (W - PW) / 2
local PY      = (H - PH) / 2

local STATE   = "none"  -- none / login / register
local ALPHA   = 0       -- animacja wejścia (0→255)
local ANIM    = false

-- pola tekstowe (guiEdit, ukryte)
local edtUser, edtPass, edtPass2
local msgText  = ""
local msgColor = {220,60,60}

-- ============================================================
--  RYSOWANIE
-- ============================================================
local function drawPanel()
    local a = math.floor(ALPHA)
    if a <= 0 then return end

    local bgA   = math.min(a, 220)
    local txtA  = a

    -- Tło
    dxDrawRectangle(PX,          PY,          PW,  PH,  tocolor(15,15,20,bgA))
    dxDrawRectangle(PX,          PY,          PW,  4,   tocolor(30,144,255,txtA))
    dxDrawRectangle(PX,          PY+PH-4,     PW,  4,   tocolor(30,144,255,math.floor(txtA*0.4)))

    -- Tytuł
    dxDrawText("SAN ANDREAS RPG",
        PX, PY+18, PX+PW, PY+50,
        tocolor(30,144,255,txtA), 1.6, "default-bold", "center","top")
    dxDrawText(STATE == "login" and "LOGOWANIE" or "REJESTRACJA",
        PX, PY+50, PX+PW, PY+80,
        tocolor(140,148,160,txtA), 1.0, "default", "center","top")

    -- Separator
    dxDrawRectangle(PX+30, PY+82, PW-60, 1, tocolor(40,45,55,bgA))

    -- Labels
    dxDrawText("Login:", PX+40, PY+100, PX+140, PY+120, tocolor(220,225,235,txtA), 1.0,"default","left","center")
    dxDrawText("Hasło:", PX+40, PY+140, PX+140, PY+160, tocolor(220,225,235,txtA), 1.0,"default","left","center")
    if STATE == "register" then
        dxDrawText("Powtórz:", PX+40, PY+180, PX+140, PY+200, tocolor(220,225,235,txtA), 1.0,"default","left","center")
    end

    -- Ramki pól
    dxDrawRectangle(PX+140, PY+96, 270, 30, tocolor(22,25,32,bgA))
    dxDrawRectangle(PX+140, PY+96, 270, 30, tocolor(40,45,55,bgA))
    dxDrawRectangle(PX+140, PY+136, 270, 30, tocolor(22,25,32,bgA))
    dxDrawRectangle(PX+140, PY+136, 270, 30, tocolor(40,45,55,bgA))
    if STATE == "register" then
        dxDrawRectangle(PX+140, PY+176, 270, 30, tocolor(22,25,32,bgA))
        dxDrawRectangle(PX+140, PY+176, 270, 30, tocolor(40,45,55,bgA))
    end

    -- Przycisk główny
    local btnY = STATE == "register" and PY+228 or PY+190
    dxDrawRectangle(PX+40, btnY, PW-80, 36, tocolor(30,144,255,txtA))
    dxDrawText(STATE == "login" and "ZALOGUJ SIĘ" or "ZAREJESTRUJ SIĘ",
        PX+40, btnY, PX+PW-40, btnY+36,
        tocolor(255,255,255,txtA), 1.1,"default-bold","center","center")

    -- Przełącznik
    local switchY = btnY + 46
    local switchTxt = STATE == "login" and "Nie masz konta? Zarejestruj się" or "Masz już konto? Zaloguj się"
    dxDrawText(switchTxt, PX, switchY, PX+PW, switchY+20,
        tocolor(100,160,255,txtA), 0.95,"default","center","top")

    -- Komunikat błędu/sukcesu
    if msgText ~= "" then
        dxDrawText(msgText, PX, switchY+24, PX+PW, switchY+44,
            tocolor(msgColor[1],msgColor[2],msgColor[3],txtA), 0.95,"default","center","top")
    end
end

-- ============================================================
--  EVENTY SERWERA
-- ============================================================
addEvent("rpAccount:showLogin", true)
addEventHandler("rpAccount:showLogin", root, function()
    STATE = "login"
    ALPHA = 0
    ANIM  = true
    msgText = ""
    showChat(false)
    addEventHandler("onClientRender", root, onRender)
    -- Pokaż pola GUI
    if edtUser then destroyElement(edtUser) end
    if edtPass then destroyElement(edtPass) end
    if edtPass2 then destroyElement(edtPass2) end

    edtUser = guiCreateEdit("", PX+142, PY+97, 266, 28, false)
    edtPass = guiCreateEdit("", PX+142, PY+137, 266, 28, false)
    guiEditSetMasked(edtPass, true)
    edtPass2 = guiCreateEdit("", PX+142, PY+177, 266, 28, false)
    guiEditSetMasked(edtPass2, true)
    guiSetVisible(edtPass2, false)
    guiSetAlpha(edtUser, 0.01)
    guiSetAlpha(edtPass, 0.01)
    guiSetAlpha(edtPass2, 0.01)
    guiSetInputEnabled(true)
    guiFocus(edtUser)
end)

-- ============================================================
--  ANIMACJA
-- ============================================================
function onRender()
    if ANIM then
        ALPHA = ALPHA + 8
        if ALPHA >= 255 then
            ALPHA = 255
            ANIM  = false
            -- Teraz pokaż pola GUI (transparentne wcześniej)
            guiSetAlpha(edtUser, 1)
            guiSetAlpha(edtPass, 1)
            if STATE == "register" then guiSetAlpha(edtPass2, 1) end
        end
    end
    if STATE ~= "none" then
        drawPanel()
    end
end

-- ============================================================
--  KLIKNIĘCIA MYSZY
-- ============================================================
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if STATE == "none" or ALPHA < 200 then return end

    local btnY = STATE == "register" and PY+228 or PY+190

    -- Przycisk główny
    if cx >= PX+40 and cx <= PX+PW-40 and cy >= btnY and cy <= btnY+36 then
        onSubmit()
        return
    end

    -- Przełącznik login/rejestracja
    local switchY = btnY + 46
    if cx >= PX and cx <= PX+PW and cy >= switchY and cy <= switchY+20 then
        toggleMode()
        return
    end
end)

-- ============================================================
--  ENTER
-- ============================================================
addEventHandler("onClientKey", root, function(key, press)
    if key == "return" and press and STATE ~= "none" then
        onSubmit()
    end
end)

-- ============================================================
--  PRZEŁĄCZ TRYB
-- ============================================================
function toggleMode()
    if STATE == "login" then
        STATE = "register"
        guiSetVisible(edtPass2, true)
        guiSetAlpha(edtPass2, 1)
    else
        STATE = "login"
        guiSetVisible(edtPass2, false)
    end
    msgText = ""
    if edtUser then guiSetText(edtUser, "") end
    if edtPass then guiSetText(edtPass, "") end
    if edtPass2 then guiSetText(edtPass2, "") end
    if edtUser then guiFocus(edtUser) end
end

-- ============================================================
--  SUBMIT
-- ============================================================
function onSubmit()
    local user = guiGetText(edtUser) or ""
    local pass = guiGetText(edtPass) or ""

    if STATE == "login" then
        triggerServerEvent("rpAccount:login", localPlayer, user, pass)
    else
        local pass2 = guiGetText(edtPass2) or ""
        if pass ~= pass2 then
            msgText  = "Hasła nie są identyczne!"
            msgColor = {220,60,60}
            return
        end
        triggerServerEvent("rpAccount:register", localPlayer, user, pass)
    end
end

-- ============================================================
--  ODPOWIEDŹ SERWERA – REJESTRACJA
-- ============================================================
addEvent("rpAccount:registerResult", true)
addEventHandler("rpAccount:registerResult", root, function(ok, msg)
    msgText  = msg or ""
    msgColor = ok and {60,200,100} or {220,60,60}
    if ok then
        STATE = "login"
        guiSetVisible(edtPass2, false)
        if edtUser then guiSetText(edtUser, "") end
        if edtPass then guiSetText(edtPass, "") end
        if edtPass2 then guiSetText(edtPass2, "") end
    end
end)

-- ============================================================
--  ODPOWIEDŹ SERWERA – LOGOWANIE
-- ============================================================
addEvent("rpAccount:loginResult", true)
addEventHandler("rpAccount:loginResult", root, function(ok, msg)
    if ok then
        -- Zamknij panel logowania
        STATE   = "none"
        ALPHA   = 0
        msgText = ""
        showChat(true)
        guiSetInputEnabled(false)
        removeEventHandler("onClientRender", root, onRender)
        if edtUser then destroyElement(edtUser) edtUser = nil end
        if edtPass then destroyElement(edtPass) edtPass = nil end
        if edtPass2 then destroyElement(edtPass2) edtPass2 = nil end
        -- rp_characters pokaze panel wyboru postaci
    else
        msgText  = msg or "Błąd logowania."
        msgColor = {220,60,60}
    end
end)

-- ============================================================
--  CZYSZCZENIE
-- ============================================================
addEventHandler("onClientResourceStop", resourceRoot, function()
    removeEventHandler("onClientRender", root, onRender)
    guiSetInputEnabled(false)
end)
