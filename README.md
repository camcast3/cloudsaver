# 🎮 Universal Emulation Save Sync v1.1.1

**Automatic cloud sync for your emulation saves across all platforms**

*Works with EmuDeck, RetroPie, Batocera, EmulationStation, and custom setups*

---

## 🚀 Quick Start

**👉 [Complete Documentation](CONSOLIDATED-DOCUMENTATION.md)** - Everything you need from setup to advanced usage

**Key Features:**

- ✅ Auto-detects saves even in custom locations
- ✅ Supports 13+ major emulators
- ✅ Multi-platform: EmuDeck, RetroPie, Batocera, EmulationStation
- ✅ Multiple cloud providers: Nextcloud, Google Drive, OneDrive, Dropbox
- ✅ Steam Deck & Bazzite optimized
- ✅ One-command setup
- ✅ Automatic wrapper scripts for seamless syncing

---

## 📚 Documentation

- **[Complete Documentation](CONSOLIDATED-DOCUMENTATION.md)** - All documentation in one place
- **[Changelog](CHANGELOG.md)** - Version history and updates

---

## ⚡ Basic Usage

```bash
# One-time setup (auto-detects your emulation platform)
./emulation-save-setup.sh

# Daily usage
./emulation-save-sync.sh download    # Before gaming
./emulation-save-sync.sh upload      # After gaming

# See detected emulators and platforms
./emulation-save-sync.sh list

# Use the newer CLI interface
node dist/cli/index.js sync
node dist/cli/index.js advanced-sync --direction upload

# Use wrapper scripts to automatically sync before and after running an emulator
./cloudsaver-wrapper.sh retroarch flatpak run org.libretro.RetroArch  # Linux/macOS
.\cloudsaver-wrapper.ps1 retroarch "C:\RetroArch\retroarch.exe"       # Windows
```

## 🔄 Backward Compatibility

**Existing EmuDeck users:** Your scripts will continue to work! Run `./create-compatibility-links.sh` to create symlinks.

---

*For detailed instructions, troubleshooting, and advanced features, see the [Complete User Guide](COMPLETE-USER-GUIDE.md)*
