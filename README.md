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
#### Lancement de PageRank

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

