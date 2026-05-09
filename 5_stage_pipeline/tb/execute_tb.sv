`timescale 1ns/1ps

module execute_tb;

// DUT Signals - Inputs
logic [31:0] pc;
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] imm;
logic alu_src_a;
logic alu_src_b;
logic [3:0] alu_op;
logic branch;
logic jump;
logic [2:0] branch_type;

// DUT Signals - Outputs
logic [31:0] alu_result;
logic [31:0] pc_target;
logic pc_sel;

// Instantiate DUT
execute dut (.*);

// Test tracking
int test_count = 0;
int fail_count = 0;

task run_test(
    input logic [31:0] test_pc,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] immediate,
    input logic src_a_sel,
    input logic src_b_sel,
    input logic [3:0] op,
    input logic br,
    input logic jmp,
    input logic [2:0] br_type,
    input logic [31:0] expected_alu,
    input logic expected_pc_sel,
    input logic [31:0] expected_pc_target
);
begin
    test_count++;

    pc = test_pc;
    rs1_data = a;
    rs2_data = b;
    imm = immediate;
    alu_src_a = src_a_sel;
    alu_src_b = src_b_sel;
    alu_op = op;
    branch = br;
    jump = jmp;
    branch_type = br_type;

    #1; // wait for combinational logic

    if (alu_result !== expected_alu) begin
        $display("Test %0d FAILED - ALU Result", test_count);
        $display("  Expected ALU=%0d, Got=%0d\n", expected_alu, alu_result);
        fail_count++;
    end else if (pc_sel !== expected_pc_sel) begin
        $display("Test %0d FAILED - PC Selection", test_count);
        $display("  Expected pc_sel=%0b, Got=%0b\n", expected_pc_sel, pc_sel);
        fail_count++;
    end else if ((expected_pc_sel) && (pc_target !== expected_pc_target)) begin
        $display("Test %0d FAILED - PC Target", test_count);
        $display("  Expected pc_target=%0d, Got=%0d\n", expected_pc_target, pc_target);
        fail_count++;
    end else begin
        $display("Test %0d PASSED", test_count);
    end
end
endtask

// Test Cases
initial begin

    // ===== ALU Operations (no branching) =====
    
    // ADD (rs2 path, operand_a=rs1, operand_b=rs2)
    run_test(32'h1000, 10, 5, 100, 0, 0, 4'b0000, 0, 0, 3'b000, 15, 0, 0);

    // ADDI (imm path, operand_a=rs1, operand_b=imm)
    run_test(32'h1000, 10, 5, 20, 0, 1, 4'b0000, 0, 0, 3'b000, 30, 0, 0);

    // SUB (rs2 path)
    run_test(32'h1000, 15, 5, 0, 0, 0, 4'b0001, 0, 0, 3'b000, 10, 0, 0);

    // SUBI (imm path)
    run_test(32'h1000, 15, 999, 3, 0, 1, 4'b0001, 0, 0, 3'b000, 12, 0, 0);

    // AND
    run_test(32'h1000, 6, 3, 0, 0, 0, 4'b0010, 0, 0, 3'b000, 2, 0, 0);

    // OR
    run_test(32'h1000, 6, 3, 0, 0, 0, 4'b0011, 0, 0, 3'b000, 7, 0, 0);

    // Edge Case: Zero
    run_test(32'h1000, 0, 0, 0, 0, 0, 4'b0000, 0, 0, 3'b000, 0, 0, 0);

    // Edge Case: Negative (2's complement)
    run_test(32'h1000, -5, 3, 0, 0, 0, 4'b0000, 0, 0, 3'b000, -2, 0, 0);

    // Large Numbers
    run_test(32'h1000, 32'h7FFFFFFF, 1, 0, 0, 0, 4'b0000, 0, 0, 3'b000, 32'h80000000, 0, 0);

    // ===== Branch Tests (BEQ - branch_type = 3'b000) =====
    
    // BEQ: Equal values, should branch (ALU computes 10+10=20)
    run_test(32'h1000, 10, 10, 20, 0, 0, 4'b0000, 1, 0, 3'b000, 20, 1, 32'h1014);

    // BEQ: Unequal values, should not branch (ALU computes 10+5=15)
    run_test(32'h1000, 10, 5, 20, 0, 0, 4'b0000, 1, 0, 3'b000, 15, 0, 0);

    // ===== Branch Tests (BNE - branch_type = 3'b001) =====
    
    // BNE: Not equal, should branch (ALU computes 10+5=15)
    run_test(32'h1000, 10, 5, 20, 0, 0, 4'b0000, 1, 0, 3'b001, 15, 1, 32'h1014);

    // BNE: Equal, should not branch (ALU computes 10+10=20)
    run_test(32'h1000, 10, 10, 20, 0, 0, 4'b0000, 1, 0, 3'b001, 20, 0, 0);

    // ===== Branch Tests (BLT - branch_type = 3'b100) =====
    
    // BLT: rs1 < rs2 (signed), should branch (ALU computes -5+3=-2)
    run_test(32'h1000, -5, 3, 20, 0, 0, 4'b0000, 1, 0, 3'b100, -2, 1, 32'h1014);

    // BLT: rs1 >= rs2, should not branch (ALU computes 5+3=8)
    run_test(32'h1000, 5, 3, 20, 0, 0, 4'b0000, 1, 0, 3'b100, 8, 0, 0);

    // ===== Branch Tests (BGE - branch_type = 3'b101) =====
    
    // BGE: rs1 >= rs2 (signed), should branch (ALU computes 5+3=8)
    run_test(32'h1000, 5, 3, 20, 0, 0, 4'b0000, 1, 0, 3'b101, 8, 1, 32'h1014);

    // BGE: rs1 < rs2, should not branch (ALU computes -5+3=-2)
    run_test(32'h1000, -5, 3, 20, 0, 0, 4'b0000, 1, 0, 3'b101, -2, 0, 0);

    // ===== Branch Tests (BLTU - branch_type = 3'b110) =====
    
    // BLTU: rs1 < rs2 (unsigned), should branch (ALU computes 0x00000001 + 0xFFFFFFFF = 0x00000000 with overflow)
    run_test(32'h1000, 32'h00000001, 32'hFFFFFFFF, 20, 0, 0, 4'b0000, 1, 0, 3'b110, 32'h00000000, 1, 32'h1014);

    // BLTU: rs1 >= rs2 (unsigned), should not branch (ALU computes 0xFFFFFFFF + 0x00000001 = 0x00000000 with overflow)
    run_test(32'h1000, 32'hFFFFFFFF, 32'h00000001, 20, 0, 0, 4'b0000, 1, 0, 3'b110, 32'h00000000, 0, 0);

    // ===== Branch Tests (BGEU - branch_type = 3'b111) =====
    
    // BGEU: rs1 >= rs2 (unsigned), should branch (ALU computes 0xFFFFFFFF + 0x00000001 = 0x00000000 with overflow)
    run_test(32'h1000, 32'hFFFFFFFF, 32'h00000001, 20, 0, 0, 4'b0000, 1, 0, 3'b111, 32'h00000000, 1, 32'h1014);

    // BGEU: rs1 < rs2 (unsigned), should not branch (ALU computes 0x00000001 + 0xFFFFFFFF = 0x00000000 with overflow)
    run_test(32'h1000, 32'h00000001, 32'hFFFFFFFF, 20, 0, 0, 4'b0000, 1, 0, 3'b111, 32'h00000000, 0, 0);

    // ===== Jump Tests (JAL/JALR - jump = 1) =====
    
    // JAL: Always jumps, alu_src_a=1 and alu_src_b=1 to compute pc+imm=0x1000+100=0x1064
    // pc_target = {alu_result[31:1], 1'b0} = {0x1064[31:1], 0} = 0x1064
    run_test(32'h1000, 10, 5, 100, 1, 1, 4'b0000, 0, 1, 3'b000, 32'h1064, 1, 32'h1064);

    // Testing report
    $display("\n========== Test Summary ==========");
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    if (fail_count == 0) begin
        $display("ALL TESTS PASSED!");
    end
    $finish;
end

endmodule