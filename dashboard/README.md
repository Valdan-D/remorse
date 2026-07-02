# dashboard/

Dashboard Power BI interattiva connessa al database PostgreSQL su Supabase.

## File

| File | Descrizione |
|---|---|
| `remorse.pbix` | File Power BI Desktop — contiene il modello dati, le misure DAX e le visualizzazioni |

## Come aprire la dashboard

1. Assicurarsi che lo star schema sia caricato e popolato su Supabase (`sql/schema_postgresql.sql` + `python etl/pipeline_postgres.py`, vedi [`etl/README.md`](../etl/README.md))
2. Aprire `remorse.pbix` con **Power BI Desktop**
3. La connessione avviene tramite il connettore nativo **PostgreSQL** verso il database Supabase — al primo accesso Power BI chiede le credenziali del database (utente/password, non "Anonimo")
4. Aggiornare i dati se richiesto (tasto "Aggiorna" nella barra multifunzione)

## Contenuto della dashboard

La dashboard risponde alle domande analitiche principali del progetto:

- **KPI**: totale occorrenze Dinosauria e Plantae, paesi rappresentati, % record con coordinate valide
- **Mappa geografica**: distribuzione mondiale dei ritrovamenti fossili, filtrabile per gruppo (dinosauri / piante)
- **Distribuzione temporale**: occorrenze per periodo geologico (Triassico, Giurassico, Cretaceo)
- **Top paesi**: classifica dei paesi per numero di ritrovamenti
- **Biodiversità combinata**: confronto dinosauri vs piante per era geologica
- **Slicer interattivi**: periodo geologico, dataset, paese

## Requisiti

- Power BI Desktop (Windows)
- Connettore PostgreSQL nativo di Power BI (incluso in Desktop, nessun driver ODBC da installare)
- Credenziali del database Supabase (vedi variabile `DATABASE_URL` nel file `.env` in root, non versionato)
- Star schema caricato su Supabase e popolato tramite `etl/pipeline_postgres.py`
