# SPI, I²C & UART: Digital Design & UVM Verification

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

A progressive course in digital design and verification covering **UART**, **SPI**, and **I²C** — from specification and RTL through UVM-based verification with Verilator. Each **module** has **README.md** (quick start), **EXAMPLES.md** (index of hands-on examples), and **docs/** (full syllabus). Examples include spec→RTL walkthroughs, baseline RTL + directed tests, and full UVM agents (transaction, sequence, driver, monitor, scoreboard) for each protocol.

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Modules](#-modules)
- [Usage](#-usage)
- [Contributing](#-contributing)
- [License](#-license)
- [Support](#-support)

## 🎯 Overview

This project is a complete educational path for learning digital design and verification in the context of common serial protocols:

- **8 Progressive Modules**: From specification→RTL methodology through UART, SPI, and I²C — each with baseline RTL + basic testbench, then UVM+SV verification
- **Hands-On Examples**: Working RTL and testbenches in each module (spec_to_rtl, uvm_smoke, uart_baseline, uart_uvm, spi_baseline, spi_uvm, i2c_baseline, i2c_uvm)
- **UVM 2017 + Verilator**: Industry-relevant toolchain; UVM agents (transaction, sequence, driver, monitor, scoreboard) for each protocol
- **Full Documentation**: Module docs in `docs/` with topics, learning outcomes, and run instructions
- **Per-Module Scripts**: `scripts/moduleN.sh --run` (and `--check` where applicable) for consistent runs from repo root

### Why UART, SPI & I²C?

- **Common Serial Protocols**: Found in embedded systems, sensors, and SoC peripherals
- **Design Flow**: Specification → RTL → directed test → UVM verification
- **Verification Methodology**: UVM agents, sequences, scoreboards; same patterns scale to larger designs
- **Toolchain**: Verilator + SystemVerilog + UVM 2017; no commercial simulator required for learning

### Learning Approach

- **Methodology First**: Spec→RTL and verification mindset (Module 1–2)
- **Protocol + RTL + Baseline Test**: UART (3), SPI (5), I²C (7) — protocol, RTL, directed testbench
- **UVM Verification**: UART (4), SPI (6), I²C (8) — full UVM agent per protocol
- **Progressive**: Build from a simple counter/spec_to_rtl through UVM smoke to UART/SPI/I²C agents

## ✨ Features

- ✅ **8 Modules**: Spec→RTL methodology, UVM basics, UART/SPI/I²C protocol + RTL + baseline, then UVM for each
- ✅ **Per-Module Layout**: README.md (quick start), EXAMPLES.md (example index), docs/MODULEN.md (syllabus)
- ✅ **Working Examples**: spec_to_rtl, uvm_smoke, uart_baseline, uart_uvm, spi_baseline, spi_uvm, i2c_baseline, i2c_uvm
- ✅ **UVM Agents**: Transaction, sequence, driver, monitor, scoreboard for UART, SPI, and I²C
- ✅ **Verilator + UVM 2017**: Open-source toolchain; UVM library under `tools/uvm-2017/`
- ✅ **Scripts**: `scripts/moduleN.sh --run` (and `--check`) for running examples from repo root
- ✅ **Documentation**: SPEC.md-style specs, walkthroughs, and module docs with topics and run instructions

## 📚 Prerequisites

### Required Knowledge

- **Basic Digital Logic**: Flip-flops, FSMs, synchronous design
- **Verilog or SystemVerilog**: Ability to read/write RTL (modules, always_ff, etc.)
- **Terminal**: Ability to run commands in Linux/macOS/WSL2

### System Requirements

- **Operating System**: Linux, macOS, or Windows (WSL2 recommended)
- **Verilator**: 5.x recommended (`verilator --version`)
- **GNU Make**: For building and running examples
- **C++ Compiler**: GCC or Clang (for Verilator-generated code)
- **UVM**: UVM 2017 sources are included under `tools/uvm-2017/`; set `UVM_HOME` or use the project’s Makefiles

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd spi_i2c_uart
```

### 2. Set Up UVM (if needed)

The repo includes UVM 2017 under `tools/uvm-2017/`. Many example Makefiles set `UVM_HOME` automatically; otherwise:

```bash
export UVM_HOME=$(pwd)/tools/uvm-2017/1800.2-2017-1.0
```

### 3. Run Module 1 (Spec → RTL)

```bash
cd module1/examples/spec_to_rtl
make run
```

Or from repo root:

```bash
./scripts/module1.sh --run
```

### 4. Run a UVM Example (e.g. UART UVM)

```bash
cd module4/examples/uart_uvm
make SIM=verilator TEST=test_uart_uvm
```

Or: `./scripts/module4.sh --run`

### 5. Follow the Modules

Start with [Module 1: Design & Verification Methodology (Part 1)](docs/MODULE1.md) and proceed through the modules. Each module doc has run instructions and links to its examples.

## 📁 Project Structure

```
spi_i2c_uart/
├── docs/                      # Module documentation (syllabus)
│   ├── UART_LEARNING_GUIDE.md               # Detailed UART: what it is, how it works, frame/baud/TX/RX (Modules 3–4)
│   ├── SPI_LEARNING_GUIDE.md                # Detailed SPI: what it is, how it works, signals/modes/Mode 0 (Modules 5–6)
│   ├── I2C_LEARNING_GUIDE.md                # Detailed I²C: what it is, how it works, START/STOP/address/data (Modules 7–8)
│   ├── LEARNING_GUIDE_PROTOCOLS_AND_UVM.md  # UART/SPI/I²C overview + where/how UVM applies (read before Modules 3–8)
│   ├── MODULE1.md             # Spec → RTL, methodology, intro to verification
│   ├── MODULE2.md             # UVM basics, testbench patterns, toolchain
│   ├── MODULE3.md             # UART protocol + RTL + baseline test
│   ├── MODULE4.md             # UART UVM+SV verification
│   ├── MODULE5.md             # SPI protocol + RTL + baseline test
│   ├── MODULE6.md             # SPI UVM+SV verification
│   ├── MODULE7.md             # I²C protocol + RTL + baseline test
│   └── MODULE8.md             # I²C UVM+SV verification
│
├── module1/                   # Spec → RTL, methodology
│   ├── README.md              # Quick start
│   ├── EXAMPLES.md            # Example index
│   ├── examples/spec_to_rtl/  # Counter spec → RTL → simulation
│   └── ...
├── module2/ … module8/       # Same layout: README.md, EXAMPLES.md, examples/
│
├── scripts/                   # Per-module run/check scripts
│   ├── module1.sh … module8.sh
│   └── ...
│
├── tools/                     # UVM 2017, learn_unix_git, etc.
│   ├── uvm-2017/              # UVM 2017 library
│   └── ...
│
├── README.md                  # This file
└── LICENSE                    # CC BY 4.0
```

## 📖 Documentation

The `docs/` directory contains the syllabus and module guides.

### Learning Guides (Protocols & UVM)

**Before Modules 3–8**, use these guides so you learn the concepts first, then run the exercises.

- **[UART_LEARNING_GUIDE.md](docs/UART_LEARNING_GUIDE.md)** — **Detailed UART guide** (Modules 3–4): what UART is, what kind of protocol (serial, asynchronous, point-to-point), how it works (frame format, baud rate, TX/RX, timing diagram), common baud rates, where it’s used, and how it maps to our RTL.
- **[SPI_LEARNING_GUIDE.md](docs/SPI_LEARNING_GUIDE.md)** — **Detailed SPI guide** (Modules 5–6): what SPI is, what kind of protocol (serial, synchronous, master–slave), how it works (signals SCLK/MOSI/MISO/CS_N, modes CPOL/CPHA, Mode 0 timing), where it’s used, and how it maps to our RTL.
- **[I2C_LEARNING_GUIDE.md](docs/I2C_LEARNING_GUIDE.md)** — **Detailed I²C guide** (Modules 7–8): what I²C is, what kind of protocol (serial, synchronous, two-wire bus), how it works (START/STOP, address+R/W, data, ACK/NACK concept, timing), where it’s used, and how it maps to our RTL (including push-pull simplification).
- **[LEARNING_GUIDE_PROTOCOLS_AND_UVM.md](docs/LEARNING_GUIDE_PROTOCOLS_AND_UVM.md)** — **Protocols + UVM overview**: UART/SPI/I²C summaries, when to use baseline vs UVM, and how transaction/driver/monitor/scoreboard map to each protocol.

Module docs 3–8 point to the relevant guide and sections.

Each module doc includes:

- **Goal & Overview**: What the module teaches
- **Running the Module**: Quick run commands and links to examples
- **Topics Covered**: Protocol, RTL, or UVM concepts
- **Learning Outcomes**: What you should be able to do after the module
- **Navigation**: Links to previous/next module and back to README

### Module Documentation

- **[MODULE1.md](docs/MODULE1.md)**: Design & Verification Methodology (Part 1) — Spec→RTL, design methodology, intro to verification
- **[MODULE2.md](docs/MODULE2.md)**: Design & Verification Methodology (Part 2) — UVM basics, testbench patterns, Verilator + UVM toolchain
- **[MODULE3.md](docs/MODULE3.md)**: UART — Protocol + RTL + baseline testbench
- **[MODULE4.md](docs/MODULE4.md)**: UART — UVM+SV verification
- **[MODULE5.md](docs/MODULE5.md)**: SPI — Protocol + RTL + baseline testbench
- **[MODULE6.md](docs/MODULE6.md)**: SPI — UVM+SV verification
- **[MODULE7.md](docs/MODULE7.md)**: I²C — Protocol + RTL + baseline testbench
- **[MODULE8.md](docs/MODULE8.md)**: I²C — UVM+SV verification

## 🎓 Modules

### Module 1: Design & Verification Methodology (Part 1)

Spec→RTL flow, design methodology, and why we verify. Example: spec_to_rtl (counter).

**Quick Start**: `./scripts/module1.sh --run` or `cd module1/examples/spec_to_rtl && make run`

### Module 2: Design & Verification Methodology (Part 2)

UVM basics, directed tests vs UVM (agents, sequences, drivers, monitors, scoreboards), toolchain. Example: uvm_smoke.

**Quick Start**: `./scripts/module2.sh --run` or `cd module2/examples/uvm_smoke && make SIM=verilator TEST=test_uvm_smoke`

### Module 3: UART — Protocol + RTL + Baseline Test

UART protocol (8N1, baud), RTL (TX, RX, baud gen), directed testbench. Example: uart_baseline.

**Quick Start**: `./scripts/module3.sh --run` or `cd module3/examples/uart_baseline && make run`

### Module 4: UART — UVM+SV Verification

UART UVM agent (transaction, sequence, driver, monitor, scoreboard). Example: uart_uvm.

**Quick Start**: `./scripts/module4.sh --run` or `cd module4/examples/uart_uvm && make SIM=verilator TEST=test_uart_uvm`

### Module 5: SPI — Protocol + RTL + Baseline Test

SPI protocol (mode 0, signals), RTL (master, clk_div), directed testbench. Example: spi_baseline.

**Quick Start**: `./scripts/module5.sh --run` or `cd module5/examples/spi_baseline && make run`

### Module 6: SPI — UVM+SV Verification

SPI UVM agent. Example: spi_uvm.

**Quick Start**: `./scripts/module6.sh --run` or `cd module6/examples/spi_uvm && make SIM=verilator TEST=test_spi_uvm`

### Module 7: I²C — Protocol + RTL + Baseline Test

I²C protocol (start/stop, addressing, ACK/NACK), RTL (master), directed testbench. Example: i2c_baseline.

**Quick Start**: `./scripts/module7.sh --run` or `cd module7/examples/i2c_baseline && make run`

### Module 8: I²C — UVM+SV Verification

I²C UVM agent. Example: i2c_uvm.

**Quick Start**: `./scripts/module8.sh --run` or `cd module8/examples/i2c_uvm && make SIM=verilator TEST=test_i2c_uvm`

## 💻 Usage

### Per-Module Scripts

From the **repository root**:

```bash
./scripts/moduleN.sh --run    # run the module’s main example
./scripts/moduleN.sh --check  # self-check (if supported)
```

Replace `N` with 1–8. Not all modules support `--check`; see the script or module README.

### Running Examples Directly

Each example directory has a `Makefile`. Typical pattern:

- **Baseline (no UVM)**: `make run`
- **UVM**: `make SIM=verilator TEST=test_<name>`

See each module’s README and EXAMPLES.md for exact commands.

### UVM_HOME

If the Makefile does not set `UVM_HOME`, point it to the included UVM 2017 tree:

```bash
export UVM_HOME=$(pwd)/tools/uvm-2017/1800.2-2017-1.0
```

## 🤝 Contributing

Contributions are welcome. This project follows practices suited to educational material:

1. **Documentation**: Keep module docs and READMEs clear and consistent.
2. **Examples**: Ensure RTL and testbenches build and run with the stated commands.
3. **Scripts**: Preserve `--run` and `--check` behavior; document new options.
4. **Structure**: Follow the existing layout (docs/, moduleN/, scripts/, tools/).

## 📄 License

This work is licensed under the **Creative Commons Attribution 4.0 International (CC BY 4.0)**. See [LICENSE](LICENSE) in this repository for the license text and a link to the full legal code.

[![CC BY 4.0](https://i.creativecommons.org/l/by/4.0/88x31.png)](https://creativecommons.org/licenses/by/4.0/)

### What this means

- ✅ **You may:** Share and adapt the material for any purpose, including commercially.
- 📝 **You must:** Give appropriate credit, link to the license, and indicate if changes were made.

## 📞 Support

For questions or issues:

1. Check the [documentation](docs/) and each module’s [README](module1/README.md) and [EXAMPLES.md](module1/EXAMPLES.md).
2. Run `./scripts/moduleN.sh --run` or `--check` for the relevant module.
3. Open an issue for bugs or suggestions.

---

**Happy Learning! 🚀**

Start with [Module 1: Design & Verification Methodology (Part 1)](docs/MODULE1.md).
