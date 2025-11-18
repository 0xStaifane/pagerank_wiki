#!/usr/bin/env bash
# Script optimisé pour le projet PageRank Wikipedia
# Crée 3 clusters Dataproc avec configurations comparables

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

# Charger les variables d'environnement si .env existe
if [ -f ".env" ]; then
  source .env
fi

# Variables principales
PROJECT_ID="${PROJECT_ID:-YOUR_PROJECT_ID}"
REGION="${REGION:-europe-west1}"
ZONE="${ZONE:-}"  # Laissez vide pour auto-zone
IMAGE_VERSION="${IMAGE_VERSION:-2.1-debian11}"
BUCKET_NAME="${BUCKET_NAME:-pagerank-wikipedia-${PROJECT_ID}}"

# Sécurité
NO_EXTERNAL_IP="${NO_EXTERNAL_IP:-false}"
SUBNET="${SUBNET:-}"

# ============================================
# VALIDATION
# ============================================

if [ "$PROJECT_ID" = "YOUR_PROJECT_ID" ]; then
  echo "❌ Erreur: Veuillez configurer PROJECT_ID dans .env ou en variable d'environnement"
  echo "   Exemple: export PROJECT_ID=mon-projet-gcp"
  exit 1
fi

echo "🔧 Configuration:"
echo "   Project ID: $PROJECT_ID"
echo "   Region: $REGION"
echo "   Bucket: $BUCKET_NAME"
echo ""

# ============================================
# FONCTION: Créer un cluster
# ============================================

create_cluster() {
  local cluster_name=$1
  local num_workers=$2
  local worker_machine_type=$3
  local master_machine_type=$4
  
  echo "📦 Création du cluster: $cluster_name"
  echo "   Workers: $num_workers x $worker_machine_type"
  echo "   Master: 1 x $master_machine_type"
  
  # Construire les arguments optionnels
  local zone_arg=""
  [ -n "$ZONE" ] && zone_arg="--zone=$ZONE"
  
  local subnet_arg=""
  [ -n "$SUBNET" ] && subnet_arg="--subnet=$SUBNET"
  
  local no_address_arg=""
  [ "$NO_EXTERNAL_IP" = true ] && no_address_arg="--no-address"
  
  # Créer le cluster
  gcloud dataproc clusters create "$cluster_name" \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    $zone_arg \
    $subnet_arg \
    --master-machine-type="$master_machine_type" \
    --worker-machine-type="$worker_machine_type" \
    --num-workers="$num_workers" \
    --image-version="$IMAGE_VERSION" \
    --bucket="$BUCKET_NAME" \
    --enable-component-gateway \
    --properties="spark:spark.executor.memory=6g,spark:spark.driver.memory=4g,spark:spark.default.parallelism=$((num_workers * 4 * 2)),spark:spark.sql.shuffle.partitions=$((num_workers * 4 * 2))" \
    $no_address_arg
  
  if [ $? -eq 0 ]; then
    echo "   ✅ Cluster $cluster_name créé avec succès"
  else
    echo "   ❌ Erreur lors de la création de $cluster_name"
    return 1
  fi
  echo ""
}

# ============================================
# FONCTION: Créer le bucket GCS
# ============================================

create_bucket() {
  echo "Création du bucket GCS: $BUCKET_NAME"
  
  # Vérifier si le bucket existe déjà
  if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
    echo "Le bucket existe déjà"
  else
    gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://$BUCKET_NAME"
    echo "   ✅ Bucket créé avec succès"
  fi
  echo ""
}

# ============================================
# FONCTION: Afficher les informations
# ============================================

show_info() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ TOUS LES CLUSTERS SONT CRÉÉS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Résumé des ressources:"
  echo ""
  echo "Cluster 1: pagerank-2w"
  echo "   └─ 2 workers  n1-standard-8 (8 vCPU, 30 GB) = 16 vCPU"
  echo "   └─ 1 master  n1-standard-4 (4 vCPU, 15 GB) = 4 vCPU"
  echo "   └─ TOTAL: 20 vCPU, 75 GB RAM"
  echo ""
  echo "Cluster 2: pagerank-4w"
  echo "   └─ 4 workers  n1-standard-4 (4 vCPU, 15 GB) = 16 vCPU"
  echo "   └─ 1 master   n1-standard-4 (4 vCPU, 15 GB) = 4 vCPU"
  echo "   └─ TOTAL: 20 vCPU, 75 GB RAM"
  echo ""
  echo "Cluster 3: pagerank-6w"
  echo "   └─ 6 workers  n1-standard-4 (4 vCPU, 15 GB) = 24 vCPU"
  echo "   └─ 1 master   n1-standard-4 (4 vCPU, 15 GB) = 4 vCPU"
  echo "   └─ TOTAL: 28 vCPU, 105 GB RAM"
  echo ""
  echo "📦 Bucket GCS: gs://$BUCKET_NAME"
  echo ""
  echo "🔗 Liens utiles:"
  echo "   • Console GCP: https://console.cloud.google.com/dataproc/clusters?project=$PROJECT_ID"
  echo "   • Bucket GCS:  https://console.cloud.google.com/storage/browser/$BUCKET_NAME?project=$PROJECT_ID"
  echo ""
  echo "💡 Prochaines étapes:"
  echo "   1. Télécharger les données Wikipedia"
  echo "   2. Uploader vers GCS: gsutil cp data.bz2 gs://$BUCKET_NAME/"
  echo "   3. Lancer les jobs PageRank sur chaque cluster"
  echo ""
  echo "🗑️  Pour supprimer les clusters:"
  echo "   ./destroy_clusters.sh"
  echo ""
}

# ============================================
# MAIN
# ============================================

main() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 CRÉATION DE L'INFRASTRUCTURE PAGERANK"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Étape 1: Créer le bucket
  create_bucket
  
  # Étape 2: Créer les 3 clusters
  echo "Création des clusters Dataproc..."
  echo "Cela peut prendre qlq minutes"
  echo ""
  
  # Configuration 1: 2 workers puissants
  create_cluster "pagerank-2w" 2 "n1-standard-8" "n1-standard-4"
  
  # Configuration 2: 4 workers moyens
  create_cluster "pagerank-4w" 4 "n1-standard-4" "n1-standard-4"
  
  # Configuration 3: 6 workers moyens
  create_cluster "pagerank-6w" 6 "n1-standard-4" "n1-standard-4"
  
  # Afficher le résumé
  show_info
}

# ============================================
# EXÉCUTION
# ============================================

# Confirmation avant création
read -p "Créer 3 clusters Dataproc (coût ~$1-2/heure total)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  main
else
  echo "Opération annulée"
  exit 0
fi