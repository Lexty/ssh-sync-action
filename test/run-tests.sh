#!/bin/bash
set -e

echo "Running tests for SSH Sync Action"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Path to scripts
SCRIPTS_DIR="../src"
TEST_DIR="$(pwd)"

# Create test environment
setup_test_env() {
  echo "Setting up test environment..."

  # Create test directories
  mkdir -p tmp/upload
  mkdir -p tmp/download
  mkdir -p tmp/remote

  # Create test files
  echo "Test file 1 content" > tmp/upload/test1.txt
  echo "Test file 2 content" > tmp/upload/test2.txt

  echo "Remote file 1 content" > tmp/remote/remote1.txt
  echo "Remote file 2 content" > tmp/remote/remote2.txt

  echo "Test environment set up."
}

# Clean up after tests
cleanup_test_env() {
  echo "Cleaning up test environment..."
  rm -rf tmp
  echo "Test environment cleaned up."
}

# Test individual script
test_script() {
  script_name=$1
  description=$2

  echo -e "\nTesting $script_name: $description"
  echo "------------------------------------"

  # Run the shellcheck on the script
  if shellcheck "$SCRIPTS_DIR/$script_name"; then
    echo -e "${GREEN}✓ ShellCheck passed for $script_name${NC}"
  else
    echo -e "${RED}✗ ShellCheck failed for $script_name${NC}"
    return 1
  fi

  # Check if script exists and is executable
  if [ -x "$SCRIPTS_DIR/$script_name" ]; then
    echo -e "${GREEN}✓ Script is executable${NC}"
  else
    echo -e "${RED}✗ Script is not executable${NC}"
    chmod +x "$SCRIPTS_DIR/$script_name"
    echo -e "${GREEN}✓ Made script executable${NC}"
  fi

  echo -e "${GREEN}✓ $script_name test passed${NC}"
  return 0
}

# Run all tests
run_all_tests() {
  local failed=0

  # Test setup-ssh.sh
  if ! test_script "setup-ssh.sh" "SSH key setup script"; then
    failed=$((failed+1))
  fi

  # Test rsync-upload.sh
  if ! test_script "rsync-upload.sh" "rsync upload script"; then
    failed=$((failed+1))
  fi

  # Test rsync-download.sh
  if ! test_script "rsync-download.sh" "rsync download script"; then
    failed=$((failed+1))
  fi

  # Test scp-upload.sh
  if ! test_script "scp-upload.sh" "SCP upload script"; then
    failed=$((failed+1))
  fi

  # Test scp-download.sh
  if ! test_script "scp-download.sh" "SCP download script"; then
    failed=$((failed+1))
  fi

  # Summary
  echo -e "\nTest Summary"
  echo "------------"

  if [ $failed -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    return 0
  else
    echo -e "${RED}$failed test(s) failed!${NC}"
    return 1
  fi
}

# Main
main() {
  # Trap for cleanup
  trap cleanup_test_env EXIT

  # Setup test environment
  setup_test_env

  # Run all tests
  run_all_tests
  exit_code=$?

  # Return exit code
  return $exit_code
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi