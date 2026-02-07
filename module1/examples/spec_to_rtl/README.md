# Spec-to-RTL Example (Module 1)

A minimal **specification → RTL → simulation** flow: an 8-bit up-counter.

## Contents

| Item   | Description |
|--------|-------------|
| [SPEC.md](SPEC.md) | Written specification for the counter (with a short "How to read this spec" for beginners) |
| [dut/counter.v](dut/counter.v) | RTL implementation of the spec |
| [top.v](top.v) | Top-level wrapper (instantiates counter; C++ drives I/O) |
| [sim_main.cpp](sim_main.cpp) | C++ test harness: clock, reset, enable, and a simple check |
| [Makefile](Makefile) | Build and run with Verilator |
| [WALKTHROUGH.md](WALKTHROUGH.md) | **Beginner-friendly**: section-by-section reading of SPEC.md and mapping to counter.v |

**New to specs?** Read [module1/UNDERSTANDING_THE_SPEC.md](../../UNDERSTANDING_THE_SPEC.md) and [module1/SPEC_TO_RTL_GUIDE.md](../../SPEC_TO_RTL_GUIDE.md), then follow [WALKTHROUGH.md](WALKTHROUGH.md) with this example.

## Flow

1. **Spec** — [SPEC.md](SPEC.md) defines interface and behavior (clk, rst_n, enable, count).
2. **RTL** — [dut/counter.v](dut/counter.v) implements that behavior in Verilog.
3. **Test** — [sim_main.cpp](sim_main.cpp) drives the DUT and checks that after 10 enabled cycles, `count == 10`.

No UVM; this is a basic directed test to show that the RTL matches the spec.

## Run

From this directory:

```bash
make run
```

Expected: `[PASS] spec_to_rtl: counter behavior matches spec.`

With VCD tracing (optional):

```bash
make run TRACE=1
# Then e.g. gtkwave spec_to_rtl.vcd
```

## Requirements

- Verilator (5.x)
- GNU Make
- C++ compiler (g++ or clang++)

No UVM or `UVM_HOME` required for this example.
