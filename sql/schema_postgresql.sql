-- ============================================================
-- REMORSE — Star Schema DDL (PostgreSQL / Supabase)
-- Reptilian Evaluation of Mesozoic Origins:
-- Retrospective Study on Extinction
--
-- Database: PostgreSQL (Supabase)
-- Fonte dati: Paleobiology Database (PBDB)
--
-- Nota: tutti gli identificatori sono in minuscolo per evitare
-- ambiguita di case-sensitivity in PostgreSQL.
-- ============================================================

DROP TABLE IF EXISTS fact_occurrence CASCADE;
DROP TABLE IF EXISTS dim_taxon CASCADE;
DROP TABLE IF EXISTS dim_location CASCADE;
DROP TABLE IF EXISTS dim_time CASCADE;
DROP TABLE IF EXISTS dim_collection CASCADE;

DROP TYPE IF EXISTS dataset_type_enum;
DROP TYPE IF EXISTS period_group_enum;

-- ------------------------------------------------------------
-- Tipi enumerati
-- ------------------------------------------------------------
CREATE TYPE dataset_type_enum AS ENUM ('Dinosauria', 'Plantae');
CREATE TYPE period_group_enum AS ENUM ('Triassic', 'Jurassic', 'Cretaceous');

-- ------------------------------------------------------------
-- dim_taxon
-- ------------------------------------------------------------
CREATE TABLE dim_taxon (
    taxon_key     SERIAL PRIMARY KEY,
    accepted_name VARCHAR(255) NOT NULL,
    accepted_rank VARCHAR(50)  NOT NULL,
    phylum        VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    class         VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    taxon_order   VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    family        VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    genus         VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    dataset_type  dataset_type_enum NOT NULL
);

-- ------------------------------------------------------------
-- dim_location
-- ------------------------------------------------------------
CREATE TABLE dim_location (
    location_key      SERIAL PRIMARY KEY,
    lat                NUMERIC(9,6),
    lng                NUMERIC(9,6),
    cc                 VARCHAR(10),
    state              VARCHAR(150) NOT NULL DEFAULT 'Unknown',
    has_valid_coords   BOOLEAN      NOT NULL DEFAULT FALSE
);

-- ------------------------------------------------------------
-- dim_time
-- ------------------------------------------------------------
CREATE TABLE dim_time (
    time_key        SERIAL PRIMARY KEY,
    early_interval  VARCHAR(100) NOT NULL,
    late_interval   VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    period_group    period_group_enum NOT NULL
);

-- ------------------------------------------------------------
-- dim_collection
-- ------------------------------------------------------------
CREATE TABLE dim_collection (
    collection_no     INT PRIMARY KEY,
    formation         VARCHAR(150) NOT NULL DEFAULT 'Unknown',
    geological_group  VARCHAR(150) NOT NULL DEFAULT 'Unknown'
);

-- ------------------------------------------------------------
-- fact_occurrence
-- ------------------------------------------------------------
CREATE TABLE fact_occurrence (
    occurrence_no  INT PRIMARY KEY,
    collection_no  INT NOT NULL REFERENCES dim_collection(collection_no),
    taxon_key      INT NOT NULL REFERENCES dim_taxon(taxon_key),
    location_key   INT NOT NULL REFERENCES dim_location(location_key),
    time_key       INT NOT NULL REFERENCES dim_time(time_key),
    dataset_type   dataset_type_enum NOT NULL,
    max_ma         NUMERIC(7,2) NOT NULL,
    min_ma         NUMERIC(7,2) NOT NULL,
    mid_ma         NUMERIC(7,2) NOT NULL
);

-- ------------------------------------------------------------
-- Indici
-- ------------------------------------------------------------
CREATE INDEX idx_fact_dataset_type  ON fact_occurrence(dataset_type);
CREATE INDEX idx_fact_collection    ON fact_occurrence(collection_no);
CREATE INDEX idx_fact_taxon         ON fact_occurrence(taxon_key);
CREATE INDEX idx_fact_location      ON fact_occurrence(location_key);
CREATE INDEX idx_fact_time          ON fact_occurrence(time_key);
CREATE INDEX idx_time_period_group  ON dim_time(period_group);
CREATE INDEX idx_location_cc        ON dim_location(cc);
CREATE INDEX idx_taxon_genus        ON dim_taxon(genus);
CREATE INDEX idx_taxon_dataset      ON dim_taxon(dataset_type);
