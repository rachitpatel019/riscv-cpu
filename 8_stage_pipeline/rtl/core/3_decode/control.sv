/*
Control unit decoding instruction opcodes, funct3, and funct7 fields.
Generates processor control signals for the execution pipeline.
*/

module control (
    input logic [31:0] instruction,

    output logic uses_rs1,
    output logic uses_rs2,
    output logic [3:0] alu_op,
    output logic alu_src_a,
    output logic alu_src_b,

    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic [1:0] mem_size,
    output logic mem_unsigned,
    output logic [1:0] wb_sel,

    output logic branch,
    output logic jump,
    output logic [2:0] branch_type
);

import decoder_package::*;
import alu_package::*;

logic [6:0] opcode;
logic [2:0] f3;
logic [6:0] f7;

// Decodes instruction fields and assigns size, unsigned, and branch parameters.
assign opcode = instruction[6:0];
assign f3 = instruction[14:12];
assign f7 = instruction[31:25];

assign mem_size = f3[1:0];
assign mem_unsigned = f3[2];
assign branch_type = f3;

// Combinational block generating control signals based on instruction opcode.
always_comb begin
    uses_rs1 = 0;
    uses_rs2 = 0;
    alu_src_a = 0;
    alu_src_b = 0;
    reg_write = 0;
    mem_read = 0;
    mem_write = 0;
    wb_sel = 2'b00;
    branch = 0;
    jump = 0;

    case (opcode)
        OP_R: begin
            uses_rs1 = 1;
            uses_rs2 = 1;
            reg_write = 1;
        end

        OP_I: begin
            uses_rs1 = 1;
            alu_src_b = 1;
            reg_write = 1;
        end

        OP_I_LOAD: begin
            uses_rs1 = 1;
            alu_src_b = 1;
            reg_write = 1;
            mem_read = 1;
            wb_sel = 2'b01;
        end

        OP_S: begin
            uses_rs1 = 1;
            uses_rs2 = 1;
            alu_src_b = 1;
            mem_write = 1;
        end

        OP_B: begin
            uses_rs1 = 1;
            uses_rs2 = 1;
            branch = 1;
        end

        OP_U_LUI: begin
            alu_src_b = 1;
            reg_write = 1;
            wb_sel = 2'b00;
        end

        OP_U_AUIPC: begin
            alu_src_a = 1;
            alu_src_b = 1;
            reg_write = 1;
            wb_sel = 2'b00;
        end

        OP_J: begin
            alu_src_a = 1;
            alu_src_b = 1;
            jump = 1;
            reg_write = 1;
            wb_sel = 2'b10;
        end

        OP_I_JALR: begin
            uses_rs1 = 1;
            alu_src_a = 0;
            alu_src_b = 1;
            jump = 1;
            reg_write = 1;
            wb_sel = 2'b10;
        end

        default: ;
    endcase
end

// Combinational block determining ALU operation codes based on opcodes and function fields.
always_comb begin
    alu_op = ALU_ADD;

    case (opcode)
        OP_R: begin
            case (f3)
                F3_ADD_SUB:
                    case (f7)
                        F7_ADD_SRL: alu_op = ALU_ADD;
                        F7_SUB_SRA: alu_op = ALU_SUB;
                        default: alu_op = ALU_ADD;
                    endcase
                F3_SLL: alu_op = ALU_SLL;
                F3_SLT: alu_op = ALU_SLT;
                F3_SLTU: alu_op = ALU_SLTU;
                F3_XOR: alu_op = ALU_XOR;
                F3_SRL_SRA:
                    case (f7)
                        F7_ADD_SRL: alu_op = ALU_SRL;
                        F7_SUB_SRA: alu_op = ALU_SRA;
                        default: alu_op = ALU_SRL;
                    endcase
                F3_OR: alu_op = ALU_OR;
                F3_AND: alu_op = ALU_AND;
            endcase
        end

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

        OP_I_LOAD, OP_S: begin
            alu_op = ALU_ADD;
        end

        OP_B: begin
            case (f3)
                3'b000: alu_op = ALU_SUB;
                3'b001: alu_op = ALU_SUB;
                3'b100: alu_op = ALU_SLT;
                3'b101: alu_op = ALU_SLT;
                3'b110: alu_op = ALU_SLTU;
                3'b111: alu_op = ALU_SLTU;
                default: alu_op = ALU_SUB;
            endcase
        end

        OP_U_LUI: begin
            alu_op = ALU_PASS;
        end

        OP_U_AUIPC: begin
            alu_op = ALU_ADD;
        end

        OP_J, OP_I_JALR: begin
            alu_op = ALU_ADD;
        end

        default: ;
    endcase
end

endmodule
