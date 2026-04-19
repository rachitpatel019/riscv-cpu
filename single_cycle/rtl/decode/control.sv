module control(
    input logic [31:0] instruction,
    
    // Execution control
    output logic [3:0] alu_op,
    output logic alu_src_a,         // 0: rs1_data, 1: pc
    output logic alu_src_b,         // 0: rs2_data, 1: immediate
    
    // Memory and Writeback control
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] mem_size,    // 00: Byte, 01: Halfword, 10: Word
    output logic mem_unsigned,      // 0: Sign-extend, 1: Zero-extend
    output logic [1:0] wb_sel,      // 00: ALU Result, 01: Read Data, 10: PC + 4
    
    // Control flow
    output logic branch,
    output logic jump,
    output logic [2:0] branch_type  // Passes funct3 directly to the branch evaluator
);

import decoder_package::*;
import alu_package::*;

// Field Extraction
logic [6:0] opcode;
logic [2:0] f3;
logic [6:0] f7;

assign opcode = instruction[6:0];
assign f3 = instruction[14:12];
assign f7 = instruction[31:25];

// Direct Extractions for Data Memory and Branching
assign mem_size = f3[1:0];      // 00=B, 01=H, 10=W (Matches RV32I encoding)
assign mem_unsigned = f3[2];    // 1=Unsigned (LBU, LHU)
assign branch_type = f3;        // Tells execute stage which branch condition to check

// 1️⃣ Main Control (opcode only)
always_comb begin
    // Default values
    alu_src_a = 0;
    alu_src_b = 0;
    reg_write = 0;
    mem_read = 0;
    mem_write = 0;
    wb_sel = 2'b00;
    branch = 0;
    jump = 0;

    case (opcode)

        // R-type
        OP_R: begin
            reg_write = 1;
        end

        // I-type arithmetic
        OP_I: begin
            alu_src_b = 1;
            reg_write = 1;
        end

        // Loads
        OP_I_LOAD: begin
            alu_src_b = 1;
            reg_write = 1;
            mem_read = 1;
            wb_sel = 2'b01; // Select Memory
        end

        // Stores
        OP_S: begin
            alu_src_b = 1;
            mem_write = 1;
        end

        // Branches
        OP_B: begin
            branch = 1;
            // alu_src_a and b remain 0 to compare rs1 and rs2 in the ALU
        end

        // LUI
        OP_U_LUI: begin
            alu_src_b = 1;
            reg_write = 1;
            wb_sel = 2'b00; // Select ALU (ALU_PASS will pass the immediate)
        end

        // AUIPC
        OP_U_AUIPC: begin
            alu_src_a = 1; // Route PC to ALU A
            alu_src_b = 1; // Route Immediate to ALU B
            reg_write = 1;
            wb_sel = 2'b00; // Select ALU
        end

        // JAL
        OP_J: begin
            alu_src_a = 1; // PC (Can be used by ALU to compute branch target if needed)
            alu_src_b = 1; // Immediate
            jump = 1;
            reg_write = 1;
            wb_sel = 2'b10; // Select PC + 4 for linking
        end

        // JALR
        OP_I_JALR: begin
            alu_src_a = 0; // rs1
            alu_src_b = 1; // Immediate
            jump = 1;
            reg_write = 1;
            wb_sel = 2'b10; // Select PC + 4 for linking
        end

        default: ;
    endcase
end

// 2️⃣ ALU Control (opcode + funct3 + funct7)
always_comb begin
    // Default ALU op
    alu_op = ALU_ADD;

    case (opcode)

        // R-TYPE
        OP_R: begin
            case (f3)
                F3_ADD_SUB:
                    case (f7)
                        F7_ADD_SRL: alu_op = ALU_ADD;
                        F7_SUB_SRA: alu_op = ALU_SUB;
                    endcase
                F3_SLL: alu_op = ALU_SLL;
                F3_SLT: alu_op = ALU_SLT;
                F3_SLTU: alu_op = ALU_SLTU;
                F3_XOR: alu_op = ALU_XOR;
                F3_SRL_SRA:
                    case (f7)
                        F7_ADD_SRL: alu_op = ALU_SRL;
                        F7_SUB_SRA: alu_op = ALU_SRA;
                    endcase
                F3_OR: alu_op = ALU_OR;
                F3_AND: alu_op = ALU_AND;
            endcase
        end

        // I-TYPE
        OP_I: begin
            case (f3)
                F3_ADD_SUB: alu_op = ALU_ADD;
                F3_SLT: alu_op = ALU_SLT;
                F3_SLTU: alu_op = ALU_SLTU;
                F3_XOR: alu_op = ALU_XOR;
                F3_OR: alu_op = ALU_OR;
                F3_AND: alu_op = ALU_AND;
                F3_SLL: alu_op = ALU_SLL;
                F3_SRL_SRA:
                    case (f7)
                        F7_ADD_SRL: alu_op = ALU_SRL;
                        F7_SUB_SRA: alu_op = ALU_SRA;
                        default: alu_op = ALU_SRL;
                    endcase
            endcase
        end

        // LOAD/STORE
        OP_I_LOAD, OP_S: begin
            alu_op = ALU_ADD; // Used for address calculation
        end

        // BRANCH
        OP_B: begin
            case (f3)
                3'b000: alu_op = ALU_SUB;  // BEQ
                3'b001: alu_op = ALU_SUB;  // BNE
                3'b100: alu_op = ALU_SLT;  // BLT
                3'b101: alu_op = ALU_SLT;  // BGE
                3'b110: alu_op = ALU_SLTU; // BLTU
                3'b111: alu_op = ALU_SLTU; // BGEU
                default: alu_op = ALU_SUB;
            endcase
        end

        // U-TYPE
        OP_U_LUI: begin
            alu_op = ALU_PASS; // Just pass immediate
        end

        OP_U_AUIPC: begin
            alu_op = ALU_ADD;  // PC + imm
        end

        // JUMPS
        OP_J,
        OP_I_JALR: begin
            alu_op = ALU_ADD;  // PC + imm OR rs1 + imm
        end

        default: ;

    endcase
end

endmodule