module alu(
    input logic [31:0] A, // operand 1
    input logic [31:0] B, // operand 2
    input logic [1:0] control, // operation
    output logic [31:0] result // result
);

always_comb begin
    case (control)
        2'b00 : result = A + B; // ADD
        2'b01 : result = A - B; // SUBTRACT
        2'b10 : result = A & B; // AND
        2'b11 : result = A | B; // OR
        default : result = 0;
    endcase
end

endmodule

// TODO: rewrite SUBTRACT using ADD