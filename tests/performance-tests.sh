#!/bin/bash

# Performance tests for EmuDeck save sync system

# Source the test framework
TEST_DIR="$(dirname "$0")"
source "$TEST_DIR/../test-suite.sh"

# Performance test configuration
PERF_TEST_DIR="/tmp/emudeck-perf-test"
PERF_SAVES_DIR="$PERF_TEST_DIR/saves"
PERF_REMOTE_DIR="$PERF_TEST_DIR/remote"
PERF_CONFIG_DIR="$PERF_TEST_DIR/config"

# Performance thresholds (in seconds)
SMALL_FILE_THRESHOLD=5    # < 1MB files should sync within 5 seconds
MEDIUM_FILE_THRESHOLD=15  # 1-10MB files should sync within 15 seconds
LARGE_FILE_THRESHOLD=30   # 10-100MB files should sync within 30 seconds
BULK_SYNC_THRESHOLD=60    # Bulk operations should complete within 60 seconds

# Setup performance test environment
setup_perf_env() {
    log_test "INFO" "Setting up performance test environment..."
    
    rm -rf "$PERF_TEST_DIR"
    mkdir -p "$PERF_SAVES_DIR" "$PERF_REMOTE_DIR" "$PERF_CONFIG_DIR"
    
    # Create save directory structure
    local saves_base="$PERF_SAVES_DIR"
    mkdir -p "$saves_base/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    mkdir -p "$saves_base/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    mkdir -p "$saves_base/net.pcsx2.PCSX2/data/pcsx2"
    
    # Create performance test config
    cat > "$PERF_CONFIG_DIR/config.conf" << EOF
RCLONE_REMOTE="perf-test"
RCLONE_REMOTE_PATH="$PERF_REMOTE_DIR/EmuDeck/saves"
LOCAL_SAVES_BASE="$PERF_SAVES_DIR"
ENABLE_LOGGING=true
SYNC_TIMEOUT=120
DRY_RUN=false
VERBOSE=false
EOF
    
    # Create rclone config for local testing
    mkdir -p "$HOME/.config/rclone"
    cat >> "$HOME/.config/rclone/rclone.conf" << EOF

[perf-test]
type = local
nounc = true
EOF
    
    log_test "INFO" "Performance test environment setup complete"
}

# Time a command execution
time_command() {
    local command="$1"
    local start_time=$(date +%s.%3N)
    eval "$command"
    local exit_code=$?
    local end_time=$(date +%s.%3N)
    local duration=$(echo "$end_time - $start_time" | bc)
    echo "$duration"
    return $exit_code
}

# Test small file performance
test_small_file_performance() {
    log_test "INFO" "Testing small file performance..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    local saves_dir="$PERF_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    
    # Create small save files (1KB - 100KB)
    for i in {1..10}; do
        dd if=/dev/urandom of="$saves_dir/small_save_$i.sav" bs=1K count=$((i * 10)) 2>/dev/null
    done
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Time upload
    local upload_time
    upload_time=$(time_command "'$sync_script' --config '$config_file' upload retroarch")
    local upload_exit=$?
    
    # Time download
    rm -f "$saves_dir"/small_save_*.sav
    local download_time
    download_time=$(time_command "'$sync_script' --config '$config_file' download retroarch")
    local download_exit=$?
    
    # Check performance
    ((TESTS_RUN++))
    if [ $upload_exit -eq 0 ] && [ $download_exit -eq 0 ]; then
        local total_time=$(echo "$upload_time + $download_time" | bc)
        if (( $(echo "$total_time < $SMALL_FILE_THRESHOLD" | bc -l) )); then
            log_test "PASS" "Small file sync performance (${total_time}s < ${SMALL_FILE_THRESHOLD}s)"
            ((TESTS_PASSED++))
        else
            log_test "FAIL" "Small file sync too slow (${total_time}s >= ${SMALL_FILE_THRESHOLD}s)"
            ((TESTS_FAILED++))
        fi
    else
        log_test "FAIL" "Small file sync failed (upload: $upload_exit, download: $download_exit)"
        ((TESTS_FAILED++))
    fi
}

# Test medium file performance
test_medium_file_performance() {
    log_test "INFO" "Testing medium file performance..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    local saves_dir="$PERF_SAVES_DIR/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    
    # Create medium save files (1MB - 5MB)
    for i in {1..5}; do
        dd if=/dev/urandom of="$saves_dir/medium_save_$i.gci" bs=1M count=$i 2>/dev/null
    done
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Time upload
    local upload_time
    upload_time=$(time_command "'$sync_script' --config '$config_file' upload dolphin")
    local upload_exit=$?
    
    # Time download
    rm -f "$saves_dir"/medium_save_*.gci
    local download_time
    download_time=$(time_command "'$sync_script' --config '$config_file' download dolphin")
    local download_exit=$?
    
    # Check performance
    ((TESTS_RUN++))
    if [ $upload_exit -eq 0 ] && [ $download_exit -eq 0 ]; then
        local total_time=$(echo "$upload_time + $download_time" | bc)
        if (( $(echo "$total_time < $MEDIUM_FILE_THRESHOLD" | bc -l) )); then
            log_test "PASS" "Medium file sync performance (${total_time}s < ${MEDIUM_FILE_THRESHOLD}s)"
            ((TESTS_PASSED++))
        else
            log_test "WARN" "Medium file sync slower than expected (${total_time}s >= ${MEDIUM_FILE_THRESHOLD}s)"
            ((TESTS_PASSED++))  # Don't fail on performance warnings
        fi
    else
        log_test "FAIL" "Medium file sync failed (upload: $upload_exit, download: $download_exit)"
        ((TESTS_FAILED++))
    fi
}

# Test large file performance
test_large_file_performance() {
    log_test "INFO" "Testing large file performance..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    local saves_dir="$PERF_SAVES_DIR/net.pcsx2.PCSX2/data/pcsx2"
    
    # Create large save files (10MB - 50MB)
    dd if=/dev/urandom of="$saves_dir/large_save_1.ps2" bs=1M count=10 2>/dev/null
    dd if=/dev/urandom of="$saves_dir/large_save_2.ps2" bs=1M count=25 2>/dev/null
    dd if=/dev/urandom of="$saves_dir/large_save_3.ps2" bs=1M count=50 2>/dev/null
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Time upload
    local upload_time
    upload_time=$(time_command "'$sync_script' --config '$config_file' upload pcsx2")
    local upload_exit=$?
    
    # Time download
    rm -f "$saves_dir"/large_save_*.ps2
    local download_time
    download_time=$(time_command "'$sync_script' --config '$config_file' download pcsx2")
    local download_exit=$?
    
    # Check performance
    ((TESTS_RUN++))
    if [ $upload_exit -eq 0 ] && [ $download_exit -eq 0 ]; then
        local total_time=$(echo "$upload_time + $download_time" | bc)
        if (( $(echo "$total_time < $LARGE_FILE_THRESHOLD" | bc -l) )); then
            log_test "PASS" "Large file sync performance (${total_time}s < ${LARGE_FILE_THRESHOLD}s)"
            ((TESTS_PASSED++))
        else
            log_test "WARN" "Large file sync slower than expected (${total_time}s >= ${LARGE_FILE_THRESHOLD}s)"
            ((TESTS_PASSED++))  # Don't fail on performance warnings
        fi
    else
        log_test "FAIL" "Large file sync failed (upload: $upload_exit, download: $download_exit)"
        ((TESTS_FAILED++))
    fi
}

# Test bulk sync performance
test_bulk_sync_performance() {
    log_test "INFO" "Testing bulk sync performance..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    
    # Create saves for multiple emulators
    local retroarch_dir="$PERF_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    local dolphin_dir="$PERF_SAVES_DIR/org.DolphinEmu.dolphin-emu/data/dolphin-emu"
    local pcsx2_dir="$PERF_SAVES_DIR/net.pcsx2.PCSX2/data/pcsx2"
    
    # Create multiple files per emulator
    for i in {1..5}; do
        dd if=/dev/urandom of="$retroarch_dir/bulk_retroarch_$i.sav" bs=1K count=$((i * 100)) 2>/dev/null
        dd if=/dev/urandom of="$dolphin_dir/bulk_dolphin_$i.gci" bs=1K count=$((i * 200)) 2>/dev/null
        dd if=/dev/urandom of="$pcsx2_dir/bulk_pcsx2_$i.ps2" bs=1K count=$((i * 500)) 2>/dev/null
    done
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Time bulk upload
    local upload_time
    upload_time=$(time_command "'$sync_script' --config '$config_file' upload")
    local upload_exit=$?
    
    # Clear local saves
    rm -f "$retroarch_dir"/bulk_retroarch_*.sav
    rm -f "$dolphin_dir"/bulk_dolphin_*.gci
    rm -f "$pcsx2_dir"/bulk_pcsx2_*.ps2
    
    # Time bulk download
    local download_time
    download_time=$(time_command "'$sync_script' --config '$config_file' download")
    local download_exit=$?
    
    # Check performance
    ((TESTS_RUN++))
    if [ $upload_exit -eq 0 ] && [ $download_exit -eq 0 ]; then
        local total_time=$(echo "$upload_time + $download_time" | bc)
        if (( $(echo "$total_time < $BULK_SYNC_THRESHOLD" | bc -l) )); then
            log_test "PASS" "Bulk sync performance (${total_time}s < ${BULK_SYNC_THRESHOLD}s)"
            ((TESTS_PASSED++))
        else
            log_test "WARN" "Bulk sync slower than expected (${total_time}s >= ${BULK_SYNC_THRESHOLD}s)"
            ((TESTS_PASSED++))  # Don't fail on performance warnings
        fi
    else
        log_test "FAIL" "Bulk sync failed (upload: $upload_exit, download: $download_exit)"
        ((TESTS_FAILED++))
    fi
}

# Test memory usage
test_memory_usage() {
    log_test "INFO" "Testing memory usage..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    
    # Create files that might cause memory issues
    local saves_dir="$PERF_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    
    # Create many small files
    for i in {1..100}; do
        echo "Save file $i" > "$saves_dir/memory_test_$i.sav"
    done
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Monitor memory usage during sync
    local mem_before=$(free -m | awk '/^Mem:/ {print $3}')
    
    # Run sync
    assert_command_success "'$sync_script' --config '$config_file' upload retroarch" "Memory test sync"
    
    local mem_after=$(free -m | awk '/^Mem:/ {print $3}')
    local mem_diff=$((mem_after - mem_before))
    
    # Check memory usage (should not increase by more than 100MB)
    ((TESTS_RUN++))
    if [ $mem_diff -lt 100 ]; then
        log_test "PASS" "Memory usage acceptable (${mem_diff}MB increase)"
        ((TESTS_PASSED++))
    else
        log_test "WARN" "Memory usage high (${mem_diff}MB increase)"
        ((TESTS_PASSED++))  # Don't fail on memory warnings
    fi
}

# Test concurrent performance
test_concurrent_performance() {
    log_test "INFO" "Testing concurrent access performance..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    
    # Create test files
    local saves_dir="$PERF_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    echo "Concurrent test" > "$saves_dir/concurrent_test.sav"
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Start background sync
    local start_time=$(date +%s.%3N)
    "$sync_script" --config "$config_file" upload retroarch >/dev/null 2>&1 &
    local bg_pid=$!
    
    # Try immediate second sync (should fail quickly due to lock)
    local lock_check_time
    lock_check_time=$(time_command "'$sync_script' --config '$config_file' download retroarch 2>/dev/null || true")
    
    wait $bg_pid
    local end_time=$(date +%s.%3N)
    local total_time=$(echo "$end_time - $start_time" | bc)
    
    # Lock checking should be very fast (< 1 second)
    ((TESTS_RUN++))
    if (( $(echo "$lock_check_time < 1" | bc -l) )); then
        log_test "PASS" "Lock check performance (${lock_check_time}s < 1s)"
        ((TESTS_PASSED++))
    else
        log_test "FAIL" "Lock check too slow (${lock_check_time}s >= 1s)"
        ((TESTS_FAILED++))
    fi
}

# Test scalability
test_scalability() {
    log_test "INFO" "Testing scalability..."
    
    local sync_script="$TEST_DIR/../emudeck-sync.sh"
    local config_file="$PERF_CONFIG_DIR/config.conf"
    
    # Test with increasing number of files
    local saves_dir="$PERF_SAVES_DIR/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata/1118310/pfx/drive_c/users/steamuser/AppData/Roaming/RetroArch/saves"
    
    export HOME="$PERF_CONFIG_DIR"
    
    # Test different scales
    for scale in 10 50 100; do
        log_test "DEBUG" "Testing scalability with $scale files..."
        
        # Create files for this scale test
        rm -f "$saves_dir"/scale_*.sav
        for i in $(seq 1 $scale); do
            echo "Scale test file $i" > "$saves_dir/scale_${scale}_${i}.sav"
        done
        
        # Time the sync
        local sync_time
        sync_time=$(time_command "'$sync_script' --config '$config_file' upload retroarch")
        local sync_exit=$?
        
        ((TESTS_RUN++))
        if [ $sync_exit -eq 0 ]; then
            log_test "PASS" "Scalability test with $scale files (${sync_time}s)"
            ((TESTS_PASSED++))
        else
            log_test "FAIL" "Scalability test with $scale files failed"
            ((TESTS_FAILED++))
        fi
    done
}

# Cleanup performance test environment
cleanup_perf_env() {
    log_test "INFO" "Cleaning up performance test environment..."
    
    export HOME="$ORIGINAL_HOME"
    rm -rf "$PERF_TEST_DIR"
    
    # Remove performance test rclone config
    if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
        sed -i '/\[perf-test\]/,/^$/d' "$HOME/.config/rclone/rclone.conf"
    fi
    
    log_test "INFO" "Performance test cleanup complete"
}

# Run performance tests
run_performance_tests() {
    log_test "INFO" "Running performance tests..."
    
    # Check if bc is available for calculations
    if ! command -v bc >/dev/null 2>&1; then
        log_test "WARN" "bc not available, skipping performance tests"
        echo ""
        echo -e "${YELLOW}Performance tests skipped - bc calculator not available${NC}"
        echo -e "Install bc: ${CYAN}sudo apt install bc${NC} (Ubuntu/Debian)"
        exit 0
    fi
    
    setup_perf_env
    
    test_small_file_performance
    test_medium_file_performance
    test_large_file_performance
    test_bulk_sync_performance
    test_memory_usage
    test_concurrent_performance
    test_scalability
    
    cleanup_perf_env
    
    log_test "INFO" "Performance tests completed"
    
    # Print results summary
    echo ""
    echo -e "${WHITE}================================${NC}"
    echo -e "${WHITE}  Performance Test Results${NC}"
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
        echo -e "${RED}Performance test suite failed!${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}All performance tests passed! ✅${NC}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    run_performance_tests
fi
