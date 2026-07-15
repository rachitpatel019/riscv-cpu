`timescale 1ns / 1ps

module tb_top;
    logic        MAX10_CLK1_50;
    logic [1:0]  KEY;
    logic [9:0]  SW;
    logic [9:0]  LEDR;
    logic [6:0]  HEX0;
    logic [6:0]  HEX1;
    logic [6:0]  HEX2;
    logic [6:0]  HEX3;
    logic [6:0]  HEX4;
    logic [6:0]  HEX5;

    // 50 MHz clock generation (20 ns period)
    always #10 MAX10_CLK1_50 = ~MAX10_CLK1_50;

    // Instantiate the top-level design
    top dut (
        .MAX10_CLK1_50(MAX10_CLK1_50),
        .KEY(KEY),
        .SW(SW),
        .LEDR(LEDR),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

    initial begin
        // Initialize inputs
        MAX10_CLK1_50 = 0;
        KEY = 2'b11; // Active-low buttons unpressed
        SW = 10'b0;  // All switches off

        // Run simulation long enough to lock the PLL, release reset,
        // and run 500 clock cycles of 125 MHz clock (500 * 8ns = 4000ns)
        #6000;
        
        $display("[TB] Gate-level simulation completed successfully.");
        $finish;
    end
endmodule
