/* ID/EX pipeline register for the 5-stage RISC-V pipeline.
TODO: Add register for the next program counter value to support branch and jump instructions.
TODO: Add control signals for stalling and flushing the pipeline in case of hazards and control flow changes. */

module ID_EX (
    input logic clk,
    input logic reset,
    input logic stall,

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

    // Outputs to execute stage
    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,
    output logic [31:0] immediate_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out,
    output logic [31:0] pc_out,

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
    output logic [2:0] branch_type_out
);

// Outputs to execute stage
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] immediate;
logic [4:0]  rs1;
logic [4:0]  rs2;
logic [4:0]  rd;
logic [31:0] pc;

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

always_ff @(posedge clk) begin
    if (reset || stall) begin
        // Outputs to execute stage
        rs1_data <= 32'b0;
        rs2_data <= 32'b0;
        immediate <= 32'b0;
        rs1 <= 5'b0;
        rs2 <= 5'b0;
        rd <= 5'b0;
        pc <= 32'b0;

        // Control signals
        alu_op <= 4'b0;
        alu_src_a <= 1'b0;
        alu_src_b <= 1'b0;
        reg_write <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        mem_size <= 2'b0;
        mem_unsigned <= 1'b0;
        wb_sel <= 2'b0;
        branch <= 1'b0;
        jump <= 1'b0;
        branch_type <= 3'b0;
    end
    else begin
        // Outputs to execute stage
        rs1_data <= rs1_data_in;
        rs2_data <= rs2_data_in;
        immediate <= immediate_in;
        rs1 <= rs1_in,
        rs2 <= rs2_in;
        rd <= rd_in;
        pc <= pc_in;

        // Control signals
        alu_op <= alu_op_in;
        alu_src_a <= alu_src_a_in,
        alu_src_b <= alu_src_b_in;
        reg_write <= reg_write_in;
        mem_read <= mem_read_in;
        mem_write <= mem_write_in;
        mem_size <= mem_size_in;
        mem_unsigned <= mem_unsigned_in;
        wb_sel <= wb_sel_in;
        branch <= branch_in,
        jump <= jump_in;
        branch_type <= branch_type_in;
    end    
end

endmodule