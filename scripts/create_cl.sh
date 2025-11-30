#!/usr/bin/env bash
# Script adapté pour créer UN cluster PageRank à la fois
# Usage: ./create_single_cluster.sh [2w|4w|6w]

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================

if [ -f ".env" ]; then
  source .env
fi

PROJECT_ID="${PROJECT_ID}"
REGION="${REGION}"
ZONE="${ZONE}"
IMAGE_VERSION="${IMAGE_VERSION:-2.1-debian11}"
BUCKET_NAME="${BUCKET_NAME}"
NETWORK="${NETWORK:-default}"

# ============================================
# VALIDATION
# ============================================

# Vérifier les arguments
if [ $# -eq 0 ]; then
  echo "Mauvais argument, usage: $0 [2w|4w|6w]"
  echo ""
  echo "Exemples:"
  echo "  $0 2w    # Crée le cluster avec 2 workers (n1-standard-8)"
  echo "  $0 4w    # Crée le cluster avec 4 workers (n1-standard-4)"
  echo "  $0 6w    # Crée le cluster avec 6 workers (n1-standard-4)"
  exit 1
fi

CLUSTER_TYPE=$1

# ============================================
# CONFIGURATION PAR TYPE DE CLUSTER
# ============================================

case $CLUSTER_TYPE in
  2w)
    CLUSTER_NAME="pagerank-2w"
    NUM_WORKERS=2
    WORKER_MACHINE="n1-standard-8"
    MASTER_MACHINE="n1-standard-4"
    WORKER_DISK_SIZE=500
    MASTER_DISK_SIZE=500
    TOTAL_CPU=20
    TOTAL_DISK=1500
    ;;
  4w)
    CLUSTER_NAME="pagerank-4w"
    NUM_WORKERS=4
    WORKER_MACHINE="n1-standard-2" 
    MASTER_MACHINE="n1-standard-2" 
    WORKER_DISK_SIZE=200
    MASTER_DISK_SIZE=200
    TOTAL_CPU=10
    TOTAL_DISK=1000
    ;;
  6w)
    CLUSTER_NAME="pagerank-6w"
    NUM_WORKERS=6
    WORKER_MACHINE="n1-standard-1"  
    MASTER_MACHINE="n1-standard-2"
    WORKER_DISK_SIZE=150
    MASTER_DISK_SIZE=200
    TOTAL_CPU=8
    TOTAL_DISK=1100
    ;;
  *)
    echo "Type de cluster invalide: $CLUSTER_TYPE"
    echo "Utiliser: 2w, 4w, ou 6w"
    exit 1
    ;;
esac

# ============================================
# CRÉATION DU CLUSTER
# ============================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 CRÉATION DU CLUSTER: $CLUSTER_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Configuration:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Workers: $NUM_WORKERS x $WORKER_MACHINE"
echo "   Master: 1 x $MASTER_MACHINE"
echo "   CPU total: ~$TOTAL_CPU vCPU"
echo "   Disque total: ~$TOTAL_DISK GB"
echo ""

# On vérifie si le cluster existe déjà
if gcloud dataproc clusters describe "$CLUSTER_NAME" \
    --project="$PROJECT_ID" \
    --region="$REGION" &>/dev/null; then
  echo " Le cluster $CLUSTER_NAME existe déjà!"
  echo ""
  read -p "Supprimer et recréer? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo " Suppression de l'ancien cluster..."
    gcloud dataproc clusters delete "$CLUSTER_NAME" \
      --project="$PROJECT_ID" \
      --region="$REGION" \
      --quiet
    echo " Ancien cluster supprimé"
  else
    echo "Opération annulée"
    exit 0
  fi
fi

echo "Création en cours (Qlq minutes)..."
echo ""

gcloud dataproc clusters create "$CLUSTER_NAME" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --zone="$ZONE" \
  --network="$NETWORK" \
  --master-machine-type="$MASTER_MACHINE" \
  --master-boot-disk-size="$MASTER_DISK_SIZE" \
  --worker-machine-type="$WORKER_MACHINE" \
  --worker-boot-disk-size="$WORKER_DISK_SIZE" \
  --num-workers="$NUM_WORKERS" \
  --image-version="$IMAGE_VERSION" \
  --bucket="$BUCKET_NAME" \
  --enable-component-gateway \
  --properties="spark:spark.executor.memory=3g,spark:spark.driver.memory=2g,spark:spark.default.parallelism=$((NUM_WORKERS * 2 * 2)),spark:spark.sql.shuffle.partitions=$((NUM_WORKERS * 2 * 2))"

if [ $? -eq 0 ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CLUSTER CRÉÉ AVEC SUCCÈS :D"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " N'oubliez pas de supprimer le cluster après vos tests!"
  echo ""
else
  echo ""
  echo "Erreur lors de la création du cluster"
  exit 1
fi