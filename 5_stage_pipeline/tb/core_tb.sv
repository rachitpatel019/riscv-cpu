`timescale 1ns/1ps

module core_tb;
    // DUT Signals
    logic clk;
    logic reset;

    // Instantiate Top-Level CPU
    core dut (.*);

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;
endmodule