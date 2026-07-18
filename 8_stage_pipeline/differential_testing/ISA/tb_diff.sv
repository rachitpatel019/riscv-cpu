`timescale 1ns / 1ps

module tb_diff;

/*
Timing parameters and clock generation control signal.
*/
localparam CLK_PERIOD = 10;
localparam MAX_CYCLES = 100000;

logic clk;
logic reset;

always #(CLK_PERIOD / 2) clk = ~clk;

/*
Mock peripheral inputs and outputs for board interconnect simulation.
*/
logic [1:0] tb_mmio_keys = 2'b11;
logic [9:0] tb_mmio_switches = 10'b0;

logic [9:0] tb_mmio_leds;
logic [23:0] tb_mmio_hex;

/*
Instantiation of the RISC-V CPU core.
*/
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

/*
Simulation boundary and verification properties parsed via command line arguments.
*/
logic [31:0] sig_begin;
logic [31:0] sig_end;
logic [31:0] tohost_addr;

/*
Logging outputs and simulation watchdog cycle counters.
*/
integer trace_file;
integer sig_file;
integer cycle_count = 0;

/*
Initialization routine parsing test configuration and handling CPU reset sequence.
*/
initial begin
    clk = 0;
    if (!$value$plusargs("SIGNATURE_BEGIN=%h", sig_begin)) begin
        $display("[ERROR] SIGNATURE_BEGIN plusarg missing!");
        $finish;
    end
    if (!$value$plusargs("SIGNATURE_END=%h", sig_end)) begin
        $display("[ERROR] SIGNATURE_END plusarg missing!");
        $finish;
    end
    if (!$value$plusargs("TOHOST_ADDR=%h", tohost_addr)) begin
        $display("[ERROR] TOHOST_ADDR plusarg missing!");
        $finish;
    end
    trace_file = $fopen("rtl_trace.txt", "w");
    if (trace_file == 0) begin
        $display("[ERROR] Could not open rtl_trace.txt for writing!");
        $finish;
    end
    force dut.stage1_fetch.pc = 32'h80000000;
    reset = 1;
    repeat (5) @(posedge clk);
    #1;
    release dut.stage1_fetch.pc;
    reset = 0;
end

/*
Watchdog cycle counting and trace logging of committed CPU instructions.
*/
always @(negedge clk) begin
    if (!reset) begin
        cycle_count <= cycle_count + 1;
        if (dut.W_reg_write && dut.W_rd != 0) begin
            $fwrite(trace_file, "core   0: 3 0x%08h (0x00000000) x%0d 0x%08h\n", dut.W_pc, dut.W_rd, dut.W_write_data);
        end
        if (cycle_count >= MAX_CYCLES) begin
            $display("[ERROR] Simulation Timeout reached!");
            $fclose(trace_file);
            $finish;
        end
    end
end

/*
Temporary address pointer for signature memory extraction loop.
*/
logic [31:0] addr;

/*
Halt detection and memory block dumping when program writes to tohost.
*/
always @(posedge clk) begin
    if (!reset && dut.stage8_memory_system.mem_write && dut.stage8_memory_system.address == tohost_addr) begin
        @(posedge clk);
        $display("[INFO] Halt requested by program. Exit code: %0d", dut.stage8_memory_system.write_data);
        $fclose(trace_file);
        sig_file = $fopen("rtl_sig.txt", "w");
        if (sig_file == 0) begin
            $display("[ERROR] Could not open rtl_sig.txt for writing!");
            $finish;
        end
        addr = sig_begin;
        while (addr < sig_end) begin
            $fwrite(sig_file, "%08h\n", dut.stage8_memory_system.dmem.memory[((addr - 32'h80020000) >> 2) & (dut.stage8_memory_system.dmem.MEM_DEPTH - 1)]);
            addr = addr + 4;
        end
        $fclose(sig_file);
        $display("[INFO] Signature dumped. Simulation finished successfully.");
        $finish;
    end
end

endmodule
