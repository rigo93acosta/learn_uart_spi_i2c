/**
 * Module 2: UVM smoke test (Verilator)
 *
 * Purpose:
 * - Provide a *self-contained* UVM test that compiles and runs on Verilator
 * - Demonstrate the core UVM structure used later for UART/SPI/I²C:
 *   transaction → sequence → driver/monitor → scoreboard
 */

`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Interface
// -----------------------------------------------------------------------------
interface reg_if;
    logic clk;
    logic rst_n;
    logic enable;
    logic [7:0] d;
    logic [7:0] q;
endinterface

// -----------------------------------------------------------------------------
// Transaction
// -----------------------------------------------------------------------------
class RegTransaction extends uvm_sequence_item;
    rand logic [7:0] d;
    rand bit enable;
    logic [7:0] observed_q;

    `uvm_object_utils(RegTransaction)

    function new(string name = "RegTransaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("enable=%0b d=0x%02h observed_q=0x%02h", enable, d, observed_q);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Sequence
// -----------------------------------------------------------------------------
class RegSequence extends uvm_sequence #(RegTransaction);
    `uvm_object_utils(RegSequence)

    function new(string name = "RegSequence");
        super.new(name);
    endfunction

    task body();
        RegTransaction txn;

        // A few directed patterns (keep smoke test deterministic).
        // Note: keep this simple and Verilator-friendly (avoid dynamic arrays here).
        byte unsigned vals[5];
        vals[0] = 8'h00;
        vals[1] = 8'h01;
        vals[2] = 8'h55;
        vals[3] = 8'hAA;
        vals[4] = 8'hFF;

        for (int i = 0; i < 5; i++) begin
            txn = RegTransaction::type_id::create($sformatf("txn_dir_%0d", i));
            txn.enable = 1'b1;
            txn.d = vals[i];
            start_item(txn);
            finish_item(txn);
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Driver
// -----------------------------------------------------------------------------
class RegDriver extends uvm_driver #(RegTransaction);
    virtual reg_if vif;

    `uvm_component_utils(RegDriver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual reg_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        RegTransaction txn;

        // Wait for reset deassertion from top module.
        wait (vif.rst_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(txn);

            vif.enable <= txn.enable;
            vif.d <= txn.d;

            `uvm_info("DRIVER", $sformatf("Driving: %s", txn.convert2string()), UVM_MEDIUM)

            @(posedge vif.clk);
            #1;

            seq_item_port.item_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Monitor
// -----------------------------------------------------------------------------
class RegMonitor extends uvm_monitor;
    virtual reg_if vif;
    uvm_analysis_port #(RegTransaction) ap;

    `uvm_component_utils(RegMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual reg_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        RegTransaction txn;

        wait (vif.rst_n === 1'b1);

        forever begin
            @(posedge vif.clk);
            #1;

            txn = RegTransaction::type_id::create("txn_obs");
            txn.enable = vif.enable;
            txn.d = vif.d;
            txn.observed_q = vif.q;

            `uvm_info("MONITOR", $sformatf("Observed: %s", txn.convert2string()), UVM_MEDIUM)
            ap.write(txn);
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Scoreboard
// -----------------------------------------------------------------------------
class RegScoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(RegTransaction, RegScoreboard) imp;
    RegTransaction expected_queue[$];
    int match_count = 0;
    int mismatch_count = 0;

    `uvm_component_utils(RegScoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void add_expected(RegTransaction txn);
        expected_queue.push_back(txn);
    endfunction

    function void write(RegTransaction txn);
        RegTransaction exp;

        if (expected_queue.size() == 0) begin
            `uvm_warning("SCOREBOARD", $sformatf("No expected item available for observed: %s", txn.convert2string()))
            return;
        end

        exp = expected_queue.pop_front();

        if (txn.enable && (txn.observed_q === exp.d)) begin
            match_count++;
            `uvm_info("SCOREBOARD", $sformatf("PASS: expected_q=0x%02h got_q=0x%02h", exp.d, txn.observed_q), UVM_MEDIUM)
        end else begin
            mismatch_count++;
            `uvm_error("SCOREBOARD", $sformatf("FAIL: expected_q=0x%02h got_q=0x%02h enable=%0b",
                                              exp.d, txn.observed_q, txn.enable))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", $sformatf("Matches: %0d, Mismatches: %0d", match_count, mismatch_count), UVM_MEDIUM)
    endfunction
endclass

// -----------------------------------------------------------------------------
// Agent + Env
// -----------------------------------------------------------------------------
class RegAgent extends uvm_agent;
    RegDriver driver;
    RegMonitor monitor;
    uvm_sequencer #(RegTransaction) sequencer;

    `uvm_component_utils(RegAgent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = RegDriver::type_id::create("driver", this);
        monitor = RegMonitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(RegTransaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

class RegEnv extends uvm_env;
    RegAgent agent;
    RegScoreboard scoreboard;

    `uvm_component_utils(RegEnv)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = RegAgent::type_id::create("agent", this);
        scoreboard = RegScoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.imp);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Test
// -----------------------------------------------------------------------------
class RegTest extends uvm_test;
    RegEnv env;

    `uvm_component_utils(RegTest)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = RegEnv::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        RegSequence seq;
        RegTransaction exp;

        phase.raise_objection(this);

        // Queue expected items to match the sequence ordering.
        // This keeps the smoke test simple and deterministic.
        exp = RegTransaction::type_id::create("exp0"); exp.enable = 1'b1; exp.d = 8'h00; env.scoreboard.add_expected(exp);
        exp = RegTransaction::type_id::create("exp1"); exp.enable = 1'b1; exp.d = 8'h01; env.scoreboard.add_expected(exp);
        exp = RegTransaction::type_id::create("exp2"); exp.enable = 1'b1; exp.d = 8'h55; env.scoreboard.add_expected(exp);
        exp = RegTransaction::type_id::create("exp3"); exp.enable = 1'b1; exp.d = 8'hAA; env.scoreboard.add_expected(exp);
        exp = RegTransaction::type_id::create("exp4"); exp.enable = 1'b1; exp.d = 8'hFF; env.scoreboard.add_expected(exp);
        `uvm_info("TEST", "Starting directed smoke sequence", UVM_LOW)

        seq = RegSequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        // Allow a few extra cycles for the monitor/scoreboard to process.
        #50;

        phase.drop_objection(this);
    endtask
endclass

// -----------------------------------------------------------------------------
// Top-level module: connects interface + DUT and starts UVM.
// -----------------------------------------------------------------------------
module test_uvm_smoke;
    reg_if vif();

    // DUT instance
    simple_register dut (
        .clk(vif.clk),
        .rst_n(vif.rst_n),
        .enable(vif.enable),
        .d(vif.d),
        .q(vif.q)
    );

    // Clock generation (10ns period).
    initial begin
        vif.clk = 1'b0;
        forever #5 vif.clk = ~vif.clk;
    end

    // Reset + initial conditions.
    initial begin
        vif.rst_n = 1'b0;
        vif.enable = 1'b0;
        vif.d = 8'h00;
        repeat (3) @(posedge vif.clk);
        vif.rst_n = 1'b1;
    end

    // Start UVM.
    initial begin
        uvm_config_db#(virtual reg_if)::set(null, "*", "vif", vif);
        run_test("RegTest");
    end
endmodule
