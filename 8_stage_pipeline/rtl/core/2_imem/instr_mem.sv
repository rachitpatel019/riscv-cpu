/*
Instruction memory stage modeling synchronous block RAM access.
Synchronizes memory read latency with pipeline flow and manages flush bubble insertion.
*/

module instr_mem (
    input logic clk,
    input logic reset,

    input logic stall,
    input logic flush,

    input logic [31:0] pc,
    input logic [31:0] pc_plus_4,

    output logic [31:0] pc_out,
    output logic [31:0] pc_plus_4_out,
    output logic [31:0] instruction
);

localparam MEM_DEPTH = 16384;

// Models target FPGA block RAM (e.g. M9K) pre-initialized with executable program code.
(* ramstyle = "M9K" *) logic [31:0] instruction_memory [0:MEM_DEPTH-1];

logic [31:0] instr_reg;
logic [31:0] pc_reg;
logic [31:0] pc_plus_4_reg;

logic flush_reg;

initial begin
    $readmemh("program.hex", instruction_memory);
end

// Synchronously fetches instruction data on clock edges while holding values during stalls
// to match the single-cycle memory read latency with the instruction pipeline stage.
always_ff @(posedge clk) begin
    if (!stall) begin
        instr_reg <= instruction_memory[pc[31:2]];
        pc_reg <= pc;
        pc_plus_4_reg <= pc_plus_4;
    end
end

// Latches reset and branch/control flush conditions so that invalid instructions
// currently being read out of synchronous RAM are cancelled on the subsequent cycle.
always_ff @(posedge clk) begin
    if (reset) begin
        flush_reg <= 1'b1;
    end
    else if (flush) begin
        flush_reg <= 1'b1;
    end
    else if (!stall) begin
        flush_reg <= 1'b0;
    end
end

// Substitutes memory outputs with NOP instructions (32'h00000013) and zeroed PCs
// when a flush condition was latched, injecting a bubble into downstream pipeline stages.
assign instruction = (flush_reg) ? 32'h00000013 : instr_reg;
assign pc_out = (flush_reg) ? 32'b0 : pc_reg;
assign pc_plus_4_out = (flush_reg) ? 32'b0 : pc_plus_4_reg;

endmodule
