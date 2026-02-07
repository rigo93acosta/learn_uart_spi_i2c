# Specification: 8-bit Up-Counter

**Purpose**: Minimal block to demonstrate the **specification → RTL** flow in Module 1.

---

## How to Read This Spec (Beginners)

If you are new to reading hardware specs, use this document in order:

1. **Interface (Section 2)** — Tells you every port: name, direction (input/output), and width. This becomes your module’s port list in RTL.
2. **Behavior (Section 3)** — Tells you what happens on reset, when to increment, and when to hold. This becomes the logic inside an `always` block (reset first, then enable, then hold).
3. **Timing (Section 4)** — Tells you that everything is synchronous to the positive edge of `clk`. That tells you to use `always @(posedge clk)` and no combinational logic for the counter output.

For a step-by-step guide on **understanding any spec**, see [module1/UNDERSTANDING_THE_SPEC.md](../../UNDERSTANDING_THE_SPEC.md).  
For **translating this spec into RTL**, see [module1/SPEC_TO_RTL_GUIDE.md](../../SPEC_TO_RTL_GUIDE.md) and [WALKTHROUGH.md](WALKTHROUGH.md).

---

## 1. Overview

- **Block name**: `counter`
- **Function**: 8-bit up-counter with synchronous reset and enable. Counts from 0 to 255 and wraps to 0.

---

## 2. Interface

| Port   | Direction | Width | Description                                      |
|--------|-----------|--------|--------------------------------------------------|
| `clk`  | input     | 1      | Clock; positive edge is active.                  |
| `rst_n`| input     | 1      | Active-low synchronous reset.                    |
| `enable` | input   | 1      | When high, counter increments on the next clk.   |
| `count`| output    | 8      | Current count value (0–255).                     |

---

## 3. Behavior

- **Reset**: On the rising edge of `clk`, if `rst_n` is low, `count` is set to `8'h00` and remains until `rst_n` goes high.
- **Count**: On the rising edge of `clk`, if `rst_n` is high and `enable` is high, `count` increments by 1. If `count` is 255, the next increment wraps to 0.
- **Hold**: If `enable` is low (and not in reset), `count` does not change.

---

## 4. Timing

- All behavior is synchronous to the positive edge of `clk`.
- No multi-cycle or combinational paths are specified; implementation is single-cycle update.

---

## 5. Use in This Course

This spec is intentionally small so that:

1. **Spec → RTL**: You can map each requirement to RTL (reset, enable, increment, width).
2. **Verification**: A simple testbench can drive clk/reset/enable and check that `count` matches expectations (e.g., after N enabled cycles, count = N mod 256).
3. **Methodology**: The same flow (spec → RTL → testbench) applies to UART, SPI, and I²C in later modules.
