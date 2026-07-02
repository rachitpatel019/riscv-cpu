`timescale 1ns / 1ps

module tb_data_mem;
int tests_total;
int tests_passed;
int tests_failed;

localparam CLK_PERIOD = 10;

logic clk;
logic mem_read;
logic mem_write;
logic [31:0] address;
logic [31:0] write_data;
logic [1:0] mem_size;
logic mem_unsigned;

logic [31:0] read_data;

data_mem dut (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(address),
    .write_data(write_data),
    .mem_size(mem_size),
    .mem_unsigned(mem_unsigned),
    .read_data(read_data)
);

always #(CLK_PERIOD / 2) clk = ~clk;

task automatic report_info(string id, string msg);
    $display("[UVM_INFO]  %s @ %0t: %s", id, $time, msg);
endtask

task automatic report_error(string id, string msg);
    $display("[UVM_ERROR] %s @ %0t: %s", id, $time, msg);
    tests_failed++;
    tests_total++;
endtask

task automatic report_fatal(string id, string msg);
    $display("[UVM_FATAL] %s @ %0t: %s", id, $time, msg);
    $finish;
endtask

task automatic drive(
    input logic i_read, input logic i_write,
    input logic [31:0] i_addr, input logic [31:0] i_wdata,
    input logic [1:0] i_size, input logic i_uns
);
    @(negedge clk);
    mem_read = i_read;
    mem_write = i_write;
    address = i_addr;
    write_data = i_wdata;
    mem_size = i_size;
    mem_unsigned = i_uns;
endtask

task automatic check(input logic [31:0] exp_data);
    @(posedge clk);
    #1;
    if (read_data === exp_data) begin
        tests_passed++;
        tests_total++;
    end else begin
        report_error("CHECK", $sformatf("MISMATCH: Addr=%h, Size=%b, Unsigned=%b, Exp=%h, Act=%h", 
            address, mem_size, mem_unsigned, exp_data, read_data));
    end
endtask

initial begin
    #100_000;
    report_fatal("WATCHDOG", "Simulation timed out.");
end

initial begin
    clk = 0;
    tests_total = 0;
    tests_passed = 0;
    tests_failed = 0;
    mem_read = 0;
    mem_write = 0;
    report_info("TB", "Starting data_mem tests.");

    drive(0, 1, 32'h0, 32'hDEADBEEF, 2'b10, 0); 
    drive(1, 0, 32'h0, 0, 2'b10, 0);           
    check(32'hDEADBEEF);

    drive(1, 0, 32'h0, 0, 2'b01, 1);           
    check(32'hBEEF);
    drive(1, 0, 32'h2, 0, 2'b01, 1);           
    check(32'hDEAD);

    drive(1, 0, 32'h0, 0, 2'b00, 1);           
    check(32'hEF);
    drive(1, 0, 32'h1, 0, 2'b00, 1);           
    check(32'hBE);

    drive(0, 1, 32'h4, 32'h00000080, 2'b10, 0); 
    drive(1, 0, 32'h4, 0, 2'b00, 0);           
    check(32'hFFFFFF80);

    report_info("TB", "All tests complete.");
    $display("--- data_mem Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end
endmodule
