# SPI UVM Example (Module 6)

SPI master RTL (same DUT as Module 5) with a **full UVM testbench**: transaction, sequence, driver, monitor, scoreboard. Directed sequence sends 0x00, 0x01, 0x55, 0xAA, 0xFF; monitor samples MOSI on SCLK (mode 0, MSB first); scoreboard checks expected vs observed.

## Layout

| File / Dir | Role |
|------------|------|
| **dut/** | spi_master.v, clk_div.v (same as module5/spi_baseline) |
| **test_spi_uvm.sv** | Interface, transaction, sequence, driver, monitor, scoreboard, agent, env, test, top module |
| **Makefile** | Verilator + UVM build and run |

## Prerequisites

- Verilator, Make, C++ compiler
- UVM (set `UVM_HOME` or use vendored UVM under `tools/`)

## Build and Run

```bash
# From this directory
make SIM=verilator TEST=test_spi_uvm
# or
make run
```

From repo root:

```bash
./scripts/module6.sh --run
```

## Success

You should see UVM phases, DRIVER/MONITOR/SCOREBOARD messages, and a scoreboard summary with 5 matches and 0 mismatches. The test passes when the sequence completes and the scoreboard agrees with the observed MOSI data.
