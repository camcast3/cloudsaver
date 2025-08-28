#!/bin/bash

# CloudSaver Emulator Wrapper Script
# Automatically syncs saves before and after emulator execution
# Usage: cloudsaver-wrapper.sh [emulator_name] [emulator_command] [args...]

SCRIPT_DIR="$(dirname "$0")"
readonly VERSION="1.1.1"
CLI_SCRIPT="$SCRIPT_DIR/dist/cli/index.js"
LOG_DIR="$HOME/.config/cloudsaver/logs"
WRAPPER_LOG="$LOG_DIR/wrapper.log"
LOCK_FILE="/tmp/cloudsaver-wrapper.lock"

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
CloudSaver Emulator Wrapper v$VERSION

This script wraps emulator execution with automatic save syncing.

Usage: $0 [emulator_name] [emulator_command] [args...]

Examples:
  $0 retroarch flatpak run org.libretro.RetroArch
  $0 dolphin /usr/bin/dolphin-emu
  $0 pcsx2 "steam steam://rungameid/1259440"

EOF
}

# Check for node.js and required commands
check_prerequisites() {
    if ! command -v node &> /dev/null; then
        log_wrapper "ERROR" "Node.js is required but not installed"
        echo -e "${RED}Error:${NC} Node.js is required but not installed"
        echo "Please install Node.js from https://nodejs.org/"
        exit 1
    fi
    
    if [ ! -f "$CLI_SCRIPT" ]; then
        log_wrapper "ERROR" "CloudSaver CLI script not found at $CLI_SCRIPT"
        echo -e "${RED}Error:${NC} CloudSaver CLI script not found"
        echo "Please run 'npm run build' in the CloudSaver directory"
        exit 1
    fi
}

# Parse arguments
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

EMULATOR_NAME="$1"
shift
EMULATOR_CMD="$@"

# Check prerequisites
check_prerequisites

# Lock file to prevent multiple syncs
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE")
    if ps -p "$LOCK_PID" > /dev/null; then
        log_wrapper "WARN" "Another sync operation is in progress (PID: $LOCK_PID)"
        echo -e "${YELLOW}Warning:${NC} Another sync operation is in progress"
        echo "Continuing without syncing saves first"
        # Skip pre-sync, but still do post-sync
    else
        # Stale lock file
        rm -f "$LOCK_FILE"
        echo $$ > "$LOCK_FILE"
        log_wrapper "INFO" "Created lock file: $LOCK_FILE"
    fi
else
    echo $$ > "$LOCK_FILE"
    log_wrapper "INFO" "Created lock file: $LOCK_FILE"
fi

# Log the wrapper execution
log_wrapper "INFO" "Starting wrapper for emulator: $EMULATOR_NAME"
log_wrapper "INFO" "Emulator command: $EMULATOR_CMD"

# Download saves before starting emulator
echo -e "${BLUE}CloudSaver:${NC} Downloading saves for $EMULATOR_NAME..."
log_wrapper "INFO" "Downloading saves for $EMULATOR_NAME"
node "$CLI_SCRIPT" advanced-sync --emulator "$EMULATOR_NAME" --direction download

# Run the emulator
echo -e "${GREEN}CloudSaver:${NC} Starting $EMULATOR_NAME..."
log_wrapper "INFO" "Starting emulator: $EMULATOR_CMD"
eval "$EMULATOR_CMD"
EMULATOR_EXIT_CODE=$?
log_wrapper "INFO" "Emulator exited with code: $EMULATOR_EXIT_CODE"

# Upload saves after emulator exits
echo -e "${BLUE}CloudSaver:${NC} Uploading saves for $EMULATOR_NAME..."
log_wrapper "INFO" "Uploading saves for $EMULATOR_NAME"
node "$CLI_SCRIPT" advanced-sync --emulator "$EMULATOR_NAME" --direction upload

# Remove lock file
if [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE"
    log_wrapper "INFO" "Removed lock file: $LOCK_FILE"
fi

echo -e "${GREEN}CloudSaver:${NC} Sync complete!"
exit $EMULATOR_EXIT_CODE
