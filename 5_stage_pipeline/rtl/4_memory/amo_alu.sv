// Atomic Memory Operation ALU
// Performs the read-modify-write operation for AMO instructions.

module amo_alu (
    input logic [31:0] mem_read_data,
    input logic [31:0] rs2_data,
    input logic [4:0]  amo_op,
    output logic [31:0] amo_result
);

import decoder_package::*;

always_comb begin
    case (amo_op)
        AMO_SWAP:  amo_result = rs2_data;
        AMO_ADD:   amo_result = mem_read_data + rs2_data;
        AMO_XOR:   amo_result = mem_read_data ^ rs2_data;
        AMO_AND:   amo_result = mem_read_data & rs2_data;
        AMO_OR:    amo_result = mem_read_data | rs2_data;
        AMO_MIN:   amo_result = ($signed(mem_read_data) < $signed(rs2_data)) ? mem_read_data : rs2_data;
        AMO_MAX:   amo_result = ($signed(mem_read_data) > $signed(rs2_data)) ? mem_read_data : rs2_data;
        AMO_MINU:  amo_result = (mem_read_data < rs2_data) ? mem_read_data : rs2_data;
        AMO_MAXU:  amo_result = (mem_read_data > rs2_data) ? mem_read_data : rs2_data;
        default:   amo_result = mem_read_data; // For LR and SC, though SC overrides write_data elsewhere
    endcase
end

endmodule
