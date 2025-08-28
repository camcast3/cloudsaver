#!/bin/bash
# CloudSaver Sync Script for Linux/macOS
# This script makes it easier to run CloudSaver sync commands

# Default values
DIRECTION="bidirectional"
EMULATOR=""

# Print help message
show_help() {
    echo "CloudSaver Sync Script"
    echo "======================"
    echo ""
    echo "Usage: ./run-sync.sh [-d <upload|download|bidirectional>] [-e <emulator>] [-h]"
    echo ""
    echo "Options:"
    echo "  -d  Sync direction (upload, download, or bidirectional). Default is bidirectional."
    echo "  -e  Specific emulator to sync. If not specified, syncs all detected emulators."
    echo "  -h  Show this help message."
    echo ""
    echo "Examples:"
    echo "  ./run-sync.sh                     # Sync all emulators bidirectionally"
    echo "  ./run-sync.sh -d upload           # Upload all emulator saves to cloud"
    echo "  ./run-sync.sh -d download -e retroarch  # Download only RetroArch saves"
    exit 0
}

# Parse command line arguments
while getopts "d:e:h" opt; do
    case ${opt} in
        d )
            if [[ "$OPTARG" == "upload" || "$OPTARG" == "download" || "$OPTARG" == "bidirectional" ]]; then
                DIRECTION=$OPTARG
            else
                echo "Error: Direction must be 'upload', 'download', or 'bidirectional'"
                exit 1
            fi
            ;;
        e )
            EMULATOR=$OPTARG
            ;;
        h )
            show_help
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            show_help
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLI_PATH="$SCRIPT_DIR/dist/cli/index.js"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed or not in PATH."
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if the CLI path exists
if [ ! -f "$CLI_PATH" ]; then
    echo "Error: CloudSaver CLI not found at $CLI_PATH"
    echo "Make sure you have built the project with 'npm run build'"
    exit 1
fi

# Build the command
COMMAND="node \"$CLI_PATH\" advanced-sync --direction $DIRECTION"
if [ -n "$EMULATOR" ]; then
    COMMAND="$COMMAND --emulator $EMULATOR"
fi

# Run the command
echo "Running: $COMMAND"
eval $COMMAND
