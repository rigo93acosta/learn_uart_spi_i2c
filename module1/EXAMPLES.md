# Module 1 Examples

Hands-on examples for **specification → RTL design flow** and methodology (no UVM in this module).

**New to specs and RTL?** Read [UNDERSTANDING_THE_SPEC.md](UNDERSTANDING_THE_SPEC.md) and [SPEC_TO_RTL_GUIDE.md](SPEC_TO_RTL_GUIDE.md) first, then follow [examples/spec_to_rtl/WALKTHROUGH.md](examples/spec_to_rtl/WALKTHROUGH.md) with the counter example.

---

## 1. Spec-to-RTL example (`examples/spec_to_rtl/`)

A minimal example that demonstrates the full flow:

1. **Spec** — [examples/spec_to_rtl/SPEC.md](examples/spec_to_rtl/SPEC.md): short written specification for an 8‑bit up-counter
2. **RTL** — [examples/spec_to_rtl/dut/counter.v](examples/spec_to_rtl/dut/counter.v): Verilog implementation of that spec
3. **Testbench** — RTL is wrapped in a top and driven by a C++ harness; simulation checks basic behavior

**Run it** (from repo root):

```bash
cd module1/examples/spec_to_rtl
make run
```

Optional: enable VCD tracing and open in a waveform viewer:

```bash
make run TRACE=1
# Then e.g. gtkwave spec_to_rtl.vcd
```

**Learn how to read the spec and translate it to RTL**:

- [examples/spec_to_rtl/WALKTHROUGH.md](examples/spec_to_rtl/WALKTHROUGH.md) — Section-by-section reading of SPEC.md and mapping to dut/counter.v.

See [examples/spec_to_rtl/README.md](examples/spec_to_rtl/README.md) for more.

---

## 2. (Reference) Verilator RTL-only examples

For a minimal Verilator “hello world” (no DUT, just C++ + top):

```bash
cd tools/learn_uvm2017_sv_verilator/tools/verilator/examples/make_hello_c
make
```

For a Verilator example with clock, reset, and tracing:

```bash
cd tools/learn_uvm2017_sv_verilator/tools/verilator/examples/make_tracing_c
make run
```

These show the same toolchain (Verilator + C++ harness) used in `spec_to_rtl`, without UVM.
