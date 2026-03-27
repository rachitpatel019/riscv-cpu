module imm_gen(
    input logic [31:0] instruction,
    output logic [31:0] immediate
);

import decoder_package::*;

logic [6:0] opcode;
assign opcode = instruction[6:0];

always_comb begin
    case (opcode)
        OP_I, OP_I_LOAD, OP_I_JALR:  
            immediate = {
                {20{instruction[31]}},
                instruction[31:20]
            };

        OP_S: 
            immediate = {
                {20{instruction[31]}},
                instruction[31:25],
                instruction[11:7]
            };

        OP_B: 
            immediate = {
                {19{instruction[31]}},
                instruction[31],
                instruction[7],
                instruction[30:25],
                instruction[11:8],
                1'b0
            };

        OP_U_LUI, OP_U_AUIPC: 
            immediate = {
                instruction[31:12],
                12'b0
            };

        OP_J: 
            immediate = {
                {11{instruction[31]}},
                instruction[31],
                instruction[19:12],
                instruction[20],
                instruction[30:21],
                1'b0
            };

        default: immediate = 32'b0;
    endcase
end

endmodule