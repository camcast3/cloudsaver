# EmuDeck Save Sync - Deployment Guide for Bazzite/SteamOS v1.1.0

This guide covers deployment of EmuDeck Save Sync v1.1.0, which includes enhanced Bazzite support and complete coverage of all major emulators.

## 🎯 Pre-Deployment Checklist

### 1. GitHub Repository Setup
- [ ] Push all files to GitHub
- [ ] Ensure all `.sh` files are committed with proper permissions
- [ ] Verify README and documentation is up to date

### 2. Bazzite Machine Preparation
- [ ] Verify Homebrew is available (should be default on Bazzite):
  - **Expected**: `brew --version` should work
  - **If missing**: Report incident to Bazzite support (unexpected)
  - **Fallback**: Use Flatpak (`flatpak install flathub org.rclone.rclone`)
- [ ] Check if EmuDeck is installed and configured
- [ ] Verify network connectivity to your Nextcloud instance
- [ ] Have your Nextcloud credentials ready

## 🔧 Quick Deployment Steps

### Step 1: Clone and Setup
```bash
# Clone the repository
git clone https://github.com/camcast3/homelab.git || { echo "Repository already cloned or error occurred"; }
cd homelab

# Make scripts executable
chmod +x *.sh

# Run the setup (this will configure your existing Nextcloud)
./emudeck-setup.sh
```

### Step 2: Verify Configuration
```bash
# Check system status
./emudeck-sync.sh status

# Test connectivity
./emudeck-sync.sh config
```

### Step 3: Test with Real Emulators
```bash
# Check what emulators are detected
./emudeck-sync.sh list

# Test download (safe - won't overwrite if no cloud saves exist)
./emudeck-sync.sh download

# After playing a game, test upload
./emudeck-sync.sh upload [emulator_name]
```

## 🎮 Real Emulator Testing Strategy

### Phase 1: Safe Testing (No Risk to Existing Saves)
1. **Backup existing saves first**:
   ```bash
   # Create backup of current saves
   mkdir -p ~/emudeck-backup
   cp -r ~/.var/app/*/data/*/saves ~/emudeck-backup/ 2>/dev/null || true
   cp -r ~/.var/app/*/config/*/saves ~/emudeck-backup/ 2>/dev/null || true
   ```

2. **Check which emulators are actually installed**:
   ```bash
   # Check installed emulator Flatpaks
   flatpak list --columns=application | grep -E "(dolphin|pcsx2|ppsspp|citra|duckstation|retroarch|rpcs3|cemu|ryujinx|yuzu|melonds|xemu|primehack)"
   
   # Check for emulator save directories
   ls ~/.var/app/ | grep -E "(org.libretro.RetroArch|org.DolphinEmu.dolphin-emu|net.pcsx2.PCSX2|org.ppsspp.PPSSPP|org.duckstation.DuckStation|net.rpcs3.RPCS3|info.cemu.Cemu|org.ryujinx.Ryujinx|org.yuzu_emu.yuzu|org.citra_emu.citra|net.kuribo64.melonDS|app.xemu.xemu|io.github.shiiion.primehack)"
   
   # Check what the sync script detects
   ./emudeck-sync.sh list
   ```

3. **Test with your most expendable emulator first** (recommend starting with one that has saves you don't mind losing):
   ```bash
   # Example with RetroArch (replace with your chosen emulator)
   ./emudeck-sync.sh upload retroarch -v
   
   # Verify upload worked
   ./emudeck-sync.sh status
   ```

### Phase 2: Testing Each Supported Emulator

Test each emulator you have installed using this pattern:

#### RetroArch (Multiple Systems)
```bash
# Check for saves
ls ~/.var/app/org.libretro.RetroArch/config/retroarch/saves/
# Or Steam version:
ls ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/

# Test sync
./emudeck-sync.sh upload retroarch -v
./emudeck-sync.sh download retroarch -v
```

#### GameCube/Wii (Dolphin)
```bash
# Check for saves
ls ~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/

# Test sync
./emudeck-sync.sh upload dolphin -v
./emudeck-sync.sh download dolphin -v
```

#### PlayStation 2 (PCSX2)
```bash
# Check for saves
ls ~/.var/app/net.pcsx2.PCSX2/data/pcsx2/

# Test sync
./emudeck-sync.sh upload pcsx2 -v
./emudeck-sync.sh download pcsx2 -v
```

#### PSP (PPSSPP)
```bash
# Check for saves
ls ~/.var/app/org.ppsspp.PPSSPP/config/ppsspp/

# Test sync
./emudeck-sync.sh upload ppsspp -v
./emudeck-sync.sh download ppsspp -v
```

#### PlayStation 1 (DuckStation)
```bash
# Check for saves
ls ~/.var/app/org.duckstation.DuckStation/data/duckstation/

# Test sync
./emudeck-sync.sh upload duckstation -v
./emudeck-sync.sh download duckstation -v
```

#### PlayStation 3 (RPCS3)
```bash
# Check for saves
ls ~/.var/app/net.rpcs3.RPCS3/data/rpcs3/

# Test sync
./emudeck-sync.sh upload rpcs3 -v
./emudeck-sync.sh download rpcs3 -v
```

#### Wii U (Cemu)
```bash
# Check for saves
ls ~/.var/app/info.cemu.Cemu/data/cemu/

# Test sync
./emudeck-sync.sh upload cemu -v
./emudeck-sync.sh download cemu -v
```

#### Nintendo Switch (Ryujinx)
```bash
# Check for saves
ls ~/.var/app/org.ryujinx.Ryujinx/config/Ryujinx/

# Test sync
./emudeck-sync.sh upload ryujinx -v
./emudeck-sync.sh download ryujinx -v
```

#### Nintendo Switch (Yuzu - if available)
```bash
# Check for saves
ls ~/.var/app/org.yuzu_emu.yuzu/data/yuzu/

# Test sync
./emudeck-sync.sh upload yuzu -v
./emudeck-sync.sh download yuzu -v
```

#### Nintendo 3DS (Citra)
```bash
# Check for saves
ls ~/.var/app/org.citra_emu.citra/data/citra-emu/

# Test sync
./emudeck-sync.sh upload citra -v
./emudeck-sync.sh download citra -v
```

#### Nintendo DS (melonDS)
```bash
# Check for saves
ls ~/.var/app/net.kuribo64.melonDS/data/melonDS/

# Test sync
./emudeck-sync.sh upload melonds -v
./emudeck-sync.sh download melonds -v
```

#### Original Xbox (Xemu)
```bash
# Check for saves
ls ~/.var/app/app.xemu.xemu/data/xemu/

# Test sync
./emudeck-sync.sh upload xemu -v
./emudeck-sync.sh download xemu -v
```

#### GameCube/Wii (PrimeHack)
```bash
# Check for saves
ls ~/.var/app/io.github.shiiion.primehack/data/dolphin-emu/

# Test sync
./emudeck-sync.sh upload primehack -v
./emudeck-sync.sh download primehack -v
```

### Phase 2: Gradual Integration
1. **Test wrapper with a quick game**:
   ```bash
   # Use wrapper for a short gaming session
   ./emudeck-wrapper.sh retroarch retroarch --menu
   ```

2. **Monitor logs during testing**:
   ```bash
   # In another terminal, monitor logs
   tail -f ~/.config/emudeck-sync/logs/emudeck-sync.log
   ```

### Phase 3: Full Integration
1. **Steam Integration** (after successful testing):
   - Add wrapper to Steam launch options for select games
   - Test with non-critical games first

## 🐛 Bazzite-Specific Considerations

### Flatpak Emulators
Bazzite uses Flatpak for many emulators. The paths should be:
- `~/.var/app/[app-id]/data/[emulator]/`
- `~/.var/app/[app-id]/config/[emulator]/`

### Expected Emulator App IDs on Bazzite:
- **RetroArch**: `org.libretro.RetroArch` or Steam Proton path
- **Dolphin**: `org.DolphinEmu.dolphin-emu`
- **PCSX2**: `net.pcsx2.PCSX2`
- **PPSSPP**: `org.ppsspp.PPSSPP`
- **DuckStation**: `org.duckstation.DuckStation`
- **RPCS3**: `net.rpcs3.RPCS3`
- **Cemu**: `info.cemu.Cemu`
- **Ryujinx**: `org.ryujinx.Ryujinx`
- **Yuzu**: `org.yuzu_emu.yuzu`
- **Citra**: `org.citra_emu.citra`
- **melonDS**: `net.kuribo64.melonDS`
- **Xemu**: `app.xemu.xemu`
- **PrimeHack**: `io.github.shiiion.primehack`

### Network Considerations
- Verify your Nextcloud URL is accessible from the Bazzite machine
- Test with: `curl -I https://your-nextcloud.example.com/`
- If using local DNS, ensure it resolves properly

## 🔍 Verification Commands

### Quick Health Check
```bash
# Run this command to verify everything is working
./emudeck-sync.sh status && echo "✅ System ready for real emulators!"
```

### Detailed Verification
```bash
# Check rclone connectivity
rclone lsd nextcloud: && echo "✅ Nextcloud accessible"

# Check available emulators
./emudeck-sync.sh list

# Check logs
ls -la ~/.config/emudeck-sync/logs/

# Verify configuration
cat ~/.config/emudeck-sync/config.conf
```

## 🚨 Safety Measures

### Before First Real Use:
1. **Create complete backup**:
   ```bash
   # Backup all potential save locations
   mkdir -p ~/save-backup-$(date +%Y%m%d)
   cp -r ~/.var/app ~/save-backup-$(date +%Y%m%d)/
   ```

2. **Test with dry-run first**:
   ```bash
   # Test what would happen without actually syncing
   ./emudeck-sync.sh upload -n -v
   ./emudeck-sync.sh download -n -v
   ```

3. **Start with non-critical saves**: Test with games you don't mind losing progress on first

## 🔧 Troubleshooting Bazzite-Specific Issues

### If rclone isn't found:
```bash
# On Bazzite, Homebrew should be available by default:
brew install rclone

# If Homebrew is missing on Bazzite (unexpected - report incident):
# Report to: https://github.com/ublue-os/bazzite/issues
# Include: System info, PATH, expected vs actual state

# Fallback: Install rclone via Flatpak
flatpak install flathub org.rclone.rclone

# If using Flatpak rclone, you may need to use:
# flatpak run org.rclone.rclone instead of just 'rclone'

# Or let the script auto-install (will detect and report incidents)
./emudeck-setup.sh
```

### If emulator paths are different:
The script auto-detects common paths, but if your EmuDeck setup is custom:
1. Check actual paths: `find ~/.var/app -name "*saves*" -type d`
2. Compare with script's expected paths in `emudeck-sync.sh`
3. Modify the configuration if needed

### If network issues:
```bash
# Test Nextcloud connectivity
rclone lsd nextcloud:

# If fails, reconfigure
rclone config reconnect nextcloud:
```

## 📊 Success Metrics

You'll know the deployment is successful when:
- [ ] `./emudeck-sync.sh status` shows ✅ Connected
- [ ] At least one emulator shows as ✅ available
- [ ] Test upload/download completes without errors
- [ ] Wrapper script works with a real emulator launch
- [ ] Logs show successful operations
- [ ] Save files maintain integrity through sync cycle

## 🎮 Recommended First Test Game

For your first real test, recommend:
1. **RetroArch with a simple game** (like a classic arcade game)
2. **Short play session** (5-10 minutes)
3. **Manual sync first** before trying wrapper
4. **Verify save integrity** by loading the game after sync

This ensures you have a working baseline before integrating with more complex emulators or Steam.
