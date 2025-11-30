# Exemple de tuple :DD 
#<http://dbpedia.org/resource/!!!!!!!> <http://dbpedia.org/ontology/wikiPageWikiLink> <http://dbpedia.org/resource/Category:2019_songs> .
#<http://dbpedia.org/resource/!!!!!!!> <http://dbpedia.org/ontology/wikiPageWikiLink> <http://dbpedia.org/resource/Category:Billie_Eilish_songs> .
#

import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import regexp_extract, col

# CONFIGURATION
BUCKET = "gs://pagerbucket10"
INPUT_FILE = f"{BUCKET}/wikilinks_lang=en.ttl.bz2" 
#INPUT_FILE = f"{BUCKET}/sample_40pct.ttl"# test  

OUTPUT_DIR = f"{BUCKET}/cleaned_data"

def run_preprocess():
    spark = SparkSession.builder.appName("WikiLinksPreprocess").getOrCreate()

    print(f"Lecture de {INPUT_FILE}...")
    # On lit le fichier texte compressé
    raw_df = spark.read.text(INPUT_FILE)

    # Extraction via Regex
    # <URL1> <lien> <URL2>
    parsed_df = raw_df.select(
        regexp_extract('value', r'<([^>]+)>', 1).alias('src_url'),
        regexp_extract('value', r'<([^>]+)>\s+<([^>]+)>', 2).alias('predicate'),
        regexp_extract('value', r'\s+<([^>]+)>\s*\.', 1).alias('dst_url')
    )

    # Filtrage et Nettoyage
    # 1. On garde que les wikiPageWikiLink
    # 2. On ne garde que le titre de la page (après le dernier /) pour économiser la RAM
    clean_df = parsed_df.filter(col("predicate").contains("wikiPageWikiLink")) \
        .select(
            regexp_extract('src_url', r'([^/]+)$', 1).alias('src'),
            regexp_extract('dst_url', r'([^/]+)$', 1).alias('dst')
        )

    # Sauvegarde en format Parquet (rapide à relire)
    print(f"Sauvegarde vers {OUTPUT_DIR}...")
    # On écrase si le dossier existe déjà
    clean_df.write.mode("overwrite").parquet(OUTPUT_DIR)
    
    print("Pré-traitement terminé !")

if __name__ == "__main__":
    run_preprocess()