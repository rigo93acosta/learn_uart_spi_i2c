# Learning Guide: UART, SPI, I²C Protocols & UVM Verification

This guide teaches **protocol fundamentals** and **where and how UVM applies** before you run the exercises in Modules 3–8. Read the relevant sections **before** starting each module so the material is learning-focused, not just “run this command.”

---

## Navigation

[↑ Back to README](../README.md) | [Module 1](MODULE1.md) | [Module 2](MODULE2.md) | [Module 3](MODULE3.md) | [Module 4](MODULE4.md) | [Module 5](MODULE5.md) | [Module 6](MODULE6.md) | [Module 7](MODULE7.md) | [Module 8](MODULE8.md)

---

## How to Use This Guide

**UART (Modules 3–4):** For a **detailed** explanation of UART — what it is, what kind of protocol, how it works (frame, baud, TX/RX, timing) — read **[UART_LEARNING_GUIDE.md](UART_LEARNING_GUIDE.md)** first. Then use this guide for UVM and baseline vs UVM.

| Before starting… | Read |
|------------------|------|
| **Module 3** (UART baseline) | **[UART_LEARNING_GUIDE.md](UART_LEARNING_GUIDE.md)** (full UART guide), then [4. When to Use Baseline vs UVM](#4-when-to-use-baseline-vs-uvm) (first part) |
| **Module 4** (UART UVM) | **[UART_LEARNING_GUIDE.md](UART_LEARNING_GUIDE.md)** (full UART guide), then [5. How UVM Maps to a Protocol](#5-how-uvm-maps-to-a-protocol), [6. UART UVM Mapping](#6-uart-uvm-mapping) |
| **Module 5** (SPI baseline) | **[SPI_LEARNING_GUIDE.md](SPI_LEARNING_GUIDE.md)** (full SPI guide), then [4. When to Use Baseline vs UVM](#4-when-to-use-baseline-vs-uvm) |
| **Module 6** (SPI UVM) | **[SPI_LEARNING_GUIDE.md](SPI_LEARNING_GUIDE.md)** (full SPI guide), then [5. How UVM Maps to a Protocol](#5-how-uvm-maps-to-a-protocol), [7. SPI UVM Mapping](#7-spi-uvm-mapping) |
| **Module 7** (I²C baseline) | **[I2C_LEARNING_GUIDE.md](I2C_LEARNING_GUIDE.md)** (full I²C guide), then [4. When to Use Baseline vs UVM](#4-when-to-use-baseline-vs-uvm) |
| **Module 8** (I²C UVM) | **[I2C_LEARNING_GUIDE.md](I2C_LEARNING_GUIDE.md)** (full I²C guide), then [5. How UVM Maps to a Protocol](#5-how-uvm-maps-to-a-protocol), [8. I²C UVM Mapping](#8-i2c-uvm-mapping) |

---

## Part A: Protocol Fundamentals

### 1. UART Protocol

**What it is**

- **UART** = Universal Asynchronous Receiver/Transmitter.
- **Asynchronous**: No separate clock line; sender and receiver agree on a **baud rate** (bits per second). Each side uses its own clock and a **baud generator** to sample at the right time.
- **Point-to-point**: One TX, one RX (often one device has both for full-duplex).

**Where it’s used**

- Serial consoles, legacy PC COM ports, many MCU debug interfaces, simple board-to-board links, GPS/sensors with serial output.

**Frame format (8N1 in this course)**

- **Idle**: Line is **high** (1).
- **Start bit**: One bit time **low** (0) — tells the receiver “a byte is coming.”
- **Data**: 8 bits, **LSB first**, one bit per baud tick.
- **Stop bit**: One bit time **high** (1).
- **No parity** in 8N1 (N = no parity).

**Timing (conceptually)**

```
Idle   Start  D0  D1  D2  D3  D4  D5  D6  D7  Stop  Idle
  1   →  0  →  LSB … MSB  →  1  →  1
  ↑       ↑    ←── one baud_tick per bit ──→   ↑
  idle   start                               stop
```

- **Baud rate**: e.g. 115200 baud = 115200 bits per second. From system clock:  
  `DIVIDER = round(clk_Hz / baud_rate)` (e.g. 50 MHz / 115200 ≈ 434).
- **Sampling**: In a simple design, sample **once per bit** at the baud tick (mid-bit is better in real designs; oversampling is common in production).

**RTL mapping (what you build in Module 3)**

- **baud_gen**: Divides `clk` → outputs `baud_tick` every DIVIDER cycles.
- **uart_tx**: On `start`, send start bit (0), then 8 data bits (LSB first), then stop bit (1); assert `busy` during the frame.
- **uart_rx**: Detect start (line goes low), sample one bit per `baud_tick`, reconstruct byte, pulse `data_valid` and output `data_out`; optionally `framing_error` if stop bit is wrong.

---

### 2. SPI Protocol

**What it is**

- **SPI** = Serial Peripheral Interface.
- **Synchronous**: A **clock line (SCLK)** is driven by the master; data is captured and changed on clock edges.
- **Master–slave**: Master drives SCLK, MOSI, and CS_N; slave(s) use MISO (optional). **Chip select (CS_N)** selects which slave is active.

**Where it’s used**

- Flash, ADCs, DACs, displays, sensors, FPGAs talking to peripherals. Short distances, higher speed than UART for same pin count when you need a clock.

**Modes (CPOL, CPHA)**

- **CPOL**: SCLK idle level (0 = low, 1 = high).
- **CPHA**: When data is captured and when it changes (0 or 1).
- **Mode 0** (used in this course): CPOL=0, CPHA=0 → SCLK **idle low**; **capture on rising edge**, **change on falling edge**; first bit valid on first rising edge.

**Signals (baseline in this repo)**

- **sclk**: Serial clock (master-driven).
- **mosi**: Master Out, Slave In (data from master).
- **cs_n**: Chip select, **active low**; frame = from CS_N low to CS_N high.
- **miso**: Optional (not used in the baseline examples).

**Timing (Mode 0, 8-bit MSB first)**

```
cs_n:   ‾‾‾‾‾‾‾‾‾‾‾‾\_________________________/‾‾‾‾‾‾‾‾
sclk:   ‾‾‾‾‾‾‾‾‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾‾‾
mosi:   ------------<MSB><  …  ><LSB>----------------------
                    ↑ capture    ↑ change (falling)
```

- One bit per half-period of SCLK; **clk_div_tick** in RTL typically advances state every N system clocks to form SCLK.

**RTL mapping (Module 5)**

- **clk_div**: Produces `clk_div_tick` every DIVIDER cycles.
- **spi_master**: On `start`, drive CS_N low, then 8 SCLK edges; output one bit per half-cycle on MOSI (MSB first); pulse `done` when the frame is complete.

---

### 3. I²C Protocol

**What it is**

- **I²C** = Inter-Integrated Circuit (I2C).
- **Two-wire**: **SCL** (clock) and **SDA** (data); both are **open-drain** in real hardware (devices pull low; pull-up resistors pull high). This course uses a **simplified** push-pull model for the RTL.
- **Multi-master capable** in the full spec (arbitration, clock stretching); our baseline is a single master.

**Where it’s used**

- Sensors, EEPROMs, RTCs, PMICs, many low-speed peripherals on the same bus. Good when you need multiple devices on two wires and moderate speed.

**Frame structure**

- **Idle**: SCL=1, SDA=1.
- **START**: SDA goes **1→0 while SCL is 1**.
- **Address + R/W**: 7-bit address + 1 bit (0=write, 1=read), **MSB first** (8 bits total).
- **ACK/NACK**: 9th clock; receiver pulls SDA low = ACK, high = NACK. (Our baseline does not model ACK/NACK.)
- **Data bytes**: 8 bits MSB first, each followed by ACK/NACK in full I²C.
- **STOP**: SDA goes **0→1 while SCL is 1**.

**Timing (conceptually)**

```
       START    Address+R/W   ACK   Data byte   ACK   STOP
SCL:   ‾‾‾‾‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾‾‾\_/‾\_/‾…
SDA:   ‾‾‾‾‾‾‾\___________________/‾\___/‾\___...___/‾‾‾‾‾‾‾
              ↑                    ↑   ↑
            START              addr+W  data
```

**RTL mapping (Module 7)**

- **clk_div**: Produces `clk_div_tick` for SCL/SDA timing.
- **i2c_master**: State machine: START → send 8 bits (address+W) → (ACK in full I²C) → send 8-bit data → STOP; pulse `done` when the transfer is complete. Our teaching DUT uses push-pull SCL/SDA and does not implement ACK/NACK or arbitration.

---

### Quick Comparison

|            | UART        | SPI              | I²C           |
|------------|------------|------------------|---------------|
| **Clock**  | None (async) | SCLK (master)   | SCL (shared)  |
| **Lines**  | TX, RX      | SCLK, MOSI, (MISO), CS_N | SCL, SDA |
| **Topology** | Point-to-point | Master + N slaves (CS per slave) | Multi-device bus |
| **Speed**  | Baud-limited | Often MHz range | 100 / 400 kHz typical |
| **Use case** | Console, simple link | Fast peripherals | Many slow devices, 2 wires |

---

## Part B: Where and How UVM Applies

### 4. When to Use Baseline vs UVM

**Baseline testbench (Modules 3, 5, 7)**

- **What**: Directed stimulus in `initial` blocks (or similar): drive pins, wait for completion, check outputs (e.g. loopback or bus monitor).
- **When**: First bring-up, sanity checks, learning the protocol and RTL, or very small blocks.
- **Limitation**: Adding new tests = more `initial` blocks and ad-hoc checks; reuse and coverage scale poorly.

**UVM testbench (Modules 4, 6, 8)**

- **What**: Same DUT, but stimulus is **transactions** (e.g. “send this byte” or “write this address/data”). A **sequence** produces transactions; a **driver** turns them into protocol cycles; a **monitor** turns protocol activity back into transactions; a **scoreboard** compares expected vs observed.
- **When**: When you want many test scenarios, reuse (sequences, agents), and a clear place to add coverage and assertions. Same methodology for UART, SPI, and I²C.

**Takeaway**

- Baseline = “learn the protocol and RTL, one or a few tests.”
- UVM = “scale tests, reuse components, and check expected vs observed in a structured way.”

---

### 5. How UVM Maps to a Protocol

UVM does **not** replace the protocol; it **sits on top** of the DUT and drives/observes it **according to the protocol**.

| UVM piece    | Role relative to the protocol |
|-------------|--------------------------------|
| **Transaction** | One “protocol unit”: one UART byte, one SPI transfer, one I²C (addr+data) write. Carries “what to do” (e.g. data to send) and “what was seen” (e.g. monitor’s reconstructed value). |
| **Sequence** | Produces a stream of transactions (e.g. 0x00, 0x55, 0xAA). Directed today; can be random or scenario-based later. |
| **Driver**   | Takes a transaction and **drives the DUT pins** following the **protocol timing** (e.g. start bit then 8 data bits for UART; SCLK/MOSI/CS_N for SPI; START/addr/data/STOP for I²C). |
| **Monitor**  | **Observes DUT pins** and, using **protocol rules**, reconstructs transactions (e.g. one byte from the serial line, one byte from SCLK/MOSI, one addr+data from SCL/SDA). Sends reconstructed transactions to the scoreboard. |
| **Scoreboard** | Holds “expected” transactions (what we sent) and “observed” (what the monitor saw). Compares them and reports pass/fail. |
| **Agent**    | Groups sequencer + driver + monitor for one interface. **Env** contains agent(s) + scoreboard. **Test** builds env, starts sequence, runs UVM phases. |

So: **protocol** defines *what* appears on the wires (frames, edges, levels). **UVM** defines *how* we generate and check that in a reusable way (transaction → driver → pins; pins → monitor → transaction → scoreboard).

---

### 6. UART UVM Mapping (Module 4)

- **Transaction**: One byte to send; monitor fills “observed” byte (from TX line or loopback).
- **Driver**: Assert `start`, put `data` on the interface, wait for one UART frame (e.g. 10 baud_ticks: start + 8 data + stop).
- **Monitor**: Watch TX (and optionally RX for loopback); detect start bit, sample 8 bits per baud_tick (LSB first), form byte; send to scoreboard.
- **Scoreboard**: Compare expected byte (from sequence) vs observed byte (from monitor); also RX path if loopback is used.

**Where UVM applies**: The **entire testbench** around the UART DUT (uart_tx, uart_rx, baud_gen). The DUT stays RTL; UVM drives and observes it via an interface.

---

### 7. SPI UVM Mapping (Module 6)

- **Transaction**: One byte to transfer; monitor fills “observed” byte from MOSI.
- **Driver**: Assert `start`, put `data_in` on the interface, wait for `done` (one SPI frame).
- **Monitor**: When CS_N goes low, sample MOSI on each **rising** SCLK (mode 0), MSB first; reconstruct byte; send to scoreboard.
- **Scoreboard**: Expected vs observed byte.

**Where UVM applies**: The testbench around the SPI master DUT (spi_master, clk_div). UVM drives start/data_in and observes sclk/mosi/cs_n (and optionally miso if present).

---

### 8. I²C UVM Mapping (Module 8)

- **Transaction**: One (address, data) write; monitor fills observed address and data.
- **Driver**: Assert `start`, put `addr` and `data_in`, wait for `done`.
- **Monitor**: Detect START; sample SDA on **rising** SCL to get 8 bits (address+W) and 8 bits (data); send (addr, data) to scoreboard.
- **Scoreboard**: Compare expected (addr, data) vs observed (addr, data).

**Where UVM applies**: The testbench around the I²C master DUT (i2c_master, clk_div). UVM drives start/addr/data_in and observes scl/sda to verify the bus-level transaction.

---

## Summary

1. **Protocols**: UART (async, baud, 8N1); SPI (sync, mode 0, SCLK/MOSI/CS_N); I²C (two-wire, START/address/data/STOP). Each has a clear frame and timing so RTL and testbench can be specified.
2. **Baseline vs UVM**: Baseline = quick, directed tests; UVM = scalable, reusable verification with transactions, sequences, driver, monitor, scoreboard.
3. **Where UVM applies**: In the **testbench only**. It generates and checks protocol behavior; the DUT remains plain RTL.
4. **How UVM maps**: Transaction = one protocol unit; driver = pins per protocol; monitor = bus sampling per protocol; scoreboard = expected vs observed.

Use this guide **before** doing the exercises in Modules 3–8 so you understand both the protocols and how UVM is applied to verify them.
