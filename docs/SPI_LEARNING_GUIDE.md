# SPI: Detailed Learning Guide

This guide explains **what SPI is**, **what kind of protocol it is**, and **how it works** from first principles. Read it before Module 5 (SPI RTL + baseline test) and Module 6 (SPI UVM).

---

## Navigation

[↑ Back to README](../README.md) | [Protocols & UVM Overview](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) | [Module 5: SPI baseline](MODULE5.md) | [Module 6: SPI UVM](MODULE6.md)

---

## 1. What Is SPI?

**SPI** stands for **Serial Peripheral Interface**.

- **Serial**: Data is sent **one bit at a time** on the data lines (MOSI, MISO).
- **Peripheral**: Often used to connect a **master** (CPU, FPGA, MCU) to **peripheral** devices (flash, ADC, DAC, display, sensor).
- **Interface**: A standard way to exchange data: the master drives a **clock** and **chip select**; data is captured and changed on clock edges.

In short: **SPI is a serial, synchronous, master–slave protocol: the master drives a clock (SCLK) and chip select (CS_N); data is sent one bit per clock edge, usually MSB first.**

---

## 2. What Kind of Protocol Is SPI?

| Property | SPI |
|----------|-----|
| **Serial vs parallel** | **Serial**: One bit at a time on MOSI and (if used) MISO. |
| **Synchronous vs asynchronous** | **Synchronous**: A **clock line (SCLK)** is driven by the master. The receiver uses this clock to sample and change data — no baud rate agreement. |
| **Topology** | **Master–slave**: One **master** (drives SCLK, MOSI, CS_N) and one or more **slaves** (selected by CS_N). Each slave has its own chip select (or shares with others in daisy-chain). |
| **Direction** | **Full-duplex** when MISO is used: master sends on MOSI and receives on MISO at the same time. **Half-duplex** if only MOSI (or only MISO) is used. |
| **Frame unit** | **Transfer-oriented**: A “frame” is one **transfer** (e.g. 8 bits). No start/stop bits; the frame is defined by **CS_N low** (active) for the duration of the transfer. |
| **Who drives** | **Master** drives SCLK, MOSI, and CS_N. **Slave** drives MISO (when selected). So clock and chip select are always from the master. |

So: **SPI is a serial, synchronous, master–slave protocol with a shared clock and chip select; data is sent one bit per clock edge, typically MSB first.**

---

## 3. How Does SPI Work? (Big Picture)

1. **Idle**: CS_N is **high** (inactive). SCLK is held at an **idle level** (low in Mode 0, high in Mode 1). No transfer.
2. **Start of frame**: The master pulls **CS_N low** (active) and starts toggling **SCLK**. This means “a transfer has started.”
3. **Data bits**: On each **clock edge**, one bit is **captured** (sampled) and one bit is **changed** (output). Which edge is “capture” and which is “change” depends on **SPI mode** (CPOL, CPHA). Usually **8 bits** are transferred, **MSB first**.
4. **End of frame**: After the last bit, the master stops toggling SCLK and pulls **CS_N high** (inactive). The transfer is done.
5. **No start/stop bits**: Unlike UART, there are no start or stop bits. The **clock** defines when each bit is valid; **CS_N** defines when the frame (transfer) is active.

So the slave **syncs** to the master’s clock; no baud rate or start bit is needed.

---

## 4. Signals

| Signal | Direction (from master) | Meaning |
|--------|-------------------------|---------|
| **SCLK** | Master → Slave(s) | **Serial clock**. Master drives; all slaves receive. Defines when to sample and when to change data. |
| **MOSI** | Master → Slave | **Master Out, Slave In**. Data from master to slave. |
| **MISO** | Slave → Master | **Master In, Slave Out**. Data from slave to master (when selected). Optional if master only sends. |
| **CS_N** | Master → Slave | **Chip select** (active **low**). One CS_N per slave (or shared in daisy-chain). When CS_N is low, that slave is active. |

**In this course’s baseline**: We use SCLK, MOSI, and CS_N only (no MISO). The master sends 8 bits on MOSI; the slave side is not modeled in the baseline RTL.

---

## 5. SPI Modes: CPOL and CPHA

SPI has **four modes** defined by two parameters:

- **CPOL** (clock polarity): SCLK level when **idle** (no transfer).
  - **CPOL = 0**: SCLK **idle low**.
  - **CPOL = 1**: SCLK **idle high**.
- **CPHA** (clock phase): **Which edge** captures data and **which edge** changes data.
  - **CPHA = 0**: **Capture** on first edge, **change** on second edge (within one clock period).
  - **CPHA = 1**: **Change** on first edge, **capture** on second edge.

| Mode | CPOL | CPHA | SCLK idle | Capture edge | Change edge |
|------|------|------|-----------|--------------|-------------|
| **0** | 0 | 0 | Low | Rising | Falling |
| **1** | 0 | 1 | Low | Falling | Rising |
| **2** | 1 | 0 | High | Falling | Rising |
| **3** | 1 | 1 | High | Rising | Falling |

**We use Mode 0** in this course: SCLK idle low; **capture on rising edge**; **change on falling edge**; first bit valid on the **first rising** edge after CS_N goes low.

---

## 6. Mode 0 in Detail (What We Implement)

- **Idle**: CS_N = 1, SCLK = 0.
- **CS_N goes low**: Transfer starts. Master will toggle SCLK.
- **Rising edge of SCLK**: **Capture** — slave (and monitor) **sample** MOSI (and MISO if present). So the **current** bit is valid at the rising edge.
- **Falling edge of SCLK**: **Change** — master (and slave) **output** the **next** bit on MOSI (and MISO). So after the falling edge, the line holds the next bit until the next rising edge.
- **8 SCLK cycles** (8 rising + 8 falling): 8 bits transferred, **MSB first**.
- **CS_N goes high**: Transfer ends. SCLK returns to idle (low in Mode 0).

So in Mode 0, **data is stable and sampled on the rising edge**; **new data is driven on the falling edge**.

---

## 7. Frame Format (No Start/Stop Bits)

Unlike UART, SPI has **no start or stop bits**. The “frame” is simply:

- **CS_N low** → start of frame.
- **N SCLK cycles** (e.g. 8) → N bits, usually MSB first.
- **CS_N high** → end of frame.

Bit order is **configurable** (MSB first is most common; some devices use LSB first). We use **MSB first** in this course.

---

## 8. Timing Diagram (Mode 0, 8 Bits, MSB First, Byte 0xA5)

0xA5 = binary **10100101**. MSB first → line sends: 1, 0, 1, 0, 0, 1, 0, 1.

```
CS_N:   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_________________________/‾‾‾‾‾‾‾‾‾‾‾‾
SCLK:   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾‾‾‾‾‾‾‾
MOSI:   ----------------<1><0><1><0><0><1><0><1>---------------
                       MSB              ...              LSB
                        ↑ capture (rising)   change (falling)
```

- **Rising edge**: Sample MOSI (capture).
- **Falling edge**: MOSI changes to next bit (master drives).

---

## 9. How the Master (TX) Works (Conceptually)

1. **Idle**: CS_N high, SCLK idle (low in Mode 0). No transfer.
2. **Start**: Host asserts **start** and provides **data_in[7:0]**. Master pulls CS_N low and loads data_in into a shift register (MSB first for output).
3. **Shift out**: On each **falling edge** of SCLK (or each half-period in RTL), master outputs the next bit on MOSI (MSB first). After 8 edges (or 8 half-periods), all 8 bits have been sent.
4. **Done**: Master pulls CS_N high and asserts **done** for one cycle. SCLK returns to idle.

So one byte = **8 SCLK cycles** (or 8 full periods). The exact timing (how many system clocks per half-period of SCLK) is set by a **clock divider** (clk_div).

---

## 10. How the Slave / Monitor Works (Conceptually)

1. **Wait for CS_N low**: When CS_N goes low, the transfer has started.
2. **Capture on rising edge**: On each **rising edge** of SCLK, sample MOSI (and MISO if present) and shift into a register (MSB first). After 8 rising edges, the full byte is captured.
3. **Use or forward**: The slave uses the byte (e.g. command, address, data); a **monitor** in the testbench forwards it to a scoreboard for checking.

So the receiver (slave or monitor) **syncs** to SCLK and needs no separate baud rate.

---

## 11. Clock Rate and Divider

- **SCLK frequency** is set by the master. It is often derived from the **system clock** by a **divider**:  
  `SCLK_period = 2 × DIVIDER × system_clock_period` (if one SCLK half-period = DIVIDER system clocks).  
  So SCLK_freq = system_clock_freq / (2 × DIVIDER).
- **Maximum rate** depends on the slave’s datasheet (e.g. 10 MHz, 50 MHz). For simulation we can use a small DIVIDER to speed up runs.

In our RTL, **clk_div** produces **clk_div_tick** (one pulse every DIVIDER system clocks). The **spi_master** uses this tick to advance SCLK and shift bits (e.g. one tick per half-period of SCLK).

---

## 12. Where SPI Is Used

- **Flash memory**: NOR/NAND flash often use SPI (e.g. SPI NOR for boot code).
- **Sensors**: Temperature, pressure, IMU with SPI output.
- **ADCs / DACs**: High-speed analog interfaces.
- **Displays**: Small LCDs and OLEDs with SPI.
- **FPGA ↔ MCU / peripheral**: Short-distance, high-speed link with a clock.

So SPI is used when you want **synchronous, clocked** serial data, often at **higher speed** than UART and with **simple** framing (no start/stop, just CS_N + SCLK).

---

## 13. SPI vs UART vs I²C (Brief)

| | SPI | UART | I²C |
|---|-----|------|-----|
| **Clock** | SCLK (master) | None (async) | SCL (shared) |
| **Wires** | SCLK, MOSI, MISO, CS_N (3–4+) | TX, RX (2) | SCL, SDA (2) |
| **Topology** | Master + slaves (CS per slave) | Point-to-point | Multi-master/multi-slave bus |
| **Frame** | CS_N low + N clocks | Start + data + stop | START + address + data + STOP |
| **Speed** | Often MHz | Limited by baud | 100 / 400 kHz typical |

SPI is **synchronous** and **simple** (no start/stop); you pay with more pins (clock + CS per slave).

---

## 14. How This Maps to Our RTL (Modules 5 and 6)

In this repo:

- **clk_div**: Divides the system clock to produce **clk_div_tick** (e.g. one pulse every DIVIDER cycles). Used to form SCLK half-periods.
- **spi_master**: On **start**, drives CS_N low, then toggles SCLK and shifts out **data_in[7:0]** on MOSI (MSB first, Mode 0). Asserts **done** when the 8-bit transfer is complete.

The **baseline testbench** (Module 5) drives start and data_in, waits for done, and may monitor MOSI to check the bits. The **UVM testbench** (Module 6) uses the same DUT and adds a UVM agent: transaction = one byte, driver drives start/data_in and waits for done, monitor samples MOSI on rising SCLK (Mode 0, MSB first), scoreboard compares expected vs observed.

---

## 15. Summary

- **SPI** = Serial Peripheral Interface: **serial**, **synchronous**, **master–slave** protocol with **SCLK** and **CS_N**.
- **No start/stop bits**: The frame is **CS_N low** + N SCLK cycles (e.g. 8 bits MSB first).
- **Mode 0**: SCLK idle low; **capture on rising edge**, **change on falling edge**.
- **Signals**: SCLK (master), MOSI (master → slave), MISO (optional, slave → master), CS_N (active low, one per slave).
- Used for flash, sensors, ADCs, displays, and high-speed peripheral links. In this course it maps to **clk_div** and **spi_master** in Module 5, and to a full UVM agent in Module 6.

Once this is clear, you can follow [Module 5](MODULE5.md) (SPI RTL + baseline test) and [Module 6](MODULE6.md) (SPI UVM) with a solid understanding of what SPI is and how it works.
