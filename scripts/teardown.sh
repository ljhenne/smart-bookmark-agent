#!/bin/bash

# Exit on any error
set -e

echo "Deleting bookmark-service from Google Cloud Run..."

gcloud run services delete bookmark-service \
  --region us-west1 \
  --quiet

echo "Teardown complete! Service removed."
