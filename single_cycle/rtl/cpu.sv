module cpu (
    input logic clk,
    input logic reset
);

// -----------------------------------------
// FETCH STAGE
// -----------------------------------------
logic [31:0] pc;
logic [31:0] instruction;
logic [31:0] pc_target;
logic pc_sel;

fetch fetch_inst (
    .clk(clk),
    .reset(reset),
    .pc_target(pc_target), // NEW: Target address from Execute
    .pc_sel(pc_sel),       // NEW: Branch/Jump flag from Execute
    .pc(pc),
    .instruction(instruction)
);

// -----------------------------------------
// DECODE STAGE
// -----------------------------------------
logic [31:0] rs1_data, rs2_data, imm;
logic [4:0]  rs1, rs2, rd;
logic [31:0] pc_out;       // NEW: Passed-through PC

// Control signals
logic alu_src_a, alu_src_b; 
logic mem_read, mem_write, reg_write;
logic [1:0] wb_sel;        // NEW: 2-bit writeback selector
logic [1:0] mem_size;      // NEW: Byte, Halfword, Word
logic mem_unsigned;        // NEW: Zero-extension flag
logic branch, jump;
logic [2:0] branch_type;   // NEW: Type of branch evaluation
logic [3:0] alu_op;
logic [31:0] write_data;

decode decode_inst (
    .clk(clk),
    .instruction(instruction),
    .pc(pc),               // NEW: PC input

    // Writeback interface
    .reg_write_wb(reg_write),
    .rd_wb(rd),
    .write_data_wb(write_data),

    // Outputs
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .immediate(imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .pc_out(pc_out),       // NEW: PC output

    // Control signals
    .alu_src_a(alu_src_a), // NEW
    .alu_src_b(alu_src_b), // NEW
    .alu_op(alu_op),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),   // NEW
    .mem_unsigned(mem_unsigned), // NEW
    .wb_sel(wb_sel),       // NEW
    .reg_write(reg_write),
    .branch(branch),
    .jump(jump),
    .branch_type(branch_type) // NEW
);

// -----------------------------------------
// EXECUTE STAGE
// -----------------------------------------
logic [31:0] alu_result;

execute execute_inst (
    .pc(pc_out),           // NEW: PC input
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .imm(imm),
    .alu_src_a(alu_src_a), // NEW
    .alu_src_b(alu_src_b), // NEW
    .alu_op(alu_op),
    .branch(branch),       // NEW
    .jump(jump),           // NEW
    .branch_type(branch_type), // NEW
    
    .alu_result(alu_result),
    .pc_target(pc_target), // NEW: Output to Fetch
    .pc_sel(pc_sel)        // NEW: Output to Fetch
);

// -----------------------------------------
// MEMORY STAGE
// -----------------------------------------
logic [31:0] read_data;

memory memory_inst (
    .clk(clk),
    .alu_result(alu_result),
    .rs2_data(rs2_data),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_size(mem_size),         // NEW
    .mem_unsigned(mem_unsigned), // NEW

    .read_data(read_data),
    .alu_result_out()            // unused
);

// -----------------------------------------
// WRITEBACK STAGE
// -----------------------------------------
writeback wb_inst (
    .alu_result(alu_result),
    .read_data(read_data),
    .pc(pc_out),           // NEW: PC input for JAL/JALR
    .wb_sel(wb_sel),       // NEW: 3-way multiplexer control

    .write_data(write_data)
);

endmodule