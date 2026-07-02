# REMORSE
### Reptilian Evaluation of Mesozoic Origins: Retrospective Study on Extinction

> *"Forse avremmo dovuto aspettare."*
> — Un rettiliano pentito, 66 milioni di anni dopo

---

## Descrizione del progetto

REMORSE è un progetto di Data Management sviluppato nell'ambito del corso ITS ICT Torino — Tecnico Superiore per la Digitalizzazione dei Processi con Soluzioni AI Based.

Il progetto analizza i dati fossili del Mesozoico (Triassico, Giurassico, Cretaceo) attraverso due dataset complementari — dinosauri e piante preistoriche — con l'obiettivo di rispondere a una domanda tanto seria quanto irresistibile:

**L'ecosistema mesozoico aveva il potenziale evolutivo per sopravvivere? Il meteorite era davvero necessario?**

L'analisi esplora la co-presenza geografica e temporale tra flora e fauna, la diversità tassonomica per era geologica e la resilienza dell'ecosistema nei milioni di anni precedenti al K-Pg.

---

## Fonte dei dati

I dataset provengono dalla **Paleobiology Database** (PBDB), banca dati pubblica di dati paleontologici scaricata tramite API pubblica.

| File | Gruppo tassonomico | Record | Attributi | Filtro |
|---|---|---|---|---|
| `dinos.csv` | Dinosauria | ~37.790 | 38 | Triassico → Cretaceo (Aves escluse) |
| `plants.csv` | Plantae | ~57.394 | 38 | Triassico, Giurassico, Cretaceo |

**Parametri API utilizzati:**
```
# Dinosauri
base_name=Dinosauria, show=coords,attr,loc,time,strat,phylo

# Piante
base_name=Plantae, interval=Triassic,Jurassic,Cretaceous, show=coords,attr,loc,time,strat,phylo
```
Data di download: 18/06/2026

---

## Stack tecnologico

| Componente | Tecnologia |
|---|---|
| Pipeline ETL | Prefect |
| Database | SQLite (locale) · PostgreSQL / Supabase (cloud) |
| Visualizzazione | Power BI Desktop |
| Linguaggio | Python 3.x |

---

## Processo

```
RAW CSV → EDA → DDL → ETL (Prefect) → Supabase (PostgreSQL) → Power BI
```

### 1. EDA — Esplorazione dei dati
`notebooks/`

Analisi esplorativa dei due CSV grezzi. Obiettivo: capire la qualità dei dati, identificare valori nulli, anomalie e distribuzioni, e prendere decisioni informate sulle trasformazioni necessarie.

### 2. DDL — Definizione dello schema
`sql/`

Star schema in SQLite con una fact table unificata e quattro dimensioni condivise tra i due dataset.

```
FACT_occurrence
├── occurrence_no (PK)
├── collection_no (FK → DIM_collection)
├── taxon_key     (FK → DIM_taxon)
├── location_key  (FK → DIM_location)
├── time_key      (FK → DIM_time)
├── dataset_type  -- 'Dinosauria' | 'Plantae'
├── max_ma
├── min_ma
└── mid_ma        -- (max_ma + min_ma) / 2

DIM_taxon         -- classificazione tassonomica
DIM_location      -- coordinate, paese, regione
DIM_time          -- intervallo geologico, period_group
DIM_collection    -- formazione e gruppo geologico
```

### 3. ETL — Pipeline Prefect
`etl/`

Pipeline locale orchestrata con Prefect. Legge i CSV grezzi, applica le trasformazioni definite in fase EDA e carica i dati nel database SQLite.

Trasformazioni principali:
- Rimozione valori nulli nelle colonne critiche
- Eliminazione duplicati
- Aggiunta colonna `dataset_type`
- Calcolo colonna `mid_ma`
- Creazione colonna `period_group` (Triassic / Jurassic / Cretaceous)
- Normalizzazione nomi paesi e categorie tassonomiche
- Flag `has_valid_coords` per record con coordinate valide
- Esclusione classe `Aves` dal dataset dinosauri

### 4. Power BI — Dashboard
`dashboard/`

Dashboard interattiva connessa al database PostgreSQL su Supabase tramite il connettore nativo PostgreSQL. Risponde alle domande analitiche principali con visualizzazioni geografiche, temporali e tassonomiche.

---

## Domande analitiche principali

1. Dove coesistevano dinosauri e piante nello stesso momento e luogo?
2. La diversità floristica cresceva o calava prima del K-Pg?
3. Le specie erano abbastanza distribuite geograficamente da resistere a estinzioni locali?
4. Quali ere mostrano il picco di biodiversità combinata?

---

## Struttura del repository

```
remorse/
├── data/
│   ├── raw/          # CSV originali (dinos.csv, plants.csv)
│   └── processed/    # remorse.db — output finale dell'ETL
├── etl/              # Pipeline Prefect
├── sql/              # DDL schema e query analitiche
├── notebooks/        # EDA
├── dashboard/        # File Power BI (.pbix) e screenshot
├── docs/             # Documentazione tecnica e dataset
└── README.md
```

---

## Team

Progetto di gruppo — ITS ICT Torino, A.A. 2025/2026
