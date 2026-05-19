`timescale 1ns / 1ps

module decode_tb;
    import decoder_package::*;
    import alu_package::*;

    // Port Signals
    logic clk;
    logic [31:0] pc;
    logic [31:0] instruction;
    logic reg_write_wb;
    logic [4:0] rd_wb;
    logic [31:0] write_data_wb;

    logic [31:0] rs1_data, rs2_data, immediate;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] pc_out;
    logic uses_rs2;
    logic [3:0] alu_op;
    logic alu_src_a, alu_src_b;
    logic reg_write, mem_read, mem_write;
    logic [1:0] mem_size;
    logic mem_unsigned;
    logic [1:0] wb_sel;
    logic branch, jump;
    logic [2:0] branch_type;

    // Instantiate DUT
    decode dut (
        .clk(clk),
        .pc(pc),
        .instruction(instruction),
        .reg_write_wb(reg_write_wb),
        .rd_wb(rd_wb),
        .write_data_wb(write_data_wb),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .immediate(immediate),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .pc_out(pc_out),
        .uses_rs2(uses_rs2),
        .alu_op(alu_op),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned),
        .wb_sel(wb_sel),
        .branch(branch),
        .jump(jump),
        .branch_type(branch_type)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test Variables
    int tests_passed = 0;
    int total_tests = 0;

    // Task for checking results
    task check_ctrl(input string msg, input logic exp_reg_write, input logic exp_mem_read, input logic exp_mem_write);
        total_tests++;
        if (reg_write === exp_reg_write && mem_read === exp_mem_read && mem_write === exp_mem_write) begin
            $display("[PASS] %s: Ctrl signals OK", msg);
            tests_passed++;
        end else begin
            $display("[FAIL] %s: Ctrl signals mismatch. Got R: %b, MR: %b, MW: %b", msg, reg_write, mem_read, mem_write);
        end
    endtask

    initial begin
        $display("Starting Decode Stage Testbench...");

        // Initialize
        pc = 32'h0000_1000;
        reg_write_wb = 0;
        rd_wb = 0;
        write_data_wb = 0;

        // Pre-load registers using WB interface
        // Write 0xDEADBEEF to x2
        @(posedge clk);
        reg_write_wb = 1;
        rd_wb = 2;
        write_data_wb = 32'hDEADBEEF;
        @(posedge clk);
        // Write 0xCAFEBABE to x3
        rd_wb = 3;
        write_data_wb = 32'hCAFEBABE;
        @(posedge clk);
        reg_write_wb = 0;

        // --- Test R-type: ADD x1, x2, x3 ---
        // opcode=0110011, f3=000, f7=0000000, rd=1, rs1=2, rs2=3
        instruction = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011};
        #1;
        check_ctrl("ADD x1, x2, x3", 1, 0, 0);
        if (rs1_data === 32'hDEADBEEF && rs2_data === 32'hCAFEBABE) begin
            $display("[PASS] Register data read OK");
            tests_passed++;
        end else begin
            $display("[FAIL] Register data mismatch. rs1: 0x%h, rs2: 0x%h", rs1_data, rs2_data);
        end
        total_tests++;

        // --- Test I-type: ADDI x4, x2, 123 ---
        // opcode=0010011, f3=000, rd=4, rs1=2, imm=123
        instruction = {12'd123, 5'd2, 3'b000, 5'd4, 7'b0010011};
        #1;
        check_ctrl("ADDI x4, x2, 123", 1, 0, 0);
        if (immediate === 32'd123) begin
            $display("[PASS] Immediate OK");
            tests_passed++;
        end else begin
            $display("[FAIL] Immediate mismatch. Got 0x%h", immediate);
        end
        total_tests++;

        // --- Test Load: LW x6, 4(x2) ---
        // opcode=0000011, f3=010 (Word), rd=6, rs1=2, imm=4
        instruction = {12'd4, 5'd2, 3'b010, 5'd6, 7'b0000011};
        #1;
        check_ctrl("LW x6, 4(x2)", 1, 1, 0);
        if (wb_sel === 2'b01) begin // Select memory data
            $display("[PASS] wb_sel OK for LW");
            tests_passed++;
        end else begin
            $display("[FAIL] wb_sel mismatch for LW: %b", wb_sel);
        end
        total_tests++;

        // --- Test Store: SW x8, 8(x2) ---
        // opcode=0100011, f3=010, rs1=2, rs2=8, imm=8
        instruction = {7'b0000000, 5'd8, 5'd2, 3'b010, 5'b01000, 7'b0100011}; // imm[11:5], rs2, rs1, f3, imm[4:0], opcode
        #1;
        check_ctrl("SW x8, 8(x2)", 0, 0, 1);

        // Generate Summary
        $display("\nDecode Stage Test Summary: %0d/%0d tests passed", tests_passed, total_tests);
        if (tests_passed == total_tests) $display("SUCCESS: All tests passed!");
        else $display("FAILURE: Some tests failed.");
        
        $finish;
    end

endmodule
