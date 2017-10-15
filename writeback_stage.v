

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
    output wire       [31:0] wb_regwdata,
    //forwarding
    output reg        forward_wb_wen,
    output reg        [4:0] forward_wb_regsrc,
    output reg        [31:0] forward_wb_wdata
);



assign wb_wen = exe_wen;
assign wb_regsrc = exe_regsrc;
assign wb_regwdata = (exe_is_load==1)? dram_rdata : alu_result_reg;

//forwarding
always @(posedge clk)begin
    forward_wb_wen <= wb_wen;
    forward_wb_regsrc <= wb_regsrc;
    forward_wb_wdata <= wb_regwdata;
end

endmodule //writeback_stage
