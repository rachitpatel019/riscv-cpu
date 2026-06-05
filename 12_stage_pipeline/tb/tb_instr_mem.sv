`timescale 1ns / 1ps

module tb_instr_mem;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic clk = 0;
    logic reset;
    logic stall;
    logic flush;
    logic [31:0] pc;
    logic [31:0] pc_out;
    logic [31:0] instruction;

    instr_mem dut (.*);

    always #5 clk = ~clk;

    task drive_instr_mem(
        input logic i_stall,
        input logic i_flush,
        input logic [31:0] i_pc
    );
        @(negedge clk);
        stall = i_stall;
        flush = i_flush;
        pc = i_pc;
    endtask

    task check_instr_mem(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_instr
    );
        @(posedge clk);
        #1;
        if (pc_out === expected_pc && instruction === expected_instr) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Expected PC=%h, Actual PC=%h, Expected Instr=%h, Actual Instr=%h", 
                   $time, expected_pc, pc_out, expected_instr, instruction);
        end
        tests_total++;
    endtask

    initial begin
        reset = 1; stall = 0; flush = 0; pc = 0;
        repeat(2) @(negedge clk);
        reset = 0;

        $display("--- Starting instr_mem Tests ---");

        // 1. Sequential Fetching (using program.hex values)
        // 0: 00a00093
        // 4: 01400113
        // 8: 002081b3
        drive_instr_mem(0, 0, 32'h0); check_instr_mem(32'h0, 32'h00a00093);
        drive_instr_mem(0, 0, 32'h4); check_instr_mem(32'h4, 32'h01400113);
        drive_instr_mem(0, 0, 32'h8); check_instr_mem(32'h8, 32'h002081b3);

        // 2. Stall Behavior
        drive_instr_mem(1, 0, 32'hC); check_instr_mem(32'h8, 32'h002081b3); // Still 8
        drive_instr_mem(1, 0, 32'h10); check_instr_mem(32'h8, 32'h002081b3);

        // Resume
        drive_instr_mem(0, 0, 32'hC); check_instr_mem(32'hC, 32'h00302023);

        // 3. Unaligned/Out-of-Bounds
        drive_instr_mem(0, 0, 32'h00000001); check_instr_mem(32'h00000001, 32'h00a00093); // PC[31:2] is 0

        $display("--- instr_mem Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
