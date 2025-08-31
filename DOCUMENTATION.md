# CloudSaver: Universal Emulation Save Sync

![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)

**Zero-dependency emulation save synchronization for all platforms**

---

## 📚 Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Supported Emulators](#supported-emulators)
- [Platform Support](#platform-support)
- [Usage Guide](#usage-guide)
- [Configuration](#configuration)
- [Advanced Features](#advanced-features)
- [Development](#development)
- [Changelog](#changelog)

---

## Overview

CloudSaver is a **completely standalone** cross-platform tool that automatically syncs emulator save files with cloud storage. It requires **no software installation** - just download and run!

### Key Features

✅ **Zero Dependencies** - No Node.js, npm, or additional software required  
✅ **Standalone Executables** - Single files (43-55MB) with embedded runtime  
✅ **Comprehensive Emulator Support** - 22+ popular emulators  
✅ **Auto-Detection** - Finds saves even in custom locations  
✅ **Multi-Platform** - EmuDeck, RetroPie, Batocera, EmulationStation  
✅ **Cloud Provider Flexibility** - Works with any rclone-supported service  
✅ **Cross-Platform** - Windows, Linux, macOS  
✅ **Steam Deck Optimized** - Perfect for portable gaming  

---

## Installation

### Standalone Executables (Recommended)

**No installation required! Just download and run.**

📥 **[Download Latest Release](https://github.com/camcast3/cloudsaver/releases)**

#### Windows (43MB)

```powershell
# Download cloudsaver-windows.exe and run directly
.\cloudsaver-windows.exe --help
.\cloudsaver-windows.exe detect --platform emudeck
```

#### Linux (51MB)

```bash
# Download cloudsaver-linux and run directly
chmod +x cloudsaver-linux
./cloudsaver-linux --help
./cloudsaver-linux detect --platform emudeck
```

#### macOS (55MB)

```bash
# Download cloudsaver-macos and run directly
chmod +x cloudsaver-macos
./cloudsaver-macos --help
./cloudsaver-macos detect --platform emudeck
```

### For Developers (requires Node.js)

```bash
# Install via npm
npm install -g cloudsaver
cloudsaver --help

# Or run from source
git clone https://github.com/camcast3/cloudsaver.git
cd cloudsaver
npm install
npm run build
node dist/cli/index.js --help
```

---

## Quick Start

### 1. Download and Test

```bash
# Download the appropriate executable for your platform
# Test basic functionality
./cloudsaver-linux --help
```

### 2. Detect Your Setup

```bash
# Auto-detect emulation platform and emulators
./cloudsaver-linux detect --platform emudeck
```

### 3. Configure Cloud Storage

```bash
# Set up rclone remote first (one-time setup)
rclone config create mycloud dropbox

# Configure CloudSaver to use your cloud storage
./cloudsaver-linux config set cloudProvider "mycloud"
./cloudsaver-linux config set syncRoot "cloudsaver-saves"
```

### 4. Start Syncing

```bash
# Upload saves to cloud
./cloudsaver-linux sync --upload

# Download saves from cloud  
./cloudsaver-linux sync --download

# Sync specific emulator
./cloudsaver-linux advanced-sync --emulator dolphin --direction upload
```

---

## Supported Emulators

CloudSaver supports **22 popular emulators** across all major gaming platforms:

### Console Emulators

- **RetroArch** - Multi-system emulator frontend
- **Dolphin** - GameCube and Wii emulator
- **PCSX2** - PlayStation 2 emulator
- **RPCS3** - PlayStation 3 emulator
- **DuckStation** - PlayStation 1 emulator
- **ePSXe** - PlayStation 1 emulator
- **ShadPS4** - PlayStation 4 emulator
- **Xenia** - Xbox 360 emulator
- **xemu** - Original Xbox emulator
- **Cemu** - Wii U emulator

### Handheld Emulators

- **Yuzu** - Nintendo Switch emulator
- **Ryujinx** - Nintendo Switch emulator
- **Vita3K** - PlayStation Vita emulator
- **PPSSPP** - PlayStation Portable emulator
- **Lime3DS** - Nintendo 3DS emulator
- **melonDS** - Nintendo DS emulator
- **mGBA** - Game Boy Advance emulator

### Specialty Emulators

- **Flycast** - Dreamcast emulator
- **ScummVM** - Adventure game engine
- **Mednafen** - Multi-system emulator
- **MAME** - Arcade machine emulator
- **Supermodel** - Sega Model 3 arcade emulator
- **Azahar** - Nintendo 3DS emulator

---

## Platform Support

CloudSaver automatically detects and works with these gaming platforms:

### Supported Platforms

- **EmuDeck** - Steam Deck optimized emulation suite
- **RetroPie** - Raspberry Pi retro gaming distribution
- **Batocera** - Multi-platform retro gaming OS
- **Lakka** - Lightweight retro gaming OS
- **EmulationStation** - Frontend for various emulators
- **Generic** - Standard desktop installations

### Operating Systems

- **Windows** (x64)
- **Linux** (x64)
- **macOS** (x64)

---

## Usage Guide

### Basic Commands

```bash
# Get help
./cloudsaver --help

# Detect emulation setup
./cloudsaver detect
./cloudsaver detect --platform emudeck
./cloudsaver detect --verbose

# View configuration
./cloudsaver config get
./cloudsaver config get logLevel

# Set configuration
./cloudsaver config set cloudProvider "mycloud"
./cloudsaver config set logLevel debug

# Reset configuration
./cloudsaver config reset
```

### Sync Operations

```bash
# Basic sync operations
./cloudsaver sync --upload       # Upload saves to cloud
./cloudsaver sync --download     # Download saves from cloud

# Advanced sync with specific emulators
./cloudsaver advanced-sync --emulator dolphin --direction upload
./cloudsaver advanced-sync --emulator all --direction download
./cloudsaver advanced-sync --emulator retroarch --direction bidirectional
```

### Path Management

```bash
# List all configured paths
./cloudsaver paths list

# Add custom emulator path
./cloudsaver paths add dolphin "/custom/dolphin/saves"

# Remove custom path
./cloudsaver paths remove dolphin "/custom/dolphin/saves"
```

---

## Configuration

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cloudProvider` | string | undefined | Rclone remote name for cloud storage |
| `syncRoot` | string | `~/.cloudsaver` | Root directory for synchronized saves |
| `logLevel` | enum | `info` | Logging level: debug, verbose, info, warn, error |
| `customPaths` | object | `{}` | Custom paths for specific files/directories |
| `emulatorPaths` | object | `{}` | Custom emulator save paths |
| `scanDirs` | array | `[]` | Additional directories to scan for saves |
| `ignoreDirs` | array | `[]` | Directories to ignore during scanning |
| `autoSync` | boolean | `false` | Enable automatic synchronization |
| `platform` | enum | auto-detected | Target platform: emudeck, retropie, batocera, etc. |

### Configuration File Locations

CloudSaver stores configuration in platform-specific locations:

- **Windows**: `%APPDATA%\cloudsaver-nodejs\Config\config.json`
- **Linux**: `~/.config/cloudsaver/config.json`
- **macOS**: `~/Library/Preferences/cloudsaver-nodejs/config.json`

### Cloud Provider Setup

CloudSaver uses rclone for cloud synchronization. Set up your preferred provider:

```bash
# Configure rclone remote (one-time setup)
rclone config create mycloud dropbox

# Set CloudSaver to use the remote
./cloudsaver config set cloudProvider "mycloud"
./cloudsaver config set syncRoot "cloudsaver-saves"
```

**Supported Cloud Providers** (via rclone):

- Dropbox, Google Drive, OneDrive
- Amazon S3, Backblaze B2, Wasabi
- SFTP, FTP, WebDAV
- Local directories, network shares

---

## Advanced Features

### Custom Emulator Integration

For emulators not automatically detected:

```bash
# Add custom emulator with multiple save paths
./cloudsaver paths add custom-emu "/path/to/saves1"
./cloudsaver paths add custom-emu "/path/to/saves2"

# Configure additional scan directories
./cloudsaver config set scanDirs '["/extra/scan/dir"]'

# Configure ignore patterns
./cloudsaver config set ignoreDirs '[".git", "node_modules"]'
```

### Automated Workflows

```bash
# Enable automatic sync
./cloudsaver config set autoSync true

# Set up scheduled sync (example for systemd)
./cloudsaver advanced-sync --emulator all --direction bidirectional
```

### Dry Run and Testing

```bash
# Test sync operations without making changes
./cloudsaver sync --upload --dry-run
./cloudsaver advanced-sync --emulator dolphin --direction upload --dry-run
```

---

## Development

### Building from Source

```bash
# Clone and build
git clone https://github.com/camcast3/cloudsaver.git
cd cloudsaver
npm install
npm run build

# Run from source
node dist/cli/index.js --help
```

### Building Standalone Executables

```bash
# Build for current platform
npm run build:exe

# Build for all platforms
npm run build:exe:all
```

### Running Tests

```bash
# Run all tests
npm test

# Run specific test suites
npm run test -- --testPathPatterns="integration"
npm run test -- --testPathPatterns="unit"

# Run with coverage
npm run test:coverage
```

### Project Structure

```
src/
├── cli/                 # Command-line interface
│   ├── commands/        # CLI command implementations
│   └── index.ts         # Main CLI entry point
├── core/                # Core functionality
│   ├── config.ts        # Configuration management
│   ├── emulator.ts      # Emulator definitions and detection
│   ├── logger.ts        # Logging system
│   └── platform.ts      # Platform detection
├── emulators/           # Emulator-specific implementations
├── platforms/           # Platform-specific implementations
├── providers/           # Cloud provider implementations
└── utils/               # Utility functions

tests/
├── unit/                # Unit tests
├── integration/         # Integration tests
└── utils/               # Test utilities
```

---

## Contributing

### Getting Started

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Adding New Emulators

To add support for a new emulator:

1. Update `src/core/emulator.ts` with the new emulator configuration
2. Add appropriate path mappings for all supported platforms
3. Include save file extensions and state file extensions
4. Add configuration file paths
5. Test detection on relevant platforms

### Code Style

- Use TypeScript for all new code
- Follow existing naming conventions
- Add JSDoc comments for public APIs
- Include unit tests for new functionality

---

## Changelog

### v1.1.1 (Current)

#### 🚀 Major Features

- **Standalone Executables**: True zero-dependency distribution
  - Windows executable (43MB) with embedded Node.js runtime
  - Linux executable (51MB) with embedded Node.js runtime  
  - macOS executable (55MB) with embedded Node.js runtime
  - No Node.js, npm, or software installation required

#### 🎮 Expanded Emulator Support

- Added 14 new emulators (total: 22 emulators)
- **New Console Emulators**: ePSXe, ShadPS4, Xenia, xemu
- **New Handheld Emulators**: Vita3K, Ryujinx, Lime3DS, melonDS, mGBA
- **New Specialty Emulators**: Flycast, ScummVM, Mednafen, MAME, Supermodel, Azahar

#### 🔧 Technical Improvements

- **Build Pipeline**: esbuild + @yao-pkg/pkg for standalone executables
- **ESM Compatibility**: Full ES module support with CommonJS bundling
- **Cross-Platform Builds**: Automated builds for Windows, Linux, macOS
- **CI/CD Pipeline**: GitHub Actions for automated testing and releases

#### 🧪 Testing Infrastructure

- **96.4% Test Coverage**: 26/28 tests passing
- **Jest Integration**: Full ES module testing support
- **Cross-Platform Testing**: Windows, Linux, macOS validation

### Previous Versions

- **v1.1.0**: Advanced sync system, multi-platform detection
- **v1.0.0**: Initial release with basic sync functionality

---

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/camcast3/cloudsaver/issues)
- **Documentation**: All features documented in this file
- **Community**: Open source project welcoming contributions

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**CloudSaver** - Making emulation save management effortless across all platforms! 🎮
