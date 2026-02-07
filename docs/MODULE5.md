# Module 5: SPI — Protocol + RTL + Basic Testbench

**Goal**: Understand the SPI protocol (mode 0, signals), translate it to RTL (SPI master, clk_div), and verify with a **basic** (non-UVM) directed testbench.

---

## Navigation

[← Previous: Module 4: UART UVM+SV](MODULE4.md) | [Next: Module 6: SPI UVM+SV →](MODULE6.md)

[↑ Back to README](../README.md)

---

## Before You Start (Learning Path)

Before running commands:

1. **Read the detailed SPI learning guide**: [SPI_LEARNING_GUIDE.md](SPI_LEARNING_GUIDE.md) — what SPI is, what kind of protocol (serial, synchronous, master–slave), how it works (signals, modes CPOL/CPHA, Mode 0, timing), and where it’s used.
2. **Read the protocols + UVM overview**: [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) — **Part B § 4. When to Use Baseline vs UVM** (why we start with a baseline test before SPI UVM in Module 6).

Then follow **Overview** → **Topics Covered** → **Example** → **Exercises**.

---

## Running Module 5

- **Module doc**: [module5/README.md](../module5/README.md)
- **Example**: [module5/examples/spi_baseline/](../module5/examples/spi_baseline/) — SPI master RTL + basic directed test (no UVM)

**Quick run** (from repo root):

```bash
cd module5/examples/spi_baseline
make run
```

Or: `./scripts/module5.sh --run`

---

## Overview

Module 5 is the second **protocol** module (after UART):

- **SPI protocol**: Mode 0 (CPOL=0, CPHA=0); SCLK, MOSI, CS_N; 8-bit transfers MSB first.
- **RTL**: `spi_master`, `clk_div` — master drives SCLK/MOSI/CS_N; divider produces clk_div_tick.
- **Basic testbench**: Directed test (start, data_in; wait for done). **No UVM** — UVM for SPI is Module 6.

### What You'll Learn

- **SPI mode 0**: SCLK idle low; capture on rising edge; change on falling edge; CS_N active low for frame.
- **Signals**: sclk, mosi, cs_n; clk_div_tick for timing (no MISO in this baseline).
- **RTL architecture**: spi_master (start, data_in → sclk, mosi, cs_n, done); clk_div (divider → clk_div_tick).
- **Basic TB**: Directed transfers (e.g. 0x55, 0xAA); wait for done; no UVM.

### Prerequisites

- Modules 1–4 (spec→RTL, UVM, UART baseline, UART UVM).
- Verilator, Make, C++ compiler. **No UVM required** for spi_baseline.

---

## Topics Covered

### 1. SPI Protocol (Mode 0)

- **Signals**: sclk (serial clock), mosi (master out, slave in), cs_n (active-low chip select). Optional: miso (not used in this baseline).
- **Mode 0 (CPOL=0, CPHA=0)**: SCLK idles low; data captured on rising edge; data changed on falling edge.
- **Timing**: One bit per clk_div_tick; clk_div_tick derived from system clock via divider (e.g. DIVIDER=8).

### 2. RTL Architecture

- **clk_div**: Divides clk; outputs clk_div_tick one cycle every DIVIDER cycles.
- **spi_master**: On start, loads data_in into shift register; asserts cs_n low; toggles sclk on clk_div_tick; outputs one bit per half-cycle (MSB first); pulses done when frame complete.

### 3. Basic Testbench

- **Directed test**: Reset release; start=1, data_in=0x55; wait for done; repeat for 0xAA; $finish. Implemented in top_spi_baseline.sv (initial block) and C++ (clk, rst_n); no UVM.

---

## Example: spi_baseline

| Component | Role |
|-----------|------|
| **dut/** | spi_master.v, clk_div.v |
| **top_spi_baseline.sv** | clk_div, spi_master; directed test in initial block |
| **sim_main.cpp** | Clock, reset; run until `$finish` |

Run: `cd module5/examples/spi_baseline && make run`

---

## Command Reference

```bash
cd module5/examples/spi_baseline
make run
```

```bash
./scripts/module5.sh --check   # Environment + example dirs
./scripts/module5.sh --run     # Run spi_baseline
```

---

## Learning Outcomes

- Describe SPI mode 0 and the role of sclk, mosi, cs_n, clk_div_tick.
- Explain the role of spi_master and clk_div.
- Run the spi_baseline example and interpret the directed test.
- Ready for Module 6: SPI UVM+SV verification.

---

## Exercises

1. **Run spi_baseline**
   - Run `make run` in `module5/examples/spi_baseline`. Confirm the directed test passes (e.g. expected bytes on MOSI).

2. **Trace one transfer**
   - Open `top_spi_baseline.sv` and DUT sources. For one byte (e.g. 0x55), trace: testbench asserts start and data_in → spi_master drives CS_N low, SCLK, and MOSI (MSB first, mode 0) → done pulses. Map SCLK edges (rising = capture, falling = change) to the RTL.

3. **Mode 0 timing**
   - In the monitor or RTL, identify where MOSI is sampled (rising SCLK) and where it changes (falling SCLK). Confirm this matches mode 0 (CPOL=0, CPHA=0).

4. **Optional: Waveforms**
   - If a VCD is generated, identify sclk, mosi, cs_n, start, done. Count 8 SCLK cycles per frame and verify MSB-first bit order.

---

## Assessment

- [ ] Can describe SPI mode 0 (idle low, capture on rising, change on falling) and signals sclk, mosi, cs_n.
- [ ] Can explain the role of spi_master and clk_div in the RTL.
- [ ] Can run spi_baseline and interpret the directed test result.
- [ ] Ready for Module 6: SPI UVM+SV verification.

---

## Next Steps

After completing this module, proceed to **Module 6: SPI UVM+SV** — full SPI verification with UVM (agent, sequences, driver, monitor, scoreboard).
