`timescale 1ns / 1ps

module dual_core_top (
    input logic clk,
    input logic reset
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
    logic [31:0] shared_imem_addr;
    logic [31:0] shared_imem_data;
    logic [31:0] shared_dmem_addr;
    logic [31:0] shared_dmem_wdata;
    logic        shared_dmem_read;
    logic        shared_dmem_write;
    logic [1:0]  shared_dmem_size;
    logic        shared_dmem_unsigned;
    logic [31:0] shared_dmem_rdata;

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
        .dmem_sc_success(c0_dmem_sc_success)
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
        .dmem_sc_success(c1_dmem_sc_success)
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
        .shared_imem_addr(shared_imem_addr),
        .shared_imem_data(shared_imem_data),
        .shared_dmem_addr(shared_dmem_addr),
        .shared_dmem_wdata(shared_dmem_wdata),
        .shared_dmem_read(shared_dmem_read),
        .shared_dmem_write(shared_dmem_write),
        .shared_dmem_size(shared_dmem_size),
        .shared_dmem_unsigned(shared_dmem_unsigned),
        .shared_dmem_rdata(shared_dmem_rdata)
    );

    // 4. Shared Instruction Memory
    instr_mem imem (
        .pc(shared_imem_addr),
        .instruction(shared_imem_data)
    );

    // 5. Shared Data Memory
    data_mem dmem (
        .clk(clk),
        .mem_read(shared_dmem_read),
        .mem_write(shared_dmem_write),
        .address(shared_dmem_addr),
        .write_data(shared_dmem_wdata),
        .mem_size(shared_dmem_size),
        .mem_unsigned(shared_dmem_unsigned),
        .read_data(shared_dmem_rdata)
    );

endmodule