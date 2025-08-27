# 🚀 Bazzite Deployment - Quick Reference

## Pre-Deployment Checklist

✅ **Your Testing Results (Windows/WSL)**:
- ✅ Successfully connected to Nextcloud: `https://your-nextcloud.example.com/`
- ✅ Uploaded/downloaded test saves successfully
- ✅ Wrapper functionality tested
- ✅ rclone configuration working
- ✅ Username: `your-username`
- ✅ Remote path: `EmuDeck/saves`

## Deployment Steps for Bazzite

### 1. GitHub Upload
```bash
# From your Windows machine
git add .
git commit -m "Add EmuDeck Save Sync with Nextcloud integration"
git push origin main
```

### 2. Clone on Bazzite
```bash
# On your Bazzite machine
git clone https://github.com/camcast3/homelab.git
cd homelab
```

### 3. Environment Check
```bash
# Check if Bazzite environment is compatible
./check-bazzite-environment.sh
```

### 4. Quick Setup (Using Existing Config)
```bash
# Make scripts executable
chmod +x *.sh

# Transfer your working Nextcloud configuration
./transfer-config.sh
```

**Enter these details when prompted:**
- Nextcloud URL: `https://your-nextcloud.example.com/`  
- Username: `your-username`
- Password: `[your app password]`

### 5. Test with Real Emulators
```bash
# Comprehensive testing with real emulator saves
./test-real-emulators.sh
```

This script will:
- ✅ Backup existing saves automatically
- ✅ Test sync with real emulator data  
- ✅ Verify upload/download integrity
- ✅ Test wrapper functionality
- ✅ Provide production-ready confirmation

### 6. Production Usage

**Manual Sync:**
```bash
./emudeck-sync.sh download    # Before gaming session
./emudeck-sync.sh upload      # After gaming session
```

**Automatic Sync:**
```bash
# Launch emulator with auto-sync
./emudeck-wrapper.sh retroarch retroarch
./emudeck-wrapper.sh dolphin dolphin-emu-nogui
```

**Steam Integration:**
- Game Properties → Launch Options
- Add: `/home/deck/homelab/emudeck-wrapper.sh retroarch %command%`

## Expected Results on Bazzite

### What Should Work Immediately:
- ✅ Connection to your Nextcloud (same credentials)
- ✅ Detection of Flatpak emulator saves
- ✅ Upload/download of existing saves
- ✅ Wrapper integration

### Emulators Likely to be Detected:
- ✅ RetroArch (if used through Steam)
- ✅ Dolphin (`org.DolphinEmu.dolphin-emu`)
- ✅ PCSX2 (`net.pcsx2.PCSX2`)  
- ✅ PPSSPP (`org.ppsspp.PPSSPP`)
- ✅ Other EmuDeck-installed emulators

### Common Differences from Windows Testing:
- **Paths**: Flatpak paths (`~/.var/app/`) instead of Steam Proton
- **Performance**: Likely faster (native Linux vs WSL)
- **Integration**: Better Steam Deck integration if using Steam

## Troubleshooting

### If Network Issues:
```bash
# Test Nextcloud connectivity
ping your-nextcloud.example.com
rclone lsd nextcloud:
```

### If Emulators Not Detected:
```bash
# Find actual emulator directories
find ~/.var/app -name "*save*" -type d
find ~/.var/app -name "*dolphin*" -type d
find ~/.var/app -name "*retroarch*" -type d
```

### If Configuration Issues:
```bash
# Check configuration
./emudeck-sync.sh config
cat ~/.config/emudeck-sync/config.conf
```

## Success Criteria

You'll know the deployment is successful when:

1. **`./check-bazzite-environment.sh`** reports mostly ✅ green checks
2. **`./emudeck-sync.sh status`** shows ✅ Connected 
3. **`./test-real-emulators.sh`** completes without errors
4. **Real save files sync correctly** between local and Nextcloud
5. **Wrapper launches emulators** and syncs automatically

## Files Created for Bazzite Deployment

- 📋 `DEPLOYMENT-GUIDE.md` - Comprehensive deployment instructions
- 🔍 `check-bazzite-environment.sh` - Environment compatibility check
- 🎮 `test-real-emulators.sh` - Real emulator testing script  
- 🔧 `transfer-config.sh` - Configuration transfer helper
- 📖 `BAZZITE-DEPLOYMENT.md` - This quick reference

## Your Next Command

After pushing to GitHub, run this on your Bazzite machine:

```bash
git clone https://github.com/camcast3/homelab.git && cd homelab && ./check-bazzite-environment.sh
```

**Good luck with your deployment! Your sync system is already proven to work with your Nextcloud.** 🚀
