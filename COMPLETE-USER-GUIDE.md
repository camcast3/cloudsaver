# 🎮 Universal Emulation Save Sync - Complete User Guide

*From zero to cloud saves across all emulation platforms in minutes*

**Supports:** EmuDeck, RetroPie, Batocera, EmulationStation, Lakka, and custom setups

## 📋 Table of Contents

1. [What This Does](#what-this-does)
2. [Prerequisites](#prerequisites)
3. [Initial Setup on Bazzite](#initial-setup-on-bazzite)
4. [Connecting to Your Cloud](#connecting-to-your-cloud)
5. [Using the Commands](#using-the-commands)
6. [Advanced Path Management](#advanced-path-management)
7. [Steam Integration](#steam-integration)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 What This Does

Universal Emulation Save Sync automatically backs up and syncs your emulator save files to cloud storage, ensuring you never lose progress and can play across multiple devices and platforms.

**Supported Platforms:**
- 🐧 **EmuDeck** (Steam Deck, Linux gaming)
- 🍓 **RetroPie** (Raspberry Pi retro gaming)
- 🦇 **Batocera** (Multi-platform retro gaming OS)
- 🎮 **EmulationStation** (Standalone frontend)
- 🐟 **Lakka** (Lightweight retro gaming)
- 🔧 **Custom setups** (Any emulator installation)

**Key Features:**
- ✅ Supports 13+ major emulators (RetroArch, Dolphin, PCSX2, PPSSPP, etc.)
- ✅ Automatic platform detection (no manual configuration needed)
- ✅ Automatic save detection (even in custom locations)
- ✅ Two-way sync: download before gaming, upload after
- ✅ Multiple cloud providers (Nextcloud, Google Drive, OneDrive, Dropbox)
- ✅ Steam Deck integration with launch options
- ✅ Dry-run testing to verify before real sync
- ✅ Intelligent path detection for Flatpaks and custom installs

---

## 🚀 Prerequisites

### What You Need:
1. **Bazzite system** (Steam Deck or desktop)
2. **Nextcloud account** (or any rclone-supported cloud service)
3. **EmuDeck installed** (with emulators you want to sync)
4. **5 minutes** to set up

### Cloud Storage Options:
- **Nextcloud** (recommended - self-hosted)
- Google Drive, OneDrive, Dropbox
- Any of 40+ services supported by rclone

---

## 🛠️ Initial Setup on Bazzite

### Step 1: Get the Scripts

```bash
# Clone the repository
git clone https://github.com/camcast3/cloudsaver.git
cd cloudsaver

# Make scripts executable
chmod +x *.sh
```

### Step 2: Check Your System

```bash
# Verify Bazzite compatibility
./check-bazzite-environment.sh
```

This will check for:
- ✅ EmuDeck installation
- ✅ Installed emulator Flatpaks
- ✅ Existing save directories (created after first emulator run)
- ✅ System requirements

### Step 3: Run Setup

```bash
# Automated setup with rclone installation (auto-detects your platform)
./emulation-save-setup.sh
```

The setup will:
1. 🔍 Detect your emulation platform (EmuDeck, RetroPie, Batocera, etc.)
2. 🔧 Install rclone (via Homebrew if needed)
3. 📁 Create necessary directories
4. 🎮 Detect your installed emulators
5. ⚙️ Prepare platform-specific configuration

---

## ☁️ Connecting to Your Cloud

### For Nextcloud Users:

When prompted during setup, provide:

```bash
# Your Nextcloud details
Nextcloud URL: https://your-nextcloud.example.com
Username: your-username
Password: [your-app-password]  # Create this in Nextcloud settings
```

**Creating Nextcloud App Password:**
1. Go to Nextcloud Settings → Security
2. Create new app password named "EmuDeck Sync"
3. Use this password (not your login password)

### For Other Cloud Services:

```bash
# Manual rclone configuration
rclone config

# Follow the prompts for your service:
# - Google Drive: Web authentication
# - OneDrive: Microsoft authentication  
# - Dropbox: OAuth authentication
```

---

## 🎮 Using the Commands

### Basic Sync Operations

```bash
# Download all saves before gaming session
./emulation-save-sync.sh download

# Upload all saves after gaming session  
./emulation-save-sync.sh upload

# Two-way sync (merges changes from both sides)
./emulation-save-sync.sh sync
```

### Single Emulator Operations

```bash
# Download saves for specific emulator
./emulation-save-sync.sh download retroarch
./emulation-save-sync.sh download dolphin

# Upload saves for specific emulator
./emulation-save-sync.sh upload pcsx2
./emulation-save-sync.sh upload ppsspp
```

### Information Commands

```bash
# List all emulators and their save paths
./emulation-save-sync.sh list

# Show system status and configuration
./emulation-save-sync.sh status

# Show current configuration details
./emulation-save-sync.sh config
```

### Test Before Real Sync

```bash
# Dry run - see what would happen without doing it
./emulation-save-sync.sh --dry-run download
./emulation-save-sync.sh --dry-run upload retroarch

# Verbose output for troubleshooting
./emulation-save-sync.sh --verbose download
```

---

## 🔍 Advanced Path Management

*New in v1.1.0+ - Handle saves in custom locations*

### Detect Save Paths

```bash
# See where saves are actually located for all emulators
./emulation-save-sync.sh list

# Detect paths for specific emulator
./emulation-save-sync.sh detect retroarch
./emulation-save-sync.sh detect dolphin
```

**Example output:**
```
✅ retroarch (default: /home/deck/.var/app/org.libretro.RetroArch/config/retroarch/saves)
❌ dolphin (not found at: /home/deck/.local/share/dolphin-emu)  
✅ pcsx2 (detected: /home/deck/.var/app/net.pcsx2.PCSX2/config/PCSX2/sstates)
```

### Set Custom Save Paths

If your saves are in a non-standard location:

```bash
# Set custom path for an emulator
./emudeck-sync.sh set-path retroarch "/custom/path/to/retroarch/saves"
./emudeck-sync.sh set-path dolphin "/home/deck/Games/Dolphin/SaveStates"

# Verify the custom path was set
./emudeck-sync.sh detect retroarch
```

### Reset to Auto-Detection

```bash
# Remove custom path and use auto-detection
./emudeck-sync.sh reset-path retroarch

# This will find saves in standard locations:
# - Default EmuDeck paths
# - Flatpak application directories  
# - Alternative known locations
```

### Supported Auto-Detection Paths

The script automatically searches these locations:

**RetroArch:**
- `~/.var/app/org.libretro.RetroArch/config/retroarch/saves`
- `~/.config/retroarch/saves`  
- `/home/deck/Emulation/saves/retroarch`

**Dolphin:**
- `~/.var/app/org.DolphinEmu.dolphin-emu/config/dolphin-emu`
- `~/.local/share/dolphin-emu`
- `/home/deck/Emulation/saves/dolphin`

*And many more for PCSX2, PPSSPP, DuckStation, RPCS3, etc.*

---

## 🚂 Steam Integration

### Method 1: Launch Options (Per Game)

1. Right-click game in Steam → Properties
2. Launch Options → Add:

```bash
# For RetroArch games
/home/deck/cloudsaver/emudeck-wrapper.sh retroarch %command%

# For Dolphin games  
/home/deck/cloudsaver/emudeck-wrapper.sh dolphin %command%

# For PCSX2 games
/home/deck/cloudsaver/emudeck-wrapper.sh pcsx2 %command%
```

### Method 2: Global Wrapper

Create a wrapper script for all emulator launches:

```bash
# This automatically syncs before and after each gaming session
./emudeck-wrapper.sh [emulator] [original_command]
```

### What the Wrapper Does:

1. 📥 Downloads latest saves from cloud
2. 🎮 Launches your emulator
3. ⏳ Waits for emulator to close  
4. 📤 Uploads saves to cloud
5. 📝 Logs everything

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### "No saves found" or "Path not detected"

```bash
# Check what paths are being searched
./emudeck-sync.sh detect [emulator] --verbose

# Manually set the correct path
./emudeck-sync.sh set-path [emulator] "/actual/path/to/saves"

# List all emulators to see status
./emudeck-sync.sh list
```

#### "rclone not found"

```bash
# Reinstall rclone
./emudeck-setup.sh

# Or install manually
brew install rclone
```

#### "Sync failed" or "Permission denied"

```bash
# Check rclone configuration
rclone config show

# Test connection
rclone ls nextcloud:EmuDeck/saves

# Check file permissions
ls -la ~/.config/emudeck-sync/
```

#### "Multiple save locations found"

The script will show all detected paths:

```bash
./emudeck-sync.sh detect retroarch
# Output: Found multiple paths:
#   /path/1/saves (using this one)
#   /path/2/saves  
#   /path/3/saves
```

To choose a specific path:
```bash
./emudeck-sync.sh set-path retroarch "/path/2/saves"
```

### Debug Mode

```bash
# Maximum verbosity for troubleshooting
./emudeck-sync.sh --verbose --dry-run list

# Check log files
tail -f ~/.config/emudeck-sync/logs/emudeck-sync.log
```

---

## 📚 Command Reference

### Main Commands
| Command | Description | Example |
|---------|-------------|---------|
| `download` | Download saves from cloud | `./emudeck-sync.sh download` |
| `upload` | Upload saves to cloud | `./emudeck-sync.sh upload retroarch` |
| `sync` | Two-way sync | `./emudeck-sync.sh sync` |
| `list` | Show emulators and paths | `./emudeck-sync.sh list` |
| `status` | Show system status | `./emudeck-sync.sh status` |

### Path Management  
| Command | Description | Example |
|---------|-------------|---------|
| `detect` | Show detected paths | `./emudeck-sync.sh detect dolphin` |
| `set-path` | Set custom save path | `./emudeck-sync.sh set-path dolphin "/custom/path"` |
| `reset-path` | Reset to auto-detection | `./emudeck-sync.sh reset-path dolphin` |

### Options
| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Test without actual sync | `./emudeck-sync.sh --dry-run upload` |
| `--verbose` | Show detailed output | `./emudeck-sync.sh --verbose download` |
| `--help` | Show help message | `./emudeck-sync.sh --help` |

---

## 🎉 You're All Set!

Your emulation saves are now protected in the cloud across all platforms!

**Daily Workflow:**
1. 📥 `./emulation-save-sync.sh download` ← Before gaming
2. 🎮 Play your games  
3. 📤 `./emulation-save-sync.sh upload` ← After gaming

**Or just use the Steam wrapper for automatic sync! 🚀**

**For Existing EmuDeck Users:**
Run `./create-compatibility-links.sh` to maintain your existing script names and automation.

---

*For technical details, see the full documentation in the repository.*
