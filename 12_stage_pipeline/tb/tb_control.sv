`timescale 1ns / 1ps

module tb_control;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [31:0] instruction;
    logic uses_rs2;
    logic [3:0] alu_op;
    logic alu_src_a;
    logic alu_src_b;
    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic [1:0] mem_size;
    logic mem_unsigned;
    logic [1:0] wb_sel;
    logic branch;
    logic jump;
    logic [2:0] branch_type;

    control dut (.*);

    import alu_package::*;

    task drive_control(input logic [31:0] i_instr);
        instruction = i_instr;
        #1;
    endtask

    task check_control(
        input logic i_uses_rs2, input logic [3:0] i_alu_op,
        input logic i_alu_src_a, input logic i_alu_src_b,
        input logic i_reg_write, input logic i_mem_read, input logic i_mem_write,
        input logic [1:0] i_mem_size, input logic i_mem_unsigned,
        input logic [1:0] i_wb_sel, input logic i_branch, input logic i_jump,
        input logic [2:0] i_branch_type
    );
        if (uses_rs2 === i_uses_rs2 && alu_op === i_alu_op && 
            alu_src_a === i_alu_src_a && alu_src_b === i_alu_src_b &&
            reg_write === i_reg_write && mem_read === i_mem_read && mem_write === i_mem_write &&
            mem_size === i_mem_size && mem_unsigned === i_mem_unsigned &&
            wb_sel === i_wb_sel && branch === i_branch && jump === i_jump &&
            branch_type === i_branch_type) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Instr=%h, Actual: uses_rs2=%b, alu_op=%b, alu_src_a=%b, alu_src_b=%b, reg_write=%b, mem_read=%b, mem_write=%b, mem_size=%b, mem_unsigned=%b, wb_sel=%b, branch=%b, jump=%b, branch_type=%b", 
                   $time, instruction, uses_rs2, alu_op, alu_src_a, alu_src_b, reg_write, mem_read, mem_write, mem_size, mem_unsigned, wb_sel, branch, jump, branch_type);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting control Tests ---");

        // R-Type (ADD x3, x1, x2) -> 002081b3
        drive_control(32'h002081b3); 
        check_control(1, ALU_ADD, 0, 0, 1, 0, 0, 2'b00, 0, 2'b00, 0, 0, 3'b000);

        // I-Type (ADDI x1, x0, 10) -> 00a00093
        drive_control(32'h00a00093);
        check_control(0, ALU_ADD, 0, 1, 1, 0, 0, 2'b00, 0, 2'b00, 0, 0, 3'b000);

        // LW x1, 4(x2) -> 00412083
        drive_control(32'h00412083);
        check_control(0, ALU_ADD, 0, 1, 1, 1, 0, 2'b10, 0, 2'b01, 0, 0, 3'b010);

        // SW x2, 4(x1) -> 0020a223
        drive_control(32'h0020a223);
        check_control(1, ALU_ADD, 0, 1, 0, 0, 1, 2'b10, 0, 2'b00, 0, 0, 3'b010);

        // BEQ x1, x2, 8 -> 00208463
        drive_control(32'h00208463);
        check_control(1, ALU_SUB, 0, 0, 0, 0, 0, 2'b00, 0, 2'b00, 1, 0, 3'b000);

        // JAL x1, 4 -> 004000ef
        drive_control(32'h004000ef);
        check_control(0, ALU_ADD, 1, 1, 1, 0, 0, 2'b00, 0, 2'b10, 0, 1, 3'b000);

        // Invalid Opcode
        drive_control(32'h00000000);
        check_control(0, ALU_ADD, 0, 0, 0, 0, 0, 2'b00, 0, 2'b00, 0, 0, 3'b000);

        $display("--- control Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
