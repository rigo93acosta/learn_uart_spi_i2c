# Module 7 Checklist: I²C Protocol + RTL + Basic Testbench

Use this checklist to confirm you have completed the module.

## Prerequisites

- [ ] Modules 1–6 completed (methodology, UART baseline/UVM, SPI baseline/UVM).
- [ ] Verilator, Make, C++ compiler available.

## Protocol

- [ ] Can explain I²C signals (SCL, SDA) and that SDA is normally **open-drain** in real hardware.
- [ ] Can describe START (SDA falls while SCL high) and STOP (SDA rises while SCL high).
- [ ] Can describe 7-bit address + R/W bit, MSB-first byte transfer, and the ACK/NACK concept.

## RTL

- [ ] Can describe the role of `clk_div` (divider → `clk_div_tick` for SCL timing).
- [ ] Can describe the role of `i2c_master` (START → address+W → data → STOP; done pulse).
- [ ] Understand the simplifications in this teaching RTL (push-pull SCL/SDA, no ACK/NACK, no arbitration).

## Basic Testbench

- [ ] Have run `module7/examples/i2c_baseline` (`make run` or `./scripts/module7.sh --run`).
- [ ] Can explain how the monitor reconstructs bytes by sampling SDA on SCL rising edges.

## Next

- [ ] Ready for Module 8: I²C UVM+SV verification.

