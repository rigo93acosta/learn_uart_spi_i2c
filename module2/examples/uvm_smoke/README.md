# Example: UVM smoke test on Verilator (`uvm_smoke/`)

**Goal**: Prove your environment can build and run a **self-contained** UVM test with Verilator.

This example intentionally keeps the DUT tiny (a simple register) so you can focus on the build/run/debug workflow and on the UVM structure: transaction → sequence → driver/monitor → scoreboard.

## Prerequisites

- Verilator 5.036+
- `UVM_HOME` set (must contain `src/uvm_pkg.sv`), or vendored UVM in the repo (see Makefile)
- `make` + a C++ compiler

## Layout

```
uvm_smoke/
├── Makefile
├── test_uvm_smoke.sv      # UVM testbench + top module
└── dut/
    └── simple_register.v  # Tiny DUT
```

## Try these

From the repo root:

```bash
cd module2/examples/uvm_smoke
make SIM=verilator TEST=test_uvm_smoke
```

If you want to clean artifacts:

```bash
make clean
```

## What to look for

- UVM output with `DRIVER`, `MONITOR`, and `SCOREBOARD` messages
- A final report summary showing **matches** and **mismatches**
- `obj_dir/` created by Verilator compilation
