/**
 * Module 4: UART TX/RX UVM test (Verilator)
 *
 * UART agent: transaction, sequence, driver, monitor, scoreboard.
 * Loopback: TX output -> RX input; scoreboard checks TX (monitor) and RX (hook).
 */

`include "uvm_macros.svh"
import uvm_pkg::*;

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// Interface
// -----------------------------------------------------------------------------
interface uart_tx_if;
    logic clk;
    logic rst_n;
    logic start;
    logic [7:0] data;
    logic tx;
    logic baud_tick;
endinterface

// -----------------------------------------------------------------------------
// Transaction
// -----------------------------------------------------------------------------
class UartTxTransaction extends uvm_sequence_item;
    rand logic [7:0] data;
    logic [7:0] observed_tx;
    logic [7:0] observed_rx;

    `uvm_object_utils(UartTxTransaction)

    function new(string name = "UartTxTransaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("data=0x%02h observed_tx=0x%02h observed_rx=0x%02h",
                         data, observed_tx, observed_rx);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Sequence
// -----------------------------------------------------------------------------
class UartTxSequence extends uvm_sequence #(UartTxTransaction);
    `uvm_object_utils(UartTxSequence)

    function new(string name = "UartTxSequence");
        super.new(name);
    endfunction

    task body();
        UartTxTransaction txn;
        // Explicitly generate a few directed transactions.

        txn = UartTxTransaction::type_id::create("txn0");
        txn.data = 8'h00;
        start_item(txn);
        finish_item(txn);

        txn = UartTxTransaction::type_id::create("txn1");
        txn.data = 8'h01;
        start_item(txn);
        finish_item(txn);

        txn = UartTxTransaction::type_id::create("txn2");
        txn.data = 8'h55;
        start_item(txn);
        finish_item(txn);

        txn = UartTxTransaction::type_id::create("txn3");
        txn.data = 8'hAA;
        start_item(txn);
        finish_item(txn);

        txn = UartTxTransaction::type_id::create("txn4");
        txn.data = 8'hFF;
        start_item(txn);
        finish_item(txn);
    endtask
endclass

// -----------------------------------------------------------------------------
// Driver
// -----------------------------------------------------------------------------
class UartTxDriver extends uvm_driver #(UartTxTransaction);
    virtual uart_tx_if vif;

    `uvm_component_utils(UartTxDriver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_tx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        UartTxTransaction txn;

        // Wait for reset deassertion
        wait (vif.rst_n === 1'b1);

        forever begin
            seq_item_port.get_next_item(txn);

            // Apply parallel data and pulse start for one cycle.
            vif.data  <= txn.data;
            vif.start <= 1'b1;
            @(posedge vif.clk);
            vif.start <= 1'b0;

            `uvm_info("DRIVER", $sformatf("Requested TX of 0x%02h", txn.data), UVM_MEDIUM)

            // Wait long enough for 10 bits (start + 8 data + stop),
            // using baud_tick as the timing reference.
            repeat (10) @(posedge vif.clk iff vif.baud_tick);

            seq_item_port.item_done();
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Monitor
// -----------------------------------------------------------------------------
class UartTxMonitor extends uvm_monitor;
    virtual uart_tx_if vif;
    uvm_analysis_port #(UartTxTransaction) ap;

    `uvm_component_utils(UartTxMonitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_tx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found")
        end
    endfunction

    task run_phase(uvm_phase phase);
        UartTxTransaction txn;
        bit [7:0] assembled;

        wait (vif.rst_n === 1'b1);

        forever begin
            // Wait for start bit (line goes low from idle high).
            @(posedge vif.clk);
            if (vif.tx === 1'b0) begin
                // Sample 8 data bits and then stop bit once per baud_tick.
                assembled = '0;
                for (int i = 0; i < 8; i++) begin
                    @(posedge vif.clk iff vif.baud_tick);
                    assembled[i] = vif.tx; // LSB first
                end

                // Optional: sample stop bit (should be 1)
                @(posedge vif.clk iff vif.baud_tick);

                txn = UartTxTransaction::type_id::create("mon_txn");
                txn.data        = '0;       // filled in by scoreboard expected queue
                txn.observed_tx = assembled;

                `uvm_info("MONITOR", $sformatf("Observed TX byte 0x%02h", assembled), UVM_MEDIUM)
                ap.write(txn);
            end
        end
    endtask
endclass

// -----------------------------------------------------------------------------
// Scoreboard
// -----------------------------------------------------------------------------
class UartTxScoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(UartTxTransaction, UartTxScoreboard) imp;
    UartTxTransaction expected_queue[$];
    int match_count = 0;
    int mismatch_count = 0;

    // RX observation comes directly from DUT rx_valid/rx_data in the top.
    int rx_match_count = 0;
    int rx_mismatch_count = 0;

    `uvm_component_utils(UartTxScoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    function void add_expected(UartTxTransaction txn);
        expected_queue.push_back(txn);
    endfunction

    function void write(UartTxTransaction txn);
        UartTxTransaction exp;
        if (expected_queue.size() == 0) begin
            `uvm_warning("SCOREBOARD", "No expected transaction available")
            return;
        end

        exp = expected_queue.pop_front();

        if (txn.observed_tx === exp.data) begin
            match_count++;
            `uvm_info("SCOREBOARD", $sformatf("PASS: expected=0x%02h got=0x%02h",
                                              exp.data, txn.observed_tx), UVM_MEDIUM)
        end else begin
            mismatch_count++;
            `uvm_error("SCOREBOARD", $sformatf("FAIL: expected=0x%02h got=0x%02h",
                                               exp.data, txn.observed_tx))
        end
    endfunction

    // Called from the DUT top when the RX side reports a valid byte.
    function void check_rx_byte(logic [7:0] rx_data);
        UartTxTransaction exp;
        if (expected_queue.size() == 0) begin
            `uvm_warning("SCOREBOARD", "RX byte arrived with no expected data")
            return;
        end

        exp = expected_queue.pop_front();

        if (rx_data === exp.data) begin
            rx_match_count++;
            `uvm_info("SCOREBOARD", $sformatf("RX PASS: expected=0x%02h got=0x%02h",
                                              exp.data, rx_data), UVM_MEDIUM)
        end else begin
            rx_mismatch_count++;
            `uvm_error("SCOREBOARD", $sformatf("RX FAIL: expected=0x%02h got=0x%02h",
                                               exp.data, rx_data))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD",
                  $sformatf("TX Matches: %0d, TX Mismatches: %0d; RX Matches: %0d, RX Mismatches: %0d",
                            match_count, mismatch_count, rx_match_count, rx_mismatch_count),
                  UVM_MEDIUM)
    endfunction
endclass

// -----------------------------------------------------------------------------
// Agent + Env
// -----------------------------------------------------------------------------
class UartTxAgent extends uvm_agent;
    UartTxDriver driver;
    UartTxMonitor monitor;
    uvm_sequencer #(UartTxTransaction) sequencer;

    `uvm_component_utils(UartTxAgent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = UartTxDriver::type_id::create("driver", this);
        monitor   = UartTxMonitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(UartTxTransaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

class UartTxEnv extends uvm_env;
    UartTxAgent       agent;
    UartTxScoreboard  scoreboard;

    `uvm_component_utils(UartTxEnv)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = UartTxAgent::type_id::create("agent", this);
        scoreboard = UartTxScoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.imp);
    endfunction
endclass

// -----------------------------------------------------------------------------
// Test
// -----------------------------------------------------------------------------
class UartTxTest extends uvm_test;
    UartTxEnv env;

    `uvm_component_utils(UartTxTest)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = UartTxEnv::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        UartTxSequence     seq;
        UartTxTransaction  exp;

        phase.raise_objection(this);

        // Expected sequence must match UartTxSequence ordering.
        exp = UartTxTransaction::type_id::create("exp0"); exp.data = 8'h00; env.scoreboard.add_expected(exp);
        exp = UartTxTransaction::type_id::create("exp1"); exp.data = 8'h01; env.scoreboard.add_expected(exp);
        exp = UartTxTransaction::type_id::create("exp2"); exp.data = 8'h55; env.scoreboard.add_expected(exp);
        exp = UartTxTransaction::type_id::create("exp3"); exp.data = 8'hAA; env.scoreboard.add_expected(exp);
        exp = UartTxTransaction::type_id::create("exp4"); exp.data = 8'hFF; env.scoreboard.add_expected(exp);

        `uvm_info("TEST", "Starting UART TX sequence", UVM_LOW)

        seq = UartTxSequence::type_id::create("seq");
        seq.start(env.agent.sequencer);

        // Allow some extra cycles for monitor/scoreboard to finish.
        #200;

        phase.drop_objection(this);
    endtask
endclass

// -----------------------------------------------------------------------------
// Top-level module: connect DUT and start UVM
// -----------------------------------------------------------------------------
module test_uart_uvm;
    uart_tx_if vif();

    // RX side signals (simple TX->RX loopback)
    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_framing_error;
    logic       baud_tick;

    // DUT
    uart_tx dut (
        .clk       (vif.clk),
        .rst_n     (vif.rst_n),
        .baud_tick (vif.baud_tick),
        .start     (vif.start),
        .data_in   (vif.data),
        .tx        (vif.tx),
        .busy      (/* unused for now */)
    );

    // Simple loopback: connect TX line directly into RX DUT.
    uart_rx dut_rx (
        .clk          (vif.clk),
        .rst_n        (vif.rst_n),
        .baud_tick    (vif.baud_tick),
        .rx           (vif.tx),
        .data_out     (rx_data),
        .data_valid   (rx_valid),
        .framing_error(rx_framing_error)
    );

    // Baud-rate generator: for testbench purposes we can pick a small
    // divider so that waveforms are easy to inspect (not exact 115200).
    baud_gen #(.DIVIDER(16)) baud_inst (
        .clk       (vif.clk),
        .rst_n     (vif.rst_n),
        .baud_tick (vif.baud_tick)
    );

    // Clock: 10 ns period
    initial begin
        vif.clk = 1'b0;
        forever #5 vif.clk = ~vif.clk;
    end

    // Reset and initial conditions
    initial begin
        vif.rst_n = 1'b0;
        vif.start = 1'b0;
        vif.data  = 8'h00;
        repeat (3) @(posedge vif.clk);
        vif.rst_n = 1'b1;
    end

    // UVM config + start
    initial begin
        uvm_config_db#(virtual uart_tx_if)::set(null, "*", "vif", vif);
        run_test("UartTxTest");
    end

    // Hook RX observations into the UVM scoreboard via uvm_config_db lookup.
    // This keeps the UVM agent focused on the serial line while still
    // checking the parallel RX output.
    initial begin : rx_scoreboard_hook
        UartTxEnv        env_h;
        UartTxScoreboard sb_h;

        // Wait some time for the test and environment to be constructed.
        // For a more advanced example, you could use explicit configuration
        // handles; for teaching we keep this simple.
        #1;
        if (!$cast(env_h, uvm_top.find("uvm_test_top.env"))) begin
            `uvm_fatal("RX_HOOK", "Failed to find UartTxEnv at uvm_test_top.env")
        end
        sb_h = env_h.scoreboard;

        forever begin
            @(posedge vif.clk);
            if (rx_valid) begin
                sb_h.check_rx_byte(rx_data);
            end
            if (rx_framing_error) begin
                `uvm_error("RX_FRAMING", $sformatf("Framing error asserted while receiving byte 0x%02h", rx_data))
            end
        end
    end
endmodule
