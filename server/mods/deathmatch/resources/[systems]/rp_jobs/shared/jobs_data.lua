--[[
    rp_jobs – Dane prac
--]]

JOBS = {
    [JOB_COURIER] = {
        id       = JOB_COURIER,
        name     = "Kurier",
        icon     = "📦",
        desc     = "Dostarczaj paczki w San Fierro i okolicach",
        basePay  = 120,    -- $ za dostarczenie
        xpPer    = 15,
        vehicle  = 478,    -- Walton
        maxLevel = 10,
        startX   = -1951.0, startY = 155.0, startZ = 35.2,
        blipId   = 51,
    },
    [JOB_TAXI] = {
        id       = JOB_TAXI,
        name     = "Taksówkarz",
        icon     = "🚕",
        desc     = "Zawożaj pasażerów po San Andreas",
        basePay  = 150,
        xpPer    = 20,
        vehicle  = 420,    -- Taxi
        maxLevel = 10,
        startX   = -2008.0, startY = 136.0, startZ = 28.8,
        blipId   = 56,
    },
    [JOB_BUS] = {
        id       = JOB_BUS,
        name     = "Kierowca Autobusu",
        icon     = "🚌",
        desc     = "Obsługuj trasy autobusowe",
        basePay  = 200,
        xpPer    = 25,
        vehicle  = 431,    -- Bus
        maxLevel = 10,
        startX   = -1976.0, startY = 103.0, startZ = 28.3,
        blipId   = 410,
    },
    [JOB_TRUCK] = {
        id       = JOB_TRUCK,
        name     = "Kierowca Ciężarówki",
        icon     = "🚛",
        desc     = "Transportuj ładunki między miastami",
        basePay  = 350,
        xpPer    = 40,
        vehicle  = 403,    -- Linerunner
        maxLevel = 10,
        startX   = -1892.0, startY = 40.0, startZ = 35.2,
        blipId   = 510,
        requireLicenceTruck = true,
    },
    [JOB_MOWER] = {
        id       = JOB_MOWER,
        name     = "Kosiarz",
        icon     = "🌿",
        desc     = "Kos trawę na boiskach i parkach",
        basePay  = 80,
        xpPer    = 10,
        vehicle  = 572,    -- Mower
        maxLevel = 5,
        startX   = -1974.0, startY = 455.0, startZ = 35.2,
        blipId   = 139,
    },
    [JOB_DIVER] = {
        id       = JOB_DIVER,
        name     = "Nurek",
        icon     = "🤿",
        desc     = "Zbieraj przedmioty pod wodą w zatoce SF",
        basePay  = 200,
        xpPer    = 30,
        vehicle  = 0,
        maxLevel = 8,
        startX   = -2159.0, startY = 253.0, startZ = 3.0,
        blipId   = 119,
    },
    [JOB_GARBAGE] = {
        id       = JOB_GARBAGE,
        name     = "Śmieciarz",
        icon     = "🗑",
        desc     = "Zbieraj śmieci po mieście",
        basePay  = 100,
        xpPer    = 12,
        vehicle  = 408,    -- Trashmaster
        maxLevel = 6,
        startX   = -1935.0, startY = 247.0, startZ = 35.2,
        blipId   = 453,
    },
    [JOB_WAREHOUSE] = {
        id       = JOB_WAREHOUSE,
        name     = "Magazynier",
        icon     = "📋",
        desc     = "Sortuj i przenoś towary w magazynie portowym",
        basePay  = 90,
        xpPer    = 12,
        vehicle  = 0,
        maxLevel = 6,
        startX   = -1913.0, startY = -6.0, startZ = 35.2,
        blipId   = 184,
    },
    [JOB_FISHERMAN] = {
        id       = JOB_FISHERMAN,
        name     = "Rybak",
        icon     = "🎣",
        desc     = "Łów ryby na wybrzeżu San Fierro",
        basePay  = 150,
        xpPer    = 18,
        vehicle  = 484,    -- Marquis
        maxLevel = 8,
        startX   = -2360.0, startY = 400.0, startZ = 2.0,
        blipId   = 253,
    },
    [JOB_PILOT] = {
        id       = JOB_PILOT,
        name     = "Pilot",
        icon     = "✈️",
        desc     = "Transportuj pasażerów między lotniskami",
        basePay  = 500,
        xpPer    = 60,
        vehicle  = 519,    -- Shamal
        maxLevel = 10,
        startX   = -1314.0, startY = -300.0, startZ = 14.1,
        blipId   = 16,
    },
}

-- Nazwy prac wg ID
function getJobNameById(id)
    return JOBS[id] and JOBS[id].name or "Bezrobotny"
end
