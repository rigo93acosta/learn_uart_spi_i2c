// C++ test harness for spec_to_rtl (8-bit counter).
// Drives clk, rst_n, enable and checks count behavior.
// Module 1: basic directed test — no UVM.

#include <cstdint>
#include <cstdlib>
#include <iostream>

#include <verilated.h>
#include "Vtop.h"

#if VM_TRACE
#  include <verilated_vcd_c.h>
#endif

static constexpr int kClockHalfPeriod = 5;
static constexpr int kMaxSimTime = 2000;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop* top = new Vtop;

#if VM_TRACE
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("spec_to_rtl.vcd");
#endif

    // Initial state
    top->clk = 0;
    top->rst_n = 0;
    top->enable = 0;

    vluint64_t sim_time = 0;
    int half_ticks = 0;
    bool reset_done = false;
    int enable_cycles = 0;
    bool test_passed = true;

    while (sim_time < kMaxSimTime) {
        // Toggle clock every kClockHalfPeriod time units
        if (half_ticks % kClockHalfPeriod == 0) {
            top->clk = !top->clk;
            // Apply stimulus only on posedge (just toggled to 1)
            if (top->clk) {
                if (sim_time > 20 && !reset_done) {
                    top->rst_n = 1;
                    reset_done = true;
                }
                if (reset_done) {
                    if (enable_cycles < 10) {
                        top->enable = 1;
                        enable_cycles++;
                    } else if (enable_cycles == 10) {
                        top->enable = 0;
                        uint8_t count_val = static_cast<uint8_t>(top->count);
                        if (count_val != 10) {
                            std::cerr << "[FAIL] After 10 enable cycles, count = "
                                      << static_cast<unsigned>(count_val)
                                      << " (expected 10)\n";
                            test_passed = false;
                        }
                        enable_cycles++;
                    }
                }
            }
        }

        top->eval();
        sim_time++;
        half_ticks++;

#if VM_TRACE
        tfp->dump(sim_time);
#endif

        // Optional: finish once we've checked
        if (enable_cycles > 10 && sim_time > 100) {
            break;
        }
    }

#if VM_TRACE
    tfp->close();
    delete tfp;
#endif

    top->final();
    delete top;

    if (test_passed) {
        std::cout << "[PASS] spec_to_rtl: counter behavior matches spec.\n";
        return 0;
    }
    return 1;
}
