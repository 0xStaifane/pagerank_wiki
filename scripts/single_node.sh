#!/usr/bin/env bash
# Crée un cluster minimal single-node pour tester

set -euo pipefail

if [ -f ".env" ]; then
  source .env
fi

PROJECT_ID="${PROJECT_ID:-YOUR_PROJECT_ID}"
REGION="${REGION:-europe-west1}"
BUCKET_NAME="${BUCKET_NAME:-pagerank-wikipedia-${PROJECT_ID}}"

echo "🧪 Création d'un cluster de TEST (single-node)..."

gcloud dataproc clusters create pagerank-test \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --single-node \
  --machine-type=n1-standard-4 \
  --image-version=2.1-debian11 \
  --bucket="$BUCKET_NAME"

echo ""
echo "Cluster de test créé: pagerank-test"
echo ""
echo "Testez votre code PageRank sur ce cluster avec 10% des données"
echo ""
echo "Pour supprimer: gcloud dataproc clusters delete pagerank-test --region=$REGION --quiet"