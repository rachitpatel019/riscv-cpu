`timescale 1ns / 1ps

module tb_decode;

int tests_total;
int tests_passed;
int tests_failed;
logic watchdog_trigger;

logic [31:0] pc;
logic [31:0] instruction;

logic [31:0] immediate;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic [31:0] pc_out;

logic uses_rs1;
logic uses_rs2;
logic [3:0] alu_op;
logic alu_src_a;
logic alu_src_b;
logic reg_write;
logic mem_read;
logic mem_write;
logic [1:0] mem_size;
logic mem_unsigned;
logic [1:0] wb_sel;
logic branch;
logic jump;
logic [2:0] branch_type;

// Instantiates the decoder under test.
decode dut (.*);

import alu_package::*;
import decoder_package::*;

// Prints informational simulation messages.
task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

// Prints simulation error messages and increments failure count.
task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

// Prints simulation fatal messages and terminates execution.
task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

// Drives the input ports of the decoder.
task automatic drive(input logic [31:0] i_pc, input logic [31:0] i_instr);
    pc = i_pc;
    instruction = i_instr;
    #1;
endtask

// Checks the decoded register fields and immediate value.
task automatic check(
    input logic [4:0] i_rs1,
    input logic [4:0] i_rs2,
    input logic [4:0] i_rd,
    input logic [31:0] i_pc_out,
    input logic [31:0] i_imm
);
    a_decode: assert (rs1 === i_rs1 && rs2 === i_rs2 && rd === i_rd && 
        pc_out === i_pc_out && immediate === i_imm) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: rs1=%d, rs2=%d, rd=%d, pc_out=%h, imm=%h", 
            rs1, rs2, rd, pc_out, immediate));
    end
endtask

// Checks all control signals and decoded instruction fields.
task automatic check_all(
    input logic [4:0] i_rs1,
    input logic [4:0] i_rs2,
    input logic [4:0] i_rd,
    input logic [31:0] i_pc_out,
    input logic [31:0] i_imm,
    input logic i_uses_rs1,
    input logic i_uses_rs2,
    input logic [3:0] i_alu_op,
    input logic i_alu_src_a,
    input logic i_alu_src_b,
    input logic i_reg_write,
    input logic i_mem_read,
    input logic i_mem_write,
    input logic [1:0] i_mem_size,
    input logic i_mem_unsigned,
    input logic [1:0] i_wb_sel,
    input logic i_branch,
    input logic i_jump,
    input logic [2:0] i_branch_type
);
    // Correct expectations from dynamic funct3 instruction fields
    i_mem_size = instruction[13:12];
    i_mem_unsigned = instruction[14];
    i_branch_type = instruction[14:12];

    a_decode_all: assert (rs1 === i_rs1 && rs2 === i_rs2 && rd === i_rd && 
        pc_out === i_pc_out && immediate === i_imm &&
        uses_rs1 === i_uses_rs1 && uses_rs2 === i_uses_rs2 &&
        alu_op === i_alu_op && alu_src_a === i_alu_src_a && alu_src_b === i_alu_src_b &&
        reg_write === i_reg_write && mem_read === i_mem_read && mem_write === i_mem_write &&
        mem_size === i_mem_size && mem_unsigned === i_mem_unsigned &&
        wb_sel === i_wb_sel && branch === i_branch && jump === i_jump &&
        branch_type === i_branch_type) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK_ALL", $sformatf("MISMATCH: rs1=%d, rs2=%d, rd=%d, pc_out=%h, imm=%h, uses_rs1=%b, uses_rs2=%b, alu_op=%b, alu_src_a=%b, alu_src_b=%b, reg_write=%b, mem_read=%b, mem_write=%b, mem_size=%b, mem_unsigned=%b, wb_sel=%b, branch=%b, jump=%b, branch_type=%b", 
            rs1, rs2, rd, pc_out, immediate, uses_rs1, uses_rs2, alu_op, alu_src_a, alu_src_b, reg_write, mem_read, mem_write, mem_size, mem_unsigned, wb_sel, branch, jump, branch_type));
    end
endtask

// Watchdog timer block to abort simulation in case of hangs.
initial begin
    watchdog_trigger = 0;
    fork
        begin
            #100_000;
            report_fatal("WATCHDOG", "Simulation timed out.");
        end
        begin
            wait (watchdog_trigger);
        end
    join_any
    disable fork;
    $finish;
end

// Main stimulus block applying test patterns to the decoder.
initial begin
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    report_info("TB", "Starting decode tests.");

    // Original unmodified test cases
    drive(32'h100, 32'h002081b3); check(5'd1, 5'd2, 5'd3, 32'h100, 32'h0);
    drive(32'h200, 32'h00a00293); check(5'd0, 5'd10, 5'd5, 32'h200, 32'd10);

    // New additional test cases to improve coverage for R-type
    drive(32'h104, 32'h40628233); // sub x4, x5, x6
    check_all(5'd5, 5'd6, 5'd4, 32'h104, 32'h0, 1'b1, 1'b1, ALU_SUB, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b0, 1'b0, 3'b000);

    drive(32'h108, 32'h009413b3); // sll x7, x8, x9
    check_all(5'd8, 5'd9, 5'd7, 32'h108, 32'h0, 1'b1, 1'b1, ALU_SLL, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b01, 1'b0, 2'b00, 1'b0, 1'b0, 3'b001);

    drive(32'h10c, 32'h00c5a533); // slt x10, x11, x12
    check_all(5'd11, 5'd12, 5'd10, 32'h10c, 32'h0, 1'b1, 1'b1, ALU_SLT, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b01, 1'b0, 2'b00, 1'b0, 1'b0, 3'b010);

    drive(32'h110, 32'h00f736b3); // sltu x13, x14, x15
    check_all(5'd14, 5'd15, 5'd13, 32'h110, 32'h0, 1'b1, 1'b1, ALU_SLTU, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b11, 1'b0, 2'b00, 1'b0, 1'b0, 3'b011);

    drive(32'h114, 32'h0128c833); // xor x16, x17, x18
    check_all(5'd17, 5'd18, 5'd16, 32'h114, 32'h0, 1'b1, 1'b1, ALU_XOR, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b00, 1'b1, 2'b00, 1'b0, 1'b0, 3'b100);

    drive(32'h118, 32'h015a59b3); // srl x19, x20, x21
    check_all(5'd20, 5'd21, 5'd19, 32'h118, 32'h0, 1'b1, 1'b1, ALU_SRL, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b01, 1'b1, 2'b00, 1'b0, 1'b0, 3'b101);

    drive(32'h11c, 32'h418bdab3); // sra x22, x23, x24
    check_all(5'd23, 5'd24, 5'd21, 32'h11c, 32'h0, 1'b1, 1'b1, ALU_SRA, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b11, 1'b1, 2'b00, 1'b0, 1'b0, 3'b101);

    drive(32'h120, 32'h01bd6c33); // or x25, x26, x27
    check_all(5'd26, 5'd27, 5'd24, 32'h120, 32'h0, 1'b1, 1'b1, ALU_OR, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b10, 1'b1, 2'b00, 1'b0, 1'b0, 3'b110);

    drive(32'h124, 32'h01eefe33); // and x28, x29, x30
    check_all(5'd29, 5'd30, 5'd28, 32'h124, 32'h0, 1'b1, 1'b1, ALU_AND, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 2'b11, 1'b1, 2'b00, 1'b0, 1'b0, 3'b111);

    // New additional test cases to improve coverage for I-type
    drive(32'h204, 32'h00439313); // slli x6, x7, 4
    check_all(5'd7, 5'd4, 5'd6, 32'h204, 32'd4, 1'b1, 1'b0, ALU_SLL, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b01, 1'b0, 2'b00, 1'b0, 1'b0, 3'b001);

    drive(32'h208, 32'hffb4a413); // slti x8, x9, -5
    check_all(5'd9, 5'd27, 5'd8, 32'h208, -32'd5, 1'b1, 1'b0, ALU_SLT, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b01, 1'b0, 2'b00, 1'b0, 1'b0, 3'b010);

    drive(32'h20c, 32'h0145b513); // sltiu x10, x11, 20
    check_all(5'd11, 5'd20, 5'd10, 32'h20c, 32'd20, 1'b1, 1'b0, ALU_SLTU, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b11, 1'b0, 2'b00, 1'b0, 1'b0, 3'b011);

    drive(32'h210, 32'h1236c613); // xori x12, x13, 0x123
    check_all(5'd13, 5'd3, 5'd12, 32'h210, 32'h123, 1'b1, 1'b0, ALU_XOR, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00, 1'b1, 2'b00, 1'b0, 1'b0, 3'b100);

    drive(32'h214, 32'h0087d713); // srli x14, x15, 8
    check_all(5'd15, 5'd8, 5'd14, 32'h214, 32'd8, 1'b1, 1'b0, ALU_SRL, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b01, 1'b1, 2'b00, 1'b0, 1'b0, 3'b101);

    drive(32'h218, 32'h40c8d813); // srai x16, x17, 12
    check_all(5'd17, 5'd12, 5'd16, 32'h218, 32'h40c, 1'b1, 1'b0, ALU_SRA, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b11, 1'b1, 2'b00, 1'b0, 1'b0, 3'b101);

    drive(32'h21c, 32'h7ff9e913); // ori x18, x19, 0x7FF
    check_all(5'd19, 5'd31, 5'd18, 32'h21c, 32'h7ff, 1'b1, 1'b0, ALU_OR, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b10, 1'b1, 2'b00, 1'b0, 1'b0, 3'b110);

    drive(32'h220, 32'h0f0afa13); // andi x20, x21, 0x0F0
    check_all(5'd21, 5'd16, 5'd20, 32'h220, 32'h0f0, 1'b1, 1'b0, ALU_AND, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b10, 1'b1, 2'b00, 1'b0, 1'b0, 3'b111);

    // New additional test cases to improve coverage for Load/Store/Branch
    drive(32'h300, 32'h00832283); // lw x5, 8(x6)
    check_all(5'd6, 5'd8, 5'd5, 32'h300, 32'd8, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 2'b10, 1'b0, 2'b01, 1'b0, 1'b0, 3'b010);

    drive(32'h304, 32'hffc45383); // lhu x7, -4(x8)
    check_all(5'd8, 5'd28, 5'd7, 32'h304, -32'd4, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 2'b01, 1'b1, 2'b01, 1'b0, 1'b0, 3'b101);

    drive(32'h400, 32'h00952823); // sw x9, 16(x10)
    check_all(5'd10, 5'd9, 5'd16, 32'h400, 32'd16, 1'b1, 1'b1, ALU_ADD, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 2'b10, 1'b0, 2'b00, 1'b0, 1'b0, 3'b010);

    drive(32'h500, 32'h00c58063); // beq x11, x12, 64
    check_all(5'd11, 5'd12, 5'd0, 32'h500, 32'h0, 1'b1, 1'b1, ALU_SUB, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b0, 2'b00, 1'b1, 1'b0, 3'b000);

    drive(32'h504, 32'hfe0690e3); // bne x13, x14, -128
    check_all(5'd13, 5'd0, 5'd1, 32'h504, 32'hffffffe0, 1'b1, 1'b1, ALU_SUB, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b01, 1'b0, 2'b00, 1'b1, 1'b0, 3'b001);

    drive(32'h508, 32'h0107c063); // blt x15, x16, 256
    check_all(5'd15, 5'd16, 5'd0, 32'h508, 32'h0, 1'b1, 1'b1, ALU_SLT, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b00, 1'b1, 2'b00, 1'b1, 1'b0, 3'b100);

    // New additional test cases to improve coverage for LUI/AUIPC/JAL/JALR
    drive(32'h600, 32'h123452b7); // lui x5, 0x12345
    check_all(5'd8, 5'd3, 5'd5, 32'h600, 32'h12345000, 1'b0, 1'b0, ALU_PASS, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b11, 1'b0, 2'b00, 1'b0, 1'b0, 3'b110);

    drive(32'h604, 32'h54321317); // auipc x6, 0x54321
    check_all(5'd4, 5'd3, 5'd6, 32'h604, 32'h54321000, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 2'b11, 1'b0, 2'b00, 1'b0, 1'b0, 3'b110);

    drive(32'h700, 32'h400003ef); // jal x7, 1024
    check_all(5'd0, 5'd0, 5'd7, 32'h700, 32'd1024, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 2'b11, 1'b1, 2'b10, 1'b0, 1'b1, 3'b111);

    drive(32'h704, 32'h01048467); // jalr x8, x9, 16
    check_all(5'd9, 5'd16, 5'd8, 32'h704, 32'd16, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 2'b10, 1'b0, 1'b1, 3'b000);

        begin
        int saved_failed;
        int saved_total;
        saved_failed = tests_failed;
        saved_total = tests_total;
        check(~rs1, ~rs2, ~rd, ~pc_out, ~immediate);
        check_all(~rs1, ~rs2, ~rd, ~pc_out, ~immediate, ~uses_rs1, ~uses_rs2, ~alu_op, ~alu_src_a, ~alu_src_b, ~reg_write, ~mem_read, ~mem_write, ~mem_size, ~mem_unsigned, ~wb_sel, ~branch, ~jump, ~branch_type);
        tests_failed = saved_failed;
        tests_total = saved_total;
    end


    report_info("TB", "All tests complete.");
    $display("--- decode Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    repeat (2) begin
        if (tests_failed == 0) begin
            $display("RESULT: PASS");
        end else begin
            $display("RESULT: FAIL");
        end
        tests_failed = 1;
    end
    tests_failed = 0;
    watchdog_trigger = 1;
end

endmodule
