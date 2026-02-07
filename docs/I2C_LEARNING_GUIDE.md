# I²C: Detailed Learning Guide

This guide explains **what I²C is**, **what kind of protocol it is**, and **how it works** from first principles. Read it before Module 7 (I²C RTL + baseline test) and Module 8 (I²C UVM).

---

## Navigation

[↑ Back to README](../README.md) | [Protocols & UVM Overview](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) | [Module 7: I²C baseline](MODULE7.md) | [Module 8: I²C UVM](MODULE8.md)

---

## 1. What Is I²C?

**I²C** (or **I2C**) stands for **Inter-Integrated Circuit**.

- **Inter-Integrated**: Designed to connect **multiple chips** on the same board (e.g. CPU, sensor, EEPROM, RTC) over a **shared bus**.
- **Two-wire**: Only **two signals** — **SCL** (clock) and **SDA** (data). Both are **shared** by all devices on the bus. No separate chip select per device (address is sent in the frame).
- **Multi-master capable**: The full I²C spec allows **multiple masters** (arbitration, clock stretching). In this course we use a **single master** for simplicity.

In short: **I²C is a serial, synchronous, two-wire bus protocol: one clock (SCL) and one data line (SDA), with START/STOP conditions, 7-bit address + R/W bit, and data bytes, often with ACK/NACK.**

---

## 2. What Kind of Protocol Is I²C?

| Property | I²C |
|----------|-----|
| **Serial vs parallel** | **Serial**: Data is sent **one bit at a time** on SDA. SCL is the clock. |
| **Synchronous vs asynchronous** | **Synchronous**: A **clock line (SCL)** is shared. Data is sampled and changed on **rising** or **falling** edges (data valid while SCL high in standard I²C; change while SCL low). |
| **Topology** | **Multi-device bus**: One **bus** (SCL + SDA) shared by **multiple devices**. Each device has a **7-bit address**. No separate chip select wire; the address is sent at the start of each transfer. |
| **Direction** | **Half-duplex** on SDA: only one device drives SDA at a time (master or slave). Full I²C can do read and write in one transaction (address + R/W, then data). |
| **Frame unit** | **Transaction-oriented**: A “frame” is a **transaction**: START → address + R/W (8 bits) → ACK → data bytes (each 8 bits + ACK) → STOP. |
| **Who drives** | **Master** drives SCL and (during its turn) SDA. **Slave** drives SDA during ACK and during read data. In **real hardware**, SCL and SDA are **open-drain**: devices **pull low**; **pull-up resistors** pull high. So multiple devices can share the bus. |

So: **I²C is a serial, synchronous, multi-device bus protocol with two wires (SCL, SDA), START/STOP conditions, addressing (7-bit + R/W), and data bytes with ACK/NACK.**

---

## 3. How Does I²C Work? (Big Picture)

1. **Idle**: When nobody is transmitting, **SCL** and **SDA** are both **high** (pulled high by pull-ups in real HW). Bus idle.
2. **START**: The master drives **SDA low while SCL is high**. This is the **START condition**. It tells all slaves: “a transaction is starting; listen for the address.”
3. **Address + R/W**: The master sends **8 bits** on SDA (MSB first): **7-bit slave address** + **1 bit** (0 = write from master to slave, 1 = read from slave to master). All slaves compare the 7-bit address to their own; the matching slave responds.
4. **ACK/NACK**: On the **9th clock**, the **addressed slave** (in write) or the **master** (in read) drives **SDA low** for **ACK** (acknowledge) or leaves **SDA high** for **NACK** (not acknowledge). (Our baseline RTL does **not** model ACK/NACK.)
5. **Data bytes**: For a **write**, the master sends **8-bit data** (MSB first); after each byte, the slave sends ACK (9th clock). For a **read**, the slave drives 8 bits; the master sends ACK or NACK after each byte. Multiple bytes can follow.
6. **STOP**: The master drives **SDA high while SCL is high** (after releasing SDA so pull-up pulls high). This is the **STOP condition**. Transaction done; bus idle again.

So: **START** and **STOP** are special transitions on SDA **while SCL is high**; **address** and **data** are sent **8 bits at a time** on SDA, **MSB first**, with **SCL** toggling to clock each bit.

---

## 4. Signals

| Signal | Meaning |
|--------|--------|
| **SCL** | **Serial clock**. Driven by the **master** (in single-master mode). In full I²C, slaves can hold SCL low to **stretch** the clock (we don’t model that). Data is **valid** when SCL is **high**; **change** when SCL is **low** (standard I²C). |
| **SDA** | **Serial data**. **Bidirectional**: master drives during address and write data; slave drives during ACK and read data. In **real hardware**, both SCL and SDA are **open-drain**: devices only pull the line **low**; **pull-up resistors** pull the line **high** when no one drives low. So multiple devices can share the bus without conflict (only one drives low at a time). |

**In this course’s baseline**: We use a **simplified** model: the **i2c_master** drives SCL and SDA as **push-pull** outputs (not open-drain). We do **not** model ACK/NACK, clock stretching, or multi-master arbitration. This keeps the RTL and testbench simple for learning; the protocol concepts (START, STOP, address, data) are the same.

---

## 5. Idle, START, and STOP

- **Idle**: SCL = 1, SDA = 1. No one is transmitting.
- **START**: SDA goes **1 → 0 while SCL is 1**. A **falling edge** on SDA while SCL is high. Unique; cannot be confused with a data bit (data changes only when SCL is low).
- **STOP**: SDA goes **0 → 1 while SCL is 1**. A **rising edge** on SDA while SCL is high. Transaction ended.

So **START** and **STOP** are **level changes on SDA while SCL is high**. That is why data must only change when SCL is low — so that START/STOP are unambiguous.

---

## 6. Address + R/W Bit (8 Bits)

The first byte after START is **address + R/W**:

- **Bits [7:1]**: **7-bit slave address**. Each device on the bus has a unique 7-bit address (or responds to a reserved address). Slaves compare these 7 bits to their own address.
- **Bit [0]**: **R/W bit**. **0** = master **writes** (master will send data to slave). **1** = master **reads** (slave will send data to master).

So one **byte** (8 bits, MSB first): A7 A6 A5 A4 A3 A2 A1 R/W. Sent by the **master** on SDA, one bit per SCL cycle (data valid when SCL high, change when SCL low).

---

## 7. Data Bytes and ACK/NACK (Full I²C)

- **Data byte**: 8 bits on SDA, **MSB first**, same as address byte. Master drives for **write**; slave drives for **read**.
- **ACK/NACK**: After **each** 8-bit byte (address or data), there is a **9th clock** (the “ACK bit”).  
  - **ACK**: The **receiver** (slave for write, master for read) pulls **SDA low** during this 9th clock. Means “byte received.”  
  - **NACK**: The receiver **leaves SDA high** (or drives high). Means “not acknowledge” (e.g. no more data, or error).

**In our baseline**: We do **not** implement ACK/NACK in the RTL. The monitor in the testbench only reconstructs **address+W** and **data** from SDA (sampling on rising SCL); it does not check the 9th clock. So you learn the frame structure (START, address, data, STOP) without the extra ACK logic.

---

## 8. Frame Format (Conceptually)

A typical **write** transaction:

```
  Idle   START   Address+R/W (8 bits)   ACK   Data (8 bits)   ACK   STOP   Idle
    |      |           A7...A0,R/W         |      D7...D0        |      |      |
  SCL: ‾‾‾‾‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾‾‾‾‾
  SDA: ‾‾‾‾‾‾‾‾\___________________/‾\___/‾\___________________/‾\___/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
            ↑   ↑                   ↑   ↑   ↑                   ↑   ↑
         START  address+R/W        ACK  data byte              ACK  STOP
```

- **START**: SDA 1→0 while SCL high.
- **8 clocks**: Address + R/W (or data), MSB first. Data **valid** when SCL **high**, **change** when SCL **low**.
- **9th clock**: ACK (receiver pulls SDA low) or NACK (SDA high). (Not modeled in our baseline.)
- **STOP**: SDA 0→1 while SCL high.

Multiple data bytes can follow (each 8 bits + ACK) before STOP.

---

## 9. Timing: When to Sample and When to Change

In **standard I²C**:

- **Data (and address) are valid** when **SCL is high**. So the receiver should **sample SDA on the rising edge** of SCL (or while SCL is high).
- **Data (and address) may change** when **SCL is low**. So the transmitter should **change SDA only when SCL is low**.

So: **sample on rising SCL**; **change on falling SCL** (or while SCL low). That way START and STOP (SDA change while SCL high) are unique and not mistaken for data.

**In our RTL and monitor**: We sample SDA on the **rising edge** of SCL to reconstruct address and data. The master changes SDA in the low phase of SCL.

---

## 10. Timing Diagram (Simplified: Address 0x50, Data 0xA5, Write)

7-bit address **0x50** (0b101_0000), R/W = 0 (write) → first byte = **0xA0**. Data byte = **0xA5**.

```
       START    Address+R/W (0xA0)    Data (0xA5)    STOP
SCL:   ‾‾‾‾‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾‾‾‾‾‾‾‾‾
SDA:   ‾‾‾‾‾‾‾‾\__1__0__1__0__0__0__0__0__/‾\__1__0__1__0__0__1__0__1__/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
              ↑  MSB            LSB  ↑  MSB            LSB  ↑
            START   (0xA0 = addr+W)   (0xA5 = data)       STOP
```

(ACK cycles omitted in this simplified picture; our baseline does not drive or check them.)

---

## 11. How the Master Works (Conceptually)

1. **Idle**: SCL and SDA high (or not driven). No transfer.
2. **Start**: Master generates **START** (SDA 1→0 while SCL high).
3. **Address + R/W**: Master toggles SCL and outputs **8 bits** on SDA (7-bit address + R/W), MSB first. (In full I²C, master releases SDA for 9th clock and checks ACK.)
4. **Data**: Master outputs **8 bits** of data on SDA, MSB first. (In full I²C, again 9th clock for ACK.)
5. **Stop**: Master generates **STOP** (SDA 0→1 while SCL high).
6. **Done**: Master asserts **done** for one cycle and returns to idle.

So one **write** in our baseline: START → 8 bits (address+W) → 8 bits (data) → STOP. No ACK in RTL.

---

## 12. How the Slave / Monitor Works (Conceptually)

1. **Wait for START**: Detect SDA going 1→0 while SCL high. Transaction started.
2. **Capture address + R/W**: On the next **8 rising edges** of SCL, sample SDA and shift into a register (MSB first). That gives the 8-bit address+W byte.
3. **(Full I²C: drive ACK on 9th clock. We skip.)**
4. **Capture data**: On the next **8 rising edges** of SCL, sample SDA (MSB first). That gives the data byte.
5. **Wait for STOP**: SDA 0→1 while SCL high. Transaction ended.

A **monitor** in the testbench does the same sampling (no ACK drive) and forwards address+data to the scoreboard for checking.

---

## 13. Clock Rate (100 kHz and 400 kHz)

- **Standard mode**: Up to **100 kHz** SCL.
- **Fast mode**: Up to **400 kHz** SCL.

In our RTL, SCL is derived from the **system clock** via a **divider** (e.g. **clk_div** producing **clk_div_tick**). The **i2c_master** state machine advances SCL and SDA timing using this tick. For simulation we can use a small divider to speed up runs.

---

## 14. Where I²C Is Used

- **Sensors**: Temperature, humidity, IMU, many small sensors with I²C.
- **EEPROM**: Small non-volatile memory.
- **RTC**: Real-time clocks.
- **PMIC**: Power management ICs (configuration over I²C).
- **Displays**: Some small LCD/OLED drivers.
- **Multi-device boards**: When you need **many devices** with **only two wires** (SCL, SDA) and **moderate speed**.

So I²C is used when you want a **shared bus**, **addressing** (no separate chip select per device), and **low pin count** (two wires total).

---

## 15. I²C vs UART vs SPI (Brief)

| | I²C | UART | SPI |
|---|-----|------|-----|
| **Clock** | SCL (shared) | None (async) | SCLK (master) |
| **Wires** | SCL + SDA (2) | TX + RX (2) | SCLK, MOSI, MISO, CS_N (3–4+) |
| **Topology** | Multi-device bus (address) | Point-to-point | Master + slaves (CS per slave) |
| **Addressing** | 7-bit address in frame | None | Chip select (separate wire) |
| **Speed** | 100 / 400 kHz typical | Baud-limited | Often MHz |
| **Complexity** | START/STOP, address, ACK | Start/data/stop | CS + clock + data |

I²C gives you **two wires** and **multiple devices** with **in-frame addressing**; you trade some complexity (START/STOP, ACK) and lower speed.

---

## 16. How This Maps to Our RTL (Modules 7 and 8)

In this repo:

- **clk_div**: Divides the system clock to produce **clk_div_tick** for SCL/SDA timing. Same idea as UART baud_gen and SPI clk_div.
- **i2c_master**: State machine that generates **START** → **8 bits (address+W)** → **8 bits (data)** → **STOP**, and pulses **done** when the transfer is complete. Drives SCL and SDA as **push-pull** (simplified; no open-drain, no ACK/NACK).

The **baseline testbench** (Module 7) drives start, addr, data_in; waits for done; and uses a **bus monitor** to reconstruct address+data from SDA (sampling on rising SCL) and compare to expected values. The **UVM testbench** (Module 8) uses the same DUT and adds a UVM agent: transaction = (address, data), driver drives start/addr/data_in and waits for done, monitor samples SCL/SDA and reconstructs (addr, data), scoreboard compares expected vs observed.

---

## 17. Summary

- **I²C** = Inter-Integrated Circuit: **serial**, **synchronous**, **two-wire bus** (SCL, SDA) with **START/STOP**, **7-bit address + R/W**, and **data bytes** (with ACK/NACK in full I²C).
- **Idle**: SCL = 1, SDA = 1. **START**: SDA 1→0 while SCL high. **STOP**: SDA 0→1 while SCL high.
- **Address + R/W**: 8 bits (7-bit address + R/W), MSB first. **Data**: 8 bits per byte, MSB first. **Sample SDA on rising SCL**; **change SDA when SCL low**.
- **Real hardware**: Open-drain + pull-ups; multi-master and ACK/NACK. **Our baseline**: Push-pull master, no ACK/NACK, single master — same frame concept for learning.
- Used for sensors, EEPROMs, RTCs, PMICs, and multi-device boards. In this course it maps to **clk_div** and **i2c_master** in Module 7, and to a full UVM agent in Module 8.

Once this is clear, you can follow [Module 7](MODULE7.md) (I²C RTL + baseline test) and [Module 8](MODULE8.md) (I²C UVM) with a solid understanding of what I²C is and how it works.
