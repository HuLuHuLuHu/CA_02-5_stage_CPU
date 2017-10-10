 

module memory_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] alu_result,        //reg num of dest operand
    input  wire [31:0] rt_reg_content,
    input  wire [3:0] de_dramwen,
    input  wire  de_dramen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output wire [3:0]  data_sram_wen,
    output wire data_sram_en
);

assign data_sram_addr = alu_result;
assign data_sram_wdata = rt_reg_content;
assign data_sram_wen = de_dramwen;
assign data_sram_en = de_dramen;

endmodule //memory_stage
