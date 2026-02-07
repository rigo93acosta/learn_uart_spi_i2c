# Module 7 Examples

Hands-on examples for **I²C protocol + RTL + basic testbench** (no UVM in this module).

---

## 1. I²C baseline (`examples/i2c_baseline/`)

Simple I²C master RTL with a **basic directed testbench**:

- Drives a single write transaction (START → address+W → data → STOP)
- Includes a simple bus monitor that samples SDA on SCL rising edges to reconstruct bytes
- No UVM

**Run it** (from repo root):

```bash
cd module7/examples/i2c_baseline
make run
```

Or use the module script:

```bash
./scripts/module7.sh --run
```

**Contents**:

- `dut/`: `i2c_master.v`, `clk_div.v`
- `top_i2c_baseline.sv`: Top with clk_div + i2c_master; directed stimulus and self-check in initial blocks.
- `sim_main.cpp`: C++ harness (clock, reset); simulation runs until `$finish`.

See [examples/i2c_baseline/README.md](examples/i2c_baseline/README.md) for layout and requirements.

---

## 2. (Reference) I²C UVM

Full I²C UVM verification (agent, sequences, driver, monitor, scoreboard) is in **Module 8** (`module8/examples/i2c_uvm/`). Module 7 focuses on protocol + RTL + basic TB only.

