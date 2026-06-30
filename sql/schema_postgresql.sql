-- ============================================================
-- REMORSE — Star Schema DDL (PostgreSQL / Supabase)
-- Reptilian Evaluation of Mesozoic Origins:
-- Retrospective Study on Extinction
--
-- Database: PostgreSQL (Supabase)
-- Fonte dati: Paleobiology Database (PBDB)
-- ============================================================

DROP TABLE IF EXISTS FACT_occurrence CASCADE;
DROP TABLE IF EXISTS DIM_taxon CASCADE;
DROP TABLE IF EXISTS DIM_location CASCADE;
DROP TABLE IF EXISTS DIM_time CASCADE;
DROP TABLE IF EXISTS DIM_collection CASCADE;

DROP TYPE IF EXISTS dataset_type_enum;
DROP TYPE IF EXISTS period_group_enum;

-- ------------------------------------------------------------
-- Tipi enumerati
-- ------------------------------------------------------------
CREATE TYPE dataset_type_enum AS ENUM ('Dinosauria', 'Plantae');
CREATE TYPE period_group_enum AS ENUM ('Triassic', 'Jurassic', 'Cretaceous');

-- ------------------------------------------------------------
-- DIM_taxon
-- Classificazione tassonomica dell'organismo fossile
-- ------------------------------------------------------------
CREATE TABLE DIM_taxon (
    taxon_key     SERIAL PRIMARY KEY,
    accepted_name VARCHAR(255) NOT NULL,
    accepted_rank VARCHAR(50)  NOT NULL,
    phylum        VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    class         VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    "order"       VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    family        VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    genus         VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    dataset_type  dataset_type_enum NOT NULL
);

-- ------------------------------------------------------------
-- DIM_location
-- Posizione geografica del ritrovamento fossile
-- ------------------------------------------------------------
CREATE TABLE DIM_location (
    location_key     SERIAL PRIMARY KEY,
    lat               NUMERIC(9,6),
    lng               NUMERIC(9,6),
    cc                VARCHAR(10),
    state             VARCHAR(150) NOT NULL DEFAULT 'Unknown',
    has_valid_coords  BOOLEAN      NOT NULL DEFAULT FALSE
);

-- ------------------------------------------------------------
-- DIM_time
-- Intervallo geologico dell'occorrenza fossile
-- ------------------------------------------------------------
CREATE TABLE DIM_time (
    time_key        SERIAL PRIMARY KEY,
    early_interval  VARCHAR(100) NOT NULL,
    late_interval   VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    period_group    period_group_enum NOT NULL
);

-- ------------------------------------------------------------
-- DIM_collection
-- Sito di scavo e formazione geologica
-- ------------------------------------------------------------
CREATE TABLE DIM_collection (
    collection_no     INT PRIMARY KEY,
    formation         VARCHAR(150) NOT NULL DEFAULT 'Unknown',
    geological_group  VARCHAR(150) NOT NULL DEFAULT 'Unknown'
);

-- ------------------------------------------------------------
-- FACT_occurrence
-- Tabella dei fatti — una riga per occorrenza fossile
-- Unifica Dinosauria e Plantae tramite dataset_type
-- ------------------------------------------------------------
CREATE TABLE FACT_occurrence (
    occurrence_no  INT PRIMARY KEY,
    collection_no  INT NOT NULL REFERENCES DIM_collection(collection_no),
    taxon_key      INT NOT NULL REFERENCES DIM_taxon(taxon_key),
    location_key   INT NOT NULL REFERENCES DIM_location(location_key),
    time_key       INT NOT NULL REFERENCES DIM_time(time_key),
    dataset_type   dataset_type_enum NOT NULL,
    max_ma         NUMERIC(7,2) NOT NULL,
    min_ma         NUMERIC(7,2) NOT NULL,
    mid_ma         NUMERIC(7,2) NOT NULL
);

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
