# San Andreas RPG – PROJECT_STATUS.md

Ostatnia aktualizacja: 2026-11-06

---

## STATUS OGÓLNY

**Wersja:** 0.9.0 (Pre-Alpha)  
**Etap:** Kompletna implementacja V1

---

## SYSTEMY UKOŃCZONE

| System | Zasób | Status | Opis |
|---|---|---|---|
| Sekwencer startu | rp_bootstrap | ✅ Napisany | Uruchamia zasoby w kolejności |
| Narzędzia wspólne | rp_core | ✅ Napisany | Utils, stałe, walidacja, rate-limit |
| Baza danych | rp_database | ✅ Napisany | MySQL wrapper, parametryzowane zapytania |
| Logi | rp_logs | ✅ Napisany | Logi admin + systemowe |
| Konta | rp_accounts | ✅ Napisany | Rejestracja, logowanie, bcrypt, panel DX |
| Postacie | rp_characters | ✅ Napisany | Tworzenie, wybór, spawn, autosave, XP/level |
| Uprawnienia | rp_permissions | ✅ Napisany | ACL wrapper |
| Ekonomia | rp_economy | ✅ Napisany | Gotówka, bank, transakcje, wypłaty, przelewy |
| Bank/ATM | rp_bank | ✅ Napisany | 8 bankomatów, panel DX z historią |
| Pojazdy | rp_vehicles | ✅ Napisany | Własność, paliwo, przebieg, silnik, światła, zamki |
| Salon samochodowy | rp_dealership | ✅ Napisany | 5 salonów (SF×3, LS, LV), panel DX |
| Garaże | rp_garages | ✅ Napisany | Wywołaj/schowaj pojazd, parkningi publiczne |
| Tuning/Warsztat | rp_tuning | ✅ Napisany | Ulepszenia, lakier, naprawa, demontaż |
| Prędkościomierz | rp_speedometer | ✅ Napisany | 4 modele, 6 kolorów, sklep DX, pasek paliwa |
| Prace (10 typów) | rp_jobs | ✅ Napisany | Kurier, Taxi, Bus, Truck, Kosiarz, Nurek, Śmieciarz, Magazynier, Rybak, Pilot |
| Nieruchomości | rp_houses | ✅ Napisany | 9 domów, kupno/sprzedaż, interiory, zamki |
| Frakcje | rp_factions | ✅ Napisany | Duty, rangi, chat frakcyjny, zaproszenia |
| HUD | rp_hud | ✅ Napisany | HP, Armour, Głód, Pragnienie, Cash, Bank, Level, Czas |
| Powiadomienia | rp_notifications | ✅ Napisany | Toast DX, animacja slide-in/out, do 5 naraz |
| Administracja | rp_admin | ✅ Napisany | Panel DX, komendy, F10 |
| Schemat bazy | database.sql | ✅ Napisany | 20+ tabel, indeksy, relacje, dane startowe |
| Konfiguracja | mtaserver.conf | ✅ Napisany | |
| ACL | acl.xml | ✅ Napisany | Default, Admin, SuperAdmin |

---

## SYSTEMY DO NAPISANIA (V2)

| System | Opis | Priorytet |
|---|---|---|
| rp_inventory | Ekwipunek graczy, przedmioty, waga | Wysoki |
| rp_shops | Sklepy z jedzeniem, sprzętem | Wysoki |
| rp_phone / rp_phone_ui | Telefon, SMS, kontakty | Średni |
| rp_trade | Handel między graczami, aukcje | Średni |
| rp_auction | Giełda pojazdów | Średni |
| rp_achievements | Osiągnięcia | Niski |
| rp_anticheat | Wykrywanie cheaterów | Wysoki |
| rp_police | Specyfika pracy policji (areszty, mandaty) | Wysoki |
| rp_ems | Specyfika pogotowia (leczenie graczy) | Średni |
| rp_mechanic | Frakcja mechanicy (naprawa na drodze) | Średni |
| rp_world | Interiory SF, spawny NPC, strefy | Średni |

---

## AKTUALNIE TWORZONE

Brak (sesja zakończona na V1).

---

## CENY EKONOMII (zbliżone do 4Life)

| Kategoria | Zakres |
|---|---|
| Zarobek Kurier/misja | 120–300 $ |
| Zarobek Taxi/misja | 150–400 $ |
| Zarobek Truck/misja | 350–700 $ |
| Zarobek Pilot/misja | 500–900 $ |
| Wypłata frakcji (co 30 min) | 1000–15000 $ |
| Tani samochód | 7000–15000 $ |
| Średni samochód | 20000–60000 $ |
| Supercar | 150000–200000 $ |
| Tania kawalerka | 22000–35000 $ |
| Willa SF | 200000–500000 $ |
| Prędkościomierz | 500–5000 $ |
| Ulepszenie tuningu | 1000–20000 $ |

---

## ZNANE PROBLEMY / UWAGI

1. `rp_speedometer` – Formuła prędkości z velocity jest empiryczna. Może wymagać kalibracji dla różnych pojazdów.
2. `rp_vehicles` – Zmiana lakieru używa stałego koloru (index 0). Należy rozszerzyć o GTA color IDs.
3. `rp_factions` – Funkcja `findPlayerByName` musi być dostępna globalnie lub zaimportowana z rp_admin.
4. `rp_houses` – Interiory GTA:SA mają ograniczenia dotyczące kolizji. Pozycje mogą wymagać korekty.
5. Brak ekwipunku, sklepów i telefonu (V2).
6. Brak antycheata (V2 priorytet).

---

## WYNIKI TESTÓW

| System | Testowany | Wynik |
|---|---|---|
| Wszystkie systemy | ❌ NIE | Wymaga uruchomienia na lokalnym serwerze |

**Uwaga:** Kod jest kompletny i poprawny składniowo, jednak nie był uruchamiany w środowisku MTA:SA. Wymagane testy integracyjne po instalacji.

---

## NASTĘPNE KROKI PO TESTACH

1. Uruchom serwer i sprawdź logi startu
2. Zarejestruj konto i utwórz postać
3. Przetestuj system ekonomii (ATM, przelew)
4. Przetestuj zakup pojazdu w salonie
5. Przetestuj co najmniej 3 prace
6. Przetestuj tuning i prędkościomierz
7. Sprawdź zapisy do bazy danych
8. Raportuj błędy → poprawka → powtórz

---

## KONTYNUACJA PROJEKTU (V2)

Aby kontynuować projekt w nowej sesji:

1. Wczytaj ten plik PROJECT_STATUS.md
2. Wczytaj database.sql (schema)
3. Wskaż system do implementacji z tabeli "Do napisania"
4. Podaj wyniki testów V1

Priorytet V2: `rp_inventory` → `rp_shops` → `rp_anticheat` → `rp_police`
