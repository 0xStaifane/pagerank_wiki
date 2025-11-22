from readFile import turtle_to_dataframe
from pyspark import SparkContext

# ==========================
# 1️⃣ Initialiser SparkContext
# ==========================
sc = SparkContext(appName="PageRankRDD")

# ==========================
# 2️⃣ Lire le TTL et créer les RDDs
# ==========================
pandas_df = turtle_to_dataframe("wikilinks_lang=en.ttl.bz2", max_rows=10000)

# Créer un RDD d'arêtes (src, dst)
edges_rdd = sc.parallelize(pandas_df[['subject', 'object']].values.tolist())

# Créer un RDD de voisins par nœud
neighbors = edges_rdd.groupByKey().mapValues(list)  # (src, [dst1, dst2,...])

# Récupérer tous les nœuds uniques
nodes = set(pandas_df['subject']).union(set(pandas_df['object']))
ranks = sc.parallelize([(node, 1.0) for node in nodes])  # (node, rank)

# ==========================
# 3️⃣ PageRank itératif
# ==========================
num_iterations = 10
damping = 0.85

for i in range(num_iterations):
    # Join ranks avec neighbors
    contribs = neighbors.join(ranks) \
        .flatMap(lambda x: [(dst, x[1][1]/len(x[1][0])) for dst in x[1][0]])  # (dst, contrib)
    
    # Somme des contributions par nœud
    ranks = contribs.reduceByKey(lambda a, b: a + b) \
        .mapValues(lambda rank: (1 - damping) + damping * rank)

# ==========================
# 4️⃣ Résultat : top 10 nodes
# ==========================
top10 = ranks.takeOrdered(10, key=lambda x: -x[1])  # tri décroissant
for node, rank in top10:
    print(node, rank)
