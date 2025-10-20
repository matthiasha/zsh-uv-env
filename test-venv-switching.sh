#!/bin/zsh

# Test for Issue #6: Switching between auto-activated venvs
# This test verifies that the plugin properly switches venvs when
# moving directly from one project to another

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/zsh-uv-env-switch-test-$$"

# Cleanup function
cleanup() {
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

trap cleanup EXIT

echo "Testing venv switching behavior (Issue #6)"
echo "=========================================="

# Setup test directories
mkdir -p "$TEST_DIR"
PROJECT_ONE="$TEST_DIR/project-one"
PROJECT_TWO="$TEST_DIR/project-two"
mkdir -p "$PROJECT_ONE" "$PROJECT_TWO"

# Create .venv for project-one
mkdir -p "$PROJECT_ONE/.venv/bin"
cat > "$PROJECT_ONE/.venv/bin/activate" << 'EOF'
export VIRTUAL_ENV="$PWD/.venv"
export VIRTUAL_ENV_PROMPT="(project-one) "
deactivate() {
    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    unset -f deactivate
}
EOF
chmod +x "$PROJECT_ONE/.venv/bin/activate"

# Create .venv for project-two
mkdir -p "$PROJECT_TWO/.venv/bin"
cat > "$PROJECT_TWO/.venv/bin/activate" << 'EOF'
export VIRTUAL_ENV="$PWD/.venv"
export VIRTUAL_ENV_PROMPT="(project-two) "
deactivate() {
    unset VIRTUAL_ENV
    unset VIRTUAL_ENV_PROMPT
    unset -f deactivate
}
EOF
chmod +x "$PROJECT_TWO/.venv/bin/activate"

# Source the plugin
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/zsh-uv-env.plugin.zsh"

echo
echo -e "${BLUE}[TEST 1]${NC} cd to project-one"
cd "$PROJECT_ONE"
autoenv_chpwd

if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$PROJECT_ONE/.venv" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - project-one venv activated: $VIRTUAL_ENV"
else
    echo -e "${RED}✗ FAIL${NC} - Expected $PROJECT_ONE/.venv, got: $VIRTUAL_ENV"
    exit 1
fi

echo
echo -e "${BLUE}[TEST 2]${NC} cd directly to project-two (the issue scenario)"
cd "$PROJECT_TWO"
autoenv_chpwd

if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$PROJECT_TWO/.venv" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - project-two venv activated: $VIRTUAL_ENV"
else
    echo -e "${RED}✗ FAIL${NC} - Expected $PROJECT_TWO/.venv, got: $VIRTUAL_ENV"
    exit 1
fi

echo
echo -e "${BLUE}[TEST 3]${NC} cd back to project-one"
cd "$PROJECT_ONE"
autoenv_chpwd

if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$PROJECT_ONE/.venv" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - project-one venv activated again: $VIRTUAL_ENV"
else
    echo -e "${RED}✗ FAIL${NC} - Expected $PROJECT_ONE/.venv, got: $VIRTUAL_ENV"
    exit 1
fi

echo
echo -e "${BLUE}[TEST 4]${NC} cd to parent directory (should deactivate)"
cd "$TEST_DIR"
autoenv_chpwd

if [[ -z "$VIRTUAL_ENV" ]]; then
    echo -e "${GREEN}✓ PASS${NC} - venv properly deactivated"
else
    echo -e "${RED}✗ FAIL${NC} - Expected no venv, but got: $VIRTUAL_ENV"
    exit 1
fi

echo
echo -e "${GREEN}All tests passed! ✅${NC}"
echo "Issue #6 is fixed - venv switching works correctly"

