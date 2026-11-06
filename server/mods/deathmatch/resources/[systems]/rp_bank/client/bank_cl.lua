--[[
    rp_bank – Panel bankomatu DX
    Zakładki: Konto | Wpłata | Wypłata | Przelew | Historia
--]]

local W, H   = guiGetScreenSize()
local PW,PH  = 480, 400
local PX = (W-PW)/2
local PY = (H-PH)/2

local panelOpen  = false
local panelAlpha = 0
local tab        = "account"
local cash2, bank2 = 0, 0
local history    = {}
local atmName    = "Bankomat"

local edtAmount, edtTarget
local msgText, msgColor = "", {60,200,100}

addEvent("rpBank:openATM", true)
addEventHandler("rpBank:openATM", root, function(cash, bank, hist, name)
    cash2    = cash  or 0
    bank2    = bank  or 0
    history  = hist  or {}
    atmName  = name  or "Bankomat"
    tab      = "account"
    msgText  = ""
    panelOpen = true
    panelAlpha = 0
    showCursor(true)

    if edtAmount then destroyElement(edtAmount) end
    if edtTarget then destroyElement(edtTarget) end
    edtAmount = guiCreateEdit("", PX+120, PY+160, 240, 28, false)
    edtTarget = guiCreateEdit("", PX+120, PY+200, 240, 28, false)
    guiSetVisible(edtAmount, false)
    guiSetVisible(edtTarget, false)
    guiSetInputEnabled(true)

    addEventHandler("onClientRender", root, renderATM)
end)

addEvent("rpBank:updatePanel", true)
addEventHandler("rpBank:updatePanel", root, function(cash, bank)
    cash2 = cash or cash2
    bank2 = bank or bank2
end)

function renderATM()
    panelAlpha = math.min(255, panelAlpha+10)
    if not panelOpen then return end
    local a  = math.floor(panelAlpha)
    local bg = tocolor(15,15,20,math.min(a,220))
    local ac = tocolor(0,180,255,a)
    local tx = tocolor(220,225,235,a)
    local dm = tocolor(140,148,160,a)
    local gr = tocolor(60,200,100,a)

    dxDrawRectangle(PX,PY,PW,PH,bg)
    dxDrawRectangle(PX,PY,PW,3,ac)
    dxDrawText(atmName,PX,PY+10,PX+PW-40,PY+36,ac,1.2,"default-bold","center","top")
    dxDrawText("✕",PX+PW-34,PY+8,PX+PW-8,PY+34,tocolor(220,60,60,a),1.2,"default-bold","center","center")

    -- Zakładki
    local tabs = {{"account","KONTO"},{"deposit","WPŁATA"},{"withdraw","WYPŁATA"},{"transfer","PRZELEW"},{"history","HISTORIA"}}
    for i, t in ipairs(tabs) do
        local tx2 = PX + (i-1)*(PW/5)
        local isA = tab == t[1]
        dxDrawRectangle(tx2,PY+40,(PW/5),24,tocolor(22,25,32,a))
        dxDrawRectangle(tx2,PY+62,(PW/5),2, isA and ac or tocolor(40,45,55,a))
        dxDrawText(t[2],tx2,PY+40,tx2+PW/5,PY+64,
            isA and tx or dm, 0.75, isA and "default-bold" or "default","center","center")
    end
    dxDrawRectangle(PX,PY+66,PW,1,tocolor(40,45,55,a))

    -- Aktualne środki (zawsze widoczne)
    dxDrawText("Gotówka: " .. formatMoney(cash2), PX+16,PY+72,PX+PW-16,PY+92,gr,0.95,"default-bold","left","top")
    dxDrawText("Konto: " .. formatMoney(bank2), PX+16,PY+92,PX+PW-16,PY+112,ac,0.95,"default-bold","left","top")
    dxDrawRectangle(PX+12,PY+114,PW-24,1,tocolor(40,45,55,a))

    if tab == "account" then
        drawAccount(a,ac,tx,dm,gr)
    elseif tab == "deposit" then
        drawDepositWithdraw(a,ac,tx,dm,gr,"deposit")
    elseif tab == "withdraw" then
        drawDepositWithdraw(a,ac,tx,dm,gr,"withdraw")
    elseif tab == "transfer" then
        drawTransfer(a,ac,tx,dm,gr)
    elseif tab == "history" then
        drawHistory(a,ac,tx,dm,gr)
    end

    if msgText ~= "" then
        dxDrawText(msgText,PX,PY+PH-24,PX+PW,PY+PH-6,
            tocolor(msgColor[1],msgColor[2],msgColor[3],a),0.9,"default","center","top")
    end
end

function drawAccount(a,ac,tx,dm,gr)
    dxDrawText("Łączne środki: " .. formatMoney(cash2+bank2),
        PX+16,PY+124,PX+PW-16,PY+144,tx,1.1,"default-bold","left","top")
end

function drawDepositWithdraw(a,ac,tx,dm,gr,mode)
    local label = mode=="deposit" and "Kwota wpłaty:" or "Kwota wypłaty:"
    dxDrawText(label,PX+16,PY+130,PX+120,PY+158,dm,0.95,"default","left","center")
    -- edtAmount jest guiEdit, transparentny (użytkownik widzi ramkę DX)
    dxDrawRectangle(PX+118,PY+156,244,32,tocolor(22,25,32,a))
    dxDrawRectangle(PX+118,PY+186,244,2,ac)
    guiSetVisible(edtAmount, true)
    guiSetPosition(edtAmount, PX+120, PY+158)

    dxDrawRectangle(PX+12,PY+198,PW-24,38,ac)
    dxDrawText(mode=="deposit" and "WPŁAĆ" or "WYPŁAĆ",
        PX+12,PY+198,PX+PW-12,PY+236,tocolor(255,255,255,a),1.1,"default-bold","center","center")
end

function drawTransfer(a,ac,tx,dm,gr)
    dxDrawText("Kwota:",PX+16,PY+130,PX+120,PY+158,dm,0.95,"default","left","center")
    dxDrawRectangle(PX+118,PY+126,244,32,tocolor(22,25,32,a))
    guiSetVisible(edtAmount, true)
    guiSetPosition(edtAmount, PX+120, PY+128)

    dxDrawText("Odbiorca (nazwa postaci):",PX+16,PY+168,PX+PW-12,PY+186,dm,0.9,"default","left","top")
    dxDrawRectangle(PX+118,PY+186,244,32,tocolor(22,25,32,a))
    guiSetVisible(edtTarget, true)
    guiSetPosition(edtTarget, PX+120, PY+188)

    dxDrawRectangle(PX+12,PY+228,PW-24,36,ac)
    dxDrawText("PRZELEJ",PX+12,PY+228,PX+PW-12,PY+264,tocolor(255,255,255,a),1.1,"default-bold","center","center")
end

function drawHistory(a,ac,tx,dm,gr)
    if #history == 0 then
        dxDrawText("Brak transakcji.",PX,PY+140,PX+PW,PY+170,dm,1.0,"default","center","top")
        return
    end
    for i = 1, math.min(10, #history) do
        local entry = history[i]
        local ry = PY + 124 + (i-1)*26
        local amtColor = entry.amount >= 0 and gr or tocolor(220,60,60,a)
        dxDrawText(entry.type:sub(1,20), PX+12,ry,PX+200,ry+24,dm,0.8,"default","left","top")
        dxDrawText((entry.amount>=0 and "+" or "")..formatMoney(entry.amount),
            PX+200,ry,PX+340,ry+24,amtColor,0.85,"default-bold","right","top")
        dxDrawText(tostring(entry.created_at):sub(1,16),PX+340,ry,PX+PW-12,ry+24,dm,0.75,"default","right","top")
    end
end

-- ============================================================
--  KLIKNIĘCIA
-- ============================================================
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
    if btn ~= "left" or state ~= "down" then return end
    if not panelOpen or panelAlpha < 150 then return end

    -- Zamknij
    if cx>=PX+PW-34 and cx<=PX+PW-8 and cy>=PY+8 and cy<=PY+34 then closeATM() return end

    -- Zakładki
    local tabs = {"account","deposit","withdraw","transfer","history"}
    for i, t in ipairs(tabs) do
        local tx2 = PX+(i-1)*(PW/5)
        if cx>=tx2 and cx<=tx2+PW/5 and cy>=PY+40 and cy<=PY+64 then
            tab = t
            guiSetVisible(edtAmount, false)
            guiSetVisible(edtTarget, false)
            return
        end
    end

    -- Akcje
    if tab == "deposit" then
        if cx>=PX+12 and cx<=PX+PW-12 and cy>=PY+198 and cy<=PY+236 then
            local amt = tonumber(guiGetText(edtAmount)) or 0
            triggerServerEvent("rpEconomy:atmDeposit", localPlayer, amt)
        end
    elseif tab == "withdraw" then
        if cx>=PX+12 and cx<=PX+PW-12 and cy>=PY+198 and cy<=PY+236 then
            local amt = tonumber(guiGetText(edtAmount)) or 0
            triggerServerEvent("rpEconomy:atmWithdraw", localPlayer, amt)
        end
    elseif tab == "transfer" then
        if cx>=PX+12 and cx<=PX+PW-12 and cy>=PY+228 and cy<=PY+264 then
            local amt  = tonumber(guiGetText(edtAmount)) or 0
            local targ = guiGetText(edtTarget) or ""
            triggerServerEvent("rpEconomy:transfer", localPlayer, targ, amt)
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not panelOpen or not press then return end
    if key == "escape" then closeATM() end
end)

function closeATM()
    panelOpen = false
    panelAlpha = 0
    removeEventHandler("onClientRender", root, renderATM)
    guiSetInputEnabled(false)
    showCursor(false)
    if edtAmount then destroyElement(edtAmount) edtAmount = nil end
    if edtTarget then destroyElement(edtTarget) edtTarget = nil end
end
