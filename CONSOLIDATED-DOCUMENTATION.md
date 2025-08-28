# CloudSaver: Universal Emulation Save Sync

![Version](https://img.shields.io/badge/version-1.1.1-blue.svg)

## A cross-platform tool for automatic cloud sync of emulation saves

---

## 📚 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Advanced Sync System Design](#advanced-sync-system-design)
- [Supported Platforms and Emulators](#supported-platforms-and-emulators)
- [Contributing](#contributing)
- [Changelog](#changelog)
- [Documentation Website Plan](#documentation-website-plan)
- [Test Suite](#test-suite)

---

## Overview

CloudSaver is a cross-platform tool that syncs emulator save files with cloud storage, similar to EmuDeck's Cloud Save functionality. It provides a convenient way to keep your game saves in sync across multiple devices.

The application automatically backs up and syncs your emulator save files to cloud storage, ensuring you never lose progress and can play across multiple devices and platforms.

---

## Features

- ✅ Auto-detects saves even in custom locations
- ✅ Supports 13+ major emulators
- ✅ Multi-platform: EmuDeck, RetroPie, Batocera, EmulationStation
- ✅ Multiple cloud providers: Nextcloud, Google Drive, OneDrive, Dropbox
- ✅ Steam Deck & Bazzite optimized
- ✅ One-command setup
- ✅ Automatic wrapper scripts for seamless syncing
- ✅ Cross-platform support (Windows, macOS, Linux)
- ✅ Command-line interface for manual syncing and configuration

---

## Quick Start

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
```

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/camcast3/cloudsaver.git
   cd cloudsaver
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Build the project:

   ```bash
   npm run build
   ```

---

## Usage

### Prerequisites

- Node.js 18 or higher
- [rclone](https://rclone.org/) for cloud storage integration

### Basic Commands

```bash
# Check your environment
./check-bazzite-environment.sh

# Manual sync operations
./emulation-save-sync.sh download    # Before gaming
./emulation-save-sync.sh upload      # After gaming
./emulation-save-sync.sh list        # Show detected emulators

# Advanced CLI
node dist/cli/index.js sync
node dist/cli/index.js detect
node dist/cli/index.js advanced-sync --direction upload --emulator dolphin
```

### Wrapper Scripts

Use the wrapper scripts to automatically sync before and after running an emulator:

```bash
# Linux/macOS
./cloudsaver-wrapper.sh /path/to/emulator [args...]

# Windows
.\cloudsaver-wrapper.ps1 C:\path\to\emulator.exe [args...]
```

---

## Configuration

Before using CloudSaver, you need to configure rclone and CloudSaver.

### rclone Configuration

1. Install rclone from [rclone.org](https://rclone.org/install/)
2. Configure a remote for your cloud storage provider:

   ```bash
   rclone config
   ```

   Follow the prompts to set up your cloud provider (Nextcloud, Google Drive, OneDrive, Dropbox, etc.)

### CloudSaver Configuration

The configuration file is located at:

- Linux/macOS: `~/.config/emulation-save-sync/config.json`
- Windows: `%APPDATA%\emulation-save-sync\config.json`

You can edit this file directly or use the configuration commands:

```bash
# CLI configuration
node dist/cli/index.js config set cloud.provider nextcloud
node dist/cli/index.js config set cloud.remote myremote
```

---

## Advanced Sync System Design

### Core Components

1. **ConfigManager**: Centralized configuration management with schema validation
2. **Platform Detection**: Runtime detection of operating system and environment
3. **Emulator Manager**: Discovery and management of supported emulators
4. **Sync Engine**: Handles bidirectional synchronization with cloud storage
5. **CLI Interface**: Command-line interface for user interaction
6. **Wrapper Scripts**: Pre/post execution hooks for emulators

### Design Decisions

1. **TypeScript & ES Modules**
   - **Decision**: Use TypeScript with ES modules for better type safety and modern import/export syntax
   - **Rationale**: Provides better code organization, type checking, and IDE support

2. **Singleton Pattern for Configuration**
   - **Decision**: Implement ConfigManager as a singleton
   - **Rationale**: Ensures consistent configuration access throughout the application

3. **External rclone Integration**
   - **Decision**: Use rclone as an external tool rather than implementing cloud storage APIs directly
   - **Rationale**: Leverages rclone's robust support for multiple cloud providers and authentication methods

4. **Wrapper Script Architecture**
   - **Decision**: Create platform-specific wrapper scripts (bash/PowerShell) with lock file mechanism
   - **Rationale**: Prevents concurrent syncs and provides a clean way to run pre/post emulator execution tasks

5. **Commander.js for CLI Structure**
   - **Decision**: Use Commander.js to structure the command-line interface
   - **Rationale**: Provides a clean, declarative way to define commands and options

6. **Winston for Logging**
   - **Decision**: Use Winston for structured logging
   - **Rationale**: Offers flexible log formats and transports

### Sync Process Flow

1. **Pre-Emulator Sync (Download)**
   - Lock acquisition to prevent concurrent operations
   - Check if cloud storage is configured
   - Download save files from cloud storage
   - Update local timestamp records

2. **Post-Emulator Sync (Upload)**
   - Lock acquisition to prevent concurrent operations
   - Check if cloud storage is configured
   - Upload modified save files to cloud storage
   - Update local timestamp records

3. **Conflict Resolution**
   - Timestamp-based conflict detection
   - Automatic resolution with configurable strategy (newer wins, local wins, cloud wins)
   - Optional backup of conflicted files

---

## Supported Platforms and Emulators

### Platforms

- 🐧 **EmuDeck** (Steam Deck, Linux gaming)
- 🍓 **RetroPie** (Raspberry Pi retro gaming)
- 🦇 **Batocera** (Multi-platform retro gaming OS)
- 🎮 **EmulationStation** (Standalone frontend)
- 🐟 **Lakka** (Lightweight retro gaming)
- 🔧 **Custom setups** (Any emulator installation)

### Emulators

- RetroArch
- Dolphin
- PCSX2
- PPSSPP
- Yuzu
- Ryujinx
- Citra
- DuckStation
- RPCS3
- Xemu
- melonDS
- mGBA
- And more...

---

## Contributing

### Adding Support for a New Emulator

CloudSaver has a modular design that makes it easy to add support for new emulators. Follow these steps to add support for a new emulator:

1. Create a new TypeScript file in the `src/emulators` directory for your emulator. Use the existing implementations as a reference:

```typescript
import path from 'path';
import fs from 'fs-extra';
import { logger } from '../core/logger.js';
import { Emulator } from '../core/emulator.js';

// Implementation for YourEmulator
export class YourEmulator implements Emulator {
  id = 'your-emulator-id';  // Unique identifier, lowercase with hyphens
  name = 'Your Emulator';   // Display name
  savePaths: string[] = []; // Will be populated in constructor
  saveExtensions = ['.sav', '.dat']; // File extensions for save files
  statePaths?: string[] = [];        // Optional paths for save states
  stateExtensions?: string[] = [];   // Optional extensions for save states
  configPaths?: string[] = [];       // Optional paths for configuration files
  
  constructor(detectedPaths: string[]) {
    this.savePaths = detectedPaths;
    logger.debug(`Initialized ${this.name} with save paths: ${this.savePaths.join(', ')}`);
  }
  
  /**
   * Get a list of all save files
   */
  async getAllSaveFiles(): Promise<string[]> {
    const files: string[] = [];
    
    for (const savePath of this.savePaths) {
      if (await fs.pathExists(savePath)) {
        const contents = await fs.readdir(savePath);
        for (const item of contents) {
          const itemPath = path.join(savePath, item);
          const stats = await fs.stat(itemPath);
          
          if (stats.isFile() && this.saveExtensions.some(ext => item.endsWith(ext))) {
            files.push(itemPath);
          }
        }
      }
    }
    
    return files;
  }
}
```

1. Add the new emulator to the emulator factory in `src/emulators/index.ts`.

1. Add platform-specific detection logic in the platform detector.

1. Add tests for the new emulator implementation.

1. Update documentation to include the new emulator.

---

## Changelog

### [1.2.0] - 2023-11-15

#### Added

- 🚀 **Node.js TypeScript CLI Interface**: Completely rewritten core in TypeScript with better architecture
- 🔄 **Advanced Sync Mode**: New command-line interface with advanced sync options
- 🎮 **Emulator Wrapper Scripts**: New scripts to automatically sync before and after running emulators
- 🌐 **Cross-Platform Wrapper Support**: Both bash and PowerShell wrapper scripts for all platforms
- 📝 **Comprehensive Sync Guide**: Added detailed SYNC-USAGE-GUIDE.md with instructions for all platforms
- ⏱️ **System Service Templates**: Added templates for systemd (Linux) and Task Scheduler (Windows)
- 🛠️ **Simplified Helper Scripts**: Added run-sync.sh and run-sync.ps1 for easy access to sync commands

#### Improved

- 🔍 **Emulator Detection**: Better algorithm for finding save directories
- 🔐 **Error Handling**: More robust error handling and reporting
- ⚙️ **Configuration Management**: Improved configuration system with validation
- 📊 **Logging**: Enhanced logging system for better troubleshooting

### [1.1.1] - 2025-08-27

#### Enhanced

- 🔍 **Enhanced Environment Detection**: `check-bazzite-environment.sh` now clearly distinguishes between:
  - **Installed Emulator Flatpaks**: Shows which emulators are available to use
  - **Existing Save Directories**: Shows which emulators have been run and created save folders
- 📚 **Clearer Documentation**: Updated user guide to explain environment check output more clearly
- 🎯 **Better User Experience**: Users now understand why only some emulators show up in the environment check

#### Fixed

- 🔧 **Environment Check Confusion**: Fixed misleading "Available emulators" description that confused users when only RetroArch appeared
- 📝 **Documentation Clarity**: Improved explanations of what the environment check actually detects

### [1.1.0] - 2025-08-27

#### 🎯 MAJOR UPDATE: Universal Emulation Platform Support

**BREAKING CHANGES:**

- Renamed all scripts from `emudeck-*` to `emulation-save-*` for generic naming
- Changed default configuration directory from `~/.config/emudeck-sync/` to `~/.config/emulation-save-sync/`
- Updated log file names and paths to use generic naming

---

## Documentation Website Plan

### Why a Documentation Website?

As CloudSaver grows to support:

- Multiple environments (Bazzite, SteamOS, Ubuntu, Windows, etc.)
- Multiple cloud providers (Nextcloud, Google Drive, OneDrive, Dropbox, etc.)
- Advanced features (path detection, custom configs, Steam integration)
- Different user skill levels (beginner to advanced)

A single markdown file becomes unwieldy and hard to navigate.

### Recommended Documentation Frameworks

#### Option 1: MkDocs (Recommended)

**Best for:** Technical documentation with great search and navigation

```bash
# Easy to set up
pip install mkdocs mkdocs-material
mkdocs new cloudsaver-docs
mkdocs serve  # Live preview
mkdocs build  # Static site for GitHub Pages
```

**Pros:**

- ✅ Markdown-based (easy migration from current docs)
- ✅ Material Design theme looks professional
- ✅ Built-in search
- ✅ GitHub Pages integration
- ✅ Mobile-friendly
- ✅ Code highlighting and copy buttons

#### Option 2: Docusaurus (Facebook's framework)

**Best for:** Larger projects with community features

- React-based with more customization
- Blog integration for changelog/updates
- Versioning support for multiple releases

#### Option 3: GitBook

**Best for:** Wiki-style documentation

- WYSIWYG editor
- Collaborative editing
- Good for non-technical contributors

---

## Test Suite

The test suite is designed to ensure reliability, security, performance, and correctness of the save synchronization functionality.

### Test Structure

```bash
tests/
├── run-all-tests.sh          # Master test runner
├── test-suite.sh             # Main test framework
├── unit-tests.sh             # Individual component tests
├── integration-tests.sh      # Full workflow tests
├── performance-tests.sh      # Speed and scalability tests
├── security-tests.sh         # Security and vulnerability tests
├── test-config.conf          # Test configuration
└── README.md                 # Documentation
```

### Test Suites

#### 1. Unit Tests (`unit-tests.sh`)

Tests individual components and functions in isolation:

- Configuration loading
- Emulator path detection
- Logging functionality
- File operations
- Error handling
- Lock file management

**Run with:** `./tests/unit-tests.sh`

#### 2. Integration Tests (`integration-tests.sh`)

Tests complete workflows and component interactions:

- Full sync workflows (upload/download)
- Wrapper script integration
- Steam launch integration
- Conflict resolution
- Large file handling
- Concurrent access protection

**Run with:** `./tests/integration-tests.sh`

#### 3. Performance Tests (`performance-tests.sh`)

Tests performance metrics and scalability:

- Large game library sync times
- Memory usage during sync
- Disk I/O optimization
- Bandwidth usage analysis
- Scaling with number of emulators

**Run with:** `./tests/performance-tests.sh`

#### 4. Security Tests (`security-tests.sh`)

Tests security and vulnerability aspects:

- Permissions verification
- Sensitive data handling
- Script injection protection
- File permission handling
- Cloud credential security

**Run with:** `./tests/security-tests.sh`

---

*This consolidated documentation combines information from multiple documentation files in the CloudSaver project. For the most up-to-date information, please refer to the individual documentation files.*
