"""
REMORSE — ETL Pipeline
Reptilian Evaluation of Mesozoic Origins: Retrospective Study on Extinction

Legge i dataset puliti, costruisce lo star schema SQLite e popola il database.

Utilizzo:
    python etl/pipeline.py

Output:
    data/processed/remorse.db
"""

import sqlite3
import pandas as pd
import pycountry_convert as pc
from pathlib import Path
from prefect import flow, task, get_run_logger

# ------------------------------------------------------------
# Percorsi
# ------------------------------------------------------------
ROOT       = Path(__file__).parent.parent
DATA_RAW   = ROOT / 'data' / 'processed'
DB_PATH    = ROOT / 'data' / 'processed' / 'remorse.db'
SCHEMA_PATH = ROOT / 'sql' / 'schema.sql'

DINOS_CSV  = DATA_RAW / 'dinos_clean.csv'
PLANTS_CSV = DATA_RAW / 'plants_clean.csv'

# ------------------------------------------------------------
# Classificazioni editoriali (da notebooks/test/analisi.ipynb, Giada)
# ------------------------------------------------------------
MAPPA_CONTINENTE_MANUALE = {
    'UK': 'EU', 'AQ': 'AN', 'TF': 'AN', 'TL': 'AS', 'PN': 'OC', 'EH': 'AF',
}
NOMI_CONTINENTE = {
    'NA': 'Nord America', 'SA': 'Sud America', 'AS': 'Asia',
    'AF': 'Africa', 'OC': 'Oceania', 'EU': 'Europa', 'AN': 'Antartide',
}

FAMIGLIE_CARNIVORE = [
    'tyrannosauridae', 'dromaeosauridae', 'troodontidae', 'abelisauridae',
    'spinosauridae', 'megalosauridae', 'carcharodontosauridae', 'caenagnathidae',
    'ornithomimidae', 'compsognathidae', 'noasauridae', 'therizinosauridae',
]
FAMIGLIE_ERBIVORE = [
    'hadrosauridae', 'ceratopsidae', 'ankylosauridae', 'nodosauridae',
    'diplodocidae', 'titanosauridae', 'camarasauridae', 'stegosauridae',
    'iguanodontidae', 'massospondylidae', 'brachiosauridae', 'thescelosauridae',
    'pachycephalosauridae', 'psittacosauridae', 'protoceratopsidae',
]

# Ordini chiaramente aviani rimasti classificati come Reptilia invece
# che come Aves (residuo del filtro di esclusione a monte)
ORDINI_AVIANI_MASCHERATI = [
    'Galliformes', 'Hesperornithiformes', 'Ichthyornithes', 'Alexornithiformes',
    'Colymbiformes', 'Yanornithiformes', 'Cathayornithiformes',
    'Eoenantiornithiformes', 'Jeholornithiformes',
]


def cc_a_continente(cc: str) -> str:
    if pd.isna(cc):
        return 'Sconosciuto'
    if cc in MAPPA_CONTINENTE_MANUALE:
        return NOMI_CONTINENTE[MAPPA_CONTINENTE_MANUALE[cc]]
    try:
        codice = pc.country_alpha2_to_continent_code(cc)
        return NOMI_CONTINENTE.get(codice, 'Sconosciuto')
    except Exception:
        return 'Sconosciuto'


def raggruppa_ordine(row: pd.Series, top_ordini_piante: list) -> str:
    if row['dataset_type'] == 'Dinosauria':
        return row['order']
    if pd.isna(row['order']):
        return row['order']
    return row['order'] if row['order'] in top_ordini_piante else 'Altro'


def assegna_categoria(row: pd.Series) -> str:
    classe   = str(row.get('class', '')).lower()
    ordine   = str(row.get('order', '')).lower()
    famiglia = str(row.get('family', '')).lower()
    phylum   = str(row.get('phylum', '')).lower()

    if phylum in ('tracheophyta', 'bryophyta', 'pteridophyta') or 'psilophyta' in phylum or 'coniferophyta' in phylum:
        return 'Pianta'
    elif 'magnoliopsida' in classe or 'liliopsida' in classe or 'pinopsida' in classe:
        return 'Pianta'

    if famiglia in FAMIGLIE_CARNIVORE:
        return 'Carnivoro'
    if famiglia in FAMIGLIE_ERBIVORE:
        return 'Erbivoro'

    if 'theropoda' in ordine or 'theropoda' in classe:
        return 'Carnivoro'
    elif 'ornithischia' in classe or 'sauropodomorpha' in ordine or 'sauropoda' in ordine:
        return 'Erbivoro'
    elif 'dinosauria' in classe or 'saurischia' in ordine:
        return 'Erbivoro/Incertezza'
    else:
        return 'Altro/Non Classificato'


# ------------------------------------------------------------
# Task: caricamento CSV
# ------------------------------------------------------------
@task(name="Carica CSV")
def load_csv() -> pd.DataFrame:
    logger = get_run_logger()

    dinos  = pd.read_csv(DINOS_CSV,  low_memory=False)
    plants = pd.read_csv(PLANTS_CSV, low_memory=False)

    df = pd.concat([dinos, plants], ignore_index=True)

    logger.info(f"Dinos:  {len(dinos):,} righe")
    logger.info(f"Plants: {len(plants):,} righe")
    logger.info(f"Totale: {len(df):,} righe")

    return df


# ------------------------------------------------------------
# Task: creazione schema SQLite
# ------------------------------------------------------------
@task(name="Crea schema")
def create_schema(conn: sqlite3.Connection) -> None:
    logger = get_run_logger()

    schema_sql = SCHEMA_PATH.read_text(encoding='utf-8')
    conn.executescript(schema_sql)
    conn.commit()

    logger.info("Schema SQLite creato.")


# ------------------------------------------------------------
# Task: popolamento DIM_collection
# ------------------------------------------------------------
@task(name="Popola DIM_collection")
def populate_dim_collection(df: pd.DataFrame, conn: sqlite3.Connection) -> None:
    logger = get_run_logger()

    dim = (
        df[['collection_no', 'formation', 'geological_group']]
        .drop_duplicates(subset='collection_no')
        .reset_index(drop=True)
    )

    dim.to_sql('DIM_collection', conn, if_exists='append', index=False)
    conn.commit()

    logger.info(f"DIM_collection: {len(dim):,} righe inserite.")


# ------------------------------------------------------------
# Task: popolamento DIM_taxon
# ------------------------------------------------------------
@task(name="Popola DIM_taxon")
def populate_dim_taxon(df: pd.DataFrame, conn: sqlite3.Connection) -> pd.DataFrame:
    logger = get_run_logger()

    cols = ['accepted_name', 'accepted_rank', 'phylum', 'class',
            'order', 'family', 'genus', 'dataset_type']

    dim = (
        df[cols]
        .drop_duplicates()
        .reset_index(drop=True)
    )

    # Ordini piu' frequenti tra le piante, calcolati a livello di
    # occorrenza (non di taxon distinto) per restare fedeli a come
    # sono stati scelti in notebooks/test/analisi.ipynb
    top_ordini_piante = (
        df.loc[df['dataset_type'] == 'Plantae', 'order']
        .value_counts()
        .head(15)
        .index
        .tolist()
    )

    dim['order_raggruppato'] = dim.apply(raggruppa_ordine, axis=1, top_ordini_piante=top_ordini_piante)
    dim['categoria'] = dim.apply(assegna_categoria, axis=1)
    dim['possibile_aviano_residuo'] = dim['order'].isin(ORDINI_AVIANI_MASCHERATI)

    dim.index.name = 'taxon_key'
    dim = dim.reset_index()
    dim['taxon_key'] += 1  # autoincrement parte da 1

    dim.to_sql('DIM_taxon', conn, if_exists='append', index=False)
    conn.commit()

    logger.info(f"DIM_taxon: {len(dim):,} righe inserite.")
    return dim


# ------------------------------------------------------------
# Task: popolamento DIM_location
# ------------------------------------------------------------
@task(name="Popola DIM_location")
def populate_dim_location(df: pd.DataFrame, conn: sqlite3.Connection) -> pd.DataFrame:
    logger = get_run_logger()

    cols = ['lat', 'lng', 'cc', 'state', 'has_valid_coords']

    dim = (
        df[cols]
        .drop_duplicates()
        .reset_index(drop=True)
    )
    dim['continente'] = dim['cc'].apply(cc_a_continente)
    dim.index.name = 'location_key'
    dim = dim.reset_index()
    dim['location_key'] += 1

    dim.to_sql('DIM_location', conn, if_exists='append', index=False)
    conn.commit()

    logger.info(f"DIM_location: {len(dim):,} righe inserite.")
    return dim


# ------------------------------------------------------------
# Task: popolamento DIM_time
# ------------------------------------------------------------
@task(name="Popola DIM_time")
def populate_dim_time(df: pd.DataFrame, conn: sqlite3.Connection) -> pd.DataFrame:
    logger = get_run_logger()

    cols = ['early_interval', 'late_interval', 'period_group']

    dim = (
        df[cols]
        .drop_duplicates()
        .reset_index(drop=True)
    )
    dim.index.name = 'time_key'
    dim = dim.reset_index()
    dim['time_key'] += 1

    dim.to_sql('DIM_time', conn, if_exists='append', index=False)
    conn.commit()

    logger.info(f"DIM_time: {len(dim):,} righe inserite.")
    return dim


# ------------------------------------------------------------
# Task: popolamento FACT_occurrence
# ------------------------------------------------------------
@task(name="Popola FACT_occurrence")
def populate_fact(
    df: pd.DataFrame,
    dim_taxon: pd.DataFrame,
    dim_location: pd.DataFrame,
    dim_time: pd.DataFrame,
    conn: sqlite3.Connection
) -> None:
    logger = get_run_logger()

    # Join per ottenere le chiavi surrogate
    taxon_cols    = ['accepted_name', 'accepted_rank', 'phylum', 'class',
                     'order', 'family', 'genus', 'dataset_type']
    location_cols = ['lat', 'lng', 'cc', 'state', 'has_valid_coords']
    time_cols     = ['early_interval', 'late_interval', 'period_group']

    fact = df.merge(dim_taxon[taxon_cols + ['taxon_key']],
                    on=taxon_cols, how='left')
    fact = fact.merge(dim_location[location_cols + ['location_key']],
                      on=location_cols, how='left')
    fact = fact.merge(dim_time[time_cols + ['time_key']],
                      on=time_cols, how='left')

    fact_final = fact[[
        'occurrence_no', 'collection_no',
        'taxon_key', 'location_key', 'time_key',
        'dataset_type', 'max_ma', 'min_ma', 'mid_ma'
    ]]

    fact_final.to_sql('FACT_occurrence', conn, if_exists='append', index=False)
    conn.commit()

    logger.info(f"FACT_occurrence: {len(fact_final):,} righe inserite.")


# ------------------------------------------------------------
# Task: verifica finale
# ------------------------------------------------------------
@task(name="Verifica database")
def verify_db(conn: sqlite3.Connection) -> None:
    logger = get_run_logger()

    tables = ['DIM_collection', 'DIM_taxon', 'DIM_location', 'DIM_time', 'FACT_occurrence']
    for table in tables:
        count = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        logger.info(f"{table}: {count:,} righe")


# ------------------------------------------------------------
# Flow principale
# ------------------------------------------------------------
@flow(name="REMORSE ETL Pipeline")
def remorse_pipeline():
    logger = get_run_logger()
    logger.info("Avvio pipeline REMORSE...")

    # Rimuovi il database se esiste già (run pulito)
    if DB_PATH.exists():
        DB_PATH.unlink()
        logger.info("Database precedente rimosso.")

    # Caricamento dati
    df = load_csv()

    # Connessione SQLite
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")

    try:
        # Schema
        create_schema(conn)

        # Dimensioni
        populate_dim_collection(df, conn)
        dim_taxon    = populate_dim_taxon(df, conn)
        dim_location = populate_dim_location(df, conn)
        dim_time     = populate_dim_time(df, conn)

        # Fatti
        populate_fact(df, dim_taxon, dim_location, dim_time, conn)

        # Verifica
        verify_db(conn)

    finally:
        conn.close()

    logger.info(f"Pipeline completata. Database: {DB_PATH}")


if __name__ == '__main__':
    remorse_pipeline()
