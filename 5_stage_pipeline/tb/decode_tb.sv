`timescale 1ns/1ps

module decode_tb;

import decoder_package::*;
import alu_package::*;

// DUT Signals
logic clk;
logic [31:0] pc;
logic [31:0] instruction;

// Write-back interface
logic reg_write_wb;
logic [4:0]  rd_wb;
logic [31:0] write_data_wb;

// Outputs
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] immediate;
logic [4:0]  rs1;
logic [4:0]  rs2;
logic [4:0]  rd;
logic [31:0] pc_out;

// Control signals
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

// Clock
initial clk = 0;
always #5 clk = ~clk;

// Counters
int test_count = 0;
int fail_count = 0;

task test_decode(
    input logic [31:0] Instruction,
    input logic [31:0] Pc,

    // Write-back
    input logic regWriteWb,
    input logic [4:0] rdWb,
    input logic [31:0] writeDataWb,

    // Expected outputs
    input logic [31:0] expectedRs1Data,
    input logic [31:0] expectedRs2Data,
    input logic [31:0] expectedImmediate,
    input logic [4:0]  expectedRs1,
    input logic [4:0]  expectedRs2,
    input logic [4:0]  expectedRd,
    input logic [31:0] expectedPcOut,

    input logic [3:0] expectedAluOp,
    input logic expectedAluSrcA,
    input logic expectedAluSrcB,
    input logic expectedRegWrite,
    input logic expectedMemRead,
    input logic expectedMemWrite,
    input logic [1:0] expectedMemSize,
    input logic expectedMemUnsigned,
    input logic [1:0] expectedWbSel,
    input logic expectedBranch,
    input logic expectedJump,
    input logic [2:0] expectedBranchType
);
begin
    test_count++;

    // Apply write-back first
    reg_write_wb = regWriteWb;
    rd_wb = rdWb;
    write_data_wb = writeDataWb;
    pc = Pc;

    @(posedge clk); // commit write

    // Apply instruction
    instruction = Instruction;

    #1; // allow combinational logic to settle

    // Checks
    if (
        rs1_data !== expectedRs1Data ||
        rs2_data !== expectedRs2Data ||
        immediate !== expectedImmediate ||
        rs1 !== expectedRs1 ||
        rs2 !== expectedRs2 ||
        rd  !== expectedRd ||
        pc_out !== expectedPcOut ||
        alu_op !== expectedAluOp ||
        alu_src_a !== expectedAluSrcA ||
        alu_src_b !== expectedAluSrcB ||
        reg_write !== expectedRegWrite ||
        mem_read !== expectedMemRead ||
        mem_write !== expectedMemWrite ||
        mem_size !== expectedMemSize ||
        mem_unsigned !== expectedMemUnsigned ||
        wb_sel !== expectedWbSel ||
        branch !== expectedBranch ||
        jump !== expectedJump ||
        branch_type !== expectedBranchType
    ) begin
        fail_count++;
        $display("Test %0d FAILED", test_count);
        $display("Instruction = %h", Instruction);
    end
    else begin
        $display("Test %0d PASSED", test_count);
    end

end
endtask


// Test Cases
initial begin
    // Initialize
    instruction = 0;
    reg_write_wb = 0;
    rd_wb = 0;
    write_data_wb = 0;

    @(posedge clk);

    // Preload registers
    test_decode(32'b0, 32'd100, 1, 5'd1, 32'd10, 0,0,0,0,0,0, 32'd100, ALU_ADD, 0,0, 0,0,0, 2'b00, 0, 2'b00, 0,0, 3'b000);
    test_decode(32'b0, 32'd100, 1, 5'd2, 32'd20, 0,0,0,0,0,0, 32'd100, ALU_ADD, 0,0, 0,0,0, 2'b00, 0, 2'b00, 0,0, 3'b000);

    // ADD x3, x1, x2
    test_decode(
        32'b0000000_00010_00001_000_00011_0110011,
        32'd100,
        0,0,0,
        32'd10,
        32'd20,
        32'd0,
        5'd1,
        5'd2,
        5'd3,
        32'd100,
        ALU_ADD,
        0,0,
        1,0,0,
        2'b00, 0, 2'b00,
        0,0,
        3'b000
    );

    // ADDI x4, x1, 5
    test_decode(
        32'b000000000101_00001_000_00100_0010011,
        32'd100,
        0,0,0,
        32'd10,
        32'd0,
        32'd5,
        5'd1,
        5'd5,
        5'd4,
        32'd100,
        ALU_ADD,
        0,1,
        1,0,0,
        2'b00, 0, 2'b00,
        0,0,
        3'b000
    );

    // LW x5, 8(x1)
    test_decode(
        32'b000000001000_00001_010_00101_0000011,
        32'd100,
        0,0,0,
        32'd10,
        32'd0,
        32'd8,
        5'd1,
        5'd8,
        5'd5,
        32'd100,
        ALU_ADD,
        0,1,
        1,1,0,
        2'b10, 0, 2'b01,
        0,0,
        3'b010
    );

    // SW x2, 4(x1)
    test_decode(
        32'b0000000_00010_00001_010_00100_0100011,
        32'd100,
        0,0,0,
        32'd10,
        32'd20,
        32'd4,
        5'd1,
        5'd2,
        5'd4,
        32'd100,
        ALU_ADD,
        0,1,
        0,0,1,
        2'b10, 0, 2'b00,
        0,0,
        3'b010
    );

    // BEQ x1, x2, 4
    test_decode(
        32'b0000000_00010_00001_000_00100_1100011,
        32'd100,
        0,0,0,
        32'd10,
        32'd20,
        32'd4,
        5'd1,
        5'd2,
        5'd4,
        32'd100,
        ALU_SUB,
        0,0,
        0,0,0,
        2'b00, 0, 2'b00,
        1,0,
        3'b000
    );

    // JAL x1
    test_decode(
        32'b00000000010000000000_00001_1101111,
        32'd100,
        0,0,0,
        32'd0,
        32'd0,
        32'd4,
        5'd0,
        5'd4,
        5'd1,
        32'd100,
        ALU_ADD,
        1,1,
        1,0,0,
        2'b00, 0, 2'b10,
        0,1,
        3'b000
    );

    // Report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule