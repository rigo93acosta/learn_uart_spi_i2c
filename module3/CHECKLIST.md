# Module 3 Checklist: UART Protocol + RTL + Basic Testbench

Use this checklist to confirm you have completed the module.

## Prerequisites

- [ ] Module 1 completed (spec → RTL flow, spec_to_rtl run).
- [ ] Module 2 completed (basic TB → UVM+SV, uvm_smoke run).
- [ ] Verilator, Make, and C++ compiler available.

## Protocol

- [ ] Can describe 8N1 UART frame (start bit, 8 data bits LSB first, stop bit).
- [ ] Can explain baud rate and the role of a baud generator (divider → baud_tick).

## RTL

- [ ] Can describe the role of `uart_tx` (parallel → serial, start/data/stop).
- [ ] Can describe the role of `uart_rx` (serial → parallel, start detect, sample, data_valid).
- [ ] Can describe the role of `baud_gen` (clock divider, baud_tick pulse).

## Basic Testbench

- [ ] Have run `module3/examples/uart_baseline` (`make run` or `./scripts/module3.sh --run`).
- [ ] Can explain the loopback test (TX → RX) and what the directed test checks.

## Next

- [ ] Ready for Module 4: UART UVM+SV verification.
