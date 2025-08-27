#!/bin/bash

# EmuDeck Save Sync Test Suite
# Comprehensive testing for all functionality

TEST_DIR="$(dirname "$0")/tests"
SCRIPT_DIR="$(dirname "$0")"
SYNC_SCRIPT="$SCRIPT_DIR/emudeck-sync.sh"
WRAPPER_SCRIPT="$SCRIPT_DIR/emudeck-wrapper.sh"
SETUP_SCRIPT="$SCRIPT_DIR/emudeck-setup.sh"
STEAM_SCRIPT="$SCRIPT_DIR/emudeck-steam-launch.sh"

# Test configuration
TEST_CONFIG_DIR="/tmp/emudeck-sync-test"
TEST_LOG_DIR="$TEST_CONFIG_DIR/logs"
TEST_RCLONE_CONFIG="/tmp/test-rclone.conf"
ORIGINAL_HOME="$HOME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS=()

# Logging function
log_test() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${CYAN}[DEBUG]${NC} $message"
            ;;
    esac
    
    # Ensure log directory exists before writing
    mkdir -p "$TEST_LOG_DIR" 2>/dev/null || true
    echo "[$timestamp] [$level] $message" >> "$TEST_LOG_DIR/test-suite.log" 2>/dev/null || true
}

# Setup test environment
setup_test_environment() {
    log_test "INFO" "Setting up test environment..."
    
    # Create test directories
    rm -rf "$TEST_CONFIG_DIR"
    mkdir -p "$TEST_CONFIG_DIR" "$TEST_LOG_DIR"
    mkdir -p "$TEST_CONFIG_DIR/mock-saves"
    mkdir -p "$TEST_CONFIG_DIR/mock-remote"
    
    # Create mock save directories
    local base_dir="$TEST_CONFIG_DIR/mock-saves"
    mkdir -p "$base_dir/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$base_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    mkdir -p "$base_dir/net.pcsx2.PCSX2/data/pcsx2"
    
    # Create test save files
    echo "test save data" > "$base_dir/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/test.sav"
    echo "dolphin save" > "$base_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu/test.gci"
    echo "pcsx2 save" > "$base_dir/net.pcsx2.PCSX2/data/pcsx2/test.ps2"
    
    # Create mock rclone config
    cat > "$TEST_RCLONE_CONFIG" << EOF
[test-nextcloud]
type = local
EOF
    
    # Create test config for sync script
    cat > "$TEST_CONFIG_DIR/config.conf" << EOF
RCLONE_REMOTE="test-nextcloud"
RCLONE_REMOTE_PATH="$TEST_CONFIG_DIR/mock-remote/EmuDeck/saves"
LOCAL_SAVES_BASE="$TEST_CONFIG_DIR/mock-saves"
ENABLE_LOGGING=true
SYNC_TIMEOUT=30
DRY_RUN=false
VERBOSE=false
EOF
    
    # Set environment variables for testing
    export HOME="$TEST_CONFIG_DIR"
    export RCLONE_CONFIG="$TEST_RCLONE_CONFIG"
    
    log_test "INFO" "Test environment setup complete"
}

# Cleanup test environment
cleanup_test_environment() {
    log_test "INFO" "Cleaning up test environment..."
    export HOME="$ORIGINAL_HOME"
    unset RCLONE_CONFIG
    rm -rf "$TEST_CONFIG_DIR"
    rm -f "$TEST_RCLONE_CONFIG"
    log_test "INFO" "Cleanup complete"
}

# Assert function
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    
    if [ "$expected" = "$actual" ]; then
        log_test "PASS" "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_test "FAIL" "$test_name - Expected: '$expected', Got: '$actual'"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    
    if [ -f "$file" ]; then
        log_test "PASS" "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_test "FAIL" "$test_name - File does not exist: $file"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    
    if [ -d "$dir" ]; then
        log_test "PASS" "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_test "FAIL" "$test_name - Directory does not exist: $dir"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert command succeeds
assert_command_success() {
    local command="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    
    if eval "$command" >/dev/null 2>&1; then
        log_test "PASS" "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_test "FAIL" "$test_name - Command failed: $command"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert command fails
assert_command_failure() {
    local command="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    
    if ! eval "$command" >/dev/null 2>&1; then
        log_test "PASS" "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_test "FAIL" "$test_name - Command should have failed: $command"
        FAILED_TESTS+=("$test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test basic script existence and permissions
test_script_files() {
    log_test "INFO" "Testing script files..."
    
    assert_file_exists "$SYNC_SCRIPT" "Main sync script exists"
    assert_file_exists "$WRAPPER_SCRIPT" "Wrapper script exists"
    assert_file_exists "$SETUP_SCRIPT" "Setup script exists"
    assert_file_exists "$STEAM_SCRIPT" "Steam launch script exists"
    
    # Test if scripts are executable
    assert_command_success "[ -x '$SYNC_SCRIPT' ]" "Main sync script is executable"
    assert_command_success "[ -x '$WRAPPER_SCRIPT' ]" "Wrapper script is executable"
    assert_command_success "[ -x '$SETUP_SCRIPT' ]" "Setup script is executable"
    assert_command_success "[ -x '$STEAM_SCRIPT' ]" "Steam launch script is executable"
}

# Test sync script help and basic commands
test_sync_script_basic() {
    log_test "INFO" "Testing sync script basic functionality..."
    
    # Test help command
    assert_command_success "'$SYNC_SCRIPT' --help" "Help command works"
    
    # Test list command
    assert_command_success "'$SYNC_SCRIPT' list" "List command works"
    
    # Test invalid command
    assert_command_failure "'$SYNC_SCRIPT' invalid-command" "Invalid command fails correctly"
}

# Test configuration management
test_configuration() {
    log_test "INFO" "Testing configuration management..."
    
    # Set up test config
    mkdir -p "$HOME/.config/emudeck-sync"
    cp "$TEST_CONFIG_DIR/config.conf" "$HOME/.config/emudeck-sync/config.conf"
    
    # Test config command
    assert_command_success "'$SYNC_SCRIPT' config" "Config command works"
    
    # Test status command
    assert_command_success "'$SYNC_SCRIPT' status" "Status command works"
}

# Test dry-run functionality
test_dry_run() {
    log_test "INFO" "Testing dry-run functionality..."
    
    # Test dry-run download
    assert_command_success "'$SYNC_SCRIPT' --dry-run download retroarch" "Dry-run download works"
    
    # Test dry-run upload
    assert_command_success "'$SYNC_SCRIPT' --dry-run upload retroarch" "Dry-run upload works"
}

# Test emulator path detection
test_emulator_paths() {
    log_test "INFO" "Testing emulator path detection..."
    
    # Create test paths and verify they're detected
    local base_dir="$TEST_CONFIG_DIR/mock-saves"
    
    # Test RetroArch path exists
    local retroarch_path="$base_dir/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    assert_dir_exists "$retroarch_path" "RetroArch save path exists"
    
    # Test Dolphin path exists
    local dolphin_path="$base_dir/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    assert_dir_exists "$dolphin_path" "Dolphin save path exists"
    
    # Test PCSX2 path exists
    local pcsx2_path="$base_dir/net.pcsx2.PCSX2/data/pcsx2"
    assert_dir_exists "$pcsx2_path" "PCSX2 save path exists"
}

# Test file synchronization
test_sync_operations() {
    log_test "INFO" "Testing sync operations..."
    
    # Create remote directory structure
    mkdir -p "$TEST_CONFIG_DIR/mock-remote/EmuDeck/saves/retroarch"
    mkdir -p "$TEST_CONFIG_DIR/mock-remote/EmuDeck/saves/dolphin"
    
    # Test upload operation (should work with local backend)
    export LOCAL_SAVES_BASE="$TEST_CONFIG_DIR/mock-saves"
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' upload retroarch" "Upload operation works"
    
    # Test download operation
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' download retroarch" "Download operation works"
}

# Test wrapper script
test_wrapper_script() {
    log_test "INFO" "Testing wrapper script functionality..."
    
    # Test wrapper help
    assert_command_success "'$WRAPPER_SCRIPT'" "Wrapper shows usage when no args"
    
    # Create a mock emulator command
    echo '#!/bin/bash' > "$TEST_CONFIG_DIR/mock-emulator"
    echo 'echo "Mock emulator running"' >> "$TEST_CONFIG_DIR/mock-emulator"
    echo 'exit 0' >> "$TEST_CONFIG_DIR/mock-emulator"
    chmod +x "$TEST_CONFIG_DIR/mock-emulator"
    
    # Test wrapper with mock emulator
    export LOCAL_SAVES_BASE="$TEST_CONFIG_DIR/mock-saves"
    assert_command_success "'$WRAPPER_SCRIPT' retroarch '$TEST_CONFIG_DIR/mock-emulator'" "Wrapper executes mock emulator"
}

# Test Steam launch script
test_steam_script() {
    log_test "INFO" "Testing Steam launch script..."
    
    # Test with no command
    assert_command_failure "'$STEAM_SCRIPT'" "Steam script fails with no command"
    
    # Test with mock command
    echo '#!/bin/bash' > "$TEST_CONFIG_DIR/mock-steam-app"
    echo 'echo "Mock Steam app running"' >> "$TEST_CONFIG_DIR/mock-steam-app"
    echo 'exit 0' >> "$TEST_CONFIG_DIR/mock-steam-app"
    chmod +x "$TEST_CONFIG_DIR/mock-steam-app"
    
    # Test Steam script with retroarch command
    export LOCAL_SAVES_BASE="$TEST_CONFIG_DIR/mock-saves"
    assert_command_success "'$STEAM_SCRIPT' retroarch '$TEST_CONFIG_DIR/mock-steam-app'" "Steam script works with retroarch"
}

# Test error handling
test_error_handling() {
    log_test "INFO" "Testing error handling..."
    
    # Test with non-existent emulator
    assert_command_failure "'$SYNC_SCRIPT' download non-existent-emulator" "Fails with non-existent emulator"
    
    # Test with invalid config
    echo "INVALID CONFIG" > "$TEST_CONFIG_DIR/bad-config.conf"
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/bad-config.conf' status" "Handles bad config gracefully"
    
    # Test with missing remote
    sed -i 's/test-nextcloud/missing-remote/' "$TEST_CONFIG_DIR/config.conf"
    assert_command_failure "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' download retroarch" "Fails with missing remote"
}

# Test concurrent access (locking)
test_locking() {
    log_test "INFO" "Testing file locking..."
    
    # Start a background sync that will hold the lock
    "$SYNC_SCRIPT" --config "$TEST_CONFIG_DIR/config.conf" download retroarch &
    local bg_pid=$!
    sleep 1
    
    # Try to run another sync (should fail due to lock)
    assert_command_failure "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' upload retroarch" "Concurrent access prevented by lock"
    
    # Wait for background process to finish
    wait $bg_pid
    
    # Now the lock should be released and sync should work
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' upload retroarch" "Lock released after process ends"
}

# Test logging functionality
test_logging() {
    log_test "INFO" "Testing logging functionality..."
    
    # Ensure logging is enabled
    mkdir -p "$HOME/.config/emudeck-sync/logs"
    
    # Run a command that should generate logs
    "$SYNC_SCRIPT" --config "$TEST_CONFIG_DIR/config.conf" --verbose list >/dev/null 2>&1
    
    # Check if log file was created
    assert_file_exists "$HOME/.config/emudeck-sync/logs/emudeck-sync.log" "Log file created"
}

# Performance tests
test_performance() {
    log_test "INFO" "Testing performance..."
    
    # Create larger test files
    local large_save_dir="$TEST_CONFIG_DIR/mock-saves/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    
    # Create multiple save files
    for i in {1..10}; do
        dd if=/dev/zero of="$large_save_dir/save$i.sav" bs=1K count=100 2>/dev/null
    done
    
    # Time the sync operation
    local start_time=$(date +%s)
    "$SYNC_SCRIPT" --config "$TEST_CONFIG_DIR/config.conf" upload retroarch >/dev/null 2>&1
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Check if sync completed within reasonable time (30 seconds)
    if [ $duration -lt 30 ]; then
        log_test "PASS" "Performance test - Sync completed in ${duration}s"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Performance test - Sync took too long: ${duration}s"
        FAILED_TESTS+=("Performance test")
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# Integration test
test_integration() {
    log_test "INFO" "Running integration test..."
    
    # Full workflow test: setup -> sync -> modify -> sync -> verify
    
    # Initial upload
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' upload retroarch" "Initial upload"
    
    # Modify local save
    echo "modified save data" > "$TEST_CONFIG_DIR/mock-saves/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/test.sav"
    
    # Upload modification
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' upload retroarch" "Upload modification"
    
    # Clear local save
    rm -f "$TEST_CONFIG_DIR/mock-saves/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/test.sav"
    
    # Download and verify
    assert_command_success "'$SYNC_SCRIPT' --config '$TEST_CONFIG_DIR/config.conf' download retroarch" "Download after modification"
    
    # Check if file was restored
    assert_file_exists "$TEST_CONFIG_DIR/mock-saves/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/test.sav" "File restored after download"
}

# Main test runner
run_tests() {
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}  EmuDeck Save Sync Test Suite${NC}"
    echo -e "${WHITE}================================${NC}"
    echo ""
    
    # Setup
    setup_test_environment
    
    # Run test categories
    test_script_files
    test_sync_script_basic
    test_configuration
    test_dry_run
    test_emulator_paths
    test_sync_operations
    test_wrapper_script
    test_steam_script
    test_error_handling
    test_locking
    test_logging
    test_performance
    test_integration
    
    # Cleanup
    cleanup_test_environment
    
    # Print results
    echo ""
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}        Test Results${NC}"
    echo -e "${WHITE}================================${NC}"
    echo -e "Tests run:    ${BLUE}$TESTS_RUN${NC}"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo ""
        echo -e "${RED}Test suite failed!${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}All tests passed! ✅${NC}"
        exit 0
    fi
}

# Check if running in test mode or being sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_tests "$@"
fi
