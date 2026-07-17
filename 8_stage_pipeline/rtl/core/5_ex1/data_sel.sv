/*
Operand selection unit for EX1 stage.
Multiplexes register data, immediates, and forwarded results.
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

// Forwarding multiplexer for register operand A (rs1).
always_comb begin
    case (forward_a_sel)
        2'b11: rs1_final = fwd_ex1_data;
        2'b01: rs1_final = fwd_ex2_data;
        2'b10: rs1_final = fwd_ex3_data;
        default: rs1_final = rs1_data;
    endcase
end

// Operand A selection between PC (for jumps/AUIPC) and register data rs1.
assign operand_a = alu_src_a ? pc : rs1_final;

// Forwarding multiplexer for register operand B (rs2).
always_comb begin
    case (forward_b_sel)
        2'b11: rs2_final = fwd_ex1_data;
        2'b01: rs2_final = fwd_ex2_data;
        2'b10: rs2_final = fwd_ex3_data;
        default: rs2_final = rs2_data;
    endcase
end

// Operand B selection between immediate and register data rs2, and outputs forwarded rs2 data.
assign operand_b = alu_src_b ? imm : rs2_final;
assign rs2_data_out = rs2_final;

endmodule