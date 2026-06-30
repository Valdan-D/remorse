# data/raw/

Dataset grezzi scaricati dalla **Paleobiology Database (PBDB)** tramite API pubblica. Non modificare questi file.

| File | Gruppo tassonomico | Record | Filtro |
|---|---|---|---|
| `dinos.csv` | Dinosauria | ~37.790 | Triassico → Cretaceo (Aves escluse) |
| `plants.csv` | Plantae | ~57.394 | Triassico, Giurassico, Cretaceo |

**Parametri API usati per il download (18/06/2026):**

```
# Dinosauri
base_name=Dinosauria, show=coords,attr,loc,time,strat,phylo

# Piante
base_name=Plantae, interval=Triassic,Jurassic,Cretaceous, show=coords,attr,loc,time,strat,phylo
```

Per dettagli sugli attributi e la struttura dei dataset, vedere [`docs/documentazione_dataset.md`](../../docs/documentazione_dataset.md).
