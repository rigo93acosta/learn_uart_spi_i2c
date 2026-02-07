# Module 6: SPI — UVM+SV Verification

**Goal**: Extend SPI verification to **UVM+SV** — SPI agent (transaction, sequence, driver, monitor, scoreboard); run on Verilator.

---

## Navigation

[← Previous: Module 5: SPI →](MODULE5.md) | [Next: Module 7: I²C →](MODULE7.md)

[↑ Back to README](../README.md)

---

## Before You Start (Learning Path)

This module applies **UVM** to the SPI DUT. Before running commands:

1. **Read the detailed SPI learning guide**: [SPI_LEARNING_GUIDE.md](SPI_LEARNING_GUIDE.md) — what SPI is, how it works (signals, Mode 0, timing), and how it maps to our RTL.
2. **Read the protocols + UVM overview**: [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) — **Part B § 5. How UVM Maps to a Protocol** and **§ 7. SPI UVM Mapping** (where UVM sits, how transaction/driver/monitor/scoreboard map to SPI).

Then follow **Overview** → **Topics Covered** → **Example** → **Exercises**.

---

## Running Module 6

- **Module doc**: [module6/README.md](../module6/README.md)
- **Example**: [module6/examples/spi_uvm/](../module6/examples/spi_uvm/) — SPI RTL + full UVM agent (same DUT as Module 5)

**Quick run** (from repo root):

```bash
cd module6/examples/spi_uvm
make SIM=verilator TEST=test_spi_uvm
```

Or: `./scripts/module6.sh --run`

---

## Overview

Module 6 builds on Module 5 (SPI protocol + RTL + basic testbench):

- **Same DUT**: spi_master, clk_div (reused from module5/examples/spi_baseline).
- **UVM testbench**: SPI agent — transaction (byte to send), sequence (directed bytes: 0x00, 0x01, 0x55, 0xAA, 0xFF), driver (start/data_in, wait for done), monitor (observe sclk/mosi/cs_n, sample MOSI on rising SCLK, MSB first), scoreboard (expected vs observed).
- **Toolchain**: Verilator + UVM_HOME + Make (same as Module 2).

### What You'll Learn

- **SPI UVM agent**: Transaction (SpiTransaction), sequence (SpiSequence), driver (SpiDriver), monitor (SpiMonitor), scoreboard (SpiScoreboard).
- **Interface**: spi_master_if (clk, rst_n, clk_div_tick, start, data_in, sclk, mosi, cs_n, busy, done) connects UVM to DUT.
- **Mode 0 monitoring**: SCLK idle low; capture on rising edge; monitor samples MOSI on each rising SCLK, MSB first, to reconstruct the byte.

### Prerequisites

- Module 1 (spec → RTL), Module 2 (UVM+SV, uvm_smoke), Module 5 (SPI protocol + RTL + basic TB).
- Verilator, Make, C++ compiler, **UVM** (UVM_HOME or vendored UVM).

---

## Topics Covered

### 1. SPI UVM Agent

- **Transaction** (SpiTransaction): byte to send (data); monitor fills observed_mosi (reconstructed from MOSI on SCLK).
- **Sequence** (SpiSequence): produces directed transactions (0x00, 0x01, 0x55, 0xAA, 0xFF).
- **Driver** (SpiDriver): gets transaction, drives start and data_in for one cycle, waits for done.
- **Monitor** (SpiMonitor): watches cs_n; when cs_n goes low, samples MOSI on each rising edge of SCLK (mode 0, MSB first), writes transaction to scoreboard.
- **Scoreboard** (SpiScoreboard): compares expected (from test) vs observed_mosi (from monitor).

### 2. Mode 0 Timing

- **SPI mode 0**: SCLK idles low; data captured on rising edge; data changed on falling edge.
- **Monitor**: Waits for cs_n low, then on 8 rising edges of SCLK captures MOSI into bits [7:0] (MSB first).

### 3. Toolchain

- Same as Module 2: Verilator with -sv, --timing, --trace, UVM include paths, make SIM=verilator TEST=test_spi_uvm. Run with +UVM_TESTNAME=SpiTest.

---

## Example: spi_uvm

| Component | Role |
|-----------|------|
| **dut/** | spi_master.v, clk_div.v (same as Module 5) |
| **test_spi_uvm.sv** | Interface, SpiTransaction, SpiSequence, SpiDriver, SpiMonitor, SpiScoreboard, SpiAgent, SpiEnv, SpiTest; top with clk_div, spi_master, clock/reset |

Run: `cd module6/examples/spi_uvm && make SIM=verilator TEST=test_spi_uvm`

---

## Command Reference

```bash
cd module6/examples/spi_uvm
make SIM=verilator TEST=test_spi_uvm
```

Or from repo root: `./scripts/module6.sh --check` then `./scripts/module6.sh --run`.

---

## Where UVM Applies (Recap)

UVM is used **only in the testbench** around the SPI DUT. The **transaction** is one byte; the **driver** drives start/data_in and waits for done; the **monitor** samples MOSI on rising SCLK (mode 0, MSB first) and sends the reconstructed byte to the **scoreboard**. See [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md § 7](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md#7-spi-uvm-mapping-module-6) for the full mapping.

---

## Learning Outcomes

- Describe the SPI UVM agent (transaction, sequence, driver, monitor, scoreboard) and mode 0 monitoring.
- Run spi_uvm and interpret UVM output.
- Ready for Module 7: I²C protocol + RTL + basic testbench.

---

## Exercises

1. **Run spi_uvm**
   - Run `make SIM=verilator TEST=test_spi_uvm` in `module6/examples/spi_uvm`. Confirm UVM phases, DRIVER/MONITOR/SCOREBOARD messages, and scoreboard pass.

2. **Trace one transaction**
   - For one transaction (e.g. 0x55), trace: sequence → driver (start, data_in, wait for done) → DUT drives SCLK/MOSI/CS_N → monitor samples MOSI on rising SCLK → scoreboard compares. Map to the corresponding UVM classes.

3. **Change the sequence**
   - Add or change a value in the SPI sequence and update the test/scoreboard expected values. Re-run and confirm pass.

4. **Optional: Compare to UART UVM**
   - Compare the structure of the SPI agent to the UART agent (Module 4): same pattern (transaction, sequence, driver, monitor, scoreboard), different protocol timing.

---

## Assessment

- [ ] Can describe the SPI UVM agent and how it maps to SPI (one byte, mode 0 monitoring).
- [ ] Can run spi_uvm and interpret UVM output.
- [ ] Ready for Module 7: I²C protocol + RTL + basic testbench.

---

## Next Steps

After Module 6, proceed to **Module 7: I²C** — protocol + RTL + basic testbench.
