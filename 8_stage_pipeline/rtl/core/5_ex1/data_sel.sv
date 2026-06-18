module data_sel (
    input logic [31:0] pc,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] imm,
    input logic        alu_src_a,
    input logic        alu_src_b,
    
    // Forwarding controls
    input logic [1:0]  forward_a_sel,
    input logic [1:0]  forward_b_sel,
    
    // Forwarding data sources
    input logic [31:0] fwd_ex2_data,
    input logic [31:0] fwd_ex3_data,
    input logic [31:0] fwd_wb_data,

    output logic [31:0] operand_a,
    output logic [31:0] operand_b,
    output logic [31:0] rs2_data_out
);

    // Operand A Selection
    logic [31:0] rs1_final;
    always_comb begin
        case (forward_a_sel)
            2'b01:   rs1_final = fwd_ex2_data; // From S7 (Registered ALU)
            2'b10:   rs1_final = fwd_ex3_data; // From S8 (Registered Writeback)
            default: rs1_final = rs1_data;
        endcase
    end
    assign operand_a = alu_src_a ? pc : rs1_final;

    // Operand B Selection
    logic [31:0] rs2_final;
    always_comb begin
        case (forward_b_sel)
            2'b01:   rs2_final = fwd_ex2_data;
            2'b10:   rs2_final = fwd_ex3_data;
            default: rs2_final = rs2_data;
        endcase
    end
    assign operand_b = alu_src_b ? imm : rs2_final;
    
    assign rs2_data_out = rs2_final;

endmodule