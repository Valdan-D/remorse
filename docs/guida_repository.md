# Guida all'utilizzo del repository REMORSE

Questo documento descrive i passaggi per lavorare sul repository in modo coordinato tra i membri del gruppo.

---

## Prerequisiti

Prima di iniziare, assicurarsi di avere installato:

| Strumento | Utilizzo | Verifica |
|---|---|---|
| Git | Versionamento del codice | `git --version` |
| Python 3.x | ETL e notebook | `python --version` |
| Jupyter | Esplorazione dati | `jupyter --version` |
| Prefect | Orchestrazione pipeline | `prefect --version` |
| Power BI Desktop | Dashboard | Applicazione Windows |

---

## Prima configurazione (solo la prima volta)

### 1. Clonare il repository

Scaricare il repository in locale nella propria cartella di lavoro.

```bash
git clone https://github.com/Valdan-D/remorse.git
cd remorse
```

### 2. Installare le dipendenze Python

Installare i pacchetti necessari elencati in `requirements.txt`.

```bash
pip install -r requirements.txt
```

### 3. Aggiungere i dataset grezzi

Copiare manualmente i file `dinos.csv` e `plants.csv` nella cartella `data/raw/`. I file sono già presenti nel repository remoto; vengono scaricati automaticamente con il clone.

---

## Flusso di lavoro quotidiano

Prima di iniziare a lavorare, aggiornare sempre il repository locale con le ultime modifiche del gruppo.

```bash
git pull
```

Al termine della sessione di lavoro, salvare e condividere le modifiche.

```bash
git add .
git commit -m "descrizione breve di cosa hai fatto"
git push
```

### Convenzioni per i messaggi di commit

Usare un prefisso che descriva il tipo di modifica:

| Prefisso | Quando usarlo |
|---|---|
| `feat:` | Aggiunta di una nuova funzionalità o file |
| `fix:` | Correzione di un errore |
| `docs:` | Modifiche alla documentazione |
| `data:` | Modifiche ai dataset o al database |
| `etl:` | Modifiche alla pipeline Prefect |
| `chore:` | Pulizia, rinominazione, riorganizzazione |

Esempio: `git commit -m "etl: aggiunto task di pulizia valori nulli"`

---

## Struttura del repository

```
remorse/
├── data/
│   ├── raw/          Dataset originali scaricati da PBDB
│   └── processed/    Database SQLite generato dall'ETL (remorse.db)
├── etl/              Pipeline Prefect per trasformazione e caricamento
├── sql/              DDL dello star schema e query analitiche
├── notebooks/        Notebook Jupyter per l'esplorazione EDA
├── dashboard/        File Power BI e screenshot della dashboard
├── docs/             Documentazione tecnica e del dataset
└── README.md         Panoramica del progetto
```

---

## Sequenza di lavoro del progetto

Il progetto segue questo ordine di fasi. Ogni fase produce un output che alimenta la successiva.

| Fase | Cartella | Output | Stato |
|---|---|---|---|
| 1. EDA | `notebooks/` | Analisi esplorativa e decisioni di trasformazione | Da fare |
| 2. DDL | `sql/` | Schema SQLite (`schema.sql`) | Da fare |
| 3. ETL | `etl/` | Pipeline Prefect e `remorse.db` | Da fare |
| 4. Dashboard | `dashboard/` | File Power BI collegato al database | Da fare |

---

## Note operative

**Non modificare i file in `data/raw/`.**
I CSV originali sono la sorgente di verità del progetto e non devono essere alterati. Tutte le trasformazioni avvengono nella pipeline ETL e il risultato va in `data/processed/`.

**Il file `remorse.db` viene generato dalla pipeline.**
Non va creato o modificato a mano. Per rigenerarlo, eseguire la pipeline ETL.

**In caso di conflitti Git**, non sovrascrivere il lavoro altrui. Contattare il membro del gruppo coinvolto e risolvere il conflitto insieme prima di fare push.
