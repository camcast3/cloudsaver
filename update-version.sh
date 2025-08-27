#!/bin/bash

# Version Management Script for Universal Emulation Save Sync
# Usage: ./update-version.sh [new_version]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "unknown")

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    cat << EOF
Universal Emulation Save Sync - Version Management

Current version: $CURRENT_VERSION

Usage: $0 [new_version]

Examples:
    $0                  # Show current version
    $0 1.2.0           # Update to version 1.2.0
    $0 1.1.1           # Update to version 1.1.1

This script will:
1. Update the VERSION file
2. Show which files reference the version
3. Remind you to update CHANGELOG.md

Note: This script only updates the VERSION file. You may need to 
manually update version references in documentation.
EOF
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

if [ $# -eq 0 ]; then
    echo -e "${BLUE}Current version: ${GREEN}$CURRENT_VERSION${NC}"
    echo
    echo "Files that automatically read from VERSION file:"
    echo "  • emulation-save-sync.sh"
    echo "  • emulation-save-setup.sh"
    echo "  • emulation-save-wrapper.sh"
    echo "  • check-bazzite-environment.sh"
    echo "  • run-all-tests.sh"
    echo
    echo "Run with --help to see usage information."
    exit 0
fi

NEW_VERSION="$1"

# Validate version format (basic semantic versioning)
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo -e "${YELLOW}Warning: Version should follow semantic versioning (e.g., 1.2.3)${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Version update cancelled."
        exit 0
    fi
fi

# Update version file
echo "$NEW_VERSION" > "$VERSION_FILE"

echo -e "${GREEN}✅ Version updated from $CURRENT_VERSION to $NEW_VERSION${NC}"
echo

echo -e "${BLUE}Scripts that will automatically use the new version:${NC}"
echo "  • emulation-save-sync.sh"
echo "  • emulation-save-setup.sh" 
echo "  • emulation-save-wrapper.sh"
echo "  • check-bazzite-environment.sh"
echo "  • run-all-tests.sh"
echo

echo -e "${YELLOW}📝 Don't forget to:${NC}"
echo "  1. Update CHANGELOG.md with the new version changes"
echo "  2. Update README.md and COMPLETE-USER-GUIDE.md if needed"
echo "  3. Update any hardcoded version references in scripts"
echo "  4. Test the updated scripts"
echo "  5. Run create-compatibility-links.sh for EmuDeck users"
echo "  6. Commit and tag the new version:"
echo "     git add ."
echo "     git commit -m \"Release v$NEW_VERSION\""
echo "     git tag v$NEW_VERSION"
echo "     git push origin main --tags"
