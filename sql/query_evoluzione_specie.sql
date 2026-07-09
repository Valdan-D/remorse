-- ============================================================
-- REMORSE — Query analitiche
-- Tema: Evoluzione/sviluppo della specie (dinosauri pre-K-Pg)
--
-- Scritte per lo schema SQLite (sql/schema.sql, tabelle/colonne
-- in CamelCase, "order" tra virgolette). Per PostgreSQL/Supabase
-- (sql/schema_postgresql.sql): usare nomi tabella minuscoli
-- (fact_occurrence, dim_taxon, dim_time) e taxon_order al posto
-- di "order".
--
-- Logica di riferimento e validazione: notebooks/test/evoluzione_Danilo.ipynb
-- Le due feature usate qui (linea evolutiva, bin temporale da 5 Ma)
-- sono classificazioni editoriali derivate da colonne già presenti
-- nello star schema (family, "order", mid_ma): non richiedono
-- modifiche allo schema condiviso. In Power BI vanno ricostruite
-- come colonna calcolata (Power Query) o misura DAX equivalente.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Occorrenze dinosauri per periodo geologico
-- ------------------------------------------------------------
SELECT
    t.period_group,
    COUNT(*) AS occorrenze
FROM FACT_occurrence f
JOIN DIM_time t ON t.time_key = f.time_key
WHERE f.dataset_type = 'Dinosauria'
GROUP BY t.period_group
ORDER BY
    CASE t.period_group
        WHEN 'Triassic'   THEN 1
        WHEN 'Jurassic'   THEN 2
        WHEN 'Cretaceous' THEN 3
    END;


-- ------------------------------------------------------------
-- 2. Occorrenze del Cretaceo per stage (early_interval),
--    ordinate cronologicamente per età media (mid_ma)
-- ------------------------------------------------------------
SELECT
    t.early_interval,
    COUNT(*)         AS occorrenze,
    AVG(f.mid_ma)     AS eta_media_ma
FROM FACT_occurrence f
JOIN DIM_time t ON t.time_key = f.time_key
WHERE f.dataset_type = 'Dinosauria'
  AND t.period_group = 'Cretaceous'
GROUP BY t.early_interval
ORDER BY eta_media_ma DESC;


-- ------------------------------------------------------------
-- 3. Classificazione "linea evolutiva" (classica vs aviaria)
--    Famiglie/ordini scelti in base alla letteratura
--    (Maniraptora/Paraves/Avialae basali) — vedi notebook
--    sezione 4 per la nota di trasparenza.
-- ------------------------------------------------------------
SELECT
    f.occurrence_no,
    tx.genus,
    tx.family,
    tx."order",
    t.period_group,
    f.mid_ma,
    CASE
        WHEN tx.family IN (
            'Dromaeosauridae', 'Troodontidae', 'Oviraptoridae',
            'Ornithomimidae', 'Ornithomimipodidae'
        )
        OR tx."order" IN (
            'Hesperornithiformes', 'Ichthyornithes', 'Alexornithiformes',
            'Yanornithiformes', 'Cathayornithiformes', 'Eoenantiornithiformes',
            'Jeholornithiformes'
        )
        THEN 'Linea aviaria'
        ELSE 'Linea classica'
    END AS linea_evolutiva
FROM FACT_occurrence f
JOIN DIM_taxon tx ON tx.taxon_key = f.taxon_key
JOIN DIM_time  t  ON t.time_key  = f.time_key
WHERE f.dataset_type = 'Dinosauria';


-- ------------------------------------------------------------
-- 4. Occorrenze per periodo geologico x linea evolutiva
-- ------------------------------------------------------------
SELECT
    t.period_group,
    CASE
        WHEN tx.family IN (
            'Dromaeosauridae', 'Troodontidae', 'Oviraptoridae',
            'Ornithomimidae', 'Ornithomimipodidae'
        )
        OR tx."order" IN (
            'Hesperornithiformes', 'Ichthyornithes', 'Alexornithiformes',
            'Yanornithiformes', 'Cathayornithiformes', 'Eoenantiornithiformes',
            'Jeholornithiformes'
        )
        THEN 'Linea aviaria'
        ELSE 'Linea classica'
    END AS linea_evolutiva,
    COUNT(*) AS occorrenze
FROM FACT_occurrence f
JOIN DIM_taxon tx ON tx.taxon_key = f.taxon_key
JOIN DIM_time  t  ON t.time_key  = f.time_key
WHERE f.dataset_type = 'Dinosauria'
GROUP BY t.period_group, linea_evolutiva
ORDER BY
    CASE t.period_group
        WHEN 'Triassic'   THEN 1
        WHEN 'Jurassic'   THEN 2
        WHEN 'Cretaceous' THEN 3
    END,
    linea_evolutiva;


-- ------------------------------------------------------------
-- 5. Ricchezza tassonomica (generi distinti) per bin temporale
--    da 5 Ma e linea evolutiva. genus = 'Unknown' escluso.
--    Il bin è un'approssimazione per il floor(mid_ma / 5) * 5:
--    la logica autorevole (pd.cut) resta nel notebook.
-- ------------------------------------------------------------
SELECT
    (CAST(f.mid_ma / 5 AS INT) * 5) + 2.5 AS bin_mid_ma,
    CASE
        WHEN tx.family IN (
            'Dromaeosauridae', 'Troodontidae', 'Oviraptoridae',
            'Ornithomimidae', 'Ornithomimipodidae'
        )
        OR tx."order" IN (
            'Hesperornithiformes', 'Ichthyornithes', 'Alexornithiformes',
            'Yanornithiformes', 'Cathayornithiformes', 'Eoenantiornithiformes',
            'Jeholornithiformes'
        )
        THEN 'Linea aviaria'
        ELSE 'Linea classica'
    END AS linea_evolutiva,
    COUNT(DISTINCT tx.genus) AS generi_distinti
FROM FACT_occurrence f
JOIN DIM_taxon tx ON tx.taxon_key = f.taxon_key
WHERE f.dataset_type = 'Dinosauria'
  AND tx.genus NOT IN ('Unknown', 'NO_GENUS_SPECIFIED')
GROUP BY bin_mid_ma, linea_evolutiva
ORDER BY bin_mid_ma DESC, linea_evolutiva;


-- ------------------------------------------------------------
-- 6. Prima comparsa e ultima occorrenza per genere
--    (mid_ma più alto = più antico, più basso = più recente)
-- ------------------------------------------------------------
SELECT
    tx.genus,
    MAX(f.mid_ma) AS comparsa_ma,
    MIN(f.mid_ma) AS ultima_occorrenza_ma,
    CASE
        WHEN tx.family IN (
            'Dromaeosauridae', 'Troodontidae', 'Oviraptoridae',
            'Ornithomimidae', 'Ornithomimipodidae'
        )
        OR tx."order" IN (
            'Hesperornithiformes', 'Ichthyornithes', 'Alexornithiformes',
            'Yanornithiformes', 'Cathayornithiformes', 'Eoenantiornithiformes',
            'Jeholornithiformes'
        )
        THEN 'Linea aviaria'
        ELSE 'Linea classica'
    END AS linea_evolutiva
FROM FACT_occurrence f
JOIN DIM_taxon tx ON tx.taxon_key = f.taxon_key
WHERE f.dataset_type = 'Dinosauria'
  AND tx.genus NOT IN ('Unknown', 'NO_GENUS_SPECIFIED')
GROUP BY tx.genus;
