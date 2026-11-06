--[[
    rp_bank – Bankomaty w całym San Andreas
    Funkcje: wpłata, wypłata, przelew, historia
--]]

local ATM_LOCATIONS = {
    -- San Fierro
    {x=-2066.0,y=227.0,z=35.2,  name="ATM – Centrum SF"},
    {x=-2180.0,y=950.0,z=35.3,  name="ATM – Targ SF"},
    {x=-1950.0,y=460.0,z=35.2,  name="ATM – Dzielnica SF"},
    {x=-2370.0,y=600.0,z=35.2,  name="ATM – Zachód SF"},
    -- Los Santos
    {x=650.0,  y=-600.0,z=16.3,  name="ATM – Centrum LS"},
    {x=1248.0, y=-785.0,z=11.1,  name="ATM – LS Wschodnia"},
    -- Las Venturas
    {x=2237.0, y=2470.0,z=10.8,  name="ATM – Centrum LV"},
    {x=2380.0, y=1990.0,z=10.8,  name="ATM – Płd. LV"},
}

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    for _, atm in ipairs(ATM_LOCATIONS) do
        local m = createMarker(atm.x, atm.y, atm.z-1, "cylinder", 1.2, 0,180,255,180)
        local b = createBlip(atm.x, atm.y, atm.z, 52, 1.5, 0,180,255,255)
        setBlipName(b, atm.name)
        setElementData(m, "isATM", true, false)
        setElementData(m, "atmName", atm.name, false)
    end
    outputServerLog("[rp_bank] " .. #ATM_LOCATIONS .. " bankomatów załadowanych.")
end)

addEventHandler("onMarkerHit", root, function(hitPlayer, dim)
    if getElementType(hitPlayer) ~= "player" then return end
    if not exports.rp_characters:isSpawned(hitPlayer) then return end
    if not getElementData(source, "isATM") then return end

    local c    = exports.rp_characters:getCharacter(hitPlayer)
    local hist = exports.rp_economy:getTransactions(c.id, 20)
    triggerClientEvent(hitPlayer, "rpBank:openATM", hitPlayer,
        c.cash, c.bank, hist or {},
        getElementData(source, "atmName") or "Bankomat")
end)
