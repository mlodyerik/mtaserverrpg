--[[
    rp_core – Walidacja danych (serwer)
--]]

-- Dozwolone znaki w nazwie gracza/postaci: litery, cyfry, spacja, myślnik, podkreślnik
local NAME_PATTERN = "^[%a%d %-%_]+$"

function isValidName(name, minLen, maxLen)
    minLen = minLen or 3
    maxLen = maxLen or 50
    if type(name) ~= "string" then return false end
    if #name < minLen or #name > maxLen then return false end
    if not name:match(NAME_PATTERN) then return false end
    return true
end

function isValidAmount(amount, minVal, maxVal)
    minVal = minVal or 1
    maxVal = maxVal or MAX_CASH
    local n = tonumber(amount)
    if not n then return false end
    if n ~= math.floor(n) then return false end  -- tylko całkowite
    return n >= minVal and n <= maxVal
end

-- Logowanie startu core
addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    outputServerLog("[rp_core] Załadowany. Wersja 1.0.0")
end)
