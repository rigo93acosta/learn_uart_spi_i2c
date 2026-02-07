// Simple UART receiver (8N1, no parity) for teaching.
// This version uses an external baud_tick enable (from baud_gen)
// so that each bit lasts many clk cycles in real time, while the
// RX state machine advances once per baud_tick.
//
// Protocol:
//   - Idle line is high.
//   - Start bit is a single low bit.
//   - 8 data bits follow, LSB first, one per clock.
//   - Stop bit is a single high bit.
//
// This RX block watches the serial line for a start bit, then samples
// one bit per clock to reconstruct the byte. When a full frame has
// been received, it pulses `data_valid` for one cycle with `data_out`.

`timescale 1ns/1ps

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,       // Active-low async reset
    input  wire       baud_tick,   // One-cycle pulse at baud rate
    input  wire       rx,          // UART RX line (idle high)
    output reg  [7:0] data_out,    // Reconstructed byte
    output reg        data_valid,  // One-cycle pulse when data_out is valid
    output reg        framing_error// High for one cycle when stop bit is bad
);
    // 10 bits total in a frame: 1 start, 8 data, 1 stop
    localparam int FRAME_BITS = 10;

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state;
    reg [2:0] bit_idx;      // counts data bits 0..7
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            bit_idx    <= 3'd0;
            shift_reg    <= 8'h00;
            data_out     <= 8'h00;
            data_valid   <= 1'b0;
            framing_error<= 1'b0;
        end else begin
            // Default: deassert data_valid and framing_error unless we complete a frame.
            data_valid    <= 1'b0;
            framing_error <= 1'b0;

            case (state)
                IDLE: begin
                    // Wait for start bit: line goes low from idle high.
                    if (rx == 1'b0) begin
                        state   <= START;
                        bit_idx <= 3'd0;
                    end
                end

                START: begin
                    // Wait for the next baud_tick to begin sampling data bits.
                    if (baud_tick) begin
                        state <= DATA;
                    end
                end

                DATA: begin
                    // Sample one data bit per baud_tick, LSB first.
                    if (baud_tick) begin
                        shift_reg[bit_idx] <= rx;
                        if (bit_idx == 3'd7) begin
                            state   <= STOP;
                            bit_idx <= 3'd0;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end
                end

                STOP: begin
                    // One stop bit (should be high). Flag a framing error
                    // if the line is not high when we sample here.
                    data_out     <= shift_reg;
                    data_valid   <= 1'b1;
                    framing_error<= (rx != 1'b1);
                    state        <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
