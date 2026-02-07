# Module 5 Examples

Hands-on examples for **SPI protocol + RTL + basic testbench** (no UVM in this module).

---

## 1. SPI baseline (`examples/spi_baseline/`)

SPI master RTL with a **basic directed testbench**: clk_div + spi_master; directed transfers (e.g. 0x55, 0xAA); wait for done; no UVM.

**Run it** (from repo root):

```bash
cd module5/examples/spi_baseline
make run
```

Or use the module script:

```bash
./scripts/module5.sh --run
```

**Contents**:

- `dut/`: `spi_master.v`, `clk_div.v`
- `top_spi_baseline.sv`: Top with clk_div, spi_master; directed stimulus and checks in initial blocks.
- `sim_main.cpp`: C++ harness (clock, reset); simulation runs until `$finish`.

See [examples/spi_baseline/README.md](examples/spi_baseline/README.md) for layout and requirements.

---

## 2. (Reference) SPI UVM

Full SPI UVM verification (agent, sequences, driver, monitor, scoreboard) is in **Module 6** (`module6/examples/spi_uvm/`). Module 5 focuses on protocol + RTL + basic TB only.
