# I2C UVM Example (Module 8)

I2C master RTL (same DUT as Module 7) with a **full UVM testbench**: transaction, sequence, driver, monitor, scoreboard. Directed sequence sends a few (addr, data) writes; monitor reconstructs address+data from SDA/SCL; scoreboard checks expected vs observed.

## Layout

| File / Dir | Role |
|------------|------|
| **dut/** | i2c_master.v, clk_div.v (same as module7/i2c_baseline) |
| **test_i2c_uvm.sv** | Interface, transaction, sequence, driver, monitor, scoreboard, agent, env, test, top module |
| **Makefile** | Verilator + UVM build and run |

## Prerequisites

- Verilator, Make, C++ compiler
- UVM (set `UVM_HOME` or use vendored UVM under `tools/`)

## Build and Run

```bash
# From this directory
make SIM=verilator TEST=test_i2c_uvm
# or
make run
```

From repo root:

```bash
./scripts/module8.sh --run
```

## Success

You should see UVM phases, DRIVER/MONITOR/SCOREBOARD messages, and a scoreboard summary with all writes matching. The test passes when the sequence completes and the scoreboard agrees with the reconstructed bus traffic.
