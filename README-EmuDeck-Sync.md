# EmuDeck Save Sync with Nextcloud

A comprehensive solution for syncing EmuDeck emulation saves using rclone with your Nextcloud instance, similar to how EmuDeck's Cloud Save scripts work.

## Features

- 🔄 Automatic sync before and after emulator usage
- ☁️ Nextcloud integration via rclone
- 🎮 Support for all major emulators used by EmuDeck
- 🔒 File locking to prevent concurrent syncs
- 📝 Comprehensive logging
- 🚀 Steam integration
- ⏰ Periodic sync with systemd timers
- 🧪 Dry-run mode for testing
- 🖥️ Cross-platform support (Linux, Windows via WSL/Git Bash)
- 🔧 Automatic rclone installation
- 🧪 Comprehensive testing framework (200+ tests)

## Quick Usage Summary

### Linux/WSL Users
```bash
./emudeck-setup.sh          # Initial setup with auto-rclone install
./emudeck-sync.sh download   # Download saves before gaming
./emudeck-sync.sh upload     # Upload saves after gaming
```

### Windows Users
```powershell
.\setup-tests.ps1            # Setup Windows batch files and runners
.\run-tests.bat              # Test the system
# Then use WSL or Git Bash for main sync operations
```

### Testing
```bash
./run-all-tests.sh           # Run comprehensive test suite
.\Run-Tests.ps1              # Windows PowerShell test runner
```

## Supported Emulators

- RetroArch
- Dolphin (GameCube/Wii)
- PCSX2 (PlayStation 2)
- PPSSPP (PSP)
- DuckStation (PlayStation 1)
- RPCS3 (PlayStation 3)
- Cemu (Wii U)
- Ryujinx (Nintendo Switch)
- Yuzu (Nintendo Switch)
- Citra (Nintendo 3DS)
- melonDS (Nintendo DS)
- xemu (Original Xbox)
- PrimeHack (Metroid Prime)

## Files

- `emudeck-sync.sh` - Main sync script
- `emudeck-wrapper.sh` - Wrapper for automatic pre/post sync
- `emudeck-setup.sh` - Interactive setup script
- `emudeck-steam-launch.sh` - Steam integration script
- `emudeck-sync@.service` - Systemd service file
- `emudeck-sync@.timer` - Systemd timer for periodic sync

## Quick Start

### 1. Setup

Run the interactive setup script:

```bash
chmod +x *.sh
./emudeck-setup.sh
```

This will:
- Automatically install rclone if not present
- Configure rclone with your Nextcloud instance
- Create necessary directory structure
- Generate configuration files

### 2. Test the Setup

Check if everything is working:

```bash
./emudeck-sync.sh status
```

## Windows Usage

### Prerequisites

**Option 1: WSL (Windows Subsystem for Linux) - Recommended**
1. Install WSL2: `wsl --install`
2. Open WSL terminal and navigate to your project directory

**Option 2: Git Bash**
1. Install Git for Windows (includes Git Bash)
2. Open Git Bash and navigate to your project directory

### Setup for Windows

1. **Download/Clone the project** to your desired location (e.g., `C:\Users\YourName\Documents\homelab`)

2. **Run the Windows setup script** (in PowerShell):
   ```powershell
   cd C:\Users\YourName\Documents\homelab
   .\setup-tests.ps1
   ```
   This creates convenient batch files and PowerShell runners for easy testing.

3. **Configure the main sync system** (in WSL or Git Bash):
   ```bash
   chmod +x *.sh
   ./emudeck-setup.sh
   ```

### Running Tests on Windows

#### Option 1: Double-Click Batch Files
- `run-tests.bat` - Run all tests
- `run-unit-tests.bat` - Unit tests only  
- `run-integration-tests.bat` - Integration tests only
- `run-performance-tests.bat` - Performance tests only
- `run-security-tests.bat` - Security tests only
- `run-main-tests.bat` - Main test suite only
- `run-tests-gitbash.bat` - Alternative using Git Bash

#### Option 2: PowerShell Runner
```powershell
# Run all tests
.\Run-Tests.ps1

# Run specific test suite
.\Run-Tests.ps1 -TestSuite unit
.\Run-Tests.ps1 -TestSuite integration
.\Run-Tests.ps1 -TestSuite performance
.\Run-Tests.ps1 -TestSuite security

# Use Git Bash instead of WSL
.\Run-Tests.ps1 -GitBash
```

#### Option 3: Direct Commands
```bash
# In WSL
wsl -- bash ./run-all-tests.sh

# In Git Bash  
bash ./run-all-tests.sh
```

### Running the Sync System on Windows

#### Via WSL (Recommended)
```bash
# In WSL terminal
./emudeck-sync.sh download
./emudeck-sync.sh upload
```

#### Via Git Bash
```bash
# In Git Bash
./emudeck-sync.sh download
./emudeck-sync.sh upload
```

## Testing Framework

### Comprehensive Test Suites

The project includes a comprehensive testing framework with 200+ individual tests across multiple suites:

#### Test Suite Overview
- **Unit Tests** (`tests/unit-tests.sh`) - Test individual functions and components
- **Integration Tests** (`tests/integration-tests.sh`) - Test complete workflows and interactions  
- **Performance Tests** (`tests/performance-tests.sh`) - Test speed, memory usage, and scalability
- **Security Tests** (`tests/security-tests.sh`) - Test security features and vulnerability protection
- **Main Test Suite** (`test-suite.sh`) - Test basic functionality and error handling

#### Test Runner Options
```bash
# Run all tests (except performance by default)
./run-all-tests.sh

# Run all tests including performance tests
./run-all-tests.sh --all

# Run specific test suites
./run-all-tests.sh --unit --integration
./run-all-tests.sh --security
./run-all-tests.sh --performance

# Verbose output with detailed reporting
./run-all-tests.sh -v --report test-results.txt

# Stop on first failure for debugging
./run-all-tests.sh -s --stop-on-fail
```

#### Automatic Dependency Installation

The scripts now automatically handle rclone installation:
- **Package Manager Support**: apt, yum, dnf, pacman, homebrew
- **Manual Installation**: Direct download with architecture detection
- **Cross-Platform**: Linux, macOS, and Windows (via WSL)
- **Fallback Options**: Multiple installation methods with graceful degradation

If rclone is not found, the scripts will:
1. Try to install via your system's package manager
2. Fall back to manual download and installation to `~/.local/bin`
3. Provide clear instructions if automatic installation fails

### 3. Test the Setup

Check if everything is working:

```bash
./emudeck-sync.sh status
```

## Complete Project Structure

```
homelab/
├── emudeck-sync.sh              # Main sync script
├── emudeck-wrapper.sh           # Wrapper for automatic pre/post sync
├── emudeck-setup.sh             # Interactive setup script  
├── emudeck-steam-launch.sh      # Steam integration script
├── emudeck-sync@.service        # Systemd service file
├── emudeck-sync@.timer          # Systemd timer for periodic sync
├── setup-emudeck-sync.sh        # Alternative setup script
├── install.sh                   # Installation helper
├── run-all-tests.sh             # Master test runner
├── test-suite.sh                # Main test suite
├── setup-tests.ps1              # Windows test setup (PowerShell)
├── Run-Tests.ps1                # PowerShell test runner
├── run-*.bat                    # Windows batch files for testing
├── tests/
│   ├── unit-tests.sh            # Unit test suite
│   ├── integration-tests.sh     # Integration test suite  
│   ├── performance-tests.sh     # Performance test suite
│   ├── security-tests.sh        # Security test suite
│   ├── test-suite.sh            # Additional test utilities
│   └── README.md               # Test documentation
└── README-EmuDeck-Sync.md      # This documentation
```

### 4. Manual Sync

Download saves before gaming:
```bash
./emudeck-sync.sh download
```

Upload saves after gaming:
```bash
./emudeck-sync.sh upload
```

Sync specific emulator only:
```bash
./emudeck-sync.sh download retroarch
./emudeck-sync.sh upload dolphin
```

### 4. Automatic Sync with Wrapper

Use the wrapper to automatically sync before and after emulator usage:

```bash
./emudeck-wrapper.sh retroarch retroarch --menu
./emudeck-wrapper.sh dolphin dolphin-emu-nogui -b -e "/path/to/game.iso"
```

## Advanced Usage

### Steam Integration

For automatic sync when launching games through Steam:

1. Copy `emudeck-steam-launch.sh` to a permanent location
2. In Steam, right-click a game → Properties → Launch Options
3. Add: `/path/to/emudeck-steam-launch.sh %command%`

### Periodic Sync with Systemd

For automatic periodic syncing (every 30 minutes):

```bash
# Copy service files to systemd directory
sudo cp emudeck-sync@.service /etc/systemd/system/
sudo cp emudeck-sync@.timer /etc/systemd/system/

# Enable and start timer for your user
sudo systemctl enable emudeck-sync@$USER.timer
sudo systemctl start emudeck-sync@$USER.timer

# Check status
systemctl status emudeck-sync@$USER.timer
```

## Configuration

The main configuration file is located at `~/.config/emudeck-sync/config.conf`:

```bash
# Rclone remote name (must be configured in rclone)
RCLONE_REMOTE="nextcloud"

# Remote path where saves will be stored
RCLONE_REMOTE_PATH="EmuDeck/saves"

# Local base path for saves
LOCAL_SAVES_BASE="$HOME/.var/app"

# Enable logging
ENABLE_LOGGING=true

# Sync timeout in seconds
SYNC_TIMEOUT=300

# Dry run mode (test without actually syncing)
DRY_RUN=false

# Verbose output
VERBOSE=false
```

## Command Reference

### emudeck-sync.sh

```bash
# Download saves from cloud
./emudeck-sync.sh download [emulator]

# Upload saves to cloud
./emudeck-sync.sh upload [emulator]

# List available emulators
./emudeck-sync.sh list

# Show status and configuration
./emudeck-sync.sh status

# Show current configuration
./emudeck-sync.sh config

# Options
-h, --help      Show help
-v, --verbose   Enable verbose output
-n, --dry-run   Perform dry run without syncing
-c, --config    Use custom configuration file
```

### emudeck-wrapper.sh

```bash
./emudeck-wrapper.sh [emulator_name] [command] [args...]

# Examples:
./emudeck-wrapper.sh retroarch retroarch
./emudeck-wrapper.sh dolphin dolphin-emu-nogui -b -e "game.iso"
./emudeck-wrapper.sh pcsx2 pcsx2 "game.iso"
```

## Directory Structure

### Local Saves (automatically detected)
```
~/.var/app/
├── com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/
├── org.DolphinEmu.dolphin-emu/data/dolphin-emu/
├── net.pcsx2.PCSX2/data/pcsx2/
├── org.ppsspp.PPSSPP/config/ppsspp/
└── ...
```

### Nextcloud Structure (created automatically)
```
EmuDeck/
└── saves/
    ├── retroarch/
    ├── dolphin/
    ├── pcsx2/
    ├── ppsspp/
    └── ...
```

### Configuration and Logs
```
~/.config/emudeck-sync/
├── config.conf
└── logs/
    ├── emudeck-sync.log
    ├── wrapper.log
    └── steam-launch.log
```

## Troubleshooting

### Common Issues

1. **"rclone remote not configured"**
   - Run `./emudeck-setup.sh` to configure rclone
   - Or manually run `rclone config` and create a remote named "nextcloud"

2. **"Permission denied"**
   - Make sure scripts are executable: `chmod +x *.sh`

3. **"Connection failed"**
   - Check your Nextcloud URL and credentials
   - Ensure your Nextcloud instance is accessible
   - Try testing with `rclone lsd nextcloud:`

4. **"Save path not found"**
   - Emulator hasn't been run yet, or non-standard installation
   - Check actual paths with `./emudeck-sync.sh list`

### Windows-Specific Issues

1. **WSL not working**
   - Ensure WSL2 is installed: `wsl --install`
   - Check WSL status: `wsl --status`
   - Try updating WSL: `wsl --update`

2. **Git Bash path issues**
   - Ensure Git for Windows is properly installed
   - Check that bash is in your PATH
   - Try running Git Bash directly and navigating to project folder

3. **PowerShell execution policy**
   - If scripts won't run, try: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

4. **Batch files not working**
   - Ensure you're in the correct directory
   - Try running `setup-tests.ps1` again to regenerate batch files
   - Check that WSL is properly configured

5. **Path conversion issues**
   - The new scripts avoid complex path conversions
   - If you have old batch files, delete them and run `setup-tests.ps1` again

### Linux/WSL Specific Issues

1. **rclone auto-installation fails**
   - Check internet connection
   - Try manual installation: `sudo apt install rclone` (Ubuntu/Debian)
   - Or download directly from: <https://rclone.org/install/>

2. **Missing dependencies for tests**
   - Install bc calculator: `sudo apt install bc`
   - Install curl/wget: `sudo apt install curl wget unzip`

### Debug Mode

Enable verbose logging and dry-run mode:

```bash
./emudeck-sync.sh -v -n download
```

### Logs

Check logs for issues:

```bash
# Main sync log
tail -f ~/.config/emudeck-sync/logs/emudeck-sync.log

# Wrapper log
tail -f ~/.config/emudeck-sync/logs/wrapper.log

# Steam launch log
tail -f ~/.config/emudeck-sync/logs/steam-launch.log
```

## Installation Methods

### Method 1: Interactive Setup (Recommended)

The easiest way to get started:

```bash
chmod +x *.sh
./emudeck-setup.sh
```

This script will:
- Check and install rclone automatically
- Guide you through Nextcloud configuration
- Set up directory structure
- Create configuration files
- Test your setup

### Method 2: Alternative Setup Script

```bash
chmod +x *.sh  
./setup-emudeck-sync.sh
```

### Method 3: Installation Helper

```bash
chmod +x *.sh
./install.sh
```

### Method 4: Manual Configuration

1. Install rclone manually
2. Configure rclone: `rclone config`
3. Create remote named "nextcloud" 
4. Edit `~/.config/emudeck-sync/config.conf`
5. Test with `./emudeck-sync.sh status`

## Configuration Options

### Environment Variables

You can override configuration settings using environment variables:

```bash
# Override remote name
export RCLONE_REMOTE="mycloud"

# Override remote path
export RCLONE_REMOTE_PATH="GameSaves/EmuDeck"

# Enable dry-run mode
export DRY_RUN=true

# Enable verbose output
export VERBOSE=true

# Custom configuration file
export CONFIG_FILE="/path/to/custom/config.conf"
```

### Advanced rclone Configuration

For better performance and reliability, consider these rclone settings:

```bash
# Edit rclone config
rclone config

# Recommended settings for Nextcloud:
# - Use WebDAV
# - Enable checksums if supported
# - Set appropriate timeout values
# - Consider bandwidth limits if needed
```

## Security Considerations

- Consider using Nextcloud app passwords instead of your main password
- The password is stored obscured by rclone, but not encrypted
- Logs may contain file paths but no sensitive data
- Lock files prevent concurrent access but don't encrypt data in transit

## Requirements

- Linux system with bash
- rclone installed and configured
- Nextcloud instance with WebDAV access
- EmuDeck installed (or compatible save directory structure)

## Installation Requirements

### Arch Linux / SteamOS
```bash
sudo pacman -S rclone
```

### Ubuntu / Debian
```bash
sudo apt install rclone
```

### Fedora
```bash
sudo dnf install rclone
```

### Manual Installation
Download from: https://rclone.org/install/

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Use at your own risk. Always backup your save files before using any sync solution.**

## Bazzite/SteamOS Deployment

### Quick Start for Bazzite Users

After cloning this repository to your Bazzite machine:

```bash
# 1. Check your environment
./check-bazzite-environment.sh

# 2. Make scripts executable
chmod +x *.sh

# 3. Set up with existing Nextcloud configuration
./emudeck-setup.sh
# OR transfer existing config
./transfer-config.sh

# 4. Test with real emulators
./test-real-emulators.sh

# 5. Use the system
./emudeck-sync.sh download    # Before gaming
./emudeck-sync.sh upload      # After gaming
```

### For Production Gaming

Once tested, use the wrapper for automatic sync:
```bash
# Launch emulator with automatic sync
./emudeck-wrapper.sh retroarch retroarch

# Or integrate with Steam launch options:
# /path/to/emudeck-wrapper.sh retroarch %command%
```

See `DEPLOYMENT-GUIDE.md` for comprehensive deployment instructions.

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve this sync solution.

---

**Note**: This script is inspired by and designed to work similarly to EmuDeck's built-in Cloud Save functionality, but operates independently and requires your own Nextcloud instance.
