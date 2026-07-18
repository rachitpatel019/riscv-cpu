/*
System memory interconnect and memory controller.
Decodes addresses to route requests to data memory or MMIO with split read/write ports.
*/

module memory (
    input logic clk,
    input logic reset,

    input logic mem_read,
    input logic [31:0] read_address,
    input logic [1:0] read_mem_size,

    input logic mem_write,
    input logic [31:0] write_address,
    input logic [31:0] write_data,
    input logic [1:0] write_mem_size,

    input logic mem_unsigned,

    output logic [31:0] read_data,

    input logic [1:0] mmio_keys,
    input logic [9:0] mmio_switches,

    output logic [9:0] mmio_leds,
    output logic [23:0] mmio_hex
);

// Backward-compatibility alias for tb_diff.sv address reference
logic [31:0] address;
assign address = write_address;

logic is_mmio_read;
logic is_mmio_write;

logic dmem_read;
logic dmem_write;

logic mmio_read;
logic mmio_write;

logic [31:0] dmem_read_data;
logic [31:0] mmio_read_data;

logic is_mmio_reg;

// Address decoders and write/read enable signal generators for memory and MMIO.
// Only addresses in the range 0x80000000 to 0x8000000F are routed to MMIO.
// All other addresses (e.g. 0x80010000+ for RAM) go to data memory.
assign is_mmio_read  = (read_address >= 32'h80000000 && read_address <= 32'h8000000f);
assign is_mmio_write = (write_address >= 32'h80000000 && write_address <= 32'h8000000f);

assign dmem_read  = mem_read & !is_mmio_read;
assign dmem_write = mem_write & !is_mmio_write;
assign mmio_read  = mem_read & is_mmio_read;
assign mmio_write = mem_write & is_mmio_write;

// Instantiates the core data memory (BRAM) as Simple Dual-Port.
data_mem dmem (
    .clk(clk),
    .mem_read(dmem_read),
    .read_address(read_address),
    .read_mem_size(read_mem_size),
    .mem_write(dmem_write),
    .write_address(write_address),
    .write_data(write_data),
    .write_mem_size(write_mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(dmem_read_data)
);

// Instantiates the Memory Mapped I/O controller with split addresses.
mmio mmio_inst (
    .clk(clk),
    .reset(reset),
    .mem_read(mmio_read),
    .read_address(read_address),
    .mem_write(mmio_write),
    .write_address(write_address),
    .write_data(write_data),
    .read_data(mmio_read_data),
    .sw_keys(mmio_keys),
    .sw_switches(mmio_switches),
    .out_leds(mmio_leds),
    .out_hex(mmio_hex)
);

// Synchronous register stage to track whether the active access was MMIO.
always_ff @(posedge clk) begin
    is_mmio_reg <= is_mmio_read;
end

// Selects final read data from MMIO or data memory based on registers.
assign read_data = is_mmio_reg ? mmio_read_data : dmem_read_data;

endmodule
