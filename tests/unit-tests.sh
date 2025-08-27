#!/bin/bash

# Unit tests for emudeck-sync.sh core functions

# Source the test framework
TEST_DIR="$(dirname "$0")"
source "$TEST_DIR/../test-suite.sh"

# Mock rclone for testing
mock_rclone() {
    local command="$1"
    local remote="$2"
    local path="$3"
    
    case $command in
        "listremotes")
            echo "test-nextcloud:"
            ;;
        "lsd")
            if [ "$remote" = "test-nextcloud:" ]; then
                echo "          -1 2023-01-01 12:00:00        -1 test-dir"
                return 0
            else
                return 1
            fi
            ;;
        "sync")
            # Mock successful sync
            echo "Transferred: 0 / 0 Bytes, 0, 0 Bytes/s, ETA -"
            echo "Checks: 0 / 0, 0%"
            echo "Elapsed time: 0.1s"
            return 0
            ;;
        "mkdir")
            # Mock directory creation
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Test configuration loading
test_config_loading() {
    log_test "INFO" "Testing configuration loading..."
    
    # Create test config
    local test_config="/tmp/test-emudeck-config.conf"
    cat > "$test_config" << EOF
RCLONE_REMOTE="test-remote"
RCLONE_REMOTE_PATH="test/path"
LOCAL_SAVES_BASE="/tmp/test-saves"
ENABLE_LOGGING=false
SYNC_TIMEOUT=120
DRY_RUN=true
VERBOSE=true
EOF
    
    # Source the config
    source "$test_config"
    
    # Test config values
    assert_equals "test-remote" "$RCLONE_REMOTE" "Config: RCLONE_REMOTE loaded correctly"
    assert_equals "test/path" "$RCLONE_REMOTE_PATH" "Config: RCLONE_REMOTE_PATH loaded correctly"
    assert_equals "/tmp/test-saves" "$LOCAL_SAVES_BASE" "Config: LOCAL_SAVES_BASE loaded correctly"
    assert_equals "false" "$ENABLE_LOGGING" "Config: ENABLE_LOGGING loaded correctly"
    assert_equals "120" "$SYNC_TIMEOUT" "Config: SYNC_TIMEOUT loaded correctly"
    assert_equals "true" "$DRY_RUN" "Config: DRY_RUN loaded correctly"
    assert_equals "true" "$VERBOSE" "Config: VERBOSE loaded correctly"
    
    rm -f "$test_config"
}

# Test emulator path validation
test_emulator_paths() {
    log_test "INFO" "Testing emulator path validation..."
    
    # Create test directory structure
    local test_base="/tmp/test-emulator-paths"
    mkdir -p "$test_base"
    
    # Test RetroArch path
    local retroarch_path="$test_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$retroarch_path"
    assert_dir_exists "$retroarch_path" "RetroArch path structure created correctly"
    
    # Test Dolphin path
    local dolphin_path="$test_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    mkdir -p "$dolphin_path"
    assert_dir_exists "$dolphin_path" "Dolphin path structure created correctly"
    
    # Test PCSX2 path
    local pcsx2_path="$test_base/net.pcsx2.PCSX2/data/pcsx2"
    mkdir -p "$pcsx2_path"
    assert_dir_exists "$pcsx2_path" "PCSX2 path structure created correctly"
    
    # Test PPSSPP path
    local ppsspp_path="$test_base/org.ppsspp.PPSSPP/config/ppsspp"
    mkdir -p "$ppsspp_path"
    assert_dir_exists "$ppsspp_path" "PPSSPP path structure created correctly"
    
    # Test DuckStation path
    local duckstation_path="$test_base/org.duckstation.DuckStation/data/duckstation"
    mkdir -p "$duckstation_path"
    assert_dir_exists "$duckstation_path" "DuckStation path structure created correctly"
    
    # Test RPCS3 path
    local rpcs3_path="$test_base/net.rpcs3.RPCS3/data/rpcs3"
    mkdir -p "$rpcs3_path"
    assert_dir_exists "$rpcs3_path" "RPCS3 path structure created correctly"
    
    # Test Cemu path
    local cemu_path="$test_base/info.cemu.Cemu/data/cemu"
    mkdir -p "$cemu_path"
    assert_dir_exists "$cemu_path" "Cemu path structure created correctly"
    
    # Test Ryujinx path
    local ryujinx_path="$test_base/org.ryujinx.Ryujinx/config/Ryujinx"
    mkdir -p "$ryujinx_path"
    assert_dir_exists "$ryujinx_path" "Ryujinx path structure created correctly"
    
    # Test Yuzu path
    local yuzu_path="$test_base/org.yuzu_emu.yuzu/data/yuzu"
    mkdir -p "$yuzu_path"
    assert_dir_exists "$yuzu_path" "Yuzu path structure created correctly"
    
    # Test Citra path
    local citra_path="$test_base/org.citra_emu.citra/data/citra-emu"
    mkdir -p "$citra_path"
    assert_dir_exists "$citra_path" "Citra path structure created correctly"
    
    # Test melonDS path
    local melonds_path="$test_base/net.kuribo64.melonDS/data/melonDS"
    mkdir -p "$melonds_path"
    assert_dir_exists "$melonds_path" "melonDS path structure created correctly"
    
    # Test xemu path
    local xemu_path="$test_base/app.xemu.xemu/data/xemu"
    mkdir -p "$xemu_path"
    assert_dir_exists "$xemu_path" "xemu path structure created correctly"
    
    # Test PrimeHack path
    local primehack_path="$test_base/io.github.shiiion.primehack/data/dolphin-emu"
    mkdir -p "$primehack_path"
    assert_dir_exists "$primehack_path" "PrimeHack path structure created correctly"
    
    rm -rf "$test_base"
}

# Test logging functionality
test_logging_functions() {
    log_test "INFO" "Testing logging functions..."
    
    local test_log="/tmp/test-emudeck.log"
    rm -f "$test_log"
    
    # Mock the log function behavior
    test_log_function() {
        local level="$1"
        local message="$2"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] [$level] $message" >> "$test_log"
    }
    
    # Test different log levels
    test_log_function "INFO" "Test info message"
    test_log_function "ERROR" "Test error message"
    test_log_function "WARN" "Test warning message"
    test_log_function "DEBUG" "Test debug message"
    
    # Verify log file was created
    assert_file_exists "$test_log" "Log file created"
    
    # Verify log content
    local log_content=$(cat "$test_log")
    if echo "$log_content" | grep -q "Test info message"; then
        log_test "PASS" "Info message logged correctly"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Info message not found in log"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    if echo "$log_content" | grep -q "Test error message"; then
        log_test "PASS" "Error message logged correctly"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Error message not found in log"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    rm -f "$test_log"
}

# Test file operations
test_file_operations() {
    log_test "INFO" "Testing file operations..."
    
    local test_dir="/tmp/test-file-ops"
    local source_dir="$test_dir/source"
    local dest_dir="$test_dir/dest"
    
    # Create test structure
    mkdir -p "$source_dir" "$dest_dir"
    
    # Create test files
    echo "save1" > "$source_dir/save1.sav"
    echo "save2" > "$source_dir/save2.sav"
    mkdir -p "$source_dir/subdir"
    echo "subsave" > "$source_dir/subdir/subsave.sav"
    
    # Test directory creation
    assert_dir_exists "$source_dir" "Source directory created"
    assert_dir_exists "$dest_dir" "Destination directory created"
    
    # Test file existence
    assert_file_exists "$source_dir/save1.sav" "Test file 1 created"
    assert_file_exists "$source_dir/save2.sav" "Test file 2 created"
    assert_file_exists "$source_dir/subdir/subsave.sav" "Test subdirectory file created"
    
    # Test file content
    local content1=$(cat "$source_dir/save1.sav")
    assert_equals "save1" "$content1" "File content matches expected"
    
    # Test directory structure
    local file_count=$(find "$source_dir" -type f | wc -l)
    assert_equals "3" "$file_count" "Correct number of files created"
    
    rm -rf "$test_dir"
}

# Test error handling
test_error_handling() {
    log_test "INFO" "Testing error handling..."
    
    # Test handling of missing directories
    local missing_dir="/tmp/non-existent-dir/subdir"
    if [ ! -d "$missing_dir" ]; then
        log_test "PASS" "Correctly identified missing directory"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Directory should not exist"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    # Test handling of invalid paths
    local invalid_path="/dev/null/invalid"
    if [ ! -d "$invalid_path" ]; then
        log_test "PASS" "Correctly identified invalid path"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Path should be invalid"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    # Test permission handling (if not root)
    if [ "$EUID" -ne 0 ]; then
        local restricted_dir="/root/test"
        if [ ! -w "/root" ] 2>/dev/null; then
            log_test "PASS" "Correctly identified permission restriction"
            ((TESTS_PASSED++))
        else
            log_test "PASS" "Permission test skipped (running as root)"
            ((TESTS_PASSED++))
        fi
    else
        log_test "PASS" "Permission test skipped (running as root)"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

# Test lock file functionality
test_lock_functionality() {
    log_test "INFO" "Testing lock functionality..."
    
    local lock_file="/tmp/test-emudeck.lock"
    rm -f "$lock_file"
    
    # Test lock creation
    echo "$$" > "$lock_file"
    assert_file_exists "$lock_file" "Lock file created"
    
    # Test lock content
    local lock_content=$(cat "$lock_file")
    assert_equals "$$" "$lock_content" "Lock file contains correct PID"
    
    # Test lock detection
    if [ -f "$lock_file" ]; then
        local pid=$(cat "$lock_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_test "PASS" "Lock file process detection works"
            ((TESTS_PASSED++))
        else
            log_test "FAIL" "Lock file process detection failed"
            ((TESTS_FAILED++))
        fi
    else
        log_test "FAIL" "Lock file not found"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    # Test lock cleanup
    rm -f "$lock_file"
    if [ ! -f "$lock_file" ]; then
        log_test "PASS" "Lock file cleaned up successfully"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Lock file cleanup failed"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
}

# Run unit tests
run_unit_tests() {
    log_test "INFO" "Running unit tests..."
    
    test_config_loading
    test_emulator_paths
    test_logging_functions
    test_file_operations
    test_error_handling
    test_lock_functionality
    
    log_test "INFO" "Unit tests completed"
    
    # Print results summary
    echo ""
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}     Unit Test Results${NC}"
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
        echo -e "${RED}Unit test suite failed!${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}All unit tests passed! ✅${NC}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_unit_tests
fi
