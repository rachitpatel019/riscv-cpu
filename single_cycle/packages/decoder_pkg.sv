package decoder_package;
    typedef enum logic [6:0] {
        OP_R = 7'b0110011,
        OP_I = 7'b0010011,
        OP_I_LOAD = 7'b0000011,
        OP_S = 7'b0100011,
        OP_B = 7'b1100011,
        OP_U_LUI = 7'b0110111,
        OP_U_AUIPC = 7'b0010111,
        OP_J = 7'b1101111,
        OP_I_JALR = 7'b1100111 
    } opcode_t;

    typedef enum logic [2:0] {
        F3_ADD_SUB = 3'b000,
        F3_SLL = 3'b001,
        F3_SLT = 3'b010,
        F3_SLTU = 3'b011,
        F3_XOR = 3'b100,
        F3_SRL_SRA = 3'b101,
        F3_OR = 3'b110,
        F3_AND = 3'b111
    } f3_RI_t;

    typedef enum logic [6:0] {
        F7_ADD_SRL = 7'b0000000,
        F7_SUB_SRA = 7'b0100000
    } f7_R_t;
endpackage