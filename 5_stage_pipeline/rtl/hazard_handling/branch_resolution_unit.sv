module branch_resolution_unit(
    input logic pc_sel,

    output logic flush
);

assign flush = pc_sel;
    
endmodule