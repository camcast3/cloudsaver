# Changelog

All notable changes to the Universal Emulation Save Sync project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-08-27

### 🎯 MAJOR UPDATE: Universal Emulation Platform Support

**BREAKING CHANGES:**
- Renamed all scripts from `emudeck-*` to `emulation-save-*` for generic naming
- Changed default configuration directory from `~/.config/emudeck-sync/` to `~/.config/emulation-save-sync/`
- Updated log file names and paths to use generic naming

### Added
- 🌍 **Universal Platform Support**: Auto-detects and supports multiple emulation platforms:
  - EmuDeck (existing support maintained)
  - RetroPie (Raspberry Pi gaming distribution)
  - Batocera (multi-platform retro gaming OS)
  - EmulationStation (standalone frontend)
  - Lakka (lightweight retro gaming OS)
  - Custom/Generic emulator installations
- 🔍 **Intelligent Platform Detection**: Automatically detects which emulation platform is installed
- 🎯 **Platform-Specific Configuration**: Different default remote paths and behaviors per platform
- � **Bazzite System Support**: Enhanced detection and support for Bazzite (immutable Fedora-based OS)
- 🍺 **Homebrew Integration**: Prioritized Homebrew for rclone installation on Bazzite systems  
- 🎮 **Expanded Emulator Support**: Added support for 13 major emulators:
  - RetroArch (multi-system retro gaming)
  - Dolphin (GameCube/Wii)
  - PCSX2 (PlayStation 2) 
  - PPSSPP (PlayStation Portable)
  - DuckStation (PlayStation 1)
  - RPCS3 (PlayStation 3)
  - Cemu (Wii U)
  - Ryujinx (Nintendo Switch)
  - Yuzu (Nintendo Switch)
  - Citra (Nintendo 3DS)
  - melonDS (Nintendo DS)
  - Xemu (Original Xbox)
  - PrimeHack (Metroid Prime trilogy)
- 🔍 **Dynamic Path Detection**: Intelligent save path discovery system with fallback mechanisms
- 📋 **Advanced Path Management**: New commands for custom save path handling:
  - `detect <emulator>` - Show detected save paths for specific emulator
  - `set-path <emulator> <path>` - Set custom save path override
  - `reset-path <emulator>` - Reset emulator to use auto-detected path
- �🔄 **Backward Compatibility**: Existing EmuDeck users can continue using old script names via symlinks
- 📁 **Extensible Path System**: Prepared architecture for platform-specific emulator path configurations
- 🛠️ **Compatibility Script**: `create-compatibility-links.sh` for seamless transition
- 🔧 **Enhanced Environment Check**: Improved `check-bazzite-environment.sh` with Homebrew detection
- 📊 **Centralized Version Management**: Added VERSION file and version display across all scripts
- 📋 **Per-Emulator Testing Documentation**: Added testing guides for each supported emulator

### Changed
- 🔧 **Improved rclone Installation**: Better automatic installation for different Linux distributions
- 📚 **Enhanced Documentation**: Updated deployment guide with Bazzite-specific setup instructions
- 🔍 **Better Error Messaging**: More helpful guidance for missing dependencies and setup issues
- 🎮 **Extended Emulator Detection**: Environment check now detects all 13 supported emulators
- 📝 **Enhanced List Display**: The `list` command now shows path sources (default/detected/custom)
- **Script Names** (with backward compatibility):
  - `emudeck-sync.sh` → `emulation-save-sync.sh`
  - `emudeck-setup.sh` → `emulation-save-setup.sh`
  - `emudeck-wrapper.sh` → `emulation-save-wrapper.sh`
  - `emudeck-steam-launch.sh` → `emulation-steam-launcher.sh`
- **Service Files**:
  - `emudeck-sync@.service` → `emulation-save-sync@.service`
  - `emudeck-sync@.timer` → `emulation-save-sync@.timer`
- **Configuration Paths**:
  - Config: `~/.config/emudeck-sync/` → `~/.config/emulation-save-sync/`
  - Logs: `emudeck-sync.log` → `emulation-save-sync.log`
- **Project Identity**: 
  - "EmuDeck Save Sync" → "Universal Emulation Save Sync"
  - Updated all documentation and help text
  - Default remote path: `EmuDeck/saves` → `EmulationSaves` (with platform-specific overrides)

### Technical Architecture
- Added `detect_emulation_manager()` function for platform detection
- Added `init_emulation_manager()` for automatic platform initialization
- Prepared extensible architecture for platform-specific features
- Maintained all existing functionality while adding extensibility layer

### Fixed
- 🐧 **Bazzite rclone Installation**: Fixed automatic rclone installation on Bazzite systems using Homebrew
- 📁 **Emulator Path Detection**: Corrected Flatpak paths for various emulators
- 🔧 **Setup Script Dependencies**: Better handling of missing dependencies during initial setup

### Migration Notes
**For Existing EmuDeck Users:**
1. Run `./create-compatibility-links.sh` to maintain existing script functionality
2. Old script names will continue to work via symlinks
3. Configuration will be automatically migrated on first run
4. No manual changes required to existing Steam launch options or automation

## [1.0.0] - 2025-08-25

### Initial Release
- 🔄 **Core Save Sync**: Basic save synchronization functionality via rclone
- ☁️ **Nextcloud Integration**: Remote storage support through rclone configuration
- 🎮 **EmuDeck Emulator Support**: Initial support for major EmuDeck emulators (RetroArch, Dolphin, PCSX2, PPSSPP, DuckStation)
- 🔒 **Concurrency Protection**: File locking to prevent multiple sync operations
- 📝 **Logging System**: Configurable logging with timestamps and log rotation
- 🧪 **Dry-Run Mode**: Safe testing mode that shows what would be synced without actual changes
- 🖥️ **Multi-Platform**: Support for Linux and Windows (via WSL/Git Bash)
- 🧪 **Basic Testing**: Test runner script and built-in validation functions
- 📖 **Documentation**: Setup guides and deployment documentation