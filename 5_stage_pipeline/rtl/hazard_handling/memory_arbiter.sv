`timescale 1ns / 1ps

module memory_arbiter (
    input logic clk,
    input logic reset,

    // Core 0 Interface
    input  logic [31:0] c0_imem_addr,
    output logic [31:0] c0_imem_data,
    input  logic [31:0] c0_dmem_addr,
    input  logic [31:0] c0_dmem_wdata,
    input  logic        c0_dmem_read,
    input  logic        c0_dmem_write,
    input  logic [1:0]  c0_dmem_size,
    input  logic        c0_dmem_unsigned,
    output logic [31:0] c0_dmem_rdata,
    input  logic        c0_dmem_is_lr,
    input  logic        c0_dmem_is_sc,
    output logic        c0_dmem_sc_success,
    output logic        c0_stall,

    // Core 1 Interface
    input  logic [31:0] c1_imem_addr,
    output logic [31:0] c1_imem_data,
    input  logic [31:0] c1_dmem_addr,
    input  logic [31:0] c1_dmem_wdata,
    input  logic        c1_dmem_read,
    input  logic        c1_dmem_write,
    input  logic [1:0]  c1_dmem_size,
    input  logic        c1_dmem_unsigned,
    output logic [31:0] c1_dmem_rdata,
    input  logic        c1_dmem_is_lr,
    input  logic        c1_dmem_is_sc,
    output logic        c1_dmem_sc_success,
    output logic        c1_stall,

    // Shared Instruction Memory
    output logic [31:0] shared_imem_addr_a,
    input  logic [31:0] shared_imem_data_a,
    output logic [31:0] shared_imem_addr_b,
    input  logic [31:0] shared_imem_data_b,

    // Shared Data Memory
    output logic [31:0] shared_dmem_addr,
    output logic [31:0] shared_dmem_wdata,
    output logic        shared_dmem_read,
    output logic        shared_dmem_write,
    output logic [1:0]  shared_dmem_size,
    output logic        shared_dmem_unsigned,
    input  logic [31:0] shared_dmem_rdata
);

    // -------------------------------------------------------------------------
    // Instruction Memory Interface (Dual-Ported Pass-through)
    // -------------------------------------------------------------------------
    // Both cores can fetch instructions independently from the dual-ported IMEM.
    
    assign shared_imem_addr_a = c0_imem_addr;
    assign c0_imem_data       = shared_imem_data_a;

    assign shared_imem_addr_b = c1_imem_addr;
    assign c1_imem_data       = shared_imem_data_b;

    // -------------------------------------------------------------------------
    // Data Memory Arbitration (Fixed Priority: Core 0 > Core 1)
    // -------------------------------------------------------------------------
    logic c0_dmem_req, c1_dmem_req;
    assign c0_dmem_req = c0_dmem_read | c0_dmem_write;
    assign c1_dmem_req = c1_dmem_read | c1_dmem_write;

    logic c0_wins_dmem;
    assign c0_wins_dmem = c0_dmem_req; // Core 0 always wins if it requests
    assign c1_stall = c1_dmem_req && c0_dmem_req; // Core 1 stalls if Core 0 is using dmem
    assign c0_stall = 1'b0; // Core 0 never stalls for Core 1 in fixed priority

    assign shared_dmem_addr     = c0_wins_dmem ? c0_dmem_addr     : c1_dmem_addr;
    assign shared_dmem_wdata    = c0_wins_dmem ? c0_dmem_wdata    : c1_dmem_wdata;
    assign shared_dmem_read     = c0_wins_dmem ? c0_dmem_read     : c1_dmem_read;
    assign shared_dmem_write    = c0_wins_dmem ? (c0_dmem_write & (!c0_dmem_is_sc | c0_dmem_sc_success)) : 
                                                 (c1_dmem_write & (!c1_dmem_is_sc | c1_dmem_sc_success));
    assign shared_dmem_size      = c0_wins_dmem ? c0_dmem_size      : c1_dmem_size;
    assign shared_dmem_unsigned  = c0_wins_dmem ? c0_dmem_unsigned  : c1_dmem_unsigned;

    assign c0_dmem_rdata = shared_dmem_rdata;
    assign c1_dmem_rdata = shared_dmem_rdata;

    // -------------------------------------------------------------------------
    // Global Reservation Stations (LR/SC Logic)
    // -------------------------------------------------------------------------
    logic c0_res_valid, c1_res_valid;
    logic [31:0] c0_res_addr, c1_res_addr;

    always_ff @(posedge clk) begin
        if (reset) begin
            c0_res_valid <= 1'b0;
            c1_res_valid <= 1'b0;
        end else begin
            // Core 0 LR
            if (c0_dmem_is_lr && !c0_stall) begin
                c0_res_valid <= 1'b1;
                c0_res_addr  <= c0_dmem_addr;
            end
            // Core 1 LR
            if (c1_dmem_is_lr && !c1_stall) begin
                c1_res_valid <= 1'b1;
                c1_res_addr  <= c1_dmem_addr;
            end

            // Invalidation logic: If Core X writes to address A, Core Y's reservation on A is cleared.
            if (shared_dmem_write) begin
                if (c0_res_valid && (c0_res_addr == shared_dmem_addr)) c0_res_valid <= 1'b0;
                if (c1_res_valid && (c1_res_addr == shared_dmem_addr)) c1_res_valid <= 1'b0;
            end
            
            // Clear on SC (attempting or succeeding usually clears)
            if (c0_dmem_is_sc && !c0_stall) c0_res_valid <= 1'b0;
            if (c1_dmem_is_sc && !c1_stall) c1_res_valid <= 1'b0;
        end
    end

    assign c0_dmem_sc_success = c0_dmem_is_sc && c0_res_valid && (c0_res_addr == c0_dmem_addr);
    assign c1_dmem_sc_success = c1_dmem_is_sc && c1_res_valid && (c1_res_addr == c1_dmem_addr);

endmodule