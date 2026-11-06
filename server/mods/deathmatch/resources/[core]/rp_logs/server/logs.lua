--[[
    rp_logs – Logi administracyjne i systemowe
--]]

-- Wpisuje do tabeli admin_logs i do pliku logów MTA
function logAdmin(adminName, targetName, action, details)
    adminName  = tostring(adminName  or "system")
    targetName = tostring(targetName or "")
    action     = tostring(action     or "unknown")
    details    = tostring(details    or "")

    exports.rp_database:dbExecute(
        "INSERT INTO admin_logs (admin_name, target_name, action, details) VALUES (?,?,?,?)",
        adminName, targetName, action, details
    )
    outputServerLog(string.format("[ADMIN] %s -> %s | %s | %s",
        adminName, targetName, action, details))
end

-- Logi techniczne (tylko plik serwera)
function logSystem(module, message)
    outputServerLog(string.format("[%s] %s", tostring(module), tostring(message)))
end

-- Logi czatu (możliwe rozszerzenie o tabelę)
function logChat(playerName, message, chatType)
    outputServerLog(string.format("[CHAT][%s] %s: %s",
        tostring(chatType or "say"), tostring(playerName), tostring(message)))
end

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    logSystem("rp_logs", "System logowania uruchomiony.")
end)
