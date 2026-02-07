# SPI Baseline Example (Module 5)

SPI master RTL with a **basic directed testbench**: clk_div + spi_master; directed transfers (0x55, 0xAA); wait for done. No UVM.

## Contents

| Item | Description |
|------|-------------|
| `dut/spi_master.v` | SPI master (mode 0, 8-bit MSB first) |
| `dut/clk_div.v` | Clock divider (clk_div_tick for SCLK timing) |
| `top_spi_baseline.sv` | Top: clk_div, spi_master; directed test in initial block |
| `sim_main.cpp` | C++ harness: clock, reset; run until `$finish` |

## Run

From this directory:

```bash
make run
```

Expected: `[PASS] SPI baseline: 0x55 transfer done`, `[PASS] SPI baseline: 0xAA transfer done`, then `SPI baseline test PASS`.

## Requirements

- Verilator (5.x)
- GNU Make
- C++ compiler

No UVM or `UVM_HOME` required.
