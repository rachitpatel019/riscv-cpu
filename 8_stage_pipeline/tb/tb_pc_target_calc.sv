`timescale 1ns / 1ps

module tb_pc_target_calc;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [31:0] pc;
    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic branch;
    logic jump;
    logic [2:0] branch_type;
    logic [31:0] imm;
    logic [31:0] alu_result;
    
    // New ports
    logic        condition_met_in;
    logic [31:0] branch_target_in;

    logic pc_sel;
    logic [31:0] pc_target;

    pc_target_calc dut (.*);

    task drive_pc_calc(
        input logic [31:0] i_pc, input logic [31:0] i_op_a, input logic [31:0] i_op_b,
        input logic i_branch, input logic i_jump, input logic [2:0] i_br_type,
        input logic [31:0] i_imm, input logic [31:0] i_alu_res
    );
        pc = i_pc; operand_a = i_op_a; operand_b = i_op_b;
        branch = i_branch; jump = i_jump; branch_type = i_br_type;
        imm = i_imm; alu_result = i_alu_res;
        
        // Emulate Stage 8 logic
        case (i_br_type)
            3'b000: condition_met_in = i_op_a == i_op_b;
            3'b001: condition_met_in = i_op_a != i_op_b;
            3'b100: condition_met_in = $signed(i_op_a) < $signed(i_op_b);
            3'b101: condition_met_in = $signed(i_op_a) >= $signed(i_op_b);
            3'b110: condition_met_in = i_op_a < i_op_b;
            3'b111: condition_met_in = i_op_a >= i_op_b;
            default: condition_met_in = 0;
        endcase
        branch_target_in = i_pc + i_imm;

        #1;
    endtask

    task check_pc_calc(input logic exp_sel, input logic [31:0] exp_target);
        if (pc_sel === exp_sel && pc_target === exp_target) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, ExpSel=%b, ActSel=%b, ExpTarget=%h, ActTarget=%h", 
                   $time, exp_sel, pc_sel, exp_target, pc_target);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting pc_target_calc Tests ---");

        // 1. BEQ True
        drive_pc_calc(32'h100, 32'h5, 32'h5, 1, 0, 3'b000, 32'h8, 0); check_pc_calc(1, 32'h108);
        // 2. BEQ False
        drive_pc_calc(32'h100, 32'h5, 32'h6, 1, 0, 3'b000, 32'h8, 0); check_pc_calc(0, 32'h0);

        // 3. Jump (JAL)
        drive_pc_calc(32'h100, 0, 0, 0, 1, 0, 0, 32'h200); check_pc_calc(1, 32'h200);

        // 4. Target Priority (jump should win)
        drive_pc_calc(32'h100, 32'h5, 32'h5, 1, 1, 3'b000, 32'h8, 32'h200); check_pc_calc(1, 32'h200);

        // 5. Negative Offsets
        drive_pc_calc(32'h100, 32'h5, 32'h5, 1, 0, 3'b000, 32'hFFFFFFF8, 0); check_pc_calc(1, 32'hF8);

        $display("--- pc_target_calc Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule