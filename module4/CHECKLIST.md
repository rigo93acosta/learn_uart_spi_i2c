# Module 4 Checklist: UART UVM+SV Verification

Use this checklist to confirm you have completed the module.

## Prerequisites

- [ ] Module 1 completed (spec → RTL, spec_to_rtl).
- [ ] Module 2 completed (basic TB → UVM, uvm_smoke).
- [ ] Module 3 completed (UART protocol + RTL + basic testbench, uart_baseline).
- [ ] Verilator, Make, C++ compiler, UVM (UVM_HOME or vendored).

## UART UVM

- [ ] Can describe the UART UVM agent: transaction (byte to send), sequence (directed bytes), driver (start/data, wait for baud_tick), monitor (observe tx line, reconstruct byte), scoreboard (expected vs observed).
- [ ] Can explain loopback: TX output → RX input; scoreboard checks both TX (monitor) and RX (hook from DUT rx_valid/rx_data).

## Run

- [ ] Have run `module4/examples/uart_uvm` (`make SIM=verilator TEST=test_uart_uvm` or `./scripts/module4.sh --run`).
- [ ] Can interpret UVM output (DRIVER, MONITOR, SCOREBOARD, TX/RX matches).

## Next

- [ ] Ready for Module 5: SPI protocol + RTL + basic testbench.
