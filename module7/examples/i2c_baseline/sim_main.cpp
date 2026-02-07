// C++ harness for I2C baseline: drive clk and rst_n, run until $finish.

#include <cstdlib>
#include <iostream>

#include <verilated.h>
#include "Vtop_i2c_baseline.h"

static constexpr int kClockHalfPeriod = 5;
static constexpr int kMaxSimTime = 500000;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtop_i2c_baseline* top = new Vtop_i2c_baseline;

    top->clk = 0;
    top->rst_n = 0;

    vluint64_t sim_time = 0;
    int half_ticks = 0;

    while (sim_time < kMaxSimTime && !Verilated::gotFinish()) {
        if (half_ticks % kClockHalfPeriod == 0) {
            top->clk = !top->clk;
        }
        if (top->clk && sim_time > 20) {
            top->rst_n = 1;
        }

        top->eval();
        sim_time++;
        half_ticks++;
    }

    top->final();
    delete top;

    return 0;
}
