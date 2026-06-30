# dashboard/

Dashboard Power BI interattiva connessa al database SQLite del progetto.

## File

| File | Descrizione |
|---|---|
| `remorse.pbix` | File Power BI Desktop — contiene il modello dati, le misure DAX e le visualizzazioni |

## Come aprire la dashboard

1. Assicurarsi che `data/processed/remorse.db` esista (generarlo con `python etl/pipeline.py` se necessario)
2. Aprire `remorse.pbix` con **Power BI Desktop**
3. La connessione al database avviene tramite **ODBC** — verificare che il driver SQLite ODBC sia installato sul sistema
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
- Driver ODBC per SQLite (`SQLite ODBC Driver` di Christian Werner o equivalente)
- `data/processed/remorse.db` generato e aggiornato
