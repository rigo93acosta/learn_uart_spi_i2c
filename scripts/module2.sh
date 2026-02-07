#!/usr/bin/env bash
#
# Module 2: Design & Verification Methodology (Part 2) — UVM smoke demo and self-check
#
# Usage:
#   ./scripts/module2.sh [--check] [--demo] [--run] [--help]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE2_DIR="$PROJECT_ROOT/module2"
UVM_SMOKE_DIR="$MODULE2_DIR/examples/uvm_smoke"
RUN_LOG="$MODULE2_DIR/run.log"

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

Module 2: Design & Verification Methodology (Part 2) — basic TB → UVM+SV, toolchain.
Run checks, show demo commands, or run the uvm_smoke example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, UVM, example dirs)
  --demo      Print demo commands for uvm_smoke (no execution)
  --run       Run the uvm_smoke example; output teed to module2/run.log
  --help      Show this help

With no options, runs --check and then --run (skip --run if --check fails).
EOF
}

run_check() {
  print_header "Module 2: Environment self-check (UVM smoke)"
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

  if [[ -d "$MODULE2_DIR" ]]; then
    print_ok "module2 directory exists: $MODULE2_DIR"
  else
    print_fail "module2 directory missing: $MODULE2_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$UVM_SMOKE_DIR" ]]; then
    print_ok "uvm_smoke example directory exists: $UVM_SMOKE_DIR"
  else
    print_fail "uvm_smoke example directory missing: $UVM_SMOKE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$UVM_SMOKE_DIR/Makefile" ]]; then
    print_ok "uvm_smoke Makefile found"
  else
    print_fail "uvm_smoke Makefile missing in $UVM_SMOKE_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$UVM_SMOKE_DIR/test_uvm_smoke.sv" ]]; then
    print_ok "uvm_smoke testbench found: test_uvm_smoke.sv"
  else
    print_fail "uvm_smoke testbench missing: $UVM_SMOKE_DIR/test_uvm_smoke.sv"
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
    print_ok "All required checks for Module 2 passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 2: Demo commands (UVM smoke)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo "echo \"\$UVM_HOME\""
  echo ""
  echo "# 2) Run the uvm_smoke example (inside the example directory):"
  echo "cd module2/examples/uvm_smoke"
  echo "make SIM=verilator TEST=test_uvm_smoke"
  echo ""
  echo "# 3) Inspect logs and waveforms:"
  echo "ls obj_dir"
  echo "# If a VCD is produced:"
  echo "ls *.vcd"
  echo "# Then open in your waveform viewer, e.g.:"
  echo "gtkwave *.vcd  # if available"
  echo ""
  print_info "See module2/EXAMPLES.md and module2/examples/uvm_smoke/README.md for more."
}

run_uvm_smoke() {
  print_header "Module 2: Run uvm_smoke example (logging to $RUN_LOG)"

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

  mkdir -p "$MODULE2_DIR"
  (
    cd "$UVM_SMOKE_DIR"
    echo "[$(date)] Running make SIM=verilator TEST=test_uvm_smoke"
    if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
      make clean || true
    fi
    make SIM=verilator TEST=test_uvm_smoke
  ) 2>&1 | tee "$RUN_LOG"

  echo ""
  print_ok "uvm_smoke completed. Log saved to: $RUN_LOG"
}

# Main
if [[ $# -eq 0 ]]; then
  run_check && run_uvm_smoke
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
      run_uvm_smoke
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
