// Module 5: SPI baseline — top with clk_div + spi_master, basic directed test.
// C++ drives clk and rst_n only; stimulus and checks are in initial blocks.

`timescale 1ns/1ps

module top_spi_baseline (
    input  wire       clk,
    input  wire       rst_n
);
    logic        clk_div_tick;
    logic        start;
    logic [7:0]  data_in;
    logic        sclk;
    logic        mosi;
    logic        cs_n;
    logic        busy;
    logic        done;

    clk_div #(.DIVIDER(8)) u_clk_div (
        .clk         (clk),
        .rst_n       (rst_n),
        .clk_div_tick(clk_div_tick)
    );

    spi_master u_spi (
        .clk         (clk),
        .rst_n       (rst_n),
        .clk_div_tick(clk_div_tick),
        .start       (start),
        .data_in     (data_in),
        .sclk        (sclk),
        .mosi        (mosi),
        .cs_n        (cs_n),
        .busy        (busy),
        .done        (done)
    );

    // Basic directed test: wait for reset release, send bytes, wait for done
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
        wait (done === 1'b1);
        $display("[PASS] SPI baseline: 0x55 transfer done");

        repeat (20) @(posedge clk);

        // Send 0xAA
        @(posedge clk);
        start   = 1'b1;
        data_in = 8'hAA;
        @(posedge clk);
        start   = 1'b0;
        wait (done === 1'b1);
        $display("[PASS] SPI baseline: 0xAA transfer done");

        $display("SPI baseline test PASS");
        $finish;
    end
endmodule
