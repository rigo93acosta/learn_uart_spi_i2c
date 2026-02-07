# I2C Baseline Example (Module 7)

Simple, teaching-oriented I2C master RTL with a **basic directed testbench** (no UVM).

## What this example does

- Generates an I2C-like waveform for a **single write transaction**:
  - START
  - 7-bit address + write bit (0)
  - 8-bit data byte
  - STOP

**Note**: This is a simplified model that treats SCL/SDA as push-pull outputs (not full open-drain, no ACK/NACK, no arbitration).

## Layout

| File / Dir | Role |
|------------|------|
| **dut/i2c_master.v** | Baseline write-only I2C master |
| **dut/clk_div.v** | Divider producing `clk_div_tick` for SCL timing |
| **top_i2c_baseline.sv** | Instantiates DUT + directed stimulus + simple bus monitor/self-check |
| **sim_main.cpp** | C++ harness drives clk and rst_n until `$finish` |
| **Makefile** | Verilator build/run |

## Run

```bash
cd module7/examples/i2c_baseline
make run
```

Or from repo root:

```bash
./scripts/module7.sh --run
```

## Success

The run should print:

- `[PASS] I2C baseline: write transaction observed correctly`
- `I2C baseline test PASS`
