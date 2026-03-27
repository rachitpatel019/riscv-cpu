module control(
    input logic [31:0] instruction,
    
    output logic [3:0] alu_op,
    output logic alu_src,
    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic mem_to_reg,
    output logic branch,
    output logic jump
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

// Main Control (opcode only)
always_comb begin
    // Default values
    alu_src = 0;
    reg_write = 0;
    mem_read = 0;
    mem_write = 0;
    mem_to_reg = 0;
    branch = 0;
    jump = 0;

    case (opcode)

        // R-type
        OP_R: begin
            reg_write = 1;
        end

        // I-type arithmetic
        OP_I: begin
            alu_src = 1;
            reg_write = 1;
        end

        // Loads
        OP_I_LOAD: begin
            alu_src = 1;
            reg_write = 1;
            mem_read = 1;
            mem_to_reg = 1;
        end

        // Stores
        OP_S: begin
            alu_src = 1;
            mem_write = 1;
        end

        // Branches
        OP_B: begin
            branch = 1;
        end

        // LUI
        OP_U_LUI: begin
            reg_write = 1;
        end

        // AUIPC
        OP_U_AUIPC: begin
            alu_src = 1;
            reg_write = 1;
        end

        // JAL
        OP_J: begin
            jump = 1;
            reg_write = 1;
        end

        // JALR
        OP_I_JALR: begin
            alu_src = 1;
            jump = 1;
            reg_write = 1;
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
                    endcase
            endcase
        end

        // LOAD/STORE
        OP_I_LOAD, OP_S: begin
            alu_op = ALU_ADD; // address calculation
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
            endcase
        end

        // U-TYPE
        OP_U_LUI: begin
            alu_op = ALU_PASS; // just pass immediate
        end

        OP_U_AUIPC: begin
            alu_op = ALU_ADD; // PC + imm
        end

        // JUMPS
        OP_J,
        OP_I_JALR: begin
            alu_op = ALU_ADD;
        end

        default: ;

    endcase
end

endmodule