// Simple UART transmitter (8N1, no parity) for teaching.
// This version uses an external baud_tick enable (from baud_gen)
// so that each bit lasts many clk cycles in real time, while the
// internal state machine still advances once per baud_tick.

`timescale 1ns/1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,      // Active-low async reset
    input  wire       baud_tick,  // One-cycle pulse at baud rate
    input  wire       start,      // Pulse high for one cycle to start transmit
    input  wire [7:0] data_in,    // Byte to transmit, LSB first on the line
    output reg        tx,         // UART TX line (idle high)
    output reg        busy        // High while frame is in progress
);
    // 10 bits total: 1 start (0), 8 data, 1 stop (1)
    localparam int FRAME_BITS = 10;

    reg [FRAME_BITS-1:0] shift_reg;
    reg [3:0]            bit_idx; // counts 0..9

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx        <= 1'b1;           // idle high
            busy      <= 1'b0;
            shift_reg <= {FRAME_BITS{1'b1}};
            bit_idx   <= 4'd0;
        end else begin
            if (!busy) begin
                // Idle; wait for start pulse.
                tx <= 1'b1;
                if (start) begin
                    // Frame layout: [stop][data7:0][start]
                    shift_reg <= {1'b1, data_in, 1'b0};
                    bit_idx   <= 4'd0;
                    busy      <= 1'b1;
                    tx        <= 1'b0; // first bit is start bit
                end
            end else begin
                // Transmitting: shift once per baud_tick, so each bit
                // lasts DIVIDER cycles of the input clk.
                if (baud_tick) begin
                    bit_idx   <= bit_idx + 1'b1;
                    shift_reg <= {1'b1, shift_reg[FRAME_BITS-1:1]}; // shift right, fill with 1s
                    tx        <= shift_reg[1]; // next bit moves into position 0 after shift

                    if (bit_idx == FRAME_BITS-1) begin
                        busy <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
