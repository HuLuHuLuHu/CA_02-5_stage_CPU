 

module memory_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] alu_result,        //reg num of dest operand
    input  wire [31:0] rt_reg_content,
    input  wire [3:0] de_dramwen,
    input  wire  de_dramen,
    output wire [31:0] data_sram_addr,
    output wire [3:0]  data_sram_wen,
    output wire data_sram_en,
    output wire [31:0] data_sram_wdata
   // output wire [31:0] data_sram_wdata
            //mem_stage final result

);

assign data_sram_en = de_dramen;
assign data_sram_wen = de_dramwen;
assign data_sram_wdata = alu_result;
///////assign data_sram_wdata = exe_dramwdata;
assign data_sram_addr = alu_result;

endmodule //memory_stage
