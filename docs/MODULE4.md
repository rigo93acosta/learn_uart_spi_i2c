# Module 4: UART — UVM+SV Verification

**Goal**: Extend UART verification to **UVM+SV** — UART agent (transaction, sequence, driver, monitor, scoreboard); run on Verilator.

---

## Navigation

[← Previous: Module 3: UART →](MODULE3.md) | [Next: Module 5: SPI →](MODULE5.md)

[↑ Back to README](../README.md)

---

## Before You Start (Learning Path)

This module applies **UVM** to the UART DUT. Before running commands:

1. **Read the detailed UART learning guide**: [UART_LEARNING_GUIDE.md](UART_LEARNING_GUIDE.md) — what UART is, how it works (frame, baud, TX/RX), and how it maps to our RTL.
2. **Read the protocols + UVM overview**: [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) — **Part B § 5. How UVM Maps to a Protocol** and **§ 6. UART UVM Mapping** (where UVM sits, how transaction/driver/monitor/scoreboard map to UART).

Then follow **Overview** → **Topics Covered** → **Example** → **Exercises**.

---

## Running Module 4

- **Module doc**: [module4/README.md](../module4/README.md)
- **Example**: [module4/examples/uart_uvm/](../module4/examples/uart_uvm/) — UART RTL + full UVM agent (same DUT as Module 3)

**Quick run** (from repo root):

```bash
cd module4/examples/uart_uvm
make SIM=verilator TEST=test_uart_uvm
```

Or: `./scripts/module4.sh --run`

- **Slides & video**: [slides.pptx](../media/module4/slides.pptx) · [slides.pdf](../media/module4/slides.pdf) · [video.mp4](../media/module4/video.mp4) — regenerate: `./scripts/build_all_media.sh --module 4`

---

## Overview

Module 4 builds on Module 3 (UART protocol + RTL + basic testbench):

- **Same DUT**: uart_tx, uart_rx, baud_gen (reused from module3/examples/uart_baseline).
- **UVM testbench**: UART agent — transaction (byte to send), sequence (directed bytes: 0x00, 0x01, 0x55, 0xAA, 0xFF), driver (start/data, wait for baud_tick), monitor (observe tx line, reconstruct byte), scoreboard (expected vs observed).
- **Loopback**: TX output → RX input; scoreboard checks both TX (monitor observes serial line) and RX (hook from DUT rx_valid/rx_data).
- **Toolchain**: Verilator + UVM_HOME + Make (same as Module 2).

### What You'll Learn

- **UART UVM agent**: Transaction (UartTxTransaction), sequence (UartTxSequence), driver (UartTxDriver), monitor (UartTxMonitor), scoreboard (UartTxScoreboard).
- **Interface**: uart_tx_if (clk, rst_n, start, data, tx, baud_tick) connects UVM to DUT.
- **Loopback check**: TX path (driver → DUT → monitor → scoreboard) and RX path (DUT rx_valid/rx_data → scoreboard.check_rx_byte).

### Prerequisites

- Module 1 (spec → RTL), Module 2 (UVM+SV, uvm_smoke), Module 3 (UART protocol + RTL + basic TB).
- Verilator, Make, C++ compiler, **UVM** (UVM_HOME or vendored UVM).

---

## Topics Covered

### 1. UART UVM Agent

- **Transaction** (UartTxTransaction): byte to send (data); monitor fills observed_tx (reconstructed from serial line).
- **Sequence** (UartTxSequence): produces directed transactions (0x00, 0x01, 0x55, 0xAA, 0xFF).
- **Driver** (UartTxDriver): gets transaction, drives start and data for one cycle, waits 10 baud_ticks (one frame).
- **Monitor** (UartTxMonitor): watches tx line for start bit, samples 8 data bits per baud_tick, writes transaction to scoreboard.
- **Scoreboard** (UartTxScoreboard): compares expected (from test) vs observed_tx (from monitor); also check_rx_byte for loopback RX.

### 2. Loopback and RX Check

- **Loopback**: TX output (vif.tx) is connected to RX input (dut_rx.rx). Bytes sent by driver are received by uart_rx.
- **RX hook**: An initial block in the top looks up the scoreboard and calls check_rx_byte(rx_data) when rx_valid is high, so both TX path (monitor) and RX path (loopback) are checked.

### 3. Toolchain

- Same as Module 2: Verilator with -sv, --timing, --trace, UVM include paths, make SIM=verilator TEST=test_uart_uvm. Run with +UVM_TESTNAME=UartTxTest.

---

## Example: uart_uvm

| Component | Role |
|-----------|------|
| **dut/** | uart_tx.v, uart_rx.v, baud_gen.v (same as Module 3) |
| **test_uart_uvm.sv** | Interface, UartTxTransaction, UartTxSequence, UartTxDriver, UartTxMonitor, UartTxScoreboard, UartTxAgent, UartTxEnv, UartTxTest; top with DUT, loopback, baud_gen, clock/reset, RX scoreboard hook |

Run: `cd module4/examples/uart_uvm && make SIM=verilator TEST=test_uart_uvm`

---

## Command Reference

```bash
cd module4/examples/uart_uvm
make SIM=verilator TEST=test_uart_uvm
```

```bash
./scripts/module4.sh --check   # Environment + UVM + example dirs
./scripts/module4.sh --run     # Run uart_uvm
```

---

## Learning Outcomes

- Describe the UART UVM agent (transaction, sequence, driver, monitor, scoreboard).
- Explain loopback (TX→RX) and how TX and RX are both checked in the scoreboard.
- Run the uart_uvm example and interpret UVM output.
- Ready for Module 5: SPI protocol + RTL + basic testbench.

---

## Where UVM Applies (Recap)

UVM is used **only in the testbench**: it does not replace the UART RTL. The **transaction** represents one byte; the **driver** drives the DUT interface per UART timing (start, data, wait for frame); the **monitor** observes the serial line and reconstructs bytes; the **scoreboard** compares expected vs observed. See [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md § 6](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md#6-uart-uvm-mapping-module-4) for the full mapping.

---

## Exercises

1. **Run uart_uvm**
   - Run `make SIM=verilator TEST=test_uart_uvm` in `module4/examples/uart_uvm`. Confirm UVM phases, DRIVER/MONITOR/SCOREBOARD messages, and scoreboard pass (e.g. matches, no mismatches).

2. **Trace one transaction**
   - Open the test and agent sources. For one transaction (e.g. 0x55), trace: sequence creates transaction → driver drives start/data → DUT TX sends frame → monitor observes tx line and reconstructs byte → scoreboard compares expected vs observed. Map each step to the corresponding UVM class/method.

3. **Change the sequence**
   - Add or change one value in the UART sequence (e.g. add 0x11). Update the expected values in the test/scoreboard to match. Re-run and confirm the scoreboard still passes.

4. **Optional: Loopback path**
   - Identify where the RX path is checked (e.g. rx_valid/rx_data hook to scoreboard). Explain how both TX (monitor on serial line) and RX (loopback) are verified.

---

## Assessment

- [ ] Can describe the UART UVM agent: transaction (one byte), sequence, driver, monitor, scoreboard.
- [ ] Can explain loopback and how TX and RX are both checked.
- [ ] Can run uart_uvm and interpret UVM output (phases, scoreboard summary).
- [ ] Ready for Module 5: SPI protocol + RTL + basic testbench.

---

## Next Steps

After completing this module, proceed to **Module 5: SPI** — SPI protocol details, RTL (master, mode 0), and basic (non-UVM) testbench.
