-- ============================================================
--  SAN ANDREAS RPG  –  DATABASE SCHEMA
--  Engine: MySQL 5.7+ / MariaDB 10.3+
--  Charset: utf8mb4
--  Collation: utf8mb4_unicode_ci
-- ============================================================

SET NAMES utf8mb4;
SET foreign_key_checks = 0;

-- ============================================================
--  ACCOUNTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `accounts` (
  `id`            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `username`      VARCHAR(50)      NOT NULL,
  `password`      VARCHAR(256)     NOT NULL,  -- bcrypt/sha512 hash
  `email`         VARCHAR(120)     NOT NULL DEFAULT '',
  `serial`        VARCHAR(64)      NOT NULL DEFAULT '',
  `last_ip`       VARCHAR(45)      NOT NULL DEFAULT '',
  `last_login`    DATETIME                  DEFAULT NULL,
  `created_at`    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `banned`        TINYINT(1)       NOT NULL DEFAULT 0,
  `ban_reason`    VARCHAR(255)              DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_username` (`username`),
  KEY `idx_serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  CHARACTERS
-- ============================================================
CREATE TABLE IF NOT EXISTS `characters` (
  `id`              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `account_id`      INT UNSIGNED   NOT NULL,
  `name`            VARCHAR(60)    NOT NULL,
  `skin_id`         SMALLINT       NOT NULL DEFAULT 0,
  `sex`             TINYINT(1)     NOT NULL DEFAULT 0,  -- 0 male, 1 female
  `spawn_x`         FLOAT          NOT NULL DEFAULT 2171.3,
  `spawn_y`         FLOAT          NOT NULL DEFAULT 933.0,
  `spawn_z`         FLOAT          NOT NULL DEFAULT 11.1,
  `spawn_rot`       FLOAT          NOT NULL DEFAULT 90.0,
  `interior`        TINYINT        NOT NULL DEFAULT 0,
  `dimension`       SMALLINT       NOT NULL DEFAULT 0,
  `hp`              FLOAT          NOT NULL DEFAULT 100.0,
  `armour`          FLOAT          NOT NULL DEFAULT 0.0,
  `hunger`          FLOAT          NOT NULL DEFAULT 100.0,
  `thirst`          FLOAT          NOT NULL DEFAULT 100.0,
  `cash`            INT            NOT NULL DEFAULT 1500,
  `bank`            INT            NOT NULL DEFAULT 0,
  `level`           SMALLINT       NOT NULL DEFAULT 1,
  `xp`              INT UNSIGNED   NOT NULL DEFAULT 0,
  `total_minutes`   INT UNSIGNED   NOT NULL DEFAULT 0,
  `job_id`          TINYINT        NOT NULL DEFAULT 0,
  `job_level`       TINYINT        NOT NULL DEFAULT 0,
  `job_xp`          INT UNSIGNED   NOT NULL DEFAULT 0,
  `speedometer_id`  SMALLINT       NOT NULL DEFAULT 0,  -- 0 = brak
  `speedometer_color` TINYINT      NOT NULL DEFAULT 1,
  `licence_car`     TINYINT(1)     NOT NULL DEFAULT 0,
  `licence_truck`   TINYINT(1)     NOT NULL DEFAULT 0,
  `licence_bike`    TINYINT(1)     NOT NULL DEFAULT 0,
  `created_at`      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_char_account` (`account_id`),
  CONSTRAINT `fk_char_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  TRANSACTIONS  (historia transakcji)
-- ============================================================
CREATE TABLE IF NOT EXISTS `transactions` (
  `id`            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `char_id`       INT UNSIGNED     NOT NULL,
  `type`          VARCHAR(40)      NOT NULL,  -- 'job_pay','buy_vehicle','transfer_out','atm_withdraw'...
  `amount`        INT              NOT NULL,  -- ujemna = wydatek
  `balance_after` INT              NOT NULL,
  `description`   VARCHAR(255)     NOT NULL DEFAULT '',
  `created_at`    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_trans_char` (`char_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  VEHICLES (baza pojazdów serwera)
-- ============================================================
CREATE TABLE IF NOT EXISTS `vehicles` (
  `id`            INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `owner_id`      INT UNSIGNED            DEFAULT NULL,  -- NULL = publiczny
  `model`         SMALLINT       NOT NULL,
  `plate`         VARCHAR(10)    NOT NULL DEFAULT '',
  `color1`        SMALLINT       NOT NULL DEFAULT 0,
  `color2`        SMALLINT       NOT NULL DEFAULT 0,
  `pos_x`         FLOAT          NOT NULL DEFAULT 0,
  `pos_y`         FLOAT          NOT NULL DEFAULT 0,
  `pos_z`         FLOAT          NOT NULL DEFAULT 0,
  `rot`           FLOAT          NOT NULL DEFAULT 0,
  `interior`      TINYINT        NOT NULL DEFAULT 0,
  `dimension`     SMALLINT       NOT NULL DEFAULT 0,
  `garage_id`     INT                     DEFAULT NULL,
  `in_garage`     TINYINT(1)     NOT NULL DEFAULT 0,
  `fuel`          FLOAT          NOT NULL DEFAULT 100.0,
  `mileage`       INT UNSIGNED   NOT NULL DEFAULT 0,
  `health`        FLOAT          NOT NULL DEFAULT 1000.0,
  `engine_on`     TINYINT(1)     NOT NULL DEFAULT 0,
  `locked`        TINYINT(1)     NOT NULL DEFAULT 1,
  `lights`        TINYINT(1)     NOT NULL DEFAULT 0,
  `nitro_installed` TINYINT(1)   NOT NULL DEFAULT 0,
  `price`         INT            NOT NULL DEFAULT 0,  -- cena zakupu
  `for_sale`      TINYINT(1)     NOT NULL DEFAULT 0,
  `sale_price`    INT            NOT NULL DEFAULT 0,
  `created_at`    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_plate` (`plate`),
  KEY `fk_veh_owner` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  VEHICLE_UPGRADES  (tuning)
-- ============================================================
CREATE TABLE IF NOT EXISTS `vehicle_upgrades` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `vehicle_id`  INT UNSIGNED   NOT NULL,
  `upgrade_id`  SMALLINT       NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_upg_veh` (`vehicle_id`),
  CONSTRAINT `fk_upg_veh` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  GARAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS `garages` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `owner_id`    INT UNSIGNED            DEFAULT NULL,
  `name`        VARCHAR(80)    NOT NULL DEFAULT '',
  `pos_x`       FLOAT          NOT NULL,
  `pos_y`       FLOAT          NOT NULL,
  `pos_z`       FLOAT          NOT NULL,
  `int_x`       FLOAT          NOT NULL,
  `int_y`       FLOAT          NOT NULL,
  `int_z`       FLOAT          NOT NULL,
  `interior`    TINYINT        NOT NULL DEFAULT 0,
  `price`       INT            NOT NULL DEFAULT 0,
  `for_sale`    TINYINT(1)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  HOUSES (nieruchomości)
-- ============================================================
CREATE TABLE IF NOT EXISTS `houses` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `owner_id`    INT UNSIGNED            DEFAULT NULL,
  `name`        VARCHAR(80)    NOT NULL DEFAULT 'Dom',
  `pos_x`       FLOAT          NOT NULL,
  `pos_y`       FLOAT          NOT NULL,
  `pos_z`       FLOAT          NOT NULL,
  `int_x`       FLOAT          NOT NULL DEFAULT 2233.35,
  `int_y`       FLOAT          NOT NULL DEFAULT -1114.1,
  `int_z`       FLOAT          NOT NULL DEFAULT 1050.9,
  `interior`    TINYINT        NOT NULL DEFAULT 5,
  `price`       INT            NOT NULL DEFAULT 50000,
  `for_sale`    TINYINT(1)     NOT NULL DEFAULT 1,
  `rent_price`  INT            NOT NULL DEFAULT 500,
  `locked`      TINYINT(1)     NOT NULL DEFAULT 1,
  `storage_max` INT            NOT NULL DEFAULT 50,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  HOUSE_STORAGE
-- ============================================================
CREATE TABLE IF NOT EXISTS `house_storage` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `house_id`    INT UNSIGNED    NOT NULL,
  `item_id`     INT UNSIGNED    NOT NULL,
  `amount`      INT             NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `fk_hs_house` (`house_id`),
  CONSTRAINT `fk_hs_house` FOREIGN KEY (`house_id`) REFERENCES `houses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  INVENTORY (ekwipunek postaci)
-- ============================================================
CREATE TABLE IF NOT EXISTS `inventory` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `char_id`     INT UNSIGNED    NOT NULL,
  `item_id`     INT UNSIGNED    NOT NULL,
  `amount`      INT             NOT NULL DEFAULT 1,
  `data`        VARCHAR(255)            DEFAULT NULL,  -- JSON lub dodatkowe info
  PRIMARY KEY (`id`),
  KEY `fk_inv_char` (`char_id`),
  CONSTRAINT `fk_inv_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  ITEMS (katalog przedmiotów)
-- ============================================================
CREATE TABLE IF NOT EXISTS `items` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(80)    NOT NULL,
  `description` VARCHAR(255)   NOT NULL DEFAULT '',
  `type`        VARCHAR(40)    NOT NULL DEFAULT 'misc',  -- food,drink,weapon,tool,key,misc
  `weight`      FLOAT          NOT NULL DEFAULT 0.1,
  `buy_price`   INT            NOT NULL DEFAULT 0,
  `sell_price`  INT            NOT NULL DEFAULT 0,
  `stackable`   TINYINT(1)     NOT NULL DEFAULT 1,
  `max_stack`   INT            NOT NULL DEFAULT 99,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  FRACTIONS (frakcje)
-- ============================================================
CREATE TABLE IF NOT EXISTS `fractions` (
  `id`          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)      NOT NULL,
  `type`        VARCHAR(30)      NOT NULL DEFAULT 'civilian',  -- police,ems,mechanic,civilian
  `color`       VARCHAR(7)       NOT NULL DEFAULT '#FFFFFF',
  `blip_model`  SMALLINT         NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  FRACTION_RANKS
-- ============================================================
CREATE TABLE IF NOT EXISTS `fraction_ranks` (
  `id`            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fraction_id`   TINYINT UNSIGNED NOT NULL,
  `rank`          TINYINT          NOT NULL DEFAULT 1,
  `name`          VARCHAR(60)      NOT NULL,
  `salary`        INT              NOT NULL DEFAULT 1000,
  PRIMARY KEY (`id`),
  KEY `fk_rank_frac` (`fraction_id`),
  CONSTRAINT `fk_rank_frac` FOREIGN KEY (`fraction_id`) REFERENCES `fractions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  FRACTION_MEMBERS
-- ============================================================
CREATE TABLE IF NOT EXISTS `fraction_members` (
  `id`            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `char_id`       INT UNSIGNED     NOT NULL,
  `fraction_id`   TINYINT UNSIGNED NOT NULL,
  `rank_id`       TINYINT UNSIGNED NOT NULL,
  `on_duty`       TINYINT(1)       NOT NULL DEFAULT 0,
  `joined_at`     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_char_frac` (`char_id`),
  KEY `fk_mem_frac` (`fraction_id`),
  CONSTRAINT `fk_mem_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mem_frac` FOREIGN KEY (`fraction_id`) REFERENCES `fractions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  ORGANIZATIONS (organizacje graczy)
-- ============================================================
CREATE TABLE IF NOT EXISTS `organizations` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)    NOT NULL,
  `tag`         VARCHAR(8)     NOT NULL DEFAULT '',
  `owner_id`    INT UNSIGNED   NOT NULL,
  `bank`        INT            NOT NULL DEFAULT 0,
  `color`       VARCHAR(7)     NOT NULL DEFAULT '#FFAA00',
  `created_at`  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_org_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  ORG_MEMBERS
-- ============================================================
CREATE TABLE IF NOT EXISTS `org_members` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `org_id`      INT UNSIGNED   NOT NULL,
  `char_id`     INT UNSIGNED   NOT NULL,
  `rank`        TINYINT        NOT NULL DEFAULT 1,
  `joined_at`   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orgmem_char` (`char_id`),
  CONSTRAINT `fk_orgmem_org`  FOREIGN KEY (`org_id`)  REFERENCES `organizations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_orgmem_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  JOBS_LOG (historia pracy)
-- ============================================================
CREATE TABLE IF NOT EXISTS `jobs_log` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `char_id`     INT UNSIGNED    NOT NULL,
  `job_id`      TINYINT         NOT NULL,
  `mission_id`  SMALLINT        NOT NULL DEFAULT 0,
  `reward`      INT             NOT NULL DEFAULT 0,
  `xp_gained`   INT             NOT NULL DEFAULT 0,
  `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_jlog_char` (`char_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  ADMIN_LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_name`  VARCHAR(60)     NOT NULL,
  `target_name` VARCHAR(60)             DEFAULT NULL,
  `action`      VARCHAR(100)    NOT NULL,
  `details`     VARCHAR(500)    NOT NULL DEFAULT '',
  `created_at`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  AUCTION_LISTINGS (giełda pojazdów/przedmiotów)
-- ============================================================
CREATE TABLE IF NOT EXISTS `auction_listings` (
  `id`            INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `seller_id`     INT UNSIGNED   NOT NULL,
  `type`          VARCHAR(20)    NOT NULL DEFAULT 'vehicle',  -- vehicle, item
  `ref_id`        INT UNSIGNED   NOT NULL,  -- vehicle_id lub item_id
  `start_price`   INT            NOT NULL,
  `current_price` INT            NOT NULL,
  `buyout_price`  INT                     DEFAULT NULL,
  `top_bidder`    INT UNSIGNED            DEFAULT NULL,
  `ends_at`       DATETIME       NOT NULL,
  `closed`        TINYINT(1)     NOT NULL DEFAULT 0,
  `created_at`    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_auction_open` (`closed`, `ends_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  SPEEDOMETER_SHOP (dostępne wersje prędkościomierzy)
-- ============================================================
CREATE TABLE IF NOT EXISTS `speedometer_shop` (
  `id`          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)      NOT NULL,
  `price`       INT              NOT NULL DEFAULT 500,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  CHAR_SPEEDOMETERS (zakupione prędkościomierze gracza)
-- ============================================================
CREATE TABLE IF NOT EXISTS `char_speedometers` (
  `id`          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `char_id`     INT UNSIGNED     NOT NULL,
  `speedo_id`   TINYINT UNSIGNED NOT NULL,
  `color_id`    TINYINT          NOT NULL DEFAULT 1,
  `purchased_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cs` (`char_id`, `speedo_id`),
  CONSTRAINT `fk_cs_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  ACHIEVEMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `achievements` (
  `id`          INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `char_id`     INT UNSIGNED     NOT NULL,
  `achiev_id`   SMALLINT         NOT NULL,
  `progress`    INT              NOT NULL DEFAULT 0,
  `completed`   TINYINT(1)       NOT NULL DEFAULT 0,
  `completed_at` DATETIME                 DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ach` (`char_id`, `achiev_id`),
  CONSTRAINT `fk_ach_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  PHONE_CONTACTS
-- ============================================================
CREATE TABLE IF NOT EXISTS `phone_contacts` (
  `id`          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `char_id`     INT UNSIGNED  NOT NULL,
  `target_id`   INT UNSIGNED  NOT NULL,
  `alias`       VARCHAR(50)   NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `fk_ph_char` (`char_id`),
  CONSTRAINT `fk_ph_char` FOREIGN KEY (`char_id`) REFERENCES `characters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  PHONE_MESSAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `from_id`     INT UNSIGNED    NOT NULL,
  `to_id`       INT UNSIGNED    NOT NULL,
  `message`     VARCHAR(500)    NOT NULL,
  `read_flag`   TINYINT(1)      NOT NULL DEFAULT 0,
  `sent_at`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_msg_to` (`to_id`, `read_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  INITIAL DATA – frakcje
-- ============================================================
INSERT IGNORE INTO `fractions` (`id`,`name`,`type`,`color`,`blip_model`) VALUES
(1,'Policja','police','#0055FF',60),
(2,'Pogotowie Ratunkowe','ems','#FF3333',56),
(3,'Warsztat Mechanika','mechanic','#FF8800',446),
(4,'Administracja','admin','#FFCC00',62);

INSERT IGNORE INTO `fraction_ranks` (`fraction_id`,`rank`,`name`,`salary`) VALUES
(1,1,'Rekrut',2500),(1,2,'Posterunkowy',3500),(1,3,'Starszy Posterunkowy',4500),
(1,4,'Kapral',5500),(1,5,'Sierżant',6500),(1,6,'Starszy Sierżant',7500),
(1,7,'Aspirant',8500),(1,8,'Komisarz',10000),(1,9,'Inspektor',12000),(1,10,'Komendant',15000),
(2,1,'Sanitariusz',2500),(2,2,'Ratownik',3500),(2,3,'Technik Medyczny',4500),
(2,4,'Pielęgniarka',5500),(2,5,'Lekarz',6500),(2,6,'Specjalista',7500),
(2,7,'Starszy Lekarz',8500),(2,8,'Ordynator',10000),(2,9,'Dyrektor Medyczny',12000),
(3,1,'Uczeń',2000),(3,2,'Pomocnik',2800),(3,3,'Mechanik',3800),
(3,4,'Starszy Mechanik',5000),(3,5,'Mistrz',7000),
(4,1,'Moderator',0),(4,2,'Administrator',0),(4,3,'Superadmin',0);

-- ============================================================
--  INITIAL DATA – sklep prędkościomierzy
-- ============================================================
INSERT IGNORE INTO `speedometer_shop` (`id`,`name`,`price`) VALUES
(1,'Classic SF', 500),
(2,'Night Edition', 1200),
(3,'Sport Carbon', 2500),
(4,'Premium Gold', 5000);

-- ============================================================
--  INITIAL DATA – przedmioty
-- ============================================================
INSERT IGNORE INTO `items` (`id`,`name`,`description`,`type`,`weight`,`buy_price`,`sell_price`,`stackable`,`max_stack`) VALUES
(1,'Hamburgier','Przywraca 25 punktów głodu','food',0.3,50,15,1,10),
(2,'Pizza','Przywraca 60 punktów głodu','food',0.5,120,40,1,5),
(3,'Woda','Przywraca 30 punktów pragnienia','drink',0.2,20,5,1,10),
(4,'Sok pomarańczowy','Przywraca 50 punktów pragnienia','drink',0.3,40,12,1,10),
(5,'Apteczka','Przywraca 50 HP','tool',0.8,200,60,1,3),
(6,'Kamizelka','Przywraca 100 Armour','tool',2.0,500,150,0,1),
(7,'Kanistr paliwa (5L)','Paliwo do pojazdu','tool',1.0,80,25,1,5),
(8,'Kanistr paliwa (20L)','Duży kanistr paliwa','tool',4.0,300,90,1,2),
(9,'Lina holownicza','Potrzebna do holowania','tool',1.5,150,45,0,1),
(10,'Mapa San Andreas','Mapa całego San Andreas','misc',0.1,300,80,0,1),
(11,'Telefon Podstawowy','Pozwala dzwonić i pisać SMS','misc',0.2,500,150,0,1),
(12,'Telefon Premium','Zaawansowany smartfon','misc',0.2,2000,600,0,1),
(13,'Zestaw narzędzi','Narzędzia mechanika','tool',3.0,800,240,0,1),
(14,'Defibrylator','Używany przez ratowników','tool',1.0,0,0,0,1),
(15,'Szybowiec','Sprzęt nurka','tool',2.0,600,180,0,1),
(16,'Kosa','Narzędzie kosiarza','tool',1.5,200,60,0,1),
(17,'Śmieciarka – klucze','Klucze do śmieciarki w zajezdni','key',0.1,0,0,0,1),
(18,'Bilet autobusowy (dzienny)','Darmowa przejazd przez 24h','misc',0.0,30,0,0,1),
(19,'Premia ekspresowa','Podwaja zarobek z pracy x1 godzinę','misc',0.0,1000,0,0,3);

-- ============================================================
--  INITIAL DATA – domy (przykładowe, San Fierro)
-- ============================================================
INSERT IGNORE INTO `houses` (`id`,`name`,`pos_x`,`pos_y`,`pos_z`,`int_x`,`int_y`,`int_z`,`interior`,`price`,`for_sale`,`rent_price`) VALUES
(1,'Kawalerka SF #1', -2696.78, 456.91, 14.52, 226.45, 1239.14, 1082.14, 10, 30000, 1, 300),
(2,'Kawalerka SF #2', -2698.50, 462.00, 14.52, 226.45, 1239.14, 1082.14, 10, 32000, 1, 320),
(3,'Dom Szeregowy SF',  -2483.11, 130.00, 26.60, 226.45, 1239.14, 1082.14, 10, 75000, 1, 700),
(4,'Willa SF',         -2481.00, 135.00, 26.60, 265.32, 1310.26, 1083.36, 11, 200000,1, 1800),
(5,'Penthouse SF',     -2050.00, 680.00, 35.00, 265.32, 1310.26, 1083.36, 11, 500000,1, 4500),
(6,'Kawalerka LS #1',  1248.87, -785.01, 11.09, 226.45, 1239.14, 1082.14, 10, 25000, 1, 250),
(7,'Dom LS',           1251.00, -780.00, 11.09, 226.45, 1239.14, 1082.14, 10, 60000, 1, 580),
(8,'Kawalerka LV #1',  2237.73, 2474.72, 10.82, 226.45, 1239.14, 1082.14, 10, 22000, 1, 220),
(9,'Dom LV',           2240.00, 2470.00, 10.82, 226.45, 1239.14, 1082.14, 10, 55000, 1, 530);

-- ============================================================
--  INITIAL DATA – garaże
-- ============================================================
INSERT IGNORE INTO `garages` (`id`,`name`,`pos_x`,`pos_y`,`pos_z`,`int_x`,`int_y`,`int_z`,`interior`,`price`,`for_sale`) VALUES
(1,'Garaż SF Centrum',    -1934.17, 272.50, 35.29, 299.45, -50.75, 1002.0, 0, 40000, 1),
(2,'Garaż SF Dzielnica',  -1916.00, 280.00, 35.00, 299.45, -50.75, 1002.0, 0, 45000, 1),
(3,'Garaż LS Płd.',        686.41,-475.70, 16.43, 299.45, -50.75, 1002.0, 0, 35000, 1),
(4,'Garaż LV Centrum',   2253.37,2452.50, 10.82, 299.45, -50.75, 1002.0, 0, 32000, 1);

SET foreign_key_checks = 1;
