// Module 7: I2C baseline — top with clk_div + i2c_master, basic directed test.
// C++ drives clk and rst_n only; stimulus and checks are in initial blocks.

`timescale 1ns/1ps

module top_i2c_baseline (
    input  wire clk,
    input  wire rst_n
);
    logic       clk_div_tick;
    logic       start;
    logic [6:0] addr;
    logic [7:0] data_in;
    logic       scl;
    logic       sda;
    logic       busy;
    logic       done;

    // Captured bytes for self-check
    logic [7:0] captured_addr_w;
    logic [7:0] captured_data;

    clk_div #(.DIVIDER(8)) u_clk_div (
        .clk         (clk),
        .rst_n       (rst_n),
        .clk_div_tick(clk_div_tick)
    );

    i2c_master u_i2c (
        .clk         (clk),
        .rst_n       (rst_n),
        .clk_div_tick(clk_div_tick),
        .start       (start),
        .addr        (addr),
        .data_in     (data_in),
        .scl         (scl),
        .sda         (sda),
        .busy        (busy),
        .done        (done)
    );

    // Monitor: detect START, then sample 8 address bits and 8 data bits.
    initial begin : i2c_monitor
        int i;
        captured_addr_w = 8'h00;
        captured_data   = 8'h00;

        wait (rst_n === 1'b1);

        // START: SDA falls while SCL high
        @(negedge sda);
        if (scl !== 1'b1) begin
            $display("[FAIL] I2C baseline: start condition detected but SCL not high");
            $finish;
        end

        // Address + write bit (MSB first)
        for (i = 7; i >= 0; i--) begin
            @(posedge scl);
            captured_addr_w[i] = sda;
        end

        // Data byte (MSB first)
        for (i = 7; i >= 0; i--) begin
            @(posedge scl);
            captured_data[i] = sda;
        end

        // STOP: SDA rises while SCL high
        @(posedge sda);
        if (scl !== 1'b1) begin
            $display("[FAIL] I2C baseline: stop condition detected but SCL not high");
            $finish;
        end

        $display("[INFO] I2C baseline: captured addr_w=0x%02h data=0x%02h", captured_addr_w, captured_data);
    end

    // Directed test + self-check
    initial begin : i2c_test
        start   = 1'b0;
        addr    = 7'h00;
        data_in = 8'h00;

        wait (rst_n === 1'b1);
        repeat (10) @(posedge clk);

        // Single write: address 0x42, data 0xA5
        addr    = 7'h42;
        data_in = 8'hA5;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done === 1'b1);

        // Self-check what we saw on the bus
        if (captured_addr_w !== {addr, 1'b0}) begin
            $display("[FAIL] I2C baseline: expected addr_w=0x%02h got=0x%02h", {addr, 1'b0}, captured_addr_w);
            $finish;
        end

        if (captured_data !== data_in) begin
            $display("[FAIL] I2C baseline: expected data=0x%02h got=0x%02h", data_in, captured_data);
            $finish;
        end

        $display("[PASS] I2C baseline: write transaction observed correctly");
        $display("I2C baseline test PASS");
        $finish;
    end
endmodule
