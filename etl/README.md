# etl/

Pipeline ETL orchestrate con **Prefect**. Leggono il CSV pulito da `data/processed/` e popolano il database con lo star schema definito in `sql/`.

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
Carica CSV (fossili_clean.csv)
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

La pulizia e l'arricchimento tassonomico sono fatti a monte in `notebooks/analisi_finale_team.ipynb`
(Parte A, base condivisa dal team — sostituisce la vecchia `cleaning_Danilo.ipynb`), che esporta un unico
CSV: `data/processed/fossili_clean.csv`. Le pipeline non ricalcolano più nulla in Python: leggono le colonne
già pronte e popolano lo star schema.

Il notebook applica, prima dell'export:

- Valori nulli rimossi nelle colonne critiche, duplicati eliminati
- Colonna `dataset_type` → `'Dinosauria'` | `'Plantae'` (da `origine_dataset`)
- Colonna `mid_ma` → `(max_ma + min_ma) / 2` (da `eta_media_ma`)
- Colonna `period_group` → `'Triassico'` | `'Giurassico'` | `'Cretaceo'` (da `periodo_mesozoico`; le righe
  `'Altro'` — età fuori dal range Mesozoico 66-252 Ma, ~1.2% del totale — vengono escluse dall'export)
- Flag `has_valid_coords` per record con coordinate valide (da `coordinate_valide`)
- Classe `Aves` esclusa dal dataset dinosauri
- Colonna `order` rinominata `taxon_order` in `pipeline_postgres.py` (PostgreSQL: parola riservata)

Oltre a queste, il notebook calcola quattro colonne derivate condivise, già pronte nel CSV (nessuna delle
due pipeline le ricalcola più — in precedenza erano duplicate in Python in entrambi i file):

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

Queste quattro colonne sono classificazioni editoriali, non campi nativi PBDB — vanno lette come tali quando
si presentano i risultati.

Le colonne testuali/tassonomiche che restano `NaN` dopo la pulizia del notebook (`phylum`, `class`, `order`,
`family`, `genus`, `state`, `formation`, `geological_group`, `late_interval`, `continente`) vengono riempite
dalle pipeline con i valori di default `'Unknown'` / `'Sconosciuto'` prima dell'inserimento (`VALORI_DEFAULT`
in entrambi i file), perché `pandas.to_sql()` inserisce `NULL` espliciti che bypassano i `DEFAULT` definiti
nello schema SQL.

`data/processed/dinos_clean.csv` e `plants_clean.csv` (output storico di `cleaning_Danilo.ipynb`) restano nel
repo ma non sono più usati da nessuna pipeline.
