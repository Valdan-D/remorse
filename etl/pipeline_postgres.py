"""
REMORSE — ETL Pipeline (PostgreSQL / Supabase)
Reptilian Evaluation of Mesozoic Origins: Retrospective Study on Extinction

Legge i dataset puliti e popola lo star schema su Supabase (PostgreSQL).
Lo schema deve essere gia stato creato eseguendo sql/schema_postgresql.sql
nel SQL Editor di Supabase.

Utilizzo:
    python etl/pipeline_postgres.py

Richiede la variabile d'ambiente DATABASE_URL, ad esempio in un file .env:
    DATABASE_URL=postgresql://postgres:PASSWORD@db.xxxx.supabase.co:5432/postgres
"""

import os
import pandas as pd
import pycountry_convert as pc
from pathlib import Path
from sqlalchemy import create_engine
from dotenv import load_dotenv
from prefect import flow, task, get_run_logger

load_dotenv()

# ------------------------------------------------------------
# Percorsi e configurazione
# ------------------------------------------------------------
ROOT     = Path(__file__).parent.parent
DATA_DIR = ROOT / 'data' / 'processed'

DINOS_CSV  = DATA_DIR / 'dinos_clean.csv'
PLANTS_CSV = DATA_DIR / 'plants_clean.csv'

DATABASE_URL = os.getenv('DATABASE_URL')

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
        return row['taxon_order']
    if pd.isna(row['taxon_order']):
        return row['taxon_order']
    return row['taxon_order'] if row['taxon_order'] in top_ordini_piante else 'Altro'


def assegna_categoria(row: pd.Series) -> str:
    classe   = str(row.get('class', '')).lower()
    ordine   = str(row.get('taxon_order', '')).lower()
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
@task(name="Carica CSV", cache_policy=None)
def load_csv() -> pd.DataFrame:
    logger = get_run_logger()

    dinos  = pd.read_csv(DINOS_CSV,  low_memory=False)
    plants = pd.read_csv(PLANTS_CSV, low_memory=False)

    df = pd.concat([dinos, plants], ignore_index=True)

    # Rinomina 'order' -> 'taxon_order' (parola riservata in SQL)
    df = df.rename(columns={'order': 'taxon_order'})

    logger.info(f"Dinos:  {len(dinos):,} righe")
    logger.info(f"Plants: {len(plants):,} righe")
    logger.info(f"Totale: {len(df):,} righe")

    return df


# ------------------------------------------------------------
# Task: popolamento dim_collection
# ------------------------------------------------------------
@task(name="Popola dim_collection", cache_policy=None)
def populate_dim_collection(df: pd.DataFrame, engine) -> None:
    logger = get_run_logger()

    dim = (
        df[['collection_no', 'formation', 'geological_group']]
        .drop_duplicates(subset='collection_no')
        .reset_index(drop=True)
    )

    dim.to_sql('dim_collection', engine, if_exists='append', index=False, method='multi', chunksize=1000)

    logger.info(f"dim_collection: {len(dim):,} righe inserite.")


# ------------------------------------------------------------
# Task: popolamento dim_taxon
# ------------------------------------------------------------
@task(name="Popola dim_taxon", cache_policy=None)
def populate_dim_taxon(df: pd.DataFrame, engine) -> pd.DataFrame:
    logger = get_run_logger()

    cols = ['accepted_name', 'accepted_rank', 'phylum', 'class',
            'taxon_order', 'family', 'genus', 'dataset_type']

    dim = (
        df[cols]
        .drop_duplicates()
        .reset_index(drop=True)
    )

    # Ordini piu' frequenti tra le piante, calcolati a livello di
    # occorrenza (non di taxon distinto) per restare fedeli a come
    # sono stati scelti in notebooks/test/analisi.ipynb
    top_ordini_piante = (
        df.loc[df['dataset_type'] == 'Plantae', 'taxon_order']
        .value_counts()
        .head(15)
        .index
        .tolist()
    )

    dim['order_raggruppato'] = dim.apply(raggruppa_ordine, axis=1, top_ordini_piante=top_ordini_piante)
    dim['categoria'] = dim.apply(assegna_categoria, axis=1)
    dim['possibile_aviano_residuo'] = dim['taxon_order'].isin(ORDINI_AVIANI_MASCHERATI)

    dim.index.name = 'taxon_key'
    dim = dim.reset_index()
    dim['taxon_key'] += 1

    dim.to_sql('dim_taxon', engine, if_exists='append', index=False, method='multi', chunksize=1000)

    logger.info(f"dim_taxon: {len(dim):,} righe inserite.")
    return dim


# ------------------------------------------------------------
# Task: popolamento dim_location
# ------------------------------------------------------------
@task(name="Popola dim_location", cache_policy=None)
def populate_dim_location(df: pd.DataFrame, engine) -> pd.DataFrame:
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

    dim.to_sql('dim_location', engine, if_exists='append', index=False, method='multi', chunksize=1000)

    logger.info(f"dim_location: {len(dim):,} righe inserite.")
    return dim


# ------------------------------------------------------------
# Task: popolamento dim_time
# ------------------------------------------------------------
@task(name="Popola dim_time", cache_policy=None)
def populate_dim_time(df: pd.DataFrame, engine) -> pd.DataFrame:
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

    dim.to_sql('dim_time', engine, if_exists='append', index=False, method='multi', chunksize=1000)

    logger.info(f"dim_time: {len(dim):,} righe inserite.")
    return dim


# ------------------------------------------------------------
# Task: popolamento fact_occurrence
# ------------------------------------------------------------
@task(name="Popola fact_occurrence", cache_policy=None)
def populate_fact(
    df: pd.DataFrame,
    dim_taxon: pd.DataFrame,
    dim_location: pd.DataFrame,
    dim_time: pd.DataFrame,
    engine
) -> None:
    logger = get_run_logger()

    taxon_cols    = ['accepted_name', 'accepted_rank', 'phylum', 'class',
                     'taxon_order', 'family', 'genus', 'dataset_type']
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

    # Inserimento a blocchi per non sovraccaricare la connessione
    fact_final.to_sql('fact_occurrence', engine, if_exists='append',
                       index=False, method='multi', chunksize=1000)

    logger.info(f"fact_occurrence: {len(fact_final):,} righe inserite.")


# ------------------------------------------------------------
# Task: verifica finale
# ------------------------------------------------------------
@task(name="Verifica database", cache_policy=None)
def verify_db(engine) -> None:
    logger = get_run_logger()

    tables = ['dim_collection', 'dim_taxon', 'dim_location', 'dim_time', 'fact_occurrence']
    with engine.connect() as conn:
        for table in tables:
            count = conn.exec_driver_sql(f"SELECT COUNT(*) FROM {table}").scalar()
            logger.info(f"{table}: {count:,} righe")


# ------------------------------------------------------------
# Flow principale
# ------------------------------------------------------------
@flow(name="REMORSE ETL Pipeline - PostgreSQL")
def remorse_pipeline_postgres():
    logger = get_run_logger()
    logger.info("Avvio pipeline REMORSE (PostgreSQL/Supabase)...")

    if not DATABASE_URL:
        raise ValueError(
            "DATABASE_URL non trovata. Crea un file .env nella root del repo con:\n"
            "DATABASE_URL=postgresql://postgres:PASSWORD@db.xxxx.supabase.co:5432/postgres"
        )

    engine = create_engine(DATABASE_URL)

    df = load_csv()

    populate_dim_collection(df, engine)
    dim_taxon    = populate_dim_taxon(df, engine)
    dim_location = populate_dim_location(df, engine)
    dim_time     = populate_dim_time(df, engine)

    populate_fact(df, dim_taxon, dim_location, dim_time, engine)

    verify_db(engine)

    logger.info("Pipeline completata.")


if __name__ == '__main__':
    remorse_pipeline_postgres()
