# EmuDeck Save Sync - Repository Migration Guide

## 🔄 Moving to Dedicated Repository

This guide helps you move the EmuDeck Save Sync project to its own dedicated repository.

## 📁 Files to Move

### Core EmuDeck Sync System
```
emudeck-sync.sh              # Main sync script
emudeck-wrapper.sh           # Wrapper for automatic pre/post sync  
emudeck-setup.sh             # Interactive setup script
emudeck-steam-launch.sh      # Steam integration script
emudeck-sync@.service        # Systemd service file
emudeck-sync@.timer          # Systemd timer for periodic sync
install.sh                   # Installation helper
```

### Testing Framework
```
run-all-tests.sh             # Master test runner
test-suite.sh                # Main test suite
setup-tests.ps1              # Windows test setup (PowerShell)
Run-Tests.ps1                # PowerShell test runner
tests/                       # Test directory containing:
├── unit-tests.sh            # Unit test suite
├── integration-tests.sh     # Integration test suite  
├── performance-tests.sh     # Performance test suite
├── security-tests.sh        # Security test suite
├── test-config.conf         # Test configuration
└── README.md               # Test documentation
```

### Bazzite/Linux Deployment
```
BAZZITE-DEPLOYMENT.md        # Quick deployment reference
DEPLOYMENT-GUIDE.md          # Comprehensive deployment guide
check-bazzite-environment.sh # Environment compatibility checker
test-real-emulators.sh       # Real emulator testing script
transfer-config.sh           # Configuration transfer helper
```

### Documentation
```
README-EmuDeck-Sync.md       # Main documentation (rename to README.md)
LICENSE                      # MIT License file
```

## 🚀 Migration Steps

### Step 1: Create New Repository
1. Create new GitHub repository: `emudeck-save-sync` or similar
2. Clone the empty repository locally

### Step 2: Copy Files
```bash
# From your homelab directory, copy all EmuDeck files
cp emudeck-*.sh /path/to/new-repo/
cp install.sh /path/to/new-repo/
cp run-all-tests.sh /path/to/new-repo/
cp test-suite.sh /path/to/new-repo/
cp setup-tests.ps1 /path/to/new-repo/
cp Run-Tests.ps1 /path/to/new-repo/
cp check-bazzite-environment.sh /path/to/new-repo/
cp test-real-emulators.sh /path/to/new-repo/
cp transfer-config.sh /path/to/new-repo/
cp -r tests/ /path/to/new-repo/
cp *DEPLOYMENT*.md /path/to/new-repo/
cp README-EmuDeck-Sync.md /path/to/new-repo/README.md
```

### Step 3: Clean Up New Repository
```bash
cd /path/to/new-repo
chmod +x *.sh
```

### Step 4: Update Documentation
- Rename `README-EmuDeck-Sync.md` to `README.md`
- Update any references to the homelab repository
- Update clone commands in documentation

### Step 5: Test the New Repository
```bash
# Test the environment checker
./check-bazzite-environment.sh

# Test that scripts are executable
ls -la *.sh

# Verify tests can run
./run-all-tests.sh --help
```

## 📋 PowerShell Commands for Windows Migration

```powershell
# Create the file list for easy copying
$files = @(
    "emudeck-sync.sh",
    "emudeck-wrapper.sh", 
    "emudeck-setup.sh",
    "emudeck-steam-launch.sh",
    "emudeck-sync@.service",
    "emudeck-sync@.timer",
    "install.sh",
    "run-all-tests.sh",
    "test-suite.sh", 
    "setup-tests.ps1",
    "Run-Tests.ps1",
    "check-bazzite-environment.sh",
    "test-real-emulators.sh",
    "transfer-config.sh",
    "BAZZITE-DEPLOYMENT.md",
    "DEPLOYMENT-GUIDE.md",
    "README-EmuDeck-Sync.md"
)

# Copy files to new repository (adjust path)
$newRepoPath = "C:\path\to\new\emudeck-save-sync"
foreach ($file in $files) {
    if (Test-Path $file) {
        Copy-Item $file $newRepoPath
    }
}

# Copy tests directory
Copy-Item -Recurse tests $newRepoPath
```

## 🧹 Cleanup Original Repository

After migration, remove from homelab:
```bash
# Remove EmuDeck files from homelab
rm emudeck-*.sh
rm install.sh  
rm run-all-tests.sh
rm test-suite.sh
rm setup-tests.ps1
rm Run-Tests.ps1
rm check-bazzite-environment.sh
rm test-real-emulators.sh
rm transfer-config.sh
rm *DEPLOYMENT*.md
rm README-EmuDeck-Sync.md
rm -r tests/
```

## 📝 Repository Structure After Migration

New `emudeck-save-sync` repository:
```
emudeck-save-sync/
├── README.md                    # Main documentation
├── emudeck-sync.sh              # Core sync script
├── emudeck-wrapper.sh           # Wrapper script
├── emudeck-setup.sh             # Setup script
├── emudeck-steam-launch.sh      # Steam integration
├── emudeck-sync@.service        # Systemd service
├── emudeck-sync@.timer          # Systemd timer
├── install.sh                   # Installation helper
├── run-all-tests.sh             # Test runner
├── test-suite.sh                # Test suite
├── setup-tests.ps1              # Windows setup
├── Run-Tests.ps1                # PowerShell runner
├── check-bazzite-environment.sh # Environment checker
├── test-real-emulators.sh       # Real testing
├── transfer-config.sh           # Config transfer
├── BAZZITE-DEPLOYMENT.md        # Quick reference
├── DEPLOYMENT-GUIDE.md          # Full guide
└── tests/                       # Test framework
    ├── unit-tests.sh
    ├── integration-tests.sh
    ├── performance-tests.sh
    ├── security-tests.sh
    ├── test-config.conf
    └── README.md
```

## 🎯 Benefits of Dedicated Repository

1. **Focused Development** - Dedicated to EmuDeck save syncing
2. **Easier Discovery** - Users can find it specifically
3. **Independent Releases** - Version the sync system separately
4. **Cleaner Issues** - Issues specific to save syncing
5. **Better Documentation** - README focused on one purpose
6. **Simpler Deployment** - Clone just what you need

## 🔗 Recommended Repository Names

- `emudeck-save-sync`
- `emudeck-nextcloud-sync` 
- `emudeck-cloud-saves`
- `emudeck-sync-tool`

## 📊 Migration Verification

After migration, verify:
- ✅ All 20+ files copied correctly
- ✅ Scripts are executable (chmod +x *.sh)
- ✅ Tests directory copied with all 6 files
- ✅ README.md renamed and updated
- ✅ Documentation updated with new clone instructions
- ✅ First commit created in new repository

## 🎉 Post-Migration

Update your Bazzite deployment instructions:
```bash
# New clone command
git clone https://github.com/camcast3/emudeck-save-sync.git
cd emudeck-save-sync
./check-bazzite-environment.sh
```

This migration will make the EmuDeck Save Sync system much more discoverable and maintainable as a standalone project!
