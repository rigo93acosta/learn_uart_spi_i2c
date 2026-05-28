# Module 7: I²C — Protocol + RTL + Basic Testbench

**Goal**: Understand the I²C protocol (start/stop, addressing, ACK/NACK), translate it to RTL (simple master + timing), and verify with a **basic** (non-UVM) directed testbench.

---

## Navigation

[← Previous: Module 6: SPI UVM+SV](MODULE6.md) | [Next: Module 8: I²C UVM+SV →](MODULE8.md)

[↑ Back to README](../README.md)

---

## Before You Start (Learning Path)

Before running commands:

1. **Read the detailed I²C learning guide**: [I2C_LEARNING_GUIDE.md](I2C_LEARNING_GUIDE.md) — what I²C is, what kind of protocol (serial, synchronous, two-wire bus), how it works (START/STOP, address+R/W, data, ACK/NACK concept), and where it’s used.
2. **Read the protocols + UVM overview**: [LEARNING_GUIDE_PROTOCOLS_AND_UVM.md](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) — **Part B § 4. When to Use Baseline vs UVM** (why we start with a baseline test before I²C UVM in Module 8).

Then follow **Overview** → **Topics Covered** → **Example** → **Exercises**.

---

## Running Module 7

- **Module doc**: [module7/README.md](../module7/README.md)
- **Example**: [module7/examples/i2c_baseline/](../module7/examples/i2c_baseline/) — I²C master RTL + basic directed test (no UVM)

**Quick run** (from repo root):

```bash
cd module7/examples/i2c_baseline
make run
```

Or: `./scripts/module7.sh --run`

- **Slides & video**: [slides.pptx](../media/module7/slides.pptx) · [slides.pdf](../media/module7/slides.pdf) · [video.mp4](../media/module7/video.mp4) — regenerate: `./scripts/build_all_media.sh --module 7`

---

## Overview

Module 7 is the I²C **protocol + RTL + basic testbench** module (UVM comes in Module 8).

- **I²C protocol**: Two-wire bus with SCL and SDA; START/STOP conditions; 7-bit address + R/W bit; byte transfers are MSB first.
- **Real hardware detail**: SDA (and often SCL) are **open-drain**; devices pull the line low and rely on pull-ups for high.
- **Teaching simplification in this repo**: Our baseline `i2c_master` drives `scl` and `sda` as **push-pull** outputs and does not model ACK/NACK or arbitration.

### What You'll Learn

- How START/STOP are detected/produced (SDA transitions while SCL high).
- How the address + R/W bit and data bytes are serialized on SDA.
- How to build a basic “bus monitor” that reconstructs bytes by sampling SDA on SCL rising edges.

### Prerequisites

- Modules 1–6.
- Verilator, Make, C++ compiler. **No UVM required** for this baseline.

---

## Topics Covered

### 1. I²C Protocol Essentials

- **Bus idle**: SCL=1, SDA=1.
- **START**: SDA goes 1→0 while SCL is 1.
- **STOP**: SDA goes 0→1 while SCL is 1.
- **Address phase**: 7-bit address + R/W bit (0=write, 1=read) sent MSB first.
- **Data phase**: 8-bit data bytes sent MSB first.
- **ACK/NACK** (concept): receiver pulls SDA low for ACK on the 9th clock; high means NACK.

### 2. RTL Architecture (Baseline)

- **clk_div**: Divides `clk` to produce `clk_div_tick` used to toggle/advance SCL timing.
- **i2c_master**: State machine that generates:
  - START condition
  - address+W bits
  - one data byte
  - STOP condition

### 3. Basic Testbench

The baseline testbench does two jobs:

- **Stimulus**: Pulses `start`, sets `addr` and `data_in`, waits for `done`.
- **Monitor/self-check**: Detects START, then samples SDA on each **rising** edge of SCL to reconstruct:
  - 8 bits of address+W
  - 8 bits of data

It then compares captured bytes to the expected values and prints `I2C baseline test PASS` on success.

---

## Example: i2c_baseline

| Component | Role |
|-----------|------|
| **dut/** | `i2c_master.v`, `clk_div.v` |
| **top_i2c_baseline.sv** | Instantiates DUT + directed test + monitor/self-check |
| **sim_main.cpp** | Clock/reset harness; simulation runs until `$finish` |

Run: `cd module7/examples/i2c_baseline && make run`

---

## Exercises

1. **Run i2c_baseline**
   - Run `make run` in `module7/examples/i2c_baseline`. Confirm the directed test passes (e.g. I2C baseline test PASS).

2. **Trace one transfer**
   - Open `top_i2c_baseline.sv` and DUT sources. For one (addr, data) write, trace: testbench pulses start, sets addr and data_in → i2c_master generates START → 8 bits address+W → 8 bits data → STOP → done. Map SCL/SDA timing to the state machine.

3. **Bus monitor**
   - Find the monitor/self-check that reconstructs bytes from SDA (sampling on rising SCL). Confirm it captures 8 bits of address+W and 8 bits of data after START.

4. **Optional: Waveforms**
   - If a VCD is generated, identify START (SDA high→low while SCL high), SCL edges, SDA data, and STOP (SDA low→high while SCL high).

---

## Assessment

- [ ] Can describe I²C START, STOP, address+R/W, and data phase (and ACK/NACK concept).
- [ ] Can explain the role of i2c_master and clk_div; know the baseline uses push-pull (simplified).
- [ ] Can run i2c_baseline and interpret the test result.
- [ ] Ready for Module 8: I²C UVM+SV verification.

---

## Next Steps

Proceed to **Module 8: I²C UVM+SV** to build a full I²C UVM agent (sequence/driver/monitor/scoreboard) and scale your testing.

