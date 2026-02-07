# Module 4 Examples

Hands-on examples for **UART UVM+SV** verification.

---

## 1. UART UVM (`examples/uart_uvm/`)

UART TX/RX RTL (same DUT as Module 3) with a **full UVM testbench**: UART transaction, sequence, driver, monitor, scoreboard; loopback TX→RX; directed sequence (0x00, 0x01, 0x55, 0xAA, 0xFF).

**Run it** (from repo root):

```bash
cd module4/examples/uart_uvm
make SIM=verilator TEST=test_uart_uvm
```

Or use the module script:

```bash
./scripts/module4.sh --run
```

**What you'll see**:

- UVM phases and reporting (DRIVER, MONITOR, SCOREBOARD).
- TX and RX scoreboard checks (TX: monitor observes serial line; RX: loopback byte checked via scoreboard).
- Final scoreboard summary (TX/RX matches and mismatches).

See [examples/uart_uvm/README.md](examples/uart_uvm/README.md) for layout and prerequisites.

---

## 2. (Reference) Module 3 UART baseline

The **basic** (non-UVM) UART test is in Module 3: [module3/examples/uart_baseline/](../module3/examples/uart_baseline/). Module 4 reuses the same DUT and adds the UVM agent.
