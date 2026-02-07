#!/usr/bin/env bash
#
# Module 1: Design & Verification Methodology (Part 1) — spec → RTL demo and self-check
#
# Usage:
#   ./scripts/module1.sh [--check] [--demo] [--run] [--trace] [--help]
#
# No UVM required for this module.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE1_DIR="$PROJECT_ROOT/module1"
SPEC_TO_RTL_DIR="$MODULE1_DIR/examples/spec_to_rtl"
RUN_LOG="$MODULE1_DIR/run.log"

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

Module 1: Design & Verification Methodology (Part 1) — spec → RTL flow.
Run checks, show demo commands, or run the spec_to_rtl example.

Options:
  --check     Run environment self-check (verilator, make, C++ compiler, example dirs)
  --demo      Print demo commands for spec_to_rtl (no execution)
  --run       Run the spec_to_rtl example; output teed to module1/run.log
  --trace     Run spec_to_rtl with VCD tracing (make run TRACE=1)
  --help      Show this help

With no options, runs --check and then --run (skip --run if --check fails).
EOF
}

run_check() {
  print_header "Module 1: Environment self-check"
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

  if [[ -d "$MODULE1_DIR" ]]; then
    print_ok "module1 directory exists: $MODULE1_DIR"
  else
    print_fail "module1 directory missing: $MODULE1_DIR"
    ((failed++)) || true
  fi

  if [[ -d "$SPEC_TO_RTL_DIR" ]]; then
    print_ok "spec_to_rtl example directory exists: $SPEC_TO_RTL_DIR"
  else
    print_fail "spec_to_rtl example directory missing: $SPEC_TO_RTL_DIR"
    ((failed++)) || true
  fi

  if [[ -f "$SPEC_TO_RTL_DIR/Makefile" ]]; then
    print_ok "spec_to_rtl Makefile found"
  else
    print_fail "spec_to_rtl Makefile missing in $SPEC_TO_RTL_DIR"
    ((failed++)) || true
  fi

  echo ""
  if [[ $failed -eq 0 ]]; then
    print_ok "All required checks passed."
  else
    print_fail "$failed check(s) failed."
    return 1
  fi
}

run_demo() {
  print_header "Module 1: Demo commands (copy-paste to try)"
  echo "From repo root:"
  echo ""
  echo "# 1) Environment sanity:"
  echo "verilator --version"
  echo "make --version"
  echo ""
  echo "# 2) Run the spec_to_rtl example (spec → RTL → simulation):"
  echo "cd module1/examples/spec_to_rtl"
  echo "make run"
  echo ""
  echo "# 3) Optional: with VCD tracing:"
  echo "make run TRACE=1"
  echo "# Then open spec_to_rtl.vcd in a waveform viewer (e.g. gtkwave)."
  echo ""
  print_info "See module1/EXAMPLES.md for more."
}

run_spec_to_rtl() {
  local with_trace="${1:-false}"
  if [[ "$with_trace" == "true" ]]; then
    print_header "Module 1: Run spec_to_rtl example with VCD trace (logging to $RUN_LOG)"
  else
    print_header "Module 1: Run spec_to_rtl example (logging to $RUN_LOG)"
  fi

  mkdir -p "$MODULE1_DIR"
  (
    cd "$SPEC_TO_RTL_DIR"
    if [[ "$with_trace" == "true" ]]; then
      echo "[$(date)] Running make run TRACE=1"
      if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
        make clean || true
      fi
      make run TRACE=1
    else
      echo "[$(date)] Running make run"
      if [[ "${CLEAN_BUILDS:-false}" == "true" ]]; then
        make clean || true
      fi
      make run
    fi
  ) 2>&1 | tee "$RUN_LOG"

  echo ""
  if grep -q '\[PASS\]' "$RUN_LOG"; then
    print_ok "spec_to_rtl completed. Log saved to: $RUN_LOG"
    if [[ "$with_trace" == "true" ]]; then
      print_info "VCD file: $SPEC_TO_RTL_DIR/spec_to_rtl.vcd"
    fi
  else
    print_fail "spec_to_rtl may have failed. Check: $RUN_LOG"
    return 1
  fi
}

# Main
if [[ $# -eq 0 ]]; then
  run_check && run_spec_to_rtl "false"
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
      run_spec_to_rtl "false"
      ;;
    --trace)
      run_spec_to_rtl "true"
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
