 

module memory_stage(
    input  wire        clk,
    input  wire        resetn,
    input wire         execption,

//data from de stage and exe stage
    input  wire        de_mem_en,
    input  wire [3:0]  exe_mem_wen, 
    input  wire [31:0] exe_mem_addr,
    input  wire [31:0] exe_mem_wdata,
//data to data ram
    output wire        data_req,
    output wire        data_wr,
    output wire [3:0]  data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata
);

assign data_req   = de_mem_en & ~execption;

assign data_wr    = |exe_mem_wen;

assign data_size  = exe_mem_wen;

assign data_addr  = {exe_mem_addr[31:2],2'b0};
//(data_wr)? exe_mem_addr : 
assign data_wdata = exe_mem_wdata;

endmodule //memory_stage
