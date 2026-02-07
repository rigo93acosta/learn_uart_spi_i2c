#!/usr/bin/env bash
#
# Module 8: I²C UVM+SV — demo and self-check
#
# Usage:
#   ./scripts/module8.sh [--check] [--demo] [--run]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE8_DIR="$PROJECT_ROOT/module8"
I2C_UVM_EXAMPLE_DIR="$MODULE8_DIR/examples/i2c_uvm"
RUN_LOG="$MODULE8_DIR/run.log"

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

Module 8: I²C UVM+SV — run checks, show demo commands, or run the I²C UVM example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, UVM, i2c_uvm example dirs)
  --demo      Print demo commands for the I²C UVM example (no execution)
  --run       Run the I²C UVM example and tee output to module8/run.log
  --help      Show this help

With no options, runs --check and then --run.
EOF
}

run_check() {
  print_header "Module 8: Environment self-check (I²C UVM)"
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

  if [[ -d "$MODULE8_DIR" ]]; then
    print_ok "module8 directory exists: $MODULE8_DIR"
  else
    print_fail "module8 directory missing: $MODULE8_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$I2C_UVM_EXAMPLE_DIR" ]]; then
    print_ok "I²C UVM example directory exists: $I2C_UVM_EXAMPLE_DIR"
  else
    print_fail "I²C UVM example directory missing: $I2C_UVM_EXAMPLE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$I2C_UVM_EXAMPLE_DIR/Makefile" ]]; then
    print_ok "I²C UVM example Makefile found."
  else
    print_fail "I²C UVM example Makefile missing in $I2C_UVM_EXAMPLE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$I2C_UVM_EXAMPLE_DIR/test_i2c_uvm.sv" ]]; then
    print_ok "I²C UVM testbench found: test_i2c_uvm.sv"
  else
    print_fail "I²C UVM testbench missing: $I2C_UVM_EXAMPLE_DIR/test_i2c_uvm.sv"
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
    print_ok "All required checks for Module 8 passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 8: Demo commands (I²C UVM example)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo "echo \"\$UVM_HOME\""
  echo ""
  echo "# 2) Run the I²C UVM example (inside the example directory):"
  echo "cd module8/examples/i2c_uvm"
  echo "make SIM=verilator TEST=test_i2c_uvm"
  echo ""
  echo "# 3) Inspect logs and waveforms:"
  echo "ls obj_dir"
  echo "# If a VCD is produced:"
  echo "ls *.vcd"
  echo ""
  print_info "See module8/EXAMPLES.md and module8/examples/i2c_uvm/README.md for more details."
}

run_i2c_uvm() {
  print_header "Module 8: Run I²C UVM example (logging to $RUN_LOG)"

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

  mkdir -p "$MODULE8_DIR"
  (
    cd "$I2C_UVM_EXAMPLE_DIR"
    echo "[$(date)] Running make SIM=verilator TEST=test_i2c_uvm"
    if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
      make clean || true
    fi
    make SIM=verilator TEST=test_i2c_uvm
  ) 2>&1 | tee "$RUN_LOG"

  if grep -q "Matches: 2.*Mismatches: 0\|I2C.*PASS\|UVM REPORT SUMMARY" "$RUN_LOG" 2>/dev/null; then
    echo ""
    print_ok "I²C UVM example completed. Log saved to: $RUN_LOG"
  else
    echo ""
    print_info "I²C UVM example run finished. Check $RUN_LOG for scoreboard and UVM summary."
  fi
}

# Main
if [[ $# -eq 0 ]]; then
  run_check
  run_i2c_uvm
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
      run_i2c_uvm
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
