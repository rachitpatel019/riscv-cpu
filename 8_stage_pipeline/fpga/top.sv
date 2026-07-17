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

    logic clk_125;
    logic pll_locked;
    logic [3:0] reset_shift = 4'b1111;

    logic [31:0] out_pc;
    logic [31:0] out_writeback_data;
    logic        out_reg_write;
    logic [31:0] out_alu_result;

    logic [9:0]  cpu_leds;
    logic [23:0] cpu_hex;

    // Instantiate PLL to generate 125 MHz clock from 50 MHz input
    /*
    PLL pll_inst (
        .inclk0(MAX10_CLK1_50),
        .c0(clk_125),
        .locked(pll_locked)
    );
    */
    assign clk_125 = MAX10_CLK1_50;
    assign pll_locked = 1'b1;

    // Power-on reset generation for the CPU
    // Reset shifts out when PLL is locked, and is held in reset when PLL is unlocked.
    always_ff @(posedge clk_125 or negedge pll_locked) begin
        if (!pll_locked) begin
            reset_shift <= 4'b1111;
        end else begin
            reset_shift <= {1'b0, reset_shift[3:1]};
        end
    end
    
    assign clk = clk_125;
    assign reset = reset_shift[0];

    // Core instantiation
    core cpu_core (
        .clk(clk),
        .reset(reset),
        .mmio_keys(KEY),
        .mmio_switches(SW),
        .mmio_leds(cpu_leds),
        .mmio_hex(cpu_hex),
        .out_pc(out_pc),
        .out_writeback_data(out_writeback_data),
        .out_reg_write(out_reg_write),
        .out_alu_result(out_alu_result)
    );

    // Map CPU LEDs to physical LEDs
    assign LEDR = cpu_leds;

    // Seven segment decoders for MMIO HEX data
    seven_seg_decoder h0 (.bin(cpu_hex[3:0]),   .seg(HEX0));
    seven_seg_decoder h1 (.bin(cpu_hex[7:4]),   .seg(HEX1));
    seven_seg_decoder h2 (.bin(cpu_hex[11:8]),  .seg(HEX2));
    seven_seg_decoder h3 (.bin(cpu_hex[15:12]), .seg(HEX3));
    seven_seg_decoder h4 (.bin(cpu_hex[19:16]), .seg(HEX4));
    seven_seg_decoder h5 (.bin(cpu_hex[23:20]), .seg(HEX5));

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
