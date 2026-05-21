`timescale 1ns / 1ps

module mmio_controller (
    input  logic clk,
    input  logic reset,
    
    // CPU Interface
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [1:0]  mem_size,
    input  logic        mem_unsigned,
    output logic [31:0] read_data,

    // Physical FPGA I/O
    input  logic [9:0]  fpga_sw,
    input  logic [1:0]  fpga_key,
    output logic [9:0]  fpga_ledr,
    output logic [7:0]  fpga_hex0,
    output logic [7:0]  fpga_hex1,
    output logic [7:0]  fpga_hex2,
    output logic [7:0]  fpga_hex3,
    output logic [7:0]  fpga_hex4,
    output logic [7:0]  fpga_hex5
);

    // Internal Registers for Outputs
    logic [9:0]  reg_ledr;
    logic [7:0]  reg_hex0, reg_hex1, reg_hex2, reg_hex3, reg_hex4, reg_hex5;
    logic [63:0] cycle_counter;

    // Drive physical outputs
    assign fpga_ledr = reg_ledr;
    assign fpga_hex0 = reg_hex0;
    assign fpga_hex1 = reg_hex1;
    assign fpga_hex2 = reg_hex2;
    assign fpga_hex3 = reg_hex3;
    assign fpga_hex4 = reg_hex4;
    assign fpga_hex5 = reg_hex5;

    // Cycle Counter
    always_ff @(posedge clk) begin
        if (reset) cycle_counter <= 64'b0;
        else       cycle_counter <= cycle_counter + 1;
    end

    // Write Logic
    always_ff @(posedge clk) begin
        if (reset) begin
            reg_ledr <= 10'b0;
            reg_hex0 <= 8'hFF; // All segments off (Active Low)
            reg_hex1 <= 8'hFF;
            reg_hex2 <= 8'hFF;
            reg_hex3 <= 8'hFF;
            reg_hex4 <= 8'hFF;
            reg_hex5 <= 8'hFF;
        end else if (mem_write) begin
            case (address)
                32'h80000008: reg_ledr <= write_data[9:0];
                32'h80000010: begin
                    reg_hex0 <= write_data[7:0];
                    reg_hex1 <= write_data[15:8];
                end
                32'h80000014: begin
                    reg_hex2 <= write_data[7:0];
                    reg_hex3 <= write_data[15:8];
                end
                32'h80000018: begin
                    reg_hex4 <= write_data[7:0];
                    reg_hex5 <= write_data[15:8];
                end
                default: ; // Ignore other writes
            endcase
        end
    end

    // Internal Registers for Synchronous Read
    logic [31:0] read_addr_reg;
    logic        read_en_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            read_addr_reg <= 32'b0;
            read_en_reg   <= 1'b0;
        end else begin
            read_addr_reg <= address;
            read_en_reg   <= mem_read;
        end
    end

    // Read Logic (Synchronous based on registered address)
    always_comb begin
        read_data = 32'b0;
        if (read_en_reg) begin
            case (read_addr_reg)
                32'h80000000: read_data = {22'b0, fpga_sw};
                32'h80000004: read_data = {30'b0, fpga_key};
                32'h80000008: read_data = {22'b0, reg_ledr};
                32'h80000010: read_data = {16'b0, reg_hex1, reg_hex0};
                32'h80000014: read_data = {16'b0, reg_hex3, reg_hex2};
                32'h80000018: read_data = {16'b0, reg_hex5, reg_hex4};
                32'h80000020: read_data = cycle_counter[31:0];
                32'h80000024: read_data = cycle_counter[63:32];
                default:      read_data = 32'hDEADBEEF; // Error indicator
            endcase
        end
    end

endmodule
