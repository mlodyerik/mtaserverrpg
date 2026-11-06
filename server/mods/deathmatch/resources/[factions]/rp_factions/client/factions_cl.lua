--[[
    rp_factions – Klient frakcji
    - Wskaźnik duty na HUD
    - Chat frakcyjny
--]]

local fractionName = ""
local rankName     = ""
local onDuty       = false

addEvent("rpFrac:setData", true)
addEventHandler("rpFrac:setData", root, function(fname, rname, duty)
    fractionName = fname or ""
    rankName     = rname or ""
    onDuty       = duty  or false
end)

-- Duty badge na HUD
addEventHandler("onClientRender", root, function()
    if fractionName == "" then return end
    local W,H = guiGetScreenSize()
    local col = onDuty and tocolor(60,200,100,220) or tocolor(140,148,160,180)
    dxDrawText((onDuty and "● " or "○ ")..fractionName.." | "..rankName,
        10, 10, 400, 30, col, 0.9,"default-bold","left","top")
end)

-- Chat frakcyjny
addEvent("rpFrac:receiveChat", true)
addEventHandler("rpFrac:receiveChat", root, function(msg, fracId)
    outputChatBox(msg, 80, 200, 120, false)
end)

-- Komendy klientów
addCommandHandler("duty", function()
    triggerServerEvent("rpFrac:toggleDuty", localPlayer)
end)
