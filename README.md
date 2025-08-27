# 🎮 Universal Emulation Save Sync v1.1.1

**Automatic cloud sync for your emulation saves across all platforms**

*Works with EmuDeck, RetroPie, Batocera, EmulationStation, and custom setups*

---

## 🚀 Quick Start

**👉 [Complete User Guide](COMPLETE-USER-GUIDE.md)** - Everything you need from setup to advanced usage

**Key Features:**
- ✅ Auto-detects saves even in custom locations
- ✅ Supports 13+ major emulators 
- ✅ Multi-platform: EmuDeck, RetroPie, Batocera, EmulationStation
- ✅ Multiple cloud providers: Nextcloud, Google Drive, OneDrive, Dropbox
- ✅ Steam Deck & Bazzite optimized
- ✅ One-command setup

---

## 📚 Documentation

- **[Complete User Guide](COMPLETE-USER-GUIDE.md)** - Start here! Setup, usage, troubleshooting
- **[Changelog](CHANGELOG.md)** - Version history and updates
- **[Test Suite Documentation](tests/README.md)** - Developer testing information

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
```

## 🔄 Backward Compatibility

**Existing EmuDeck users:** Your scripts will continue to work! Run `./create-compatibility-links.sh` to create symlinks.

---

*For detailed instructions, troubleshooting, and advanced features, see the [Complete User Guide](COMPLETE-USER-GUIDE.md)*
