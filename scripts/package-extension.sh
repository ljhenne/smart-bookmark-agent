#!/bin/bash

# Navigate to the repository root directory
cd "$(dirname "$0")/.."

echo "Packaging Chrome Extension..."

# Check if config.json exists
if [ ! -f "extension/config.json" ]; then
  echo "Error: extension/config.json not found."
  echo "Please create config.json with your API_BASE_URL first (Step 2)."
  exit 1
fi

# Check if build output exists
if [ ! -d "extension/dist" ] || [ ! -f "extension/dist/popup.js" ]; then
  echo "Warning: extension/dist/popup.js not found. Attempting to build..."
  if cd extension && npm install && npm run build && cd ..; then
    echo "Build successful."
  else
    echo "Error: Build failed. Please ensure you have npm installed and run 'npm run build' manually in the extension directory."
    exit 1
  fi
fi

# Zip the extension directory, excluding node_modules
# We save the zip in the root directory.
zip -r extension.zip extension -x "extension/node_modules/*"

echo "=================================================="
echo "Extension packaged successfully as 'extension.zip'!"
echo "=================================================="
echo "To install it on your local machine:"
echo "1. In the Cloud Editor explorer, right-click 'extension.zip' and select 'Download'."
echo "   (Or use the Cloud Shell 'Download' menu option and enter the path: ~/smart-bookmark-agent/extension.zip)"
echo "2. Unzip the downloaded file on your local machine."
echo "3. Go to chrome://extensions/ in Google Chrome."
echo "4. Enable 'Developer mode' (top-right)."
echo "5. Click 'Load unpacked' and select the unzipped 'extension' folder."
echo "=================================================="
