#!/bin/bash

# Test suite for zsh-uv-env plugin
# This script tests the find_venv function and plugin functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/zsh-uv-env-test-$$"

# Cleanup function
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo
    log_info "Running test: $test_name"
    ((TESTS_RUN++))
    
    if $test_function; then
        log_success "$test_name"
    else
        log_fail "$test_name"
    fi
}

# Source the plugin to get access to find_venv function
source_plugin() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugin_path="$script_dir/zsh-uv-env.plugin.zsh"
    if [[ ! -f "$plugin_path" ]]; then
        echo "Error: Cannot find plugin file at $plugin_path"
        exit 1
    fi
    
    # Source in a subshell to avoid affecting the test environment
    export PLUGIN_PATH="$plugin_path"
}

# Test: find_venv function with .venv directory
test_dotenv_directory() {
    local test_dir="$TEST_DIR/dotenv-test"
    mkdir -p "$test_dir"
    
    # Create .venv with activate script
    mkdir -p "$test_dir/.venv/bin"
    touch "$test_dir/.venv/bin/activate"
    chmod +x "$test_dir/.venv/bin/activate"
    
    # Test find_venv function
    cd "$test_dir"
    local result
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv")
    local expected="$test_dir/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Expected '$expected', got '$result'"
        return 1
    fi
}

# Test: find_venv function with venv directory
test_venv_directory() {
    local test_dir="$TEST_DIR/venv-test"
    mkdir -p "$test_dir"
    
    # Create venv with activate script
    mkdir -p "$test_dir/venv/bin"
    touch "$test_dir/venv/bin/activate"
    chmod +x "$test_dir/venv/bin/activate"
    
    # Test find_venv function
    cd "$test_dir"
    local result
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv")
    local expected="$test_dir/venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Expected '$expected', got '$result'"
        return 1
    fi
}

# Test: Priority order when both .venv and venv exist
test_priority_order() {
    local test_dir="$TEST_DIR/priority-test"
    mkdir -p "$test_dir"
    
    # Create both .venv and venv with activate scripts
    mkdir -p "$test_dir/.venv/bin"
    touch "$test_dir/.venv/bin/activate"
    chmod +x "$test_dir/.venv/bin/activate"
    
    mkdir -p "$test_dir/venv/bin"
    touch "$test_dir/venv/bin/activate"
    chmod +x "$test_dir/venv/bin/activate"
    
    # Test find_venv function - should prefer .venv
    cd "$test_dir"
    local result
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv")
    local expected="$test_dir/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Expected '.venv' to be preferred, but got '$result'"
        return 1
    fi
}

# Test: Validation of activate script existence
test_activate_script_validation() {
    local test_dir="$TEST_DIR/broken-test"
    mkdir -p "$test_dir"
    
    # Create venv directory without activate script
    mkdir -p "$test_dir/venv/bin"
    # Note: No activate script created
    
    # Test find_venv function - should fail
    cd "$test_dir"
    local result
    local exit_code
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv" 2>/dev/null)
    exit_code=$?
    
    if [[ $exit_code -ne 0 && -z "$result" ]]; then
        return 0
    else
        log_fail "Expected find_venv to fail for directory without activate script, but it returned: '$result'"
        return 1
    fi
}

# Test: No virtual environment found
test_no_venv_found() {
    local test_dir="$TEST_DIR/no-venv-test"
    mkdir -p "$test_dir"
    
    # Test find_venv function in directory with no venv
    cd "$test_dir"
    local result
    local exit_code
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv" 2>/dev/null)
    exit_code=$?
    
    if [[ $exit_code -ne 0 && -z "$result" ]]; then
        return 0
    else
        log_fail "Expected find_venv to fail when no venv exists, but it returned: '$result'"
        return 1
    fi
}

# Test: Nested directory search
test_nested_directory_search() {
    local test_dir="$TEST_DIR/nested-test"
    mkdir -p "$test_dir/deep/nested/directory"
    
    # Create .venv in parent directory
    mkdir -p "$test_dir/.venv/bin"
    touch "$test_dir/.venv/bin/activate"
    chmod +x "$test_dir/.venv/bin/activate"
    
    # Test find_venv function from nested directory
    cd "$test_dir/deep/nested/directory"
    local result
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv")
    local expected="$test_dir/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Expected to find parent .venv from nested directory. Expected '$expected', got '$result'"
        return 1
    fi
}

# Test: Plugin integration with real uv environments
test_uv_integration() {
    local test_dir="$TEST_DIR/uv-integration-test"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Check if uv is available
    if ! command -v uv >/dev/null 2>&1; then
        log_warning "uv not available, skipping uv integration test"
        return 0
    fi
    
    # Create actual uv environment
    uv venv .venv >/dev/null 2>&1
    
    # Test find_venv function with real uv environment
    local result
    result=$(bash -c "source '$PLUGIN_PATH'; find_venv")
    local expected="$test_dir/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Failed to detect real uv environment. Expected '$expected', got '$result'"
        return 1
    fi
}

# Test: Home directory boundary
test_home_directory_boundary() {
    # This test ensures the plugin doesn't search beyond the home directory
    local test_dir="$TEST_DIR/home-boundary-test"
    mkdir -p "$test_dir"
    
    # Create a fake home directory structure
    local fake_home="$test_dir/fake-home"
    local project_dir="$fake_home/project"
    mkdir -p "$project_dir"
    
    # Create .venv in fake home
    mkdir -p "$fake_home/.venv/bin"
    touch "$fake_home/.venv/bin/activate"
    chmod +x "$fake_home/.venv/bin/activate"
    
    # Test from project directory with HOME set to fake home
    cd "$project_dir"
    local result
    result=$(bash -c "HOME='$fake_home'; source '$PLUGIN_PATH'; find_venv")
    local expected="$fake_home/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Failed to respect home directory boundary. Expected '$expected', got '$result'"
        return 1
    fi
}

# Main test execution
main() {
    echo "Starting zsh-uv-env plugin test suite"
    echo "====================================="
    
    # Setup
    source_plugin
    mkdir -p "$TEST_DIR"
    
    # Run all tests
    run_test "Test .venv directory detection" test_dotenv_directory
    run_test "Test venv directory detection" test_venv_directory
    run_test "Test priority order (.venv preferred)" test_priority_order
    run_test "Test activate script validation" test_activate_script_validation
    run_test "Test no virtual environment found" test_no_venv_found
    run_test "Test nested directory search" test_nested_directory_search
    run_test "Test uv integration" test_uv_integration
    run_test "Test home directory boundary" test_home_directory_boundary
    
    # Summary
    echo
    echo "Test Results Summary"
    echo "==================="
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed! ✅${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed! ❌${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
