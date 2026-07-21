#!/bin/bash

# Exit on any error
set -e

# Suppress noisy regional access boundary warnings and other non-critical warnings
export CLOUDSDK_CORE_VERBOSITY=error

echo "Deleting smart-bookmarks-service from Google Cloud Run..."

gcloud run services delete smart-bookmarks-service \
  --region "$REGION" \
  --quiet

echo "Teardown complete! Service removed."
