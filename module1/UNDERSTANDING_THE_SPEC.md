# Understanding the Specification (Beginner's Guide)

This guide helps you **read and understand** a hardware specification so that you know exactly what to build before writing any RTL.

---

## 1. What Is a Specification?

A **specification** (or "spec") is a written description of **what** a block must do—its interface, behavior, and timing—without saying **how** it is implemented. Think of it as a contract:

- The **designer** implements RTL that satisfies the spec.
- The **verification engineer** writes tests that check the RTL against the spec.
- Anyone can **review** the spec to agree on requirements before implementation.

A good spec answers: *What are the inputs and outputs? What happens on reset? What happens on each clock when control signals change?*

---

## 2. What to Look For in a Spec

When you open a spec, look for these four areas. Not every spec will label them explicitly, but the information is usually there.

### 2.1 Interface (Ports and Signals)

**What it is**: The list of inputs and outputs of the block—names, direction (input/output), and width (e.g., 1 bit, 8 bits).

**Why it matters**: This becomes the **port list** of your RTL module. Get it wrong and the block cannot connect to the rest of the system.

**Questions to answer**:

- What is the **clock**? (Almost every synchronous block has one.)
- Is there a **reset**? **Active high or active low?** (e.g., `rst_n` = 0 means reset.)
- What **control** signals are there? (e.g., enable, valid, ready.)
- What **data** goes in and out? (e.g., 8-bit count, 32-bit data bus.)
- What is the **bit width** of each signal? (1 bit, 8 bits, 32 bits, etc.)

**Example** (from our counter spec):

| Port     | Direction | Width | Meaning        |
|----------|-----------|--------|----------------|
| `clk`    | input     | 1      | Clock          |
| `rst_n`  | input     | 1      | Reset (0 = reset) |
| `enable` | input     | 1      | Count when high |
| `count`  | output    | 8      | Current value  |

From this you know: one clock, one active-low reset, one enable, and an 8-bit output. That’s your module’s port list.

---

### 2.2 Behavior (What the Block Does)

**What it is**: A description of **when** and **how** outputs (and internal state) change. Usually described in terms of:

- **Reset**: What happens when reset is asserted? (e.g., count goes to 0.)
- **Normal operation**: What happens on each clock when reset is released? (e.g., if enable is high, count increments.)
- **Edge cases**: What happens at boundaries? (e.g., when count is 255 and we increment, it wraps to 0.)

**Why it matters**: This becomes the **logic** inside your RTL (e.g., `always @(posedge clk)` with `if (reset) ... else if (enable) ...`).

**Questions to answer**:

- What is the **reset value** of every output (and important internal register)?
- What is the **priority** of actions? (Typically: reset first, then enable/valid, then hold.)
- What are the **conditions** for each action? (e.g., “increment only when enable is high”.)
- Are there **boundaries**? (e.g., “after 255, next value is 0” = wrap.)

**Example** (from our counter spec):

- **Reset**: When `rst_n` is low, `count` becomes 0.
- **Count**: When `rst_n` is high and `enable` is high, `count` increments by 1.
- **Hold**: When `enable` is low, `count` does not change.
- **Wrap**: When `count` is 255, the next increment makes it 0.

So in RTL you will have: (1) reset branch, (2) increment branch, (3) implicit hold when neither applies.

---

### 2.3 Timing (When Things Happen)

**What it is**: When do inputs get sampled and when do outputs change? Most simple blocks are **synchronous**: everything happens on a **clock edge** (e.g., positive edge of `clk`).

**Why it matters**: You need to know whether to use `always @(posedge clk)` (synchronous) or `always @(*)` (combinational), and whether reset is synchronous or asynchronous.

**Questions to answer**:

- Is the block **synchronous** (clocked) or **combinational** (no clock)?
- Which **clock edge** is active? (Usually rising edge.)
- Is reset **synchronous** (only on clock edge) or **asynchronous** (takes effect immediately)?
- Do outputs change **only on the clock edge**, or can they change between edges? (For a register, they change only on the edge.)

**Example** (from our counter spec):

- “All behavior is synchronous to the positive edge of `clk`.”  
  → Use `always @(posedge clk)`.
- “Active-low **synchronous** reset.”  
  → Reset is checked inside the same `always @(posedge clk)` block; no `negedge rst_n` in the sensitivity list.

---

### 2.4 Edge Cases and Assumptions

**What it is**: Unusual or boundary situations: full/empty, wrap-around, first cycle after reset, and what the spec **does not** define (e.g., “don’t care” or “undefined”).

**Why it matters**: These often hide bugs. Making them explicit in the spec (and in tests) avoids surprises.

**Questions to answer**:

- What happens at **max value**? (e.g., 255 → 0 for an 8-bit counter.)
- What if two control signals are active at once? (Spec should define priority.)
- Are there **illegal** input combinations? (If so, spec may say “undefined” or “don’t care”.)
- **Power-on**: Does the spec assume a reset at startup? (Usually yes.)

**Example** (from our counter spec):

- “If `count` is 255, the next increment wraps to 0.”  
  → Explicit edge case; RTL must implement wrap (e.g., 8-bit addition does this automatically).

---

## 3. A Simple Reading Checklist

Before you start writing RTL, you should be able to answer:

1. **Interface**: What are all the ports (name, direction, width)?  
   → You can draw the block or write the module header.

2. **Reset**: What is the reset signal and polarity? What value does every output (and key state) have after reset?  
   → You can write the reset branch.

3. **Clock**: Which edge is used? Synchronous or asynchronous reset?  
   → You know the sensitivity list and reset style.

4. **Normal operation**: What happens when reset is released? In what order (priority)?  
   → You can write the rest of the `always` block.

5. **Edge cases**: What happens at boundaries (e.g., wrap, full, empty)?  
   → You know what to implement and what to test.

If the spec doesn’t answer one of these, **ask** (or document an assumption) before implementing.

---

## 4. Next Step: Translating Spec to RTL

Once you understand the spec, the next step is to **translate** it into RTL. See:

- **[SPEC_TO_RTL_GUIDE.md](SPEC_TO_RTL_GUIDE.md)** — General method: how to go from spec sections to RTL constructs.
- **[examples/spec_to_rtl/WALKTHROUGH.md](examples/spec_to_rtl/WALKTHROUGH.md)** — Concrete example: our counter spec line-by-line to RTL.

These guides show how to turn “what the spec says” into “what you write in Verilog.”
