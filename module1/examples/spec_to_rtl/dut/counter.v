// 8-bit up-counter — RTL implementation per SPEC.md
// Module 1: Spec → RTL methodology example.

`timescale 1ns/1ps

module counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    output reg  [7:0] count
);
    always @(posedge clk) begin
        if (!rst_n)
            count <= 8'h00;
        else if (enable)
            count <= count + 8'd1;
    end
endmodule
