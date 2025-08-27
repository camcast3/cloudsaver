#!/bin/bash

# Master test runner for EmuDeck Save Sync system
# Orchestrates and runs all test suites with comprehensive reporting

PROJECT_ROOT="$(dirname "$0")"
TEST_DIR="$PROJECT_ROOT/tests"

# Test suite files
MAIN_TEST_SUITE="$PROJECT_ROOT/test-suite.sh"
UNIT_TESTS="$TEST_DIR/unit-tests.sh"
INTEGRATION_TESTS="$TEST_DIR/integration-tests.sh"
PERFORMANCE_TESTS="$TEST_DIR/performance-tests.sh"
SECURITY_TESTS="$TEST_DIR/security-tests.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global test tracking
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
SUITE_RESULTS=()

# Test configuration
RUN_UNIT=true
RUN_INTEGRATION=true
RUN_MAIN=true
RUN_PERFORMANCE=false  # Disabled by default due to time
RUN_SECURITY=true
VERBOSE_OUTPUT=false
STOP_ON_FAILURE=false
GENERATE_REPORT=true
REPORT_FILE=""

# Usage information
show_usage() {
    cat << EOF
EmuDeck Save Sync - Master Test Runner

Usage: $0 [OPTIONS]

Test Suites:
    --unit              Run unit tests only
    --integration       Run integration tests only
    --main              Run main test suite only
    --performance       Run performance tests only
    --security          Run security tests only
    --all               Run all test suites (default)

Options:
    -v, --verbose       Enable verbose output
    -s, --stop-on-fail  Stop on first test suite failure
    -r, --report FILE   Generate detailed report to file
    -h, --help          Show this help message

Examples:
    $0                          # Run all tests except performance
    $0 --all                    # Run all tests including performance
    $0 --unit --integration     # Run only unit and integration tests
    $0 -v --report results.txt  # Verbose output with report file
    $0 --performance           # Run only performance tests

Test Suites Description:
    Unit Tests      - Test individual functions and components
    Integration     - Test complete workflows and interactions
    Main Suite      - Test basic functionality and error handling
    Performance     - Test speed, memory usage, and scalability
    Security        - Test security features and vulnerability protection
EOF
}

# Parse command line arguments
parse_arguments() {
    local explicit_suites=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit)
                if [ "$explicit_suites" = false ]; then
                    RUN_UNIT=true
                    RUN_INTEGRATION=false
                    RUN_MAIN=false
                    RUN_PERFORMANCE=false
                    RUN_SECURITY=false
                    explicit_suites=true
                else
                    RUN_UNIT=true
                fi
                shift
                ;;
            --integration)
                if [ "$explicit_suites" = false ]; then
                    RUN_UNIT=false
                    RUN_INTEGRATION=true
                    RUN_MAIN=false
                    RUN_PERFORMANCE=false
                    RUN_SECURITY=false
                    explicit_suites=true
                else
                    RUN_INTEGRATION=true
                fi
                shift
                ;;
            --main)
                if [ "$explicit_suites" = false ]; then
                    RUN_UNIT=false
                    RUN_INTEGRATION=false
                    RUN_MAIN=true
                    RUN_PERFORMANCE=false
                    RUN_SECURITY=false
                    explicit_suites=true
                else
                    RUN_MAIN=true
                fi
                shift
                ;;
            --performance)
                if [ "$explicit_suites" = false ]; then
                    RUN_UNIT=false
                    RUN_INTEGRATION=false
                    RUN_MAIN=false
                    RUN_PERFORMANCE=true
                    RUN_SECURITY=false
                    explicit_suites=true
                else
                    RUN_PERFORMANCE=true
                fi
                shift
                ;;
            --security)
                if [ "$explicit_suites" = false ]; then
                    RUN_UNIT=false
                    RUN_INTEGRATION=false
                    RUN_MAIN=false
                    RUN_PERFORMANCE=false
                    RUN_SECURITY=true
                    explicit_suites=true
                else
                    RUN_SECURITY=true
                fi
                shift
                ;;
            --all)
                RUN_UNIT=true
                RUN_INTEGRATION=true
                RUN_MAIN=true
                RUN_PERFORMANCE=true
                RUN_SECURITY=true
                shift
                ;;
            -v|--verbose)
                VERBOSE_OUTPUT=true
                shift
                ;;
            -s|--stop-on-fail)
                STOP_ON_FAILURE=true
                shift
                ;;
            -r|--report)
                GENERATE_REPORT=true
                REPORT_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Error: Unknown option $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set default report file if not specified
    if [ "$GENERATE_REPORT" = true ] && [ -z "$REPORT_FILE" ]; then
        REPORT_FILE="test-results-$(date +%Y%m%d-%H%M%S).txt"
    fi
}

# Run a test suite and capture results
run_test_suite() {
    local suite_name="$1"
    local suite_script="$2"
    local suite_description="$3"
    
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                     $suite_description${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$suite_script" ]; then
        echo -e "${RED}Error: Test suite not found: $suite_script${NC}"
        SUITE_RESULTS+=("$suite_name:ERROR:Test suite file not found")
        return 1
    fi
    
    # Make sure test script is executable
    chmod +x "$suite_script"
    
    local start_time=$(date +%s)
    local temp_output="/tmp/test-output-$$-$suite_name"
    
    # Run the test suite
    if [ "$VERBOSE_OUTPUT" = true ]; then
        echo -e "${CYAN}Running $suite_name tests...${NC}"
        "$suite_script" 2>&1 | tee "$temp_output"
        local exit_code=${PIPESTATUS[0]}
    else
        echo -e "${CYAN}Running $suite_name tests...${NC}"
        "$suite_script" > "$temp_output" 2>&1
        local exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Parse results from output
    local tests_run=0
    local tests_passed=0
    local tests_failed=0
    
    if [ -f "$temp_output" ]; then
        tests_run=$(awk '/Tests run:/ { print $3 }' "$temp_output" | tail -1 || echo "0")
        tests_passed=$(awk '/Tests passed:/ { print $3 }' "$temp_output" | tail -1 || echo "0")
        tests_failed=$(awk '/Tests failed:/ { print $3 }' "$temp_output" | tail -1 || echo "0")
    fi
    
    # Update totals
    TOTAL_TESTS=$((TOTAL_TESTS + tests_run))
    TOTAL_PASSED=$((TOTAL_PASSED + tests_passed))
    TOTAL_FAILED=$((TOTAL_FAILED + tests_failed))
    
    # Report results
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ $suite_name completed successfully${NC}"
        echo -e "${GREEN}   Tests: $tests_run, Passed: $tests_passed, Failed: $tests_failed, Time: ${duration}s${NC}"
        SUITE_RESULTS+=("$suite_name:PASS:$tests_run:$tests_passed:$tests_failed:${duration}s")
    else
        echo -e "${RED}❌ $suite_name failed${NC}"
        echo -e "${RED}   Tests: $tests_run, Passed: $tests_passed, Failed: $tests_failed, Time: ${duration}s${NC}"
        SUITE_RESULTS+=("$suite_name:FAIL:$tests_run:$tests_passed:$tests_failed:${duration}s")
        
        if [ "$VERBOSE_OUTPUT" = false ]; then
            echo -e "${YELLOW}Last few lines of output:${NC}"
            tail -10 "$temp_output"
        fi
        
        if [ "$STOP_ON_FAILURE" = true ]; then
            echo -e "${RED}Stopping due to test failure (--stop-on-fail)${NC}"
            cleanup_temp_files
            exit 1
        fi
    fi
    
    # Save output for report
    if [ "$GENERATE_REPORT" = true ]; then
        echo "=== $suite_name Test Suite Output ===" >> "$temp_output.report"
        cat "$temp_output" >> "$temp_output.report"
        echo "" >> "$temp_output.report"
    fi
    
    rm -f "$temp_output"
    return $exit_code
}

# Generate comprehensive report
generate_report() {
    if [ "$GENERATE_REPORT" = false ] || [ -z "$REPORT_FILE" ]; then
        return
    fi
    
    echo -e "${CYAN}Generating test report: $REPORT_FILE${NC}"
    
    cat > "$REPORT_FILE" << EOF
EmuDeck Save Sync - Test Results Report
=====================================

Generated: $(date)
Test Environment: $(uname -a)
Shell: $SHELL
User: $(whoami)

SUMMARY
=======
Total Test Suites: ${#SUITE_RESULTS[@]}
Total Tests Run: $TOTAL_TESTS
Total Tests Passed: $TOTAL_PASSED
Total Tests Failed: $TOTAL_FAILED
Overall Success Rate: $((TOTAL_TESTS > 0 ? (TOTAL_PASSED * 100 / TOTAL_TESTS) : 0))%

SUITE RESULTS
=============
EOF
    
    for result in "${SUITE_RESULTS[@]}"; do
        IFS=':' read -r suite status tests_run tests_passed tests_failed duration <<< "$result"
        echo "[$status] $suite - Tests: $tests_run, Passed: $tests_passed, Failed: $tests_failed, Duration: $duration" >> "$REPORT_FILE"
    done
    
    echo "" >> "$REPORT_FILE"
    echo "DETAILED OUTPUT" >> "$REPORT_FILE"
    echo "===============" >> "$REPORT_FILE"
    
    # Append detailed outputs
    for temp_report in /tmp/test-output-$$-*.report; do
        if [ -f "$temp_report" ]; then
            cat "$temp_report" >> "$REPORT_FILE"
            rm -f "$temp_report"
        fi
    done
    
    echo -e "${GREEN}Report generated: $REPORT_FILE${NC}"
}

# Cleanup temporary files
cleanup_temp_files() {
    rm -f /tmp/test-output-$$-*
}

# Check prerequisites and install if needed
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    local missing_deps=()
    
    # Check required tools
    if ! command -v rclone >/dev/null 2>&1; then
        echo -e "${YELLOW}rclone not found, attempting automatic installation...${NC}"
        
        # Try to install rclone
        if command -v apt >/dev/null 2>&1; then
            echo -e "${CYAN}Installing rclone using apt...${NC}"
            sudo apt update >/dev/null 2>&1 && sudo apt install -y rclone >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            echo -e "${CYAN}Installing rclone using yum...${NC}"
            sudo yum install -y rclone >/dev/null 2>&1
        elif command -v dnf >/dev/null 2>&1; then
            echo -e "${CYAN}Installing rclone using dnf...${NC}"
            sudo dnf install -y rclone >/dev/null 2>&1
        elif command -v pacman >/dev/null 2>&1; then
            echo -e "${CYAN}Installing rclone using pacman...${NC}"
            sudo pacman -S --noconfirm rclone >/dev/null 2>&1
        elif command -v brew >/dev/null 2>&1; then
            echo -e "${CYAN}Installing rclone using homebrew...${NC}"
            brew install rclone >/dev/null 2>&1
        else
            echo -e "${YELLOW}Attempting manual rclone installation...${NC}"
            
            # Manual installation for tests
            local temp_dir=$(mktemp -d)
            local arch=$(uname -m)
            local os=$(uname -s | tr '[:upper:]' '[:lower:]')
            
            case $arch in
                x86_64|amd64) arch="amd64" ;;
                aarch64|arm64) arch="arm64" ;;
                armv7l|armhf) arch="arm" ;;
                i386|i686) arch="386" ;;
            esac
            
            case $os in
                linux) os="linux" ;;
                darwin) os="osx" ;;
            esac
            
            local download_url="https://downloads.rclone.org/current/rclone-current-${os}-${arch}.zip"
            
            if command -v curl >/dev/null 2>&1; then
                curl -L -o "$temp_dir/rclone.zip" "$download_url" >/dev/null 2>&1
            elif command -v wget >/dev/null 2>&1; then
                wget -O "$temp_dir/rclone.zip" "$download_url" >/dev/null 2>&1
            else
                missing_deps+=("rclone")
            fi
            
            if [ -f "$temp_dir/rclone.zip" ] && command -v unzip >/dev/null 2>&1; then
                unzip -q "$temp_dir/rclone.zip" -d "$temp_dir"
                local rclone_binary=$(find "$temp_dir" -name "rclone" -type f | head -1)
                
                if [ -n "$rclone_binary" ]; then
                    mkdir -p "$HOME/.local/bin"
                    cp "$rclone_binary" "$HOME/.local/bin/rclone"
                    chmod +x "$HOME/.local/bin/rclone"
                    export PATH="$HOME/.local/bin:$PATH"
                    echo -e "${GREEN}✅ rclone installed to ~/.local/bin/rclone${NC}"
                fi
            fi
            
            rm -rf "$temp_dir"
        fi
        
        # Verify installation
        if ! command -v rclone >/dev/null 2>&1; then
            missing_deps+=("rclone")
        else
            echo -e "${GREEN}✅ rclone installation successful${NC}"
        fi
    else
        echo -e "${GREEN}✅ rclone is available${NC}"
    fi
    
    if ! command -v bc >/dev/null 2>&1 && [ "$RUN_PERFORMANCE" = true ]; then
        echo -e "${YELLOW}Warning: bc not found, performance tests may be limited${NC}"
    fi
    
    # Check main scripts exist
    if [ ! -f "$PROJECT_ROOT/emudeck-sync.sh" ]; then
        echo -e "${RED}Error: Main sync script not found: $PROJECT_ROOT/emudeck-sync.sh${NC}"
        exit 1
    fi
    
    if [ ! -f "$PROJECT_ROOT/emudeck-wrapper.sh" ]; then
        echo -e "${RED}Error: Wrapper script not found: $PROJECT_ROOT/emudeck-wrapper.sh${NC}"
        exit 1
    fi
    
    # Make scripts executable
    chmod +x "$PROJECT_ROOT"/*.sh 2>/dev/null || true
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}Please install missing dependencies manually:${NC}"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "rclone")
                    echo -e "${WHITE}  Install rclone:${NC}"
                    echo -e "    Ubuntu/Debian: ${CYAN}sudo apt install rclone${NC}"
                    echo -e "    Fedora: ${CYAN}sudo dnf install rclone${NC}"
                    echo -e "    Arch: ${CYAN}sudo pacman -S rclone${NC}"
                    echo -e "    macOS: ${CYAN}brew install rclone${NC}"
                    echo -e "    Or visit: ${CYAN}https://rclone.org/install/${NC}"
                    ;;
            esac
        done
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Main test execution
main() {
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║              EmuDeck Save Sync - Master Test Runner           ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show test plan
    echo -e "${BLUE}Test Plan:${NC}"
    [ "$RUN_UNIT" = true ] && echo -e "  ${GREEN}✓${NC} Unit Tests"
    [ "$RUN_INTEGRATION" = true ] && echo -e "  ${GREEN}✓${NC} Integration Tests"
    [ "$RUN_MAIN" = true ] && echo -e "  ${GREEN}✓${NC} Main Test Suite"
    [ "$RUN_PERFORMANCE" = true ] && echo -e "  ${GREEN}✓${NC} Performance Tests"
    [ "$RUN_SECURITY" = true ] && echo -e "  ${GREEN}✓${NC} Security Tests"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    local start_time=$(date +%s)
    local overall_success=true
    
    # Run selected test suites
    if [ "$RUN_UNIT" = true ]; then
        run_test_suite "Unit" "$UNIT_TESTS" "Unit Tests - Individual Component Testing"
        [ $? -ne 0 ] && overall_success=false
    fi
    
    if [ "$RUN_INTEGRATION" = true ]; then
        run_test_suite "Integration" "$INTEGRATION_TESTS" "Integration Tests - Complete Workflow Testing"
        [ $? -ne 0 ] && overall_success=false
    fi
    
    if [ "$RUN_MAIN" = true ]; then
        run_test_suite "Main" "$MAIN_TEST_SUITE" "Main Test Suite - Core Functionality Testing"
        [ $? -ne 0 ] && overall_success=false
    fi
    
    if [ "$RUN_PERFORMANCE" = true ]; then
        run_test_suite "Performance" "$PERFORMANCE_TESTS" "Performance Tests - Speed and Scalability Testing"
        [ $? -ne 0 ] && overall_success=false
    fi
    
    if [ "$RUN_SECURITY" = true ]; then
        run_test_suite "Security" "$SECURITY_TESTS" "Security Tests - Vulnerability and Safety Testing"
        [ $? -ne 0 ] && overall_success=false
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Final results
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                        FINAL RESULTS                          ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "${BLUE}Test Suites Run:${NC} ${#SUITE_RESULTS[@]}"
    echo -e "${BLUE}Total Tests:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}Tests Passed:${NC} $TOTAL_PASSED"
    echo -e "${RED}Tests Failed:${NC} $TOTAL_FAILED"
    echo -e "${BLUE}Total Duration:${NC} ${total_duration}s"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$((TOTAL_PASSED * 100 / TOTAL_TESTS))
        echo -e "${PURPLE}Success Rate:${NC} ${success_rate}%"
    fi
    
    # Generate report
    generate_report
    
    # Cleanup
    cleanup_temp_files
    
    echo ""
    if [ "$overall_success" = true ] && [ $TOTAL_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED! The EmuDeck Save Sync system is ready for use.${NC}"
        exit 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED. Please review the results and fix issues before deployment.${NC}"
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup_temp_files EXIT

# Run main function
main "$@"
