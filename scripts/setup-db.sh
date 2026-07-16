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

REGION="us-west1"
INSTANCE_NAME="smart-bookmarks"
DB_NAME="smart-bookmarks-db"
DB_USER="smart-bookmarks-service"

echo "Using GCP Project: $PROJECT_ID"
echo "Using Region:      $REGION"

# 1. Verify Cloud SQL instance exists
echo "Verifying Cloud SQL instance '$INSTANCE_NAME' exists..."
if ! gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Error: Cloud SQL instance '$INSTANCE_NAME' does not exist."
  echo "Please run scripts/create-db-instance.sh first to initialize the database instance."
  exit 1
fi
echo "Cloud SQL instance '$INSTANCE_NAME' verified."

# 2. Create the database (if it doesn't exist)
echo "Checking if database '$DB_NAME' exists..."
if gcloud sql databases describe "$DB_NAME" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Database '$DB_NAME' already exists."
else
  echo "Creating database '$DB_NAME'..."
  gcloud sql databases create "$DB_NAME" \
    --instance="$INSTANCE_NAME" \
    --project="$PROJECT_ID"
fi

# 3. Create database user (if it doesn't exist)
echo "Checking if database user '$DB_USER' exists..."
if gcloud sql users describe "$DB_USER" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Database user '$DB_USER' already exists."
else
  echo "Creating database user '$DB_USER'..."
  gcloud sql users create "$DB_USER" \
    --instance="$INSTANCE_NAME" \
    --password="$DB_PASSWORD" \
    --project="$PROJECT_ID"
fi

# 4. Start the Cloud SQL Auth Proxy to securely connect to the database
# Check if cloud-sql-proxy is available in path, locally, or download it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v cloud-sql-proxy &> /dev/null; then
  PROXY_BIN="cloud-sql-proxy"
elif [ -f "$SCRIPT_DIR/cloud-sql-proxy" ]; then
  PROXY_BIN="$SCRIPT_DIR/cloud-sql-proxy"
else
  echo "Cloud SQL Auth Proxy not found. Downloading..."
  OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH_TYPE=$(uname -m)
  if [ "$ARCH_TYPE" = "x86_64" ]; then
    ARCH_TYPE="amd64"
  elif [ "$ARCH_TYPE" = "arm64" ] || [ "$ARCH_TYPE" = "aarch64" ]; then
    ARCH_TYPE="arm64"
  fi
  PROXY_BIN="$SCRIPT_DIR/cloud-sql-proxy"
  curl -o "$PROXY_BIN" "https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.0/cloud-sql-proxy.${OS_TYPE}.${ARCH_TYPE}"
  chmod +x "$PROXY_BIN"
fi

echo "Starting Cloud SQL Auth Proxy..."
$PROXY_BIN "$PROJECT_ID:$REGION:$INSTANCE_NAME" --port 5432 >/dev/null 2>&1 &
PROXY_PID=$!

# Ensure the proxy is killed on script exit
cleanup() {
  echo "Stopping Cloud SQL Auth Proxy..."
  kill $PROXY_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "Waiting for Cloud SQL Auth Proxy to start..."
sleep 5

# 5. Run scripts/schema.sql to enable the vector extension and create the bookmark table
echo "Initializing database schema via schema.sql..."

# Locate python bin (prefer virtualenv python if it exists)
PYTHON_BIN="python3"
if [ -f "$SCRIPT_DIR/../service/.venv/bin/python" ]; then
  PYTHON_BIN="$SCRIPT_DIR/../service/.venv/bin/python"
elif [ -f "$SCRIPT_DIR/../service/.venv/bin/python3" ]; then
  PYTHON_BIN="$SCRIPT_DIR/../service/.venv/bin/python3"
fi

# Ensure pg8000 is installed
if ! "$PYTHON_BIN" -c "import pg8000" &>/dev/null; then
  echo "Installing pg8000 Python module..."
  "$PYTHON_BIN" -m pip install pg8000 || "$PYTHON_BIN" -m pip install --user pg8000
fi

"$PYTHON_BIN" -c "
import os
import pg8000

db_password = os.environ.get('DB_PASSWORD')
schema_path = os.path.join('$SCRIPT_DIR', 'schema.sql')

try:
    conn = pg8000.dbapi.connect(
        user='$DB_USER',
        password=db_password,
        host='127.0.0.1',
        port=5432,
        database='$DB_NAME'
    )
    cursor = conn.cursor()
    
    with open(schema_path, 'r') as f:
        sql = f.read()
        
    statements = sql.split(';')
    for statement in statements:
        cmd = statement.strip()
        if cmd:
            cursor.execute(cmd)
            
    conn.commit()
    cursor.close()
    conn.close()
    print('Schema initialized successfully.')
except Exception as e:
    print('Error executing schema.sql:', e)
    exit(1)
"

echo "Setup complete!"

