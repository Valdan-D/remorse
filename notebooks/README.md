# notebooks/

Notebook Jupyter per l'analisi esplorativa (EDA) e il cleaning dei dataset.

## File

| File | Fase | Descrizione |
|---|---|---|
| `eda_Danilo.ipynb` | EDA | Analisi esplorativa dei dataset grezzi (`dinos.csv`, `plants.csv`) |
| `cleaning_Danilo.ipynb` | Cleaning | Trasformazioni e pulizia dei dati; produce `dinos_clean.csv` e `plants_clean.csv` |
| `visualizations_Danilo.ipynb` | Visualizzazione | Grafici e visualizzazioni esplorative sui dati puliti |
| `eda-Danilo.ipynb - Colab.pdf` | EDA | Esportazione PDF del notebook EDA (eseguito su Google Colab) |

## Ordine di esecuzione

```
eda_Danilo.ipynb  →  cleaning_Danilo.ipynb  →  visualizations_Danilo.ipynb
```

Il notebook di cleaning è quello che produce i CSV puliti usati dalla pipeline ETL. Va eseguito prima di `etl/pipeline.py`.

## Avvio

```bash
jupyter notebook notebooks/
```

I CSV grezzi da cui partono i notebook si trovano in `data/raw/`.
