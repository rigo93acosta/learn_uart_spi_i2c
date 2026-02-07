# Walkthrough: From Counter Spec to RTL

This document walks through the **8-bit up-counter** example step by step: how to read the spec and how each part of the spec becomes a specific part of the RTL. Use it together with [SPEC.md](SPEC.md) and [dut/counter.v](dut/counter.v).

**Before starting**: Read [module1/UNDERSTANDING_THE_SPEC.md](../../UNDERSTANDING_THE_SPEC.md) and [module1/SPEC_TO_RTL_GUIDE.md](../../SPEC_TO_RTL_GUIDE.md) for the general method.

---

## Part A: How to Read This Spec

We go through [SPEC.md](SPEC.md) section by section and turn it into concrete design questions.

### Section 1: Overview

**Spec says**: “Block name: `counter`. Function: 8-bit up-counter with synchronous reset and enable. Counts from 0 to 255 and wraps to 0.”

**What we learn**:

- **Module name**: `counter`.
- **Function**: Count up by 1 on each clock when enabled; 8 bits → 0–255, then wrap to 0.
- **Controls**: Reset and enable (details in Interface and Behavior).

So we will have: one module `counter`, one 8-bit register that increments under enable and wraps.

---

### Section 2: Interface

**Spec says**:

| Port    | Direction | Width | Description                    |
|---------|-----------|--------|--------------------------------|
| `clk`   | input     | 1      | Clock; positive edge active.  |
| `rst_n` | input     | 1      | Active-low synchronous reset. |
| `enable`| input     | 1      | When high, counter increments.|
| `count` | output    | 8      | Current count (0–255).        |

**What we learn**:

- **Clock**: One input, positive-edge-triggered. → RTL will use `always @(posedge clk)`.
- **Reset**: One input, **active-low** (`rst_n`). “Synchronous” → we check reset **inside** the clocked block, not with `negedge rst_n` in the sensitivity list.
- **Enable**: One input; when high we increment. → We need `if (enable)` (or equivalent) for the increment.
- **Output**: 8-bit `count`. It holds state → in RTL it will be a `reg` assigned in the clocked block.

So the RTL will have exactly these four ports, with these directions and widths.

---

### Section 3: Behavior

**Spec says**:

- **Reset**: On rising edge of `clk`, if `rst_n` is low, set `count` to `8'h00` and keep it until `rst_n` goes high.
- **Count**: On rising edge of `clk`, if `rst_n` is high and `enable` is high, increment `count` by 1. If `count` is 255, next increment wraps to 0.
- **Hold**: If `enable` is low (and not in reset), `count` does not change.

**What we learn**:

- **Priority**: Reset has highest priority (handled first). Then “increment when enable”, then “hold” (do nothing).
- **Reset value**: `count` = 0 in reset.
- **Increment**: One per clock when both `rst_n` and `enable` are high.
- **Hold**: No assignment to `count` when enable is low → register keeps its value.
- **Wrap**: 255 → 0. With 8-bit unsigned, 255 + 1 = 0 in Verilog, so no extra logic needed.

So in the `always` block we will have: first `if (!rst_n)`, then `else if (enable) count <= count + 1`, and no `else` (hold by default).

---

### Section 4: Timing

**Spec says**: “All behavior is synchronous to the positive edge of `clk`. No multi-cycle or combinational paths; single-cycle update.”

**What we learn**:

- One `always @(posedge clk)` block.
- No combinational `always @(*)` for `count`; it is a pure register.
- No multi-cycle operations; everything is decided in one clock cycle.

So we use a single clocked block and no other always blocks for `count`.

---

## Part B: How We Translated Spec to RTL

We now map each RTL construct in [dut/counter.v](dut/counter.v) back to the spec.

### 1. Module and ports (Spec: Section 2 — Interface)

**Spec**: Port table (clk, rst_n, enable, count; directions and widths).

**RTL**:

```verilog
module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    output reg  [7:0] count
);
```

- `clk`, `rst_n`, `enable`: inputs, 1 bit each → `input wire`.
- `count`: 8-bit output that holds state → `output reg [7:0]`.

So the **interface** section of the spec becomes this **port list** exactly.

---

### 2. Clock and reset style (Spec: Section 4 — Timing; Section 2 — “synchronous reset”)

**Spec**: “All behavior synchronous to positive edge of clk”; “active-low **synchronous** reset.”

**RTL**:

```verilog
always @(posedge clk) begin
```

- Only `posedge clk` in the sensitivity list → synchronous to rising edge.
- No `negedge rst_n` → reset is **synchronous**; we evaluate it inside the block.

So **timing** and **reset type** from the spec fix the **sensitivity list** and the way we handle reset.

---

### 3. Reset branch (Spec: Section 3 — Reset)

**Spec**: “On rising edge of clk, if rst_n is low, set count to 8'h00.”

**RTL**:

```verilog
    if (!rst_n)
        count <= 8'h00;
```

- “rst_n is low” → `!rst_n` (active-low).
- “set count to 0” → `count <= 8'h00` (8-bit zero).
- This is the **first** branch so reset has highest priority.

So the **reset** behavior in the spec becomes this **first** `if` branch.

---

### 4. Increment and hold (Spec: Section 3 — Count and Hold)

**Spec**: “If rst_n high and enable high, increment by 1”; “if enable low, count does not change.”

**RTL**:

```verilog
    else if (enable)
        count <= count + 8'd1;
```

- “rst_n high and enable high” → we are in the `else` of `if (!rst_n)`, so we only need `else if (enable)`.
- “Increment by 1” → `count <= count + 8'd1` (8-bit constant 1).
- “Enable low, count does not change” → no `else` branch; when `enable` is low we don’t assign `count`, so it holds.

So **count** and **hold** in the spec become this single **else if** and the absence of an else assignment.

---

### 5. Wrap (Spec: Section 3 — “255 wraps to 0”)

**Spec**: “If count is 255, the next increment wraps to 0.”

**RTL**: No extra line. We use an 8-bit register and 8-bit addition:

- `count` is `[7:0]`.
- `count + 8'd1` when `count == 255` gives 256 in math, but in 8-bit unsigned it is 0.

So the **edge case** “255 → 0” is implemented by **correct width** and standard Verilog arithmetic, not by an explicit if.

---

## Part C: Traceability Table

| Spec reference                    | RTL location in counter.v        |
|----------------------------------|----------------------------------|
| Section 2 — Interface            | Lines 6–11: module and ports    |
| Section 4 — Synchronous to clk  | Line 12: `always @(posedge clk)` |
| Section 3 — Reset                | Lines 13–14: `if (!rst_n) count <= 8'h00` |
| Section 3 — Count (increment)    | Lines 15–16: `else if (enable) count <= count + 8'd1` |
| Section 3 — Hold                 | No else branch                  |
| Section 3 — Wrap 255→0          | 8-bit type and `+ 8'd1`         |

You can use this table to **review** the RTL (does every spec item have an implementation?) and to **maintain** it (when the spec changes, you know which lines to change).

---

## Part D: What to Do Next

1. **Run the example**: `make run` in this directory. The testbench checks that after 10 enabled cycles, `count == 10`, which matches the spec.
2. **Change and re-check**: Edit the spec (e.g., “reset to 0xFF”) and change the RTL to match; run `make run` again to see the test fail or pass.
3. **Try another block**: Write a short spec for a different block (e.g., “loadable counter” or “enable-only register”) and translate it to RTL using [SPEC_TO_RTL_GUIDE.md](../../SPEC_TO_RTL_GUIDE.md).

This walkthrough and the two guides in module1 give you a repeatable way to **understand any spec** and **translate it into a design** clearly and safely.
