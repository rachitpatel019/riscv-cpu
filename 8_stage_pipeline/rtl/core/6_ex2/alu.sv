/*
Arithmetic Logic Unit (ALU) for RISC-V.
Performs parallel evaluations of arithmetic, logic, shifts, and comparisons.
*/

module alu (
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [3:0] control,

    output logic [31:0] result
);

import alu_package::*;

logic [31:0] add_res;
logic [31:0] sub_res;
logic [31:0] and_res;
logic [31:0] or_res;
logic [31:0] xor_res;

logic [31:0] sll_res;
logic [31:0] srl_res;
logic [31:0] sra_res;

logic slt_res;
logic sltu_res;

// Evaluation of arithmetic and logical operations.
assign add_res = A + B;
assign sub_res = A - B;
assign and_res = A & B;
assign or_res = A | B;
assign xor_res = A ^ B;

// Evaluation of shift operations.
assign sll_res = A << B[4:0];
assign srl_res = A >> B[4:0];
assign sra_res = $signed(A) >>> B[4:0];

// Evaluation of comparison operations.
assign slt_res = ($signed(A) < $signed(B));
assign sltu_res = (A < B);

// Multiplexer selecting the final ALU result based on control signal.
always_comb begin
    case (control)
        ALU_ADD: result = add_res;
        ALU_SUB: result = sub_res;
        ALU_AND: result = and_res;
        ALU_OR: result = or_res;
        ALU_XOR: result = xor_res;
        ALU_SLTU: result = {31'b0, sltu_res};
        ALU_SLT: result = {31'b0, slt_res};
        ALU_SLL: result = sll_res;
        ALU_SRL: result = srl_res;
        ALU_SRA: result = sra_res;
        ALU_PASS: result = B;
        default: result = 32'b0;
    endcase
end

endmodule