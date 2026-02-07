# Makefile for Module 3 UART baseline (basic testbench, no UVM)
#
# Usage:
#   make run
#

VERILATOR ?= verilator
TOPLEVEL ?= top_uart_baseline
DUT_SRC = dut/*.v
RTL_SRC = top_uart_baseline.sv $(DUT_SRC)
HARNESS = sim_main.cpp

VERILATOR_FLAGS = -sv --timing -Wall -Wno-fatal -Wno-TIMESCALEMOD -Wno-WIDTHTRUNC

.PHONY: run compile clean

run: compile
	@echo "Running $(TOPLEVEL)..."
	./obj_dir/V$(TOPLEVEL)

compile:
	@echo "Compiling UART baseline with Verilator..."
	$(VERILATOR) $(VERILATOR_FLAGS) --cc --exe $(RTL_SRC) $(HARNESS) --top-module $(TOPLEVEL)
	$(MAKE) -j$$(nproc 2>/dev/null || echo 8) -C obj_dir -f V$(TOPLEVEL).mk

clean:
	rm -rf obj_dir
	rm -f *.vcd *.log
