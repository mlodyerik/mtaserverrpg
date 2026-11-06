# Instrukcja instalacji – San Andreas RPG

## Wymagania
- Windows 10 / 11 (lub Linux)
- MTA:SA Server 1.6.x (pobierz z https://multitheftauto.com)
- MySQL 5.7+ lub MariaDB 10.3+
- Node.js nie wymagany

---

## Krok 1: Baza danych

### Utwórz bazę i użytkownika MySQL:
```sql
CREATE DATABASE sarpg CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'sarpg_user'@'localhost' IDENTIFIED BY 'TWOJE_HASLO';
GRANT ALL PRIVILEGES ON sarpg.* TO 'sarpg_user'@'localhost';
FLUSH PRIVILEGES;
```

### Zaimportuj schemat:
```bash
mysql -u sarpg_user -p sarpg < database.sql
```
lub przez phpMyAdmin: Import → wybierz `database.sql`.

---

## Krok 2: Konfiguracja serwera MTA:SA

1. Zainstaluj MTA:SA Server do katalogu, np. `C:\SA-RPG\server\`
2. Skopiuj folder `server\mods\deathmatch\resources\[sa-rpg]\*` do:
   ```
   C:\SA-RPG\server\mods\deathmatch\resources\
   ```
   Tak by powstało:
   ```
   resources\[core]\rp_bootstrap\
   resources\[core]\rp_core\
   resources\[systems]\rp_economy\
   ... itd.
   ```
3. Zastąp plik `mtaserver.conf` dostarczonym plikiem i edytuj:
   ```xml
   <dbhost>127.0.0.1</dbhost>
   <dbport>3306</dbport>
   <dbname>sarpg</dbname>
   <dbuser>sarpg_user</dbuser>
   <dbpass>TWOJE_HASLO</dbpass>
   ```
4. Zastąp `acl.xml` dostarczonym plikiem.

---

## Krok 3: Pierwsze uruchomienie

```
C:\SA-RPG\server\MTA Server.exe
```

Konsola serwera powinna wyświetlić:
```
[BOOTSTRAP] === SAN ANDREAS RPG – SEKWENCER STARTOWY ===
[BOOTSTRAP] START OK: rp_core
[BOOTSTRAP] START OK: rp_database
[BOOTSTRAP] Połączono z MySQL: 127.0.0.1/sarpg
...
[BOOTSTRAP] Wszystkie zasoby uruchomione. Serwer gotowy!
```

---

## Krok 4: Tworzenie konta SuperAdmin

W konsoli serwera MTA wpisz:
```
addaccount AdminLogin AdminHaslo
set object user.AdminLogin SuperAdmin
```

Następnie zaloguj się w grze używając tego loginu jako konta gry **i** hasła RPG (możesz użyć tych samych danych).

---

## Krok 5: Połączenie z grą

1. Uruchom klienta MTA:SA
2. Direct Connect: `127.0.0.1:22003`
3. Po połączeniu pojawi się panel logowania RPG
4. Zarejestruj konto → utwórz postać → graj

---

## Komendy dostępne od razu

| Komenda | Opis |
|---|---|
| `/duty` | Włącz/wyłącz służbę frakcji |
| `/fc <wiadomość>` | Frakcyjny czat |
| `/wyjdz` | Wyjdź z wnętrza budynku |
| `F` | Uruchom/wyłącz silnik pojazdu |
| `H` | Zamknij/otwórz pojazd |
| `Y` | Zapiąj/odpiaj pas bezpieczeństwa |
| `L` | Włącz/wyłącz światła |

### Komendy admina (po nadaniu uprawnień):
| Komenda | Opis |
|---|---|
| `/adminpanel` | Panel administracyjny (F10) |
| `/kick <nick> [powód]` | Wyrzucenie gracza |
| `/ban <nick> <powód>` | Zbanowanie gracza |
| `/setcash <nick> <kwota>` | Ustaw gotówkę |
| `/setbank <nick> <kwota>` | Ustaw konto bankowe |
| `/setlevel <nick> <lvl>` | Ustaw poziom |
| `/tp <nick>` | Teleport do gracza |
| `/tphere <nick>` | Teleport gracza do siebie |
| `/repair` | Napraw swój pojazd |
| `/freeze <nick>` / `/unfreeze <nick>` | Zamroź / odmroź |
| `/spawnveh <model>` | Stwórz pojazd |
| `/giveveh <nick> <model>` | Daj pojazd graczowi |
| `/announce <tekst>` | Ogłoszenie serwerowe |
| `/noclip` | Tryb no-clip (admin) |

---

## Możliwe błędy

| Błąd | Rozwiązanie |
|---|---|
| `BLAD: Nie udalo sie polaczyc z baza danych` | Sprawdź dane w mtaserver.conf i czy MySQL działa |
| `Zasob 'rp_X' nie istnieje` | Sprawdź czy folder zasobu jest w `resources/` |
| Panel logowania się nie pojawia | Sprawdź czy `rp_accounts` uruchomił się bez błędów |
| Pojazdy znikają po restarcie | Sprawdź tabele `vehicles` w bazie |
| `passwordHash` nie działa | Wymaga MTA 1.5.7+ |

---

## Struktura plików

```
sa-rpg/
├── database.sql                        ← schemat bazy danych
├── INSTALL.md                          ← ta instrukcja
├── PROJECT_STATUS.md                   ← postęp projektu
└── server/
    └── mods/
        └── deathmatch/
            ├── mtaserver.conf
            ├── acl.xml
            └── resources/
                ├── [core]/
                │   ├── rp_bootstrap/
                │   ├── rp_core/
                │   ├── rp_database/
                │   ├── rp_logs/
                │   ├── rp_accounts/
                │   ├── rp_characters/
                │   └── rp_permissions/
                ├── [systems]/
                │   ├── rp_economy/
                │   ├── rp_bank/
                │   ├── rp_vehicles/
                │   ├── rp_dealership/
                │   ├── rp_garages/
                │   ├── rp_tuning/
                │   ├── rp_speedometer/
                │   ├── rp_jobs/
                │   └── rp_houses/
                ├── [factions]/
                │   └── rp_factions/
                ├── [interface]/
                │   ├── rp_notifications/
                │   └── rp_hud/
                └── [admin]/
                    └── rp_admin/
```
