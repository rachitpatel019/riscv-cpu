`timescale 1ns / 1ps

module tb_forwarding_unit;
    int tests_total = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    logic [4:0] E1_rs1;
    logic [4:0] E1_rs2;
    logic E1_uses_rs1;
    logic E1_uses_rs2;
    
    logic E2_reg_write;
    logic E2_mem_read;
    logic [4:0] E2_rd;
    logic [31:0] E2_forward_data;
    
    logic E3_reg_write;
    logic E3_mem_read;
    logic [4:0] E3_rd;
    logic [31:0] E3_forward_data;
    
    logic M1_reg_write;
    logic M1_mem_read;
    logic [4:0] M1_rd;
    logic [31:0] M1_forward_data;
    
    logic M_reg_write;
    logic [4:0] M_rd;
    logic [31:0] M_forward_data;
    
    logic W_reg_write;
    logic [4:0] W_rd;
    logic [31:0] W_write_data;
    
    logic E1_forward_a;
    logic E1_forward_b;
    logic [31:0] E1_forward_a_data;
    logic [31:0] E1_forward_b_data;

    forwarding_unit dut (.*);

    task drive_fwd(
        input logic [4:0] i_rs1, input logic [4:0] i_rs2, 
        input logic i_uses_rs1, input logic i_uses_rs2,
        input logic i_e2_en, input logic i_e2_read, input logic [4:0] i_e2_rd, input logic [31:0] i_e2_data,
        input logic i_e3_en, input logic i_e3_read, input logic [4:0] i_e3_rd, input logic [31:0] i_e3_data,
        input logic i_m1_en, input logic i_m1_read, input logic [4:0] i_m1_rd, input logic [31:0] i_m1_data,
        input logic i_m_en,  input logic [4:0] i_m_rd,  input logic [31:0] i_m_data,
        input logic i_w_en,  input logic [4:0] i_w_rd,  input logic [31:0] i_w_data
    );
        E1_rs1 = i_rs1; E1_rs2 = i_rs2; 
        E1_uses_rs1 = i_uses_rs1; E1_uses_rs2 = i_uses_rs2;
        E2_reg_write = i_e2_en; E2_mem_read = i_e2_read; E2_rd = i_e2_rd; E2_forward_data = i_e2_data;
        E3_reg_write = i_e3_en; E3_mem_read = i_e3_read; E3_rd = i_e3_rd; E3_forward_data = i_e3_data;
        M1_reg_write = i_m1_en; M1_mem_read = i_m1_read; M1_rd = i_m1_rd; M1_forward_data = i_m1_data;
        M_reg_write = i_m_en;   M_rd = i_m_rd;   M_forward_data = i_m_data;
        W_reg_write = i_w_en;   W_rd = i_w_rd;   W_write_data = i_w_data;
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

        // 1. Priority 1 (EX2)
        // drive_fwd(rs1, rs2, uses1, uses2, e2_en, e2_rd, e2_rd_addr, e2_data, ...)
        drive_fwd(5'd1, 5'd2, 1, 1, 1, 0, 5'd1, 32'hE2, 1, 0, 5'd1, 32'hE3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(1, 32'hE2, 0, 0);

        // 2. Priority 2 (EX3)
        drive_fwd(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 1, 0, 5'd1, 32'hE3, 1, 0, 5'd1, 32'hA1, 0, 0, 0, 0, 0, 0); check_fwd(1, 32'hE3, 0, 0);

        // 3. Stage 11 (M) Forwarding
        drive_fwd(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5'd2, 32'hBA, 0, 0, 0); check_fwd(0, 0, 1, 32'hBA);

        // 4. WB Stage Forwarding
        drive_fwd(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 5'd1, 32'hBD); check_fwd(1, 32'hBD, 0, 0);

        // 5. R0 Exemption
        drive_fwd(5'd0, 5'd0, 1, 1, 1, 0, 5'd0, 32'hE2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(0, 0, 0, 0);

        // 6. Uses RS1/RS2 Filter
        drive_fwd(5'd1, 5'd2, 0, 0, 1, 0, 5'd1, 32'hE2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(0, 0, 0, 0);

        // 7. Mem Read Blocking (fragile load-use check)
        drive_fwd(5'd1, 5'd2, 1, 1, 1, 1, 5'd1, 32'hBAD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(0, 0, 0, 0);
        drive_fwd(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 1, 1, 5'd1, 32'hBAD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); check_fwd(0, 0, 0, 0);
        drive_fwd(5'd1, 5'd2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 5'd1, 32'hBAD, 0, 0, 0, 0, 0, 0); check_fwd(0, 0, 0, 0);

        $display("--- forwarding_unit Test Summary ---");
        $display("Total Tests: %d", tests_total);
        $display("Passed: %d", tests_passed);
        $display("Failed: %d", tests_failed);
        if (tests_failed == 0) $display("RESULT: PASS");
        else $display("RESULT: FAIL");
        $finish;
    end
endmodule
