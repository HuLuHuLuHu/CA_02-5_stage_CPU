

module writeback_stage(
    input  wire              clk,
    input  wire              resetn,
//data from exe stage and mem stage
    input  wire              exe_reg_en,
    input  wire       [4:0]  exe_reg_waddr,
    input  wire              exe_mem_read,
    input  wire       [31:0] alu_result_reg,
    input  wire       [31:0] mem_rdata,
//data used in wb stage
    output wire              wb_reg_en,
    output wire       [4:0]  wb_reg_waddr,
    output wire       [31:0] wb_reg_wdata
);



assign wb_reg_en    =  exe_reg_en;
assign wb_reg_waddr =  exe_reg_waddr;
assign wb_reg_wdata = (exe_mem_read) ? mem_rdata : alu_result_reg;

endmodule //writeback_stage
