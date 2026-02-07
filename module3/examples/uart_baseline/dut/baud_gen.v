// Simple baud-rate generator for teaching.
// Divides the input clock down to a 1-cycle-wide baud_tick pulse.
//
// Example: For a 50 MHz system clock and 115200 baud target,
// DIVIDER ≈ 50_000_000 / 115200 ≈ 434.

`timescale 1ns/1ps

module baud_gen #(
    parameter int DIVIDER = 434  // Default divider, can be overridden
) (
    input  wire clk,
    input  wire rst_n,      // Active-low async reset
    output reg  baud_tick   // One-cycle pulse at baud rate
);
    int count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count     <= 0;
            baud_tick <= 1'b0;
        end else begin
            if (count == DIVIDER - 1) begin
                count     <= 0;
                baud_tick <= 1'b1;
            end else begin
                count     <= count + 1;
                baud_tick <= 1'b0;
            end
        end
    end

endmodule
