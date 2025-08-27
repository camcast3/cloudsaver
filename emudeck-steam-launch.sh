#!/bin/bash

# Steam Launch Script for EmuDeck Save Sync
# This script can be used as a Steam launch option to automatically sync saves
# Usage in Steam: Add this as launch option: /path/to/emudeck-steam-launch.sh %command%

SCRIPT_DIR="$(dirname "$0")"
SYNC_SCRIPT="$SCRIPT_DIR/emudeck-sync.sh"
LOG_DIR="$HOME/.config/emudeck-sync/logs"

# Create log directory
mkdir -p "$LOG_DIR"

# Log function
log_steam() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_DIR/steam-launch.log"
}

# Check if command is provided
if [ $# -eq 0 ]; then
    log_steam "ERROR: No command provided"
    echo "Error: No command provided"
    echo "Usage: $0 [emulator_command_and_args]"
    exit 1
fi

# Parse the full command
FULL_COMMAND="$*"
log_steam "INFO: Steam launch command: $FULL_COMMAND"

# Try to detect emulator from command
EMULATOR_NAME=""
if echo "$FULL_COMMAND" | grep -q "retroarch"; then
    EMULATOR_NAME="retroarch"
elif echo "$FULL_COMMAND" | grep -q "dolphin"; then
    EMULATOR_NAME="dolphin"
elif echo "$FULL_COMMAND" | grep -q "pcsx2"; then
    EMULATOR_NAME="pcsx2"
elif echo "$FULL_COMMAND" | grep -q "ppsspp"; then
    EMULATOR_NAME="ppsspp"
elif echo "$FULL_COMMAND" | grep -q "duckstation"; then
    EMULATOR_NAME="duckstation"
elif echo "$FULL_COMMAND" | grep -q "rpcs3"; then
    EMULATOR_NAME="rpcs3"
elif echo "$FULL_COMMAND" | grep -q "cemu"; then
    EMULATOR_NAME="cemu"
elif echo "$FULL_COMMAND" | grep -q "ryujinx"; then
    EMULATOR_NAME="ryujinx"
elif echo "$FULL_COMMAND" | grep -q "yuzu"; then
    EMULATOR_NAME="yuzu"
elif echo "$FULL_COMMAND" | grep -q "citra"; then
    EMULATOR_NAME="citra"
elif echo "$FULL_COMMAND" | grep -q "melonds"; then
    EMULATOR_NAME="melonds"
elif echo "$FULL_COMMAND" | grep -q "xemu"; then
    EMULATOR_NAME="xemu"
elif echo "$FULL_COMMAND" | grep -q "primehack"; then
    EMULATOR_NAME="primehack"
fi

if [ -n "$EMULATOR_NAME" ]; then
    log_steam "INFO: Detected emulator: $EMULATOR_NAME"
    
    # Pre-sync
    log_steam "INFO: Starting pre-sync for $EMULATOR_NAME"
    if "$SYNC_SCRIPT" download "$EMULATOR_NAME" >> "$LOG_DIR/steam-launch.log" 2>&1; then
        log_steam "INFO: Pre-sync completed successfully"
    else
        log_steam "WARN: Pre-sync failed, continuing anyway"
    fi
else
    log_steam "WARN: Could not detect emulator from command, skipping sync"
fi

# Execute the original command
log_steam "INFO: Executing: $FULL_COMMAND"
eval "$FULL_COMMAND"
EXIT_CODE=$?

log_steam "INFO: Command finished with exit code: $EXIT_CODE"

# Post-sync if emulator was detected
if [ -n "$EMULATOR_NAME" ]; then
    log_steam "INFO: Starting post-sync for $EMULATOR_NAME"
    if "$SYNC_SCRIPT" upload "$EMULATOR_NAME" >> "$LOG_DIR/steam-launch.log" 2>&1; then
        log_steam "INFO: Post-sync completed successfully"
    else
        log_steam "ERROR: Post-sync failed"
    fi
fi

log_steam "INFO: Steam launch script completed"
exit $EXIT_CODE
