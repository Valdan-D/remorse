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
| `DIM_taxon` | `taxon_key` | Classificazione tassonomica (phylum → genus) |
| `DIM_location` | `location_key` | Coordinate, paese, regione |
| `DIM_time` | `time_key` | Intervallo geologico, period_group |
| `DIM_collection` | `collection_no` | Sito di scavo, formazione geologica |

### Differenze tra versioni

- **SQLite** (`schema.sql`): usa `AUTOINCREMENT`, virgolette per parole riservate (`"order"`)
- **PostgreSQL** (`schema_postgresql.sql`): usa `SERIAL`, nomi colonne lowercase, `taxon_order` al posto di `order`
- **MariaDB** (`schema_mariadb.sql`): usa `AUTO_INCREMENT`, backtick per i nomi riservati
