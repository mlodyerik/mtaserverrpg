--[[
    rp_vehicles – klient
    - Pas bezpieczeństwa (F + informacja)
    - Hamulec ręczny (Space override)
    - Blokada silnika przy wejściu
    - Skróty klawiszowe
--]]

local inVehicle    = false
local seatbelt     = false
local engineOn     = false
local handbrakeOn  = false

-- ============================================================
--  WEJŚCIE / WYJŚCIE Z POJAZDU
-- ============================================================
addEventHandler("onClientVehicleEnter", root, function(veh, seat)
    if source ~= localPlayer then return end
    inVehicle = true
    seatbelt  = false
    -- Silnik wyłączony przy wejściu (gracz musi go uruchomić)
    triggerEvent("rpNotif:local", localPlayer, "info","Pojazd","[F] Silnik   [H] Zamek   [Y] Pas   [L] Światła")
end)

addEventHandler("onClientVehicleExit", root, function()
    if source ~= localPlayer then return end
    inVehicle    = false
    engineOn     = false
    handbrakeOn  = false
end)

-- ============================================================
--  SKRÓTY KLAWISZOWE
-- ============================================================
bindKey("f", "down", function()
    if not inVehicle then return end
    triggerServerEvent("rpVeh:toggleEngine", localPlayer)
end)

bindKey("h", "down", function()
    if not inVehicle then return end
    triggerServerEvent("rpVeh:toggleLock", localPlayer)
end)

bindKey("y", "down", function()
    if not inVehicle then return end
    seatbelt = not seatbelt
    local msg = seatbelt and "Pas bezpieczeństwa zapięty 🔐" or "Pas bezpieczeństwa odpięty"
    triggerEvent("rpNotif:local", localPlayer, seatbelt and "success" or "warning","Pojazd", msg)
end)

bindKey("l", "down", function()
    if not inVehicle then return end
    triggerServerEvent("rpVeh:toggleLights", localPlayer)
end)

-- ============================================================
--  SYGNAŁ KLAKSONU (CTRL+H)
-- ============================================================
bindKey("horn", "down", function()
    -- naturalnie obsłużone przez MTA
end)

-- ============================================================
--  AKTUALIZACJA STANU SILNIKA (z serwera)
-- ============================================================
addEvent("rpVeh:engineState", true)
addEventHandler("rpVeh:engineState", root, function(state)
    engineOn = state
    local msg = state and "Silnik uruchomiony 🔑" or "Silnik wyłączony"
    triggerEvent("rpNotif:local", localPlayer, state and "success" or "info","Pojazd", msg)
end)

-- ============================================================
--  PAS – OCHRONA PRZED WYPADNIĘCIEM (symulacja)
-- ============================================================
addEventHandler("onClientRender", root, function()
    if not inVehicle then return end
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end

    -- Jeśli pojazd ma wypadek (health < 300) i brak pasa → dodaj obrażenia
    local hp = getElementHealth(veh)
    if hp < 300 and not seatbelt then
        -- Symulacja obrażeń bez pasa (raz na 500ms)
        -- Obsługa przez serwer jest bardziej bezpieczna, to tylko klient-side efekt
    end
end)
