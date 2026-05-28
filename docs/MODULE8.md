# Module 8: I²C — UVM+SV Verification

**Goal**: Extend I²C verification to **UVM+SV** — I²C agent (transaction, sequence, driver, monitor, scoreboard); run on Verilator.

---

## Navigation

[← Previous: Module 7: I²C](MODULE7.md) | [Next: (End of Series)](MODULE8.md)

[↑ Back to README](../README.md)

---

## Before You Start (Learning Path)

This module applies **UVM** to the I²C DUT. Before running commands:

1. **Read the detailed I²C learning guide**: [I2C_LEARNING_GUIDE.md](I2C_LEARNING_GUIDE.md) — what I²C is, how it works (START/STOP, address+R/W, data, timing), and how it maps to our RTL.
2. **Read the protocols + UVM overview**: [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) — **Part B § 5. How UVM Maps to a Protocol** and **§ 8. I²C UVM Mapping** (where UVM sits, how transaction/driver/monitor/scoreboard map to I²C).

Then follow **Overview** → **Topics Covered** → **Example** → **Exercises**.

---

## Running Module 8

- **Module doc**: [module8/README.md](../module8/README.md)
- **Example**: [module8/examples/i2c_uvm/](../module8/examples/i2c_uvm/) — I²C RTL + full UVM agent (same DUT as Module 7)

**Quick run** (from repo root):

```bash
cd module8/examples/i2c_uvm
make SIM=verilator TEST=test_i2c_uvm
```

Or: `./scripts/module8.sh --run`

- **Slides & video**: [slides.pptx](../media/module8/slides.pptx) · [slides.pdf](../media/module8/slides.pdf) · [video.mp4](../media/module8/video.mp4) — regenerate: `./scripts/build_all_media.sh --module 8`

---

## Overview

Module 8 builds on Module 7 (I²C protocol + RTL + basic testbench):

- **Same DUT**: i2c_master, clk_div (reused from module7/examples/i2c_baseline).
- **UVM testbench**: I²C agent — transaction (addr + data), sequence (directed writes), driver (start/addr/data_in, wait for done), monitor (observe SCL/SDA and reconstruct bytes), scoreboard (expected vs observed).
- **Toolchain**: Verilator + UVM_HOME + Make (same pattern as Module 6, SPI UVM).

### What You'll Learn

- **I²C UVM agent**: I2cTransaction, I2cSequence, I2cDriver, I2cMonitor, I2cScoreboard.
- **Interface**: i2c_if (clk, rst_n, start, addr, data_in, scl, sda, clk_div_tick, busy, done) connects UVM to DUT.
- How to hook up a UVM monitor and scoreboard to a bus-oriented DUT.

### Prerequisites

- Module 7 (I²C protocol + RTL + basic TB).
- Verilator, Make, C++ compiler, **UVM** (UVM_HOME or vendored UVM).

---

## Topics Covered

### 1. I²C UVM Agent

- **Transaction** (I2cTransaction): address and data to write; monitor fills observed_addr/observed_data.
- **Sequence** (I2cSequence): produces directed transactions (e.g. same addr, different data bytes).
- **Driver** (I2cDriver): gets transaction, drives start/addr/data_in for one cycle, waits for done.
- **Monitor** (I2cMonitor): watches SCL/SDA; after START, samples SDA on rising SCL to reconstruct 8 bits of address+W and 8 bits of data.
- **Scoreboard** (I2cScoreboard): compares expected (from test) vs observed_addr/observed_data.

### 2. Toolchain

- Same as Module 6 (SPI UVM): Verilator with -sv, --timing, --trace, UVM include paths, `make SIM=verilator TEST=test_i2c_uvm`. Run with `+UVM_TESTNAME=test_i2c_uvm`.

---

## Example: i2c_uvm

| Component | Role |
|-----------|------|
| **dut/** | i2c_master.v, clk_div.v (same as Module 7) |
| **test_i2c_uvm.sv** | Interface, I2cTransaction, I2cSequence, I2cDriver, I2cMonitor, I2cScoreboard, I2cAgent, I2cEnv, test_i2c_uvm top module |

Run: `cd module8/examples/i2c_uvm && make SIM=verilator TEST=test_i2c_uvm`

---

## Where UVM Applies (Recap)

UVM is used **only in the testbench** around the I²C DUT. The **transaction** is (address, data); the **driver** drives start/addr/data_in and waits for done; the **monitor** observes SCL/SDA, reconstructs address+data (sample SDA on rising SCL), and sends to the **scoreboard**. See [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md § 8](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md#8-i2c-uvm-mapping-module-8) for the full mapping.

---

## Exercises

1. **Run i2c_uvm**
   - Run `make SIM=verilator TEST=test_i2c_uvm` in `module8/examples/i2c_uvm`. Confirm UVM phases, DRIVER/MONITOR/SCOREBOARD messages, and scoreboard pass.

2. **Trace one transaction**
   - For one (addr, data) transaction, trace: sequence → driver (start, addr, data_in, wait for done) → DUT generates START/addr/data/STOP → monitor samples SDA on rising SCL → scoreboard compares expected vs observed addr and data.

3. **Change the sequence**
   - Add or change an (addr, data) pair in the I²C sequence and update expected values in the test/scoreboard. Re-run and confirm pass.

4. **Compare across protocols**
   - Compare UART (Module 4), SPI (Module 6), and I²C (Module 8) UVM agents: same UVM pattern (transaction, sequence, driver, monitor, scoreboard), different protocol units (byte vs byte vs addr+data) and bus signals.

---

## Assessment

- [ ] Can describe the I²C UVM agent and how it maps to I²C (addr+data, monitor on SCL/SDA).
- [ ] Can run i2c_uvm and interpret UVM output.
- [ ] Can compare UVM structure across UART, SPI, and I²C.

---

## Next Steps

This completes the 8-module series. You can now compare methodology and UVM patterns across UART, SPI, and I²C.
