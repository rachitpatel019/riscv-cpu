`timescale 1ns/1ps

module alu_tb;

import alu_package::*;

// DUT Signals
logic [31:0] A; // operand 1
logic [31:0] B; // operand 2
alu_operations control; // operation
logic [31:0] result; // result

// Instantiate DUT
alu dut (.*);

// Counters
int test_count = 0;
int fail_count = 0;

// Test Task
task run_test(
    input logic [31:0] a,
    input logic [31:0] b,
    input alu_operations ctrl,
    input logic [31:0] expected
);
begin
    A = a;
    B = b;
    control = ctrl;
    #1;

    test_count++;

    if (result !== expected) begin
        fail_count++;
        $display("[%0t] FAIL: OP=%s A=%h B=%h | Expected=%h Got=%h", $time, ctrl.name(), a, b, expected, result);
    end
    else begin
        $display("[%0t] PASS: OP=%s A=%h B=%h Result=%h", $time, ctrl.name(), a, b, result);
    end
end
endtask

// Test Cases
initial begin
    #1;

    // ADD
    run_test(32'd10, 32'd5, ALU_ADD, 32'd15);
    run_test(32'd0, 32'd0, ALU_ADD, 32'd0);
    run_test(-32'd5, 32'd10, ALU_ADD, 32'd5);
    run_test(32'h7FFFFFFF, 32'd1, ALU_ADD, 32'h80000000);
    run_test(32'hFFFFFFFF, 32'd1, ALU_ADD, 32'h00000000);

    // SUBTRACT
    run_test(32'd10, 32'd5, ALU_SUB, 32'd5);
    run_test(32'd5, 32'd10, ALU_SUB, -32'd5);
    run_test(-32'd10, -32'd5, ALU_SUB, -32'd5);
    run_test(32'd0, 32'd1, ALU_SUB, -32'd1);
    run_test(32'h80000000, 32'd1, ALU_SUB, 32'h7FFFFFFF);

    // AND
    run_test(32'hF0F0F0F0, 32'h0F0F0F0F, ALU_AND, 32'h00000000);
    run_test(32'hFFFFFFFF, 32'h00000000, ALU_AND, 32'h00000000);
    run_test(32'hAAAAAAAA, 32'h55555555, ALU_AND, 32'h00000000);
    run_test(32'hFFFFFFFF, 32'hFFFFFFFF, ALU_AND, 32'hFFFFFFFF);

    // OR
    run_test(32'hF0F0F0F0, 32'h0F0F0F0F, ALU_OR, 32'hFFFFFFFF);
    run_test(32'hAAAAAAAA, 32'h55555555, ALU_OR, 32'hFFFFFFFF);
    run_test(32'h00000000, 32'h00000000, ALU_OR, 32'h00000000);

    // XOR
    run_test(32'hAAAAAAAA, 32'h55555555, ALU_XOR, 32'hFFFFFFFF);
    run_test(32'hFFFFFFFF, 32'hFFFFFFFF, ALU_XOR, 32'h00000000);
    run_test(32'h12345678, 32'hFFFFFFFF, ALU_XOR, 32'hEDCBA987);

    // UNSIGNED LESS THAN
    run_test(32'd5, 32'd10, ALU_SLTU, 32'd1);
    run_test(32'd10, 32'd5, ALU_SLTU, 32'd0);
    run_test(32'hFFFFFFFF, 32'd0, ALU_SLTU, 32'd0);
    run_test(32'd0, 32'hFFFFFFFF, ALU_SLTU, 32'd1);

    // SIGNED LESS THAN
    run_test(-32'd5, 32'd3, ALU_SLT, 32'd1);
    run_test(32'd5, -32'd3, ALU_SLT, 32'd0);
    run_test(-32'd10, -32'd5, ALU_SLT, 32'd1);
    run_test(32'h80000000, 32'd0, ALU_SLT, 32'd1);
    run_test(32'd0, 32'h80000000, ALU_SLT, 32'd0);

    // SHIFT LEFT LOGICAL
    run_test(32'd1, 32'd1, ALU_SLL, 32'd2);
    run_test(32'd1, 32'd31, ALU_SLL, 32'h80000000);
    run_test(32'hFFFFFFFF, 32'd4, ALU_SLL, 32'hFFFFFFF0);
    run_test(32'd1, 32'd32, ALU_SLL, 32'd1);

    // SHIFT RIGHT LOGICAL
    run_test(32'h80000000, 32'd1, ALU_SRL, 32'h40000000);
    run_test(32'hFFFFFFFF, 32'd4, ALU_SRL, 32'h0FFFFFFF);
    run_test(32'd1, 32'd31, ALU_SRL, 32'd0);

    // SHIFT RIGHT ARITHMETIC
    run_test(-32'd1, 32'd1, ALU_SRA, 32'hFFFFFFFF);
    run_test(32'h80000000, 32'd1, ALU_SRA, 32'hC0000000);
    run_test(-32'd16, 32'd2, ALU_SRA, -32'd4);
    run_test(32'd16, 32'd2, ALU_SRA, 32'd4);

    // Summary
    $display("======================================");
    if (fail_count == 0)
        $display("ALL TESTS PASSED (%0d tests)", test_count);
    else
        $display("FAILED: %0d / %0d tests", fail_count, test_count);
    $display("======================================");

    $finish;
end

endmodule