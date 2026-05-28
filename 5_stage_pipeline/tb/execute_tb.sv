`timescale 1ns / 1ps

module execute_tb;
    import alu_package::*;

    // Port Signals
    logic [31:0] pc;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;
    logic alu_src_a;
    logic alu_src_b;
    logic [3:0] alu_op;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic reg_write;
    logic branch;
    logic jump;
    logic [2:0] branch_type;
    logic forward_a;
    logic forward_b;
    logic [31:0] forward_a_data;
    logic [31:0] forward_b_data;

    logic [31:0] alu_result;
    logic pc_sel;
    logic [31:0] pc_target;
    logic [4:0] rd_out;
    logic reg_write_out;
    logic [4:0] rs1_out;
    logic [4:0] rs2_out;
    logic [31:0] rs2_data_out;

    // Instantiate DUT
    execute dut (
        .pc(pc),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm(imm),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_op(alu_op),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .reg_write(reg_write),
        .branch(branch),
        .jump(jump),
        .branch_type(branch_type),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_a_data(forward_a_data),
        .forward_b_data(forward_b_data),
        .alu_result(alu_result),
        .pc_sel(pc_sel),
        .pc_target(pc_target),
        .rd_out(rd_out),
        .reg_write_out(reg_write_out),
        .rs1_out(rs1_out),
        .rs2_out(rs2_out),
        .rs2_data_out(rs2_data_out)
    );

    // Test Variables
    int tests_passed = 0;
    int total_tests = 0;

    // Task for checking results
    task check_alu(input [31:0] expected, input string msg);
        total_tests++;
        if (alu_result === expected) begin
            $display("[PASS] %s: ALU Result = 0x%h", msg, alu_result);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Expected 0x%h, Got 0x%h", msg, expected, alu_result);
        end
    endtask

    initial begin
        $display("Starting Execute Stage Testbench...");
        $display("Architecture: 8-stage pipeline (Execute module remains combinational)");

        // Initialize
        pc = 32'h0000_1000;
        rs1_data = 32'h0000_000A; // 10
        rs2_data = 32'h0000_0005; // 5
        imm = 32'h0000_0020;      // 32
        alu_src_a = 0; // Use rs1
        alu_src_b = 0; // Use rs2
        alu_op = ALU_ADD;
        rs1 = 1; rs2 = 2; rd = 3;
        reg_write = 1;
        branch = 0; jump = 0; branch_type = 0;
        forward_a = 0; forward_b = 0;
        forward_a_data = 0; forward_b_data = 0;

        #1;
        // --- Test ADD ---
        check_alu(32'd15, "ADD 10 + 5");

        // --- Test SUB ---
        alu_op = ALU_SUB;
        #1;
        check_alu(32'd5, "SUB 10 - 5");

        // --- Test ADDI (using imm) ---
        alu_op = ALU_ADD;
        alu_src_b = 1; // Use imm
        #1;
        check_alu(32'd42, "ADDI 10 + 32");

        // --- Test Forwarding A ---
        alu_src_b = 0; // Use rs2
        forward_a = 1;
        forward_a_data = 32'd100;
        #1;
        check_alu(32'd105, "Forward A (100) + rs2 (5)");

        // --- Test Forwarding B ---
        forward_a = 0;
        forward_b = 1;
        forward_b_data = 32'd200;
        #1;
        check_alu(32'd210, "rs1 (10) + Forward B (200)");

        // --- Test Branch PC Target ---
        branch = 1;
        branch_type = 3'b000; // BEQ
        imm = 32'h0000_0010; // offset 16
        rs1_data = 32'd10;
        rs2_data = 32'd10;
        forward_a = 0; forward_b = 0;
        #1;
        total_tests++;
        if (pc_sel === 1 && pc_target === 32'h0000_1010) begin
            $display("[PASS] BEQ Taken: PC target OK");
            tests_passed++;
        end else begin
            $display("[FAIL] BEQ Taken: pc_sel=%b, pc_target=0x%h", pc_sel, pc_target);
        end

        // --- Test Jump (JAL) ---
        branch = 0;
        jump = 1;
        imm = 32'h0000_0040;
        alu_src_a = 1; // pc
        alu_src_b = 1; // imm
        forward_a = 0;
        forward_b = 0;
        #1;
        total_tests++;
        if (pc_sel === 1 && pc_target === 32'h0000_1040) begin
            $display("[PASS] JAL: PC target OK");
            tests_passed++;
        end else begin
            $display("[FAIL] JAL: pc_sel=%b, pc_target=0x%h", pc_sel, pc_target);
        end

        // Generate Summary
        $display("\nExecute Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
