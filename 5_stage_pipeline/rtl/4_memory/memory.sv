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

// Reservation Station for LR/SC
logic reservation_valid;
logic [31:0] reservation_address;

always_ff @(posedge clk) begin
    if (reset) begin
        reservation_valid <= 1'b0;
        reservation_address <= 32'b0;
    end
    else if (is_lr) begin
        reservation_valid <= 1'b1;
        reservation_address <= alu_result; // The memory address
    end
    else if (is_sc) begin
        reservation_valid <= 1'b0; // Any SC clears the reservation
    end
end

logic sc_success;
assign sc_success = is_sc && reservation_valid && (reservation_address == alu_result);

// Determine actual write enable for data memory
logic actual_mem_write;
assign actual_mem_write = mem_write && (!is_sc || sc_success);

// AMO ALU
logic [31:0] amo_result;
logic [31:0] raw_read_data;

amo_alu amo_alu_inst (
    .mem_read_data(raw_read_data),
    .rs2_data(rs2_data),
    .amo_op(amo_op),
    .amo_result(amo_result)
);

// Determine data to write to memory
logic [31:0] actual_write_data;
always_comb begin
    if (is_atomic && !is_sc && !is_lr) begin
        actual_write_data = amo_result;
    end
    else begin
        actual_write_data = rs2_data; // Store or SC uses rs2_data directly
    end
end

// Data memory instance
data_mem dmem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(actual_mem_write),
    .address(alu_result),
    .write_data(actual_write_data),
    .read_data(raw_read_data),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned)
);

// Determine read data to pass to Writeback
always_comb begin
    if (is_sc) begin
        read_data = sc_success ? 32'b0 : 32'b1; // SC writes success/fail to rd
    end
    else begin
        read_data = raw_read_data; // Normal loads, LR, and AMO write raw mem data to rd
    end
end

endmodule