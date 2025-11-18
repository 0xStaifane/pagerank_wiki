#!/usr/bin/env bash
# Crée un cluster minimal single-node pour tester

set -euo pipefail

if [ -f ".env" ]; then
  source .env
fi

PROJECT_ID="${PROJECT_ID:-YOUR_PROJECT_ID}"
REGION="${REGION:-europe-west1}"
BUCKET_NAME="${BUCKET_NAME:-pagerbucket10}"

echo "🔍 Vérification du bucket GCS..."

# Créer le bucket s'il n'existe pas
if gsutil ls -b "gs://$BUCKET_NAME" &>/dev/null; then
  echo "   ✅ Bucket gs://$BUCKET_NAME existe déjà"
else
  echo "   📦 Création du bucket gs://$BUCKET_NAME..."
  gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://$BUCKET_NAME"
  echo "   ✅ Bucket créé avec succès"
fi

echo ""
echo "🧪 Création d'un cluster de TEST (single-node)..."

gcloud dataproc clusters create pagerank-test \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --single-node \
  --master-machine-type=n1-standard-4 \
  --image-version=2.1-debian11 \
  --bucket="$BUCKET_NAME"

echo ""
echo "✅ Cluster de test créé: pagerank-test"
echo ""
echo "Testez votre code PageRank sur ce cluster avec 10% des données"
echo ""
echo "Pour check la liste de cluster : gcloud dataproc clusters list --region=europe-west1"
echo ""
echo "Pour supprimer: gcloud dataproc clusters delete pagerank-test --region=europe-west1 --quiet"