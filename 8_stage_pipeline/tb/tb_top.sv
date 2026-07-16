`timescale 1ns / 1ps

module tb_top;

// Clock and buttons control signals
logic MAX10_CLK1_50;
logic [1:0] KEY;

// Switch inputs
logic [9:0] SW;

// Visual outputs
logic [9:0] LEDR;
logic [6:0] HEX0;
logic [6:0] HEX1;
logic [6:0] HEX2;
logic [6:0] HEX3;
logic [6:0] HEX4;
logic [6:0] HEX5;

// Periodic clock generator
always #10 MAX10_CLK1_50 = ~MAX10_CLK1_50;

// Device under test instantiation
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

// Main simulation execution and watchdog timer
initial begin
    MAX10_CLK1_50 = 0;
    KEY = 2'b11;
    SW = 10'b0;
    #6000;
    $display("[TB] Gate-level simulation completed successfully.");
    $finish;
end

endmodule
