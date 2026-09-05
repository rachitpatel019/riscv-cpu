/*
Pipeline register between MEM and WB stages.
Holds destination index, write control, ALU/memory data, and select signals.
*/

module MEM_WB (
    input logic clk,
    input logic reset,

    input logic [4:0] rd_in,
    input logic reg_write_in,
    input logic [31:0] fwd_val_in,
    input logic [31:0] mem_read_data_in,
    input logic mem_read_in,
    input logic [1:0] wb_sel_in,
    input logic [31:0] pc_in,

    output logic [4:0] rd_out,
    output logic reg_write_out,
    output logic [31:0] fwd_val_out,
    output logic [31:0] mem_read_data_out,
    output logic mem_read_out,
    output logic [1:0] wb_sel_out,
    output logic [31:0] pc_out
);

// Propagates Stage 7 (EX3/MEM) values to writeback Stage 8 (WB), supporting reset.
always_ff @(posedge clk) begin
    if (reset) begin
        rd_out <= 5'b0;
        reg_write_out <= 0;
        fwd_val_out <= 32'b0;
        mem_read_data_out <= 32'b0;
        mem_read_out <= 0;
        wb_sel_out <= 2'b0;
        pc_out <= 32'b0;
    end
    else begin
        rd_out <= rd_in;
        reg_write_out <= reg_write_in;
        fwd_val_out <= fwd_val_in;
        mem_read_data_out <= mem_read_data_in;
        mem_read_out <= mem_read_in;
        wb_sel_out <= wb_sel_in;
        pc_out <= pc_in;
    end
end

endmodule