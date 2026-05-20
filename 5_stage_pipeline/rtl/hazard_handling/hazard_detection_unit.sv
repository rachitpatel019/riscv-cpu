module hazard_detection_unit(
    input logic mem_read_ex,
    input logic [4:0] rd_ex,
    input logic [4:0] rs1_id,
    input logic [4:0] rs2_id,
    input logic uses_rs2, // Signal to indicate if the instruction in EX stage uses rs2
    input logic core_stall, // Global stall from memory arbiter

    output logic stall
);

always_comb begin
    if (core_stall) begin
        stall = 1;
    end
    else if (mem_read_ex && (rd_ex != 5'b0) && ((rd_ex == rs1_id) || (uses_rs2 && rd_ex == rs2_id))) begin
        // Hazard detected, stall the pipeline
        stall = 1;
    end
    else begin
        // No hazard, proceed normally
        stall = 0;
    end
end
    
endmodule