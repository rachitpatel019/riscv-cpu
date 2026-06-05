/*
Module to calculate and output the next program counter (PC) value.
*/

module pc_update (
    input logic clk,
    input logic reset,

    input logic stall,
    input logic flush,
    
    input logic pc_sel,
    input logic [31:0] pc_target,

    output logic [31:0] pc
);

always_ff @(posedge clk) begin
    if (reset) begin
        pc <= 32'b0;
    end
    else if (stall) begin
        pc <= pc;
    end
    else if (pc_sel) begin
        pc <= pc_target;
    end
    else begin
        pc <= pc + 32'd4;
    end
end

endmodule