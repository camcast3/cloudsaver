#!/bin/bash

# EmuDeck Save Sync Setup Script
# Helps configure rclone with Nextcloud for EmuDeck save syncing

SCRIPT_DIR="$(dirname "$0")"
SYNC_SCRIPT="$SCRIPT_DIR/emudeck-sync.sh"
CONFIG_DIR="$HOME/.config/emudeck-sync"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${WHITE}  EmuDeck Save Sync Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if rclone is installed
if ! command -v rclone >/dev/null 2>&1; then
    echo -e "${YELLOW}rclone is not installed. Attempting automatic installation...${NC}"
    echo ""
    
    # Try to install rclone automatically
    if command -v apt >/dev/null 2>&1; then
        echo -e "${CYAN}Installing rclone using apt...${NC}"
        sudo apt update && sudo apt install -y rclone
    elif command -v yum >/dev/null 2>&1; then
        echo -e "${CYAN}Installing rclone using yum...${NC}"
        sudo yum install -y rclone
    elif command -v dnf >/dev/null 2>&1; then
        echo -e "${CYAN}Installing rclone using dnf...${NC}"
        sudo dnf install -y rclone
    elif command -v pacman >/dev/null 2>&1; then
        echo -e "${CYAN}Installing rclone using pacman...${NC}"
        sudo pacman -S --noconfirm rclone
    elif command -v brew >/dev/null 2>&1; then
        echo -e "${CYAN}Installing rclone using homebrew...${NC}"
        brew install rclone
    else
        echo -e "${YELLOW}No supported package manager found. Installing rclone manually...${NC}"
        
        # Manual installation
        TEMP_DIR=$(mktemp -d)
        ARCH=$(uname -m)
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        
        case $ARCH in
            x86_64|amd64) ARCH="amd64" ;;
            aarch64|arm64) ARCH="arm64" ;;
            armv7l|armhf) ARCH="arm" ;;
            i386|i686) ARCH="386" ;;
        esac
        
        case $OS in
            linux) OS="linux" ;;
            darwin) OS="osx" ;;
        esac
        
        DOWNLOAD_URL="https://downloads.rclone.org/current/rclone-current-${OS}-${ARCH}.zip"
        
        echo -e "${CYAN}Downloading rclone from: $DOWNLOAD_URL${NC}"
        
        if command -v curl >/dev/null 2>&1; then
            curl -L -o "$TEMP_DIR/rclone.zip" "$DOWNLOAD_URL"
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$TEMP_DIR/rclone.zip" "$DOWNLOAD_URL"
        else
            echo -e "${RED}Error: Neither curl nor wget found. Cannot download rclone.${NC}"
            echo "Please install rclone manually from: https://rclone.org/install/"
            exit 1
        fi
        
        if command -v unzip >/dev/null 2>&1; then
            unzip -q "$TEMP_DIR/rclone.zip" -d "$TEMP_DIR"
            RCLONE_BINARY=$(find "$TEMP_DIR" -name "rclone" -type f | head -1)
            
            mkdir -p "$HOME/.local/bin"
            cp "$RCLONE_BINARY" "$HOME/.local/bin/rclone"
            chmod +x "$HOME/.local/bin/rclone"
            
            # Add to PATH
            export PATH="$HOME/.local/bin:$PATH"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc 2>/dev/null || true
            
            echo -e "${GREEN}✅ rclone installed to ~/.local/bin/rclone${NC}"
        else
            echo -e "${RED}Error: unzip not found. Cannot extract rclone.${NC}"
            echo "Please install unzip and try again, or install rclone manually."
            exit 1
        fi
        
        rm -rf "$TEMP_DIR"
    fi
    
    # Verify installation
    if command -v rclone >/dev/null 2>&1; then
        echo -e "${GREEN}✅ rclone installation successful${NC}"
        RCLONE_VERSION=$(rclone version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        echo -e "${GREEN}   Version: $RCLONE_VERSION${NC}"
    else
        echo -e "${RED}❌ rclone installation failed${NC}"
        echo ""
        echo "Please install rclone manually:"
        echo "  Arch/Manjaro: sudo pacman -S rclone"
        echo "  Ubuntu/Debian: sudo apt install rclone"
        echo "  Fedora: sudo dnf install rclone"
        echo "  macOS: brew install rclone"
        echo "  Or visit: https://rclone.org/install/"
        exit 1
    fi
else
    echo -e "${GREEN}✅ rclone is installed${NC}"
    RCLONE_VERSION=$(rclone version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    echo -e "${GREEN}   Version: $RCLONE_VERSION${NC}"
fi

# Check if sync script exists
if [ ! -f "$SYNC_SCRIPT" ]; then
    echo -e "${RED}Error: Sync script not found: $SYNC_SCRIPT${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Sync script found${NC}"

# Create config directory
mkdir -p "$CONFIG_DIR"

echo ""
echo -e "${CYAN}This setup will help you configure rclone with your Nextcloud instance.${NC}"
echo ""

# Prompt for Nextcloud details
read -p "Enter your Nextcloud server URL (e.g., https://cloud.example.com): " nextcloud_url
read -p "Enter your Nextcloud username: " nextcloud_user
read -s -p "Enter your Nextcloud password (or app password): " nextcloud_pass
echo ""

# Validate inputs
if [ -z "$nextcloud_url" ] || [ -z "$nextcloud_user" ] || [ -z "$nextcloud_pass" ]; then
    echo -e "${RED}Error: All fields are required${NC}"
    exit 1
fi

# Clean up URL (remove trailing slash)
nextcloud_url=$(echo "$nextcloud_url" | sed 's/\/$//')

echo ""
echo -e "${YELLOW}Configuring rclone remote 'nextcloud'...${NC}"

# Create rclone config using rclone config create
rclone config create nextcloud webdav \
    url "$nextcloud_url/remote.php/webdav/" \
    vendor nextcloud \
    user "$nextcloud_user" \
    pass "$(rclone obscure "$nextcloud_pass")"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Rclone remote 'nextcloud' configured successfully${NC}"
else
    echo -e "${RED}❌ Failed to configure rclone remote${NC}"
    exit 1
fi

# Test the connection
echo ""
echo -e "${YELLOW}Testing connection to Nextcloud...${NC}"
if rclone lsd nextcloud: >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Connection to Nextcloud successful${NC}"
else
    echo -e "${RED}❌ Connection to Nextcloud failed${NC}"
    echo "Please check your credentials and try again"
    exit 1
fi

# Create EmuDeck directory structure in Nextcloud
echo ""
echo -e "${YELLOW}Creating EmuDeck directory structure in Nextcloud...${NC}"
rclone mkdir nextcloud:EmuDeck
rclone mkdir nextcloud:EmuDeck/saves

# Create initial sync config
echo ""
echo -e "${YELLOW}Creating sync configuration...${NC}"
"$SYNC_SCRIPT" config >/dev/null 2>&1

# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

echo ""
echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo ""
echo -e "${WHITE}Next steps:${NC}"
echo "1. Test the sync by running:"
echo "   ${CYAN}./emudeck-sync.sh status${NC}"
echo ""
echo "2. Download existing saves (if any):"
echo "   ${CYAN}./emudeck-sync.sh download${NC}"
echo ""
echo "3. Use the wrapper to launch emulators with auto-sync:"
echo "   ${CYAN}./emudeck-wrapper.sh retroarch retroarch${NC}"
echo ""
echo "4. Or sync manually:"
echo "   ${CYAN}./emudeck-sync.sh upload${NC} (after gaming)"
echo "   ${CYAN}./emudeck-sync.sh download${NC} (before gaming)"
echo ""
echo -e "${YELLOW}Note: The first sync might take some time depending on your save file sizes.${NC}"
echo ""
echo -e "${WHITE}Configuration files:${NC}"
echo "  Sync config: $CONFIG_DIR/config.conf"
echo "  Logs: $CONFIG_DIR/logs/"
echo "  Rclone config: $HOME/.config/rclone/rclone.conf"
