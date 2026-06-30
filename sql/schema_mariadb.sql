-- ============================================================
-- REMORSE — Star Schema DDL (MariaDB)
-- Reptilian Evaluation of Mesozoic Origins:
-- Retrospective Study on Extinction
--
-- Database: MariaDB (AWS RDS)
-- Fonte dati: Paleobiology Database (PBDB)
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS FACT_occurrence;
DROP TABLE IF EXISTS DIM_taxon;
DROP TABLE IF EXISTS DIM_location;
DROP TABLE IF EXISTS DIM_time;
DROP TABLE IF EXISTS DIM_collection;

SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------
-- DIM_taxon
-- Classificazione tassonomica dell'organismo fossile
-- ------------------------------------------------------------
CREATE TABLE DIM_taxon (
    taxon_key     INT AUTO_INCREMENT PRIMARY KEY,
    accepted_name VARCHAR(255) NOT NULL,
    accepted_rank VARCHAR(50)  NOT NULL,
    phylum        VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    class         VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    `order`       VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    family        VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    genus         VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    dataset_type  ENUM('Dinosauria', 'Plantae') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- DIM_location
-- Posizione geografica del ritrovamento fossile
-- ------------------------------------------------------------
CREATE TABLE DIM_location (
    location_key     INT AUTO_INCREMENT PRIMARY KEY,
    lat               DECIMAL(9,6),
    lng               DECIMAL(9,6),
    cc                VARCHAR(10),
    state             VARCHAR(150) NOT NULL DEFAULT 'Unknown',
    has_valid_coords  TINYINT(1)   NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- DIM_time
-- Intervallo geologico dell'occorrenza fossile
-- ------------------------------------------------------------
CREATE TABLE DIM_time (
    time_key        INT AUTO_INCREMENT PRIMARY KEY,
    early_interval  VARCHAR(100) NOT NULL,
    late_interval   VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    period_group    ENUM('Triassic', 'Jurassic', 'Cretaceous') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- DIM_collection
-- Sito di scavo e formazione geologica
-- ------------------------------------------------------------
CREATE TABLE DIM_collection (
    collection_no     INT PRIMARY KEY,
    formation         VARCHAR(150) NOT NULL DEFAULT 'Unknown',
    geological_group  VARCHAR(150) NOT NULL DEFAULT 'Unknown'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- FACT_occurrence
-- Tabella dei fatti — una riga per occorrenza fossile
-- Unifica Dinosauria e Plantae tramite dataset_type
-- ------------------------------------------------------------
CREATE TABLE FACT_occurrence (
    occurrence_no  INT PRIMARY KEY,
    collection_no  INT NOT NULL,
    taxon_key      INT NOT NULL,
    location_key   INT NOT NULL,
    time_key       INT NOT NULL,
    dataset_type   ENUM('Dinosauria', 'Plantae') NOT NULL,
    max_ma         DECIMAL(7,2) NOT NULL,
    min_ma         DECIMAL(7,2) NOT NULL,
    mid_ma         DECIMAL(7,2) NOT NULL,

    CONSTRAINT fk_fact_collection FOREIGN KEY (collection_no) REFERENCES DIM_collection(collection_no),
    CONSTRAINT fk_fact_taxon      FOREIGN KEY (taxon_key)     REFERENCES DIM_taxon(taxon_key),
    CONSTRAINT fk_fact_location   FOREIGN KEY (location_key)  REFERENCES DIM_location(location_key),
    CONSTRAINT fk_fact_time       FOREIGN KEY (time_key)      REFERENCES DIM_time(time_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- Indici per ottimizzare le query analitiche
-- ------------------------------------------------------------
CREATE INDEX idx_fact_dataset_type  ON FACT_occurrence(dataset_type);
CREATE INDEX idx_fact_collection    ON FACT_occurrence(collection_no);
CREATE INDEX idx_fact_taxon         ON FACT_occurrence(taxon_key);
CREATE INDEX idx_fact_location      ON FACT_occurrence(location_key);
CREATE INDEX idx_fact_time          ON FACT_occurrence(time_key);
CREATE INDEX idx_time_period_group  ON DIM_time(period_group);
CREATE INDEX idx_location_cc        ON DIM_location(cc);
CREATE INDEX idx_taxon_genus        ON DIM_taxon(genus);
CREATE INDEX idx_taxon_dataset      ON DIM_taxon(dataset_type);
