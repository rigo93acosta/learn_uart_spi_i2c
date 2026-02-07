# Translating Specification to RTL (Beginner's Guide)

This guide explains **how to turn a specification into RTL** in a structured way. Use it after you have read and understood the spec (see [UNDERSTANDING_THE_SPEC.md](UNDERSTANDING_THE_SPEC.md)).

---

## 1. The Big Picture

Translation follows the **same order** you use when reading the spec:

1. **Interface** → Module declaration and port list.
2. **Timing** → Choice of `always` block (e.g., `always @(posedge clk)`).
3. **Reset** → First branch inside the block (what happens when reset is active).
4. **Normal behavior** → Remaining branches (enable, increment, hold, etc.).
5. **Edge cases** → Same blocks (e.g., wrap is often “free” with the right width).

You implement **one concern at a time** and keep a clear mapping: *this line of RTL implements this sentence in the spec*.

---

## 2. Step 1: Interface → Module and Ports

**From the spec**: The “Interface” or “Ports” section lists every input and output with direction and width.

**In RTL**: Write the module name and port list. Use the **exact** names and widths from the spec so that verification and integration don’t break.

| Spec says              | RTL you write                          |
|------------------------|----------------------------------------|
| input, 1 bit            | `input wire sig_name` or `input wire sig_name` |
| output, 8 bits         | `output reg [7:0] count` (if it’s a register) or `output wire [7:0] count` |
| Clock                  | `input wire clk`                       |
| Active-low reset       | `input wire rst_n`                     |

**Rule of thumb**: Outputs that **hold state** (e.g., a counter value) are `output reg` and are assigned in an `always` block. Outputs that are pure combinational logic can be `output wire` and assigned with `assign`.

**Example** (counter):

- Spec: `clk` (input, 1), `rst_n` (input, 1), `enable` (input, 1), `count` (output, 8).
- RTL: `module counter ( input wire clk, input wire rst_n, input wire enable, output reg [7:0] count );`

---

## 3. Step 2: Timing → Choose the Always Block

**From the spec**: Look for “synchronous to the positive edge of clk” or “on the rising edge.” That tells you:

- Use a **clocked** `always` block: `always @(posedge clk)`.
- All registered outputs (like `count`) are updated **only** in this block.

If the spec says **asynchronous reset** (e.g., “reset takes effect immediately”), the sensitivity list includes the reset edge, e.g. `always @(posedge clk or negedge rst_n)`. If it says **synchronous reset**, only the clock is in the sensitivity list: `always @(posedge clk)`.

**Example** (counter with synchronous reset):

- Spec: “All behavior is synchronous to the positive edge of clk” and “active-low **synchronous** reset.”
- RTL: `always @(posedge clk) begin ... end`  
  No `negedge rst_n` in the list; reset is evaluated **inside** the block on each clock edge.

---

## 4. Step 3: Reset → First Branch in the Always Block

**From the spec**: “When reset is asserted, output X is 0” (or whatever the reset values are).

**In RTL**: Make reset the **first** condition in the block. Use the same polarity as the spec (e.g., `if (!rst_n)` for active-low).

```verilog
always @(posedge clk) begin
    if (!rst_n) begin
        count <= 8'h00;   // or whatever the spec says
    end
    else ...
end
```

**Why first?** So that nothing else (enable, increment, etc.) can override reset. Reset has **highest priority**.

**Checklist**: For every output (and important internal register), assign the **exact** reset value the spec requires (same width and value, e.g. `8'h00` for an 8-bit zero).

---

## 5. Step 4: Normal Behavior → Remaining Branches

**From the spec**: “When reset is not asserted, if enable is high, count increments; otherwise count holds.”

**In RTL**: After the reset branch, use `else if` (and possibly `else`) for each case. Order of branches = **priority** (same as in the spec).

Typical pattern:

```verilog
always @(posedge clk) begin
    if (!rst_n)
        count <= 8'h00;
    else if (enable)
        count <= count + 8'd1;
    // else: hold (no write to count, so it keeps its value)
end
```

**Mapping**:

- “If enable is high, increment” → `else if (enable) count <= count + 8'd1;`
- “If enable is low, hold” → no assignment to `count` in that case; the register keeps its value.

**Width**: Use the same width as the spec (e.g., 8-bit counter → `8'd1`, `[7:0] count`). That way wrap (255 → 0) is automatic and matches the spec.

---

## 6. Step 5: Edge Cases (Wrap, Boundaries)

**From the spec**: “If count is 255, the next increment wraps to 0.”

**In RTL**: For an 8-bit register, `count + 8'd1` when `count == 255` already gives 0 in Verilog (unsigned wrap). So you **don’t** need an extra `if (count == 255) count <= 0`. The spec’s edge case is satisfied by correct width and a single increment.

For other blocks you might need explicit logic (e.g., “if full, do not increment”). The key is: **one edge case in the spec → one place in the RTL (or one decision)** that implements it.

---

## 7. Traceability: Spec ↔ RTL

As you write RTL, keep a mental (or written) map:

| Spec section / sentence | RTL location |
|-------------------------|--------------|
| Interface table         | Module port list |
| “Synchronous to posedge clk” | `always @(posedge clk)` |
| “When rst_n is low, count is 0” | `if (!rst_n) count <= 8'h00;` |
| “When enable is high, increment” | `else if (enable) count <= count + 8'd1;` |
| “When enable is low, hold” | No assignment in else branch |
| “255 wraps to 0”       | 8-bit addition (implicit) |

If someone asks “where do we implement X?”, you should be able to point to a specific line or block. If the spec is updated, you know exactly which RTL to change.

---

## 8. Summary: Order of Work

1. **Ports** from the interface table → module declaration.
2. **Clock and reset type** → sensitivity list and reset style.
3. **Reset values** → first branch in the `always` block.
4. **Normal behavior** → `else if` / `else` branches in priority order.
5. **Edge cases** → either implicit (e.g., wrap) or one explicit condition.
6. **Traceability** → every requirement in the spec has a corresponding RTL place.

---

## 9. Apply It: Counter Example

A full walkthrough of the **counter** spec turned into RTL—with each spec sentence mapped to the exact line of Verilog—is in:

- **[examples/spec_to_rtl/WALKTHROUGH.md](examples/spec_to_rtl/WALKTHROUGH.md)**

Open [SPEC.md](examples/spec_to_rtl/SPEC.md), [dut/counter.v](examples/spec_to_rtl/dut/counter.v), and the walkthrough side by side to see the translation in practice.
