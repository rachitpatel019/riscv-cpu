module data_mem (
    input  logic clk,
    input  logic mem_read,
    input  logic mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  logic [1:0] mem_size,
    input  logic mem_unsigned,
    output logic [31:0] read_data
);

logic [31:0] memory [0:255]; // 256 words

// Write logic
always_ff @(posedge clk) begin
    if (mem_write) begin
        case (mem_size)
            2'b10: memory[address[31:2]] <= write_data; // Word
            2'b01: // Halfword
                case (address[1])
                    1'b1: memory[address[31:2]][31:16] <= write_data[15:0];
                    1'b0: memory[address[31:2]][15:0]  <= write_data[15:0];
                endcase
            2'b00: // Byte (Corrected to Little-Endian)
                case (address[1:0])
                    2'b11: memory[address[31:2]][31:24] <= write_data[7:0];
                    2'b10: memory[address[31:2]][23:16] <= write_data[7:0];
                    2'b01: memory[address[31:2]][15:8]  <= write_data[7:0];
                    2'b00: memory[address[31:2]][7:0]   <= write_data[7:0];
                endcase
            default: memory[address[31:2]] <= write_data;
        endcase
    end
end

// Read Logic
logic [31:0] current_word;
logic [15:0] extracted_halfword;
logic [7:0]  extracted_byte;

always_comb begin
    current_word = memory[address[31:2]];

    extracted_halfword = address[1] ? current_word[31:16] : current_word[15:0];
    
    case (address[1:0])
        2'b11: extracted_byte = current_word[31:24];
        2'b10: extracted_byte = current_word[23:16];
        2'b01: extracted_byte = current_word[15:8];
        2'b00: extracted_byte = current_word[7:0];
    endcase

    if (mem_read) begin
        case (mem_size)
            2'b10: read_data = current_word;
            2'b01: // Halfword
                if (mem_unsigned)
                    read_data = {16'b0, extracted_halfword};
                else
                    read_data = {{16{extracted_halfword[15]}}, extracted_halfword}; 
            2'b00: // Byte
                if (mem_unsigned)
                    read_data = {24'b0, extracted_byte};
                else
                    read_data = {{24{extracted_byte[7]}}, extracted_byte}; 
            default: read_data = current_word;
        endcase
    end
    else begin
        read_data = 32'b0; // Default output when not reading
    end
end

endmodule