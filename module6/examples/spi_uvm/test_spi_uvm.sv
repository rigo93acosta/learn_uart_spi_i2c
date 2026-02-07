/**
 * Module 6: SPI master UVM test (Verilator)
 *
 * SPI agent: transaction, sequence, driver, monitor, scoreboard.
 * Driver sends bytes via start/data_in; monitor samples MOSI on SCLK (mode 0);
 * scoreboard checks expected vs observed.
 */

`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Interface
// -----------------------------------------------------------------------------
interface spi_master_if;
    logic        clk;
    logic        rst_n;
    logic        clk_div_tick;
    logic        start;
    logic [7:0]  data_in;
    logic        sclk;
    logic        mosi;
    logic        cs_n;
    logic        busy;
    logic        done;
endinterface

// -----------------------------------------------------------------------------
// Transaction
// -----------------------------------------------------------------------------
class SpiTransaction extends uvm_sequence_item;
    rand logic [7:0] data;
    logic [7:0] observed_mosi;

    `uvm_object_utils(SpiTransaction)

    function new(string name = "SpiTransaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("data=0x%02h observed_mosi=0x%02h", data, observed_mosi);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Sequence
// -----------------------------------------------------------------------------
class SpiSequence extends uvm_sequence #(SpiTransaction);
    `uvm_object_utils(SpiSequence)

    function new(string name = "SpiSequence");
        super.new(name);
    endfunction

    task body();
        SpiTransaction txn;

        txn = SpiTransaction::type_id::create("txn0");
        txn.data = 8'h00;
        start_item(txn);
        finish_item(txn);

        txn = SpiTransaction::type_id::create("txn1");
        txn.data = 8'h01;
        start_item(txn);
        finish_item(txn);

        txn = SpiTransaction::type_id::create("txn2");
        txn.data = 8'h55;
        start_item(txn);
        finish_item(txn);

        txn = SpiTransaction::type_id::create("txn3");
        txn.data = 8'hAA;
        start_item(txn);
        finish_item(txn);

        txn = SpiTransaction::type_id::create("txn4");
        txn.data = 8'hFF;
        start_item(txn);
        finish_item(txn);
    endtask
endclass

// -----------------------------------------------------------------------------
// Driver
// -----------------------------------------------------------------------------
class SpiDriver extends uvm_driver #(SpiTransaction);
    virtual spi_master_if vif;

    `uvm_component_utils(SpiDriver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_master_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        SpiTransaction txn;

        wait (vif.rst_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(txn);

            vif.data_in <= txn.data;
            vif.start   <= 1'b1;
            @(posedge vif.clk);
            vif.start   <= 1'b0;

            `uvm_info("DRIVER", $sformatf("Requested SPI transfer 0x%02h", txn.data), UVM_MEDIUM)

            wait (vif.done === 1'b1);
            @(posedge vif.clk);

            seq_item_port.item_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Monitor (mode 0: sample MOSI on rising SCLK, MSB first)
// -----------------------------------------------------------------------------
class SpiMonitor extends uvm_monitor;
    virtual spi_master_if vif;
    uvm_analysis_port #(SpiTransaction) ap;

    `uvm_component_utils(SpiMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_master_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        SpiTransaction txn;
        logic [7:0] assembled;
        int bit_idx;

        wait (vif.rst_n === 1'b1);

        forever begin
            // Wait for transfer start: cs_n goes low
            @(posedge vif.clk);
            if (vif.cs_n === 1'b0) begin
                assembled = '0;
                // Mode 0: capture on rising edge of SCLK, MSB first
                for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
                    @(posedge vif.sclk);
                    assembled[bit_idx] = vif.mosi;
                end

                txn = SpiTransaction::type_id::create("mon_txn");
                txn.data         = '0;
                txn.observed_mosi = assembled;

                `uvm_info("MONITOR", $sformatf("Observed MOSI byte 0x%02h", assembled), UVM_MEDIUM)
                ap.write(txn);
            end
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Scoreboard
// -----------------------------------------------------------------------------
class SpiScoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(SpiTransaction, SpiScoreboard) imp;
    SpiTransaction expected_queue[$];
    int match_count = 0;
    int mismatch_count = 0;

    `uvm_component_utils(SpiScoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void add_expected(SpiTransaction txn);
        expected_queue.push_back(txn);
    endfunction

    function void write(SpiTransaction txn);
        SpiTransaction exp;
        if (expected_queue.size() == 0) begin
            `uvm_warning("SCOREBOARD", "No expected transaction available")
            return;
        end

        exp = expected_queue.pop_front();

        if (txn.observed_mosi === exp.data) begin
            match_count++;
            `uvm_info("SCOREBOARD", $sformatf("PASS: expected=0x%02h got=0x%02h",
                                              exp.data, txn.observed_mosi), UVM_MEDIUM)
        end else begin
            mismatch_count++;
            `uvm_error("SCOREBOARD", $sformatf("FAIL: expected=0x%02h got=0x%02h",
                                               exp.data, txn.observed_mosi))
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
class SpiAgent extends uvm_agent;
    SpiDriver  driver;
    SpiMonitor monitor;
    uvm_sequencer #(SpiTransaction) sequencer;

    `uvm_component_utils(SpiAgent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver   = SpiDriver::type_id::create("driver", this);
        monitor  = SpiMonitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(SpiTransaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

class SpiEnv extends uvm_env;
    SpiAgent      agent;
    SpiScoreboard scoreboard;

    `uvm_component_utils(SpiEnv)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = SpiAgent::type_id::create("agent", this);
        scoreboard = SpiScoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.imp);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Test
// -----------------------------------------------------------------------------
class SpiTest extends uvm_test;
    SpiEnv env;

    `uvm_component_utils(SpiTest)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = SpiEnv::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        SpiSequence    seq;
        SpiTransaction exp;

        phase.raise_objection(this);

        exp = SpiTransaction::type_id::create("exp0"); exp.data = 8'h00; env.scoreboard.add_expected(exp);
        exp = SpiTransaction::type_id::create("exp1"); exp.data = 8'h01; env.scoreboard.add_expected(exp);
        exp = SpiTransaction::type_id::create("exp2"); exp.data = 8'h55; env.scoreboard.add_expected(exp);
        exp = SpiTransaction::type_id::create("exp3"); exp.data = 8'hAA; env.scoreboard.add_expected(exp);
        exp = SpiTransaction::type_id::create("exp4"); exp.data = 8'hFF; env.scoreboard.add_expected(exp);

        `uvm_info("TEST", "Starting SPI sequence", UVM_LOW)

        seq = SpiSequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        #500;

        phase.drop_objection(this);
    endtask
endclass

// -----------------------------------------------------------------------------
// Top-level module: connect DUT and start UVM
// -----------------------------------------------------------------------------
module test_spi_uvm;
    spi_master_if vif();

    logic clk_div_tick;

    clk_div #(.DIVIDER(8)) u_clk_div (
        .clk         (vif.clk),
        .rst_n       (vif.rst_n),
        .clk_div_tick(vif.clk_div_tick)
    );

    spi_master u_spi (
        .clk         (vif.clk),
        .rst_n       (vif.rst_n),
        .clk_div_tick(vif.clk_div_tick),
        .start       (vif.start),
        .data_in     (vif.data_in),
        .sclk        (vif.sclk),
        .mosi        (vif.mosi),
        .cs_n        (vif.cs_n),
        .busy        (vif.busy),
        .done        (vif.done)
    );

    initial begin
        vif.clk = 1'b0;
        forever #5 vif.clk = ~vif.clk;
    end

    initial begin
        vif.rst_n   = 1'b0;
        vif.start   = 1'b0;
        vif.data_in = 8'h00;
        repeat (3) @(posedge vif.clk);
        vif.rst_n   = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual spi_master_if)::set(null, "*", "vif", vif);
        run_test("SpiTest");
    end
endmodule
