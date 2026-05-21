/* ID/EX pipeline register for the 5-stage RISC-V pipeline.
TODO: Add register for the next program counter value to support branch and jump instructions.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module ID_EX (
    input logic clk,
    input logic reset,
    input logic stall,
    input logic flush,

    // Outputs to execute stage
    input logic [31:0] rs1_data_in,
    input logic [31:0] rs2_data_in,
    input logic [31:0] immediate_in,
    input logic [4:0]  rs1_in,
    input logic [4:0]  rs2_in,
    input logic [4:0]  rd_in,
    input logic [31:0] pc_in,

    // Control signals
    input logic [3:0] alu_op_in,
    input logic alu_src_a_in,
    input logic alu_src_b_in,
    input logic reg_write_in,
    input logic mem_read_in,
    input logic mem_write_in,
    input logic [1:0] mem_size_in,
    input logic mem_unsigned_in,
    input logic [1:0] wb_sel_in,
    input logic branch_in,
    input logic jump_in,
    input logic [2:0] branch_type_in,
    input logic uses_rs2_in,
    input logic is_atomic_in,
    input logic [4:0] amo_op_in,

    // Outputs to execute stage
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] immediate_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,
    output logic [31:0] pc_out,
    output logic uses_rs2_out,

    // Control signals
    output logic [3:0] alu_op_out,
    output logic alu_src_a_out,
    output logic alu_src_b_out,
    output logic reg_write_out,
    output logic mem_read_out,
    output logic mem_write_out,
    output logic [1:0] mem_size_out,
    output logic mem_unsigned_out,
    output logic [1:0] wb_sel_out,
    output logic branch_out,
    output logic jump_out,
    output logic [2:0] branch_type_out,
    output logic is_atomic_out,
    output logic [4:0] amo_op_out
);

// Register data signals are now pass-through because regfile is synchronous
assign rs1_data_out = rs1_data_in;
assign rs2_data_out = rs2_data_in;

always_ff @(posedge clk) begin
    if (reset || flush || stall) begin
        // Outputs to execute stage
        immediate_out <= 32'b0;
        rs1_out <= 5'b0;
        rs2_out <= 5'b0;
        rd_out <= 5'b0;
        pc_out <= 32'b0;

        // Control signals
        alu_op_out <= 4'b0;
        alu_src_a_out <= 1'b0;
        alu_src_b_out <= 1'b0;
        reg_write_out <= 1'b0;
        mem_read_out <= 1'b0;
        mem_write_out <= 1'b0;
        mem_size_out <= 2'b0;
        mem_unsigned_out <= 1'b0;
        wb_sel_out <= 2'b0;
        branch_out <= 1'b0;
        jump_out <= 1'b0;
        branch_type_out <= 3'b0;
        uses_rs2_out <= 1'b0;
        is_atomic_out <= 1'b0;
        amo_op_out <= 5'b0;
    end
    else begin
        // Outputs to execute stage
        immediate_out <= immediate_in;
        rs1_out <= rs1_in;
        rs2_out <= rs2_in;
        rd_out <= rd_in;
        pc_out <= pc_in;

        // Control signals
        alu_op_out <= alu_op_in;
        alu_src_a_out <= alu_src_a_in;
        alu_src_b_out <= alu_src_b_in;
        reg_write_out <= reg_write_in;
        mem_read_out <= mem_read_in;
        mem_write_out <= mem_write_in;
        mem_size_out <= mem_size_in;
        mem_unsigned_out <= mem_unsigned_in;
        wb_sel_out <= wb_sel_in;
        branch_out <= branch_in;
        jump_out <= jump_in;
        branch_type_out <= branch_type_in;
        uses_rs2_out <= uses_rs2_in;
        is_atomic_out <= is_atomic_in;
        amo_op_out <= amo_op_in;
    end    
end

endmodule