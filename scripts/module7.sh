#!/usr/bin/env bash
#
# Module 7: I²C — Protocol + RTL + Basic Testbench
#
# Usage:
#   ./scripts/module7.sh [--check] [--demo] [--run] [--help]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE7_DIR="$PROJECT_ROOT/module7"
I2C_BASELINE_DIR="$MODULE7_DIR/examples/i2c_baseline"
RUN_LOG="$MODULE7_DIR/run.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
  echo ""
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${CYAN}========================================${NC}"
  echo ""
}

print_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
print_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
print_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }

show_usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Module 7: I²C — Protocol + RTL + basic testbench (no UVM).
Run checks, show demo commands, or run the i2c_baseline example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, example dirs)
  --demo      Print demo commands for i2c_baseline (no execution)
  --run       Run the i2c_baseline example; output teed to module7/run.log
  --help      Show this help

With no options, runs --check and then --run (skip --run if --check fails).
EOF
}

run_check() {
  print_header "Module 7: Environment self-check (I²C baseline)"
  local failed=0

  if command -v verilator &>/dev/null; then
    print_ok "verilator: $(verilator --version | head -n 1)"
  else
    print_fail "verilator not found in PATH"
    ((failed++)) || true
  fi

  if command -v make &>/dev/null; then
    print_ok "make: $(make --version | head -n 1)"
  else
    print_fail "make not found in PATH"
    ((failed++)) || true
  fi

  if command -v g++ &>/dev/null || command -v clang++ &>/dev/null; then
    print_ok "C++ compiler available (g++ or clang++)"
  else
    print_fail "No C++ compiler found (g++/clang++)"
    ((failed++)) || true
  fi

  if [[ -d "$MODULE7_DIR" ]]; then
    print_ok "module7 directory exists: $MODULE7_DIR"
  else
    print_fail "module7 directory missing: $MODULE7_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$I2C_BASELINE_DIR" ]]; then
    print_ok "i2c_baseline example directory exists: $I2C_BASELINE_DIR"
  else
    print_fail "i2c_baseline example directory missing: $I2C_BASELINE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$I2C_BASELINE_DIR/Makefile" ]]; then
    print_ok "i2c_baseline Makefile found"
  else
    print_fail "i2c_baseline Makefile missing in $I2C_BASELINE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$I2C_BASELINE_DIR/top_i2c_baseline.sv" ]]; then
    print_ok "i2c_baseline top found: top_i2c_baseline.sv"
  else
    print_fail "i2c_baseline top missing: $I2C_BASELINE_DIR/top_i2c_baseline.sv"
    ((failed++)) || true
  fi

  echo ""
  if [[ $failed -eq 0 ]]; then
    print_ok "All required checks for Module 7 passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 7: Demo commands (I²C baseline)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo ""
  echo "# 2) Run the I²C baseline example (basic TB, no UVM):"
  echo "cd module7/examples/i2c_baseline"
  echo "make run"
  echo ""
  print_info "See module7/EXAMPLES.md and module7/examples/i2c_baseline/README.md for more."
}

run_i2c_baseline() {
  print_header "Module 7: Run i2c_baseline example (logging to $RUN_LOG)"

  mkdir -p "$MODULE7_DIR"
  (
    cd "$I2C_BASELINE_DIR"
    echo "[$(date)] Running make run"
    if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
      make clean || true
    fi
    make run
  ) 2>&1 | tee "$RUN_LOG"

  echo ""
  if grep -q 'I2C baseline test PASS' "$RUN_LOG"; then
    print_ok "i2c_baseline completed. Log saved to: $RUN_LOG"
  else
    print_fail "i2c_baseline may have failed. Check: $RUN_LOG"
    return 1
  fi
}

# Main
if [[ $# -eq 0 ]]; then
  run_check && run_i2c_baseline
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      run_check
      ;;
    --demo)
      run_demo
      ;;
    --run)
      run_i2c_baseline
      ;;
    --help|-h)
      show_usage
      exit 0
      ;;
    *)
      print_fail "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
  shift
done
