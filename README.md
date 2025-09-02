# 🎮 Universal Emulation Save Sync v1.1.1

**Automatic cloud sync for your emulation saves across all platforms**

*Works with EmuDeck, RetroPie, Batocera, EmulationStation, and custom setups*

---

## 🚀 Quick Start

**� Download standalone executables (no installation required):**

### Windows
```powershell
# Download cloudsaver-windows.exe (43MB) from releases
.\cloudsaver-windows.exe --help
.\cloudsaver-windows.exe detect --platform emudeck
```

### Linux
```bash  
# Download cloudsaver-linux (51MB) from releases
chmod +x cloudsaver-linux
./cloudsaver-linux --help
./cloudsaver-linux detect --platform emudeck
```

### macOS
```bash
# Download cloudsaver-macos (55MB) from releases
chmod +x cloudsaver-macos  
./cloudsaver-macos --help
./cloudsaver-macos detect --platform emudeck
```

**📥 [Download Latest Release](https://github.com/camcast3/cloudsaver/releases)**

**Key Features:**

- ✅ **No installation required** - Standalone executables (43-55MB each)
- ✅ Auto-detects saves even in custom locations  
- ✅ Supports 22+ major emulators
- ✅ Multi-platform: EmuDeck, RetroPie, Batocera, EmulationStation
- ✅ Multiple cloud providers: Nextcloud, Google Drive, OneDrive, Dropbox
- ✅ Steam Deck & Bazzite optimized
- ✅ One-command setup
- ✅ Cross-platform compatibility

---

## 📚 Documentation

- **[Complete Documentation](DOCUMENTATION.md)** - Comprehensive guide with installation, usage, and configuration
- **[Changelog](CHANGELOG.md)** - Version history and updates

---

## ⚡ Basic Usage

### Standalone Executables (Recommended)
```bash
# Detect your emulation setup
./cloudsaver-linux detect --platform emudeck

# Configure cloud provider  
./cloudsaver-linux config set cloudProvider "your-rclone-remote"

# Sync saves
./cloudsaver-linux sync --upload     # Upload saves to cloud
./cloudsaver-linux sync --download   # Download saves from cloud

# Advanced features
./cloudsaver-linux advanced-sync --emulator dolphin --direction upload
./cloudsaver-linux paths list        # Manage custom emulator paths
```

### For Developers (requires Node.js)
```bash
# Modern CLI interface (TypeScript-based)
npx tsx src/cli/index.ts detect      # Auto-detect emulators and platforms
npx tsx src/cli/index.ts config get  # View current configuration
npx tsx src/cli/index.ts sync        # Sync all detected saves
npx tsx src/cli/index.ts paths list  # Manage custom emulator paths

# Advanced sync operations
npx tsx src/cli/index.ts advanced-sync --emulator dolphin --direction upload
npx tsx src/cli/index.ts advanced-sync --emulator all --direction download
```

## 🔄 Backward Compatibility

**Existing EmuDeck users:** Your scripts will continue to work! Run `./create-compatibility-links.sh` to create symlinks.

---

*For detailed instructions, troubleshooting, and advanced features, see the [Sync Usage Guide](SYNC-USAGE-GUIDE.md)*
