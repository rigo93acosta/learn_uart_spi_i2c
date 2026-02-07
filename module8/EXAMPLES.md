# Module 8 Examples

Hands-on examples for **I²C UVM+SV** verification.

---

## 1. I²C UVM (`examples/i2c_uvm/`)

I²C master RTL (same DUT as Module 7) with a **full UVM testbench**: I2cTransaction, I2cSequence, I2cDriver, I2cMonitor, I2cScoreboard; directed address+data writes; monitor reconstructs address and data from SDA while scoreboard compares expected vs observed.

**Run it** (from repo root):

```bash
cd module8/examples/i2c_uvm
make SIM=verilator TEST=test_i2c_uvm
```

Or use the module script:

```bash
./scripts/module8.sh --run
```

**What you'll see**:

- UVM phases and reporting (DRIVER, MONITOR, SCOREBOARD).
- Scoreboard checks (expected vs observed address+data from the bus).
- Final scoreboard summary (matches and mismatches).

See [examples/i2c_uvm/README.md](examples/i2c_uvm/README.md) for layout and prerequisites.

---

## 2. (Reference) Module 7 I²C baseline

The **basic** (non-UVM) I²C test is in Module 7: [module7/examples/i2c_baseline/](../module7/examples/i2c_baseline/). Module 8 reuses the same DUT and adds the UVM agent.
