#!/command/with-contenv bash

# Pre-configure qBittorrent to allow localhost API access without authentication
echo "Setting up qBittorrent configuration..."

# Allow optional base path argument for testing
BASE_PATH="${1:-/config}"
CONFIG_DIR="$BASE_PATH/config"
CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Check if config file exists, if not create a minimal one
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating new qBittorrent config file..."
    touch "$CONFIG_FILE"
fi

# Allow localhost API access without authentication
echo "Disabling authentication requirement for localhost..."
# Use sed to set the value. If the section doesn't exist, we'll just append it.
if grep -q "\[Preferences\]" "$CONFIG_FILE"; then
    sed -i '/\[Preferences\]/,/\[/ s/WebUI\\LocalHostAuth=.*/WebUI\\LocalHostAuth=false/' "$CONFIG_FILE"
else
    printf "\n[Preferences]\nWebUI\\LocalHostAuth=false\n" >> "$CONFIG_FILE"
fi

echo "qBittorrent pre-configuration completed"

