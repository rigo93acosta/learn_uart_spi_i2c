#!/usr/bin/env bash
#
# Module 5: SPI — Protocol + RTL + Basic Testbench
#
# Usage:
#   ./scripts/module5.sh [--check] [--demo] [--run] [--help]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE5_DIR="$PROJECT_ROOT/module5"
SPI_BASELINE_DIR="$MODULE5_DIR/examples/spi_baseline"
RUN_LOG="$MODULE5_DIR/run.log"

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

Module 5: SPI — Protocol + RTL + basic testbench (no UVM).
Run checks, show demo commands, or run the spi_baseline example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, example dirs)
  --demo      Print demo commands for spi_baseline (no execution)
  --run       Run the spi_baseline example; output teed to module5/run.log
  --help      Show this help

With no options, runs --check and then --run (skip --run if --check fails).
EOF
}

run_check() {
  print_header "Module 5: Environment self-check (SPI baseline)"
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

  if [[ -d "$MODULE5_DIR" ]]; then
    print_ok "module5 directory exists: $MODULE5_DIR"
  else
    print_fail "module5 directory missing: $MODULE5_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$SPI_BASELINE_DIR" ]]; then
    print_ok "spi_baseline example directory exists: $SPI_BASELINE_DIR"
  else
    print_fail "spi_baseline example directory missing: $SPI_BASELINE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$SPI_BASELINE_DIR/Makefile" ]]; then
    print_ok "spi_baseline Makefile found"
  else
    print_fail "spi_baseline Makefile missing in $SPI_BASELINE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$SPI_BASELINE_DIR/top_spi_baseline.sv" ]]; then
    print_ok "spi_baseline top found: top_spi_baseline.sv"
  else
    print_fail "spi_baseline top missing: $SPI_BASELINE_DIR/top_spi_baseline.sv"
    ((failed++)) || true
  fi

  echo ""
  if [[ $failed -eq 0 ]]; then
    print_ok "All required checks for Module 5 passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 5: Demo commands (SPI baseline)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo ""
  echo "# 2) Run the SPI baseline example (basic TB, no UVM):"
  echo "cd module5/examples/spi_baseline"
  echo "make run"
  echo ""
  print_info "See module5/EXAMPLES.md and module5/examples/spi_baseline/README.md for more."
}

run_spi_baseline() {
  print_header "Module 5: Run spi_baseline example (logging to $RUN_LOG)"

  mkdir -p "$MODULE5_DIR"
  (
    cd "$SPI_BASELINE_DIR"
    echo "[$(date)] Running make run"
    if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
      make clean || true
    fi
    make run
  ) 2>&1 | tee "$RUN_LOG"

  echo ""
  if grep -q 'SPI baseline test PASS' "$RUN_LOG"; then
    print_ok "spi_baseline completed. Log saved to: $RUN_LOG"
  else
    print_fail "spi_baseline may have failed. Check: $RUN_LOG"
    return 1
  fi
}

# Main
if [[ $# -eq 0 ]]; then
  run_check && run_spi_baseline
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
      run_spi_baseline
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
