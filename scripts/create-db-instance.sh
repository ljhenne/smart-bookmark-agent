#!/bin/bash

# Exit on any error
set -e

# Suppress noisy regional access boundary warnings and other non-critical warnings
export CLOUDSDK_CORE_VERBOSITY=error
export GOOGLE_AUTH_TRUST_BOUNDARY_ENABLED=false


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


INSTANCE_NAME="smart-bookmarks"

echo "Using GCP Project: $PROJECT_ID"
echo "Using Region:      $REGION"

# Create a Cloud SQL instance (if it doesn't exist)
echo "Checking if Cloud SQL instance '$INSTANCE_NAME' exists..."
if gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Cloud SQL instance '$INSTANCE_NAME' already exists."
else
  echo "Creating Cloud SQL instance '$INSTANCE_NAME' (this may take 5-10 minutes)..."
  gcloud sql instances create "$INSTANCE_NAME" \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region="$REGION" \
    --project="$PROJECT_ID"
fi

echo "Cloud SQL instance '$INSTANCE_NAME' is ready."
