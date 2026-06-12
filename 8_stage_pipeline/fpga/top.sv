module top (
    input  logic        MAX10_CLK1_50,
    input  logic [1:0]  KEY,
    input  logic [9:0]  SW,
    output logic [9:0]  LEDR,
    output logic [6:0]  HEX0,
    output logic [6:0]  HEX1,
    output logic [6:0]  HEX2,
    output logic [6:0]  HEX3,
    output logic [6:0]  HEX4,
    output logic [6:0]  HEX5
);

    logic clk_osc;
    logic clk_manual;
    logic clk;
    logic reset;

    assign clk_osc = MAX10_CLK1_50;
    assign clk_manual = !KEY[1];

    // SW[9] selects between 50MHz oscillator (1) and manual clock (0)
    assign clk = SW[9] ? clk_osc : clk_manual;
    assign reset = !KEY[0]; // KEY[0] is active low, core reset is active high

    logic [31:0] out_pc;
    logic [31:0] out_writeback_data;
    logic        out_reg_write;
    logic [31:0] out_alu_result;

    // Core instantiation
    core cpu_core (
        .clk(clk),
        .reset(reset),
        .out_pc(out_pc),
        .out_writeback_data(out_writeback_data),
        .out_reg_write(out_reg_write),
        .out_alu_result(out_alu_result)
    );

    // Map PC to LEDs
    assign LEDR = out_pc[9:0];
    // Seven segment decoders for Writeback data
    // Showing lower 24 bits of out_writeback_data (6 hex digits)
    seven_seg_decoder h0 (.bin(out_writeback_data[3:0]),   .seg(HEX0));
    seven_seg_decoder h1 (.bin(out_writeback_data[7:4]),   .seg(HEX1));
    seven_seg_decoder h2 (.bin(out_writeback_data[11:8]),  .seg(HEX2));
    seven_seg_decoder h3 (.bin(out_writeback_data[15:12]), .seg(HEX3));
    seven_seg_decoder h4 (.bin(out_writeback_data[19:16]), .seg(HEX4));
    seven_seg_decoder h5 (.bin(out_writeback_data[23:20]), .seg(HEX5));

endmodule

module seven_seg_decoder (
    input  logic [3:0] bin,
    output logic [6:0] seg
);
    always_comb begin
        case (bin)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
