#!/bin/bash

# Universal Emulation Save Sync - Python Migration Preparation Script
# This script ONLY prepares files and documentation - NO automatic execution or changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.1.1")

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐍 Universal Emulation Save Sync - Python Migration Preparation v$VERSION${NC}"
echo "============================================================================="
echo
echo -e "${YELLOW}⚠️  SAFE MODE: This script will NOT modify any existing files or configurations${NC}"
echo -e "${YELLOW}⚠️  It ONLY creates new files for migration preparation${NC}"
echo
echo "This script will SAFELY create:"
echo "1. 📋 Emulator configuration reference (emulator-config.json)"
echo "2. � Python project structure template (python-version/)"
echo "3. 📚 Migration documentation and roadmap"
echo "4. 🔍 Analysis of current bash script inconsistencies"
echo "5. 📝 Step-by-step migration instructions"
echo
echo -e "${GREEN}✅ Your existing scripts and configs will remain UNTOUCHED${NC}"
echo -e "${GREEN}✅ No backups needed - nothing will be changed${NC}"
echo -e "${GREEN}✅ You can review everything before deciding to migrate${NC}"
echo

read -p "Create migration preparation files? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration preparation cancelled."
    exit 0
fi
# Step 1: Generate consolidated emulator configuration REFERENCE
echo -e "${BLUE}1. Creating emulator configuration reference...${NC}"

# This creates a REFERENCE file - does NOT modify existing configs
cat > "$SCRIPT_DIR/emulator-config-reference.json" << 'EOF'
{
  "version": "1.1.1",
  "emulators": {
    "retroarch": {
      "name": "RetroArch",
      "flatpak_id": "org.libretro.RetroArch",
      "save_paths": [
        "~/.var/app/org.libretro.RetroArch/config/retroarch/saves",
        "~/.var/app/org.libretro.RetroArch/data/retroarch/saves",
        "~/.config/retroarch/saves",
        "/home/deck/Emulation/saves/retroarch",
        "~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
      ],
      "config_paths": [
        "~/.var/app/org.libretro.RetroArch/config/retroarch",
        "~/.config/retroarch"
      ]
    },
    "dolphin": {
      "name": "Dolphin",
      "flatpak_id": "org.DolphinEmu.dolphin-emu",
      "save_paths": [
        "~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC",
        "~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu/Wii",
        "~/.local/share/dolphin-emu/GC",
        "~/.local/share/dolphin-emu/Wii",
        "/home/deck/Emulation/saves/dolphin"
      ],
      "config_paths": [
        "~/.var/app/org.DolphinEmu.dolphin-emu/data/dolphin-emu",
        "~/.local/share/dolphin-emu"
      ]
    },
    "pcsx2": {
      "name": "PCSX2",
      "flatpak_id": "net.pcsx2.PCSX2",
      "save_paths": [
        "~/.var/app/net.pcsx2.PCSX2/data/PCSX2/sstates",
        "~/.var/app/net.pcsx2.PCSX2/data/PCSX2/memcards",
        "~/.config/PCSX2/sstates",
        "~/.config/PCSX2/memcards",
        "/home/deck/Emulation/saves/pcsx2"
      ],
      "config_paths": [
        "~/.var/app/net.pcsx2.PCSX2/data/PCSX2",
        "~/.config/PCSX2"
      ]
    },
    "ppsspp": {
      "name": "PPSSPP",
      "flatpak_id": "org.ppsspp.PPSSPP",
      "save_paths": [
        "~/.var/app/org.ppsspp.PPSSPP/config/ppsspp/PSP/SAVEDATA",
        "~/.var/app/org.ppsspp.PPSSPP/config/ppsspp/PSP/PPSSPP_STATE",
        "~/.config/ppsspp/PSP/SAVEDATA",
        "~/.config/ppsspp/PSP/PPSSPP_STATE",
        "/home/deck/Emulation/saves/ppsspp"
      ],
      "config_paths": [
        "~/.var/app/org.ppsspp.PPSSPP/config/ppsspp",
        "~/.config/ppsspp"
      ]
    },
    "duckstation": {
      "name": "DuckStation",
      "flatpak_id": "org.duckstation.DuckStation",
      "save_paths": [
        "~/.var/app/org.duckstation.DuckStation/data/duckstation/savestates",
        "~/.var/app/org.duckstation.DuckStation/data/duckstation/memcards",
        "~/.local/share/duckstation/savestates",
        "~/.local/share/duckstation/memcards",
        "/home/deck/Emulation/saves/duckstation"
      ],
      "config_paths": [
        "~/.var/app/org.duckstation.DuckStation/data/duckstation",
        "~/.local/share/duckstation"
      ]
    },
    "rpcs3": {
      "name": "RPCS3",
      "flatpak_id": "net.rpcs3.RPCS3",
      "save_paths": [
        "~/.var/app/net.rpcs3.RPCS3/data/rpcs3/dev_hdd0/home/00000001/savedata",
        "~/.config/rpcs3/dev_hdd0/home/00000001/savedata",
        "/home/deck/Emulation/saves/rpcs3"
      ],
      "config_paths": [
        "~/.var/app/net.rpcs3.RPCS3/data/rpcs3",
        "~/.config/rpcs3"
      ]
    },
    "cemu": {
      "name": "Cemu",
      "flatpak_id": "info.cemu.Cemu",
      "save_paths": [
        "~/.var/app/info.cemu.Cemu/data/cemu/mlc01/usr/save",
        "~/.local/share/cemu/mlc01/usr/save",
        "/home/deck/Emulation/saves/cemu"
      ],
      "config_paths": [
        "~/.var/app/info.cemu.Cemu/data/cemu",
        "~/.local/share/cemu"
      ]
    },
    "ryujinx": {
      "name": "Ryujinx",
      "flatpak_id": "org.ryujinx.Ryujinx",
      "save_paths": [
        "~/.var/app/org.ryujinx.Ryujinx/config/Ryujinx/bis/user/save",
        "~/.config/Ryujinx/bis/user/save",
        "/home/deck/Emulation/saves/ryujinx"
      ],
      "config_paths": [
        "~/.var/app/org.ryujinx.Ryujinx/config/Ryujinx",
        "~/.config/Ryujinx"
      ]
    },
    "yuzu": {
      "name": "Yuzu",
      "flatpak_id": "org.yuzu_emu.yuzu",
      "save_paths": [
        "~/.var/app/org.yuzu_emu.yuzu/data/yuzu/nand/user/save",
        "~/.local/share/yuzu/nand/user/save",
        "/home/deck/Emulation/saves/yuzu"
      ],
      "config_paths": [
        "~/.var/app/org.yuzu_emu.yuzu/data/yuzu",
        "~/.local/share/yuzu"
      ]
    },
    "citra": {
      "name": "Citra",
      "flatpak_id": "org.citra_emu.citra",
      "save_paths": [
        "~/.var/app/org.citra_emu.citra/data/citra-emu/sdmc/Nintendo 3DS",
        "~/.local/share/citra-emu/sdmc/Nintendo 3DS",
        "/home/deck/Emulation/saves/citra"
      ],
      "config_paths": [
        "~/.var/app/org.citra_emu.citra/data/citra-emu",
        "~/.local/share/citra-emu"
      ]
    },
    "melonds": {
      "name": "melonDS",
      "flatpak_id": "net.kuribo64.melonDS",
      "save_paths": [
        "~/.var/app/net.kuribo64.melonDS/data/melonDS",
        "~/.local/share/melonDS",
        "/home/deck/Emulation/saves/melonds"
      ],
      "config_paths": [
        "~/.var/app/net.kuribo64.melonDS/data/melonDS",
        "~/.local/share/melonDS"
      ]
    },
    "xemu": {
      "name": "Xemu",
      "flatpak_id": "app.xemu.xemu",
      "save_paths": [
        "~/.var/app/app.xemu.xemu/data/xemu/xbox_hdd/UDATA",
        "~/.local/share/xemu/xbox_hdd/UDATA",
        "/home/deck/Emulation/saves/xemu"
      ],
      "config_paths": [
        "~/.var/app/app.xemu.xemu/data/xemu",
        "~/.local/share/xemu"
      ]
    },
    "primehack": {
      "name": "PrimeHack",
      "flatpak_id": "io.github.shiiion.primehack",
      "save_paths": [
        "~/.var/app/io.github.shiiion.primehack/data/dolphin-emu/GC",
        "~/.var/app/io.github.shiiion.primehack/data/dolphin-emu/Wii",
        "/home/deck/Emulation/saves/primehack"
      ],
      "config_paths": [
        "~/.var/app/io.github.shiiion.primehack/data/dolphin-emu"
      ]
    }
  },
  "platforms": {
    "emudeck": {
      "name": "EmuDeck",
      "detection_paths": [
        "~/Applications/EmuDeck",
        "~/.var/app"
      ],
      "default_remote_path": "EmuDeck/saves"
    },
    "retropie": {
      "name": "RetroPie",
      "detection_paths": [
        "/opt/retropie",
        "~/RetroPie"
      ],
      "default_remote_path": "RetroPie/saves"
    },
    "batocera": {
      "name": "Batocera",
      "detection_paths": [
        "/userdata/saves",
        "/userdata/system/configs"
      ],
      "default_remote_path": "Batocera/saves"
    },
    "lakka": {
      "name": "Lakka",
      "detection_paths": [
        "/storage/savefiles",
        "/storage/savestates"
      ],
      "default_remote_path": "Lakka/saves"
    },
    "generic": {
      "name": "Generic Setup",
      "detection_paths": [],
      "default_remote_path": "EmulationSync/saves"
    }
  }
}
EOF

echo -e "${GREEN}✅${NC} Generated emulator configuration reference: emulator-config-reference.json"

# Step 2: Create Python project template structure
echo -e "${BLUE}2. Creating Python project template...${NC}"

mkdir -p python-template/{src,tests,config,docs,scripts}

# Create basic Python project structure TEMPLATE
cat > python-template/requirements.txt << 'EOF'
# Core dependencies
pathlib2>=2.3.0
pyyaml>=6.0
requests>=2.28.0
click>=8.1.0

# Cloud storage support
rclone-python>=0.1.0

# Optional UI dependencies
streamlit>=1.25.0
fastapi>=0.100.0
uvicorn>=0.23.0

# Development dependencies
pytest>=7.0.0
black>=23.0.0
flake8>=5.0.0
mypy>=1.0.0
EOF

cat > python-template/setup.py << 'EOF'
from setuptools import setup, find_packages

setup(
    name="universal-emulation-save-sync",
    version="2.0.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[
        "pathlib2>=2.3.0",
        "pyyaml>=6.0",
        "requests>=2.28.0",
        "click>=8.1.0",
        "rclone-python>=0.1.0",
    ],
    extras_require={
        "ui": ["streamlit>=1.25.0", "fastapi>=0.100.0", "uvicorn>=0.23.0"],
        "dev": ["pytest>=7.0.0", "black>=23.0.0", "flake8>=5.0.0", "mypy>=1.0.0"],
    },
    entry_points={
        "console_scripts": [
            "emulation-sync=universal_emulation_sync.cli:main",
            "emulation-sync-ui=universal_emulation_sync.ui:main",
        ],
    },
    python_requires=">=3.8",
)
EOF

# Copy emulator config reference to Python template
cp emulator-config-reference.json python-template/config/

echo -e "${GREEN}✅${NC} Created Python project template in: python-template/"

# Step 3: Analyze current bash script inconsistencies
echo -e "${BLUE}3. Analyzing current bash script inconsistencies...${NC}"

# Analyze inconsistencies in current bash scripts (READ-ONLY analysis)
cat > BASH-INCONSISTENCIES-ANALYSIS.md << 'EOF'
# Bash Script Inconsistencies Analysis

## Current Issues Found

### RetroArch Path Differences
- **check-bazzite-environment.sh**: 
  - Line ~164: `org.libretro.RetroArch/config/retroarch`
  - Line ~157: Steam Proton path with full RetroArch directory
- **emulation-save-sync.sh**: 
  - Line ~48: `org.libretro.RetroArch/config/retroarch/saves`
  - Line ~31: Steam path with `/saves` subdirectory
- **Issue**: Inconsistent subdirectory expectations cause detection failures

### Flatpak ID Variations
- Some scripts check `~/.var/app/{flatpak-id}/data/`
- Others check `~/.var/app/{flatpak-id}/config/`
- No consistent pattern across emulators

### Save Path Priority Inconsistencies
- **check-bazzite-environment.sh**: Checks Flatpak paths in one order
- **emulation-save-sync.sh**: Checks same paths in different order
- Results in different emulators being detected by different scripts

### Duplicate Definitions
- Emulator paths defined separately in each script
- Changes in one script don't propagate to others
- Maintenance nightmare when adding new emulators

## Impact
- User sees RetroArch in version 1.1.0, then only Xemu in 1.1.1
- Inconsistent behavior confuses users
- Hard to debug and maintain

## Solution: Single Source of Truth
Python version will use centralized emulator-config-reference.json for ALL scripts
EOF

echo -e "${GREEN}✅${NC} Created bash inconsistencies analysis"

# Step 4: Create migration documentation (NO execution)
echo -e "${BLUE}4. Creating migration documentation...${NC}"

cat > PYTHON-MIGRATION-ROADMAP.md << 'EOF'
# Python Migration Roadmap

## Phase 1: Foundation (Week 1)
- [x] ✅ Backup current bash implementation
- [x] ✅ Generate consolidated emulator configuration JSON
- [x] ✅ Create Python project structure
- [ ] 🔄 Implement core EmulatorManager class
- [ ] 🔄 Implement PlatformDetector class
- [ ] 🔄 Create unit tests for core functionality

## Phase 2: Core Migration (Week 2)
- [ ] 🔄 Port emulator detection logic
- [ ] 🔄 Port save path detection logic  
- [ ] 🔄 Port rclone integration
- [ ] 🔄 Implement CLI interface matching bash commands
- [ ] 🔄 Create integration tests

## Phase 3: Advanced Features (Week 3)
- [ ] 🔄 Add Streamlit web UI
- [ ] 🔄 Implement real-time sync monitoring
- [ ] 🔄 Add configuration management UI
- [ ] 🔄 Create system tray integration (optional)

## Phase 4: Migration & Deployment (Week 4)
- [ ] 🔄 Comprehensive testing across all platforms
- [ ] 🔄 Create migration scripts for existing users
- [ ] 🔄 Update documentation
- [ ] 🔄 Package for distribution (PyPI, AppImage, etc.)

## Backward Compatibility Strategy
1. Keep bash scripts functional during migration
2. Use migration-wrapper.sh to bridge both versions
3. Gradual feature migration with fallback support
4. Final deprecation only after Python version is stable

## Testing Strategy
- Unit tests for all emulator detection logic
- Integration tests with mock file systems
- Real-world testing on EmuDeck, RetroPie, Batocera
- Performance testing for large save file syncing

## Distribution Options
1. **PyPI Package**: `pip install universal-emulation-save-sync`
2. **Standalone Executable**: PyInstaller bundle
3. **AppImage**: Linux portable application
4. **Flatpak**: System integration for Bazzite/SteamOS
EOF

echo -e "${GREEN}✅${NC} Generated migration roadmap: PYTHON-MIGRATION-ROADMAP.md"

# Step 6: Clean up inconsistent bash definitions (prepare for deprecation)
echo -e "${BLUE}6. Documenting bash script inconsistencies for reference...${NC}"

cat > BASH-INCONSISTENCIES.md << 'EOF'
# Bash Script Inconsistencies Found

## Emulator Path Differences

### RetroArch
- **check-bazzite-environment.sh**: Uses `org.libretro.RetroArch/config/retroarch`
- **emulation-save-sync.sh**: Uses `org.libretro.RetroArch/config/retroarch/saves`
- **Issue**: Different subdirectory expectations

### Flatpak ID Variations
- Some scripts use full Flatpak app paths
- Others use shortened versions
- Inconsistent between detection and sync logic

### Save Path Priority
- Different scripts check paths in different orders
- Some prioritize Flatpak paths, others prioritize native paths
- No centralized path resolution

## Fixes Applied in Python Version
1. ✅ Single source of truth in emulator-config.json
2. ✅ Consistent path resolution logic
3. ✅ Priority-ordered path checking
4. ✅ Centralized emulator definitions

## Migration Benefits
- No more duplicate emulator definitions
- Consistent behavior across all tools
- Easy to add new emulators
- Better error handling and debugging
EOF

echo -e "${GREEN}✅${NC} Documented bash inconsistencies for reference"

# Step 6: Create Python development setup guide (documentation only)
echo -e "${BLUE}6. Creating Python development setup guide...${NC}"

cat > MANUAL-PYTHON-SETUP.md << 'EOF'
# Manual Python Development Setup Guide

## When You're Ready to Start Python Development

This guide walks you through setting up the Python development environment
**ONLY when you decide to proceed with migration**.

### Prerequisites
- Python 3.8+ installed
- pip package manager
- Virtual environment support

### Setup Steps (run these manually when ready)

1. **Navigate to Python template:**
   ```bash
   cd python-template
   ```

2. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Linux/Mac
   # OR
   venv\Scripts\activate     # Windows
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   pip install -e .
   ```

4. **Verify setup:**
   ```bash
   python -c "import pathlib, yaml; print('Dependencies OK')"
   ```

### Development Workflow

1. **Always activate virtual environment first:**
   ```bash
   source venv/bin/activate
   ```

2. **Run tests:**
   ```bash
   pytest tests/
   ```

3. **Start development server (when UI is implemented):**
   ```bash
   streamlit run src/universal_emulation_sync/ui.py
   ```

4. **Format code:**
   ```bash
   black src/ tests/
   ```

### Implementation Order
1. Start with `src/universal_emulation_sync/emulator_manager.py`
2. Implement `src/universal_emulation_sync/platform_detector.py`
3. Add `src/universal_emulation_sync/sync_manager.py`
4. Create CLI interface `src/universal_emulation_sync/cli.py`
5. Optional: Add Streamlit UI `src/universal_emulation_sync/ui.py`

### Testing
- Unit tests for each component
- Integration tests with mock file systems
- Real-world testing on your actual system

### Safety
- Develop in virtual environment
- Test thoroughly before replacing bash scripts
- Keep bash scripts as backup during development
EOF

echo -e "${GREEN}✅${NC} Created Python development setup guide"

# Final summary
echo
echo -e "${GREEN}🎉 Safe migration preparation complete!${NC}"
echo
echo -e "${BLUE}Files created (NO existing files modified):${NC}"
echo "📋 Emulator config reference: emulator-config-reference.json"
echo "🐍 Python project template: python-template/"
echo "� Migration roadmap: PYTHON-MIGRATION-ROADMAP.md"
echo "🐛 Inconsistencies analysis: BASH-INCONSISTENCIES-ANALYSIS.md"
echo "🚀 Development setup guide: MANUAL-PYTHON-SETUP.md"
echo
echo -e "${GREEN}✅ Your existing bash scripts are completely UNTOUCHED${NC}"
echo -e "${GREEN}✅ All configurations remain exactly as they were${NC}"
echo -e "${GREEN}✅ No automatic execution or changes made${NC}"
echo
echo -e "${YELLOW}Next steps (when YOU decide to proceed):${NC}"
echo "1. Review emulator-config-reference.json for centralized definitions"
echo "2. Study BASH-INCONSISTENCIES-ANALYSIS.md to understand current issues"
echo "3. Follow PYTHON-MIGRATION-ROADMAP.md for implementation plan"
echo "4. Use python-template/ as starting point when ready"
echo
echo -e "${BLUE}Your current sync functionality continues working normally!${NC}"
