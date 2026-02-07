# UART UVM Example (Module 4)

UART TX/RX RTL (same DUT as Module 3) with a **full UVM testbench**: UART agent (transaction, sequence, driver, monitor, scoreboard); loopback TX→RX; directed sequence (0x00, 0x01, 0x55, 0xAA, 0xFF).

## Prerequisites

- Verilator 5.036+
- UVM_HOME set (must contain `src/uvm_pkg.sv`) or vendored UVM in repo (see Makefile)
- make + C++ compiler

## Layout

```
uart_uvm/
├── Makefile
├── test_uart_uvm.sv   # UVM testbench + top (interface, agent, DUT, loopback)
└── dut/
    ├── uart_tx.v
    ├── uart_rx.v
    └── baud_gen.v
```

## Run

From this directory:

```bash
make SIM=verilator TEST=test_uart_uvm
```

Or from repo root: `./scripts/module4.sh --run`

## What to look for

- UVM phases and DRIVER, MONITOR, SCOREBOARD messages
- TX and RX scoreboard checks (TX: monitor observes serial line; RX: hook from DUT rx_valid/rx_data)
- Final scoreboard summary: TX Matches, TX Mismatches, RX Matches, RX Mismatches
