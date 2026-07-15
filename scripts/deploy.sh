#!/bin/bash

# Exit on any error
set -e

# Verify GEMINI_API_KEY is configured
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Please export GEMINI_API_KEY before running this script, or run it like:"
  echo "  GEMINI_API_KEY=your_api_key_here ./deploy.sh"
  exit 1
fi

# Verify DB_PASSWORD is configured
if [ -z "$DB_PASSWORD" ]; then
  echo "Error: DB_PASSWORD environment variable is not set."
  echo "Please export DB_PASSWORD before running this script, or run it like:"
  echo "  DB_PASSWORD=your_db_password_here ./deploy.sh"
  exit 1
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

gcloud run deploy smart-bookmarks-service \
  --source "$(dirname "$0")/../service" \
  --region us-west1 \
  --platform managed \
  --allow-unauthenticated \
  --add-cloudsql-instances="$PROJECT_ID:us-west1:smart-bookmarks" \
  --set-env-vars="PROJECT_ID=$PROJECT_ID,REGION=us-west1,INSTANCE_NAME=smart-bookmarks,DB_USER=smart-bookmarks-service,DB_PASSWORD=$DB_PASSWORD,DB_NAME=smart-bookmarks-db,GEMINI_API_KEY=$GEMINI_API_KEY"

echo "Deployment complete!"

