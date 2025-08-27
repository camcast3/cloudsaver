# EmuDeck Save Sync - Test Suite Documentation

This directory contains a comprehensive test suite for the EmuDeck Save Sync system. The test suite is designed to ensure reliability, security, performance, and correctness of the save synchronization functionality.

## Test Structure

```
tests/
├── run-all-tests.sh          # Master test runner
├── test-suite.sh             # Main test framework
├── unit-tests.sh             # Individual component tests
├── integration-tests.sh      # Full workflow tests
├── performance-tests.sh      # Speed and scalability tests
├── security-tests.sh         # Security and vulnerability tests
├── test-config.conf          # Test configuration
└── README.md                 # This file
```

## Test Suites

### 1. Unit Tests (`unit-tests.sh`)
Tests individual components and functions in isolation:
- Configuration loading
- Emulator path detection
- Logging functionality
- File operations
- Error handling
- Lock file management

**Run with:** `./tests/unit-tests.sh`

### 2. Integration Tests (`integration-tests.sh`)
Tests complete workflows and component interactions:
- Full sync workflows (upload/download)
- Wrapper script integration
- Steam launch integration
- Conflict resolution
- Large file handling
- Concurrent access protection

**Run with:** `./tests/integration-tests.sh`

### 3. Main Test Suite (`test-suite.sh`)
Core functionality testing framework that includes:
- Script file validation
- Basic command functionality
- Configuration management
- Dry-run operations
- Emulator path validation
- Error scenarios

**Run with:** `./test-suite.sh`

### 4. Performance Tests (`performance-tests.sh`)
Speed, memory, and scalability testing:
- Small file sync performance (< 1MB)
- Medium file sync performance (1-10MB)
- Large file sync performance (10-100MB)
- Bulk sync operations
- Memory usage monitoring
- Concurrent access overhead
- Scalability with many files

**Run with:** `./tests/performance-tests.sh`

**Note:** Performance tests are disabled by default as they can be time-consuming.

### 5. Security Tests (`security-tests.sh`)
Security and vulnerability assessment:
- Path traversal protection
- Symbolic link handling
- File permission preservation
- Filename security
- Configuration injection protection
- Lock file security
- Log file security
- Environment variable handling

**Run with:** `./tests/security-tests.sh`

## Quick Start

### Run All Tests (Recommended)
```bash
# Make scripts executable
chmod +x *.sh tests/*.sh

# Run all test suites (except performance)
./run-all-tests.sh

# Run all tests including performance
./run-all-tests.sh --all

# Run with verbose output and generate report
./run-all-tests.sh -v --report test-results.txt
```

### Run Specific Test Suites
```bash
# Run only unit and integration tests
./run-all-tests.sh --unit --integration

# Run only security tests
./run-all-tests.sh --security

# Run performance tests only
./run-all-tests.sh --performance
```

### Run Individual Test Suites
```bash
# Run unit tests directly
./tests/unit-tests.sh

# Run integration tests directly
./tests/integration-tests.sh
```

## Test Configuration

Test behavior can be customized by editing `tests/test-config.conf`:

```bash
# Performance thresholds
PERF_SMALL_FILE_THRESHOLD=5
PERF_MEDIUM_FILE_THRESHOLD=15
PERF_LARGE_FILE_THRESHOLD=30

# Test coverage
TEST_RETROARCH=true
TEST_DOLPHIN=true
TEST_PCSX2=true

# Security settings
SECURITY_STRICT_MODE=true
```

## Prerequisites

### Required Software
- **rclone** - For cloud synchronization
- **bash** - Shell environment
- **bc** - Basic calculator (for performance tests)
- **standard Unix tools** - grep, sed, awk, find, etc.

### Installation
```bash
# Arch Linux / SteamOS
sudo pacman -S rclone bc

# Ubuntu / Debian
sudo apt install rclone bc

# Fedora
sudo dnf install rclone bc
```

### Test Environment Setup
The test suite creates isolated environments and doesn't interfere with your actual EmuDeck installation. All test data is stored in `/tmp/emudeck-*` directories and cleaned up automatically.

## Test Results and Reporting

### Console Output
Tests provide color-coded output:
- 🟢 **Green** - Passed tests
- 🔴 **Red** - Failed tests
- 🟡 **Yellow** - Warnings
- 🔵 **Blue** - Information
- 🟣 **Purple** - Debug information

### Report Generation
```bash
# Generate detailed report
./run-all-tests.sh --report test-results.txt

# Generate report with verbose output
./run-all-tests.sh -v --report detailed-results.txt
```

Reports include:
- Test summary and statistics
- Individual test results
- Performance metrics
- Detailed output logs
- Environment information

## Continuous Integration

### GitHub Actions Example
```yaml
name: EmuDeck Save Sync Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: sudo apt-get install rclone bc
      - name: Run tests
        run: ./run-all-tests.sh --all --report ci-results.txt
      - name: Upload results
        uses: actions/upload-artifact@v2
        with:
          name: test-results
          path: ci-results.txt
```

## Test Development

### Adding New Tests
1. **Unit Tests**: Add functions to `tests/unit-tests.sh`
2. **Integration Tests**: Add scenarios to `tests/integration-tests.sh`
3. **Performance Tests**: Add benchmarks to `tests/performance-tests.sh`
4. **Security Tests**: Add vulnerability checks to `tests/security-tests.sh`

### Test Framework Functions
```bash
# Assertion functions
assert_equals "expected" "$actual" "test description"
assert_file_exists "/path/to/file" "file should exist"
assert_dir_exists "/path/to/dir" "directory should exist"
assert_command_success "command" "command should succeed"
assert_command_failure "command" "command should fail"

# Logging functions
log_test "PASS" "test passed"
log_test "FAIL" "test failed"
log_test "INFO" "informational message"
log_test "WARN" "warning message"
```

### Test Environment Functions
```bash
# Environment setup
setup_test_environment
cleanup_test_environment

# Mock functions for testing
mock_rclone
mock_emulator
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x *.sh tests/*.sh
   ```

2. **Missing Dependencies**
   ```bash
   # Check what's missing
   ./run-all-tests.sh
   # Install missing tools
   sudo pacman -S rclone bc  # or apt/dnf equivalent
   ```

3. **Tests Hang**
   - Check for background processes
   - Increase timeout in `test-config.conf`
   - Run with `--verbose` to see where it hangs

4. **Rclone Config Issues**
   - Tests use mock local backend by default
   - Real Nextcloud testing requires configuration in `test-config.conf`

5. **Performance Tests Fail**
   - Performance tests have strict time limits
   - Adjust thresholds in `test-config.conf`
   - Consider system load when running

### Debug Mode
```bash
# Run with maximum verbosity
./run-all-tests.sh -v --stop-on-fail

# Check individual test outputs
ls /tmp/test-output-*

# Review test logs
tail -f ~/.config/emudeck-sync/logs/test-suite.log
```

### Test Data Cleanup
```bash
# Manual cleanup if needed
rm -rf /tmp/emudeck-*
rm -rf ~/.config/emudeck-sync/
```

## Performance Benchmarks

### Expected Performance (Local Backend)
- **Small files** (< 1MB): < 5 seconds
- **Medium files** (1-10MB): < 15 seconds
- **Large files** (10-100MB): < 30 seconds
- **Bulk operations**: < 60 seconds

### Memory Usage
- **Normal operation**: < 50MB RAM
- **Large file sync**: < 100MB RAM
- **Bulk operations**: < 150MB RAM

## Security Considerations

The security test suite validates:
- ✅ Path traversal prevention
- ✅ Symbolic link safety
- ✅ File permission handling
- ✅ Configuration injection protection
- ✅ Lock file security
- ✅ Log file privacy
- ✅ Environment variable safety

## Contributing

### Test Contributions Welcome
- Add test cases for edge conditions
- Improve performance benchmarks
- Add security vulnerability checks
- Enhance error handling tests
- Add new emulator support tests

### Test Standards
- Use descriptive test names
- Include both positive and negative test cases
- Clean up test data appropriately
- Document complex test scenarios
- Follow the existing test patterns

---

For questions about the test suite, please refer to the main project documentation or create an issue in the project repository.
