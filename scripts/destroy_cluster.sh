#!/usr/bin/env bash
# Supprime tous les clusters PageRank

set -euo pipefail

if [ -f ".env" ]; then
  source .env
fi

PROJECT_ID="${PROJECT_ID:-YOUR_PROJECT_ID}"
REGION="${REGION:-europe-west1}"

echo " Suppression des clusters PageRank..."
echo ""

for cluster in pagerank-2w pagerank-4w pagerank-6w; do
  echo "Suppression de $cluster..."
  if gcloud dataproc clusters delete "$cluster" \
      --project="$PROJECT_ID" \
      --region="$REGION" \
      --quiet; then
    echo "  $cluster supprimé"
  else
    echo "  $cluster n'existe pas ou erreur"
  fi
done

echo ""
echo " Nettoyage terminé"
echo ""
read -p "Supprimer aussi le bucket GCS? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  BUCKET_NAME="pagerank-wikipedia-${PROJECT_ID}"
  echo "🗑️  Suppression de gs://$BUCKET_NAME..."
  gsutil -m rm -r "gs://$BUCKET_NAME" || echo "Bucket déjà supprimé !!"
fi