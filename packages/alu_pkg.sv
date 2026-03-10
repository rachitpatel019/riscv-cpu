package alu_package;
    typedef enum logic[3:0] {
        ADD = 4'b0000,
        SUBTRACT = 4'b0001,
        AND = 4'b0010,
        OR = 4'b0011,
        XOR = 4'b0100,
        ULT = 4'b0101, // UNSIGNED LESS THAN
        SLT = 4'b0110, // SIGNED LESS THAN
        SLL = 4'b0111, // SHIFT LEFT LOGICAL (only last 5 bits of B are used to evaluate the shift amount)
        SRL = 4'b1000, // SHIFT RIGHT LOGICAL (only last 5 bits of B are used to evaluate the shift amount)
        SRA = 4'b1001 // SHIFT RIGHT ARITHMETIC (only last 5 bits of B are used to evaluate the shift amount)
    } alu_operations;

endpackage