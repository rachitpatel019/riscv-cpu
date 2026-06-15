/**
 * Memory Mapped I/O (MMIO) Module
 * Handles access to FPGA peripherals: LEDs, 7-Segment displays, Switches, and Keys.
 * 
 * Address Map:
 * 0x80000000: LEDR (W) - bits [9:0]
 * 0x80000004: HEX (W)  - bits [23:0] (4 bits per digit for HEX0-HEX5)
 * 0x80000008: SW (R)   - bits [9:0]
 * 0x8000000C: KEY (R)  - bits [1:0]
 */

module mmio (
    input  logic        clk,
    input  logic        reset,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data,

    // Peripheral I/O
    input  logic [1:0]  sw_keys,
    input  logic [9:0]  sw_switches,
    output logic [9:0]  out_leds,
    output logic [23:0] out_hex
);

    // Peripheral Registers
    logic [9:0]  led_reg;
    logic [23:0] hex_reg;

    assign out_leds = led_reg;
    assign out_hex  = hex_reg;

    // Write Logic
    always_ff @(posedge clk) begin
        if (reset) begin
            led_reg <= 10'b0;
            hex_reg <= 24'b0;
        end else if (mem_write) begin
            case (address)
                32'h80000000: led_reg <= write_data[9:0];
                32'h80000004: hex_reg <= write_data[23:0];
                default: ; // Ignore other addresses
            endcase
        end
    end

    // Read Logic (Synchronous to match BRAM latency)
    always_ff @(posedge clk) begin
        if (mem_read) begin
            case (address)
                32'h80000008: read_data <= {22'b0, sw_switches};
                32'h8000000C: read_data <= {30'b0, sw_keys};
                default:      read_data <= 32'b0;
            endcase
        end else begin
            read_data <= 32'b0;
        end
    end

endmodule
