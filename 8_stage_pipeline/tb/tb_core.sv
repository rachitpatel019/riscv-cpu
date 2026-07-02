`timescale 1ns / 1ps

module tb_core;
int tests_total;
int tests_passed;
int tests_failed;

int cycle_count;
int cycles_run;
int errors_found;

localparam MAX_CYCLES = 500;
localparam CLK_PERIOD = 10;

logic clk;
logic reset;

always #(CLK_PERIOD / 2) clk = ~clk;

wire [31:0] probe_fetch_pc = dut.F_pc;
wire [31:0] probe_alu_result = dut.E2_alu_result;
wire probe_mem_read = dut.E3_mem_read;
wire [31:0] probe_wb_data = dut.W_write_data;
wire [4:0] probe_wb_reg = dut.W_rd;
wire probe_reg_write = dut.W_reg_write;

typedef struct {
    logic [31:0] expected_fetch_pc;
    logic [31:0] expected_alu_result;
    logic expected_mem_read;
    logic [31:0] expected_wb_data;
    logic [4:0] expected_wb_reg;
    logic expected_reg_write;
} cycle_state_t;

cycle_state_t expected_states [0:MAX_CYCLES];

logic [1:0] tb_mmio_keys = 2'b11;
logic [9:0] tb_mmio_switches = 10'b1010101010;
logic [9:0] tb_mmio_leds;
logic [23:0] tb_mmio_hex;

core dut (
    .clk(clk),
    .reset(reset),
    .mmio_keys(tb_mmio_keys),
    .mmio_switches(tb_mmio_switches),
    .mmio_leds(tb_mmio_leds),
    .mmio_hex(tb_mmio_hex),
    .out_pc(),
    .out_writeback_data(),
    .out_reg_write(),
    .out_alu_result()
);

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

task automatic reset_dut();
    reset = 1;
    repeat (2) @(posedge clk);
    #1;
    reset = 0;
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
    cycle_count = 0;
    cycles_run = 0;
    errors_found = 0;
    report_info("TB", "Starting core tests.");

    for (int i = 0; i <= MAX_CYCLES; i++) begin
        expected_states[i] = '{
            expected_fetch_pc: i * 4,
            expected_alu_result: 32'h0,
            expected_mem_read: 1'b0,
            expected_wb_data: 32'h0,
            expected_wb_reg: 5'h0,
            expected_reg_write: 1'b0
        };
    end

    expected_states[5].expected_alu_result = 32'h1;
    expected_states[7].expected_wb_data = 32'h1;
    expected_states[7].expected_wb_reg = 5'd1;
    expected_states[7].expected_reg_write = 1'b1;

    expected_states[10].expected_alu_result = 32'h2;
    expected_states[12].expected_wb_data = 32'h2;
    expected_states[12].expected_wb_reg = 5'd2;
    expected_states[12].expected_reg_write = 1'b1;

    expected_states[15].expected_alu_result = 32'h3;
    expected_states[17].expected_wb_data = 32'h3;
    expected_states[17].expected_wb_reg = 5'd3;
    expected_states[17].expected_reg_write = 1'b1;

    for (int i = 0; i <= MAX_CYCLES; i++) begin
        if (i < 43)
            expected_states[i].expected_fetch_pc = i * 4;
        else
            expected_states[i].expected_fetch_pc = 32'hffffffff;
    end

    reset_dut();

    fork
        begin
            repeat (MAX_CYCLES) @(posedge clk);
            report_info("TB", $sformatf("Simulation Timeout (PC at end: %h)", dut.W_pc));
        end
        begin
            wait (cycles_run > 50);
            forever begin
                @(posedge clk);
                if (dut.W_pc == 32'h000000fc) break; 
            end
            report_info("TB", $sformatf("Program Completion Detected (PC: %h)", dut.W_pc));
        end
    join_any

    if (errors_found == 0) begin
        tests_passed = 1;
        tests_total = 1;
        tests_failed = 0;
    end else begin
        tests_passed = 0;
        tests_failed = errors_found;
        tests_total = errors_found;
    end

    report_info("TB", "All tests complete.");
    $display("--- core Test Summary ---");
    $display("Total: %0d | Passed: %0d | Failed: %0d", tests_total, tests_passed, tests_failed);
    if (tests_failed == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $finish;
end

always @(negedge clk) begin
    if (!reset) begin
        cycle_count++;
        cycles_run++;
    end
end
endmodule
