#!/bin/bash

# Exit on any error
set -e

# Suppress noisy regional access boundary warnings and other non-critical warnings
export CLOUDSDK_CORE_VERBOSITY=error
export GOOGLE_AUTH_TRUST_BOUNDARY_ENABLED=false


# Verify DB_PASSWORD is configured, prompt if missing
if [ -z "$DB_PASSWORD" ]; then
  read -s -p "Enter Database Password (DB_PASSWORD): " DB_PASSWORD
  echo
  if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD is required."
    exit 1
  fi
  export DB_PASSWORD
fi

# Retrieve PROJECT_ID
PROJECT_FILE="$HOME/project_id.txt"
if [ -f "$PROJECT_FILE" ]; then
  PROJECT_ID=$(cat "$PROJECT_FILE" | tr -d '[:space:]')
else
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
fi

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
  echo "Error: Google Cloud Project ID is not set. Please run init.sh first or configure gcloud."
  exit 1
fi

echo "Deploying smart-bookmarks-service to Google Cloud Run..."
echo "Using GCP Project: $PROJECT_ID"
echo "Using Region:      $REGION"

gcloud run deploy smart-bookmarks-service \
  --source "$(dirname "$0")/../service" \
  --region "$REGION"
  --platform managed \
  --allow-unauthenticated \
  --add-cloudsql-instances="$PROJECT_ID:$REGION:smart-bookmarks" \
  --set-env-vars="PROJECT_ID=$PROJECT_ID,INSTANCE_NAME=smart-bookmarks,DB_USER=smart-bookmarks-service,DB_PASSWORD=$DB_PASSWORD,DB_NAME=smart-bookmarks-db"

echo "Deployment complete!"

