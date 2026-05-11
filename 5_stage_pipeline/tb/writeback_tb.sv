`timescale 1ns/1ps

module writeback_tb;

// DUT Signals
logic [31:0] pc;
logic [31:0] alu_result;
logic [31:0] read_data;
logic [1:0] wb_sel;

logic [31:0] write_data;

// Instantiate DUT with explicit port connections
writeback dut (
    .pc(pc),
    .alu_result(alu_result),
    .read_data(read_data),
    .wb_sel(wb_sel),
    .write_data(write_data)
);

// Test tracking
int test_count = 0;
int fail_count = 0;

task run_test(
    input logic [31:0] pc_in,
    input logic [31:0] alu_in,
    input logic [31:0] mem_in,
    input logic [1:0] sel,
    input logic [31:0] expected
);
begin
    test_count++;

    pc         = pc_in;
    alu_result = alu_in;
    read_data  = mem_in;
    wb_sel     = sel;

    #1; // allow combinational logic to settle

    if (write_data !== expected) begin
        $display("Test %0d FAILED", test_count);
        $display("  pc=0x%08h alu_result=0x%08h read_data=0x%08h wb_sel=%0b", pc_in, alu_in, mem_in, sel);
        $display("  Expected=0x%08h, Got=0x%08h\n", expected, write_data);
        fail_count++;
    end else begin
        $display("Test %0d PASSED", test_count);
    end
end
endtask

// Test Cases
initial begin
    // ALU path (wb_sel = 2'b00)
    run_test(32'h0000_0000, 10, 100, 2'b00, 32'h0000_000A);
    run_test(32'h0000_0010, 32'hFFFFFFFF, 123, 2'b00, 32'hFFFFFFFF);

    // Memory path (wb_sel = 2'b01)
    run_test(32'h0000_0020, 10, 32'h1234_5678, 2'b01, 32'h1234_5678);
    run_test(32'h0000_0030, 32'hABCDEF01, 32'h8000_0000, 2'b01, 32'h8000_0000);

    // PC+4 path (wb_sel = 2'b10)
    run_test(32'h0000_0040, 32'h1111_1111, 32'h2222_2222, 2'b10, 32'h0000_0044);
    run_test(32'hFFFF_FFFC, 32'hDEAD_BEEF, 32'hCAFE_BABE, 2'b10, 32'h0000_0000); // wrap-around example

    // Default fallback path (wb_sel = 2'b11) should behave like ALU result
    run_test(32'h0000_0050, 32'h0000_00FF, 32'h0000_FF00, 2'b11, 32'h0000_00FF);

    // Edge Cases
    run_test(32'h0000_0060, 32'h0000_0000, 32'h0000_0000, 2'b00, 32'h0000_0000);
    run_test(32'h0000_0070, 32'h0000_0001, 32'h0000_0002, 2'b01, 32'h0000_0002);

    // Testing report
    $display("Tests run: %0d, Failures: %0d", test_count, fail_count);
    $finish;
end

endmodule