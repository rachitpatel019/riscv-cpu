/*
Data memory module supporting byte, halfword, and word accesses.
Provides alignment logic and infers M9K BRAM blocks.
*/

module data_mem (
    input logic clk,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] address,
    input logic [31:0] write_data,
    input logic [1:0] mem_size,
    input logic mem_unsigned,

    output logic [31:0] read_data
);

localparam MEM_DEPTH = 16384;

(* ramstyle = "M9K" *) logic [31:0] memory [0:MEM_DEPTH-1];

logic [31:0] current_word;
logic [31:0] shifted_word;
logic [1:0] addr_low;

logic read_active;
logic [1:0] size_reg;
logic unsigned_reg;

// Synchronous write port logic handling byte, halfword, and word masking.
always_ff @(posedge clk) begin
    if (mem_write) begin
        case (mem_size)
            2'b10: memory[address[31:2]] <= write_data;
            2'b01:
                case (address[1])
                    1'b1: memory[address[31:2]][31:16] <= write_data[15:0];
                    1'b0: memory[address[31:2]][15:0] <= write_data[15:0];
                endcase
            2'b00:
                case (address[1:0])
                    2'b11: memory[address[31:2]][31:24] <= write_data[7:0];
                    2'b10: memory[address[31:2]][23:16] <= write_data[7:0];
                    2'b01: memory[address[31:2]][15:8] <= write_data[7:0];
                    2'b00: memory[address[31:2]][7:0] <= write_data[7:0];
                endcase
            default: memory[address[31:2]] <= write_data;
        endcase
    end
end

// Synchronous read registers storing read address offsets and memory control states.
always_ff @(posedge clk) begin
    current_word <= memory[address[31:2]];
    addr_low <= address[1:0];
    read_active <= mem_read;
    size_reg <= mem_size;
    unsigned_reg <= mem_unsigned;
end

// Asynchronously aligns the read word based on address offset.
assign shifted_word = current_word >> {addr_low, 3'b000};

// Decides size and sign extension of the read word based on control registers.
always_comb begin
    if (read_active) begin
        case (size_reg)
            2'b10: read_data = current_word;
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
            default: read_data = current_word;
        endcase
    end
    else begin
        read_data = 32'b0;
    end
end

endmodule
