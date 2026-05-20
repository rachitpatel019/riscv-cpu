`timescale 1ns / 1ps

module system_interconnect (
    // Arbiter Interface (Master)
    input  logic [31:0] master_addr,
    input  logic [31:0] master_wdata,
    input  logic        master_read,
    input  logic        master_write,
    input  logic [1:0]  master_size,
    input  logic        master_unsigned,
    output logic [31:0] master_rdata,

    // Data RAM Interface (Slave 0)
    output logic [31:0] ram_addr,
    output logic [31:0] ram_wdata,
    output logic        ram_read,
    output logic        ram_write,
    output logic [1:0]  ram_size,
    output logic        ram_unsigned,
    input  logic [31:0] ram_rdata,

    // MMIO Interface (Slave 1)
    output logic [31:0] mmio_addr,
    output logic [31:0] mmio_wdata,
    output logic        mmio_read,
    output logic        mmio_write,
    output logic [1:0]  mmio_size,
    output logic        mmio_unsigned,
    input  logic [31:0] mmio_rdata
);

    // Simple address decoding
    // RAM: 0x00000000 - 0x00003FFF (bit 31 is 0)
    // MMIO: 0x80000000 - 0x800001FF (bit 31 is 1)
    
    logic is_mmio;
    assign is_mmio = master_addr[31];

    // Steer signals to RAM
    assign ram_addr     = master_addr;
    assign ram_wdata    = master_wdata;
    assign ram_read     = master_read  & !is_mmio;
    assign ram_write    = master_write & !is_mmio;
    assign ram_size     = master_size;
    assign ram_unsigned = master_unsigned;

    // Steer signals to MMIO
    assign mmio_addr     = master_addr;
    assign mmio_wdata    = master_wdata;
    assign mmio_read     = master_read  & is_mmio;
    assign mmio_write    = master_write & is_mmio;
    assign mmio_size     = master_size;
    assign mmio_unsigned = master_unsigned;

    // Multiplex read data back to master
    assign master_rdata = is_mmio ? mmio_rdata : ram_rdata;

endmodule
