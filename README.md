# pagerank_wiki

#### Echantillon 
Pour tester le pagerank avec un échantillon de 10% : 
```bash
# Décompresse et prend les 1 million premiere lignes et les redirige dans un autre fichier  
bzcat "wikilinks_lang=en.ttl.bz2" | head -n 1000000 > sample_10pct.ttl
# Vérification de la taille du fichier
ls -lh sample_10pct.ttl
