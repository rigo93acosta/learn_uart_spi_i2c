#!/usr/bin/env bash
#
# Module 6: SPI UVM+SV — demo and self-check
#
# Usage:
#   ./scripts/module6.sh [--check] [--demo] [--run]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE6_DIR="$PROJECT_ROOT/module6"
SPI_UVM_EXAMPLE_DIR="$MODULE6_DIR/examples/spi_uvm"
RUN_LOG="$MODULE6_DIR/run.log"

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

Module 6: SPI UVM+SV — run checks, show demo commands, or run the SPI UVM example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, UVM, spi_uvm example dirs)
  --demo      Print demo commands for the SPI UVM example (no execution)
  --run       Run the SPI UVM example and tee output to module6/run.log
  --help      Show this help

With no options, runs --check and then --run.
EOF
}

run_check() {
  print_header "Module 6: Environment self-check (SPI UVM)"
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

  if [[ -d "$MODULE6_DIR" ]]; then
    print_ok "module6 directory exists: $MODULE6_DIR"
  else
    print_fail "module6 directory missing: $MODULE6_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$SPI_UVM_EXAMPLE_DIR" ]]; then
    print_ok "SPI UVM example directory exists: $SPI_UVM_EXAMPLE_DIR"
  else
    print_fail "SPI UVM example directory missing: $SPI_UVM_EXAMPLE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$SPI_UVM_EXAMPLE_DIR/Makefile" ]]; then
    print_ok "SPI UVM example Makefile found."
  else
    print_fail "SPI UVM example Makefile missing in $SPI_UVM_EXAMPLE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$SPI_UVM_EXAMPLE_DIR/test_spi_uvm.sv" ]]; then
    print_ok "SPI UVM testbench found: test_spi_uvm.sv"
  else
    print_fail "SPI UVM testbench missing: $SPI_UVM_EXAMPLE_DIR/test_spi_uvm.sv"
    ((failed++)) || true
  fi

  # UVM check: either UVM_HOME set or vendored UVM present
  local uvm_home="${UVM_HOME:-}"
  local vendored_uvm="$PROJECT_ROOT/tools/uvm-2017/1800.2-2017-1.0"
  local vendored_uvm_alt="$PROJECT_ROOT/tools/learn_uvm2017_sv_verilator/tools/uvm-2017/1800.2-2017-1.0"

  if [[ -n "$uvm_home" && -f "$uvm_home/src/uvm_pkg.sv" ]]; then
    print_ok "UVM_HOME set and uvm_pkg.sv found: $uvm_home"
  elif [[ -f "$vendored_uvm/src/uvm_pkg.sv" ]]; then
    print_info "UVM_HOME not set; vendored UVM found at: $vendored_uvm"
  elif [[ -f "$vendored_uvm_alt/src/uvm_pkg.sv" ]]; then
    print_info "UVM_HOME not set; vendored UVM found at: $vendored_uvm_alt"
  else
    print_fail "Neither UVM_HOME/src/uvm_pkg.sv nor vendored UVM found"
    ((failed++)) || true
  fi

  echo ""
  if [[ $failed -eq 0 ]]; then
    print_ok "All required checks for Module 6 passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 6: Demo commands (SPI UVM example)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo "echo \"\$UVM_HOME\""
  echo ""
  echo "# 2) Run the SPI UVM example (inside the example directory):"
  echo "cd module6/examples/spi_uvm"
  echo "make SIM=verilator TEST=test_spi_uvm"
  echo ""
  echo "# 3) Inspect logs and waveforms:"
  echo "ls obj_dir"
  echo "# If a VCD is produced:"
  echo "ls *.vcd"
  echo ""
  print_info "See module6/EXAMPLES.md and module6/examples/spi_uvm/README.md for more details."
}

run_spi_uvm() {
  print_header "Module 6: Run SPI UVM example (logging to $RUN_LOG)"

  # Set UVM_HOME if not already set
  if [[ -z "${UVM_HOME:-}" ]]; then
    local vendored_uvm="$PROJECT_ROOT/tools/uvm-2017/1800.2-2017-1.0"
    local vendored_uvm_alt="$PROJECT_ROOT/tools/learn_uvm2017_sv_verilator/tools/uvm-2017/1800.2-2017-1.0"
    if [[ -f "$vendored_uvm/src/uvm_pkg.sv" ]]; then
      export UVM_HOME="$vendored_uvm"
      print_info "Setting UVM_HOME to: $UVM_HOME"
    elif [[ -f "$vendored_uvm_alt/src/uvm_pkg.sv" ]]; then
      export UVM_HOME="$vendored_uvm_alt"
      print_info "Setting UVM_HOME to: $UVM_HOME"
    else
      print_fail "UVM_HOME not set and vendored UVM not found"
      return 1
    fi
  fi

  mkdir -p "$MODULE6_DIR"
  (
    cd "$SPI_UVM_EXAMPLE_DIR"
    echo "[$(date)] Running make SIM=verilator TEST=test_spi_uvm"
    if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
      make clean || true
    fi
    make SIM=verilator TEST=test_spi_uvm
  ) 2>&1 | tee "$RUN_LOG"

  if grep -q "Matches: 5.*Mismatches: 0\|SPI.*PASS\|UVM REPORT SUMMARY" "$RUN_LOG" 2>/dev/null; then
    echo ""
    print_ok "SPI UVM example completed. Log saved to: $RUN_LOG"
  else
    echo ""
    print_info "SPI UVM example run finished. Check $RUN_LOG for scoreboard and UVM summary."
  fi
}

# Main
if [[ $# -eq 0 ]]; then
  run_check
  run_spi_uvm
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
      run_spi_uvm
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
