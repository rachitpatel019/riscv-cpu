`timescale 1ns / 1ps

module tb_forwarding_unit;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [4:0] E1_rs1;
    logic [4:0] E1_rs2;
    logic E1_uses_rs2;
    logic E3_reg_write;
    logic [4:0] E3_rd;
    logic [31:0] E3_alu_result;
    logic M1_reg_write;
    logic [4:0] M1_rd;
    logic [31:0] M1_alu_result;
    logic M_reg_write;
    logic [4:0] M_rd;
    logic [31:0] M_alu_result;
    logic W_reg_write;
    logic [4:0] W_rd;
    logic [31:0] W_write_data;
    logic E1_forward_a;
    logic E1_forward_b;
    logic [31:0] E1_forward_a_data;
    logic [31:0] E1_forward_b_data;

    forwarding_unit dut (.*);

    task drive_fwd(
        input logic [4:0] i_rs1, input logic [4:0] i_rs2, input logic i_uses_rs2,
        input logic i_e3_en, input logic [4:0] i_e3_rd, input logic [31:0] i_e3_data,
        input logic i_m1_en, input logic [4:0] i_m1_rd, input logic [31:0] i_m1_data,
        input logic i_m_en, input logic [4:0] i_m_rd, input logic [31:0] i_m_data,
        input logic i_w_en, input logic [4:0] i_w_rd, input logic [31:0] i_w_data
    );
        E1_rs1 = i_rs1; E1_rs2 = i_rs2; E1_uses_rs2 = i_uses_rs2;
        E3_reg_write = i_e3_en; E3_rd = i_e3_rd; E3_alu_result = i_e3_data;
        M1_reg_write = i_m1_en; M1_rd = i_m1_rd; M1_alu_result = i_m1_data;
        M_reg_write = i_m_en; M_rd = i_m_rd; M_alu_result = i_m_data;
        W_reg_write = i_w_en; W_rd = i_w_rd; W_write_data = i_w_data;
        #1;
    endtask

    task check_fwd(input logic exp_a, input logic [31:0] exp_a_data, input logic exp_b, input logic [31:0] exp_b_data);
        if (E1_forward_a === exp_a && E1_forward_a_data === exp_a_data &&
            E1_forward_b === exp_b && E1_forward_b_data === exp_b_data) begin
            tests_passed++;
        end else begin
            tests_failed++;
            $error("MISMATCH: Time=%t, ExpA=%b (%h), ActA=%b (%h), ExpB=%b (%h), ActB=%b (%h)", 
                   $time, exp_a, exp_a_data, E1_forward_a, E1_forward_a_data, exp_b, exp_b_data, E1_forward_b, E1_forward_b_data);
        end
        tests_total++;
    endtask

    initial begin
        $display("--- Starting forwarding_unit Tests ---");

        // 1. Standard Forwarding Priority 1 (EX3)
        drive_fwd(5'd1, 5'd2, 1, 1, 5'd1, 32'hA, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(1, 32'hA, 0, 0);

        // 2. Priority Overlap (EX3 vs M1)
        drive_fwd(5'd1, 5'd2, 1, 1, 5'd1, 32'hA, 1, 5'd1, 32'hB, 0, 0, 0, 0, 0, 0); check_fwd(1, 32'hA, 0, 0);

        // 3. WB Stage Forwarding
        drive_fwd(5'd1, 5'd2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5'd1, 32'h1234_5678); check_fwd(1, 32'h1234_5678, 0, 0);

        // 4. Uses RS2 Filter
        drive_fwd(5'd1, 5'd2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5'd2, 32'h1234_5678); check_fwd(0, 0, 0, 0);

        // 5. R0 Exemption
        drive_fwd(5'd0, 5'd0, 1, 1, 5'd0, 32'hA, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(0, 0, 0, 0);

        $display("--- forwarding_unit Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
