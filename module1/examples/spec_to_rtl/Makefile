# Makefile for Module 1 spec_to_rtl example
# Spec → RTL → basic simulation (no UVM).
#
# Usage:
#   make run          Build and run (default)
#   make run TRACE=1  Build with VCD tracing, then run
#   make clean        Remove obj_dir and VCD

TRACE ?= 0
VERILATOR ?= verilator
TOPLEVEL ?= top
DUT_SRC = dut/*.v
RTL_SRC = top.v $(DUT_SRC)
HARNESS = sim_main.cpp

VERILATOR_FLAGS = -cc --exe -Wall
ifeq ($(TRACE),1)
  VERILATOR_FLAGS += --trace
endif

.PHONY: run compile clean

run: compile
	@echo "Running $(TOPLEVEL)..."
	./obj_dir/V$(TOPLEVEL)

compile:
	@echo "Compiling with Verilator (TRACE=$(TRACE))..."
	$(VERILATOR) $(VERILATOR_FLAGS) $(RTL_SRC) $(HARNESS) --top-module $(TOPLEVEL)
	$(MAKE) -j$$(nproc 2>/dev/null || echo 8) -C obj_dir -f V$(TOPLEVEL).mk

clean:
	rm -rf obj_dir
	rm -f *.vcd *.log
