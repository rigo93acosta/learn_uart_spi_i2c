# UART: Detailed Learning Guide

This guide explains **what UART is**, **what kind of protocol it is**, and **how it works** from first principles. Read it before Module 3 (UART RTL + baseline test) and Module 4 (UART UVM).

---

## Navigation

[↑ Back to README](../README.md) | [Protocols & UVM Overview](LEARNING_GUIDE_PROTOCOLS_AND_UVM.md) | [Module 3: UART baseline](MODULE3.md) | [Module 4: UART UVM](MODULE4.md)

---

## 1. What Is UART?

**UART** stands for **Universal Asynchronous Receiver/Transmitter**.

- **Universal**: The same idea is used across many systems (PCs, microcontrollers, FPGAs, sensors). The basic frame format and rules are standardized.
- **Asynchronous**: There is **no separate clock wire** between the two sides. The receiver does not get a clock from the transmitter; instead, both sides agree in advance on a **bit rate** (baud rate) and use their own local clocks to time bits.
- **Receiver/Transmitter**: A UART block usually has both: it **transmits** data on one pin (TX) and **receives** data on another pin (RX). So one chip can send and receive over two lines (full-duplex).

In short: **UART is a serial, asynchronous, point-to-point protocol that sends data one bit at a time, framed by a start bit and one or more stop bits, with no shared clock.**

---

## 2. What Kind of Protocol Is UART?

Understanding UART’s “kind” helps you see how it differs from SPI and I²C.

| Property | UART |
|----------|------|
| **Serial vs parallel** | **Serial**: Data is sent **one bit at a time** on a single data line (per direction). No separate wires for each bit. |
| **Synchronous vs asynchronous** | **Asynchronous**: There is **no clock line**. Timing is recovered from the **start bit** and the agreed **baud rate**. |
| **Topology** | **Point-to-point**: One transmitter talks to one receiver. (You can have multiple UARTs on a board, each with its own TX/RX pair.) |
| **Direction** | Usually **full-duplex**: TX and RX are separate lines, so both sides can send at the same time (if both have a UART). |
| **Frame unit** | **Character- or byte-oriented**: Each “frame” is one character (often 8 bits) plus start and stop bits. No separate address or packet header in the basic form. |
| **Who drives the line** | Each side drives only its **TX** output; the other side’s **RX** is the input. So each wire is driven by one transmitter. |

So: **UART is a serial, asynchronous, point-to-point, character-oriented protocol with no shared clock.**

---

## 3. How Does UART Work? (Big Picture)

1. **Idle**: When nobody is sending, the TX line is held **high** (logic 1). This is the “idle” or “mark” state.
2. **Start of frame**: To send a byte, the transmitter pulls the line **low** for one bit time. This is the **start bit** (always 0). It tells the receiver: “get ready, a frame is starting.”
3. **Data bits**: The transmitter then sends the data bits, **one bit per bit time**, usually **LSB first** (least significant bit first). Common is 8 data bits.
4. **End of frame**: After the data bits, the transmitter sends one (or two) **stop bits** by holding the line **high** (1) for one (or two) bit times. Then the line stays high (idle) until the next start bit.
5. **Timing**: There is no clock wire. The receiver **knows** the bit rate in advance (e.g. 115200 bits per second). It waits for the **falling edge** (start bit), then samples the line at the **middle** of each bit time (in a good design) to read data and stop bits.

So the receiver “syncs” to the frame using the **start bit** and then uses its **local clock** (from a baud generator) to sample at the right moments.

---

## 4. Physical Layer: Wires and Levels

- **Wires**: For **full-duplex** (both directions at once), you need at least **two signal lines**:
  - **TX** of device A connects to **RX** of device B.
  - **TX** of device B connects to **RX** of device A.
  So “TX” and “RX” are from one device’s point of view; the two sides cross-connect.
- **Voltage levels**: In our RTL we use **logic levels** (0 and 1). In real hardware:
  - **TTL/CMOS**: e.g. 0 V = 0, 3.3 V or 5 V = 1 (common on boards and MCUs).
  - **RS-232**: Uses ±voltage (e.g. +3 to +15 V = 0, −3 to −15 V = 1) and different connectors; level shifters convert between TTL and RS-232 when needed (e.g. USB–serial adapters).

We do not model voltage or RS-232 in RTL; we only model the **logical** line (idle high, start low, data, stop high).

---

## 5. Frame Format in Detail

A single UART “frame” is **one character** (e.g. one byte). The frame has a fixed structure.

### 5.1 Standard Frame Structure

```
  Idle    Start   Data bits (e.g. 8)      Parity (optional)   Stop bit(s)   Idle
    |        |    D0 D1 D2 ... D7              |                    |          |
    v        v    LSB ---------> MSB           v                    v          v
  ___      _____  _________________________  _____  ________________  ___
_|   |____|     |                          |     |                  |   |_____
     ^          ^                          ^     ^                  ^
   high        low                        optional                 high
   (1)         (0)                        (P)                      (1)
```

- **Idle**: Line is **high** (1). No transmission.
- **Start bit**: **One bit time low** (0). Always present. This is the **synchronization** event: the receiver detects the high→low transition and starts its bit timer.
- **Data bits**: Usually **5, 6, 7, 8, or 9** bits. Most common is **8 bits**. Sent **LSB first** (D0 first, then D1, …, then D7).
- **Parity** (optional): One extra bit for simple error detection (even or odd parity). **N** = no parity. We use **no parity** in this course (8N1).
- **Stop bit(s)**: **One or two** bit times with the line **high** (1). Gives the receiver time to finish and prepares the line for the next start bit. We use **1 stop bit** (8N1).

### 5.2 Notation: 8N1

You will see formats like **8N1**:

- **8** = 8 data bits.
- **N** = No parity (E = even, O = odd, N = none).
- **1** = 1 stop bit (could be 1.5 or 2 in other configs).

So **8N1** means: 1 start bit (always) + 8 data bits + no parity + 1 stop bit = **10 bit times per byte**.

---

## 6. Baud Rate and Bit Time

- **Baud rate** = number of **symbols per second** on the line. For UART, one symbol is one bit, so baud rate = **bits per second** (e.g. 9600, 115200).
- **Bit time** = time for one bit = 1 / baud_rate.  
  Example: 115200 baud → bit time = 1/115200 ≈ 8.68 µs.

The receiver and transmitter **must use the same baud rate**. If they differ, bytes will be misread.

### 6.1 Deriving a Baud Tick from the System Clock

In RTL we have a **system clock** (e.g. 50 MHz). We need a **baud tick** (one pulse per bit time) to drive TX and to sample RX.

- **Divider**:  
  `DIVIDER = round(system_clock_Hz / baud_rate)`  
  Example: 50 MHz, 115200 baud → DIVIDER = 50_000_000 / 115200 ≈ 434.
- **Baud tick**: Every **DIVIDER** system clock cycles, we assert **one** baud tick for one cycle. So we get exactly one “tick” per bit time.

That baud tick is used to:
- **TX**: Advance the shift register (output one bit per tick).
- **RX**: Sample the line once per bit (or, in better designs, oversample and take the middle sample).

---

## 7. How the Transmitter (TX) Works

Conceptually:

1. **Idle**: TX output is **high**. When the host wants to send a byte, it asserts **start** and provides **data_in[7:0]**.
2. **Start bit**: On the next baud tick, TX drives the line **low** for one baud period.
3. **Data bits**: On the next 8 baud ticks, TX outputs **data_in[0], data_in[1], …, data_in[7]** (LSB first), one bit per tick.
4. **Stop bit**: On the next baud tick, TX drives the line **high** for one baud period.
5. **Done**: TX goes back to idle (high). It may assert a **busy** signal during the whole frame and clear it after the stop bit.

So one byte = 1 + 8 + 1 = **10 baud ticks** for 8N1.

---

## 8. How the Receiver (RX) Works

Conceptually:

1. **Idle**: RX watches the line. When it sees the line go **high → low** (start bit), it **synchronizes** and starts a bit counter.
2. **Sampling**: To avoid sampling at the edges (where the line might still be changing), we sample near the **middle** of each bit. In a simple RTL design we might sample on a **baud tick** that is aligned to the middle (e.g. after waiting half a bit time after the start edge, then one tick per bit). In production, **oversampling** (e.g. 16×) is common: run a faster tick and take the majority vote in the middle of the bit.
3. **Data**: For 8 bits, RX samples the line on 8 successive (mid-)bit times and shifts them into a register (LSB first), giving **data_out[7:0]**.
4. **Stop bit**: RX samples the stop bit (expects high). If it sees low, it can flag **framing_error**.
5. **Output**: RX asserts **data_valid** for one cycle and presents **data_out**. Then it goes back to watching for the next start bit.

So the receiver **reconstructs** the byte from the serial line using only the start-bit edge and the agreed baud rate.

---

## 9. Timing Diagram (One Frame, 8N1, Byte 0x55)

Byte **0x55** = binary **01010101**. LSB first, so the line sends: 1, 0, 1, 0, 1, 0, 1, 0.

```
Bit:     Idle  Start  D0  D1  D2  D3  D4  D5  D6  D7  Stop  Idle
          1      0     1   0   1   0   1   0   1   0    1     1

Line:  ___     _____   _   _   _   _   _   _   _   _   ___   ___
     _|   |___|     |_| |_| |_| |_| |_| |_| |_| |_| |_|   |_|   |___
        ^       ^
        |       +-- start bit (0)
        +---------- idle (1)

Time:  |<- 1 bit time ->|<- 1 bit ->| ... (10 bit times total for 8N1)
```

So you see: idle high → start low → 8 data bits (LSB first) → stop high → idle high.

---

## 10. Common Baud Rates and Use Cases

| Baud rate | Typical use |
|-----------|-------------|
| 9600 | Legacy equipment, simple sensors, some industrial |
| 19200, 38400 | Older serial links |
| 57600 | Mid-range serial |
| 115200 | Very common: debug consoles, many USB–serial adapters, development |
| 230400, 460800, 921600 | Higher-speed serial where supported |

Both sides **must** be configured for the same baud rate and frame format (e.g. 8N1).

---

## 11. Where UART Is Used

- **Serial console / debug**: Many boards expose a UART (TTL or RS-232) for a “serial console” to log messages and run a shell.
- **Legacy PC**: Classic “COM port” (RS-232) is UART-based.
- **MCU ↔ sensor / GPS**: Many sensors and GPS modules output data over UART (e.g. NMEA sentences).
- **Board-to-board**: Simple link between two FPGAs or between MCU and FPGA.
- **Bootloaders**: MCUs often use UART to load firmware during development.

So UART is a **general-purpose, simple serial link** when you don’t need a shared clock or multi-drop bus.

---

## 12. UART vs SPI vs I²C (Brief)

| | UART | SPI | I²C |
|---|------|-----|-----|
| **Clock** | No clock line (async) | Clock line (SCLK) from master | Shared clock (SCL) |
| **Wires** | TX + RX (2 for full-duplex) | SCLK, MOSI, MISO, CS_N (3–4+) | SCL + SDA (2) |
| **Topology** | Point-to-point | Master + slaves (CS per slave) | Multi-master/multi-slave bus |
| **Speed** | Limited by baud (e.g. 115200) | Often MHz | 100 / 400 kHz typical |
| **Complexity** | Simple framing (start/data/stop) | Simple, but needs CS and clock | More complex (START/STOP, address, ACK) |

UART is the **simplest** in terms of framing (no clock, no address); you just agree on baud and format.

---

## 13. How This Maps to Our RTL (Modules 3 and 4)

In this repo:

- **baud_gen**: Divides the system clock to produce **baud_tick** (one pulse per bit time). Implements the “agreed baud rate” in hardware.
- **uart_tx**: Implements the TX behavior above: start bit (0), 8 data bits (LSB first), stop bit (1); **busy** during the frame.
- **uart_rx**: Implements the RX behavior: detect start (line low), sample on baud_tick, reconstruct 8 bits, **data_valid** and **data_out**; optional **framing_error** if stop bit is wrong.

The **baseline testbench** (Module 3) connects TX output to RX input (loopback), sends bytes, and checks that the same bytes are received. The **UVM testbench** (Module 4) uses the same DUT and adds a UVM agent (transaction = one byte, driver drives start/data, monitor observes the line, scoreboard compares expected vs observed).

---

## 14. Summary

- **UART** = Universal Asynchronous Receiver/Transmitter: **serial**, **asynchronous**, **point-to-point**, **character-oriented** (one frame = one byte + start + stop).
- **No clock line**: Both sides use the **start bit** to sync and a **baud rate** (bits per second) to time bits. A **baud generator** turns the system clock into one tick per bit.
- **Frame (8N1)**: Idle high → **start (0)** → **8 data bits (LSB first)** → **stop (1)** → idle. 10 bit times per byte.
- **TX** sends that sequence; **RX** detects start, samples at bit times, and reconstructs the byte.
- Used for consoles, debug, sensors, and simple links. In this course it maps to **baud_gen**, **uart_tx**, and **uart_rx** in Module 3, and to a full UVM agent in Module 4.

Once this is clear, you can follow [Module 3](MODULE3.md) (UART RTL + baseline test) and [Module 4](MODULE4.md) (UART UVM) with a solid understanding of what UART is and how it works.
