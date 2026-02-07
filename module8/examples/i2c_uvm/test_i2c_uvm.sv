/**
 * Module 4: I2C master UVM test (simplified, single write transaction).
 *
 * Teaching example:
 * - Simplified I2C master (no real open-drain or ACK handling).
 * - UVM agent requests address+data writes and a monitor reconstructs them
 *   from SDA/SCL activity under a single START/STOP frame.
 */

`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Interface
// -----------------------------------------------------------------------------
interface i2c_if;
    logic clk;
    logic rst_n;
    logic start;
    logic [6:0] addr;
    logic [7:0] data_in;
    logic scl;
    logic sda;
    logic clk_div_tick;
    logic busy;
    logic done;
endinterface

// -----------------------------------------------------------------------------
// Transaction
// -----------------------------------------------------------------------------
class I2cTransaction extends uvm_sequence_item;
    rand logic [6:0] addr;
    rand logic [7:0] data;
    logic [6:0] observed_addr;
    logic [7:0] observed_data;

    `uvm_object_utils(I2cTransaction)

    function new(string name = "I2cTransaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("addr=0x%02h data=0x%02h observed_addr=0x%02h observed_data=0x%02h",
                         addr, data, observed_addr, observed_data);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Sequence
// -----------------------------------------------------------------------------
class I2cSequence extends uvm_sequence #(I2cTransaction);
    `uvm_object_utils(I2cSequence)

    function new(string name = "I2cSequence");
        super.new(name);
    endfunction

    task body();
        I2cTransaction txn;

        txn = I2cTransaction::type_id::create("txn0");
        txn.addr = 7'h12;
        txn.data = 8'h00;
        start_item(txn);
        finish_item(txn);

        txn = I2cTransaction::type_id::create("txn1");
        txn.addr = 7'h12;
        txn.data = 8'hFF;
        start_item(txn);
        finish_item(txn);
    endtask
endclass

// -----------------------------------------------------------------------------
// Driver
// -----------------------------------------------------------------------------
class I2cDriver extends uvm_driver #(I2cTransaction);
    virtual i2c_if vif;

    `uvm_component_utils(I2cDriver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        I2cTransaction txn;

        wait (vif.rst_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(txn);

            vif.addr  <= txn.addr;
            vif.data_in <= txn.data;
            vif.start <= 1'b1;
            @(posedge vif.clk);
            vif.start <= 1'b0;

            `uvm_info("DRIVER", $sformatf("Requested I2C write: addr=0x%02h data=0x%02h",
                                          txn.addr, txn.data), UVM_MEDIUM)

            // Wait for done pulse.
            @(posedge vif.clk iff vif.done);

            seq_item_port.item_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Monitor
// -----------------------------------------------------------------------------
class I2cMonitor extends uvm_monitor;
    virtual i2c_if vif;
    uvm_analysis_port #(I2cTransaction) ap;

    `uvm_component_utils(I2cMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        I2cTransaction txn;
        bit [7:0] addr_w;
        bit [7:0] data_b;
        int       bit_idx;

        wait (vif.rst_n === 1'b1);

        forever begin
            // Wait for START: SDA falling while SCL high.
            @(posedge vif.clk);
            if (vif.scl == 1'b1 && vif.sda == 1'b0) begin
                // Capture address+W (8 bits) then data (8 bits).
                addr_w = '0;
                data_b = '0;

                // Address + W.
                bit_idx = 7;
                repeat (8) begin
                    @(posedge vif.scl);
                    addr_w[bit_idx] = vif.sda;
                    bit_idx -= 1;
                end

                // Data byte.
                bit_idx = 7;
                repeat (8) begin
                    @(posedge vif.scl);
                    data_b[bit_idx] = vif.sda;
                    bit_idx -= 1;
                end

                txn = I2cTransaction::type_id::create("mon_txn");
                txn.observed_addr = addr_w[7:1]; // top 7 bits as address
                txn.observed_data = data_b;
                txn.addr          = '0;
                txn.data          = '0;

                `uvm_info("MONITOR",
                          $sformatf("Observed I2C write: addr=0x%02h data=0x%02h",
                                    txn.observed_addr, txn.observed_data),
                          UVM_MEDIUM)
                ap.write(txn);
            end
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Scoreboard
// -----------------------------------------------------------------------------
class I2cScoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(I2cTransaction, I2cScoreboard) imp;
    I2cTransaction expected_queue[$];
    int match_count    = 0;
    int mismatch_count = 0;

    `uvm_component_utils(I2cScoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void add_expected(I2cTransaction txn);
        expected_queue.push_back(txn);
    endfunction

    function void write(I2cTransaction txn);
        I2cTransaction exp;
        if (expected_queue.size() == 0) begin
            `uvm_warning("SCOREBOARD", "No expected transaction available")
            return;
        end

        exp = expected_queue.pop_front();

        if (txn.observed_addr === exp.addr && txn.observed_data === exp.data) begin
            match_count++;
            `uvm_info("SCOREBOARD",
                      $sformatf("PASS: expected addr=0x%02h data=0x%02h got addr=0x%02h data=0x%02h",
                                exp.addr, exp.data, txn.observed_addr, txn.observed_data),
                      UVM_MEDIUM)
        end else begin
            mismatch_count++;
            `uvm_error("SCOREBOARD",
                       $sformatf("FAIL: expected addr=0x%02h data=0x%02h got addr=0x%02h data=0x%02h",
                                 exp.addr, exp.data, txn.observed_addr, txn.observed_data))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD",
                  $sformatf("Matches: %0d, Mismatches: %0d", match_count, mismatch_count),
                  UVM_MEDIUM)
    endfunction
endclass

// -----------------------------------------------------------------------------
// Agent + Env
// -----------------------------------------------------------------------------
class I2cAgent extends uvm_agent;
    I2cDriver   driver;
    I2cMonitor  monitor;
    uvm_sequencer #(I2cTransaction) sequencer;

    `uvm_component_utils(I2cAgent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = I2cDriver::type_id::create("driver", this);
        monitor   = I2cMonitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(I2cTransaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

class I2cEnv extends uvm_env;
    I2cAgent      agent;
    I2cScoreboard scoreboard;

    `uvm_component_utils(I2cEnv)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = I2cAgent::type_id::create("agent", this);
        scoreboard = I2cScoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.imp);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Test
// -----------------------------------------------------------------------------
class I2cTest extends uvm_test;
    I2cEnv env;

    `uvm_component_utils(I2cTest)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = I2cEnv::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        I2cSequence    seq;
        I2cTransaction exp;

        phase.raise_objection(this);

        // Expected sequence must match I2cSequence ordering.
        exp = I2cTransaction::type_id::create("exp0"); exp.addr = 7'h12; exp.data = 8'h00; env.scoreboard.add_expected(exp);
        exp = I2cTransaction::type_id::create("exp1"); exp.addr = 7'h12; exp.data = 8'hFF; env.scoreboard.add_expected(exp);

        `uvm_info("TEST", "Starting I2C master sequence", UVM_LOW)

        seq = I2cSequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        // Allow some extra cycles for monitor/scoreboard to finish.
        #5000;

        phase.drop_objection(this);
    endtask
endclass

// -----------------------------------------------------------------------------
// Top-level module: connect DUT and start UVM
// -----------------------------------------------------------------------------
module test_i2c_uvm;
    i2c_if vif();

    // DUT: I2C master
    i2c_master dut (
        .clk          (vif.clk),
        .rst_n        (vif.rst_n),
        .clk_div_tick (vif.clk_div_tick),
        .start        (vif.start),
        .addr         (vif.addr),
        .data_in      (vif.data_in),
        .scl          (vif.scl),
        .sda          (vif.sda),
        .busy         (vif.busy),
        .done         (vif.done)
    );

    // Clock divider for SCL timing.
    clk_div #(.DIVIDER(8)) clk_div_inst (
        .clk          (vif.clk),
        .rst_n        (vif.rst_n),
        .clk_div_tick (vif.clk_div_tick)
    );

    // System clock: 10 ns period.
    initial begin
        vif.clk = 1'b0;
        forever #5 vif.clk = ~vif.clk;
    end

    // Reset and initial conditions.
    initial begin
        vif.rst_n      = 1'b0;
        vif.start      = 1'b0;
        vif.addr       = 7'h00;
        vif.data_in    = 8'h00;
        vif.scl        = 1'b1;
        vif.sda        = 1'b1;
        vif.clk_div_tick = 1'b0;
        repeat (5) @(posedge vif.clk);
        vif.rst_n = 1'b1;
    end

    // UVM config + start.
    initial begin
        uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", vif);
        run_test("I2cTest");
    end
endmodule

