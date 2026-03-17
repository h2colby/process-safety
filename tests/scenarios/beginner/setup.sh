#!/usr/bin/env bash
set -euo pipefail

# Create a clean temporary test environment for the beginner scenario
TEST_DIR=$(mktemp -d -t psm-test-beginner-XXXXXX)
PLUGIN_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"

echo "Setting up beginner test scenario..."
echo "  Test directory: $TEST_DIR"
echo "  Plugin source:  $PLUGIN_DIR"

# Copy plugin files into test directory
cp -r "$PLUGIN_DIR" "$TEST_DIR/process-safety"

# Create the working directory structure
mkdir -p "$TEST_DIR/work"

echo ""
echo "Setup complete. To run the test:"
echo "  cd $TEST_DIR/work"
echo "  # Then run /process-safety:screen, etc."
echo ""
echo "To run verification scripts after each step:"
echo "  bash $TEST_DIR/process-safety/tests/scenarios/beginner/verify-screen.sh $TEST_DIR/work"
echo "  bash $TEST_DIR/process-safety/tests/scenarios/beginner/verify-generate.sh $TEST_DIR/work"
echo ""
echo "Test directory: $TEST_DIR"
