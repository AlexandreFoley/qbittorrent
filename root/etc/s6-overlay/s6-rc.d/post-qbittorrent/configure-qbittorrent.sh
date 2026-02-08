#!/command/with-contenv bash

# Configure qBittorrent based on environment variables
# This runs after qBittorrent service has started

echo "Configuring qBittorrent from environment variables..."

# Wait for qBittorrent to be fully ready
echo "Waiting for qBittorrent to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:8080/api/v2/app/webapiVersion > /dev/null 2>&1; then
        echo "qBittorrent is ready"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "qBittorrent not ready yet, retrying in 1 second... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep 1
    fi
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "Warning: qBittorrent did not become ready after ${MAX_ATTEMPTS} seconds"
fi

# Create download directory if specified and doesn't exist
if [ -n "$DOWNLOAD_FOLDER" ]; then
    if [ ! -d "$DOWNLOAD_FOLDER" ]; then
        echo "Creating download directory: $DOWNLOAD_FOLDER"
        mkdir -p "$DOWNLOAD_FOLDER"
        chmod 777 "$DOWNLOAD_FOLDER"
    fi
fi

# Build JSON preferences from environment variables
PREFS_JSON="{"

# WebUI Username
if [ -n "$WEBUI_USERNAME" ]; then
    PREFS_JSON="${PREFS_JSON}\"web_ui_username\":\"${WEBUI_USERNAME}\","
fi

# WebUI Password
if [ -n "$WEBUI_PASSWORD" ]; then
    PREFS_JSON="${PREFS_JSON}\"web_ui_password\":\"${WEBUI_PASSWORD}\","
fi

# Download folder
if [ -n "$DOWNLOAD_FOLDER" ]; then
    PREFS_JSON="${PREFS_JSON}\"save_path\":\"${DOWNLOAD_FOLDER}\","
fi

# Remove trailing comma and close JSON
PREFS_JSON="${PREFS_JSON%,}}"

# Apply settings via API if we have any
if [ "$PREFS_JSON" != "{}" ]; then
    echo "Applying settings to qBittorrent..."
    echo "Settings JSON: $PREFS_JSON"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/api/v2/app/setPreferences \
        --data "json=${PREFS_JSON}")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$RESPONSE" | head -n-1)
    
    echo "API Response Code: $HTTP_CODE"
    echo "API Response Body: $RESPONSE_BODY"
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "✓ Configuration applied successfully"
    else
        echo "✗ Configuration failed with HTTP $HTTP_CODE"
        echo "Response: $RESPONSE_BODY"
        # exit 1
    fi
else
    echo "No environment variables set, skipping configuration"
fi

echo "qBittorrent configuration completed"
