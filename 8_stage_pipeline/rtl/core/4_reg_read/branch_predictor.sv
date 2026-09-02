/*
Branch predictor module wrapping the Branch History Table (BHT).
Computes branch target addresses, counter updates, and branch direction predictions.
*/

module branch_predictor (
    input logic clk,
    input logic reset,

    input logic [31:0] D_pc,
    input logic stall_frontend,

    input logic [31:0] IDRR_pc,
    input logic [31:0] IDRR_immediate,
    input logic IDRR_branch,

    input logic [31:0] E3_pc,
    input logic E3_branch,
    input logic [1:0] E3_counter_val,
    input logic E3_condition_met,

    output logic [31:0] IDRR_branch_target,
    output logic IDRR_predict_taken,
    output logic [1:0] IDRR_counter_val,
    output logic [1:0] E3_next_counter
);

logic [1:0] BRAM_counter_out;

// Computes branch target address for Stage 4
assign IDRR_branch_target = IDRR_pc + IDRR_immediate;

// Selects counter output from BRAM and predicts taken direction based on MSB
assign IDRR_counter_val = BRAM_counter_out;
assign IDRR_predict_taken = IDRR_branch && (IDRR_counter_val[1] == 1'b1);

// Computes updated BHT saturating counter value for Stage 7 update
always_comb begin
    if (E3_condition_met) begin
        E3_next_counter = (E3_counter_val == 2'b11) ? 2'b11 : (E3_counter_val + 2'b01);
    end else begin
        E3_next_counter = (E3_counter_val == 2'b00) ? 2'b00 : (E3_counter_val - 2'b01);
    end
end

// Synchronous Dual-Port BHT RAM instantiation
bht stage4_bht (
    .clk(clk),
    .reset(reset),
    .read_index(D_pc[11:2]),
    .read_enable(!stall_frontend),
    .read_counter_out(BRAM_counter_out),
    .write_index(E3_pc[11:2]),
    .write_enable(E3_branch),
    .write_counter_in(E3_next_counter)
);

endmodule
