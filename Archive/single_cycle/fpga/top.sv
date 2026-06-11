`timescale 1ns / 1ps

module top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,
    output logic [9:0] LEDR,
    output logic [7:0] HEX0,
    output logic [7:0] HEX1,
    output logic [7:0] HEX2,
    output logic [7:0] HEX3,
    output logic [7:0] HEX4,
    output logic [7:0] HEX5
);

    // Internal signals
    logic reset;
    logic [31:0] out_pc;
    logic [31:0] out_writeback_data;
    logic        out_reg_write;
    logic [31:0] out_alu_result;

    // Reset logic: KEY[0] is active low, convert to active high for CPU
    assign reset = ~KEY[0];

    // CPU instantiation
    cpu cpu_inst (
        .clk                ( MAX10_CLK1_50      ),
        .reset              ( reset              ),
        .out_pc             ( out_pc             ),
        .out_writeback_data ( out_writeback_data ),
        .out_reg_write      ( out_reg_write      ),
        .out_alu_result     ( out_alu_result     )
    );

    // Display Program Counter on LEDs (lower 10 bits)
    assign LEDR = out_pc[9:0];

    // Seven segment decoders for ALU Result
    // We'll display 24 bits of out_alu_result across HEX0-HEX5 (6 hex digits)
    seven_seg_decoder hex0_dec (.data(out_alu_result[3:0]),   .seg(HEX0));
    seven_seg_decoder hex1_dec (.data(out_alu_result[7:4]),   .seg(HEX1));
    seven_seg_decoder hex2_dec (.data(out_alu_result[11:8]),  .seg(HEX2));
    seven_seg_decoder hex3_dec (.data(out_alu_result[15:12]), .seg(HEX3));
    seven_seg_decoder hex4_dec (.data(out_alu_result[19:16]), .seg(HEX4));
    seven_seg_decoder hex5_dec (.data(out_alu_result[23:20]), .seg(HEX5));

endmodule

// Helper module for Seven Segment Decoder
module seven_seg_decoder (
    input  logic [3:0] data,
    output logic [7:0] seg
);
    always_comb begin
        case (data)
            4'h0: seg = 8'b1100_0000;
            4'h1: seg = 8'b1111_1001;
            4'h2: seg = 8'b1010_0100;
            4'h3: seg = 8'b1011_0000;
            4'h4: seg = 8'b1001_1001;
            4'h5: seg = 8'b1001_0010;
            4'h6: seg = 8'b1000_0010;
            4'h7: seg = 8'b1111_1000;
            4'h8: seg = 8'b1000_0000;
            4'h9: seg = 8'b1001_0000;
            4'hA: seg = 8'b1000_1000;
            4'hB: seg = 8'b1000_0011;
            4'hC: seg = 8'b1100_0110;
            4'hD: seg = 8'b1010_0001;
            4'hE: seg = 8'b1000_0110;
            4'hF: seg = 8'b1000_1110;
            default: seg = 8'b1111_1111;
        endcase
    end
endmodule
