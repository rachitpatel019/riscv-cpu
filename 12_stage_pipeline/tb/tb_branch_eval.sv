`timescale 1ns / 1ps

/**
 * Testbench for Stage 8 Branch Evaluation Module
 */

module tb_branch_eval;
    // Global Counters
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    // Signals
    logic [31:0] pc;
    logic [31:0] imm;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [2:0]  branch_type;
    logic        condition_met;
    logic [31:0] branch_target;

    // DUT Instantiation
    branch_eval dut (.*);

    // Task for driving stimuli
    task drive_branch_eval(
        input logic [31:0] i_pc,
        input logic [31:0] i_imm,
        input logic [31:0] i_op_a,
        input logic [31:0] i_op_b,
        input logic [2:0]  i_br_type
    );
        pc = i_pc;
        imm = i_imm;
        operand_a = i_op_a;
        operand_b = i_op_b;
        branch_type = i_br_type;
        #1;
    endtask

    // Task for checking results
    task check_branch_eval(
        input logic exp_cond,
        input logic [31:0] exp_target
    );
        if (condition_met === exp_cond && branch_target === exp_target) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Type=%b, ExpCond=%b, ActCond=%b, ExpTarget=%h, ActTarget=%h", 
                   $time, branch_type, exp_cond, condition_met, exp_target, branch_target);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting branch_eval Tests ---");

        // 1. BEQ (000)
        drive_branch_eval(32'h100, 32'h8, 32'h5, 32'h5, 3'b000); check_branch_eval(1, 32'h108);
        drive_branch_eval(32'h100, 32'h8, 32'h5, 32'h6, 3'b000); check_branch_eval(0, 32'h108);

        // 2. BNE (001)
        drive_branch_eval(32'h100, 32'h8, 32'h5, 32'h6, 3'b001); check_branch_eval(1, 32'h108);
        drive_branch_eval(32'h100, 32'h8, 32'h5, 32'h5, 3'b001); check_branch_eval(0, 32'h108);

        // 3. BLT (100) - Signed
        drive_branch_eval(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b100); check_branch_eval(1, 32'h108); // -2 < 1
        drive_branch_eval(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b100); check_branch_eval(0, 32'h108); // 1 < -2 (False)

        // 4. BGE (101) - Signed
        drive_branch_eval(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b101); check_branch_eval(1, 32'h108); // 1 >= -2
        drive_branch_eval(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b101); check_branch_eval(0, 32'h108); // -2 >= 1 (False)

        // 5. BLTU (110) - Unsigned
        drive_branch_eval(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b110); check_branch_eval(1, 32'h108); // 1 < large_uint
        drive_branch_eval(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b110); check_branch_eval(0, 32'h108); // large_uint < 1 (False)

        // 6. BGEU (111) - Unsigned
        drive_branch_eval(32'h100, 32'h8, 32'hFFFFFFFE, 32'h00000001, 3'b111); check_branch_eval(1, 32'h108); // large_uint >= 1
        drive_branch_eval(32'h100, 32'h8, 32'h00000001, 32'hFFFFFFFE, 3'b111); check_branch_eval(0, 32'h108); // 1 >= large_uint (False)

        // 7. PC Target with Negative Offset
        drive_branch_eval(32'h100, 32'hFFFFFFF8, 32'h0, 32'h0, 3'b000); check_branch_eval(1, 32'hF8); // PC-8

        // Completion Summary
        $display("--- branch_eval Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
