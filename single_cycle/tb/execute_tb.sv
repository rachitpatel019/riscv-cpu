`timescale 1ns/1ps

module execute_tb;

// DUT Signals
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] imm;
logic alu_src;
logic [3:0] alu_op;

logic [31:0] alu_result;

// Instantiate DUT
execute dut (.*);

// Test tracking
int test_count = 0;
int fail_count = 0;

task run_test(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] immediate,
    input logic src_sel,
    input logic [3:0] op,
    input logic [31:0] expected
);
begin
    test_count++;

    rs1_data = a;
    rs2_data = b;
    imm = immediate;
    alu_src = src_sel;
    alu_op = op;

    #1; // wait for combinational logic

    if (alu_result !== expected) begin
        $display("Test %0d FAILED", test_count);
        $display("  rs1=%0d rs2=%0d imm=%0d alu_src=%0b alu_op=%0d", a, b, immediate, src_sel, op);
        $display("  Expected=%0d, Got=%0d\n", expected, alu_result);
        fail_count++;
    end else begin
        $display("Test %0d PASSED", test_count);
    end
end
endtask

// Test Cases
initial begin

    // ADD (rs2 path)
    run_test(10, 5,  100, 0, 0, 15);  // 10 + 5

    // ADDI (imm path)
    run_test(10, 5,  20, 1, 0, 30);   // 10 + 20

    // SUB (rs2 path)
    run_test(15, 5,  0, 0, 1, 10);    // 15 - 5

    // SUBI (imm path)
    run_test(15, 999, 3, 1, 1, 12);   // 15 - 3

    // AND
    run_test(6, 3, 0, 0, 2, 6 & 3);

    // OR
    run_test(6, 3, 0, 0, 3, 6 | 3);

    // Edge Case: Zero
    run_test(0, 0, 0, 0, 0, 0);

    // Edge Case: Negative (2's complement)
    run_test(-5, 3, 0, 0, 0, -2);

    // Large Numbers
    run_test(32'h7FFFFFFF, 1, 0, 0, 0, 32'h80000000);

    // Testing report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule