# Module 2: Design & Verification Methodology (Part 2)

**Goal**: Understand basic testbench patterns (directed tests, pin wiggling), the evolution to a UVM+SV testbench (agents, sequences, drivers, monitors, scoreboards), and the toolchain (Verilator, UVM_HOME, Make).

---

## Navigation

[← Previous: Module 1: Methodology (Part 1)](MODULE1.md) | [Next: Module 3: UART →](MODULE3.md)

[↑ Back to README](../README.md)

---

## Running Module 2

This module focuses on **verification methodology** and **toolchain** (no UART/SPI/I²C yet—those start in Module 3).

- **Module doc**: [module2/README.md](../module2/README.md)
- **Example**: [module2/examples/uvm_smoke/](../module2/examples/uvm_smoke/) — tiny DUT + full UVM test (transaction, sequence, driver, monitor, scoreboard)

**Quick run** (from repo root):

```bash
cd module2/examples/uvm_smoke
make SIM=verilator TEST=test_uvm_smoke
```

Or use the module script:

```bash
./scripts/module2.sh --run
```

- **Slides & video**: [slides.pptx](../media/module2/slides.pptx) · [slides.pdf](../media/module2/slides.pdf) · [video.mp4](../media/module2/video.mp4) — regenerate: `./scripts/build_all_media.sh --module 2`

---

## Overview

Module 2 builds on Module 1 (spec → RTL) by focusing on **how we verify**:

1. **Basic testbench**: Directed tests, pin wiggling — drive inputs, check outputs. (You saw a minimal version in Module 1’s spec_to_rtl C++ harness.)
2. **UVM+SV**: A structured testbench with **transactions**, **sequences**, **drivers**, **monitors**, and **scoreboards** — the same pattern used for UART/SPI/I²C in later modules.
3. **Toolchain**: Verilator + UVM_HOME + Make — build and run a UVM test on RTL.

### What You'll Learn

- **Basic TB vs UVM**: From “wiggle pins and check” to “transaction → sequence → driver/monitor → scoreboard.”
- **UVM building blocks**: Transaction (sequence item), sequence, driver, monitor, scoreboard, agent, env, test.
- **Toolchain**: UVM_HOME, include paths, Verilator flags (`-sv`, `--timing`, `--trace`), and `make SIM=verilator TEST=...`.

### Prerequisites

- **Module 1** completed (spec → RTL flow, spec_to_rtl example run).
- **Verilator** (5.036+)
- **GNU Make** and **C++ compiler**
- **UVM**: UVM_HOME set (must contain `src/uvm_pkg.sv`) or vendored UVM in the repo (see uvm_smoke Makefile)

---

## Topics Covered

### 1. Basic Testbench (Directed Tests, Pin Wiggling)

- **Directed test**: Drive specific inputs (e.g., reset, then a fixed sequence of data) and check expected outputs (e.g., register value, count).
- **Pin wiggling**: The testbench directly drives and samples DUT pins (clock, reset, data, enable) — no transaction layer yet.
- **Relation to Module 1**: The spec_to_rtl example used a C++ harness to drive clk/rst_n/enable and check count; that’s a minimal directed test. Here we keep the same idea but structure it with UVM (transactions, driver, monitor, scoreboard).

### 2. Evolution to UVM+SV Testbench

- **Transaction** (`uvm_sequence_item`): Represents “one operation” (e.g., one write to a register: data + enable). The sequence produces transactions; the driver turns them into pin activity; the monitor turns pin activity back into transactions.
- **Sequence**: Produces a stream of transactions (e.g., a few directed values: 0x00, 0x01, 0x55, 0xAA, 0xFF). Can be deterministic (directed) or random (later).
- **Driver**: Gets transactions from the sequencer and drives the DUT interface (e.g., set enable and d on the bus, wait for clock).
- **Monitor**: Observes the DUT interface and turns pin activity into transactions, then sends them to the scoreboard via an analysis port.
- **Scoreboard**: Compares “expected” (what we sent) vs “observed” (what the monitor saw). Reports matches/mismatches.
- **Agent**: Groups driver, monitor, and sequencer for one interface. **Env**: Contains agent(s) and scoreboard. **Test**: Builds the env, starts the sequence, raises/drops objections.

This structure scales: for UART (Module 4), SPI (Module 6), and I²C (Module 8) you will have a protocol-specific transaction, sequence, driver, monitor, and scoreboard, but the same UVM pattern.

### 3. Toolchain (Verilator, UVM_HOME, Make)

- **Verilator**: Compiles SystemVerilog (including UVM) + C++ into an executable. Key flags: `-sv`, `--timing`, `--trace`, `--binary`, include paths for UVM.
- **UVM_HOME**: Points to the UVM library root; the build uses `$(UVM_HOME)/src/uvm_pkg.sv` and `+incdir+$(UVM_HOME)/src`. If not set, the uvm_smoke Makefile can fall back to a vendored UVM under `tools/`.
- **Make**: One target to compile (Verilator + make in obj_dir), one to run (`./obj_dir/Vtest_uvm_smoke +UVM_TESTNAME=...`). Same pattern for UART/SPI/I²C UVM tests later.

---

## Example: uvm_smoke

The example in [module2/examples/uvm_smoke/](../module2/examples/uvm_smoke/) demonstrates:

| Component   | Role |
|------------|------|
| **DUT**    | `dut/simple_register.v` — tiny register (clk, rst_n, enable, d, q). |
| **Interface** | `reg_if` — connects testbench to DUT. |
| **Transaction** | `RegTransaction` — data + enable + observed_q. |
| **Sequence** | `RegSequence` — produces 5 directed transactions (0x00, 0x01, 0x55, 0xAA, 0xFF). |
| **Driver** | `RegDriver` — drives enable and d from transaction; waits for clock. |
| **Monitor** | `RegMonitor` — samples enable, d, q each cycle; writes transaction to scoreboard. |
| **Scoreboard** | `RegScoreboard` — compares expected vs observed; reports matches/mismatches. |
| **Test**     | `RegTest` — builds env, queues expected values, starts sequence, objections. |

Run it:

```bash
cd module2/examples/uvm_smoke
make SIM=verilator TEST=test_uvm_smoke
```

You should see UVM phases, DRIVER/MONITOR/SCOREBOARD messages, and a final scoreboard summary.

---

## Command Reference

### Environment checks

```bash
verilator --version
make --version
echo "$UVM_HOME"
ls "$UVM_HOME/src/uvm_pkg.sv"
```

### Build and run uvm_smoke

```bash
cd module2/examples/uvm_smoke
make SIM=verilator TEST=test_uvm_smoke
```

### Module script (from repo root)

```bash
./scripts/module2.sh --check   # Environment + UVM + example dirs
./scripts/module2.sh --run     # Run uvm_smoke
./scripts/module2.sh --help    # Options
```

---

## Learning Outcomes

By the end of Module 2, you should be able to:

- Explain **basic testbench** (directed tests, pin wiggling) and how it evolves into **UVM** (transaction, sequence, driver, monitor, scoreboard).
- Describe the role of **transaction**, **sequence**, **driver**, **monitor**, **scoreboard**, **agent**, **env**, and **test** in a UVM testbench.
- Run the **uvm_smoke** example (make SIM=verilator TEST=test_uvm_smoke) and interpret UVM output.
- Use the **toolchain**: Verilator, UVM_HOME, Make; know why `-sv`, `--timing`, and include paths are needed.
- Be ready for **Module 3**: UART protocol + RTL + basic (non-UVM) testbench.

---

## Exercises

1. **Run uvm_smoke**
   - Run `make SIM=verilator TEST=test_uvm_smoke` in module2/examples/uvm_smoke. Confirm you see DRIVER, MONITOR, SCOREBOARD messages and a final “Matches: 5, Mismatches: 0” (or similar).

2. **Traceability**
   - Open test_uvm_smoke.sv. For one transaction (e.g., 0x55), trace: sequence creates it → driver drives enable/d → DUT updates q → monitor samples q → scoreboard compares. Map each step to the corresponding class and method.

3. **Change the sequence**
   - Add or change one value in RegSequence (e.g., add 0x11). Update the expected queue in RegTest’s run_phase to match. Re-run and confirm the scoreboard still passes.

4. **Optional: Waveforms**
   - If the Makefile enables `--trace`, inspect the generated VCD. Identify clk, rst_n, enable, d, q and confirm they match the sequence.

---

## Assessment

- [ ] Can explain basic TB vs UVM (transaction, sequence, driver, monitor, scoreboard).
- [ ] Can describe the role of UVM_HOME, Verilator flags, and Make in building/running a UVM test.
- [ ] Can run uvm_smoke and interpret the output.
- [ ] Ready to move to Module 3 (UART protocol + RTL + basic testbench).

---

## Next Steps

After completing this module, proceed to **Module 3: UART** — UART protocol details, translating protocol to RTL (TX/RX, baud gen), RTL implementation, and **basic** (non-UVM or minimal SV) testbench. UVM verification for UART follows in Module 4.
