# Module 5 Checklist: SPI Protocol + RTL + Basic Testbench

Use this checklist to confirm you have completed the module.

## Prerequisites

- [ ] Modules 1–4 completed (spec→RTL, UVM, UART baseline, UART UVM).
- [ ] Verilator, Make, C++ compiler available.

## Protocol

- [ ] Can describe SPI mode 0 (CPOL=0, CPHA=0): SCLK idle low; capture on rising edge; change on falling edge.
- [ ] Can list SPI signals: sclk, mosi, cs_n (and optionally miso); clk_div_tick for timing.

## RTL

- [ ] Can describe the role of `spi_master` (start, data_in; drive sclk, mosi, cs_n; MSB first; done pulse).
- [ ] Can describe the role of `clk_div` (divider → clk_div_tick for SCLK rate).

## Basic Testbench

- [ ] Have run `module5/examples/spi_baseline` (`make run` or `./scripts/module5.sh --run`).
- [ ] Can explain the directed test (start + data_in; wait for done; repeat for another byte).

## Next

- [ ] Ready for Module 6: SPI UVM+SV verification.
