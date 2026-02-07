// Simple register DUT for UVM smoke testing.
// Intentionally tiny: exercises clk/reset/enable and makes waveform/debug easy.

`timescale 1ns/1ps

module simple_register (
    input  wire       clk,
    input  wire       rst_n,     // Active-low asynchronous reset
    input  wire       enable,
    input  wire [7:0] d,
    output reg  [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 8'h00;
        end else if (enable) begin
            q <= d;
        end
    end
endmodule
