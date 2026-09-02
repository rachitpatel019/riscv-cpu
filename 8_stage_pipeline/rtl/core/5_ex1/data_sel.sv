/*
Operand data selection and forwarding unit for the EX1 execution stage.
Resolves RAW data hazards by multiplexing register data with forwarded values from EX1, EX2, and EX3 stages.
Selects final ALU input operands by picking PC or RS1 for operand A, and immediate or RS2 for operand B.
*/

module data_sel (
    input logic [31:0] pc,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic alu_src_a,
    input logic alu_src_b,

    input logic [1:0] forward_a_sel,
    input logic [1:0] forward_b_sel,

    input logic [31:0] fwd_ex1_data,
    input logic [31:0] fwd_ex2_data,
    input logic [31:0] fwd_ex3_data,

    output logic [31:0] operand_a,
    output logic [31:0] operand_b,
    output logic [31:0] rs2_data_out
);

logic [31:0] rs1_final;
logic [31:0] rs2_final;

// Selects RS1 data by multiplexing register file output with forwarded data from downstream stages to resolve data hazards.
always_comb begin
    case (forward_a_sel)
        2'b11: rs1_final = fwd_ex1_data;
        2'b01: rs1_final = fwd_ex2_data;
        2'b10: rs1_final = fwd_ex3_data;
        default: rs1_final = rs1_data;
    endcase
end

// Muxes between Program Counter (for branch/jump targets and AUIPC) and the resolved RS1 data to form ALU operand A.
assign operand_a = alu_src_a ? pc : rs1_final;

// Selects RS2 data by multiplexing register file output with forwarded data from downstream stages to resolve data hazards.
always_comb begin
    case (forward_b_sel)
        2'b11: rs2_final = fwd_ex1_data;
        2'b01: rs2_final = fwd_ex2_data;
        2'b10: rs2_final = fwd_ex3_data;
        default: rs2_final = rs2_data;
    endcase
end

// Muxes between immediate value and resolved RS2 data for ALU operand B, and passes resolved RS2 data for store operations.
assign operand_b = alu_src_b ? imm : rs2_final;
assign rs2_data_out = rs2_final;

endmodule