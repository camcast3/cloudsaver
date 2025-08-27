# EmuDeck Save Sync - Deployment Guide for Bazzite/SteamOS

## 🎯 Pre-Deployment Checklist

### 1. GitHub Repository Setup
- [ ] Push all files to GitHub
- [ ] Ensure all `.sh` files are committed with proper permissions
- [ ] Verify README and documentation is up to date

### 2. Bazzite Machine Preparation
- [ ] Ensure rclone is available (`flatpak install flathub org.rclone.rclone` or use auto-install)
- [ ] Check if EmuDeck is installed and configured
- [ ] Verify network connectivity to your Nextcloud instance
- [ ] Have your Nextcloud credentials ready

## 🔧 Quick Deployment Steps

### Step 1: Clone and Setup
```bash
# Clone the repository
git clone https://github.com/camcast3/homelab.git
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

2. **Test with a single emulator** (recommend RetroArch first):
   ```bash
   # Check if RetroArch saves exist
   ls ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/

   # If saves exist, upload them
   ./emudeck-sync.sh upload retroarch -v

   # Verify upload worked
   ./emudeck-sync.sh status
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
- **Citra**: `org.citra_emu.citra`
- **And others as configured by EmuDeck

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
# Install rclone via Flatpak
flatpak install flathub org.rclone.rclone

# Or let the script auto-install it
./emudeck-setup.sh  # Will attempt automatic installation
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
