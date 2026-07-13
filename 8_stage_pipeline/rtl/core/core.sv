/*
Eight-stage pipelined RISC-V (RV32I) CPU core.
Includes data forwarding, hazard detection, and memory-mapped I/O.
*/

module core (
    input logic clk,
    input logic reset,

    input logic [1:0] mmio_keys,
    input logic [9:0] mmio_switches,

    output logic [9:0] mmio_leds,
    output logic [23:0] mmio_hex,

    output logic [31:0] out_pc,
    output logic [31:0] out_writeback_data,
    output logic out_reg_write,
    output logic [31:0] out_alu_result
);

// Pipeline stage register input/output signals and hazard/forwarding status lines.
logic stall_frontend;
logic flush;

logic [31:0] F_pc;

logic [31:0] IM_pc_out;
logic [31:0] IM_instruction;

logic [31:0] D_pc;
logic [31:0] D_instruction;
logic [31:0] D_immediate;
logic [4:0] D_rs1;
logic [4:0] D_rs2;
logic [4:0] D_rd;
logic [31:0] D_pc_out;
logic D_uses_rs1;
logic D_uses_rs2;
logic [3:0] D_alu_op;
logic D_alu_src_a;
logic D_alu_src_b;
logic D_reg_write;
logic D_mem_read;
logic D_mem_write;
logic [1:0] D_mem_size;
logic D_mem_unsigned;
logic [1:0] D_wb_sel;
logic D_branch;
logic D_jump;
logic [2:0] D_branch_type;

logic [31:0] IDRR_immediate;
logic [4:0] IDRR_rs1;
logic [4:0] IDRR_rs2;
logic [4:0] IDRR_rd;
logic [31:0] IDRR_pc;
logic IDRR_uses_rs1;
logic IDRR_uses_rs2;
logic [3:0] IDRR_alu_op;
logic IDRR_alu_src_a;
logic IDRR_alu_src_b;
logic IDRR_reg_write;
logic IDRR_mem_read;
logic IDRR_mem_write;
logic [1:0] IDRR_mem_size;
logic IDRR_mem_unsigned;
logic [1:0] IDRR_wb_sel;
logic IDRR_branch;
logic IDRR_jump;
logic [2:0] IDRR_branch_type;
logic [1:0] IDRR_forward_a_sel;
logic [1:0] IDRR_forward_b_sel;
logic [31:0] IDRR_branch_target;
logic IDRR_predict_taken;
logic [1:0] BRAM_counter_out;
logic [1:0] IDRR_counter_val;
logic [1:0] E1_counter_val;
logic [1:0] E2_counter_val;
logic [1:0] E3_counter_val;
logic [1:0] E2_next_counter;
logic [1:0] E3_next_counter;
logic [1:0] E1_forward_a_sel;
logic [1:0] E1_forward_b_sel;
logic [31:0] RF_read_data1;
logic [31:0] RF_read_data2;

logic [31:0] E1_immediate;
logic [4:0] E1_rs1;
logic [4:0] E1_rs2;
logic [4:0] E1_rd;
logic [31:0] E1_rs1_data;
logic [31:0] E1_rs2_data;
logic [31:0] E1_pc;
logic E1_uses_rs1;
logic E1_uses_rs2;
logic [3:0] E1_alu_op;
logic E1_alu_src_a;
logic E1_alu_src_b;
logic E1_reg_write;
logic E1_mem_read;
logic E1_mem_write;
logic [1:0] E1_mem_size;
logic E1_mem_unsigned;
logic [1:0] E1_wb_sel;
logic E1_branch;
logic E1_jump;
logic [2:0] E1_branch_type;
logic [31:0] E1_branch_target;
logic E1_predict_taken;
logic [31:0] E1_operand_a;
logic [31:0] E1_operand_b;
logic [31:0] E1_rs2_data_fwd;

logic [31:0] E2_fwd_val;
logic [31:0] E3_fwd_val;
logic [31:0] W_fwd_val;

logic [31:0] E2_pc;
logic [3:0] E2_alu_op;
logic [31:0] E2_imm;
logic E2_branch;
logic E2_jump;
logic [2:0] E2_branch_type;
logic E2_reg_write;
logic E2_mem_read;
logic E2_mem_write;
logic [1:0] E2_mem_size;
logic E2_mem_unsigned;
logic [1:0] E2_wb_sel;
logic [4:0] E2_rd;
logic [31:0] E2_operand_a;
logic [31:0] E2_operand_b;
logic [31:0] E2_rs2_data;
logic [31:0] E2_alu_result;
logic E2_condition_met;
logic [31:0] E2_branch_target;
logic E2_predict_taken;

logic [31:0] E3_pc;
logic [31:0] E3_imm;
logic E3_branch;
logic E3_jump;
logic [2:0] E3_branch_type;
logic E3_reg_write;
logic E3_mem_read;
logic E3_mem_write;
logic [1:0] E3_mem_size;
logic E3_mem_unsigned;
logic [1:0] E3_wb_sel;
logic [4:0] E3_rd;
logic [31:0] E3_operand_a;
logic [31:0] E3_operand_b;
logic [31:0] E3_rs2_data;
logic [31:0] E3_alu_result;
logic E3_condition_met;
logic [31:0] E3_branch_target;
logic E3_predict_taken;
logic E3_pc_sel;
logic [31:0] E3_pc_target;

logic W_reg_write;
logic [4:0] W_rd;
logic [31:0] W_alu_result;
logic [31:0] W_pc;
logic [31:0] W_mem_read_data;
logic [1:0] W_wb_sel;
logic [31:0] W_write_data;
logic [31:0] W_wb_intermediate;

logic [31:0] F_pc_plus_4;
logic [31:0] IM_pc_plus_4;
logic [31:0] D_pc_plus_4;
logic [31:0] IDRR_pc_plus_4;
logic [31:0] E1_pc_plus_4;
logic [31:0] E2_pc_plus_4;
logic [31:0] E3_pc_plus_4;
logic [31:0] W_pc_plus_4;
logic W_mem_read;
logic [31:0] W_mem_read_data_raw;

// Flush control logic based on program counter selection.
assign flush = E3_pc_sel;
logic IDRR_is_jal;
assign IDRR_is_jal = IDRR_jump && !IDRR_uses_rs1;
logic stage4_pc_sel;
assign stage4_pc_sel = IDRR_predict_taken || IDRR_is_jal;
logic stage4_flush;
assign stage4_flush = stage4_pc_sel;

// Stage 1: Instruction Fetch. Computes the next PC value.
pc_update stage1_fetch (
    .clk(clk),
    .reset(reset),
    .stall(stall_frontend),
    .pc_sel(E3_pc_sel),
    .pc_target(E3_pc_target),
    .stage4_pc_sel(stage4_pc_sel),
    .stage4_pc_target(IDRR_branch_target),
    .pc(F_pc),
    .pc_plus_4(F_pc_plus_4)
);

// Stage 2: Instruction Memory access. Retrieves instructions from memory.
instr_mem stage2_imem (
    .clk(clk),
    .reset(reset),
    .stall(stall_frontend),
    .flush(flush || stage4_flush),
    .pc(F_pc),
    .pc_plus_4(F_pc_plus_4),
    .pc_out(IM_pc_out),
    .pc_plus_4_out(IM_pc_plus_4),
    .instruction(IM_instruction)
);

// Stage 3: Decode phase pipeline register. Passes instruction fields down the pipeline.
IF_ID stage3_if_id_reg (
    .clk(clk),
    .reset(reset),
    .stall(stall_frontend),
    .flush(flush || stage4_flush),
    .pc_in(IM_pc_out),
    .pc_plus_4_in(IM_pc_plus_4),
    .instruction_in(IM_instruction),
    .pc_out(D_pc),
    .pc_plus_4_out(D_pc_plus_4),
    .instruction_out(D_instruction)
);

// Stage 3: Instruction Decoder. Generates control signals and extracts immediates.
decode stage3_decode (
    .pc(D_pc),
    .instruction(D_instruction),
    .immediate(D_immediate),
    .rs1(D_rs1),
    .rs2(D_rs2),
    .rd(D_rd),
    .pc_out(D_pc_out),
    .uses_rs1(D_uses_rs1),
    .uses_rs2(D_uses_rs2),
    .alu_op(D_alu_op),
    .alu_src_a(D_alu_src_a),
    .alu_src_b(D_alu_src_b),
    .reg_write(D_reg_write),
    .mem_read(D_mem_read),
    .mem_write(D_mem_write),
    .mem_size(D_mem_size),
    .mem_unsigned(D_mem_unsigned),
    .wb_sel(D_wb_sel),
    .branch(D_branch),
    .jump(D_jump),
    .branch_type(D_branch_type)
);

// Stage 3: Reg Read phase pipeline register. Synchronizes controls and handles bubble insertion on stalls.
ID_RR stage3_id_rr_reg (
    .clk(clk),
    .reset(reset),
    .stall(stall_frontend),
    .flush(flush || stall_frontend || stage4_flush), 
    .immediate_in(D_immediate),
    .rs1_in(D_rs1),
    .rs2_in(D_rs2),
    .rd_in(D_rd),
    .pc_in(D_pc_out),
    .pc_plus_4_in(D_pc_plus_4),
    .uses_rs1_in(D_uses_rs1),
    .uses_rs2_in(D_uses_rs2),
    .alu_op_in(D_alu_op),
    .alu_src_a_in(D_alu_src_a),
    .alu_src_b_in(D_alu_src_b),
    .reg_write_in(D_reg_write),
    .mem_read_in(D_mem_read),
    .mem_write_in(D_mem_write),
    .mem_size_in(D_mem_size),
    .mem_unsigned_in(D_mem_unsigned),
    .wb_sel_in(D_wb_sel),
    .branch_in(D_branch),
    .jump_in(D_jump),
    .branch_type_in(D_branch_type),
    .immediate_out(IDRR_immediate),
    .rs1_out(IDRR_rs1),
    .rs2_out(IDRR_rs2),
    .rd_out(IDRR_rd),
    .pc_out(IDRR_pc),
    .pc_plus_4_out(IDRR_pc_plus_4),
    .uses_rs1_out(IDRR_uses_rs1),
    .uses_rs2_out(IDRR_uses_rs2),
    .alu_op_out(IDRR_alu_op),
    .alu_src_a_out(IDRR_alu_src_a),
    .alu_src_b_out(IDRR_alu_src_b),
    .reg_write_out(IDRR_reg_write),
    .mem_read_out(IDRR_mem_read),
    .mem_write_out(IDRR_mem_write),
    .mem_size_out(IDRR_mem_size),
    .mem_unsigned_out(IDRR_mem_unsigned),
    .wb_sel_out(IDRR_wb_sel),
    .branch_out(IDRR_branch),
    .jump_out(IDRR_jump),
    .branch_type_out(IDRR_branch_type)
);

// Stage 4: Register File read. Decodes rs1/rs2 addresses to retrieve register contents.
regfile stage4_regfile (
    .clk(clk),
    .read_address1(IDRR_rs1),
    .read_address2(IDRR_rs2),
    .read_data1(E1_rs1_data),
    .read_data2(E1_rs2_data),
    .write_address(W_rd),
    .write_data(W_write_data),
    .write_enable(W_reg_write)
);

// Forwarding Unit. Evaluates downstream stage registers to resolve register hazards.
forwarding_unit fwd_unit (
    .IDRR_rs1(IDRR_rs1),
    .IDRR_rs2(IDRR_rs2),
    .IDRR_uses_rs1(IDRR_uses_rs1),
    .IDRR_uses_rs2(IDRR_uses_rs2),
    .E2_reg_write(E2_reg_write),
    .E2_mem_read(E2_mem_read),
    .E2_rd(E2_rd),
    .E3_reg_write(E3_reg_write),
    .E3_rd(E3_rd),
    .forward_a_sel(IDRR_forward_a_sel),
    .forward_b_sel(IDRR_forward_b_sel)
);

// Stage 4: Branch target calculation
assign IDRR_branch_target = IDRR_pc + IDRR_immediate;

// Stage 4: Branch History Table. Predicts branch outcomes.
bht stage4_bht (
    .clk(clk),
    .reset(reset),
    .read_index(D_pc[11:2]),
    .read_enable(!stall_frontend),
    .read_counter_out(BRAM_counter_out),
    .write_index(E3_pc[11:2]),
    .write_enable(E3_branch),
    .write_counter_in(E3_next_counter)
);

// Stage 6 and Stage 7 Next Counter computation
always_comb begin
    if (E2_condition_met)
        E2_next_counter = (E2_counter_val == 2'b11) ? 2'b11 : E2_counter_val + 2'b01;
    else
        E2_next_counter = (E2_counter_val == 2'b00) ? 2'b00 : E2_counter_val - 2'b01;
end

always_comb begin
    if (E3_condition_met)
        E3_next_counter = (E3_counter_val == 2'b11) ? 2'b11 : E3_counter_val + 2'b01;
    else
        E3_next_counter = (E3_counter_val == 2'b00) ? 2'b00 : E3_counter_val - 2'b01;
end

// BHT Bypass logic
always_comb begin
    if (E3_branch && (E3_pc[11:2] == IDRR_pc[11:2])) begin
        IDRR_counter_val = E3_next_counter;
    end
    else if (E2_branch && (E2_pc[11:2] == IDRR_pc[11:2])) begin
        IDRR_counter_val = E2_next_counter;
    end
    else begin
        IDRR_counter_val = BRAM_counter_out;
    end
end

// Predict taken if MSB of the counter is 1
assign IDRR_predict_taken = IDRR_branch && (IDRR_counter_val[1] == 1'b1);

// Stage 4: EX1 phase pipeline register. Synchronizes operand selection controls.
RR_EX1 stage4_rr_ex1_reg (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .immediate_in(IDRR_immediate),
    .rs1_in(IDRR_rs1),
    .rs2_in(IDRR_rs2),
    .rd_in(IDRR_rd),
    .pc_in(IDRR_pc),
    .pc_plus_4_in(IDRR_pc_plus_4),
    .uses_rs1_in(IDRR_uses_rs1),
    .uses_rs2_in(IDRR_uses_rs2),
    .alu_op_in(IDRR_alu_op),
    .alu_src_a_in(IDRR_alu_src_a),
    .alu_src_b_in(IDRR_alu_src_b),
    .reg_write_in(IDRR_reg_write),
    .mem_read_in(IDRR_mem_read),
    .mem_write_in(IDRR_mem_write),
    .mem_size_in(IDRR_mem_size),
    .mem_unsigned_in(IDRR_mem_unsigned),
    .wb_sel_in(IDRR_wb_sel),
    .branch_in(IDRR_branch),
    .jump_in(IDRR_jump && IDRR_uses_rs1),
    .branch_type_in(IDRR_branch_type),
    .predicted_taken_in(IDRR_predict_taken),
    .forward_a_sel_in(IDRR_forward_a_sel),
    .forward_b_sel_in(IDRR_forward_b_sel),
    .branch_target_in(IDRR_branch_target),
    .counter_val_in(IDRR_counter_val),
    .immediate_out(E1_immediate),
    .rs1_out(E1_rs1),
    .rs2_out(E1_rs2),
    .rd_out(E1_rd),
    .pc_out(E1_pc),
    .pc_plus_4_out(E1_pc_plus_4),
    .uses_rs1_out(E1_uses_rs1),
    .uses_rs2_out(E1_uses_rs2),
    .alu_op_out(E1_alu_op),
    .alu_src_a_out(E1_alu_src_a),
    .alu_src_b_out(E1_alu_src_b),
    .reg_write_out(E1_reg_write),
    .mem_read_out(E1_mem_read),
    .mem_write_out(E1_mem_write),
    .mem_size_out(E1_mem_size),
    .mem_unsigned_out(E1_mem_unsigned),
    .wb_sel_out(E1_wb_sel),
    .branch_out(E1_branch),
    .jump_out(E1_jump),
    .branch_type_out(E1_branch_type),
    .predicted_taken_out(E1_predict_taken),
    .forward_a_sel_out(E1_forward_a_sel),
    .forward_b_sel_out(E1_forward_b_sel),
    .branch_target_out(E1_branch_target),
    .counter_val_out(E1_counter_val)
);

// Forwarding data path assignments for downstream execution stages.
assign E2_fwd_val = (E2_wb_sel == 2'b10) ? E2_pc_plus_4 : E2_alu_result;
assign E3_fwd_val = (E3_wb_sel == 2'b10) ? E3_pc_plus_4 : E3_alu_result;
assign W_fwd_val = W_write_data;

// Stage 5: Data selector. Multiplexes register operands and forwarded values.
data_sel stage5_data_sel (
    .pc(E1_pc),
    .rs1_data(E1_rs1_data),
    .rs2_data(E1_rs2_data),
    .imm(E1_immediate),
    .alu_src_a(E1_alu_src_a),
    .alu_src_b(E1_alu_src_b),
    .forward_a_sel(E1_forward_a_sel),
    .forward_b_sel(E1_forward_b_sel),
    .fwd_ex2_data(E3_fwd_val),
    .fwd_ex3_data(W_fwd_val),
    .operand_a(E1_operand_a),
    .operand_b(E1_operand_b),
    .rs2_data_out(E1_rs2_data_fwd)
);

// Stage 5: EX2 phase pipeline register. Registers ALU inputs and control signals.
EX1_EX2 stage5_ex1_ex2_reg (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .pc_in(E1_pc),
    .pc_plus_4_in(E1_pc_plus_4),
    .alu_op_in(E1_alu_op),
    .imm_in(E1_immediate),
    .branch_in(E1_branch),
    .jump_in(E1_jump),
    .branch_type_in(E1_branch_type),
    .predicted_taken_in(E1_predict_taken),
    .reg_write_in(E1_reg_write),
    .rd_in(E1_rd),
    .operand_a_in(E1_operand_a),
    .operand_b_in(E1_operand_b),
    .rs2_data_in(E1_rs2_data_fwd),
    .mem_read_in(E1_mem_read),
    .mem_write_in(E1_mem_write),
    .mem_size_in(E1_mem_size),
    .mem_unsigned_in(E1_mem_unsigned),
    .wb_sel_in(E1_wb_sel),
    .branch_target_in(E1_branch_target),
    .counter_val_in(E1_counter_val),
    .pc_out(E2_pc),
    .pc_plus_4_out(E2_pc_plus_4),
    .alu_op_out(E2_alu_op),
    .imm_out(E2_imm),
    .branch_out(E2_branch),
    .jump_out(E2_jump),
    .branch_type_out(E2_branch_type),
    .predicted_taken_out(E2_predict_taken),
    .reg_write_out(E2_reg_write),
    .rd_out(E2_rd),
    .operand_a_out(E2_operand_a),
    .operand_b_out(E2_operand_b),
    .rs2_data_out(E2_rs2_data),
    .mem_read_out(E2_mem_read),
    .mem_write_out(E2_mem_write),
    .mem_size_out(E2_mem_size),
    .mem_unsigned_out(E2_mem_unsigned),
    .wb_sel_out(E2_wb_sel),
    .branch_target_out(E2_branch_target),
    .counter_val_out(E2_counter_val)
);

// Stage 6: Arithmetic Logic Unit. Executes arithmetic and logical operations.
alu stage6_alu (
    .A(E2_operand_a),
    .B(E2_operand_b),
    .control(E2_alu_op),
    .result(E2_alu_result)
);

// Stage 6: Branch evaluator. Computes branch condition results.
branch_eval stage6_branch_eval (
    .operand_a(E2_operand_a),
    .operand_b(E2_operand_b),
    .branch_type(E2_branch_type),
    .condition_met(E2_condition_met)
);

// Stage 6: EX3/MEM phase pipeline register. Stores ALU outputs and memory commands.
EX2_EX3 stage6_ex2_ex3_reg (
    .clk(clk),
    .reset(reset),
    .flush(flush),
    .pc_in(E2_pc),
    .pc_plus_4_in(E2_pc_plus_4),
    .imm_in(E2_imm),
    .branch_in(E2_branch),
    .jump_in(E2_jump),
    .branch_type_in(E2_branch_type),
    .predicted_taken_in(E2_predict_taken),
    .reg_write_in(E2_reg_write),
    .rd_in(E2_rd),
    .operand_a_in(E2_operand_a),
    .operand_b_in(E2_operand_b),
    .rs2_data_in(E2_rs2_data),
    .alu_result_in(E2_alu_result),
    .condition_met_in(E2_condition_met),
    .branch_target_in(E2_branch_target),
    .mem_read_in(E2_mem_read),
    .mem_write_in(E2_mem_write),
    .mem_size_in(E2_mem_size),
    .mem_unsigned_in(E2_mem_unsigned),
    .wb_sel_in(E2_wb_sel),
    .counter_val_in(E2_counter_val),
    .pc_out(E3_pc),
    .pc_plus_4_out(E3_pc_plus_4),
    .imm_out(E3_imm),
    .branch_out(E3_branch),
    .jump_out(E3_jump),
    .branch_type_out(E3_branch_type),
    .predicted_taken_out(E3_predict_taken),
    .reg_write_out(E3_reg_write),
    .rd_out(E3_rd),
    .operand_a_out(E3_operand_a),
    .operand_b_out(E3_operand_b),
    .rs2_data_out(E3_rs2_data),
    .alu_result_out(E3_alu_result),
    .condition_met_out(E3_condition_met),
    .branch_target_out(E3_branch_target),
    .mem_read_out(E3_mem_read),
    .mem_write_out(E3_mem_write),
    .mem_size_out(E3_mem_size),
    .mem_unsigned_out(E3_mem_unsigned),
    .wb_sel_out(E3_wb_sel),
    .counter_val_out(E3_counter_val)
);

// Stage 7: Program Counter target calculator. Selects jump or branch targets.
pc_target_calc stage7_calc (
    .pc(E3_pc),
    .pc_plus_4(E3_pc_plus_4),
    .operand_a(E3_operand_a),
    .operand_b(E3_operand_b),
    .branch(E3_branch),
    .jump(E3_jump),
    .branch_type(E3_branch_type),
    .imm(E3_imm),
    .alu_result(E3_alu_result),
    .condition_met_in(E3_condition_met),
    .branch_target_in(E3_branch_target),
    .predicted_taken_in(E3_predict_taken),
    .pc_sel(E3_pc_sel),
    .pc_target(E3_pc_target)
);

// Pre-writeback selection multiplexer.
assign W_wb_intermediate = (E3_wb_sel == 2'b10) ? E3_pc_plus_4 : E3_alu_result;

// Stage 7: Writeback phase pipeline register. Registers memory or ALU writeback values.
MEM_WB stage7_mem_wb_reg (
    .clk(clk),
    .reset(reset),
    .rd_in(E3_rd),
    .reg_write_in(E3_reg_write),
    .alu_result_in(W_wb_intermediate),
    .mem_read_data_in(W_mem_read_data_raw),
    .mem_read_in(E3_mem_read),
    .wb_sel_in(E3_wb_sel),
    .pc_in(E3_pc),
    .pc_plus_4_in(E3_pc_plus_4),
    .rd_out(W_rd),
    .reg_write_out(W_reg_write),
    .alu_result_out(W_alu_result),
    .mem_read_data_out(W_mem_read_data),
    .mem_read_out(W_mem_read),
    .wb_sel_out(W_wb_sel),
    .pc_out(W_pc),
    .pc_plus_4_out(W_pc_plus_4)
);

// Stage 8: Data Memory interconnect. Interfaces to data BRAM and MMIO registers.
memory stage8_memory_system (
    .clk(clk),
    .reset(reset),
    .mem_read(E2_mem_read),
    .mem_write(E2_mem_write),
    .address(E2_alu_result),
    .write_data(E2_rs2_data),
    .mem_size(E2_mem_size),
    .mem_unsigned(E2_mem_unsigned),
    .read_data(W_mem_read_data_raw),
    .mmio_keys(mmio_keys),
    .mmio_switches(mmio_switches),
    .mmio_leds(mmio_leds),
    .mmio_hex(mmio_hex)
);

// Stage 8: Writeback multiplexer. Decides data source for register file write.
writeback stage8_wb (
    .pc(W_pc),
    .alu_result(W_alu_result),
    .mem_data(W_mem_read_data),
    .wb_sel(W_wb_sel),
    .write_data(W_write_data)
);

// Hazard detection unit. Stalls frontend execution on load-use hazards.
hazard_detection_unit hazard_unit (
    .D_rs1(D_rs1),
    .D_rs2(D_rs2),
    .D_uses_rs1(D_uses_rs1),
    .D_uses_rs2(D_uses_rs2),
    .RR_reg_write(IDRR_reg_write),
    .RR_rd(IDRR_rd),
    .E1_reg_write(E1_reg_write),
    .E1_rd(E1_rd),
    .stall(stall_frontend)
);

// Output interface assignments. Exposes internal CPU states for monitoring.
assign out_pc = W_pc;
assign out_writeback_data = W_write_data;
assign out_reg_write = W_reg_write;
assign out_alu_result = E2_alu_result;

endmodule
