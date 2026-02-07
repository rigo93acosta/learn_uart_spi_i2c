# Module 2 Examples

Hands-on examples for **basic testbench → UVM+SV** and toolchain (Verilator, UVM_HOME, Make).

---

## 1. UVM smoke test (`examples/uvm_smoke/`)

A minimal **UVM test** that compiles and runs on Verilator: tiny DUT (simple register) + full UVM structure (transaction, sequence, driver, monitor, scoreboard).

**Run it** (from repo root):

```bash
cd module2/examples/uvm_smoke
make SIM=verilator TEST=test_uvm_smoke
```

Or use the module script:

```bash
./scripts/module2.sh --run
```

**What you'll see**:

- UVM phases and reporting (DRIVER, MONITOR, SCOREBOARD messages).
- Directed sequence: a few data values (0x00, 0x01, 0x55, 0xAA, 0xFF) driven and checked.
- Final scoreboard summary (matches/mismatches).

See [examples/uvm_smoke/README.md](examples/uvm_smoke/README.md) for layout and prerequisites.

---

## 2. (Reference) UVM examples in tools

This repo also includes UVM-on-Verilator demos you can run directly:

**UVM class hierarchy**:

```bash
cd tools/learn_uvm2017_sv_verilator/module3/examples/class_hierarchy
verilator -sv --cc --exe --timing --trace \
  -I"$UVM_HOME/src" +incdir+"$UVM_HOME/src" +define+UVM_NO_DPI \
  --binary "$UVM_HOME/src/uvm_pkg.sv" class_hierarchy.sv class_hierarchy.cpp \
  --top-module class_hierarchy
make -C obj_dir -f Vclass_hierarchy.mk
./obj_dir/Vclass_hierarchy
```

**UVM phases**:

```bash
cd tools/learn_uvm2017_sv_verilator/module3/examples/phases
# (similar Verilator command; see that directory's README)
```

These show the same toolchain (Verilator + UVM) used in `uvm_smoke`.
