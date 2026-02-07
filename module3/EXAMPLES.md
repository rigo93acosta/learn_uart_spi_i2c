# Module 3 Examples

Hands-on examples for **UART protocol + RTL + basic testbench** (no UVM in this module).

---

## 1. UART baseline (`examples/uart_baseline/`)

UART TX/RX RTL with a **basic directed testbench**: loopback (TX output → RX input), send a few bytes, check they are received correctly.

**Run it** (from repo root):

```bash
cd module3/examples/uart_baseline
make run
```

Or use the module script:

```bash
./scripts/module3.sh --run
```

**Contents**:

- `dut/`: `uart_tx.v`, `uart_rx.v`, `baud_gen.v`
- `top_uart_baseline.sv`: Top with loopback; directed stimulus and checks in initial blocks.
- `sim_main.cpp`: C++ harness (clock, reset); simulation runs until `$finish`.

See [examples/uart_baseline/README.md](examples/uart_baseline/README.md) for layout and requirements.

---

## 2. (Reference) UART UVM

Full UART UVM verification (agent, sequences, driver, monitor, scoreboard) is in **Module 4** (`module4/examples/uart_uvm/`). Module 3 focuses on protocol + RTL + basic TB only.
