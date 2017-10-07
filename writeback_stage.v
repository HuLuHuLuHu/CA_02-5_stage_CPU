

module writeback_stage(
    input  wire        clk,
    input  wire        resetn,
    input  wire        exe_wen,
    input  wire       [4:0] exe_regsrc,
    input  wire       [31:0] alu_result_reg,
    input  wire       [31:0] dram_rdata,
    input  wire       exe_is_load,
    output wire       wb_wen,
    output wire       [4:0] wb_regsrc,
    output wire       [31:0] wb_regwdata
);



assign wb_wen = exe_wen;
assign wb_regsrc = exe_regsrc;
assign wb_regwdata = (exe_is_load==1)? dram_rdata : alu_result_reg;

endmodule //writeback_stage
