 

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
    output wire data_sram_en,

    //forwarding
    input wire [4:0] forward_mem_rt,
    input wire forward_wb_wen,
    input wire [4:0] forward_wb_regsrc,
    input wire [31:0] forward_wb_wdata,
    input wire forward_wb_wen_reg,
    input wire [4:0] forward_wb_regsrc_reg,
    input wire [31:0] forward_wb_wdata_reg
);
//forwarding
wire write_from_wb;
wire write_from_wb_reg;
assign write_from_wb = (forward_wb_wen & forward_wb_regsrc !== 5'd0 &
                        forward_mem_rt == forward_wb_regsrc)? 1:0;
assign write_from_wb_reg = (forward_wb_wen_reg & forward_wb_regsrc_reg !== 5'd0 &
							forward_mem_rt !== forward_wb_regsrc &
							forward_mem_rt == forward_wb_regsrc_reg)? 1:0;
assign data_sram_wdata = (write_from_wb)? forward_wb_wdata:
						 (write_from_wb_reg)?forward_wb_wdata_reg:
						  rt_reg_content;
assign data_sram_addr = alu_result;
assign data_sram_wen = de_dramwen;
assign data_sram_en = de_dramen;

endmodule //memory_stage
