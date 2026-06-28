#!/command/with-contenv bash

# Configure qBittorrent based on environment variables
# This runs after qBittorrent service has started

echo "Configuring qBittorrent from environment variables..."

# Wait for qBittorrent to be fully ready
echo "Waiting for qBittorrent to be ready..."
WEBUI_PORT="${WEBUI_PORTS%%/*}"  # Extract port number from WEBUI_PORTS (e.g., "8080/tcp" -> "8080")
WEBUI_PORT="${WEBUI_PORT:-8080}"  # Default to 8080 if not set
RETRY_INTERVAL=1
if [[ "${VPN_ENABLED}" == "true" ]] && [[ "${VPN_AUTO_PORT_FORWARD}" != "false" ]]; then
    RETRY_INTERVAL=5
    echo "VPN port forwarding enabled, checking qBittorrent readiness every ${RETRY_INTERVAL} seconds"
fi

MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:${WEBUI_PORT}/api/v2/app/webapiVersion > /dev/null 2>&1; then
        echo "qBittorrent is ready"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "qBittorrent not ready yet, retrying in ${RETRY_INTERVAL} second(s)... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep "$RETRY_INTERVAL"
    fi
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "Warning: qBittorrent did not become ready after $((MAX_ATTEMPTS * RE_INTERVAL)) seconds"
fi

# Create download directory if specified and doesn't exist
if [ -n "$DOWNLOAD_FOLDER" ]; then
    if [ ! -d "$DOWNLOAD_FOLDER" ]; then
        echo "Creating download directory: $DOWNLOAD_FOLDER"
        mkdir -p "$DOWNLOAD_FOLDER"
        chmod 777 "$DOWNLOAD_FOLDER"
    fi
fi

# Build JSON preferences from environment variables using jq
# Handle UPnP logic from upstream
UPNP_VALUE="${QBITTORRENT_UPNP:-false}"
case "${UPNP_VALUE,,}" in
    true|1|yes|on)
        UPNP_JSON_VALUE=true
        ;;
    false|0|no|off|"")
        UPNP_JSON_VALUE=false
        ;;
    *)
        echo "Warning: invalid QBITTORRENT_UPNP value '$UPNP_VALUE', defaulting to false"
        UPNP_JSON_VALUE=false
        ;;
esac

# Generate random password if WEBUI_PASSWORD is empty
if [ -z "${WEBUI_PASSWORD}" ]; then
    PASS=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 12)
else
    PASS="$WEBUI_PASSWORD"
fi

PREFS_JSON=$(jq -n \
    --arg user "${WEBUI_USERNAME:-admin}" \
    --arg pass "$PASS" \
    --arg path "${DOWNLOAD_FOLDER:-/media/torrents}" \
    --argjson upnp "$UPNP_JSON_VALUE" \
    '{web_ui_username: $user, web_ui_password: $pass, save_path: $path, upnp: $upnp}')

# Apply settings via API if we have any
if [ "$PREFS_JSON" != "{}" ] && [ "$PREFS_JSON" != "null" ]; then
    echo "Applying settings to qBittorrent..."
    echo "Settings JSON: $PREFS_JSON"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST http://localhost:${WEBUI_PORT}/api/v2/app/setPreferences \
        --data "json=$PREFS_JSON")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$RESPONSE" | head -n-1)
    
    echo "API Response Code: $HTTP_CODE"
    echo "API Response Body: $RESPONSE_BODY"
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "✓ Configuration applied successfully"
    else
        echo "✗ Configuration failed with HTTP $HTTP_CODE"
        echo "Response: $RESPONSE_BODY"
    fi
else
    echo "No environment variables set, skipping configuration"
fi

echo "qBittorrent configuration completed"