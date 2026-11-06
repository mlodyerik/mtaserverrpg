--[[
    rp_core – Rate limiter (zapobiega spamowaniu eventów)
    Użycie: exports.rp_core:rateLimitCheck(player, "buy_item", 1000)
    Zwraca true jeśli akcja dozwolona, false jeśli za szybko.
--]]

local _limits = {} -- [player][action] = lastTime

addEventHandler("onPlayerQuit", root, function()
    _limits[source] = nil
end)

function rateLimitCheck(player, action, intervalMs)
    intervalMs = intervalMs or 500
    local now = getTickCount()
    if not _limits[player] then _limits[player] = {} end
    local last = _limits[player][action] or 0
    if now - last < intervalMs then
        return false
    end
    _limits[player][action] = now
    return true
end
