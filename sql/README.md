# sql/

Definizioni DDL dello star schema per i tre target database supportati dal progetto.

## File

| File | Database | Utilizzo |
|---|---|---|
| `schema.sql` | SQLite | Usato direttamente dalla pipeline `etl/pipeline.py` |
| `schema_postgresql.sql` | PostgreSQL / Supabase | Da eseguire nel SQL Editor di Supabase prima della pipeline Postgres |
| `schema_mariadb.sql` | MariaDB / AWS RDS | Schema alternativo per ambienti MySQL/MariaDB |

## Star schema

Il modello è composto da una fact table e quattro dimensioni, condivise tra i due dataset (Dinosauria e Plantae).

```
                    ┌─────────────────┐
                    │  DIM_collection │
                    │  collection_no  │
                    └────────┬────────┘
                             │
┌──────────┐      ┌──────────▼──────────┐      ┌───────────┐
│ DIM_taxon│◄─────│   FACT_occurrence   │─────►│DIM_location│
└──────────┘      │   occurrence_no     │      └───────────┘
                  │   collection_no     │
                  │   taxon_key         │      ┌──────────┐
                  │   location_key      │─────►│ DIM_time │
                  │   time_key          │      └──────────┘
                  │   dataset_type      │
                  │   max_ma / min_ma   │
                  │   mid_ma            │
                  └─────────────────────┘
```

### Tabelle

| Tabella | Chiave | Contenuto |
|---|---|---|
| `FACT_occurrence` | `occurrence_no` | Un record per ritrovamento fossile |
| `DIM_taxon` | `taxon_key` | Classificazione tassonomica (phylum → genus), più `order_raggruppato` e `categoria` |
| `DIM_location` | `location_key` | Coordinate, paese, regione, più `continente` |
| `DIM_time` | `time_key` | Intervallo geologico, `period_group` (`'Triassico'`/`'Giurassico'`/`'Cretaceo'`) |
| `DIM_collection` | `collection_no` | Sito di scavo, formazione geologica |

### Colonne derivate (classificazioni editoriali)

Oltre ai campi originali PBDB, `DIM_taxon` e `DIM_location` includono colonne calcolate a monte in
`notebooks/analisi_finale_team.ipynb` (Parte B) e già pronte nel CSV che alimenta le pipeline ETL — non sono
dati nativi PBDB, ma classificazioni scelte dal team:

| Colonna | Tabella | Derivata da | Descrizione |
|---|---|---|---|
| `continente` | `DIM_location` | `cc` | Continente (`pycountry_convert` + mappa manuale per codici non standard) |
| `order_raggruppato` | `DIM_taxon` | `order`/`taxon_order`, `dataset_type` | Uguale a `order` per Dinosauria; per Plantae, i 15 ordini più frequenti restano invariati, il resto è raggruppato in `'Altro'` |
| `categoria` | `DIM_taxon` | `phylum`, `class`, `order`/`taxon_order`, `family` | Macro-categoria trofica/tassonomica: `'Pianta'`, `'Carnivoro'`, `'Erbivoro'`, `'Erbivoro/Incertezza'`, `'Altro/Non Classificato'` |
| `possibile_aviano_residuo` | `DIM_taxon` | `order`/`taxon_order` | Booleano: `TRUE` se l'ordine è tra quelli aviari noti rimasti classificati come `Reptilia` invece che come `Aves` (residuo del filtro di esclusione a monte). Colonna condivisa: il tema ecosistema la usa per escludere questi record, il tema evoluzione per includerli come segnale di transizione verso gli uccelli |

### Differenze tra versioni

- **SQLite** (`schema.sql`): usa `AUTOINCREMENT`, virgolette per parole riservate (`"order"`)
- **PostgreSQL** (`schema_postgresql.sql`): usa `SERIAL`, nomi colonne lowercase, `taxon_order` al posto di `order`
- **MariaDB** (`schema_mariadb.sql`): usa `AUTO_INCREMENT`, backtick per i nomi riservati
