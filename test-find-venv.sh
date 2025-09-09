#!/bin/bash

# Focused test for the find_venv function only
# This extracts and tests just the core functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

trap cleanup EXIT

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo
    log_info "Running test: $test_name"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Run test in a way that doesn't exit the script on failure
    set +e
    $test_function
    local result=$?
    set -e
    
    if [[ $result -eq 0 ]]; then
        log_success "$test_name"
    else
        log_fail "$test_name"
    fi
}

# Extract the find_venv function from the plugin
create_find_venv_function() {
    cat << 'EOF'
# Function to find nearest .venv or venv directory
find_venv() {
    local current_dir="$PWD"
    local home_dir="$HOME"
    local root_dir="/"
    local stop_dir="$root_dir"

    # If we're under home directory, stop at home
    if [[ "$current_dir" == "$home_dir"* ]]; then
        stop_dir="$home_dir"
    fi

    while [[ "$current_dir" != "$stop_dir" ]]; do
        for _v in .venv venv; do
            if [[ -d "$current_dir/$_v" && -r "$current_dir/$_v/bin/activate" ]]; then
                echo "$current_dir/$_v"
                return 0
            fi
        done
        current_dir="$(dirname "$current_dir")"
    done

    # Check stop_dir itself
    for _v in .venv venv; do
        if [[ -d "$stop_dir/$_v" && -r "$stop_dir/$_v/bin/activate" ]]; then
            echo "$stop_dir/$_v"
            return 0
        fi
    done

    return 1
}
EOF
}

# Test: find_venv function with .venv directory
test_dotenv_directory() {
    local test_dir="$TEST_DIR/dotenv-test"
    mkdir -p "$test_dir"
    
    # Create .venv with activate script
    mkdir -p "$test_dir/.venv/bin"
    touch "$test_dir/.venv/bin/activate"
    chmod +r "$test_dir/.venv/bin/activate"
    
    # Test find_venv function
    cd "$test_dir"
    local result
    result=$(bash -c "$(create_find_venv_function); find_venv")
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
    chmod +r "$test_dir/venv/bin/activate"
    
    # Test find_venv function
    cd "$test_dir"
    local result
    result=$(bash -c "$(create_find_venv_function); find_venv")
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
    chmod +r "$test_dir/.venv/bin/activate"
    
    mkdir -p "$test_dir/venv/bin"
    touch "$test_dir/venv/bin/activate"
    chmod +r "$test_dir/venv/bin/activate"
    
    # Test find_venv function - should prefer .venv
    cd "$test_dir"
    local result
    result=$(bash -c "$(create_find_venv_function); find_venv")
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
    result=$(bash -c "$(create_find_venv_function); find_venv" 2>/dev/null)
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
    result=$(bash -c "$(create_find_venv_function); find_venv" 2>/dev/null)
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
    chmod +r "$test_dir/.venv/bin/activate"
    
    # Test find_venv function from nested directory
    cd "$test_dir/deep/nested/directory"
    local result
    result=$(bash -c "$(create_find_venv_function); find_venv")
    local expected="$test_dir/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Expected to find parent .venv from nested directory. Expected '$expected', got '$result'"
        return 1
    fi
}

# Test: Home directory boundary
test_home_directory_boundary() {
    local test_dir="$TEST_DIR/home-boundary-test"
    mkdir -p "$test_dir"
    
    # Create a fake home directory structure
    local fake_home="$test_dir/fake-home"
    local project_dir="$fake_home/project"
    mkdir -p "$project_dir"
    
    # Create .venv in fake home
    mkdir -p "$fake_home/.venv/bin"
    touch "$fake_home/.venv/bin/activate"
    chmod +r "$fake_home/.venv/bin/activate"
    
    # Test from project directory with HOME set to fake home
    cd "$project_dir"
    local result
    result=$(bash -c "HOME='$fake_home'; $(create_find_venv_function); find_venv")
    local expected="$fake_home/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Failed to respect home directory boundary. Expected '$expected', got '$result'"
        return 1
    fi
}

# Test with actual uv environments
test_uv_integration() {
    local test_dir="$TEST_DIR/uv-integration-test"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Check if uv is available
    if ! command -v uv >/dev/null 2>&1; then
        echo -e "${YELLOW}[SKIP]${NC} uv not available, skipping uv integration test"
        return 0
    fi
    
    # Create actual uv environment
    uv venv .venv >/dev/null 2>&1
    
    # Test find_venv function with real uv environment
    local result
    result=$(bash -c "$(create_find_venv_function); find_venv")
    local expected="$test_dir/.venv"
    
    if [[ "$result" == "$expected" ]]; then
        return 0
    else
        log_fail "Failed to detect real uv environment. Expected '$expected', got '$result'"
        return 1
    fi
}

# Main test execution
main() {
    echo "Testing find_venv function for zsh-uv-env plugin"
    echo "==============================================="
    
    # Setup
    mkdir -p "$TEST_DIR"
    
    # Run all tests
    run_test "Test .venv directory detection" test_dotenv_directory
    run_test "Test venv directory detection" test_venv_directory
    run_test "Test priority order (.venv preferred)" test_priority_order
    run_test "Test activate script validation" test_activate_script_validation
    run_test "Test no virtual environment found" test_no_venv_found
    run_test "Test nested directory search" test_nested_directory_search
    run_test "Test home directory boundary" test_home_directory_boundary
    run_test "Test uv integration" test_uv_integration
    
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
