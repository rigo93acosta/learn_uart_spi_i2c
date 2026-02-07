# Module 8 Checklist: I²C UVM+SV Verification

Use this checklist to confirm you have completed the module.

## Prerequisites

- [ ] Module 1 completed (spec → RTL, spec_to_rtl).
- [ ] Module 2 completed (basic TB → UVM, uvm_smoke).
- [ ] Module 7 completed (I²C protocol + RTL + basic testbench, i2c_baseline).
- [ ] Verilator, Make, C++ compiler, UVM (UVM_HOME or vendored).

## I²C UVM

- [ ] Can describe the I²C UVM agent: transaction (addr + data), sequence (directed writes), driver (start/addr/data_in, wait for done), monitor (observe SCL/SDA, reconstruct addr+data), scoreboard (expected vs observed).
- [ ] Can explain how the monitor samples SDA on SCL rising edges to rebuild address and data bytes.

## Run

- [ ] Have run `module8/examples/i2c_uvm` (`make SIM=verilator TEST=test_i2c_uvm` or `./scripts/module8.sh --run`).
- [ ] Can interpret UVM output (DRIVER, MONITOR, SCOREBOARD, matches/mismatches).

## Next

- [ ] Can compare UVM structure across UART (Module 4), SPI (Module 6), and I²C (Module 8).
