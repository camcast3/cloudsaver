#!/bin/bash

# Universal Emulation Save Sync Script
# Uses rclone to sync emulation saves with cloud storage before and after emulator usage
# Supports EmuDeck, RetroPie, Batocera, EmulationStation, and custom emulator setups

# Configuration
SCRIPT_NAME="Universal Emulation Save Sync"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.1.0")
LOG_DIR="$HOME/.config/emulation-save-sync/logs"
CONFIG_DIR="$HOME/.config/emulation-save-sync"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOCK_FILE="/tmp/emulation-save-sync.lock"

# Default configuration (can be overridden in config file)
RCLONE_REMOTE="nextcloud"
RCLONE_REMOTE_PATH="EmulationSaves"
LOCAL_SAVES_BASE="$HOME/.var/app"
ENABLE_LOGGING=true
SYNC_TIMEOUT=300  # 5 minutes
DRY_RUN=false
VERBOSE=false

# Emulation Package Manager Detection
EMULATION_MANAGER=""

# Emulator paths by package manager
# EmuDeck paths (relative to $HOME/.var/app)
declare -A EMULATOR_SAVE_PATHS=(
    ["retroarch"]="com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    ["dolphin"]="org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    ["pcsx2"]="net.pcsx2.PCSX2/data/pcsx2"
    ["ppsspp"]="org.ppsspp.PPSSPP/config/ppsspp"
    ["duckstation"]="org.duckstation.DuckStation/data/duckstation"
    ["rpcs3"]="net.rpcs3.RPCS3/data/rpcs3"
    ["cemu"]="info.cemu.Cemu/data/cemu"
    ["ryujinx"]="org.ryujinx.Ryujinx/config/Ryujinx"
    ["yuzu"]="org.yuzu_emu.yuzu/data/yuzu"
    ["citra"]="org.citra_emu.citra/data/citra-emu"
    ["melonds"]="net.kuribo64.melonDS/data/melonDS"
    ["xemu"]="app.xemu.xemu/data/xemu"
    ["primehack"]="io.github.shiiion.primehack/data/dolphin-emu"
)

# Alternative paths to search for each emulator
declare -A EMULATOR_ALT_PATHS=(
    ["retroarch"]="org.libretro.RetroArch/config/retroarch/saves org.libretro.RetroArch/data/retroarch/saves ~/.config/retroarch/saves"
    ["dolphin"]="org.DolphinEmu.dolphin-emu/config/dolphin-emu ~/.local/share/dolphin-emu ~/.config/dolphin-emu"
    ["pcsx2"]="net.pcsx2.PCSX2/config/PCSX2 ~/.config/PCSX2 ~/.local/share/pcsx2"
    ["ppsspp"]="org.ppsspp.PPSSPP/data/ppsspp ~/.config/ppsspp ~/.local/share/ppsspp"
    ["duckstation"]="org.duckstation.DuckStation/config/duckstation ~/.local/share/duckstation ~/.config/duckstation"
    ["rpcs3"]="net.rpcs3.RPCS3/config/rpcs3 ~/.config/rpcs3 ~/.local/share/rpcs3"
    ["cemu"]="info.cemu.Cemu/config/cemu ~/.local/share/cemu ~/.config/cemu"
    ["ryujinx"]="org.ryujinx.Ryujinx/data/Ryujinx ~/.config/Ryujinx ~/.local/share/Ryujinx"
    ["yuzu"]="org.yuzu_emu.yuzu/config/yuzu ~/.config/yuzu ~/.local/share/yuzu"
    ["citra"]="org.citra_emu.citra/config/citra-emu ~/.config/citra-emu ~/.local/share/citra-emu"
    ["melonds"]="net.kuribo64.melonDS/config/melonDS ~/.config/melonDS ~/.local/share/melonDS"
    ["xemu"]="app.xemu.xemu/config/xemu ~/.config/xemu ~/.local/share/xemu"
    ["primehack"]="io.github.shiiion.primehack/config/dolphin-emu ~/.config/primehack ~/.local/share/primehack"
)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Detect emulation package manager
detect_emulation_manager() {
    # Check for EmuDeck
    if [ -f "$HOME/.config/EmuDeck/settings.sh" ] || [ -d "$HOME/emudeck" ]; then
        echo "emudeck"
        return 0
    fi
    
    # Check for RetroPie
    if [ -d "/opt/retropie" ] || [ -f "/home/pi/RetroPie/retropiemenu/retropie_setup.sh" ]; then
        echo "retropie"
        return 0
    fi
    
    # Check for Batocera
    if [ -f "/usr/bin/batocera-info" ] || [ -f "/userdata/system/batocera.conf" ]; then
        echo "batocera"
        return 0
    fi
    
    # Check for EmulationStation
    if [ -d "$HOME/.emulationstation" ] || [ -f "$HOME/.emulationstation/es_systems.cfg" ]; then
        echo "emulationstation"
        return 0
    fi
    
    # Check for Lakka
    if [ -f "/etc/lakka-release" ]; then
        echo "lakka"
        return 0
    fi
    
    # Default to custom/generic
    echo "custom"
    return 0
}

# Initialize emulation manager detection
init_emulation_manager() {
    EMULATION_MANAGER=$(detect_emulation_manager)
    log "INFO" "Detected emulation manager: $EMULATION_MANAGER"
    
    # Set default remote path based on manager
    case $EMULATION_MANAGER in
        "emudeck")
            RCLONE_REMOTE_PATH="EmuDeck/saves"
            ;;
        "retropie")
            RCLONE_REMOTE_PATH="RetroPie/saves"
            ;;
        "batocera")
            RCLONE_REMOTE_PATH="Batocera/saves"
            ;;
        "emulationstation")
            RCLONE_REMOTE_PATH="EmulationStation/saves"
            ;;
        "lakka")
            RCLONE_REMOTE_PATH="Lakka/saves"
            ;;
        *)
            RCLONE_REMOTE_PATH="EmulationSaves"
            ;;
    esac
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$ENABLE_LOGGING" = true ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_DIR/emulation-save-sync.log"
    fi
    
    case $level in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "DEBUG")
            if [ "$VERBOSE" = true ]; then
                echo -e "${CYAN}[DEBUG]${NC} $message"
            fi
            ;;
    esac
}

# Download and install rclone if not present
install_rclone() {
    log "INFO" "Installing rclone..."
    
    # Detect architecture and OS
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case $arch in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l|armhf) arch="arm" ;;
        i386|i686) arch="386" ;;
        *) 
            log "ERROR" "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    case $os in
        linux) os="linux" ;;
        darwin) os="osx" ;;
        *) 
            log "ERROR" "Unsupported OS: $os"
            return 1
            ;;
    esac
    
    # Create local bin directory
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    # Download URL
    local rclone_version="current"
    local download_url="https://downloads.rclone.org/${rclone_version}/rclone-${rclone_version}-${os}-${arch}.zip"
    local temp_dir=$(mktemp -d)
    local zip_file="$temp_dir/rclone.zip"
    
    log "INFO" "Downloading rclone from: $download_url"
    
    # Download rclone
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$zip_file" "$download_url" || {
            log "ERROR" "Failed to download rclone with curl"
            rm -rf "$temp_dir"
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$zip_file" "$download_url" || {
            log "ERROR" "Failed to download rclone with wget"
            rm -rf "$temp_dir"
            return 1
        }
    else
        log "ERROR" "Neither curl nor wget found. Cannot download rclone."
        return 1
    fi
    
    # Extract rclone
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$zip_file" -d "$temp_dir" || {
            log "ERROR" "Failed to extract rclone zip file"
            rm -rf "$temp_dir"
            return 1
        }
    else
        log "ERROR" "unzip not found. Cannot extract rclone."
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Find and copy rclone binary
    local rclone_binary=$(find "$temp_dir" -name "rclone" -type f | head -1)
    if [ -z "$rclone_binary" ]; then
        log "ERROR" "Could not find rclone binary in downloaded archive"
        rm -rf "$temp_dir"
        return 1
    fi
    
    cp "$rclone_binary" "$bin_dir/rclone" || {
        log "ERROR" "Failed to copy rclone to $bin_dir"
        rm -rf "$temp_dir"
        return 1
    }
    
    chmod +x "$bin_dir/rclone" || {
        log "ERROR" "Failed to make rclone executable"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$bin_dir"; then
        export PATH="$bin_dir:$PATH"
        
        # Add to shell profile for persistence
        for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            if [ -f "$profile" ]; then
                if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$profile"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$profile"
                    log "INFO" "Added $bin_dir to PATH in $profile"
                fi
                break
            fi
        done
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Verify installation
    if command -v rclone >/dev/null 2>&1; then
        local rclone_version=$(rclone version 2>/dev/null | head -1 | awk '{print $2}')
        log "INFO" "Successfully installed rclone version: $rclone_version"
        log "INFO" "Rclone installed to: $bin_dir/rclone"
        return 0
    else
        log "ERROR" "Rclone installation verification failed"
        return 1
    fi
}

# Install rclone using package manager
install_rclone_package_manager() {
    log "INFO" "Attempting to install rclone using system package manager..."
    
    # Detect package manager and install
    if command -v apt >/dev/null 2>&1; then
        log "INFO" "Using apt package manager..."
        sudo apt update && sudo apt install -y rclone || return 1
    elif command -v yum >/dev/null 2>&1; then
        log "INFO" "Using yum package manager..."
        sudo yum install -y rclone || return 1
    elif command -v dnf >/dev/null 2>&1; then
        log "INFO" "Using dnf package manager..."
        sudo dnf install -y rclone || return 1
    elif command -v pacman >/dev/null 2>&1; then
        log "INFO" "Using pacman package manager..."
        sudo pacman -S --noconfirm rclone || return 1
    elif command -v zypper >/dev/null 2>&1; then
        log "INFO" "Using zypper package manager..."
        sudo zypper install -y rclone || return 1
    elif command -v brew >/dev/null 2>&1; then
        log "INFO" "Using homebrew package manager..."
        brew install rclone || return 1
    else
        log "WARN" "No supported package manager found"
        return 1
    fi
    
    # Verify installation
    if command -v rclone >/dev/null 2>&1; then
        local rclone_version=$(rclone version 2>/dev/null | head -1 | awk '{print $2}')
        log "INFO" "Successfully installed rclone version: $rclone_version"
        return 0
    else
        log "ERROR" "Package manager installation verification failed"
        return 1
    fi
}

# Check if required tools are installed and auto-install if needed
check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    # Check for rclone
    if ! command -v rclone >/dev/null 2>&1; then
        log "WARN" "rclone not found, attempting automatic installation..."
        
        # Try package manager first (faster and more reliable)
        if install_rclone_package_manager; then
            log "INFO" "rclone installed successfully via package manager"
        else
            log "INFO" "Package manager installation failed, trying direct download..."
            if install_rclone; then
                log "INFO" "rclone installed successfully via direct download"
            else
                log "ERROR" "Failed to install rclone automatically"
                log "INFO" "Please install rclone manually:"
                log "INFO" "  - Visit: https://rclone.org/install/"
                log "INFO" "  - Or use your package manager:"
                log "INFO" "    * Ubuntu/Debian: sudo apt install rclone"
                log "INFO" "    * Fedora: sudo dnf install rclone"
                log "INFO" "    * Arch: sudo pacman -S rclone"
                log "INFO" "    * macOS: brew install rclone"
                return 1
            fi
        fi
    else
        local rclone_version=$(rclone version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        log "INFO" "rclone is available (version: $rclone_version)"
    fi
    
    # Check for other optional tools
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        log "WARN" "Neither curl nor wget found - some features may not work"
    fi
    
    if ! command -v unzip >/dev/null 2>&1; then
        log "WARN" "unzip not found - automatic rclone installation may fail"
    fi
    
    return 0
}

# Create necessary directories
create_directories() {
    # Initialize emulation manager detection
    init_emulation_manager
    
    log "DEBUG" "Creating necessary directories..."
    mkdir -p "$LOG_DIR" "$CONFIG_DIR"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log "DEBUG" "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log "WARN" "Configuration file not found, using defaults"
        create_default_config
    fi
}

# Detect actual save paths for emulators
detect_save_paths() {
    local emulator="$1"
    local detected_paths=()
    
    log "DEBUG" "Detecting save paths for $emulator"
    
    # Check if user has custom path configured
    local custom_path_var="CUSTOM_${emulator^^}_PATH"
    local custom_path="${!custom_path_var}"
    if [ -n "$custom_path" ] && [ -d "$custom_path" ]; then
        log "INFO" "Using custom path for $emulator: $custom_path"
        echo "$custom_path"
        return 0
    fi
    
    # Check default path first
    local default_path="$LOCAL_SAVES_BASE/${EMULATOR_SAVE_PATHS[$emulator]}"
    if [ -d "$default_path" ]; then
        detected_paths+=("$default_path")
    fi
    
    # Check alternative paths
    local alt_paths="${EMULATOR_ALT_PATHS[$emulator]}"
    if [ -n "$alt_paths" ]; then
        for alt_path in $alt_paths; do
            # Handle paths starting with ~
            if [[ "$alt_path" =~ ^~/.* ]]; then
                alt_path="${alt_path/#\~/$HOME}"
                if [ -d "$alt_path" ]; then
                    detected_paths+=("$alt_path")
                fi
            else
                # Check under LOCAL_SAVES_BASE
                local full_path="$LOCAL_SAVES_BASE/$alt_path"
                if [ -d "$full_path" ]; then
                    detected_paths+=("$full_path")
                fi
            fi
        done
    fi
    
    # Search for Steam installations with different user IDs for RetroArch
    if [ "$emulator" = "retroarch" ]; then
        local steam_base="$LOCAL_SAVES_BASE/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata"
        if [ -d "$steam_base" ]; then
            for compat_dir in "$steam_base"/*/; do
                local retroarch_path="$compat_dir/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
                if [ -d "$retroarch_path" ]; then
                    detected_paths+=("$retroarch_path")
                fi
            done
        fi
    fi
    
    # Search more broadly if still no paths found
    if [ ${#detected_paths[@]} -eq 0 ]; then
        log "WARN" "No standard paths found for $emulator, performing broader search..."
        case "$emulator" in
            "retroarch")
                local search_paths=(
                    "$HOME/.var/app/*/config/retroarch/saves"
                    "$HOME/.var/app/*/data/retroarch/saves"
                    "$HOME/.config/retroarch/saves"
                    "$HOME/.local/share/retroarch/saves"
                )
                ;;
            "dolphin")
                local search_paths=(
                    "$HOME/.var/app/*/data/dolphin-emu"
                    "$HOME/.var/app/*/config/dolphin-emu"
                    "$HOME/.local/share/dolphin-emu"
                    "$HOME/.config/dolphin-emu"
                )
                ;;
            *)
                local search_paths=(
                    "$HOME/.var/app/*/${emulator}"
                    "$HOME/.var/app/*/data/${emulator}"
                    "$HOME/.var/app/*/config/${emulator}"
                    "$HOME/.local/share/${emulator}"
                    "$HOME/.config/${emulator}"
                )
                ;;
        esac
        
        for search_pattern in "${search_paths[@]}"; do
            for found_path in $search_pattern; do
                if [ -d "$found_path" ]; then
                    detected_paths+=("$found_path")
                fi
            done
        done
    fi
    
    # Return the first found path or empty if none found
    if [ ${#detected_paths[@]} -gt 0 ]; then
        local chosen_path="${detected_paths[0]}"
        log "INFO" "Detected save path for $emulator: $chosen_path"
        if [ ${#detected_paths[@]} -gt 1 ]; then
            log "WARN" "Multiple paths found for $emulator, using: $chosen_path"
            log "WARN" "Other paths found: ${detected_paths[*]:1}"
        fi
        echo "$chosen_path"
    else
        log "WARN" "No save paths found for $emulator"
        return 1
    fi
}

# Helper function to detect a single emulator's path
detect_emulator_path() {
    local emulator="$1"
    
    # Check if emulator exists in our configuration
    if [ -z "${EMULATOR_SAVE_PATHS[$emulator]:-}" ] && [ -z "${EMULATOR_ALT_PATHS[$emulator]:-}" ]; then
        return 1
    fi
    
    # Use the same logic as detect_save_paths but for a single emulator
    local detected_paths=()
    
    # Check custom path first
    local custom_path_var="CUSTOM_${emulator^^}_PATH"
    local custom_path="${!custom_path_var:-}"
    if [ -n "$custom_path" ] && [ -d "$custom_path" ]; then
        echo "$custom_path"
        return 0
    fi
    
    # Check default path
    if [ -n "${EMULATOR_SAVE_PATHS[$emulator]:-}" ]; then
        local default_path="$LOCAL_SAVES_BASE/${EMULATOR_SAVE_PATHS[$emulator]}"
        if [ -d "$default_path" ]; then
            echo "$default_path"
            return 0
        fi
    fi
    
    # Check alternative paths
    if [ -n "${EMULATOR_ALT_PATHS[$emulator]:-}" ]; then
        IFS=' ' read -ra alt_paths <<< "${EMULATOR_ALT_PATHS[$emulator]}"
        for alt_path in "${alt_paths[@]}"; do
            if [ -d "$alt_path" ]; then
                echo "$alt_path"
                return 0
            fi
        done
    fi
    
    # If not found, return the default path anyway for reference
    if [ -n "${EMULATOR_SAVE_PATHS[$emulator]:-}" ]; then
        echo "$LOCAL_SAVES_BASE/${EMULATOR_SAVE_PATHS[$emulator]}"
    fi
    return 1
}

# Helper function to get custom path for an emulator
get_custom_path() {
    local emulator="$1"
    local custom_var="CUSTOM_${emulator^^}_PATH"
    
    # Check if config file exists and has custom path
    if [ -f "$CONFIG_FILE" ]; then
        local custom_path=$(grep "^${custom_var}=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"')
        if [ -n "$custom_path" ]; then
            echo "$custom_path"
            return 0
        fi
    fi
    
    # Check environment variable
    local env_path="${!custom_var:-}"
    if [ -n "$env_path" ]; then
        echo "$env_path"
        return 0
    fi
    
    return 1
}

# Create default configuration file
create_default_config() {
    log "INFO" "Creating default configuration file at $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOF
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
}

# Check if rclone remote is configured
check_rclone_config() {
    log "DEBUG" "Checking rclone configuration for remote: $RCLONE_REMOTE"
    
    if ! rclone listremotes | grep -q "^$RCLONE_REMOTE:$"; then
        log "ERROR" "Rclone remote '$RCLONE_REMOTE' is not configured"
        log "INFO" "Please configure your Nextcloud remote with: rclone config"
        return 1
    fi
    
    # Test remote connectivity
    if ! timeout $SYNC_TIMEOUT rclone lsd "$RCLONE_REMOTE:" >/dev/null 2>&1; then
        log "ERROR" "Cannot connect to rclone remote '$RCLONE_REMOTE'"
        return 1
    fi
    
    log "INFO" "Rclone remote '$RCLONE_REMOTE' is accessible"
    return 0
}

# Acquire lock to prevent multiple instances
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "ERROR" "Another instance is already running (PID: $pid)"
            return 1
        else
            log "WARN" "Stale lock file found, removing it"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    echo $$ > "$LOCK_FILE"
    log "DEBUG" "Lock acquired (PID: $$)"
    return 0
}

# Release lock
release_lock() {
    if [ -f "$LOCK_FILE" ]; then
        rm -f "$LOCK_FILE"
        log "DEBUG" "Lock released"
    fi
}

# Sync saves for a specific emulator
sync_emulator_saves() {
    local emulator="$1"
    local direction="$2"  # "download" or "upload"
    
    if [ -z "${EMULATOR_SAVE_PATHS[$emulator]}" ]; then
        log "ERROR" "Unknown emulator: $emulator"
        return 1
    fi
    
    local local_path="$LOCAL_SAVES_BASE/${EMULATOR_SAVE_PATHS[$emulator]}"
    local remote_path="$RCLONE_REMOTE:$RCLONE_REMOTE_PATH/$emulator"
    
    # Check if local path exists for upload direction
    if [ "$direction" = "upload" ] && [ ! -d "$local_path" ]; then
        log "WARN" "Local save path does not exist: $local_path"
        return 0
    fi
    
    log "INFO" "Syncing $emulator saves ($direction)..."
    log "DEBUG" "Local path: $local_path"
    log "DEBUG" "Remote path: $remote_path"
    
    local rclone_cmd="rclone sync"
    if [ "$DRY_RUN" = true ]; then
        rclone_cmd="$rclone_cmd --dry-run"
    fi
    
    if [ "$VERBOSE" = true ]; then
        rclone_cmd="$rclone_cmd --verbose"
    fi
    
    # Add timeout
    rclone_cmd="timeout $SYNC_TIMEOUT $rclone_cmd"
    
    case $direction in
        "download")
            # Sync from remote to local (before emulator starts)
            mkdir -p "$local_path"
            if eval "$rclone_cmd \"$remote_path\" \"$local_path\""; then
                log "INFO" "Successfully downloaded $emulator saves"
                return 0
            else
                log "ERROR" "Failed to download $emulator saves"
                return 1
            fi
            ;;
        "upload")
            # Sync from local to remote (after emulator closes)
            if eval "$rclone_cmd \"$local_path\" \"$remote_path\""; then
                log "INFO" "Successfully uploaded $emulator saves"
                return 0
            else
                log "ERROR" "Failed to upload $emulator saves"
                return 1
            fi
            ;;
        *)
            log "ERROR" "Invalid sync direction: $direction"
            return 1
            ;;
    esac
}

# Sync all emulator saves
sync_all_saves() {
    local direction="$1"
    local failed_count=0
    
    log "INFO" "Syncing all emulator saves ($direction)..."
    
    for emulator in "${!EMULATOR_SAVE_PATHS[@]}"; do
        if ! sync_emulator_saves "$emulator" "$direction"; then
            ((failed_count++))
        fi
    done
    
    if [ $failed_count -eq 0 ]; then
        log "INFO" "All saves synced successfully"
        return 0
    else
        log "ERROR" "$failed_count emulator(s) failed to sync"
        return 1
    fi
}

# Show usage information
show_usage() {
    cat << EOF
$SCRIPT_NAME v$VERSION
Universal emulation save sync with cloud storage using rclone
Supports EmuDeck, RetroPie, Batocera, EmulationStation, and custom setups

Usage: $0 [OPTIONS] COMMAND [EMULATOR]

Commands:
    download [emulator]    Download saves from cloud (before emulator)
    upload [emulator]      Upload saves to cloud (after emulator)
    sync [emulator]        Two-way sync saves with cloud
    list                   List available emulators and their detected paths
    status                 Show sync status and configuration
    config                 Show current configuration
    detect [emulator]      Detect and show save paths for emulator
    set-path <emulator> <path>  Set custom save path for emulator
    reset-path <emulator>  Reset emulator to use auto-detected path

Options:
    -h, --help            Show this help message
    -v, --verbose         Enable verbose output
    -n, --dry-run         Perform a dry run without actual syncing
    -c, --config FILE     Use custom configuration file

Examples:
    $0 download                 # Download all saves before gaming session
    $0 upload                   # Upload all saves after gaming session
    $0 download retroarch       # Download only RetroArch saves
    $0 upload dolphin           # Upload only Dolphin saves
    $0 status                   # Show current status
    $0 list                     # Show all emulators and detected paths
    $0 detect retroarch         # Show detected paths for RetroArch
    $0 set-path retroarch "/custom/path/to/retroarch/saves"
    $0 reset-path dolphin       # Reset Dolphin to auto-detected path

Available emulators:
$(for emulator in "${!EMULATOR_SAVE_PATHS[@]}"; do echo "    $emulator"; done | sort)
EOF
}

# List available emulators
list_emulators() {
    log "INFO" "Available emulators:"
    for emulator in "${!EMULATOR_SAVE_PATHS[@]}"; do
        local local_path="$LOCAL_SAVES_BASE/${EMULATOR_SAVE_PATHS[$emulator]}"
        local status="❌"
        local path_info=""
        
        # Check if emulator has detected or custom path
        local detected_path=""
        if command -v find &> /dev/null; then
            detected_path=$(detect_emulator_path "$emulator")
        fi
        
        # Check custom path first
        local config_path=$(get_custom_path "$emulator")
        if [ -n "$config_path" ] && [ -d "$config_path" ]; then
            status="✅"
            path_info=" (custom: $config_path)"
        elif [ -n "$detected_path" ] && [ "$detected_path" != "$local_path" ]; then
            if [ -d "$detected_path" ]; then
                status="✅"
                path_info=" (detected: $detected_path)"
            else
                path_info=" (detected but not found: $detected_path)"
            fi
        elif [ -d "$local_path" ]; then
            status="✅"
            path_info=" (default: $local_path)"
        else
            path_info=" (not found at: $local_path)"
        fi
        
        echo "  $status $emulator$path_info"
    done
}

# Show status
show_status() {
    log "INFO" "EmuDeck Save Sync Status"
    echo "Configuration file: $CONFIG_FILE"
    echo "Log directory: $LOG_DIR"
    echo "Rclone remote: $RCLONE_REMOTE"
    echo "Remote path: $RCLONE_REMOTE_PATH"
    echo "Local base path: $LOCAL_SAVES_BASE"
    echo "Dry run mode: $DRY_RUN"
    echo "Verbose mode: $VERBOSE"
    echo ""
    
    log "INFO" "Checking rclone connectivity..."
    if check_rclone_config; then
        echo "Rclone status: ✅ Connected"
    else
        echo "Rclone status: ❌ Not connected"
    fi
    
    echo ""
    list_emulators
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    local command="$1"
    local emulator="$2"
    
    # Create directories and load configuration
    create_directories
    load_config
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    case $command in
        download)
            if ! acquire_lock; then
                exit 1
            fi
            
            if ! check_rclone_config; then
                release_lock
                exit 1
            fi
            
            if [ -n "$emulator" ]; then
                sync_emulator_saves "$emulator" "download"
                result=$?
            else
                sync_all_saves "download"
                result=$?
            fi
            
            release_lock
            exit $result
            ;;
        upload)
            if ! acquire_lock; then
                exit 1
            fi
            
            if ! check_rclone_config; then
                release_lock
                exit 1
            fi
            
            if [ -n "$emulator" ]; then
                sync_emulator_saves "$emulator" "upload"
                result=$?
            else
                sync_all_saves "upload"
                result=$?
            fi
            
            release_lock
            exit $result
            ;;
        sync)
            if ! acquire_lock; then
                exit 1
            fi
            
            if ! check_rclone_config; then
                release_lock
                exit 1
            fi
            
            log "INFO" "Performing two-way sync..."
            # For two-way sync, we use rclone sync both ways with conflict resolution
            # This is more complex and might need manual conflict resolution
            log "WARN" "Two-way sync not implemented yet. Use download/upload instead."
            
            release_lock
            exit 1
            ;;
        list)
            list_emulators
            ;;
        status)
            show_status
            ;;
        config)
            if [ -f "$CONFIG_FILE" ]; then
                echo "Current configuration ($CONFIG_FILE):"
                cat "$CONFIG_FILE"
            else
                log "ERROR" "Configuration file not found: $CONFIG_FILE"
                exit 1
            fi
            ;;
        detect)
            if [ -z "$emulator" ]; then
                log "ERROR" "Emulator name required for detect command"
                echo "Usage: $0 detect <emulator>"
                exit 1
            fi
            
            if [[ ! " ${!EMULATOR_SAVE_PATHS[@]} " =~ " $emulator " ]]; then
                log "ERROR" "Unknown emulator: $emulator"
                echo "Available emulators: ${!EMULATOR_SAVE_PATHS[@]}"
                exit 1
            fi
            
            echo "Detecting save paths for $emulator..."
            detected_path=$(detect_save_paths "$emulator")
            if [ $? -eq 0 ]; then
                echo "✅ Detected path: $detected_path"
            else
                echo "❌ No save paths found for $emulator"
                echo ""
                echo "You can set a custom path with:"
                echo "  $0 set-path $emulator /path/to/saves"
            fi
            ;;
        set-path)
            if [ -z "$emulator" ] || [ -z "$3" ]; then
                log "ERROR" "Emulator name and path required for set-path command"
                echo "Usage: $0 set-path <emulator> <path>"
                exit 1
            fi
            
            local custom_path="$3"
            
            if [[ ! " ${!EMULATOR_SAVE_PATHS[@]} " =~ " $emulator " ]]; then
                log "ERROR" "Unknown emulator: $emulator"
                echo "Available emulators: ${!EMULATOR_SAVE_PATHS[@]}"
                exit 1
            fi
            
            if [ ! -d "$custom_path" ]; then
                log "ERROR" "Path does not exist: $custom_path"
                exit 1
            fi
            
            # Save custom path to config file
            local custom_var="CUSTOM_${emulator^^}_PATH"
            if grep -q "^$custom_var=" "$CONFIG_FILE" 2>/dev/null; then
                sed -i "s|^$custom_var=.*|$custom_var=\"$custom_path\"|" "$CONFIG_FILE"
            else
                echo "" >> "$CONFIG_FILE"
                echo "# Custom path for $emulator" >> "$CONFIG_FILE"
                echo "$custom_var=\"$custom_path\"" >> "$CONFIG_FILE"
            fi
            
            echo "✅ Custom path set for $emulator: $custom_path"
            echo "Path saved to: $CONFIG_FILE"
            ;;
        reset-path)
            if [ -z "$emulator" ]; then
                log "ERROR" "Emulator name required for reset-path command"
                echo "Usage: $0 reset-path <emulator>"
                exit 1
            fi
            
            if [[ ! " ${!EMULATOR_SAVE_PATHS[@]} " =~ " $emulator " ]]; then
                log "ERROR" "Unknown emulator: $emulator"
                echo "Available emulators: ${!EMULATOR_SAVE_PATHS[@]}"
                exit 1
            fi
            
            # Remove custom path from config file
            local custom_var="CUSTOM_${emulator^^}_PATH"
            if [ -f "$CONFIG_FILE" ] && grep -q "^$custom_var=" "$CONFIG_FILE"; then
                sed -i "/^$custom_var=/d" "$CONFIG_FILE"
                sed -i "/^# Custom path for $emulator/d" "$CONFIG_FILE"
                echo "✅ Custom path reset for $emulator - will use auto-detection"
                
                # Show what will be detected
                detected_path=$(detect_save_paths "$emulator")
                if [ $? -eq 0 ]; then
                    echo "Auto-detected path: $detected_path"
                else
                    echo "⚠️  No auto-detectable paths found"
                fi
            else
                echo "ℹ️  No custom path was set for $emulator"
            fi
            ;;
        "")
            log "ERROR" "No command specified"
            show_usage
            exit 1
            ;;
        *)
            log "ERROR" "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Cleanup on exit
trap 'release_lock' EXIT

# Run main function
main "$@"
