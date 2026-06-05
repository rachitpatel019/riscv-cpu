module pc_target_calc(
    input logic [31:0] pc,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,

    input logic branch,
    input logic jump,
    input logic [2:0] branch_type,

    input logic [31:0] imm,
    input logic [31:0] alu_result,
    
    // Optimized timing inputs (from EX2_EX3 register)
    input logic        condition_met_in,
    input logic [31:0] branch_target_in,

    output logic pc_sel,
    output logic [31:0] pc_target
);

always_comb begin
    // Decision is now driven by registered condition_met
    pc_sel = jump || (branch && condition_met_in);

    if (jump)
        pc_target = {alu_result[31:1], 1'b0};
    else if (branch && condition_met_in)
        pc_target = branch_target_in;
	else
        pc_target = 32'b0;
end

endmodule