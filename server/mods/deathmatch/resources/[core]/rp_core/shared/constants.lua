--[[
    rp_core – Stałe globalne projektu
--]]

-- Spawny miast
SPAWN_SF = { x = 2171.3,  y = 933.0,   z = 11.1,  rot = 90.0 }
SPAWN_LS = { x = 1248.87, y = -785.01, z = 11.09, rot = 180.0}
SPAWN_LV = { x = 2237.73, y = 2474.72, z = 10.82, rot = 270.0}

-- Kolory UI (grafit + niebieski akcent)
UI_COLOR_BG         = { 15,  15,  20,  220 }  -- główne tło
UI_COLOR_BG2        = { 22,  25,  32,  220 }  -- drugorzędne tło
UI_COLOR_ACCENT     = { 30, 144, 255, 255 }   -- niebieski akcent
UI_COLOR_ACCENT2    = { 0,  100, 200, 255 }   -- ciemniejszy akcent
UI_COLOR_TEXT       = { 220, 225, 235, 255 }  -- tekst główny
UI_COLOR_TEXT_DIM   = { 140, 148, 160, 255 }  -- tekst drugorzędny
UI_COLOR_SUCCESS    = { 60,  200, 100, 255 }  -- zielony
UI_COLOR_WARNING    = { 255, 180,  40, 255 }  -- żółty
UI_COLOR_ERROR      = { 220,  60,  60, 255 }  -- czerwony
UI_COLOR_SEPARATOR  = { 40,   45,  55, 200 }  -- linia podziału

-- Limity
MAX_CASH        = 9999999   -- max gotówka
MAX_BANK        = 99999999  -- max bank
MAX_LEVEL       = 100
STARTING_CASH   = 1500
STARTING_BANK   = 0

-- Pojazdy – paliwo
FUEL_MAX        = 100.0
FUEL_RATE       = 0.008  -- jednostki paliwa na metr

-- Praca
JOB_NONE        = 0
JOB_COURIER     = 1
JOB_TAXI        = 2
JOB_BUS         = 3
JOB_TRUCK       = 4
JOB_MOWER       = 5
JOB_DIVER       = 6
JOB_GARBAGE     = 7
JOB_WAREHOUSE   = 8
JOB_FISHERMAN   = 9
JOB_PILOT       = 10

-- XP do kolejnego poziomu (wzorzec: level^2 * 100)
function getLevelXP(level)
    return level * level * 100
end

-- Identyfikatory eventów (zapobiegają literówkom)
EV_CHAR_LOADED    = "onCharacterLoaded"
EV_CHAR_SAVED     = "onCharacterSaved"
EV_MONEY_CHANGE   = "onMoneyChange"
EV_VEH_LOADED     = "onVehicleLoaded"
