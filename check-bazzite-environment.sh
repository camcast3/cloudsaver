#!/bin/bash

# EmuDeck Save Sync - Bazzite Environment Check
# Run this script on your Bazzite machine after cloning from GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.0.0")

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 EmuDeck Save Sync - Bazzite Environment Check v$VERSION${NC}"
echo "========================================================="

# Function to check and report status
check_status() {
    local description="$1"
    local status="$2"
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✅${NC} $description"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️${NC} $description"
    else
        echo -e "${RED}❌${NC} $description"
    fi
}

echo
echo -e "${BLUE}1. System Information${NC}"
echo "===================="
echo "Hostname: $(hostname)"
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "User: $(whoami)"

echo
echo -e "${BLUE}2. Required Dependencies${NC}"
echo "======================="

# Check for bash
if command -v bash &> /dev/null; then
    bash_version=$(bash --version | head -1 | cut -d' ' -f4)
    check_status "Bash available (version $bash_version)" "OK"
else
    check_status "Bash not found" "FAIL"
fi

# Check for rclone
if command -v rclone &> /dev/null; then
    rclone_version=$(rclone version | head -1 | awk '{print $2}')
    check_status "rclone available (version $rclone_version)" "OK"
elif flatpak list | grep -q rclone; then
    check_status "rclone available via Flatpak" "OK"
else
    # Check if we're on Bazzite to provide appropriate guidance
    if grep -q "bazzite" /etc/os-release 2>/dev/null || hostname | grep -q "bazzite"; then
        if command -v brew &> /dev/null; then
            check_status "rclone not found, but Homebrew available (run: brew install rclone)" "WARNING"
        else
            check_status "🚨 INCIDENT: Homebrew missing on Bazzite (should be default) - report to Bazzite support" "FAIL"
        fi
    else
        check_status "rclone not found (install via package manager or Homebrew)" "WARNING"
    fi
fi

# Check for curl
if command -v curl &> /dev/null; then
    check_status "curl available" "OK"
else
    check_status "curl not found" "FAIL"
fi

# Check for basic utils
for util in mkdir cp mv rm ls chmod; do
    if command -v $util &> /dev/null; then
        check_status "$util available" "OK"
    else
        check_status "$util not found" "FAIL"
    fi
done

# Check for Homebrew (should be default on Bazzite)
if grep -q "bazzite" /etc/os-release 2>/dev/null || hostname | grep -q "bazzite"; then
    if command -v brew &> /dev/null; then
        check_status "Homebrew available (as expected on Bazzite)" "OK"
    else
        check_status "🚨 INCIDENT: Homebrew missing on Bazzite - should be available by default" "FAIL"
        echo -e "${RED}   Report to: https://github.com/ublue-os/bazzite/issues${NC}"
    fi
else
    # Non-Bazzite systems
    if command -v brew &> /dev/null; then
        check_status "Homebrew available" "OK"
    fi
fi

echo
echo -e "${BLUE}3. EmuDeck Environment${NC}"
echo "===================="

# Check for EmuDeck installation
if [ -d "$HOME/Applications/EmuDeck" ]; then
    check_status "EmuDeck installation found" "OK"
elif [ -d "$HOME/.var/app" ] && ls ~/.var/app/ | grep -E "(dolphin|retroarch|pcsx2|ppsspp)" &> /dev/null; then
    check_status "Emulator Flatpaks detected" "OK"
else
    check_status "EmuDeck/Emulator installation not clearly detected" "WARNING"
fi

# Check for installed emulator Flatpaks
echo
echo "Installed Emulator Flatpaks:"
emulator_installed_count=0

declare -A flatpaks=(
    ["RetroArch"]="org.libretro.RetroArch"
    ["Dolphin"]="org.DolphinEmu.dolphin-emu"
    ["PCSX2"]="net.pcsx2.PCSX2"
    ["PPSSPP"]="org.ppsspp.PPSSPP"
    ["Citra"]="org.citra_emu.citra"
    ["DuckStation"]="org.duckstation.DuckStation"
    ["RPCS3"]="net.rpcs3.RPCS3"
    ["Cemu"]="info.cemu.Cemu"
    ["Ryujinx"]="org.ryujinx.Ryujinx"
    ["Yuzu"]="org.yuzu_emu.yuzu"
    ["melonDS"]="net.kuribo64.melonDS"
    ["Xemu"]="app.xemu.xemu"
    ["PrimeHack"]="io.github.shiiion.primehack"
)

for emulator in "${!flatpaks[@]}"; do
    flatpak_id="${flatpaks[$emulator]}"
    if [ -d "$HOME/.var/app/$flatpak_id" ]; then
        check_status "$emulator Flatpak installed ($flatpak_id)" "OK"
        ((emulator_installed_count++))
    fi
done

if [ $emulator_installed_count -gt 0 ]; then
    echo -e "${GREEN}✅${NC} $emulator_installed_count emulator(s) installed via Flatpak"
else
    echo -e "${YELLOW}⚠️${NC} No emulator Flatpaks detected - may need to install emulators first"
fi

# Check for common emulator save paths (only exist after running emulators)
echo
echo "Emulator Save Directories (created after first run):"
emulator_count=0

# RetroArch (Steam/Proton path)
retroarch_steam_path="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch"
if [ -d "$retroarch_steam_path" ]; then
    check_status "RetroArch (Steam) saves: $retroarch_steam_path" "OK"
    ((emulator_count++))
fi

# RetroArch (Flatpak)
retroarch_flatpak_path="$HOME/.var/app/org.libretro.RetroArch/config/retroarch"
if [ -d "$retroarch_flatpak_path" ]; then
    check_status "RetroArch (Flatpak) config: $retroarch_flatpak_path" "OK"
    ((emulator_count++))
fi

# Other common emulators
declare -A emulators=(
    ["Dolphin"]="$HOME/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    ["PCSX2"]="$HOME/.var/app/net.pcsx2.PCSX2/data/pcsx2"
    ["PPSSPP"]="$HOME/.var/app/org.ppsspp.PPSSPP/config/ppsspp"
    ["Citra"]="$HOME/.var/app/org.citra_emu.citra/data/citra-emu"
    ["DuckStation"]="$HOME/.var/app/org.duckstation.DuckStation/data/duckstation"
    ["RPCS3"]="$HOME/.var/app/net.rpcs3.RPCS3/data/rpcs3"
    ["Cemu"]="$HOME/.var/app/info.cemu.Cemu/data/cemu"
    ["Ryujinx"]="$HOME/.var/app/org.ryujinx.Ryujinx/config/Ryujinx"
    ["Yuzu"]="$HOME/.var/app/org.yuzu_emu.yuzu/data/yuzu"
    ["melonDS"]="$HOME/.var/app/net.kuribo64.melonDS/data/melonDS"
    ["Xemu"]="$HOME/.var/app/app.xemu.xemu/data/xemu"
    ["PrimeHack"]="$HOME/.var/app/io.github.shiiion.primehack/data/dolphin-emu"
)

for emulator in "${!emulators[@]}"; do
    path="${emulators[$emulator]}"
    if [ -d "$path" ]; then
        check_status "$emulator saves: $path" "OK"
        ((emulator_count++))
    fi
done

echo
if [ $emulator_count -gt 0 ]; then
    check_status "$emulator_count emulator(s) with existing save data detected" "OK"
else
    check_status "No emulator save directories found yet" "WARNING"
    echo -e "${YELLOW}   This is normal if you haven't run the emulators yet.${NC}"
    echo -e "${YELLOW}   Save directories are created when you first launch each emulator.${NC}"
fi

echo
echo -e "${BLUE}4. Network Connectivity${NC}"
echo "======================"

# Test network connectivity
if ping -c 1 8.8.8.8 &> /dev/null; then
    check_status "Internet connectivity" "OK"
else
    check_status "Internet connectivity" "FAIL"
fi

# Test Nextcloud connectivity (if already configured)
if [ -f ~/.config/rclone/rclone.conf ] && grep -q "nextcloud" ~/.config/rclone/rclone.conf; then
    nextcloud_url=$(grep -A 10 '\[nextcloud\]' ~/.config/rclone/rclone.conf | grep 'url' | cut -d'=' -f2 | tr -d ' ' | sed 's|/remote.php/webdav/||')
    if [ -n "$nextcloud_url" ] && curl -I "$nextcloud_url" &> /dev/null; then
        check_status "Nextcloud server reachable" "OK"
    elif [ -n "$nextcloud_url" ]; then
        check_status "Nextcloud server configured but not reachable (may be network/VPN issue)" "WARNING"
    else
        check_status "Nextcloud configured but URL not detected" "WARNING"
    fi
else
    check_status "Nextcloud server test (will configure during setup)" "WARNING"
fi

echo
echo -e "${BLUE}5. File System Permissions${NC}"
echo "=========================="

# Test write permissions in home directory
test_dir="$HOME/.test-emudeck-$(date +%s)"
if mkdir -p "$test_dir" && touch "$test_dir/test.txt" && rm -rf "$test_dir"; then
    check_status "Home directory write permissions" "OK"
else
    check_status "Home directory write permissions" "FAIL"
fi

# Test .config directory
config_dir="$HOME/.config"
if [ -d "$config_dir" ] && [ -w "$config_dir" ]; then
    check_status ".config directory writable" "OK"
elif mkdir -p "$config_dir" 2>/dev/null; then
    check_status ".config directory created and writable" "OK"
else
    check_status ".config directory access" "FAIL"
fi

echo
echo -e "${BLUE}6. Current Directory Check${NC}"
echo "========================="

# Check if we're in the right directory
if [ -f "emudeck-sync.sh" ] && [ -f "emudeck-setup.sh" ]; then
    check_status "EmuDeck Sync scripts found in current directory" "OK"
    
    # Check script permissions
    if [ -x "emudeck-sync.sh" ]; then
        check_status "Scripts are executable" "OK"
    else
        check_status "Scripts need execute permissions (run: chmod +x *.sh)" "WARNING"
    fi
else
    check_status "EmuDeck Sync scripts not found in current directory" "FAIL"
    echo "  Run this from the cloned repository directory"
fi

echo
echo -e "${BLUE}7. Summary${NC}"
echo "========="

# Count issues and provide Bazzite-specific guidance
if command -v bash &> /dev/null && [ -f "emudeck-sync.sh" ]; then
    echo -e "${GREEN}✅ Ready for deployment!${NC}"
    echo
    echo "Next steps for Bazzite:"
    echo "1. Run: chmod +x *.sh"
    if ! command -v rclone &> /dev/null; then
        echo "2. Install rclone: brew install rclone (recommended for Bazzite)"
    fi
    echo "3. Run: ./emudeck-setup.sh"
    echo "4. Follow the Deployment Guide"
else
    echo -e "${RED}❌ Some issues need to be resolved first${NC}"
    echo
    echo "Common fixes for Bazzite:"
    echo "1. Make sure you're in the cloned repository directory"
    if ! command -v rclone &> /dev/null; then
        echo "2. Install rclone: brew install rclone (or flatpak install flathub org.rclone.rclone)"
    fi
    echo "3. Check network connectivity"
fi

echo
echo -e "${YELLOW}💡 Bazzite-specific tips:${NC}"
if command -v brew &> /dev/null; then
    echo "- ✅ Homebrew detected - use 'brew install rclone' for best results"
else
    echo "- Consider installing Homebrew for easier package management"
    echo "- Alternative: Use Flatpak for rclone installation"
fi

echo
echo -e "${YELLOW}💡 Tip:${NC} Keep this output for troubleshooting if needed"
echo "For detailed deployment instructions, see: DEPLOYMENT-GUIDE.md"
