/*
Data memory module supporting byte, halfword, and word accesses.
Provides alignment logic and infers M9K BRAM blocks as a Simple Dual-Port RAM.
*/

module data_mem (
    input logic clk,

    input logic mem_read,
    input logic [31:0] read_address,
    input logic [1:0] read_mem_size,

    input logic mem_write,
    input logic [31:0] write_address,
    input logic [31:0] write_data,
    input logic [1:0] write_mem_size,

    input logic mem_unsigned,

    output logic [31:0] read_data
);

parameter MEM_DEPTH = 32768;

(* ramstyle = "M9K" *) logic [31:0] memory [0:MEM_DEPTH-1];

initial begin
    $readmemh("data.hex", memory);
end

logic [31:0] current_word;
logic [31:0] shifted_word;
logic [1:0] addr_low;

logic read_active;
logic [1:0] size_reg;
logic unsigned_reg;

// Emulates physical BRAM address line wrap-around to prevent out-of-bounds simulation crashes
// when executing compliance tests with high address offsets (e.g. 0x80000000).
// Subtracts the RAM base offset (0x80020000) to align with zero-indexed data.hex.
logic [$clog2(MEM_DEPTH)-1:0] masked_read_addr;
logic [$clog2(MEM_DEPTH)-1:0] masked_write_addr;

assign masked_read_addr  = ((read_address  - 32'h80020000) >> 2) & (MEM_DEPTH-1);
assign masked_write_addr = ((write_address - 32'h80020000) >> 2) & (MEM_DEPTH-1);

// Synchronous write port logic handling byte, halfword, and word masking.
always_ff @(posedge clk) begin
    if (mem_write) begin
        case (write_mem_size)
            2'b10: memory[masked_write_addr] <= write_data;
            2'b01:
                case (write_address[1])
                    1'b1: memory[masked_write_addr][31:16] <= write_data[15:0];
                    1'b0: memory[masked_write_addr][15:0] <= write_data[15:0];
                endcase
            2'b00:
                case (write_address[1:0])
                    2'b11: memory[masked_write_addr][31:24] <= write_data[7:0];
                    2'b10: memory[masked_write_addr][23:16] <= write_data[7:0];
                    2'b01: memory[masked_write_addr][15:8] <= write_data[7:0];
                    2'b00: memory[masked_write_addr][7:0] <= write_data[7:0];
                endcase
            default: memory[masked_write_addr] <= write_data;
        endcase
    end
end

// Synchronous read registers storing read address offsets and memory control states.
always_ff @(posedge clk) begin
    current_word <= memory[masked_read_addr];
    addr_low <= read_address[1:0];
    read_active <= mem_read;
    size_reg <= read_mem_size;
    unsigned_reg <= mem_unsigned;
end

// Write-during-read bypass/forwarding logic to handle RDW collisions on same clock edge.
logic [$clog2(MEM_DEPTH)-1:0] write_addr_reg;
logic [31:0] write_data_reg;
logic [1:0] write_size_reg;
logic [1:0] write_addr_low_reg;
logic write_en_reg;
logic [$clog2(MEM_DEPTH)-1:0] read_addr_reg;

always_ff @(posedge clk) begin
    write_addr_reg     <= masked_write_addr;
    write_data_reg     <= write_data;
    write_size_reg     <= write_mem_size;
    write_addr_low_reg <= write_address[1:0];
    write_en_reg       <= mem_write;
    read_addr_reg      <= masked_read_addr;
end

logic [31:0] forwarded_word;
always_comb begin
    forwarded_word = current_word;
    if (write_en_reg && (write_addr_reg == read_addr_reg)) begin
        case (write_size_reg)
            2'b10: forwarded_word = write_data_reg;
            2'b01:
                case (write_addr_low_reg[1])
                    1'b1: forwarded_word = {write_data_reg[15:0], current_word[15:0]};
                    1'b0: forwarded_word = {current_word[31:16], write_data_reg[15:0]};
                endcase
            2'b00:
                case (write_addr_low_reg[1:0])
                    2'b11: forwarded_word = {write_data_reg[7:0], current_word[23:0]};
                    2'b10: forwarded_word = {current_word[31:24], write_data_reg[7:0], current_word[15:0]};
                    2'b01: forwarded_word = {current_word[31:16], write_data_reg[7:0], current_word[7:0]};
                    2'b00: forwarded_word = {current_word[31:8], write_data_reg[7:0]};
                endcase
            default: forwarded_word = write_data_reg;
        endcase
    end
end

// Asynchronously aligns the read word based on address offset using the forwarded word.
assign shifted_word = forwarded_word >> {addr_low, 3'b000};

// Decides size and sign extension of the read word based on control registers.
always_comb begin
    if (read_active) begin
        case (size_reg)
            2'b10: read_data = forwarded_word;
            2'b01:
                if (unsigned_reg)
                    read_data = {16'b0, shifted_word[15:0]};
                else
                    read_data = {{16{shifted_word[15]}}, shifted_word[15:0]}; 
            2'b00:
                if (unsigned_reg)
                    read_data = {24'b0, shifted_word[7:0]};
                else
                    read_data = {{24{shifted_word[7]}}, shifted_word[7:0]}; 
            default: read_data = forwarded_word;
        endcase
    end
    else begin
        read_data = 32'b0;
    end
end

endmodule
