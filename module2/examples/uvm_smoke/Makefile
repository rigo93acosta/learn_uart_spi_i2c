# Makefile for Module 2 UVM smoke test
#
# Mirrors the style used in:
# - tools/learn_uvm2017_sv_verilator/module3/tests/uvm_tests/Makefile
#
# Usage:
#   make SIM=verilator TEST=test_uvm_smoke
#

SIM ?= verilator
TEST ?= test_uvm_smoke

# Prefer an externally-installed UVM, but fall back to the repo's vendored UVM.
UVM_HOME ?= $(shell echo $$UVM_HOME)
# From module2/examples/uvm_smoke, repo root is ../../..
UVM_HOME_FALLBACK := ../../../tools/uvm-2017/1800.2-2017-1.0
UVM_HOME_FALLBACK_ALT := ../../../tools/learn_uvm2017_sv_verilator/tools/uvm-2017/1800.2-2017-1.0

ifeq ($(UVM_HOME),)
  ifneq ($(wildcard $(UVM_HOME_FALLBACK)/src/uvm_pkg.sv),)
    UVM_HOME := $(UVM_HOME_FALLBACK)
    $(info UVM_HOME not set; using fallback: $(UVM_HOME))
  else ifneq ($(wildcard $(UVM_HOME_FALLBACK_ALT)/src/uvm_pkg.sv),)
    UVM_HOME := $(UVM_HOME_FALLBACK_ALT)
    $(info UVM_HOME not set; using fallback: $(UVM_HOME))
  else
    $(error UVM_HOME is not set and fallback not found. Please export UVM_HOME=/path/to/uvm)
  endif
endif

# Verilator flags commonly used for UVM builds.
VERILATOR_FLAGS = -sv --timing --trace -Wno-fatal -Wno-TIMESCALEMOD -Wno-WIDTHTRUNC

# If UVM_HOME points to root, use /src; if it points to src, use directly.
UVM_SRC_DIR = $(if $(wildcard $(UVM_HOME)/src/uvm_pkg.sv),$(UVM_HOME)/src,$(UVM_HOME))
INCLUDES = -I$(UVM_SRC_DIR) +incdir+$(UVM_SRC_DIR) +define+UVM_NO_DPI

DUT_SRC = dut/*.v
TEST_SRC = $(TEST).sv
TOPLEVEL = $(TEST)

ifeq ($(SIM),verilator)
compile:
	@echo "Compiling with Verilator..."
	verilator $(VERILATOR_FLAGS) $(INCLUDES) \
		--binary \
		$(UVM_SRC_DIR)/uvm_pkg.sv \
		$(DUT_SRC) $(TEST_SRC) \
		--top-module $(TOPLEVEL)
	make -j$(shell nproc 2>/dev/null || echo 8) -C obj_dir -f V$(TOPLEVEL).mk VM_PARALLEL_BUILDS=1

run: compile
	@echo "Running $(TEST)..."
	./obj_dir/V$(TOPLEVEL) +UVM_TESTNAME=$(TOPLEVEL)

clean:
	rm -rf obj_dir
	rm -f *.vcd *.log

.PHONY: compile run clean
endif

all: run
.PHONY: all
