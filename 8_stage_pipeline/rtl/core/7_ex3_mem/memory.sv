/**
 * System Interconnect / Memory Controller
 * Decodes addresses to route requests to Data Memory (BRAM) or MMIO.
 * 
 * Address Decoding:
 * - 0x0000_0000 to 0x7FFF_FFFF: Data Memory (BRAM)
 * - 0x8000_0000 to 0x8000_0FFF: MMIO Peripherals
 */

module memory (
    input  logic        clk,
    input  logic        reset,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  logic [1:0]  mem_size,
    input  logic        mem_unsigned,
    output logic [31:0] read_data,

    // MMIO External Ports
    input  logic [1:0]  mmio_keys,
    input  logic [9:0]  mmio_switches,
    output logic [9:0]  mmio_leds,
    output logic [23:0] mmio_hex
);

    // Address Decoding
    logic is_mmio;
    assign is_mmio = (address[31] == 1'b1); // 0x8000_0000 and above

    // Gated Control Signals
    logic dmem_read, dmem_write;
    logic mmio_read, mmio_write;

    assign dmem_read  = mem_read  & !is_mmio;
    assign dmem_write = mem_write & !is_mmio;
    assign mmio_read  = mem_read  &  is_mmio;
    assign mmio_write = mem_write &  is_mmio;

    // Sub-module Read Data
    logic [31:0] dmem_read_data;
    logic [31:0] mmio_read_data;

    // Instantiate Data Memory
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

    // Instantiate MMIO
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

    // Read Data Multiplexing (Registered to match BRAM timing)
    logic is_mmio_reg;
    always_ff @(posedge clk) begin
        is_mmio_reg <= is_mmio;
    end

    assign read_data = is_mmio_reg ? mmio_read_data : dmem_read_data;

endmodule
