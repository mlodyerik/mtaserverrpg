--[[
    rp_jobs – Logika prac (serwer)
    Każda praca: przyjmij → wykonaj misję → dostarcz → wypłata
    Misje generowane proceduralnie.
--]]

local activeMissions = {}  -- [player] = { jobId, missionData, vehicleElement }

-- ============================================================
--  PUNKTY POBORU PRACY (markery)
-- ============================================================
local jobMarkers   = {}
local jobBlips     = {}

local function createJobMarkers()
    for id, job in pairs(JOBS) do
        local marker = createMarker(job.startX, job.startY, job.startZ-1, "cylinder", 1.8, 30,144,255,150)
        local blip   = createBlip(job.startX, job.startY, job.startZ, job.blipId, 1.5, 255,255,255,255)
        setBlipName(blip, job.name)
        setElementData(marker, "jobId", id, false)
        jobMarkers[id] = marker
        jobBlips[id]   = blip
    end
    outputServerLog("[rp_jobs] " .. #JOBS .. " punktów pracy utworzonych.")
end

addEventHandler("onResourceStart", resourceRoot, function()
    if source ~= getThisResource() then return end
    createJobMarkers()
end)

-- ============================================================
--  WEJŚCIE W MARKER → POKAŻ PANEL
-- ============================================================
addEventHandler("onMarkerHit", root, function(hitPlayer, dim)
    if getElementType(hitPlayer) ~= "player" then return end
    if not exports.rp_characters:isSpawned(hitPlayer) then return end

    local jobId = getElementData(source, "jobId")
    if not jobId then return end

    local job = JOBS[jobId]
    if not job then return end

    -- Sprawdź licencję
    local c = exports.rp_characters:getCharacter(hitPlayer)
    if job.requireLicenceTruck and not c.licenceTruck then
        triggerClientEvent(hitPlayer,"rpNotif:send",hitPlayer,"error","Praca",
            "Potrzebujesz prawa jazdy kat. C (ciężarówka).")
        return
    end

    triggerClientEvent(hitPlayer, "rpJobs:showPanel", hitPlayer, job, c.jobId, c.jobLevel, c.jobXp)
end)

-- ============================================================
--  PRZYJĘCIE / ZMIANA PRACY
-- ============================================================
addEvent("rpJobs:takeJob", true)
addEventHandler("rpJobs:takeJob", root, function(jobId)
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    if not exports.rp_core:rateLimitCheck(player, "take_job", 2000) then return end

    jobId = tonumber(jobId)
    local job = JOBS[jobId]
    if not job then return end

    local c = exports.rp_characters:getCharacter(player)

    -- Jeśli ma aktywną misję, anuluj ją
    if activeMissions[player] then
        cancelMission(player, true)
    end

    c.jobId = jobId
    exports.rp_database:dbExecute(
        "UPDATE characters SET job_id=? WHERE id=?", jobId, c.id
    )

    triggerClientEvent(player,"rpJobs:setJobName",player, job.name)
    triggerClientEvent(player,"rpNotif:send",player,"success","Praca",
        "Zatrudniono jako: " .. job.name)

    -- Start pierwszej misji
    startMission(player, jobId)
end)

-- ============================================================
--  GENERATOR MISJI
-- ============================================================
local SF_DELIVERY_POINTS = {
    {x=-2186.0, y=943.0,  z=35.3,  name="Targ Rybny SF"},
    {x=-1934.0, y=290.0,  z=35.2,  name="Centrum SF"},
    {x=-2050.0, y=665.0,  z=35.2,  name="Chinatown SF"},
    {x=-1961.0, y=471.0,  z=35.2,  name="Dzielnica Północna SF"},
    {x=-2373.0, y=601.0,  z=35.2,  name="Zachód SF"},
    {x=-1672.0, y=1388.0, z=7.2,   name="Lotnisko SF"},
    {x=687.0,   y=-609.0, z=16.3,  name="Sklep w LS"},
    {x=2152.0,  y=1017.0, z=10.8,  name="Centrum LV"},
}

local TRUCK_ROUTES = {
    {from={x=-1892.0,y=40.0,z=35.2,name="Depot SF"}, to={x=2152.0,y=1017.0,z=10.8,name="Depot LV"}, dist=3, bonus=200},
    {from={x=-1892.0,y=40.0,z=35.2,name="Depot SF"}, to={x=687.0,y=-609.0,z=16.3,name="Depot LS"}, dist=3, bonus=180},
    {from={x=687.0,y=-609.0,z=16.3,name="Depot LS"}, to={x=-1892.0,y=40.0,z=35.2,name="Depot SF"}, dist=3, bonus=175},
}

local BUS_STOPS_SF = {
    {x=-2008.0,y=136.0,z=28.8,   name="Dworzec SF (Start)"},
    {x=-2186.0,y=943.0,z=35.3,   name="Targ Rybny"},
    {x=-2050.0,y=665.0,z=35.2,   name="Chinatown"},
    {x=-1934.0,y=290.0,z=35.2,   name="Centrum"},
    {x=-1951.0,y=155.0,z=35.2,   name="Port"},
    {x=-2008.0,y=136.0,z=28.8,   name="Dworzec SF (Koniec)"},
}

local DIVE_SPOTS = {
    {x=-2250.0,y=350.0,z=-5.0,  name="Zatoka A"},
    {x=-2300.0,y=420.0,z=-8.0,  name="Zatoka B"},
    {x=-2180.0,y=280.0,z=-6.0,  name="Zatoka C"},
}

local GARBAGE_POINTS = {
    {x=-2186.0,y=900.0,z=35.3,  name="Targ"},
    {x=-2060.0,y=650.0,z=35.2,  name="Park"},
    {x=-1940.0,y=500.0,z=35.2,  name="Ulica A"},
    {x=-1980.0,y=350.0,z=35.2,  name="Ulica B"},
    {x=-1950.0,y=200.0,z=35.2,  name="Port"},
}

local FISH_SPOTS = {
    {x=-2360.0,y=370.0,z=1.0},
    {x=-2400.0,y=420.0,z=1.0},
    {x=-2320.0,y=330.0,z=1.0},
}

function startMission(player, jobId)
    local job = JOBS[jobId]
    if not job then return end
    local c   = exports.rp_characters:getCharacter(player)

    local mission = { jobId = jobId, stage = 0 }

    if jobId == JOB_COURIER then
        local pt = SF_DELIVERY_POINTS[math.random(#SF_DELIVERY_POINTS)]
        mission.dest = pt
        mission.reward = job.basePay + math.random(0, 50) + c.jobLevel * 10
        mission.xp     = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Kurier: Dostawa",
            desc    = "Dostarcz paczkę do: " .. pt.name,
            targetX = pt.x, targetY = pt.y, targetZ = pt.z,
            reward  = mission.reward,
        })

    elseif jobId == JOB_TAXI then
        -- Losowy pasażer gdzieś w mieście
        local pickup = SF_DELIVERY_POINTS[math.random(#SF_DELIVERY_POINTS)]
        local dest   = SF_DELIVERY_POINTS[math.random(#SF_DELIVERY_POINTS)]
        while dest == pickup do dest = SF_DELIVERY_POINTS[math.random(#SF_DELIVERY_POINTS)] end
        mission.pickup  = pickup
        mission.dest    = dest
        mission.stage   = 1  -- 1=pick up, 2=deliver
        mission.reward  = math.floor(
            dist3D(pickup.x,pickup.y,pickup.z,dest.x,dest.y,dest.z) * 2 + 50
        ) + c.jobLevel * 15
        mission.xp = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Taxi: Odbierz pasażera",
            desc    = "Jedź po pasażera do: " .. pickup.name,
            targetX = pickup.x, targetY = pickup.y, targetZ = pickup.z,
            reward  = mission.reward,
        })

    elseif jobId == JOB_BUS then
        mission.stops      = BUS_STOPS_SF
        mission.stopIndex  = 1
        mission.reward     = 0
        mission.xp         = job.xpPer
        local stop = BUS_STOPS_SF[1]
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Bus SF: Przystanek 1/" .. #BUS_STOPS_SF,
            desc    = "Jedź do: " .. stop.name,
            targetX = stop.x, targetY = stop.y, targetZ = stop.z,
            reward  = job.basePay * #BUS_STOPS_SF,
        })

    elseif jobId == JOB_TRUCK then
        local route = TRUCK_ROUTES[math.random(#TRUCK_ROUTES)]
        mission.route  = route
        mission.stage  = 1
        mission.reward = job.basePay + route.bonus + c.jobLevel * 30
        mission.xp     = job.xpPer * 3
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Transport: Załadunek",
            desc    = "Jedź do bazy: " .. route.from.name,
            targetX = route.from.x, targetY = route.from.y, targetZ = route.from.z,
            reward  = mission.reward,
        })

    elseif jobId == JOB_MOWER then
        -- Kos do zielona na określonym obszarze (timer 60s)
        mission.timeLeft = 60
        mission.reward   = job.basePay + c.jobLevel * 5
        mission.xp       = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Kosiarz",
            desc    = "Kos trawę przez 60 sekund (jedź na zielonej kosiarce)",
            targetX = job.startX+10, targetY = job.startY, targetZ = job.startZ,
            reward  = mission.reward,
        })
        -- Timer misji
        mission.timer = setTimer(function()
            if activeMissions[player] and activeMissions[player].jobId == JOB_MOWER then
                completeMission(player)
            end
        end, 60000, 1)

    elseif jobId == JOB_DIVER then
        local spot = DIVE_SPOTS[math.random(#DIVE_SPOTS)]
        mission.spot   = spot
        mission.reward = job.basePay + c.jobLevel * 20
        mission.xp     = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Nurek: Zanurkuj",
            desc    = "Dopłyń do punktu i zanurkuj",
            targetX = spot.x, targetY = spot.y, targetZ = spot.z,
            reward  = mission.reward,
        })

    elseif jobId == JOB_GARBAGE then
        -- Zbierz 5 punktów śmieci
        local points = {}
        for i = 1, 5 do
            table.insert(points, GARBAGE_POINTS[math.random(#GARBAGE_POINTS)])
        end
        mission.points    = points
        mission.collected = 0
        mission.reward    = job.basePay + c.jobLevel * 8
        mission.xp        = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Śmieciarz: Zbierz śmieci 0/5",
            desc    = "Jedź po kontenery śmietnika",
            targetX = points[1].x, targetY = points[1].y, targetZ = points[1].z,
            reward  = mission.reward,
        })

    elseif jobId == JOB_WAREHOUSE then
        -- Przenieś 3 ładunki (kliknij 3x w markery)
        mission.needed = 3
        mission.done   = 0
        mission.reward = job.basePay + c.jobLevel * 8
        mission.xp     = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Magazynier: Przenoś ładunki 0/3",
            desc    = "Podejdź do ładunku i naciśnij E",
            targetX = job.startX+5, targetY = job.startY, targetZ = job.startZ,
            reward  = mission.reward,
        })

    elseif jobId == JOB_FISHERMAN then
        local spot = FISH_SPOTS[math.random(#FISH_SPOTS)]
        mission.spot    = spot
        mission.timeLeft= 90
        mission.reward  = job.basePay + c.jobLevel * 15
        mission.xp      = job.xpPer
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Rybak: Łów ryby",
            desc    = "Jedź na łódkę i łów przez 90s",
            targetX = spot.x, targetY = spot.y, targetZ = spot.z,
            reward  = mission.reward,
        })
        mission.timer = setTimer(function()
            if activeMissions[player] and activeMissions[player].jobId == JOB_FISHERMAN then
                completeMission(player)
            end
        end, 90000, 1)

    elseif jobId == JOB_PILOT then
        -- Lot SF → LS
        local dest = {x=1665.0,y=-2398.0,z=14.0,name="Lotnisko LS"}
        mission.dest   = dest
        mission.reward = job.basePay + c.jobLevel * 40
        mission.xp     = job.xpPer * 2
        triggerClientEvent(player,"rpJobs:newMission",player, {
            title   = "Pilot: Lot do LS",
            desc    = "Leć do lotniska: " .. dest.name,
            targetX = dest.x, targetY = dest.y, targetZ = dest.z,
            reward  = mission.reward,
        })
    end

    activeMissions[player] = mission
end

-- ============================================================
--  UKOŃCZENIE MISJI (wejście w cel)
-- ============================================================
addEvent("rpJobs:reachedTarget", true)
addEventHandler("rpJobs:reachedTarget", root, function()
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    local mission = activeMissions[player]
    if not mission then return end

    local jobId = mission.jobId
    local job   = JOBS[jobId]

    if jobId == JOB_TAXI then
        if mission.stage == 1 then
            -- Odebrano pasażera, jedź do celu
            mission.stage = 2
            triggerClientEvent(player,"rpJobs:updateTarget",player,
                mission.dest.x, mission.dest.y, mission.dest.z,
                "Taxi: Dowieź pasażera do " .. mission.dest.name)
            return
        end
    end

    if jobId == JOB_TRUCK then
        if mission.stage == 1 then
            mission.stage = 2
            triggerClientEvent(player,"rpJobs:updateTarget",player,
                mission.route.to.x, mission.route.to.y, mission.route.to.z,
                "Transport: Jedź do " .. mission.route.to.name)
            return
        end
    end

    if jobId == JOB_BUS then
        mission.stopIndex = mission.stopIndex + 1
        mission.reward    = (mission.reward or 0) + job.basePay
        if mission.stopIndex > #mission.stops then
            completeMission(player)
            return
        end
        local stop = mission.stops[mission.stopIndex]
        triggerClientEvent(player,"rpJobs:updateTarget",player,
            stop.x, stop.y, stop.z,
            "Bus SF: Przystanek " .. mission.stopIndex .. "/" .. #mission.stops)
        return
    end

    if jobId == JOB_GARBAGE then
        mission.collected = mission.collected + 1
        if mission.collected >= 5 then
            completeMission(player)
            return
        end
        local pt = mission.points[mission.collected+1]
        triggerClientEvent(player,"rpJobs:updateTarget",player,
            pt.x, pt.y, pt.z,
            "Śmieciarz: Zbierz śmieci " .. mission.collected .. "/5")
        return
    end

    if jobId == JOB_WAREHOUSE then
        mission.done = mission.done + 1
        if mission.done >= mission.needed then
            completeMission(player)
            return
        end
        triggerClientEvent(player,"rpJobs:updateTarget",player,
            job.startX+5+mission.done*3, job.startY, job.startZ,
            "Magazynier: Ładunki " .. mission.done .. "/" .. mission.needed)
        return
    end

    completeMission(player)
end)

-- ============================================================
--  WYPŁATA
-- ============================================================
function completeMission(player)
    local mission = activeMissions[player]
    if not mission then return end

    local job = JOBS[mission.jobId]
    if not job then return end

    local reward = mission.reward or job.basePay
    local xp     = mission.xp    or job.xpPer

    exports.rp_economy:giveCash(player, reward, "job_pay_" .. mission.jobId)
    exports.rp_characters:giveXP(player, xp)

    -- Zapis do logu
    local c = exports.rp_characters:getCharacter(player)
    if c then
        c.jobXp = c.jobXp + xp
        exports.rp_database:dbExecute(
            "INSERT INTO jobs_log (char_id, job_id, reward, xp_gained) VALUES (?,?,?,?)",
            c.id, mission.jobId, reward, xp
        )
        -- Awans poziomu pracy
        local nextJobXP = job.maxLevel and (c.jobLevel+1) * 100 or 9999
        if c.jobXp >= nextJobXP and c.jobLevel < (job.maxLevel or 10) then
            c.jobLevel = c.jobLevel + 1
            c.jobXp    = 0
            triggerClientEvent(player,"rpNotif:send",player,"success","Praca",
                "Awans! Jesteś teraz poziomem " .. c.jobLevel .. " " .. job.name)
        end
    end

    -- Wyczyść timer jeśli był
    if mission.timer then killTimer(mission.timer) end

    activeMissions[player] = nil

    triggerClientEvent(player,"rpNotif:send",player,"success","Praca",
        "Misja ukończona! Zarobek: +" .. formatMoney(reward))

    -- Następna misja po 3 sekundach
    setTimer(function()
        local c2 = exports.rp_characters:getCharacter(player)
        if c2 and c2.jobId == mission.jobId and isPlayer(player) then
            startMission(player, mission.jobId)
        end
    end, 3000, 1)
end

function cancelMission(player, silent)
    local m = activeMissions[player]
    if not m then return end
    if m.timer then killTimer(m.timer) end
    activeMissions[player] = nil
    if not silent then
        triggerClientEvent(player,"rpNotif:send",player,"warning","Praca","Misja anulowana.")
    end
    triggerClientEvent(player,"rpJobs:clearTarget",player)
end

-- ============================================================
--  RZUCENIE PRACY
-- ============================================================
addEvent("rpJobs:quit", true)
addEventHandler("rpJobs:quit", root, function()
    local player = client
    if not exports.rp_characters:isSpawned(player) then return end
    cancelMission(player)
    local c = exports.rp_characters:getCharacter(player)
    if c then
        c.jobId = JOB_NONE
        exports.rp_database:dbExecute(
            "UPDATE characters SET job_id=0 WHERE id=?", c.id
        )
    end
    triggerClientEvent(player,"rpJobs:setJobName",player,"")
    triggerClientEvent(player,"rpNotif:send",player,"info","Praca","Zrezygnowałeś z pracy.")
end)

-- ============================================================
--  CZYSZCZENIE PRZY WYJŚCIU
-- ============================================================
addEventHandler("onPlayerQuit", root, function()
    cancelMission(source, true)
end)

-- ============================================================
--  EKSPORTY
-- ============================================================
function startJob(player, jobId) startMission(player, jobId) end
function stopJob(player)  cancelMission(player) end
function getJobName(jobId) return getJobNameById(jobId) end
