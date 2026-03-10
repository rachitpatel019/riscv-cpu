module alu(
    input logic [31:0] A, // operand 1
    input logic [31:0] B, // operand 2
    input logic [3:0] control, // operation
    output logic [31:0] result // result
);

import alu_package::*;

always_comb begin // change output immediately on input change
    // perform operation based on control variable
    case (control)
        ADD : result = A + B;
        SUBTRACT : result = A + (~B + 1'b1);
        AND : result = A & B;
        OR : result = A | B;
        XOR : result = A ^ B;
        ULT : result = {31'b0, A < B}; // UNSIGNED LESS THAN
        SLT : result = {31'b0, $signed(A) < $signed(B)}; // SIGNED LESS THAN
        SLL : result = A << B[4:0]; // SHIFT LEFT LOGICAL (only last 5 bits of B are used to evaluate the shift amount)
        SRL : result = A >> B[4:0]; // SHIFT RIGHT LOGICAL (only last 5 bits of B are used to evaluate the shift amount)
        SRA : result = $signed(A) >>> B[4:0]; // SHIFT RIGHT ARITHMETIC (only last 5 bits of B are used to evaluate the shift amount)
        default : result = 0;
    endcase
end

endmodule