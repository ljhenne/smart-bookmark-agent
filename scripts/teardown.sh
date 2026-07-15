#!/bin/bash

# Exit on any error
set -e

echo "Deleting smart-bookmarks-service from Google Cloud Run..."

gcloud run services delete smart-bookmarks-service \
  --region us-west1 \
  --quiet

echo "Teardown complete! Service removed."
