--[[
    rp_notifications – DX Toast Notifications
    Typ: success | error | info | warning
    Wyświetla do 5 powiadomień jednocześnie, animacja slide-in/out
--]]

local W, H = guiGetScreenSize()

local queue = {}    -- kolejka oczekujących
local active = {}   -- aktywne: { text, title, type, alpha, y, timer }

local MAX_ACTIVE  = 5
local NOTIF_W     = 320
local NOTIF_H     = 56
local NOTIF_X     = W - NOTIF_W - 16
local NOTIF_BASE_Y = H - 70
local ANIM_SPEED  = 12

local COLORS = {
    success = { 60,  200, 100 },
    error   = { 220,  60,  60 },
    info    = {  30, 144, 255 },
    warning = { 255, 180,  40 },
}

local function addNotif(nType, title, text)
    nType = nType or "info"
    local color = COLORS[nType] or COLORS.info
    local n = {
        title   = tostring(title or ""),
        text    = tostring(text  or ""),
        color   = color,
        alpha   = 0,
        slideX  = NOTIF_W + 20,  -- wjeżdża z prawej
        state   = "in",  -- in → show → out
        timer   = 0,
        holdMs  = 4000,
    }
    table.insert(active, 1, n)
    if #active > MAX_ACTIVE then table.remove(active) end
end

-- ============================================================
--  RENDER
-- ============================================================
addEventHandler("onClientRender", root, function()
    local dt = 1

    for i, n in ipairs(active) do
        local targetY = NOTIF_BASE_Y - (i-1) * (NOTIF_H + 8)

        if n.state == "in" then
            n.alpha  = math.min(255, n.alpha + ANIM_SPEED * 2)
            n.slideX = math.max(0, n.slideX - 20)
            if n.alpha >= 255 and n.slideX <= 0 then
                n.state   = "show"
                n.timer   = getTickCount()
            end
        elseif n.state == "show" then
            if getTickCount() - n.timer > n.holdMs then
                n.state = "out"
            end
        elseif n.state == "out" then
            n.alpha  = math.max(0, n.alpha - ANIM_SPEED)
            n.slideX = n.slideX + 12
            if n.alpha <= 0 then
                table.remove(active, i)
                break
            end
        end

        local a  = math.floor(n.alpha)
        local nx = NOTIF_X + n.slideX
        local ny = targetY

        -- Tło
        dxDrawRectangle(nx, ny, NOTIF_W, NOTIF_H, tocolor(15,15,20,math.min(a,220)))
        -- Pasek koloru po lewej
        dxDrawRectangle(nx, ny, 4, NOTIF_H, tocolor(n.color[1],n.color[2],n.color[3],a))
        -- Górna kreska
        dxDrawRectangle(nx+4, ny, NOTIF_W-4, 1, tocolor(n.color[1],n.color[2],n.color[3],math.floor(a*0.5)))

        -- Tytuł
        dxDrawText(n.title, nx+12, ny+6, nx+NOTIF_W-8, ny+26,
            tocolor(n.color[1],n.color[2],n.color[3],a), 1.0,"default-bold","left","top")
        -- Tekst
        dxDrawText(n.text, nx+12, ny+24, nx+NOTIF_W-8, ny+NOTIF_H-4,
            tocolor(200,210,220,a), 0.9,"default","left","top")
    end
end)

-- ============================================================
--  EVENT SERWERA
-- ============================================================
addEvent("rpNotif:send", true)
addEventHandler("rpNotif:send", root, function(nType, title, text)
    addNotif(nType, title, text)
end)

-- Lokalny też
addEvent("rpNotif:local", false)
addEventHandler("rpNotif:local", root, function(nType, title, text)
    addNotif(nType, title, text)
end)
