`timescale 1ns / 1ps

module tb_decode;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [31:0] pc;
    logic [31:0] instruction;

    logic [31:0] immediate;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [31:0] pc_out;
    logic uses_rs1;
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

    decode dut (.*);

    task drive_decode(input logic [31:0] i_pc, input logic [31:0] i_instr);
        pc = i_pc;
        instruction = i_instr;
        #1;
    endtask

    task check_decode(
        input logic [4:0] i_rs1, input logic [4:0] i_rs2, input logic [4:0] i_rd,
        input logic [31:0] i_pc_out, input logic [31:0] i_imm
    );
        if (rs1 === i_rs1 && rs2 === i_rs2 && rd === i_rd && 
            pc_out === i_pc_out && immediate === i_imm) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, Instr=%h, Actual: rs1=%d, rs2=%d, rd=%d, pc_out=%h, imm=%h", 
                   $time, instruction, rs1, rs2, rd, pc_out, immediate);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting decode Tests ---");

        // ADD x3, x1, x2 -> 002081b3
        drive_decode(32'h100, 32'h002081b3);
        check_decode(5'd1, 5'd2, 5'd3, 32'h100, 32'h0);

        // ADDI x5, x0, 10 -> 00a00293
        drive_decode(32'h200, 32'h00a00293);
        check_decode(5'd0, 5'd10, 5'd5, 32'h200, 32'd10);

        $display("--- decode Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
