# data/processed/

Output generati dalla pipeline ETL. Non modificare questi file a mano.

| File | Descrizione |
|---|---|
| `fossili_clean.csv` | Dataset dinosauri + piante pulito e arricchito, esportato da `notebooks/analisi_finale_team.ipynb` (Parte B) — input attuale di entrambe le pipeline ETL |
| `dinos_clean.csv` | *(legacy)* Dataset dinosauri dopo la vecchia fase di cleaning (notebook `cleaning_Danilo.ipynb`) — non più usato dalle pipeline |
| `plants_clean.csv` | *(legacy)* Dataset piante dopo la vecchia fase di cleaning — non più usato dalle pipeline |
| `remorse.db` | Database SQLite con lo star schema finale, generato da `etl/pipeline.py` |

## Come rigenerare remorse.db

```bash
python etl/pipeline.py
```

La pipeline elimina il database esistente e lo ricrea da zero leggendo `fossili_clean.csv`.

## Perché esiste remorse.db (e perché non alimenta Supabase)

`remorse.db` è pensato solo per **validazione locale rapida** dello star schema (vincoli `FOREIGN KEY`,
`CHECK` su `dataset_type`/`period_group`) prima di toccare il database condiviso: se `etl/pipeline.py`
fallisce in locale su un dato sporco, sappiamo che lo stesso dato farebbe fallire anche il caricamento
su Supabase.

`etl/pipeline_postgres.py` **non legge da `remorse.db`** — legge direttamente `fossili_clean.csv`
e scrive su Supabase via rete (`to_sql`, in append). Non c'è quindi un passaggio
intermedio "CSV → SQLite → Postgres": i due database (locale e cloud) vengono popolati in parallelo,
in modo indipendente, dallo stesso CSV pulito.

Il motivo per cui non usiamo `remorse.db` come staging per Postgres è di semplicità: con il volume di
dati di questo progetto (decine di migliaia di righe), tenere i dati in memoria con pandas non è un
problema, e aggiungere uno stadio intermedio da tenere sincronizzato (rigenerare sempre `remorse.db`
prima di ogni caricamento su Supabase) avrebbe aggiunto complessità senza un beneficio reale.

Per validare lo schema prima di un caricamento su Supabase, si può quindi lanciare `etl/pipeline.py`
in locale come "dry run": stesso schema, stessi vincoli, senza toccare il database condiviso.

## Star schema

```
FACT_occurrence
├── occurrence_no  (PK)
├── collection_no  (FK → DIM_collection)
├── taxon_key      (FK → DIM_taxon)
├── location_key   (FK → DIM_location)
├── time_key       (FK → DIM_time)
├── dataset_type   -- 'Dinosauria' | 'Plantae'
├── max_ma
├── min_ma
└── mid_ma         -- (max_ma + min_ma) / 2
```

`DIM_time.period_group` usa valori italiani: `'Triassico'` | `'Giurassico'` | `'Cretaceo'`.

Per lo schema DDL completo vedere [`sql/schema.sql`](../../sql/schema.sql).
