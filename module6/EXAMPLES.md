# Module 6 Examples

Hands-on examples for **SPI UVM+SV** verification.

---

## 1. SPI UVM (`examples/spi_uvm/`)

SPI master RTL (same DUT as Module 5) with a **full UVM testbench**: SPI transaction, sequence, driver, monitor, scoreboard; directed sequence (0x00, 0x01, 0x55, 0xAA, 0xFF); monitor samples MOSI on SCLK and scoreboard compares expected vs observed.

**Run it** (from repo root):

```bash
cd module6/examples/spi_uvm
make SIM=verilator TEST=test_spi_uvm
```

Or use the module script:

```bash
./scripts/module6.sh --run
```

**What you'll see**:

- UVM phases and reporting (DRIVER, MONITOR, SCOREBOARD).
- Scoreboard checks (expected byte from sequence vs observed byte on MOSI).
- Final scoreboard summary (matches and mismatches).

See [examples/spi_uvm/README.md](examples/spi_uvm/README.md) for layout and prerequisites.

---

## 2. (Reference) Module 5 SPI baseline

The **basic** (non-UVM) SPI test is in Module 5: [module5/examples/spi_baseline/](../module5/examples/spi_baseline/). Module 6 reuses the same DUT and adds the UVM agent.
