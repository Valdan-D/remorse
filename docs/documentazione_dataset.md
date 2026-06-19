# Documentazione dei dataset

## Origine dei dati

I dataset utilizzati nel progetto provengono dalla **Paleobiology Database (PBDB)**, una banca dati pubblica dedicata alla raccolta di informazioni paleontologiche. La piattaforma raccoglie dati relativi a fossili, taxa, località di ritrovamento, intervalli geologici, coordinate geografiche, classificazioni tassonomiche e riferimenti bibliografici.

I dati sono stati ottenuti tramite API pubblica della Paleobiology Database, utilizzando l'endpoint dedicato alle **fossil occurrences**, cioè ai record di presenza/ritrovamento fossile. Ogni record rappresenta una segnalazione fossile collegata a una determinata collezione, località, taxon e riferimento scientifico.

I file utilizzati nel progetto sono:
- `dinos.csv`
- `plants.csv`

Entrambi i dataset sono stati scaricati in formato CSV e successivamente rinominati per renderli più semplici da gestire nel progetto.

---

## Dataset 1: `dinos.csv`

### Descrizione generale

Il dataset contiene record fossili associati al gruppo tassonomico **Dinosauria**. La query originale è stata costruita usando il parametro `base_name=Dinosauria`, che restituisce le occorrenze collegate a Dinosauria e ai taxa discendenti.

| Proprietà | Valore |
|---|---|
| Record | 37.790 |
| Attributi | 38 |

> **Nota:** dal punto di vista tassonomico, Dinosauria include anche gli uccelli (Aves), in quanto discendenti dei dinosauri teropodi. Se l'obiettivo è concentrarsi sui dinosauri mesozoici "classici", sarà necessario escludere Aves o limitare l'analisi agli intervalli Triassic, Jurassic e Cretaceous.

### Attributi principali

| Attributo | Descrizione |
|---|---|
| `occurrence_no` | Identificativo univoco dell'occorrenza fossile |
| `collection_no` | Identificativo della collezione/località |
| `identified_name` | Nome con cui il fossile è stato identificato nel record originale |
| `accepted_name` | Nome tassonomico accettato |
| `accepted_rank` | Rango tassonomico del nome accettato |
| `early_interval` | Intervallo geologico iniziale |
| `late_interval` | Eventuale intervallo geologico finale |
| `max_ma` | Età massima stimata (milioni di anni) |
| `min_ma` | Età minima stimata (milioni di anni) |
| `lng` | Longitudine |
| `lat` | Latitudine |
| `cc` | Codice paese |
| `state` | Stato o regione |
| `county` | Contea o area locale |
| `formation` | Formazione geologica |
| `geological_group` | Gruppo geologico |
| `phylum, class, order, family, genus` | Classificazione tassonomica |

### Possibili utilizzi

- Distribuzione geografica dei ritrovamenti fossili di dinosauri
- Distribuzione dei fossili per periodo geologico
- Paesi con il maggior numero di ritrovamenti
- Taxa più rappresentati
- Confronto tra gruppi tassonomici
- Relazione tra ritrovamenti fossili e formazioni geologiche
- Evoluzione della presenza fossile nel tempo geologico

---

## Dataset 2: `plants.csv`

### Descrizione generale

Il dataset contiene record fossili associati al gruppo tassonomico **Plantae**, filtrati sugli intervalli geologici Triassico, Giurassico e Cretaceo — ovvero il **Mesozoico**, l'era in cui vissero e si diffusero i dinosauri non-aviani.

| Proprietà | Valore |
|---|---|
| Record | 57.394 |
| Attributi | 38 |

### Attributi principali

Stessa struttura di `dinos.csv` — i 38 attributi sono identici.

### Possibili utilizzi

- Distribuzione geografica delle piante fossili nel Mesozoico
- Periodi geologici con maggiore presenza di fossili vegetali
- Paesi e regioni con più ritrovamenti vegetali
- Famiglie o generi vegetali più frequenti
- Confronto tra presenza di vegetazione fossile e presenza di dinosauri
- Studio degli ecosistemi mesozoici attraverso dati paleontologici

---

## Collegamento tra i due dataset

I due dataset possono essere analizzati insieme perché provengono dalla stessa fonte, hanno struttura identica e condividono le stesse colonne. Il collegamento non avviene tramite chiave univoca diretta, ma tramite **attributi comuni**:

- Periodo geologico
- Età in milioni di anni (`max_ma`, `min_ma`)
- Coordinate geografiche (`lat`, `lng`)
- Paese (`cc`)
- Formazione geologica (`formation`)
- Collezione o località (`collection_no`)
- Classificazione tassonomica

L'obiettivo non è dimostrare una relazione causale diretta tra un singolo fossile di dinosauro e una singola pianta, ma analizzare la **sovrapposizione geografica e temporale** tra i due gruppi per ricostruire in modo esplorativo gli ecosistemi mesozoici.

---

## Possibili analisi per la dashboard

### Analisi principali
- Numero totale di occorrenze fossili per dataset
- Distribuzione dei fossili per periodo geologico
- Distribuzione geografica dei ritrovamenti su mappa
- Confronto dinosauri vs piante per paese e per intervallo geologico
- Top 10 paesi con più ritrovamenti
- Top 10 generi o famiglie più frequenti
- Analisi della presenza di coordinate mancanti

### KPI
| KPI | Descrizione |
|---|---|
| Totale record dinosauri | Conteggio occorrenze `dinos.csv` |
| Totale record piante fossili | Conteggio occorrenze `plants.csv` |
| Paesi rappresentati | Numero di `cc` distinti |
| % record con coordinate | Record con `lat`/`lng` validi |
| Intervallo con più ritrovamenti | `early_interval` più frequente |
| Paese con più occorrenze | `cc` con count massimo |

---

## Qualità dei dati e trasformazioni previste

### Problemi attesi
- Valori mancanti nelle colonne principali
- Duplicati
- Coordinate mancanti o imprecise
- Taxa non specificati
- Campi geologici incompleti
- Record non coerenti con l'obiettivo dell'analisi (es. Aves in `dinos.csv`)

### Trasformazioni pianificate

1. Rimozione o gestione dei valori nulli nelle colonne più importanti
2. Eliminazione di eventuali duplicati
3. Creazione colonna `dataset_type` → `'Dinosauria'` | `'Plantae'`
4. Creazione colonna `mid_ma` → `(max_ma + min_ma) / 2`
5. Creazione colonna `period_group` → `'Triassic'` | `'Jurassic'` | `'Cretaceous'`
6. Normalizzazione dei nomi dei paesi e delle categorie tassonomiche
7. Filtro dei record con coordinate valide per le visualizzazioni geografiche
8. Esclusione della classe `Aves` dal dataset dinosauri (opzionale, da decidere in fase EDA)

---

## Limiti del dataset

I dati PBDB derivano da pubblicazioni scientifiche e contributi inseriti nel tempo. Il dataset non rappresenta tutti i fossili esistenti, ma solo quelli registrati nella banca dati. La distribuzione può essere influenzata da:

- Maggiore attività di ricerca in alcuni paesi
- Diversa accessibilità dei siti fossiliferi
- Diversa conservazione dei fossili nelle rocce
- Differenze nella qualità delle informazioni inserite
- Presenza di record con coordinate approssimative o mancanti
- Aggiornamenti continui del database

Le analisi devono essere interpretate come **esplorative e descrittive**, evitando conclusioni causali troppo forti.

---

## Citazione della sorgente

| Campo | Valore |
|---|---|
| Sorgente | Paleobiology Database |
| Tipo di dati | Fossil occurrences |
| Formato | CSV |
| Data di download | 18/06/2026 |
| File | `dinos.csv`, `plants.csv` |

**Parametri API:**
```
# Dinosauri
base_name=Dinosauria, show=coords,attr,loc,time,strat,phylo

# Piante
base_name=Plantae, interval=Triassic,Jurassic,Cretaceous, show=coords,attr,loc,time,strat,phylo
```
