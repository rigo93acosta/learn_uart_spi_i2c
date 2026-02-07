# Module 6 Checklist: SPI UVM+SV Verification

Use this checklist to confirm you have completed the module.

## Prerequisites

- [ ] Module 1 completed (spec → RTL, spec_to_rtl).
- [ ] Module 2 completed (basic TB → UVM, uvm_smoke).
- [ ] Module 5 completed (SPI protocol + RTL + basic testbench, spi_baseline).
- [ ] Verilator, Make, C++ compiler, UVM (UVM_HOME or vendored).

## SPI UVM

- [ ] Can describe the SPI UVM agent: transaction (byte to send), sequence (directed bytes), driver (start/data_in, wait for done), monitor (observe sclk/mosi/cs_n, reconstruct byte on MOSI), scoreboard (expected vs observed).
- [ ] Can explain SPI mode 0 timing: SCLK idle low; capture on rising edge; data change on falling edge; monitor samples MOSI on rising SCLK, MSB first.

## Run

- [ ] Have run `module6/examples/spi_uvm` (`make SIM=verilator TEST=test_spi_uvm` or `./scripts/module6.sh --run`).
- [ ] Can interpret UVM output (DRIVER, MONITOR, SCOREBOARD, matches/mismatches).

## Next

- [ ] Ready for Module 7: I²C protocol + RTL + basic testbench.
