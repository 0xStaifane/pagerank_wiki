# pagerank_wiki

#### Echantillon 
Pour tester le pagerank avec un échantillon de 10% : 
```bash
# Décompresse et prend les 1 million premiere lignes et les redirige dans un autre fichier  
bzcat "wikilinks_lang=en.ttl.bz2" | head -n 1000000 > sample_10pct.ttl
# Vérification de la taille du fichier
ls -lh sample_10pct.ttl
```
Envoyer l'echantillon dans le storage : 
```bash
export BUCKET_NAME={Nom de votre bucket} 
gsutil cp sample_10pct.ttl gs://$BUCKET_NAME/
```
#### Lancement de PageRank (Exemple avec DF)

Lancement du cluster avec le nombre de worker choisit 
```bash
#Un cluster avec 2 workers
./scripts/single_node.sh 2w
```
On submit le parser pour nettoyer les datas du wikilink 
```bash
gcloud dataproc jobs submit pyspark --cluster=pagerank-2w --region=europe-west1 ./src/parser.py
```

Submit le pagerank avec l'implémentation DataFrame 
```bash
gcloud dataproc jobs submit pyspark --cluster=pagerank-2w --region=europe-west1 ./src/sparkDF.py
```

### Choix et Optimisation 

##### Pipeline de Données (ETL)

Pré-traitement séparé (parser.py) : Nous avons isolé l'étape de nettoyage des données brutes (.ttl).
        Le parsing des regex et le nettoyage des chaînes de caractères sont coûteux. En sauvegardant le résultat propre au format Parquet, nous accélérons drastiquement les tests itératifs et réduisons l'empreinte mémoire lors du chargement.

##### Stratégie de Partitionnement (Anti-Crash)

Nous avons rencontré de nombreuses erreurs Exit Code 143 (Out Of Memory) lors du passage à l'échelle.
Pour palier a ces prolèmes nous avons fait une augmentation des Partitions : de 20 à 200 partitions.
        Lors de nos anciens essais sur un petit échantillons nous utilisions 20 partitions, chaque tâche devait traiter ~13 millions de liens, ce qui saturait la RAM des workers (15 Go). Avec 200 partitions, les "bouchées" sont plus petites (~1.2M liens) et tiennent en mémoire.

##### Partitionnement par Source (src) :
Essentiel pour respecter la consigne de "éviter le shuffle dans la boucle". En regroupant les liens par URL source dès le début, la structure du graphe reste fixe sur les nœuds. Seuls les scores (ranks) circulent sur le réseau.

##### Gestion de la Mémoire et Robustesse

Persistance Hybride : Utilisation de StorageLevel.MEMORY_AND_DISK au lieu de cache() (MEMORY_ONLY).
Si la RAM est pleine, Spark écrit temporairement sur le disque ("Spill") au lieu de faire planter l'application.
Désactivation du Broadcast Join : spark.sql.autoBroadcastJoinThreshold = -1.
Spark tentait d'envoyer la table des liens à tous les nœuds (Broadcast), provoquant des ClosedByInterruptException. Nous forçons un Shuffle Hash Join ou Sort Merge Join, plus lents mais beaucoup plus robustes pour ce volume de données.

## Résultats 
| Configuration | Temps RDD (s) | Temps DataFrame (s) |
|---------------|---------------|---------------------|
| 2 Noeuds      | 1196.16       | x               |
| 4 Noeuds      | 690.66        | 4342.28                |
| 6 Noeuds      | 493.77        | 2957.57                 |

Vainqueur DATAFRAME : Living_people avec un score de 10637.954559768625 en moyenne

Vainqueur RDD : Living_people avec un score de 10638.03 en moyenne.


### Conclusion 
Malgré le fait que les RDDs offrent un contrôle fin utile pour le partitionnement (crucial pour PageRank), leur surcoût mémoire et CPU en PySpark les rend inadaptés au Big Data moderne par rapport aux DataFrames qui bénéficient du moteur Tungsten et de l'optimiseur Catalyst.
