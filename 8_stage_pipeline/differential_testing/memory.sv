/*
System memory interconnect and memory controller.
Decodes addresses to route requests to data memory or MMIO.
*/

module memory (
    input logic clk,
    input logic reset,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] address,
    input logic [31:0] write_data,
    input logic [1:0] mem_size,
    input logic mem_unsigned,

    output logic [31:0] read_data,

    input logic [1:0] mmio_keys,
    input logic [9:0] mmio_switches,

    output logic [9:0] mmio_leds,
    output logic [23:0] mmio_hex
);

logic is_mmio;

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
assign is_mmio = (address >= 32'h80000000 && address <= 32'h8000000f);

assign dmem_read = mem_read & !is_mmio;
assign dmem_write = mem_write & !is_mmio;
assign mmio_read = mem_read & is_mmio;
assign mmio_write = mem_write & is_mmio;

// Instantiates the core data memory (BRAM).
data_mem dmem (
    .clk(clk),
    .mem_read(dmem_read),
    .mem_write(dmem_write),
    .address(address),
    .write_data(write_data),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(dmem_read_data)
);

// Instantiates the Memory Mapped I/O controller.
mmio mmio_inst (
    .clk(clk),
    .reset(reset),
    .mem_read(mmio_read),
    .mem_write(mmio_write),
    .address(address),
    .write_data(write_data),
    .read_data(mmio_read_data),
    .sw_keys(mmio_keys),
    .sw_switches(mmio_switches),
    .out_leds(mmio_leds),
    .out_hex(mmio_hex)
);

// Synchronous register stage to track whether the active access was MMIO.
always_ff @(posedge clk) begin
    is_mmio_reg <= is_mmio;
end

// Selects final read data from MMIO or data memory based on registers.
assign read_data = is_mmio_reg ? mmio_read_data : dmem_read_data;

endmodule
