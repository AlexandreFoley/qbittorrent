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

# Function to set a value in config file (ini format)
# set_config_value section key value
set_config_value() {
    local section="$1"
    local key="$2"
    local value="$3"
    local tmpfile="${CONFIG_FILE}.tmp"
    
    # Check if section exists
    if ! grep -q "^\[$section\]" "$CONFIG_FILE"; then
        printf '\n[%s]\n' "$section" >> "$CONFIG_FILE"
    fi
    
    # Use pure bash to avoid awk's backslash escaping issues
    local in_section=0
    local found=0
    local insert_line=-1
    local line_num=0
    
    # First pass: find where to insert and check if key exists
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [ "$line" = "[$section]" ]; then
            in_section=1
        elif [ $in_section -eq 1 ] && [[ "$line" =~ ^\[ ]]; then
            # Hit next section
            insert_line=$((line_num - 1))
            break
        elif [ $in_section -eq 1 ] && [ "$line" = "${key}=${value}" ]; then
            # Key already has correct value, nothing to do
            found=2
            break
        elif [ $in_section -eq 1 ] && [[ "$line" == "${key}="* ]]; then
            # Key exists but value is different - need to update
            found=1
            break
        elif [ $in_section -eq 1 ] && [ -n "$line" ]; then
            # Line in section
            insert_line=$line_num
        fi
    done < "$CONFIG_FILE"
    
    # If we're at EOF in section
    if [ $in_section -eq 1 ] && [ $insert_line -eq -1 ]; then
        insert_line=$line_num
    fi
    
    # If key already correct, do nothing
    if [ $found -eq 2 ]; then
        return 0
    fi
    
    # Now rebuild the file
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [ $found -eq 1 ] && [[ "$line" == "${key}="* ]]; then
            # Replace this line
            printf '%s=%s\n' "$key" "$value"
            found=0
        elif [ $line_num -eq $insert_line ] && [ $found -eq 0 ]; then
            # Insert after this line
            printf '%s\n' "$line"
            printf '%s=%s\n' "$key" "$value"
        else
            printf '%s\n' "$line"
        fi
    done < "$CONFIG_FILE" > "$tmpfile"
    
    mv "$tmpfile" "$CONFIG_FILE"
}

# Allow localhost API access without authentication
echo "Disabling authentication requirement for localhost..."
set_config_value "Preferences" 'WebUI\LocalHostAuth' "false"

# Set ownership to hotio user if it exists
if id hotio &>/dev/null; then
    chown -R hotio:hotio $BASE_PATH
fi

echo "qBittorrent pre-configuration completed"

