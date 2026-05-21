module hazard_detection_unit(
    input logic mem_read_ex,
    input logic [4:0] rd_ex,
    input logic mem_read_mem, // NEW: Detect load in MEM stage
    input logic [4:0] rd_mem,    // NEW: rd of load in MEM stage
    input logic [4:0] rs1_id,
    input logic [4:0] rs2_id,
    input logic uses_rs2, // Signal to indicate if the instruction in EX stage uses rs2
    input logic core_stall, // Global stall from memory arbiter

    output logic stall
);

always_comb begin
    stall = 1'b0;
    
    if (core_stall) begin
        stall = 1'b1;
    end
    // Hazard from EX stage (1st cycle of load)
    else if (mem_read_ex && (rd_ex != 5'b0) && ((rd_ex == rs1_id) || (uses_rs2 && rd_ex == rs2_id))) begin
        stall = 1'b1;
    end
    // Hazard from MEM stage (2nd cycle of load - required for synchronous memory)
    else if (mem_read_mem && (rd_mem != 5'b0) && ((rd_mem == rs1_id) || (uses_rs2 && rd_mem == rs2_id))) begin
        stall = 1'b1;
    end
end
    
endmodule