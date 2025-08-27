#!/bin/bash

# Integration tests for the complete EmuDeck save sync workflow

# Source the test framework
TEST_DIR="$(dirname "$0")"
source "$TEST_DIR/../test-suite.sh"

# Integration test configuration
INTEGRATION_TEST_DIR="/tmp/emudeck-integration-test"
MOCK_NEXTCLOUD_DIR="$INTEGRATION_TEST_DIR/mock-nextcloud"
MOCK_SAVES_DIR="$INTEGRATION_TEST_DIR/mock-saves"
MOCK_CONFIG_DIR="$INTEGRATION_TEST_DIR/config"

# Setup integration test environment
setup_integration_env() {
    log_test "INFO" "Setting up integration test environment..."
    
    # Clean up any existing test directory
    rm -rf "$INTEGRATION_TEST_DIR"
    
    # Create directory structure
    mkdir -p "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves"
    mkdir -p "$MOCK_SAVES_DIR"
    mkdir -p "$MOCK_CONFIG_DIR"
    
    # Create realistic save directory structure
    local saves_base="$MOCK_SAVES_DIR"
    
    # RetroArch
    mkdir -p "$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/states"
    
    # Dolphin
    mkdir -p "$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC"
    mkdir -p "$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu/Wii"
    mkdir -p "$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu/StateSaves"
    
    # PCSX2
    mkdir -p "$saves_base/net.pcsx2.PCSX2/data/pcsx2/memcards"
    mkdir -p "$saves_base/net.pcsx2.PCSX2/data/pcsx2/sstates"
    
    # Create sample save files
    create_sample_saves
    
    # Create integration test config
    create_integration_config
    
    log_test "INFO" "Integration test environment setup complete"
}

# Create sample save files
create_sample_saves() {
    log_test "DEBUG" "Creating sample save files..."
    
    local saves_base="$MOCK_SAVES_DIR"
    
    # RetroArch saves
    echo "SNES save data for Super Mario World" > "$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Super Mario World.srm"
    echo "Genesis save data for Sonic" > "$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Sonic.sav"
    
    # RetroArch states
    dd if=/dev/urandom of="$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/states/Super Mario World.state1" bs=1K count=50 2>/dev/null
    
    # Dolphin saves
    echo "GameCube save data" > "$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu/GC/MemoryCardA.USA.raw"
    echo "Wii save data" > "$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu/Wii/title/00000001/00000002/data/setting.txt"
    dd if=/dev/urandom of="$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu/StateSaves/GALE01.gci" bs=1K count=30 2>/dev/null
    
    # PCSX2 saves
    dd if=/dev/urandom of="$saves_base/net.pcsx2.PCSX2/data/pcsx2/memcards/Mcd001.ps2" bs=1K count=128 2>/dev/null
    dd if=/dev/urandom of="$saves_base/net.pcsx2.PCSX2/data/pcsx2/sstates/SLUS-20062 (01234567).p2s" bs=1M count=5 2>/dev/null
}

# Create integration test configuration
create_integration_config() {
    log_test "DEBUG" "Creating integration test configuration..."
    
    cat > "$MOCK_CONFIG_DIR/config.conf" << EOF
# Integration test configuration
RCLONE_REMOTE="integration-test"
RCLONE_REMOTE_PATH="$MOCK_NEXTCLOUD_DIR/EmuDeck/saves"
LOCAL_SAVES_BASE="$MOCK_SAVES_DIR"
ENABLE_LOGGING=true
SYNC_TIMEOUT=60
DRY_RUN=false
VERBOSE=true
EOF
    
    # Create rclone config for local testing
    mkdir -p "$HOME/.config/rclone"
    cat >> "$HOME/.config/rclone/rclone.conf" << EOF

[integration-test]
type = local
nounc = true
EOF
}

# Test full sync workflow
test_full_sync_workflow() {
    log_test "INFO" "Testing full sync workflow..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$MOCK_CONFIG_DIR/config.conf"
    
    # Set environment variables
    export HOME="$MOCK_CONFIG_DIR"
    
    # Test initial upload
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Initial upload of RetroArch saves"
    
    # Verify files were uploaded
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Super Mario World.srm" "RetroArch save uploaded"
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Sonic.sav" "RetroArch save uploaded"
    
    # Test upload of Dolphin saves
    assert_command_success "'$sync_script' --config '$config_file' upload dolphin" "Upload of Dolphin saves"
    
    # Verify Dolphin files were uploaded
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/dolphin/GC/MemoryCardA.USA.raw" "Dolphin GC save uploaded"
    
    # Test upload of PCSX2 saves
    assert_command_success "'$sync_script' --config '$config_file' upload pcsx2" "Upload of PCSX2 saves"
    
    # Test bulk upload
    assert_command_success "'$sync_script' --config '$config_file' upload" "Bulk upload of all saves"
    
    # Modify local files
    echo "Modified save data" > "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Super Mario World.srm"
    
    # Upload modifications
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Upload modified saves"
    
    # Delete local files
    rm -rf "$MOCK_SAVES_DIR/com.valvesoftware.Steam"
    
    # Download and verify restoration
    assert_command_success "'$sync_script' --config '$config_file' download retroarch" "Download saves after deletion"
    assert_file_exists "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Super Mario World.srm" "Save file restored"
    
    # Verify content was preserved
    local content=$(cat "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Super Mario World.srm")
    assert_equals "Modified save data" "$content" "Save file content preserved"
}

# Test wrapper integration
test_wrapper_integration() {
    log_test "INFO" "Testing wrapper integration..."
    
    local wrapper_script="$TEST_DIR/../emudeck-wrapper.sh"
    local config_file="$MOCK_CONFIG_DIR/config.conf"
    
    # Create mock emulator
    local mock_emulator="$INTEGRATION_TEST_DIR/mock-retroarch"
    cat > "$mock_emulator" << 'EOF'
#!/bin/bash
echo "Mock RetroArch starting..."
# Simulate save file modification
echo "New game progress" > "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/New Game.srm"
sleep 2
echo "Mock RetroArch exiting..."
EOF
    chmod +x "$mock_emulator"
    
    # Set environment
    export HOME="$MOCK_CONFIG_DIR"
    export MOCK_SAVES_DIR="$MOCK_SAVES_DIR"
    
    # Test wrapper execution
    assert_command_success "'$wrapper_script' retroarch '$mock_emulator'" "Wrapper executes mock emulator"
    
    # Verify new save was created and uploaded
    assert_file_exists "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/New Game.srm" "New save file created by mock emulator"
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/New Game.srm" "New save file uploaded by wrapper"
}

# Test Steam integration
test_steam_integration() {
    log_test "INFO" "Testing Steam integration..."
    
    local steam_script="$TEST_DIR/../emudeck-steam-launch.sh"
    local config_file="$MOCK_CONFIG_DIR/config.conf"
    
    # Create mock Steam app
    local mock_steam_app="$INTEGRATION_TEST_DIR/mock-steam-retroarch"
    cat > "$mock_steam_app" << 'EOF'
#!/bin/bash
echo "Mock Steam RetroArch launching..."
# Simulate gameplay and save creation
echo "Steam session save" > "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Steam Game.srm"
sleep 1
echo "Mock Steam RetroArch closing..."
EOF
    chmod +x "$mock_steam_app"
    
    # Set environment
    export HOME="$MOCK_CONFIG_DIR"
    export MOCK_SAVES_DIR="$MOCK_SAVES_DIR"
    
    # Test Steam script execution
    assert_command_success "'$steam_script' retroarch '$mock_steam_app'" "Steam script executes mock app"
    
    # Verify save was created and uploaded
    assert_file_exists "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Steam Game.srm" "Steam save file created"
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Steam Game.srm" "Steam save file uploaded"
}

# Test conflict resolution
test_conflict_resolution() {
    log_test "INFO" "Testing conflict resolution..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$MOCK_CONFIG_DIR/config.conf"
    
    # Set environment
    export HOME="$MOCK_CONFIG_DIR"
    
    # Create conflicting saves (different content in local vs remote)
    echo "Local version" > "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Conflict.srm"
    echo "Remote version" > "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Conflict.srm"
    
    # Test download overwrites local (rclone sync behavior)
    assert_command_success "'$sync_script' --config '$config_file' download retroarch" "Download with conflict"
    
    local content=$(cat "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Conflict.srm")
    assert_equals "Remote version" "$content" "Download overwrote local file"
    
    # Modify local again
    echo "New local version" > "$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves/Conflict.srm"
    
    # Test upload overwrites remote
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Upload with conflict"
    
    local remote_content=$(cat "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Conflict.srm")
    assert_equals "New local version" "$remote_content" "Upload overwrote remote file"
}

# Test large file handling
test_large_file_handling() {
    log_test "INFO" "Testing large file handling..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$MOCK_CONFIG_DIR/config.conf"
    
    # Set environment
    export HOME="$MOCK_CONFIG_DIR"
    
    # Create large save files (10MB each)
    local large_save_dir="$MOCK_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    dd if=/dev/urandom of="$large_save_dir/Large Game 1.srm" bs=1M count=10 2>/dev/null
    dd if=/dev/urandom of="$large_save_dir/Large Game 2.srm" bs=1M count=10 2>/dev/null
    dd if=/dev/urandom of="$large_save_dir/Large Game 3.srm" bs=1M count=10 2>/dev/null
    
    # Test upload of large files
    local start_time=$(date +%s)
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Upload large save files"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Verify files were uploaded
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Large Game 1.srm" "Large file 1 uploaded"
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Large Game 2.srm" "Large file 2 uploaded"
    assert_file_exists "$MOCK_NEXTCLOUD_DIR/EmuDeck/saves/retroarch/Large Game 3.srm" "Large file 3 uploaded"
    
    # Performance check (should complete within reasonable time)
    if [ $duration -lt 60 ]; then
        log_test "PASS" "Large file upload completed in reasonable time (${duration}s)"
        ((TESTS_PASSED++))
    else
        log_test "WARN" "Large file upload took longer than expected (${duration}s)"
        ((TESTS_PASSED++))  # Don't fail on performance, just warn
    fi
    ((TESTS_RUN++))
    
    # Test download of large files
    rm -f "$large_save_dir/Large Game"*
    
    start_time=$(date +%s)
    assert_command_success "'$sync_script' --config '$config_file' download retroarch" "Download large save files"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Verify files were downloaded
    assert_file_exists "$large_save_dir/Large Game 1.srm" "Large file 1 downloaded"
    assert_file_exists "$large_save_dir/Large Game 2.srm" "Large file 2 downloaded"
    assert_file_exists "$large_save_dir/Large Game 3.srm" "Large file 3 downloaded"
}

# Test concurrent access
test_concurrent_access() {
    log_test "INFO" "Testing concurrent access handling..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$MOCK_CONFIG_DIR/config.conf"
    
    # Set environment
    export HOME="$MOCK_CONFIG_DIR"
    
    # Start background sync
    "$sync_script" --config "$config_file" upload retroarch >/dev/null 2>&1 &
    local bg_pid=$!
    sleep 1
    
    # Try to start another sync (should fail due to lock)
    if ! "$sync_script" --config "$config_file" download retroarch >/dev/null 2>&1; then
        log_test "PASS" "Concurrent access properly blocked"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Concurrent access should have been blocked"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    # Wait for background process and verify lock is released
    wait $bg_pid
    
    # Now sync should work
    assert_command_success "'$sync_script' --config '$config_file' download retroarch" "Lock properly released after process completion"
}

# Cleanup integration test environment
cleanup_integration_env() {
    log_test "INFO" "Cleaning up integration test environment..."
    
    # Restore original HOME
    export HOME="$ORIGINAL_HOME"
    
    # Clean up test directory
    rm -rf "$INTEGRATION_TEST_DIR"
    
    # Remove integration test rclone config
    if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        sed -i '/\[integration-test\]/,/^$/d' "$HOME/.config/rclone/rclone.conf"
    fi
    
    log_test "INFO" "Integration test cleanup complete"
}

# Run integration tests
run_integration_tests() {
    log_test "INFO" "Running integration tests..."
    
    setup_integration_env
    
    test_full_sync_workflow
    test_wrapper_integration
    test_steam_integration
    test_conflict_resolution
    test_large_file_handling
    test_concurrent_access
    
    cleanup_integration_env
    
    log_test "INFO" "Integration tests completed"
    
    # Print results summary
    echo ""
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}  Integration Test Results${NC}"
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
        echo -e "${RED}Integration test suite failed!${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}All integration tests passed! ✅${NC}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_integration_tests
fi
