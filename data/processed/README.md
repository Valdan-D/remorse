# data/processed/

Output generati dalla pipeline ETL. Non modificare questi file a mano.

| File | Descrizione |
|---|---|
| `dinos_clean.csv` | Dataset dinosauri dopo la fase di cleaning (notebook `cleaning_Danilo.ipynb`) |
| `plants_clean.csv` | Dataset piante dopo la fase di cleaning |
| `remorse.db` | Database SQLite con lo star schema finale, generato da `etl/pipeline.py` |

## Come rigenerare remorse.db

```bash
python etl/pipeline.py
```

La pipeline elimina il database esistente e lo ricrea da zero leggendo i CSV puliti.

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

Per lo schema DDL completo vedere [`sql/schema.sql`](../../sql/schema.sql).
