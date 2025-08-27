#!/bin/bash

# EmuDeck Save Sync - Configuration Transfer Helper
# Use this if you want to transfer your existing Nextcloud configuration to a new machine

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 EmuDeck Save Sync - Configuration Transfer${NC}"
echo "============================================="

echo "This script helps transfer your Nextcloud configuration to a new machine."
echo "You'll need your Nextcloud server details that were configured previously."
echo

# Check if configuration already exists
if [ -f "$HOME/.config/emudeck-sync/config.conf" ]; then
    echo -e "${YELLOW}⚠️  Existing configuration found${NC}"
    echo "Current configuration:"
    cat "$HOME/.config/emudeck-sync/config.conf"
    echo
    read -p "Do you want to reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing configuration."
        exit 0
    fi
fi

echo
echo "Please enter your Nextcloud details:"

# Get Nextcloud URL
while true; do
    read -p "Nextcloud server URL: " nextcloud_url
    if [[ "$nextcloud_url" =~ ^https?:// ]]; then
        break
    else
        echo "Please enter a full URL (e.g., https://nextcloud.example.com)"
    fi
done

# Get username
read -p "Nextcloud username: " nextcloud_user

# Get password (hidden)
echo -n "Nextcloud password (or app password): "
read -s nextcloud_pass
echo

echo
echo "Configuring rclone..."

# Create rclone configuration
mkdir -p "$HOME/.config/rclone"

# Use rclone config create to set up the remote
rclone config create nextcloud webdav \
    url "${nextcloud_url}/remote.php/webdav/" \
    vendor nextcloud \
    user "$nextcloud_user" \
    pass "$(rclone obscure "$nextcloud_pass")"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Rclone configured successfully${NC}"
else
    echo -e "${RED}❌ Rclone configuration failed${NC}"
    exit 1
fi

echo
echo "Testing connection..."
if rclone lsd nextcloud: &>/dev/null; then
    echo -e "${GREEN}✅ Connection successful${NC}"
else
    echo -e "${RED}❌ Connection test failed${NC}"
    echo "Please check your credentials and server URL"
    exit 1
fi

echo
echo "Creating sync configuration..."

# Create sync configuration directory
mkdir -p "$HOME/.config/emudeck-sync/logs"

# Create configuration file
cat > "$HOME/.config/emudeck-sync/config.conf" << 'EOF'
# EmuDeck Save Sync Configuration
# Rclone remote name (must be configured in rclone)
RCLONE_REMOTE="nextcloud"

# Remote path where saves will be stored
RCLONE_REMOTE_PATH="EmuDeck/saves"

# Local base path for saves (usually don't change this)
LOCAL_SAVES_BASE="$HOME/.var/app"

# Enable logging
ENABLE_LOGGING=true

# Sync timeout in seconds
SYNC_TIMEOUT=300

# Dry run mode (test without actually syncing)
DRY_RUN=false

# Verbose output
VERBOSE=false
EOF

echo -e "${GREEN}✅ Configuration created${NC}"

echo
echo "Creating remote directory structure..."
rclone mkdir nextcloud:EmuDeck/saves 2>/dev/null || true

echo
echo -e "${GREEN}🎉 Configuration transfer complete!${NC}"
echo
echo "Your Nextcloud sync is now configured with:"
echo "  Server: $nextcloud_url"
echo "  Username: $nextcloud_user"
echo "  Remote path: EmuDeck/saves"
echo
echo "Test your setup with:"
echo "  ./emudeck-sync.sh status"
echo
echo "For comprehensive testing, run:"
echo "  ./test-real-emulators.sh"
