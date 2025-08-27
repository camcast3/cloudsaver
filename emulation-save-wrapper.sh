#!/bin/bash

# Universal Emulation Save Sync Wrapper
# Automatically syncs saves before and after emulator execution
# Usage: emulation-save-wrapper.sh [emulator_name] [emulator_command] [args...]

SYNC_SCRIPT_DIR="$(dirname "$0")"
readonly VERSION="1.2.0"
SYNC_SCRIPT="$SYNC_SCRIPT_DIR/emulation-save-sync.sh"
LOG_DIR="$HOME/.config/emulation-save-sync/logs"
WRAPPER_LOG="$LOG_DIR/wrapper.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log_wrapper() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] [$level] $message" >> "$WRAPPER_LOG"
    
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
    esac
}

# Show usage
show_usage() {
    cat << EOF
EmuDeck Save Sync Wrapper v$VERSION

This script wraps emulator execution with automatic save syncing.

Usage: $0 [emulator_name] [emulator_command] [args...]

Examples:
    $0 retroarch retroarch --menu
    $0 dolphin dolphin-emu-nogui -b -e "/path/to/game.iso"
    $0 pcsx2 pcsx2 "/path/to/game.iso"
    $0 ppsspp ppsspp "/path/to/game.cso"

Available emulator names:
    retroarch, dolphin, pcsx2, ppsspp, duckstation, rpcs3, cemu,
    ryujinx, yuzu, citra, melonds, xemu, primehack

The script will:
1. Download saves from your Nextcloud before starting the emulator
2. Run the emulator with your specified command and arguments
3. Upload saves to your Nextcloud after the emulator closes
EOF
}

# Check if sync script exists
if [ ! -f "$SYNC_SCRIPT" ]; then
    log_wrapper "ERROR" "Sync script not found: $SYNC_SCRIPT"
    exit 1
fi

# Check arguments
if [ $# -lt 2 ]; then
    log_wrapper "ERROR" "Insufficient arguments provided"
    show_usage
    exit 1
fi

# Parse arguments
EMULATOR_NAME="$1"
shift
EMULATOR_COMMAND="$1"
shift
EMULATOR_ARGS="$@"

log_wrapper "INFO" "Starting emulator wrapper for $EMULATOR_NAME"
log_wrapper "INFO" "Command: $EMULATOR_COMMAND $EMULATOR_ARGS"

# Pre-sync: Download saves from cloud
log_wrapper "INFO" "Downloading saves before starting $EMULATOR_NAME..."
if "$SYNC_SCRIPT" download "$EMULATOR_NAME"; then
    log_wrapper "INFO" "Pre-sync completed successfully"
else
    log_wrapper "WARN" "Pre-sync failed, continuing anyway..."
fi

# Start emulator and wait for it to finish
log_wrapper "INFO" "Starting $EMULATOR_NAME..."
start_time=$(date +%s)

# Execute the emulator command
if [ -n "$EMULATOR_ARGS" ]; then
    "$EMULATOR_COMMAND" $EMULATOR_ARGS
else
    "$EMULATOR_COMMAND"
fi

emulator_exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

log_wrapper "INFO" "$EMULATOR_NAME finished (exit code: $emulator_exit_code, duration: ${duration}s)"

# Post-sync: Upload saves to cloud
log_wrapper "INFO" "Uploading saves after $EMULATOR_NAME session..."
if "$SYNC_SCRIPT" upload "$EMULATOR_NAME"; then
    log_wrapper "INFO" "Post-sync completed successfully"
else
    log_wrapper "ERROR" "Post-sync failed! Your saves may not be backed up."
fi

log_wrapper "INFO" "Emulator wrapper completed"

# Exit with the same code as the emulator
exit $emulator_exit_code
