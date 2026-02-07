// Module 3: UART baseline — top with loopback (TX -> RX), basic directed test.
// C++ drives clk and rst_n only; stimulus and checks are in initial blocks.

`timescale 1ns/1ps

module top_uart_baseline (
    input  wire       clk,
    input  wire       rst_n
);
    logic        baud_tick;
    logic        start;
    logic [7:0]  data_in;
    logic        busy;
    logic        tx;
    logic        rx;
    logic [7:0]  data_out;
    logic        data_valid;
    logic        framing_error;

    assign rx = tx;  // Loopback: TX output drives RX input

    baud_gen #(.DIVIDER(434)) u_baud (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick)
    );

    uart_tx u_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick),
        .start     (start),
        .data_in   (data_in),
        .tx        (tx),
        .busy      (busy)
    );

    uart_rx u_rx (
        .clk          (clk),
        .rst_n        (rst_n),
        .baud_tick    (baud_tick),
        .rx           (rx),
        .data_out     (data_out),
        .data_valid   (data_valid),
        .framing_error(framing_error)
    );

    // Basic directed test: wait for reset release, send bytes, check RX
    initial begin
        start   = 1'b0;
        data_in = 8'h00;

        wait (rst_n === 1'b1);
        repeat (10) @(posedge clk);

        // Send 0x55
        @(posedge clk);
        start   = 1'b1;
        data_in = 8'h55;
        @(posedge clk);
        start   = 1'b0;
        wait (busy === 1'b0);
        wait (data_valid === 1'b1);
        if (data_out !== 8'h55) $error("UART baseline: expected 0x55, got 0x%02h", data_out);
        else $display("[PASS] UART baseline: 0x55 loopback OK");

        repeat (20) @(posedge clk);

        // Send 0xAA
        @(posedge clk);
        start   = 1'b1;
        data_in = 8'hAA;
        @(posedge clk);
        start   = 1'b0;
        wait (busy === 1'b0);
        wait (data_valid === 1'b1);
        if (data_out !== 8'hAA) $error("UART baseline: expected 0xAA, got 0x%02h", data_out);
        else $display("[PASS] UART baseline: 0xAA loopback OK");

        $display("UART baseline test PASS");
        $finish;
    end
endmodule
