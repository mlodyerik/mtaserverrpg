--[[
    rp_hud – Główny HUD
    Lewy dół: HP, Armour, Głód, Pragnienie
    Prawy dół: Gotówka, Bank, Poziom, XP, Czas gry
    Ukrywa domyślny HUD MTA.
--]]

local W, H   = guiGetScreenSize()
local visible = false
local hudData = {
    hp=100, armour=0, hunger=100, thirst=100,
    cash=0, bank=0, level=1, xp=0,
    name="", jobName="", totalMinutes=0
}

local function hudVisible(v)
    visible = v
    setPlayerHudComponentVisible("all", false)
    setPlayerHudComponentVisible("radar", true)
    setPlayerHudComponentVisible("clock", false)
end

-- ============================================================
--  RYSOWANIE
-- ============================================================
addEventHandler("onClientRender", root, function()
    if not visible then return end

    local lx = 16     -- lewy dół
    local ly = H - 160
    local rx = W - 220  -- prawy dół
    local ry = H - 200

    -- === LEWY DÓŁ ===

    -- Tło lewego bloku
    dxDrawRectangle(lx-6, ly-6, 190, 152, tocolor(15,15,20,180))
    dxDrawRectangle(lx-6, ly-6, 3, 152, tocolor(30,144,255,200))

    -- HP
    local hp = math.max(0, math.min(100, hudData.hp))
    local hpColor = hp > 60 and tocolor(60,200,100,220)
                  or hp > 30 and tocolor(255,180,40,220)
                  or tocolor(220,60,60,220)
    dxDrawText("♥ HP", lx, ly+2, lx+180, ly+20, tocolor(140,148,160,200), 0.85,"default","left","top")
    dxDrawRectangle(lx, ly+20, 170, 10, tocolor(30,30,35,200))
    dxDrawRectangle(lx, ly+20, math.floor(170*(hp/100)), 10, hpColor)
    dxDrawText(tostring(math.floor(hp)), lx+175, ly+14, lx+200, ly+30, hpColor, 0.8,"default","left","top")

    -- Armour
    local ar = math.max(0, math.min(100, hudData.armour))
    dxDrawText("✦ Pancerz", lx, ly+36, lx+180, ly+52, tocolor(140,148,160,200), 0.85,"default","left","top")
    dxDrawRectangle(lx, ly+52, 170, 10, tocolor(30,30,35,200))
    dxDrawRectangle(lx, ly+52, math.floor(170*(ar/100)), 10, tocolor(30,144,255,200))
    dxDrawText(tostring(math.floor(ar)), lx+175, ly+46, lx+200, ly+62, tocolor(30,144,255,200), 0.8,"default","left","top")

    -- Głód
    local hu = math.max(0, math.min(100, hudData.hunger))
    dxDrawText("🍗 Głód", lx, ly+68, lx+180, ly+84, tocolor(140,148,160,200), 0.85,"default","left","top")
    dxDrawRectangle(lx, ly+84, 170, 8, tocolor(30,30,35,200))
    dxDrawRectangle(lx, ly+84, math.floor(170*(hu/100)), 8, tocolor(220,160,40,200))

    -- Pragnienie
    local th = math.max(0, math.min(100, hudData.thirst))
    dxDrawText("💧 Pragnienie", lx, ly+98, lx+180, ly+114, tocolor(140,148,160,200), 0.85,"default","left","top")
    dxDrawRectangle(lx, ly+114, 170, 8, tocolor(30,30,35,200))
    dxDrawRectangle(lx, ly+114, math.floor(170*(th/100)), 8, tocolor(60,160,255,200))

    -- Praca
    if hudData.jobName and hudData.jobName ~= "" then
        dxDrawText("⚙ " .. hudData.jobName, lx, ly+128, lx+180, ly+146,
            tocolor(100,160,255,200), 0.9,"default","left","top")
    end

    -- === PRAWY DÓŁ ===

    -- Tło prawego bloku
    dxDrawRectangle(rx-6, ry-6, 210, 190, tocolor(15,15,20,180))
    dxDrawRectangle(rx+204, ry-6, 3, 190, tocolor(30,144,255,200))

    -- Nazwa
    dxDrawText(hudData.name or "", rx, ry, rx+200, ry+22,
        tocolor(30,144,255,220), 1.0,"default-bold","right","top")

    -- Poziom + XP
    local xpNeeded = hudData.level * 100
    local xpPct    = math.min(1, (hudData.xp or 0) / math.max(1, xpNeeded))
    dxDrawText("POZIOM " .. (hudData.level or 1), rx, ry+26, rx+200, ry+44,
        tocolor(140,148,160,200), 0.85,"default","right","top")
    dxDrawRectangle(rx, ry+46, 200, 6, tocolor(30,30,35,200))
    dxDrawRectangle(rx, ry+46, math.floor(200*xpPct), 6, tocolor(30,144,255,200))

    -- Separator
    dxDrawRectangle(rx, ry+58, 200, 1, tocolor(40,45,55,200))

    -- Gotówka
    dxDrawText("GOTÓWKA", rx, ry+64, rx+200, ry+80, tocolor(140,148,160,200), 0.8,"default","right","top")
    dxDrawText(formatMoney(hudData.cash or 0), rx, ry+78, rx+200, ry+98,
        tocolor(60,200,100,230), 1.1,"default-bold","right","top")

    -- Bank
    dxDrawText("BANK", rx, ry+102, rx+200, ry+118, tocolor(140,148,160,200), 0.8,"default","right","top")
    dxDrawText(formatMoney(hudData.bank or 0), rx, ry+116, rx+200, ry+136,
        tocolor(100,160,255,230), 1.0,"default-bold","right","top")

    -- Czas gry
    local mins  = hudData.totalMinutes or 0
    local hrs   = math.floor(mins/60)
    local mrem  = mins % 60
    dxDrawText(string.format("Czas: %dh %02dm", hrs, mrem),
        rx, ry+140, rx+200, ry+158, tocolor(140,148,160,200), 0.8,"default","right","top")

    -- Serwer (zegar)
    local h2,m2,s2 = getTime()
    dxDrawText(string.format("%02d:%02d:%02d", h2, m2, s2),
        rx, ry+158, rx+200, ry+178, tocolor(200,210,220,220), 1.0,"default-bold","right","top")
end)

-- ============================================================
--  EVENTY
-- ============================================================
addEvent("rpChar:onSpawn", true)
addEventHandler("rpChar:onSpawn", root, function(charData)
    if not charData then return end
    hudData.hp      = charData.hp     or 100
    hudData.armour  = charData.armour or 0
    hudData.hunger  = charData.hunger or 100
    hudData.thirst  = charData.thirst or 100
    hudData.cash    = charData.cash   or 0
    hudData.bank    = charData.bank   or 0
    hudData.level   = charData.level  or 1
    hudData.xp      = charData.xp    or 0
    hudData.name    = charData.name   or ""
    hudData.totalMinutes = charData.totalMinutes or 0
    hudVisible(true)
end)

addEvent("rpEconomy:update", true)
addEventHandler("rpEconomy:update", root, function(cash, bank)
    hudData.cash = cash or hudData.cash
    hudData.bank = bank or hudData.bank
end)

addEvent("rpChar:updateHUD", true)
addEventHandler("rpChar:updateHUD", root, function(charData)
    if not charData then return end
    for k, v in pairs(charData) do hudData[k] = v end
end)

addEvent("rpChar:levelUp", true)
addEventHandler("rpChar:levelUp", root, function(newLevel)
    hudData.level = newLevel
    triggerEvent("rpNotif:local", localPlayer, "success", "Awans!", "Osiągnąłeś poziom " .. newLevel .. "!")
end)

addEvent("rpJobs:setJobName", true)
addEventHandler("rpJobs:setJobName", root, function(name)
    hudData.jobName = name or ""
end)

-- Aktualizacja HP co klatkę
addEventHandler("onClientRender", root, function()
    if not visible then return end
    hudData.hp     = getElementHealth(localPlayer)
    hudData.armour = getPedArmor(localPlayer)
end)
