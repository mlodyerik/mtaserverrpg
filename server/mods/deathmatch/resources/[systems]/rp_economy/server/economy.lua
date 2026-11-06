--[[
    rp_economy – jedyny zasób zmieniający pieniądze.
    Zasada: żaden inny zasób nie modyfikuje c.cash ani c.bank bezpośrednio.
    Każda zmiana: weryfikacja → aktualizacja pamięci → async zapis do DB → log → event HUD.
--]]

-- Pobierz dane postaci gracza
local function getChar(player)
    return exports.rp_characters:getCharacter(player)
end

-- Zaktualizuj pola w DB asynchronicznie
local function saveMoneyToDB(charId, cash, bank)
    exports.rp_database:dbExecute(
        "UPDATE characters SET cash=?, bank=? WHERE id=?",
        cash, bank, charId
    )
end

-- Wyślij aktualizację do klienta (HUD)
local function notifyClient(player, c)
    triggerClientEvent(player, "rpEconomy:update", player, c.cash, c.bank)
end

-- ============================================================
--  LOG TRANSAKCJI
-- ============================================================
function logTransaction(charId, txType, amount, balanceAfter, description)
    exports.rp_database:dbExecute(
        "INSERT INTO transactions (char_id, type, amount, balance_after, description) VALUES (?,?,?,?,?)",
        charId, tostring(txType), math.floor(amount), math.floor(balanceAfter), tostring(description or "")
    )
end

-- ============================================================
--  GOTÓWKA
-- ============================================================
function giveCash(player, amount, reason)
    local c = getChar(player)
    if not c then return false, "Brak postaci" end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Kwota musi być dodatnia" end
    c.cash = math.min(c.cash + amount, MAX_CASH)
    saveMoneyToDB(c.id, c.cash, c.bank)
    logTransaction(c.id, reason or "give_cash", amount, c.cash, reason or "")
    notifyClient(player, c)
    return true
end

function takeCash(player, amount, reason)
    local c = getChar(player)
    if not c then return false, "Brak postaci" end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Kwota musi być dodatnia" end
    if c.cash < amount then return false, "Nie masz wystarczająco gotówki" end
    c.cash = c.cash - amount
    saveMoneyToDB(c.id, c.cash, c.bank)
    logTransaction(c.id, reason or "take_cash", -amount, c.cash, reason or "")
    notifyClient(player, c)
    return true
end

-- ============================================================
--  BANK
-- ============================================================
function giveBank(player, amount, reason)
    local c = getChar(player)
    if not c then return false, "Brak postaci" end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Kwota musi być dodatnia" end
    c.bank = math.min(c.bank + amount, MAX_BANK)
    saveMoneyToDB(c.id, c.cash, c.bank)
    logTransaction(c.id, reason or "give_bank", amount, c.bank, reason or "")
    notifyClient(player, c)
    return true
end

function takeBank(player, amount, reason)
    local c = getChar(player)
    if not c then return false, "Brak postaci" end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false, "Kwota musi być dodatnia" end
    if c.bank < amount then return false, "Niewystarczające środki na koncie" end
    c.bank = c.bank - amount
    saveMoneyToDB(c.id, c.cash, c.bank)
    logTransaction(c.id, reason or "take_bank", -amount, c.bank, reason or "")
    notifyClient(player, c)
    return true
end

-- ============================================================
--  GETTERY
-- ============================================================
function getCash(player)
    local c = getChar(player)
    return c and c.cash or 0
end

function getBank(player)
    local c = getChar(player)
    return c and c.bank or 0
end

-- ============================================================
--  PRZELEW MIĘDZY GRACZAMI (gotówka)
-- ============================================================
function transferCash(fromPlayer, toPlayer, amount, reason)
    local ok, err = takeCash(fromPlayer, amount, "transfer_out:" .. (reason or ""))
    if not ok then return false, err end
    local ok2, err2 = giveCash(toPlayer, amount, "transfer_in:" .. (reason or ""))
    if not ok2 then
        -- Zwrot
        giveCash(fromPlayer, amount, "transfer_refund")
        return false, err2
    end
    return true
end

-- ============================================================
--  GOTÓWKA → BANK  /  BANK → GOTÓWKA
-- ============================================================
function cashToBank(player, amount)
    local ok, err = takeCash(player, amount, "cash_to_bank")
    if not ok then return false, err end
    giveBank(player, amount, "cash_to_bank")
    return true
end

function bankToCash(player, amount)
    local ok, err = takeBank(player, amount, "bank_to_cash")
    if not ok then return false, err end
    giveCash(player, amount, "bank_to_cash")
    return true
end

-- ============================================================
--  HISTORIA TRANSAKCJI
-- ============================================================
function getTransactions(charId, limit)
    limit = math.min(tonumber(limit) or 20, 100)
    return exports.rp_database:dbGetAll(
        "SELECT type, amount, balance_after, description, created_at FROM transactions WHERE char_id=? ORDER BY id DESC LIMIT ?",
        charId, limit
    )
end

-- ============================================================
--  SYSTEM WYPŁAT (co 30 min dla frakcji)
-- ============================================================
local SALARY_INTERVAL_MS = 30 * 60 * 1000

setTimer(function()
    for _, player in ipairs(getElementsByType("player")) do
        local c = getChar(player)
        if c then
            -- Frakcja: pobierz wypłatę z DB
            local mem = exports.rp_database:dbGetRow(
                [[SELECT fr.salary FROM fraction_members fm
                  JOIN fraction_ranks fr ON fr.id = fm.rank_id
                  WHERE fm.char_id = ? AND fm.on_duty = 1]],
                c.id
            )
            if mem and mem.salary and mem.salary > 0 then
                giveCash(player, mem.salary, "fraction_salary")
                triggerClientEvent(player, "rpNotif:send", player,
                    "success", "Wypłata frakcyjna",
                    "Otrzymałeś " .. formatMoney(mem.salary) .. " wynagrodzenia.")
            end
        end
    end
end, SALARY_INTERVAL_MS, 0)

-- ============================================================
--  EVENTY KLIENTÓW (bankomat, wpłata, wypłata)
-- ============================================================
addEvent("rpEconomy:atmDeposit", true)
addEventHandler("rpEconomy:atmDeposit", root, function(amount)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "atm", 1000) then return end

    amount = math.floor(tonumber(amount) or 0)
    if not exports.rp_core:isValidAmount(amount, 1, MAX_CASH) then
        triggerClientEvent(player, "rpNotif:send", player,"error","Bankomat","Nieprawidłowa kwota.")
        return
    end

    local ok, err = cashToBank(player, amount)
    if ok then
        triggerClientEvent(player, "rpNotif:send", player,"success","Bankomat",
            "Wpłacono " .. formatMoney(amount) .. " na konto.")
        triggerClientEvent(player, "rpBank:updatePanel", player,
            getCash(player), getBank(player))
    else
        triggerClientEvent(player, "rpNotif:send", player,"error","Bankomat", err)
    end
end)

addEvent("rpEconomy:atmWithdraw", true)
addEventHandler("rpEconomy:atmWithdraw", root, function(amount)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "atm", 1000) then return end

    amount = math.floor(tonumber(amount) or 0)
    if not exports.rp_core:isValidAmount(amount, 1, MAX_BANK) then
        triggerClientEvent(player, "rpNotif:send", player,"error","Bankomat","Nieprawidłowa kwota.")
        return
    end

    local ok, err = bankToCash(player, amount)
    if ok then
        triggerClientEvent(player, "rpNotif:send", player,"success","Bankomat",
            "Wypłacono " .. formatMoney(amount) .. " gotówki.")
        triggerClientEvent(player, "rpBank:updatePanel", player,
            getCash(player), getBank(player))
    else
        triggerClientEvent(player, "rpNotif:send", player,"error","Bankomat", err)
    end
end)

addEvent("rpEconomy:transfer", true)
addEventHandler("rpEconomy:transfer", root, function(targetName, amount)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "transfer", 2000) then return end

    amount = math.floor(tonumber(amount) or 0)
    if not exports.rp_core:isValidAmount(amount, 1, MAX_BANK) then
        triggerClientEvent(player, "rpNotif:send", player,"error","Przelew","Nieprawidłowa kwota.")
        return
    end

    if type(targetName) ~= "string" or #targetName < 3 then
        triggerClientEvent(player, "rpNotif:send", player,"error","Przelew","Nieprawidłowy odbiorca.")
        return
    end

    -- Znajdź odbiorcę online
    local targetPlayer = nil
    for _, p in ipairs(getElementsByType("player")) do
        if exports.rp_characters:isSpawned(p) then
            local tc = exports.rp_characters:getCharacter(p)
            if tc and tc.name:lower() == targetName:lower() then
                targetPlayer = p
                break
            end
        end
    end

    if not targetPlayer then
        -- Spróbuj offline (tylko bank)
        local row = exports.rp_database:dbGetRow(
            "SELECT id, bank FROM characters WHERE name = ?", targetName
        )
        if not row then
            triggerClientEvent(player, "rpNotif:send", player,"error","Przelew","Nie znaleziono gracza.")
            return
        end
        local senderC = exports.rp_characters:getCharacter(player)
        if not senderC then return end
        local ok, err = takeBank(player, amount, "transfer_offline")
        if not ok then
            triggerClientEvent(player, "rpNotif:send", player,"error","Przelew", err)
            return
        end
        exports.rp_database:dbExecute(
            "UPDATE characters SET bank = bank + ? WHERE id = ?", amount, row.id
        )
        logTransaction(row.id, "transfer_in_offline", amount, row.bank + amount,
            "od " .. senderC.name)
        triggerClientEvent(player, "rpNotif:send", player,"success","Przelew",
            "Przelano " .. formatMoney(amount) .. " do " .. targetName)
        return
    end

    local senderC = exports.rp_characters:getCharacter(player)
    if senderC and targetPlayer == player then
        triggerClientEvent(player, "rpNotif:send", player,"error","Przelew","Nie możesz przelać sobie.")
        return
    end

    local ok2, err2 = takeBank(player, amount, "transfer_out")
    if not ok2 then
        triggerClientEvent(player, "rpNotif:send", player,"error","Przelew", err2)
        return
    end
    giveBank(targetPlayer, amount, "transfer_in")

    local tc = exports.rp_characters:getCharacter(targetPlayer)
    triggerClientEvent(player, "rpNotif:send", player,"success","Przelew",
        "Przelano " .. formatMoney(amount) .. " do " .. (tc and tc.name or targetName))
    triggerClientEvent(targetPlayer, "rpNotif:send", targetPlayer,"info","Przelew",
        "Otrzymano " .. formatMoney(amount) .. " od " .. (senderC and senderC.name or "?"))
end)
