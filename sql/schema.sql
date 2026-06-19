-- ============================================================
-- REMORSE — Star Schema DDL
-- Reptilian Evaluation of Mesozoic Origins:
-- Retrospective Study on Extinction
--
-- Database: SQLite
-- Fonte dati: Paleobiology Database (PBDB)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- DIM_taxon
-- Classificazione tassonomica dell'organismo fossile
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DIM_taxon (
    taxon_key    INTEGER PRIMARY KEY AUTOINCREMENT,
    accepted_name TEXT    NOT NULL,
    accepted_rank TEXT    NOT NULL,
    phylum       TEXT    NOT NULL DEFAULT 'Unknown',
    class        TEXT    NOT NULL DEFAULT 'Unknown',
    "order"      TEXT    NOT NULL DEFAULT 'Unknown',
    family       TEXT    NOT NULL DEFAULT 'Unknown',
    genus        TEXT    NOT NULL DEFAULT 'Unknown',
    dataset_type TEXT    NOT NULL CHECK (dataset_type IN ('Dinosauria', 'Plantae'))
);

-- ------------------------------------------------------------
-- DIM_location
-- Posizione geografica del ritrovamento fossile
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DIM_location (
    location_key     INTEGER PRIMARY KEY AUTOINCREMENT,
    lat              REAL,
    lng              REAL,
    cc               TEXT,
    state            TEXT    NOT NULL DEFAULT 'Unknown',
    has_valid_coords INTEGER NOT NULL DEFAULT 0 CHECK (has_valid_coords IN (0, 1))
);

-- ------------------------------------------------------------
-- DIM_time
-- Intervallo geologico dell'occorrenza fossile
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DIM_time (
    time_key       INTEGER PRIMARY KEY AUTOINCREMENT,
    early_interval TEXT    NOT NULL,
    late_interval  TEXT    NOT NULL DEFAULT 'Unknown',
    period_group   TEXT    NOT NULL CHECK (period_group IN ('Triassic', 'Jurassic', 'Cretaceous'))
);

-- ------------------------------------------------------------
-- DIM_collection
-- Sito di scavo e formazione geologica
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DIM_collection (
    collection_no    INTEGER PRIMARY KEY,
    formation        TEXT    NOT NULL DEFAULT 'Unknown',
    geological_group TEXT    NOT NULL DEFAULT 'Unknown'
);

-- ------------------------------------------------------------
-- FACT_occurrence
-- Tabella dei fatti — una riga per occorrenza fossile
-- Unifica Dinosauria e Plantae tramite dataset_type
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS FACT_occurrence (
    occurrence_no  INTEGER PRIMARY KEY,
    collection_no  INTEGER NOT NULL REFERENCES DIM_collection(collection_no),
    taxon_key      INTEGER NOT NULL REFERENCES DIM_taxon(taxon_key),
    location_key   INTEGER NOT NULL REFERENCES DIM_location(location_key),
    time_key       INTEGER NOT NULL REFERENCES DIM_time(time_key),
    dataset_type   TEXT    NOT NULL CHECK (dataset_type IN ('Dinosauria', 'Plantae')),
    max_ma         REAL    NOT NULL,
    min_ma         REAL    NOT NULL,
    mid_ma         REAL    NOT NULL
);

-- ------------------------------------------------------------
-- Indici per ottimizzare le query analitiche
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_fact_dataset_type  ON FACT_occurrence(dataset_type);
CREATE INDEX IF NOT EXISTS idx_fact_collection     ON FACT_occurrence(collection_no);
CREATE INDEX IF NOT EXISTS idx_fact_taxon          ON FACT_occurrence(taxon_key);
CREATE INDEX IF NOT EXISTS idx_fact_location       ON FACT_occurrence(location_key);
CREATE INDEX IF NOT EXISTS idx_fact_time           ON FACT_occurrence(time_key);
CREATE INDEX IF NOT EXISTS idx_time_period_group   ON DIM_time(period_group);
CREATE INDEX IF NOT EXISTS idx_location_cc         ON DIM_location(cc);
CREATE INDEX IF NOT EXISTS idx_taxon_genus         ON DIM_taxon(genus);
CREATE INDEX IF NOT EXISTS idx_taxon_dataset       ON DIM_taxon(dataset_type);
