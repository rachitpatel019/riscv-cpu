module alu(
    input logic [31:0] A, // operand 1
    input logic [31:0] B, // operand 2
    input logic [3:0] control, // operation
    output logic [31:0] result // result
);

logic [4:0] shamt = B[4:0]; // only last 5 bits of B are used to evaluate the shift amount

always_comb begin // change output immediately on input change
    // perform operation based on control variable
    case (control)
        4'b0000 : result = A + B; // ADD
        4'b0001 : result = A + (~B + 1'b1); // SUBTRACT
        4'b0010 : result = A & B; // AND
        4'b0011 : result = A | B; // OR
        4'b0100 : result = A ^ B; // XOR
        4'b0101 : result = {31'b0, A < B}; // UNSIGNED LESS THAN
        4'b0110 : result = {31'b0, $signed(A) < $signed(B)}; // SIGNED LESS THAN
        4'b0111 : result = A << shamt; // SHIFT LEFT LOGICAL
        4'b1000 : result = A >> shamt; // SHIFT RIGHT LOGICAL
        4'b1001 : result = $signed(A) >>> shamt; // SHIFT RIGHT ARITHMETIC
        default : result = 0;
    endcase
end

endmodule