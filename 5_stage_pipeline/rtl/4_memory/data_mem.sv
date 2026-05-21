/* Synchronous data memory for FPGA BRAM inference.
   Read data is available one cycle after the address is provided. */

module data_mem (
    input  logic clk,
    input  logic stall, // Pipeline stall signal
    input  logic mem_read,
    input  logic mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  logic [1:0]  mem_size,
    input  logic        mem_unsigned,
    output logic [31:0] read_data
);

logic [31:0] memory [0:511]; // 512 words = 2KB

// Internal registers to support synchronous read behavior
logic [1:0]  addr_low_reg;
logic [1:0]  mem_size_reg;
logic        mem_unsigned_reg;
logic [31:0] raw_read_data;

// Synchronous Write and Address/Control Sampling
always_ff @(posedge clk) begin
    if (!stall) begin
        if (mem_write) begin
            case (mem_size)
                2'b10: memory[address[10:2]] <= write_data; // Word
                2'b01: // Halfword
                    case (address[1])
                        1'b1: memory[address[10:2]][31:16] <= write_data[15:0];
                        1'b0: memory[address[10:2]][15:0]  <= write_data[15:0];
                    endcase
                2'b00: // Byte
                    case (address[1:0])
                        2'b11: memory[address[10:2]][31:24] <= write_data[7:0];
                        2'b10: memory[address[10:2]][23:16] <= write_data[7:0];
                        2'b01: memory[address[10:2]][15:8]  <= write_data[7:0];
                        2'b00: memory[address[10:2]][7:0]   <= write_data[7:0];
                    endcase
                default: memory[address[10:2]] <= write_data;
            endcase
        end
        
        // Capture address and control for the read cycle
        raw_read_data    <= memory[address[10:2]];
        addr_low_reg     <= address[1:0];
        mem_size_reg     <= mem_size;
        mem_unsigned_reg <= mem_unsigned;
    end
end

// Post-read alignment logic (Combinational, based on registered address/size)
logic [15:0] extracted_halfword;
logic [7:0]  extracted_byte;

always_comb begin
    extracted_halfword = addr_low_reg[1] ? raw_read_data[31:16] : raw_read_data[15:0];
    
    case (addr_low_reg)
        2'b11: extracted_byte = raw_read_data[31:24];
        2'b10: extracted_byte = raw_read_data[23:16];
        2'b01: extracted_byte = raw_read_data[15:8];
        2'b00: extracted_byte = raw_read_data[7:0];
    endcase

    case (mem_size_reg)
        2'b10: read_data = raw_read_data;
        2'b01: // Halfword
            if (mem_unsigned_reg)
                read_data = {16'b0, extracted_halfword};
            else
                read_data = {{16{extracted_halfword[15]}}, extracted_halfword}; 
        2'b00: // Byte
            if (mem_unsigned_reg)
                read_data = {24'b0, extracted_byte};
            else
                read_data = {{24{extracted_byte[7]}}, extracted_byte}; 
        default: read_data = raw_read_data;
    endcase
end

endmodule
