`timescale 1ns / 1ps

module dual_core_top (
    input  logic clk,
    input  logic reset,

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

    // --- Core 0 Memory Interface Wires ---
    logic [31:0] c0_imem_addr;
    logic [31:0] c0_imem_data;
    logic [31:0] c0_dmem_addr;
    logic [31:0] c0_dmem_wdata;
    logic        c0_dmem_read;
    logic        c0_dmem_write;
    logic [1:0]  c0_dmem_size;
    logic        c0_dmem_unsigned;
    logic [31:0] c0_dmem_rdata;
    logic        c0_dmem_is_lr;
    logic        c0_dmem_is_sc;
    logic        c0_dmem_sc_success;
    logic        c0_stall;

    // --- Core 1 Memory Interface Wires ---
    logic [31:0] c1_imem_addr;
    logic [31:0] c1_imem_data;
    logic [31:0] c1_dmem_addr;
    logic [31:0] c1_dmem_wdata;
    logic        c1_dmem_read;
    logic        c1_dmem_write;
    logic [1:0]  c1_dmem_size;
    logic        c1_dmem_unsigned;
    logic [31:0] c1_dmem_rdata;
    logic        c1_dmem_is_lr;
    logic        c1_dmem_is_sc;
    logic        c1_dmem_sc_success;
    logic        c1_stall;

    // --- Shared Memory Interface Wires ---
    logic [31:0] shared_imem_addr_a;
    logic [31:0] shared_imem_data_a;
    logic [31:0] shared_imem_addr_b;
    logic [31:0] shared_imem_data_b;
    logic [31:0] shared_dmem_addr;
    logic [31:0] shared_dmem_wdata;
    logic        shared_dmem_read;
    logic        shared_dmem_write;
    logic [1:0]  shared_dmem_size;
    logic        shared_dmem_unsigned;
    logic [31:0] shared_dmem_rdata;

    // --- Interconnect Wires ---
    logic [31:0] ram_addr, ram_wdata, ram_rdata;
    logic        ram_read, ram_write;
    logic [1:0]  ram_size;
    logic        ram_unsigned;
    logic        ram_stall;

    logic [31:0] mmio_addr, mmio_wdata, mmio_rdata;
    logic        mmio_read, mmio_write;
    logic [1:0]  mmio_size;
    logic        mmio_unsigned;

    logic c0_imem_stall, c0_dmem_stall;
    logic c1_imem_stall, c1_dmem_stall;
    logic shared_imem_stall_a, shared_imem_stall_b;

    // 1. Core 0 Instance
    core core0 (
        .clk(clk),
        .reset(reset),
        .hart_id(32'd0),
        .core_stall(c0_stall),
        .imem_addr(c0_imem_addr),
        .imem_instruction(c0_imem_data),
        .dmem_addr(c0_dmem_addr),
        .dmem_write_data(c0_dmem_wdata),
        .dmem_mem_read(c0_dmem_read),
        .dmem_mem_write(c0_dmem_write),
        .dmem_size(c0_dmem_size),
        .dmem_unsigned(c0_dmem_unsigned),
        .dmem_read_data(c0_dmem_rdata),
        .dmem_is_lr(c0_dmem_is_lr),
        .dmem_is_sc(c0_dmem_is_sc),
        .dmem_sc_success(c0_dmem_sc_success),
        .imem_stall(c0_imem_stall),
        .dmem_stall(c0_dmem_stall)
    );

    // 2. Core 1 Instance
    core core1 (
        .clk(clk),
        .reset(reset),
        .hart_id(32'd1),
        .core_stall(c1_stall),
        .imem_addr(c1_imem_addr),
        .imem_instruction(c1_imem_data),
        .dmem_addr(c1_dmem_addr),
        .dmem_write_data(c1_dmem_wdata),
        .dmem_mem_read(c1_dmem_read),
        .dmem_mem_write(c1_dmem_write),
        .dmem_size(c1_dmem_size),
        .dmem_unsigned(c1_dmem_unsigned),
        .dmem_read_data(c1_dmem_rdata),
        .dmem_is_lr(c1_dmem_is_lr),
        .dmem_is_sc(c1_dmem_is_sc),
        .dmem_sc_success(c1_dmem_sc_success),
        .imem_stall(c1_imem_stall),
        .dmem_stall(c1_dmem_stall)
    );

    // 3. Memory Arbiter Instance
    memory_arbiter arbiter (
        .clk(clk),
        .reset(reset),
        .c0_imem_addr(c0_imem_addr),
        .c0_imem_data(c0_imem_data),
        .c0_dmem_addr(c0_dmem_addr),
        .c0_dmem_wdata(c0_dmem_wdata),
        .c0_dmem_read(c0_dmem_read),
        .c0_dmem_write(c0_dmem_write),
        .c0_dmem_size(c0_dmem_size),
        .c0_dmem_unsigned(c0_dmem_unsigned),
        .c0_dmem_rdata(c0_dmem_rdata),
        .c0_dmem_is_lr(c0_dmem_is_lr),
        .c0_dmem_is_sc(c0_dmem_is_sc),
        .c0_dmem_sc_success(c0_dmem_sc_success),
        .c0_stall(c0_stall),
        .c0_imem_stall(c0_imem_stall),
        .c0_dmem_stall(c0_dmem_stall),
        .c1_imem_addr(c1_imem_addr),
        .c1_imem_data(c1_imem_data),
        .c1_dmem_addr(c1_dmem_addr),
        .c1_dmem_wdata(c1_dmem_wdata),
        .c1_dmem_read(c1_dmem_read),
        .c1_dmem_write(c1_dmem_write),
        .c1_dmem_size(c1_dmem_size),
        .c1_dmem_unsigned(c1_dmem_unsigned),
        .c1_dmem_rdata(c1_dmem_rdata),
        .c1_dmem_is_lr(c1_dmem_is_lr),
        .c1_dmem_is_sc(c1_dmem_is_sc),
        .c1_dmem_sc_success(c1_dmem_sc_success),
        .c1_stall(c1_stall),
        .c1_imem_stall(c1_imem_stall),
        .c1_dmem_stall(c1_dmem_stall),
        .shared_imem_addr_a(shared_imem_addr_a),
        .shared_imem_data_a(shared_imem_data_a),
        .shared_imem_addr_b(shared_imem_addr_b),
        .shared_imem_data_b(shared_imem_data_b),
        .shared_imem_stall_a(shared_imem_stall_a),
        .shared_imem_stall_b(shared_imem_stall_b),
        .shared_dmem_addr(shared_dmem_addr),
        .shared_dmem_wdata(shared_dmem_wdata),
        .shared_dmem_read(shared_dmem_read),
        .shared_dmem_write(shared_dmem_write),
        .shared_dmem_size(shared_dmem_size),
        .shared_dmem_unsigned(shared_dmem_unsigned),
        .shared_dmem_rdata(shared_dmem_rdata),
        .shared_dmem_stall(ram_stall)
    );

    // 4. System Interconnect
    system_interconnect interconnect_inst (
        .clk(clk),
        .reset(reset),
        .master_addr(shared_dmem_addr),
        .master_wdata(shared_dmem_wdata),
        .master_read(shared_dmem_read),
        .master_write(shared_dmem_write),
        .master_size(shared_dmem_size),
        .master_unsigned(shared_dmem_unsigned),
        .master_rdata(shared_dmem_rdata),

        .ram_addr(ram_addr),
        .ram_wdata(ram_wdata),
        .ram_read(ram_read),
        .ram_write(ram_write),
        .ram_size(ram_size),
        .ram_unsigned(ram_unsigned),
        .ram_rdata(ram_rdata),

        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_read(mmio_read),
        .mmio_write(mmio_write),
        .mmio_size(mmio_size),
        .mmio_unsigned(mmio_unsigned),
        .mmio_rdata(mmio_rdata)
    );

    // 5. Shared Instruction Memory
    instr_mem imem (
        .clk(clk),
        .stall_a(shared_imem_stall_a),
        .stall_b(shared_imem_stall_b),
        .pc_a(shared_imem_addr_a),
        .instruction_a(shared_imem_data_a),
        .pc_b(shared_imem_addr_b),
        .instruction_b(shared_imem_data_b)
    );

    // 6. Shared Data Memory (RAM)
    data_mem dmem (
        .clk(clk),
        .stall(ram_stall),
        .mem_read(ram_read),
        .mem_write(ram_write),
        .address(ram_addr),
        .write_data(ram_wdata),
        .mem_size(ram_size),
        .mem_unsigned(ram_unsigned),
        .read_data(ram_rdata)
    );

    // 7. MMIO Controller
    mmio_controller mmio (
        .clk(clk),
        .reset(reset),
        .address(mmio_addr),
        .write_data(mmio_wdata),
        .mem_read(mmio_read),
        .mem_write(mmio_write),
        .mem_size(mmio_size),
        .mem_unsigned(mmio_unsigned),
        .read_data(mmio_rdata),
        .fpga_sw(fpga_sw),
        .fpga_key(fpga_key),
        .fpga_ledr(fpga_ledr),
        .fpga_hex0(fpga_hex0),
        .fpga_hex1(fpga_hex1),
        .fpga_hex2(fpga_hex2),
        .fpga_hex3(fpga_hex3),
        .fpga_hex4(fpga_hex4),
        .fpga_hex5(fpga_hex5)
    );

endmodule
