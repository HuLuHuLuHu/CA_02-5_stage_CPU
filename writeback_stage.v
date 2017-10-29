

module writeback_stage(
    input  wire              clk,
    input  wire              resetn,
//data from exe stage and mem stage
    input  wire              exe_reg_en,
    input  wire       [5:0]  exe_reg_waddr,
    input  wire              exe_mem_read,
    input  wire       [31:0] alu_result_reg,
    input  wire       [31:0] mem_rdata,
    input  wire              exe_double_en,
    input  wire       [63:0] exe_MD_result,
    input  wire       [2:0]  exe_load_type,  //new
    input  wire       [31:0] exe_load_rt_data,  //new
//data used in wb stage
    output wire              wb_reg_en,
    output wire       [5:0]  wb_reg_waddr,
    output wire       [31:0] wb_reg_wdata,
    output wire              wb_double_en,
    output wire       [63:0] wb_MD_result
);

//define load-type
parameter type_LW     = 3'b000;
parameter type_LB     = 3'b001;
parameter type_LBU    = 3'b010;
parameter type_LH     = 3'b011;
parameter type_LHU    = 3'b100;
parameter type_LWL    = 3'b101;
parameter type_LWR    = 3'b110;

wire [31:0] load_data;
wire [31:0] LWL_data;
wire [31:0] LWR_data;
wire [7:0]  byte_data;
wire [15:0] half_data;

assign LWL_data  = (alu_result_reg[1:0] == 2'b00)? {mem_rdata[7:0 ],exe_load_rt_data[23:0]}:
                   (alu_result_reg[1:0] == 2'b01)? {mem_rdata[15:0],exe_load_rt_data[15:0]}:
                   (alu_result_reg[1:0] == 2'b10)? {mem_rdata[23:0] ,exe_load_rt_data[7:0]}:
                   (alu_result_reg[1:0] == 2'b11)? mem_rdata:32'b0;

assign LWR_data  = (alu_result_reg[1:0] == 2'b00)? mem_rdata:
                   (alu_result_reg[1:0] == 2'b01)? {exe_load_rt_data[31:24],mem_rdata[31:8]}:
                   (alu_result_reg[1:0] == 2'b10)? {exe_load_rt_data[31:16],mem_rdata[31:16]}:
                   (alu_result_reg[1:0] == 2'b11)? {exe_load_rt_data[31:8] ,mem_rdata[31:24]}:
                   32'b0;

assign byte_data = (alu_result_reg[1:0] == 2'b00)? mem_rdata[7:0]:
                   (alu_result_reg[1:0] == 2'b01)? mem_rdata[15:8]:
                   (alu_result_reg[1:0] == 2'b10)? mem_rdata[23:16]:
                   (alu_result_reg[1:0] == 2'b11)? mem_rdata[31:24]:8'b0;

assign half_data = (alu_result_reg[1:0] == 2'b00)? mem_rdata[15:0]:
                   (alu_result_reg[1:0] == 2'b10)? mem_rdata[31:16]:16'b0;

assign load_data = (exe_load_type == type_LW) ? mem_rdata:
                   (exe_load_type == type_LB) ? {{24{byte_data[7]}},byte_data}:
                   (exe_load_type == type_LBU)? {24'b0,byte_data}:
                   (exe_load_type == type_LH) ? {{16{half_data[15]}},half_data}:
                   (exe_load_type == type_LHU)? {16'b0,half_data}:
                   (exe_load_type == type_LWL)? LWL_data:
                   (exe_load_type == type_LWR)? LWR_data:
                   32'b0;

assign wb_reg_en    =  exe_reg_en;
assign wb_reg_waddr =  exe_reg_waddr;
assign wb_reg_wdata = (exe_mem_read) ? load_data : alu_result_reg;
assign wb_double_en =  exe_double_en;
assign wb_MD_result =  exe_MD_result;

endmodule //writeback_stage
