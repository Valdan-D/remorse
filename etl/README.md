# etl/

Pipeline ETL orchestrate con **Prefect**. Leggono i CSV puliti da `data/processed/` e popolano il database con lo star schema definito in `sql/`.

## File

| File | Target | Descrizione |
|---|---|---|
| `pipeline.py` | SQLite (`remorse.db`) | Pipeline locale — crea e popola il database SQLite |
| `pipeline_postgres.py` | PostgreSQL / Supabase | Pipeline cloud — carica i dati su Supabase via SQLAlchemy |

## Utilizzo

### Pipeline SQLite (locale)

```bash
python etl/pipeline.py
```

Output: `data/processed/remorse.db`

### Pipeline PostgreSQL / Supabase

1. Creare il file `.env` nella root del repo:
   ```
   DATABASE_URL=postgresql://postgres:PASSWORD@db.xxxx.supabase.co:5432/postgres
   ```
2. Eseguire prima lo schema DDL su Supabase (`sql/schema_postgresql.sql`)
3. Avviare la pipeline:
   ```bash
   python etl/pipeline_postgres.py
   ```

## Struttura della pipeline

Entrambe le pipeline seguono lo stesso flusso Prefect:

```
Carica CSV (dinos_clean + plants_clean)
    ↓
Crea schema (SQLite) / usa schema esistente (PostgreSQL)
    ↓
Popola DIM_collection
Popola DIM_taxon
Popola DIM_location
Popola DIM_time
    ↓
Popola FACT_occurrence (join sulle chiavi surrogate)
    ↓
Verifica conteggi tabelle
```

## Trasformazioni applicate

Le trasformazioni sono già state eseguite nella fase di cleaning (notebook `cleaning_Danilo.ipynb`). I CSV puliti in ingresso contengono già:

- Valori nulli rimossi nelle colonne critiche
- Duplicati eliminati
- Colonna `dataset_type` → `'Dinosauria'` | `'Plantae'`
- Colonna `mid_ma` → `(max_ma + min_ma) / 2`
- Colonna `period_group` → `'Triassic'` | `'Jurassic'` | `'Cretaceous'`
- Flag `has_valid_coords` per record con coordinate valide
- Classe `Aves` esclusa dal dataset dinosauri
- Colonna `order` rinominata `taxon_order` (PostgreSQL: parola riservata)
