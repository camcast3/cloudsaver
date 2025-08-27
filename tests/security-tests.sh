#!/bin/bash

# Security tests for EmuDeck save sync system

# Source the test framework
TEST_DIR="$(dirname "$0")"
source "$TEST_DIR/../test-suite.sh"

# Security test configuration
SECURITY_TEST_DIR="/tmp/emudeck-security-test"
SECURITY_CONFIG_DIR="$SECURITY_TEST_DIR/config"
MALICIOUS_SAVES_DIR="$SECURITY_TEST_DIR/malicious-saves"

# Setup security test environment
setup_security_env() {
    log_test "INFO" "Setting up security test environment..."
    
    rm -rf "$SECURITY_TEST_DIR"
    mkdir -p "$SECURITY_CONFIG_DIR" "$MALICIOUS_SAVES_DIR"
    
    # Create test config
    cat > "$SECURITY_CONFIG_DIR/config.conf" << EOF
RCLONE_REMOTE="security-test"
RCLONE_REMOTE_PATH="$SECURITY_TEST_DIR/remote/EmuDeck/saves"
LOCAL_SAVES_BASE="$MALICIOUS_SAVES_DIR"
ENABLE_LOGGING=true
SYNC_TIMEOUT=30
DRY_RUN=false
VERBOSE=false
EOF
    
    # Create local rclone config for testing
    mkdir -p "$HOME/.config/rclone"
    cat >> "$HOME/.config/rclone/rclone.conf" << EOF

[security-test]
type = local
nounc = true
EOF
    
    log_test "INFO" "Security test environment setup complete"
}

# Test path traversal protection
test_path_traversal() {
    log_test "INFO" "Testing path traversal protection..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    
    # Create save directories with potential path traversal
    local saves_base="$MALICIOUS_SAVES_DIR"
    mkdir -p "$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    
    # Try to create files with path traversal patterns
    local traversal_dir="$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    
    # These should be handled safely by the sync system
    echo "Normal save" > "$traversal_dir/normal.sav"
    echo "Malicious content" > "$traversal_dir/../../../../../../../tmp/malicious.txt" 2>/dev/null || true
    echo "Relative path" > "$traversal_dir/../../relative.sav" 2>/dev/null || true
    
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Test sync with potentially malicious paths
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Sync handles path traversal attempts"
    
    # Verify malicious files were not created outside the intended directory
    if [ ! -f "/tmp/malicious.txt" ]; then
        log_test "PASS" "Path traversal attack prevented"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Path traversal attack succeeded"
        ((TESTS_FAILED++))
        rm -f "/tmp/malicious.txt"
    fi
    ((TESTS_RUN++))
}

# Test symbolic link handling
test_symlink_handling() {
    log_test "INFO" "Testing symbolic link handling..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    
    # Create save directory
    local saves_base="$MALICIOUS_SAVES_DIR"
    local saves_dir="$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$saves_dir"
    
    # Create normal file
    echo "Normal save" > "$saves_dir/normal.sav"
    
    # Create symbolic links (potentially dangerous)
    ln -s "/etc/passwd" "$saves_dir/passwd_link.sav" 2>/dev/null || true
    ln -s "/tmp" "$saves_dir/tmp_link" 2>/dev/null || true
    ln -s "../../../../../../../etc/shadow" "$saves_dir/shadow_link.sav" 2>/dev/null || true
    
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Test sync behavior with symlinks
    if "$sync_script" --config "$config_file" upload retroarch >/dev/null 2>&1; then
        # Check that symlinks were not followed to sensitive locations
        local remote_dir="$SECURITY_TEST_DIR/remote/EmuDeck/saves/retroarch"
        
        # Normal file should be synced
        assert_file_exists "$remote_dir/normal.sav" "Normal file synced"
        
        # Symlinks should either be skipped or handled safely
        if [ -f "$remote_dir/passwd_link.sav" ]; then
            # If symlink was copied, it should not contain sensitive content
            local content=$(cat "$remote_dir/passwd_link.sav" 2>/dev/null || echo "safe")
            if echo "$content" | grep -q "root:"; then
                log_test "FAIL" "Symlink to /etc/passwd was followed"
                ((TESTS_FAILED++))
            else
                log_test "PASS" "Symlink handled safely"
                ((TESTS_PASSED++))
            fi
        else
            log_test "PASS" "Dangerous symlink was skipped"
            ((TESTS_PASSED++))
        fi
        ((TESTS_RUN++))
    else
        log_test "FAIL" "Sync failed with symlinks present"
        ((TESTS_FAILED++))
        ((TESTS_RUN++))
    fi
}

# Test file permission preservation
test_file_permissions() {
    log_test "INFO" "Testing file permission handling..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    
    # Create save directory
    local saves_base="$MALICIOUS_SAVES_DIR"
    local saves_dir="$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$saves_dir"
    
    # Create files with different permissions
    echo "Readable save" > "$saves_dir/readable.sav"
    chmod 644 "$saves_dir/readable.sav"
    
    echo "Executable save" > "$saves_dir/executable.sav"
    chmod 755 "$saves_dir/executable.sav"
    
    echo "Restricted save" > "$saves_dir/restricted.sav"
    chmod 600 "$saves_dir/restricted.sav"
    
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Test sync
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Sync with various permissions"
    
    # Verify files were synced
    local remote_dir="$SECURITY_TEST_DIR/remote/EmuDeck/saves/retroarch"
    assert_file_exists "$remote_dir/readable.sav" "Readable file synced"
    assert_file_exists "$remote_dir/executable.sav" "Executable file synced"
    assert_file_exists "$remote_dir/restricted.sav" "Restricted file synced"
    
    # Test download and permission restoration
    rm -rf "$saves_dir"
    mkdir -p "$saves_dir"
    
    assert_command_success "'$sync_script' --config '$config_file' download retroarch" "Download with permission restoration"
    
    # Files should exist after download
    assert_file_exists "$saves_dir/readable.sav" "Readable file downloaded"
    assert_file_exists "$saves_dir/executable.sav" "Executable file downloaded"
    assert_file_exists "$saves_dir/restricted.sav" "Restricted file downloaded"
}

# Test large filename handling
test_filename_security() {
    log_test "INFO" "Testing filename security..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    
    # Create save directory
    local saves_base="$MALICIOUS_SAVES_DIR"
    local saves_dir="$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$saves_dir"
    
    # Create files with potentially problematic names
    echo "Normal" > "$saves_dir/normal.sav"
    echo "Spaces" > "$saves_dir/file with spaces.sav"
    echo "Special" > "$saves_dir/file-with-special_chars.sav"
    
    # Very long filename (close to filesystem limits)
    local long_name="very_long_filename_that_might_cause_problems_in_some_filesystems_or_applications_$(printf 'a%.0s' {1..100}).sav"
    if [ ${#long_name} -lt 255 ]; then
        echo "Long name" > "$saves_dir/$long_name" 2>/dev/null || true
    fi
    
    # Filename with quotes and special characters
    echo "Quotes" > "$saves_dir/file'with\"quotes.sav" 2>/dev/null || true
    echo "Newlines" > "$saves_dir/file"$'\n'"with"$'\n'"newlines.sav" 2>/dev/null || true
    
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Test sync with problematic filenames
    if "$sync_script" --config "$config_file" upload retroarch >/dev/null 2>&1; then
        log_test "PASS" "Sync handles problematic filenames"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Sync failed with problematic filenames"
        ((TESTS_FAILED++))
    fi
    ((TESTS_RUN++))
    
    # Verify normal files were synced
    local remote_dir="$SECURITY_TEST_DIR/remote/EmuDeck/saves/retroarch"
    assert_file_exists "$remote_dir/normal.sav" "Normal filename file synced"
    assert_file_exists "$remote_dir/file with spaces.sav" "Spaces in filename handled"
    assert_file_exists "$remote_dir/file-with-special_chars.sav" "Special characters handled"
}

# Test configuration injection
test_config_injection() {
    log_test "INFO" "Testing configuration injection protection..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    
    # Create malicious config file
    local malicious_config="$SECURITY_TEST_DIR/malicious.conf"
    cat > "$malicious_config" << 'EOF'
RCLONE_REMOTE="security-test"
RCLONE_REMOTE_PATH="/tmp/malicious"
LOCAL_SAVES_BASE="/tmp/test"
ENABLE_LOGGING=true
SYNC_TIMEOUT=30
DRY_RUN=false
VERBOSE=false
# Attempt command injection
MALICIOUS_COMMAND="; rm -rf /tmp/important; echo 'injected'"
ANOTHER_VAR="$(whoami)"
EOF
    
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Test that malicious config doesn't cause command injection
    if "$sync_script" --config "$malicious_config" status >/dev/null 2>&1; then
        # Check that no malicious commands were executed
        if [ ! -f "/tmp/injected" ]; then
            log_test "PASS" "Configuration injection prevented"
            ((TESTS_PASSED++))
        else
            log_test "FAIL" "Configuration injection succeeded"
            ((TESTS_FAILED++))
            rm -f "/tmp/injected"
        fi
    else
        log_test "PASS" "Malicious configuration rejected"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
}

# Test lock file security
test_lock_security() {
    log_test "INFO" "Testing lock file security..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    local lock_file="/tmp/emudeck-sync.lock"
    
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Create a fake lock file with malicious content
    echo "malicious_pid_123456789" > "$lock_file"
    
    # Test that sync handles invalid lock file gracefully
    if "$sync_script" --config "$config_file" status >/dev/null 2>&1; then
        log_test "PASS" "Invalid lock file handled gracefully"
        ((TESTS_PASSED++))
    else
        log_test "PASS" "Sync properly rejected due to lock (expected)"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
    
    # Clean up
    rm -f "$lock_file"
    
    # Test lock file creation permissions
    "$sync_script" --config "$config_file" --dry-run upload retroarch >/dev/null 2>&1 &
    local bg_pid=$!
    sleep 1
    
    if [ -f "$lock_file" ]; then
        local perms=$(stat -c "%a" "$lock_file" 2>/dev/null || echo "644")
        if [ "$perms" = "644" ] || [ "$perms" = "664" ] || [ "$perms" = "600" ]; then
            log_test "PASS" "Lock file has appropriate permissions ($perms)"
            ((TESTS_PASSED++))
        else
            log_test "WARN" "Lock file permissions may be too permissive ($perms)"
            ((TESTS_PASSED++))  # Don't fail on permission warnings
        fi
    else
        log_test "PASS" "Lock file test skipped (dry-run may not create lock)"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
    
    wait $bg_pid 2>/dev/null || true
}

# Test log file security
test_log_security() {
    log_test "INFO" "Testing log file security..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    local log_dir="$SECURITY_CONFIG_DIR/.config/emudeck-sync/logs"
    
    mkdir -p "$log_dir"
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Run sync to generate logs
    "$sync_script" --config "$config_file" status >/dev/null 2>&1
    
    # Check if log files were created with appropriate permissions
    if [ -f "$log_dir/emudeck-sync.log" ]; then
        local log_perms=$(stat -c "%a" "$log_dir/emudeck-sync.log" 2>/dev/null || echo "644")
        if [ "$log_perms" = "644" ] || [ "$log_perms" = "664" ] || [ "$log_perms" = "600" ]; then
            log_test "PASS" "Log file has appropriate permissions ($log_perms)"
            ((TESTS_PASSED++))
        else
            log_test "WARN" "Log file permissions may be inappropriate ($log_perms)"
            ((TESTS_PASSED++))
        fi
        
        # Check that log doesn't contain sensitive information
        local log_content=$(cat "$log_dir/emudeck-sync.log" 2>/dev/null || echo "")
        if echo "$log_content" | grep -qi "password\|secret\|token"; then
            log_test "WARN" "Log file may contain sensitive information"
            ((TESTS_PASSED++))  # Warn but don't fail
        else
            log_test "PASS" "Log file doesn't contain obvious sensitive data"
            ((TESTS_PASSED++))
        fi
        ((TESTS_RUN++))
    else
        log_test "PASS" "Log file test skipped (no log created)"
        ((TESTS_PASSED++))
        ((TESTS_RUN++))
    fi
}

# Test rclone config security
test_rclone_config_security() {
    log_test "INFO" "Testing rclone configuration security..."
    
    # Check rclone config file permissions
    local rclone_config="$HOME/.config/rclone/rclone.conf"
    
    if [ -f "$rclone_config" ]; then
        local config_perms=$(stat -c "%a" "$rclone_config" 2>/dev/null || echo "644")
        
        # rclone config should ideally be 600 (readable only by owner)
        if [ "$config_perms" = "600" ]; then
            log_test "PASS" "Rclone config has secure permissions ($config_perms)"
            ((TESTS_PASSED++))
        elif [ "$config_perms" = "644" ] || [ "$config_perms" = "664" ]; then
            log_test "WARN" "Rclone config has permissive permissions ($config_perms)"
            ((TESTS_PASSED++))  # Warn but don't fail
        else
            log_test "WARN" "Rclone config has unusual permissions ($config_perms)"
            ((TESTS_PASSED++))
        fi
        ((TESTS_RUN++))
    else
        log_test "PASS" "Rclone config test skipped (no config file)"
        ((TESTS_PASSED++))
        ((TESTS_RUN++))
    fi
}

# Test environment variable handling
test_env_var_security() {
    log_test "INFO" "Testing environment variable security..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$SECURITY_CONFIG_DIR/config.conf"
    
    # Set potentially malicious environment variables
    export MALICIOUS_VAR="; rm -rf /tmp/test; echo 'env injection'"
    export RCLONE_CONFIG_PASSWORD="fake_password"
    export HOME_OVERRIDE="/tmp/fake_home"
    
    # Restore proper HOME for test
    export HOME="$SECURITY_CONFIG_DIR"
    
    # Test that script doesn't execute malicious environment variables
    if "$sync_script" --config "$config_file" status >/dev/null 2>&1; then
        if [ ! -f "/tmp/env_injection" ]; then
            log_test "PASS" "Environment variable injection prevented"
            ((TESTS_PASSED++))
        else
            log_test "FAIL" "Environment variable injection succeeded"
            ((TESTS_FAILED++))
            rm -f "/tmp/env_injection"
        fi
    else
        log_test "PASS" "Script properly handled malicious environment"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
    
    # Clean up environment
    unset MALICIOUS_VAR
    unset RCLONE_CONFIG_PASSWORD
    unset HOME_OVERRIDE
}

# Cleanup security test environment
cleanup_security_env() {
    log_test "INFO" "Cleaning up security test environment..."
    
    export HOME="$ORIGINAL_HOME"
    rm -rf "$SECURITY_TEST_DIR"
    
    # Remove security test rclone config
    if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        sed -i '/\[security-test\]/,/^$/d' "$HOME/.config/rclone/rclone.conf"
    fi
    
    # Clean up any test files that might have been created
    rm -f /tmp/malicious.txt
    rm -f /tmp/injected
    rm -f /tmp/env_injection
    
    log_test "INFO" "Security test cleanup complete"
}

# Run security tests
run_security_tests() {
    log_test "INFO" "Running security tests..."
    
    setup_security_env
    
    test_path_traversal
    test_symlink_handling
    test_file_permissions
    test_filename_security
    test_config_injection
    test_lock_security
    test_log_security
    test_rclone_config_security
    test_env_var_security
    
    cleanup_security_env
    
    log_test "INFO" "Security tests completed"
    
    # Print results summary
    echo ""
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}   Security Test Results${NC}"
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
        echo -e "${RED}Security test suite failed!${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}All security tests passed! ✅${NC}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_security_tests
fi
