import pandas as pd
import psycopg2
import os
from io import StringIO
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "soumiatech_db")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "votre_mot_de_passe")
FILE_PATH = "soumiaTech_orders_export.csv.xlsx"

def ingest_data():
    try:
        print(f"--- Dmarrage de l'ingestion de {FILE_PATH} ---")
        
        # 1. Lecture du fichier Excel
        df = pd.read_excel(FILE_PATH)
        
        # S'assurer que toutes les colonnes sont traites comme du texte pour le staging
        df = df.astype(str)
        # Remplacer 'nan' par None (NULL en SQL)
        df = df.replace('nan', None)
        df = df.replace('None', None)

        # 2. Connexion  PostgreSQL
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cur = conn.cursor()

        # 3. Vider la table de staging
        cur.execute("TRUNCATE TABLE staging_orders;")
        
        # 4. Ingestion massive via COPY (ultra-rapide)
        # On utilise un buffer StringIO pour simuler un fichier CSV
        output = StringIO()
        df.to_csv(output, sep='\t', header=False, index=False)
        output.seek(0)
        
        cur.copy_from(output, 'staging_orders', sep='\t', null='')
        
        conn.commit()
        print(f"Succs : {len(df)} lignes insres dans staging_orders.")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"ERREUR lors de l'ingestion : {e}")
        exit(1)

if __name__ == "__main__":
    ingest_data()
