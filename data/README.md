# data/

Contiene i dataset utilizzati nel progetto, divisi in due sottocartelle.

```
data/
├── raw/        CSV originali scaricati dalla Paleobiology Database (PBDB)
└── processed/  Output dell'ETL: CSV puliti e database SQLite finale
```

**Regola fondamentale:** i file in `raw/` non vanno mai modificati. Sono la sorgente di verità del progetto. Tutte le trasformazioni avvengono nella pipeline ETL e il risultato va in `processed/`.
