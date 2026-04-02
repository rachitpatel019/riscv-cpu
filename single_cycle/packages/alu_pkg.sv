package alu_package;
    typedef enum logic[3:0] {
        ALU_ADD = 4'b0000,
        ALU_SUB = 4'b0001,
        ALU_AND = 4'b0010,
        ALU_OR = 4'b0011,
        ALU_XOR = 4'b0100,
        ALU_SLTU = 4'b0101, // UNSIGNED LESS THAN
        ALU_SLT = 4'b0110, // SIGNED LESS THAN
        ALU_SLL = 4'b0111, // SHIFT LEFT LOGICAL (only last 5 bits of B are used to evaluate the shift amount)
        ALU_SRL = 4'b1000, // SHIFT RIGHT LOGICAL (only last 5 bits of B are used to evaluate the shift amount)
        ALU_SRA = 4'b1001, // SHIFT RIGHT ARITHMETIC (only last 5 bits of B are used to evaluate the shift amount)
        ALU_PASS = 4'b1010
    } alu_operations;
endpackage