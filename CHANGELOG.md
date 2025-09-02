# Changelog

All notable changes to the Universal Emulation Save Sync project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2023-11-15

### Added

- 🚀 **Node.js TypeScript CLI Interface**: Completely rewritten core in TypeScript with better architecture
- 🔄 **Advanced Sync Mode**: New command-line interface with advanced sync options
- 🎮 **Emulator Wrapper Scripts**: New scripts to automatically sync before and after running emulators
- 🌐 **Cross-Platform Wrapper Support**: Both bash and PowerShell wrapper scripts for all platforms
- 📝 **Comprehensive Sync Guide**: Added detailed SYNC-USAGE-GUIDE.md with instructions for all platforms
- ⏱️ **System Service Templates**: Added templates for systemd (Linux) and Task Scheduler (Windows)
- 🛠️ **Simplified Helper Scripts**: Added run-sync.sh and run-sync.ps1 for easy access to sync commands

### Improved

- 🔍 **Emulator Detection**: Better algorithm for finding save directories
- 🔐 **Error Handling**: More robust error handling and reporting
- ⚙️ **Configuration Management**: Improved configuration system with validation
- 📊 **Logging**: Enhanced logging system for better troubleshooting

## [1.1.1] - 2025-08-31

### 🚀 Major Features Added

- **Standalone Executables**: True zero-dependency distribution system
  - Windows executable (43MB) with embedded Node.js v18.20.8 runtime
  - Linux executable (51MB) with embedded Node.js v18.20.8 runtime  
  - macOS executable (55MB) with embedded Node.js v18.20.8 runtime
  - No Node.js, npm, or software installation required for end users

### 🎮 Comprehensive Emulator Support

- **Expanded from 8 to 22 emulators** - 175% increase in emulator coverage
- **Console Emulators Added**: ePSXe, ShadPS4, Xenia, xemu  
- **Handheld Emulators Added**: Vita3K, Ryujinx, Lime3DS, melonDS, mGBA
- **Specialty Emulators Added**: Flycast, ScummVM, Mednafen, MAME, Supermodel, Azahar
- **All requested emulators supported**: vita3k, retroarch, pcsx2, duckstation confirmed working

### 🔧 Technical Infrastructure

- **Build Pipeline**: esbuild + @yao-pkg/pkg for standalone executable creation
- **ESM Compatibility**: Full ES module support with CommonJS bundling for pkg
- **Cross-Platform Builds**: Automated builds for Windows, Linux, macOS via npm scripts
- **Bundle Optimization**: 1.6MB core bundle + Node.js runtime = 43-55MB total per platform

### 📚 Documentation Consolidation

- **Streamlined Documentation**: Consolidated 13+ markdown files into 3 essential files
- **DOCUMENTATION.md**: Comprehensive installation, usage, and feature guide
- **README.md**: Updated with accurate file sizes and emulator counts
- **Clean Project Structure**: Removed redundant development summaries and duplicate guides

### 🧪 Testing & Quality

- **Test Coverage**: 96.4% success rate (26/28 tests passing)
- **Jest Integration**: Full ES module testing support maintained
- **Cross-Platform Validation**: Windows executable tested and verified
- **CI/CD Ready**: GitHub Actions configured for automated builds and releases

### Improved

- 🔍 **Enhanced Environment Detection**: `check-bazzite-environment.sh` now clearly distinguishes between:
  - **Installed Emulator Flatpaks**: Shows which emulators are available to use
  - **Existing Save Directories**: Shows which emulators have been run and created save folders
- 📚 **Clearer Documentation**: Updated user guide to explain environment check output more clearly
- 🎯 **Better User Experience**: Users now understand why only some emulators show up in the environment check

### Fixed

- 🔧 **Environment Check Confusion**: Fixed misleading "Available emulators" description that confused users when only RetroArch appeared
- 📝 **Documentation Clarity**: Improved explanations of what the environment check actually detects

## [1.1.0] - 2025-08-27

### 🎯 MAJOR UPDATE: Universal Emulation Platform Support

**BREAKING CHANGES:**

- Renamed all scripts from `emudeck-*` to `emulation-save-*` for generic naming
- Changed default configuration directory from `~/.config/emudeck-sync/` to `~/.config/emulation-save-sync/`
- Updated log file names and paths to use generic naming

### New Features

- 🌍 **Universal Platform Support**: Auto-detects and supports multiple emulation platforms:
  - EmuDeck (Steam Deck)
  - RetroPie (Raspberry Pi, etc.)
  - Batocera (dedicated gaming systems)
  - EmulationStation (desktop systems)
  - Custom setups (manual configurations)
- 🎮 **Universal Emulator Support**: Expanded from Steam Deck focus to all platforms:
  - RetroArch (multi-system)
  - Dolphin (GameCube/Wii)
  - PCSX2 (PlayStation 2)
  - RPCS3 (PlayStation 3)
  - Yuzu (Nintendo Switch)
  - Ryujinx (Nintendo Switch)
  - Citra (Nintendo 3DS)
  - PPSSPP (PSP)
  - Duckstation (PlayStation)
  - melonDS (Nintendo DS)
  - Cemu (Wii U)
  - PrimeHack (Metroid Prime)
  - And more!
- 🔄 **Cross-Platform Sync Compatibility**: Ensure saves work across different emulation platforms
- 🔧 **Dynamic Configuration**: Adapt settings based on detected platform
- 📋 **Platform-Aware Paths**: Auto-adjust paths based on platform conventions
- 🌟 **Platform-Specific Optimizations**: Specialized handling for each platform's quirks

### Changed

- 🔧 **Improved rclone Installation**: Better automatic installation for different Linux distributions
- 📂 **Path Structure**: More logical organization of configuration files
- 🔔 **Notifications**: Platform-aware notification methods
- 🔑 **Permissions Handling**: Better approach to file ownership on different systems
- 🔍 **Detection Logic**: More sophisticated platform and emulator detection
- 🔄 **Sync Strategy**: Optimized based on platform capabilities
- 🗄️ **Data Organization**: More consistent storage of configuration and logs
- 📚 **Documentation**: Completely rewritten for platform-agnostic approach
- 🖼️ **Project Branding**: Updated to reflect universal support rather than EmuDeck-specific
- 🔧 **Defaults**: Better starting configuration for each platform
- 🔌 **Integrations**: More flexibility in how the tool integrates with various systems
- 🌐 **Project Identity**: Universal Emulation Save Sync instead of EmuDeck-specific tool

### Technical Architecture

- Added `detect_emulation_manager()` function for platform detection
- Restructured configuration to support multiple platforms
- Added platform-specific path resolution
- Enhanced logging with platform context

### Resolved Issues

- 🐧 **Bazzite rclone Installation**: Fixed automatic rclone installation on Bazzite systems using Homebrew
- 🔄 **Sync Path Conflicts**: Resolved issues with paths that differ across platforms

### Migration Notes

1. Run `./create-compatibility-links.sh` to maintain existing script functionality
2. Update any custom scripts to use the new file names
3. Check the configuration at `~/.config/emulation-save-sync/` after migration

## [1.0.0] - 2025-08-01

### Added

- Initial release
- Support for EmuDeck on Steam Deck
- Basic cloud sync functionality using rclone
- Support for RetroArch, Dolphin, PCSX2 emulators
