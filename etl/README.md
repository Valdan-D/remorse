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

Oltre a queste, entrambe le pipeline calcolano tre colonne aggiuntive prima di popolare le dimensioni
(logica portata da `notebooks/test/analisi.ipynb`, tema "ecosistema" di Giada):

- `DIM_location.continente` — da `cc`, tramite `pycountry_convert` più una mappa manuale per codici PBDB
  non standard (`UK`, `AQ`, `TF`, `TL`, `PN`, `EH`)
- `DIM_taxon.order_raggruppato` — uguale a `order`/`taxon_order` per Dinosauria; per Plantae, i 15 ordini
  più frequenti (per numero di occorrenze, non di taxon distinti) restano invariati, il resto va in `'Altro'`
- `DIM_taxon.categoria` — macro-categoria trofica/tassonomica (`'Pianta'`, `'Carnivoro'`, `'Erbivoro'`,
  `'Erbivoro/Incertezza'`, `'Altro/Non Classificato'`), basata su famiglie di teropodi/ornitischi/sauropodi
  note in letteratura, con fallback su ordine/classe quando la famiglia non è nota
- `DIM_taxon.possibile_aviano_residuo` — booleano, `TRUE` se l'ordine è tra quelli aviari noti
  (`Galliformes`, `Hesperornithiformes`, `Ichthyornithes`, `Alexornithiformes`, `Colymbiformes`,
  `Yanornithiformes`, `Cathayornithiformes`, `Eoenantiornithiformes`, `Jeholornithiformes`) rimasti
  classificati come `Reptilia` invece che come `Aves`. Colonna condivisa tra due temi con esigenze opposte:
  il tema ecosistema filtra `WHERE NOT possibile_aviano_residuo` per restare sui soli dinosauri "classici",
  il tema evoluzione la usa come uno dei segnali della transizione verso la linea aviaria

Queste tre colonne sono classificazioni editoriali, non campi nativi PBDB — vanno lette come tali quando
si presentano i risultati. La loro completezza dipende dal livello di riempimento tassonomico dei CSV
puliti in ingresso: `dinos_clean.csv`/`plants_clean.csv` non includono l'arricchimento tassonomico più
approfondito fatto in `notebooks/EDA_unito_V0.3.ipynb` (sezione 7, tramite i CSV di supporto in
`notebooks/scraping/`), quindi `categoria` risulta `'Altro/Non Classificato'` per una quota di record
superiore rispetto a quanto visto in `analisi.ipynb`, che lavora sul dataframe arricchito.
