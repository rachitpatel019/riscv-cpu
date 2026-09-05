/*
Calculates and outputs the next program counter (PC) value.
*/

module pc_update (
    input logic clk,
    input logic reset,

    input logic stall,

    input logic pc_sel,
    input logic [31:0] pc_target,
    input logic stage4_pc_sel,
    input logic [31:0] stage4_pc_target,

    output logic [31:0] pc
);

/*
Updates the program counter register on each clock cycle based on stall, jump, and reset signals.
0 on reset
PC+4 on sequential instruction fetching.
jump/branch targets from the pc-target_calc module (stage 7) are given higher priority than
targets from bht (stage 4) as they originate from older instructions.
*/
always_ff @(posedge clk) begin
    if (reset) begin
        pc <= 32'b0;
    end
    else if (pc_sel) begin
        pc <= pc_target;
    end
    else if (stage4_pc_sel) begin
        pc <= stage4_pc_target;
    end
    else if (stall) begin
        pc <= pc;
    end
    else begin
        pc <= pc + 32'd4;
    end
end

endmodule