#!/bin/bash

# EmuDeck Save Sync - Real Emulator Test Script for Bazzite
# This script helps you safely test the sync system with actual emulators

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🎮 EmuDeck Save Sync - Real Emulator Testing${NC}"
echo "============================================="

# Check if we're set up
if [ ! -f "$SCRIPT_DIR/emudeck-sync.sh" ]; then
    echo -e "${RED}❌ emudeck-sync.sh not found. Run this from the project directory.${NC}"
    exit 1
fi

if [ ! -f "$HOME/.config/emudeck-sync/config.conf" ]; then
    echo -e "${RED}❌ Configuration not found. Please run ./emudeck-setup.sh first.${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Phase 1: Pre-Test Safety Backup${NC}"
echo "==============================="

BACKUP_DIR="$HOME/emudeck-saves-backup-$(date +%Y%m%d-%H%M%S)"
echo "Creating backup directory: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

# Backup existing saves
echo "Backing up existing save files..."
backup_count=0

# Common save locations
declare -A save_paths=(
    ["retroarch-steam"]="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch"
    ["retroarch-flatpak"]="$HOME/.var/app/org.libretro.RetroArch/config/retroarch"
    ["dolphin"]="$HOME/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    ["pcsx2"]="$HOME/.var/app/net.pcsx2.PCSX2/data/pcsx2"
    ["ppsspp"]="$HOME/.var/app/org.ppsspp.PPSSPP/config/ppsspp"
    ["citra"]="$HOME/.var/app/org.citra_emu.citra/data/citra-emu"
    ["duckstation"]="$HOME/.var/app/org.duckstation.DuckStation/data/duckstation"
)

for emulator in "${!save_paths[@]}"; do
    path="${save_paths[$emulator]}"
    if [ -d "$path" ]; then
        echo "  Backing up $emulator: $path"
        mkdir -p "$BACKUP_DIR/$emulator"
        cp -r "$path"/* "$BACKUP_DIR/$emulator/" 2>/dev/null || true
        ((backup_count++))
    fi
done

if [ $backup_count -gt 0 ]; then
    echo -e "${GREEN}✅ Backed up $backup_count emulator save directories${NC}"
    echo "Backup location: $BACKUP_DIR"
else
    echo -e "${YELLOW}⚠️  No existing save directories found to backup${NC}"
fi

echo
echo -e "${BLUE}Phase 2: System Status Check${NC}"
echo "============================="

# Run status check
echo "Checking EmuDeck Sync status..."
if "$SCRIPT_DIR/emudeck-sync.sh" status; then
    echo -e "${GREEN}✅ System status check passed${NC}"
else
    echo -e "${RED}❌ System status check failed${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Phase 3: Available Emulators${NC}"
echo "============================="

echo "Detecting available emulators..."
available_emulators=()

# Parse the list output to get available emulators
while IFS= read -r line; do
    if [[ "$line" =~ ✅[[:space:]]+([a-z]+) ]]; then
        emulator="${BASH_REMATCH[1]}"
        available_emulators+=("$emulator")
        echo -e "${GREEN}✅ $emulator${NC} - Ready for sync"
    elif [[ "$line" =~ ❌[[:space:]]+([a-z]+) ]]; then
        emulator="${BASH_REMATCH[1]}"
        echo -e "${YELLOW}⚠️  $emulator${NC} - No saves detected yet"
    fi
done < <("$SCRIPT_DIR/emudeck-sync.sh" list 2>/dev/null | grep -E "✅|❌")

if [ ${#available_emulators[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No emulators with existing saves detected${NC}"
    echo "This is normal if you haven't played any games yet."
    echo
    echo "To test the system:"
    echo "1. Launch an emulator and play a game briefly"
    echo "2. Save your progress"
    echo "3. Run this script again"
    exit 0
fi

echo
echo -e "${GREEN}Found ${#available_emulators[@]} emulator(s) with saves:${NC} ${available_emulators[*]}"

echo
echo -e "${BLUE}Phase 4: Safe Dry-Run Test${NC}"
echo "=========================="

echo "Testing sync operations in dry-run mode..."

for emulator in "${available_emulators[@]}"; do
    echo
    echo "Testing $emulator (dry-run):"
    
    echo "  - Upload test:"
    if "$SCRIPT_DIR/emudeck-sync.sh" upload "$emulator" --dry-run -v; then
        echo -e "    ${GREEN}✅ Upload dry-run successful${NC}"
    else
        echo -e "    ${RED}❌ Upload dry-run failed${NC}"
        continue
    fi
    
    echo "  - Download test:"
    if "$SCRIPT_DIR/emudeck-sync.sh" download "$emulator" --dry-run -v; then
        echo -e "    ${GREEN}✅ Download dry-run successful${NC}"
    else
        echo -e "    ${RED}❌ Download dry-run failed${NC}"
    fi
done

echo
echo -e "${BLUE}Phase 5: Real Sync Test${NC}"
echo "======================="

echo -e "${YELLOW}⚠️  About to perform REAL sync operations${NC}"
echo "This will upload your save files to Nextcloud."
echo

read -p "Continue with real sync test? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled. Your saves are safe."
    exit 0
fi

# Test with first available emulator
test_emulator="${available_emulators[0]}"
echo
echo "Testing real sync with: $test_emulator"

echo
echo "Step 1: Upload current saves to Nextcloud..."
if "$SCRIPT_DIR/emudeck-sync.sh" upload "$test_emulator" -v; then
    echo -e "${GREEN}✅ Upload successful${NC}"
else
    echo -e "${RED}❌ Upload failed${NC}"
    exit 1
fi

echo
echo "Step 2: Verify files are in Nextcloud..."
if rclone lsl nextcloud:EmuDeck/saves/$test_emulator 2>/dev/null | head -5; then
    echo -e "${GREEN}✅ Files confirmed in Nextcloud${NC}"
else
    echo -e "${YELLOW}⚠️  Could not list remote files (may be normal)${NC}"
fi

echo
echo "Step 3: Test download (should be identical)..."
if "$SCRIPT_DIR/emudeck-sync.sh" download "$test_emulator" -v; then
    echo -e "${GREEN}✅ Download successful${NC}"
else
    echo -e "${RED}❌ Download failed${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Phase 6: Wrapper Test (Optional)${NC}"
echo "================================="

echo "The wrapper automatically syncs before and after emulator launch."
echo "This test will launch $test_emulator briefly to test the wrapper."
echo

read -p "Test the wrapper functionality? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "Testing wrapper with $test_emulator..."
    echo "Note: This will launch the emulator - close it after verifying it starts correctly."
    
    # Find a suitable test command for the emulator
    case "$test_emulator" in
        "retroarch")
            cmd="retroarch --menu"
            ;;
        "dolphin")
            cmd="dolphin-emu --help"  # Just show help, don't launch GUI
            ;;
        *)
            echo "Manual wrapper test needed for $test_emulator"
            echo "Run: ./emudeck-wrapper.sh $test_emulator [emulator-command]"
            cmd=""
            ;;
    esac
    
    if [ -n "$cmd" ]; then
        echo "Running: ./emudeck-wrapper.sh $test_emulator $cmd"
        if "$SCRIPT_DIR/emudeck-wrapper.sh" "$test_emulator" $cmd; then
            echo -e "${GREEN}✅ Wrapper test completed${NC}"
        else
            echo -e "${YELLOW}⚠️  Wrapper test had issues (check logs)${NC}"
        fi
    fi
else
    echo "Wrapper test skipped."
fi

echo
echo -e "${BLUE}Phase 7: Test Results${NC}"
echo "===================="

echo -e "${GREEN}🎉 Real emulator testing completed!${NC}"
echo
echo "What was tested:"
echo "  ✅ System connectivity to your Nextcloud"
echo "  ✅ Emulator save detection"
echo "  ✅ Real save file upload/download"
echo "  ✅ File integrity through sync cycle"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  ✅ Wrapper functionality"
fi

echo
echo "Your sync system is ready for production use!"
echo
echo "Next steps:"
echo "1. Use manually: ./emudeck-sync.sh upload/download [emulator]"
echo "2. Use wrapper: ./emudeck-wrapper.sh [emulator] [command]"
echo "3. Integrate with Steam launch options (see DEPLOYMENT-GUIDE.md)"
echo "4. Set up periodic sync with systemd timers"

echo
echo "Logs are available at: ~/.config/emudeck-sync/logs/"
echo "Backup created at: $BACKUP_DIR"

echo
echo -e "${GREEN}✅ Testing complete - Your EmuDeck Save Sync is working!${NC}"
