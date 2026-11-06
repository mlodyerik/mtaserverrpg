--[[
    rp_characters – definicje i stałe postaci
--]]

-- Dostępne skórki do tworzenia postaci (nie frakcyjne)
CHAR_SKINS_MALE = {
    0,1,2,7,14,15,16,17,21,23,24,25,26,27,28,29,
    30,31,32,33,34,35,36,43,44,45,46,47,48,49,50,
    57,58,59,60,61,62,66,67,68,69,70,72,73,78,
    80,81,82,83,84,85,86,87,88,89,90,91,92,93,
    94,95,96,97,98,99,100,101,102,103,104,105,
    106,107,108,109,110,111,112,113,114,115
}
CHAR_SKINS_FEMALE = {
    9,10,11,12,13,18,19,20,22,40,41,42,51,52,53,
    54,55,56,63,64,65,71,74,75,76,77,
    116,117,118,119,120,121,122,123,124,125,126,
    127,128,129,130,131,132,133,134,135
}

-- XP potrzebne do następnego poziomu
function getXPForLevel(level)
    -- Wzrost: 100, 200, 300... (level * 100)
    return level * 100
end

-- Łączne XP od poziomu 1 do lvl
function getTotalXPForLevel(lvl)
    local total = 0
    for i = 1, lvl-1 do total = total + getXPForLevel(i) end
    return total
end
