// Top-level wrapper for spec_to_rtl example.
// Instantiates the counter DUT; C++ harness drives clk, rst_n, enable and reads count.

`timescale 1ns/1ps

module top (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    output wire [7:0] count
);
    counter u_counter (
        .clk    (clk),
        .rst_n  (rst_n),
        .enable (enable),
        .count  (count)
    );
endmodule
