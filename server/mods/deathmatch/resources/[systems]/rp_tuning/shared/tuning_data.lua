--[[
    rp_tuning – Katalog ulepszeń
    Źródło ID: MTA:SA Vehicle Component IDs
--]]

TUNING_CATEGORIES = {
    "Silnik", "Skrzynia biegów", "Wydech", "Body-kit", "Spojler",
    "Felgi", "Nitro", "Hamulce", "Hydraulika"
}

-- Ulepszenia wspólne dla wszystkich pojazdów
TUNING_ITEMS = {
    -- Silnik (zwiększa przyspieszenie)
    { id=1008, name="Silnik Lvl.1",       cat="Silnik",        price=5000  },
    { id=1009, name="Silnik Lvl.2",       cat="Silnik",        price=10000 },
    { id=1010, name="Silnik Lvl.3",       cat="Silnik",        price=20000 },
    -- Skrzynia
    { id=1001, name="Skrzynia Sport",     cat="Skrzynia biegów",price=6000 },
    { id=1002, name="Skrzynia Race",      cat="Skrzynia biegów",price=12000},
    -- Wydech
    { id=1018, name="Wydech Standard",    cat="Wydech",        price=1500  },
    { id=1019, name="Wydech Sport",       cat="Wydech",        price=3000  },
    { id=1020, name="Wydech Race",        cat="Wydech",        price=6000  },
    -- Spojler
    { id=1049, name="Spojler A",          cat="Spojler",       price=2000  },
    { id=1050, name="Spojler B",          cat="Spojler",       price=3500  },
    { id=1138, name="Spojler OEM",        cat="Spojler",       price=1000  },
    -- Nitro
    { id=1008, name="Nitro x2",           cat="Nitro",         price=3000  },
    { id=1009, name="Nitro x5",           cat="Nitro",         price=6000  },
    { id=1010, name="Nitro x10",          cat="Nitro",         price=10000 },
    -- Felgi
    { id=1025, name="Felgi Standardowe",  cat="Felgi",         price=1000  },
    { id=1073, name="Felgi Sportowe",     cat="Felgi",         price=3000  },
    { id=1074, name="Felgi Street",       cat="Felgi",         price=4000  },
    { id=1075, name="Felgi Wire Gold",    cat="Felgi",         price=8000  },
    { id=1076, name="Felgi Lowrider",     cat="Felgi",         price=5000  },
    { id=1077, name="Felgi Off-road",     cat="Felgi",         price=4500  },
    { id=1078, name="Felgi Classique",    cat="Felgi",         price=3500  },
    { id=1080, name="Felgi Chrome",       cat="Felgi",         price=7000  },
    -- Hamulce
    { id=1006, name="Hamulce Sport",      cat="Hamulce",       price=4000  },
    { id=1007, name="Hamulce Race",       cat="Hamulce",       price=8000  },
}

-- Ceny lakieru
PAINT_JOBS = {
    {id=1, name="Metalik Czarny",   r=20,  g=20,  b=20  },
    {id=2, name="Metalik Szary",    r=80,  g=80,  b=80  },
    {id=3, name="Metalik Biały",    r=230, g=230, b=230 },
    {id=4, name="Metalik Czerwony", r=180, g=20,  b=20  },
    {id=5, name="Metalik Niebieski",r=20,  g=80,  b=200 },
    {id=6, name="Metalik Zielony",  r=20,  g=150, b=60  },
    {id=7, name="Metalik Złoty",    r=200, g=170, b=30  },
    {id=8, name="Metalik Różowy",   r=200, g=80,  b=150 },
    {id=9, name="Metalik Fioletowy",r=120, g=30,  b=180 },
}
PAINT_PRICE = 500  -- cena za zmianę lakieru

-- Nitro IDs MTA
NITRO_IDS = { 1008, 1009, 1010 }
