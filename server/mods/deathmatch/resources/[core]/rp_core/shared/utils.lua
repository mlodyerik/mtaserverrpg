--[[
    rp_core – Narzędzia pomocnicze (shared: serwer + klient)
--]]

-- Formatowanie pieniędzy: 1234567 → "1 234 567 $"
function formatMoney(amount)
    if type(amount) ~= "number" then return "0 $" end
    local s = tostring(math.floor(math.abs(amount)))
    local result = ""
    local mod = #s % 3
    for i = 1, #s do
        if i > 1 and (i - 1 - mod) % 3 == 0 then
            result = result .. " "
        end
        result = result .. s:sub(i, i)
    end
    return (amount < 0 and "-" or "") .. result .. " $"
end

-- Ograniczenie wartości do zakresu
function clamp(val, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, val))
end

-- Sprawdź, czy tabela zawiera wartość
function tableContains(t, val)
    for _, v in ipairs(t) do
        if v == val then return true end
    end
    return false
end

-- Interpolacja liniowa
function lerp(a, b, t)
    return a + (b - a) * clamp(t, 0, 1)
end

-- Odległość 2D
function dist2D(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- Odległość 3D
function dist3D(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

-- Konwersja {r,g,b,a} → tocolor
function colorToHex(t)
    return tocolor(t[1], t[2], t[3], t[4] or 255)
end

-- Zapis tabeli z kluczami i wartościami do stringa (debug)
function tableToString(t, indent)
    indent = indent or 0
    local s = "{\n"
    for k, v in pairs(t) do
        s = s .. string.rep("  ", indent+1)
        s = s .. tostring(k) .. " = "
        if type(v) == "table" then
            s = s .. tableToString(v, indent+1)
        else
            s = s .. tostring(v)
        end
        s = s .. ",\n"
    end
    return s .. string.rep("  ", indent) .. "}"
end

-- Skrócenie stringa do max długości
function truncate(str, maxLen)
    if #str > maxLen then
        return str:sub(1, maxLen-3) .. "..."
    end
    return str
end

-- Bezpieczna konwersja na liczbę
function toSafeNumber(val, default)
    local n = tonumber(val)
    return n or (default or 0)
end

-- Sprawdź, czy string jest liczbą całkowitą
function isInteger(str)
    return tostring(str):match("^-?%d+$") ~= nil
end

-- Czas w formacie gg:mm:ss
function secondsToTime(secs)
    secs = math.floor(secs)
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end
