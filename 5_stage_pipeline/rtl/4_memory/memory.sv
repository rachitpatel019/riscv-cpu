// Memory stage of the 5-stage RISC-V pipeline.

module memory (
    input logic clk,
    input logic reset,
    input logic [31:0] alu_result,
    input logic [31:0] rs2_data,
    input logic mem_read,
    input logic mem_write,
    input logic [1:0] mem_size,
    input logic mem_unsigned,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic reg_write,
    
    // Atomic control signals
    input logic is_atomic,
    input logic [4:0] amo_op,

    // Data Memory Interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_write_data,
    output logic        dmem_mem_read,
    output logic        dmem_mem_write,
    output logic [1:0]  dmem_size,
    output logic        dmem_unsigned,
    input  logic [31:0] dmem_read_data,
    output logic        dmem_is_lr,
    output logic        dmem_is_sc,
    input  logic        dmem_sc_success,

    output logic [31:0] read_data,
    output logic [31:0] alu_result_output,
    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,
    output logic [4:0] rd_out,
    output logic reg_write_out
);

import decoder_package::*;

// Pass-through
assign alu_result_output = alu_result;
assign rs1_out = rs1;
assign rs2_out = rs2;
assign rd_out = rd;
assign reg_write_out = reg_write;

// Atomic Memory Operation logic
logic is_lr, is_sc;
assign is_lr = is_atomic && (amo_op == AMO_LR);
assign is_sc = is_atomic && (amo_op == AMO_SC);

// AMO ALU
logic [31:0] amo_result;
amo_alu amo_alu_inst (
    .mem_read_data(dmem_read_data),
    .rs2_data(rs2_data),
    .amo_op(amo_op),
    .amo_result(amo_result)
);

// Interface assignments
assign dmem_addr = alu_result;
assign dmem_mem_read = mem_read;
assign dmem_mem_write = mem_write;
assign dmem_size = mem_size;
assign dmem_unsigned = mem_unsigned;
assign dmem_is_lr = is_lr;
assign dmem_is_sc = is_sc;

// Determine data to write to memory
always_comb begin
    if (is_atomic && !is_sc && !is_lr) begin
        dmem_write_data = amo_result;
    end
    else begin
        dmem_write_data = rs2_data;
    end
end

// Determine read data to pass to Writeback
always_comb begin
    if (is_sc) begin
        read_data = dmem_sc_success ? 32'b0 : 32'b1;
    end
    else begin
        read_data = dmem_read_data;
    end
end

endmodule