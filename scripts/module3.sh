#!/usr/bin/env bash
#
# Module 3: UART — Protocol + RTL + Basic Testbench
#
# Usage:
#   ./scripts/module3.sh [--check] [--demo] [--run] [--help]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE3_DIR="$PROJECT_ROOT/module3"
UART_BASELINE_DIR="$MODULE3_DIR/examples/uart_baseline"
RUN_LOG="$MODULE3_DIR/run.log"

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

Module 3: UART — Protocol + RTL + basic testbench (no UVM).
Run checks, show demo commands, or run the uart_baseline example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, example dirs)
  --demo      Print demo commands for uart_baseline (no execution)
  --run       Run the uart_baseline example; output teed to module3/run.log
  --help      Show this help

With no options, runs --check and then --run (skip --run if --check fails).
EOF
}

run_check() {
  print_header "Module 3: Environment self-check (UART baseline)"
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

  if [[ -d "$MODULE3_DIR" ]]; then
    print_ok "module3 directory exists: $MODULE3_DIR"
  else
    print_fail "module3 directory missing: $MODULE3_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$UART_BASELINE_DIR" ]]; then
    print_ok "uart_baseline example directory exists: $UART_BASELINE_DIR"
  else
    print_fail "uart_baseline example directory missing: $UART_BASELINE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$UART_BASELINE_DIR/Makefile" ]]; then
    print_ok "uart_baseline Makefile found"
  else
    print_fail "uart_baseline Makefile missing in $UART_BASELINE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$UART_BASELINE_DIR/top_uart_baseline.sv" ]]; then
    print_ok "uart_baseline top found: top_uart_baseline.sv"
  else
    print_fail "uart_baseline top missing: $UART_BASELINE_DIR/top_uart_baseline.sv"
    ((failed++)) || true
  fi

  echo ""
  if [[ $failed -eq 0 ]]; then
    print_ok "All required checks for Module 3 passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 3: Demo commands (UART baseline)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo ""
  echo "# 2) Run the UART baseline example (loopback, basic TB, no UVM):"
  echo "cd module3/examples/uart_baseline"
  echo "make run"
  echo ""
  print_info "See module3/EXAMPLES.md and module3/examples/uart_baseline/README.md for more."
}

run_uart_baseline() {
  print_header "Module 3: Run uart_baseline example (logging to $RUN_LOG)"

  mkdir -p "$MODULE3_DIR"
  (
    cd "$UART_BASELINE_DIR"
    echo "[$(date)] Running make run"
    if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
      make clean || true
    fi
    make run
  ) 2>&1 | tee "$RUN_LOG"

  echo ""
  if grep -q 'UART baseline test PASS' "$RUN_LOG"; then
    print_ok "uart_baseline completed. Log saved to: $RUN_LOG"
  else
    print_fail "uart_baseline may have failed. Check: $RUN_LOG"
    return 1
  fi
}

# Main
if [[ $# -eq 0 ]]; then
  run_check && run_uart_baseline
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
      run_uart_baseline
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
