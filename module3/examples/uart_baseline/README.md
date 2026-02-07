# UART Baseline Example (Module 3)

UART TX/RX RTL with a **basic directed testbench**: loopback (TX → RX), send bytes, check received data. No UVM.

## Contents

| Item | Description |
|------|-------------|
| `dut/uart_tx.v` | UART transmitter (8N1) |
| `dut/uart_rx.v` | UART receiver (8N1) |
| `dut/baud_gen.v` | Baud-rate generator (divider → baud_tick) |
| `top_uart_baseline.sv` | Top: loopback, baud_gen, uart_tx, uart_rx; directed test in initial block |
| `sim_main.cpp` | C++ harness: clock, reset; run until `$finish` |

## Run

From this directory:

```bash
make run
```

Expected: `[PASS] UART baseline: 0x55 loopback OK`, `[PASS] UART baseline: 0xAA loopback OK`, then `UART baseline test PASS`.

## Requirements

- Verilator (5.x)
- GNU Make
- C++ compiler

No UVM or `UVM_HOME` required.
