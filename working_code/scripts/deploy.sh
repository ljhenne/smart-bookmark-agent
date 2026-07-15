#!/bin/bash

# Exit on any error
set -e

# Verify DB_PASSWORD is configured
if [ -z "$DB_PASSWORD" ]; then
  echo "Error: DB_PASSWORD environment variable is not set."
  echo "Please export DB_PASSWORD before running this script, or run it like:"
  echo "  DB_PASSWORD=your_db_password_here ./deploy.sh"
  exit 1
fi

echo "Deploying bookmark-service to Google Cloud Run..."

gcloud run deploy bookmark-service \
  --source "$(dirname "$0")" \
  --region us-west1 \
  --platform managed \
  --allow-unauthenticated \
  --add-cloudsql-instances=ljhenne-joonix-sandbox:us-west1:bookmark-instance \
  --set-env-vars="PROJECT_ID=ljhenne-joonix-sandbox,REGION=us-west1,INSTANCE_NAME=bookmark-instance,DB_USER=bookmark-user,DB_PASSWORD=$DB_PASSWORD,DB_NAME=bookmarks-db"

echo "Deployment complete!"
