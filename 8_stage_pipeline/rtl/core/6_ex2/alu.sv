// Arithmetic Logic Unit (Flattened for Timing Optimization)

module alu(
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [3:0] control,

    output logic [31:0] result
);

import alu_package::*;

// Parallel evaluation of all operations
logic [31:0] add_res, sub_res, and_res, or_res, xor_res;
logic [31:0] sll_res, srl_res, sra_res;
logic        slt_res, sltu_res;

assign add_res = A + B;
assign sub_res = A - B;
assign and_res = A & B;
assign or_res  = A | B;
assign xor_res = A ^ B;

// Shifters
assign sll_res = A << B[4:0];
assign srl_res = A >> B[4:0];
assign sra_res = $signed(A) >>> B[4:0];

// Comparators
assign slt_res  = ($signed(A) < $signed(B));
assign sltu_res = (A < B);

always_comb begin
    case (control)
        ALU_ADD : result = add_res;
        ALU_SUB : result = sub_res;
        ALU_AND : result = and_res;
        ALU_OR  : result = or_res;
        ALU_XOR : result = xor_res;
        ALU_SLTU: result = {31'b0, sltu_res};
        ALU_SLT : result = {31'b0, slt_res};
        ALU_SLL : result = sll_res;
        ALU_SRL : result = srl_res;
        ALU_SRA : result = sra_res;
        ALU_PASS: result = B;
        default : result = 32'b0;
    endcase
end

endmodule