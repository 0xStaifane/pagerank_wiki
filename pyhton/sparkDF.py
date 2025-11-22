import pandas as pd
import os
from readFile import turtle_to_dataframe

from pyspark.sql import SparkSession
from pyspark.sql import Row
from pyspark.sql.functions import col, lit, sum as spark_sum

# lire un échantillon du fichier
pandas_df = turtle_to_dataframe("wikilinks_lang=en.ttl.bz2", max_rows=20000)
print("Nombre de triples :", len(pandas_df))

log4j_path = os.path.join(os.getcwd(), "log4j.properties")

spark = SparkSession.builder \
    .appName("RDF_PageRank") \
    .config("spark.driver.extraJavaOptions", f"-Dlog4j.configuration=file:{log4j_path}") \
    .getOrCreate()

df = spark.createDataFrame(pandas_df)
df.show(1)
#df.printSchema()


# Construire les arêtes
edges = df.selectExpr("subject as src", "object as dst").distinct()
# Construire les sommets uniques
vertices = edges.select("src").union(edges.select("dst")).distinct().withColumnRenamed("src", "id")


src_degree = edges.groupBy("src").count().withColumnRenamed("count", "src_degree")
edges = edges.join(src_degree, on="src", how="left")

ranks = vertices.withColumn("pagerank", lit(1.0))

num_iterations = 10
damping = 0.85

for i in range(num_iterations):
    # Calculer les contributions
    contribs = edges.join(ranks, edges.src == ranks.id, how="left") \
                    .select(edges.dst.alias("id"), (col("pagerank") / col("src_degree")).alias("contrib"))
    
    # Somme des contributions par nœud
    ranks = contribs.groupBy("id").agg(spark_sum("contrib").alias("pagerank")) \
                    .na.fill(0.0, subset=["pagerank"]) \
                    .withColumn("pagerank", lit((1 - damping)) + damping * col("pagerank"))


ranks.show(10)

top_node = ranks.orderBy(col("pagerank").desc()).limit(1).collect()[0]

# Afficher l'ID et le PageRank complet
print("Top node ID:", top_node["id"])
print("PageRank:", top_node["pagerank"])