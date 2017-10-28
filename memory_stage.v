 

module memory_stage(
    input  wire        clk,
    input  wire        resetn,

//data from de stage and exe stage
    input  wire        de_mem_en,
    input  wire [3:0]  exe_mem_wen, //new
    input  wire [31:0] exe_mem_waddr,
    input  wire [31:0] exe_mem_wdata, //new
//data to data ram
    output wire        data_sram_en,
    output wire [3:0]  data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata
);

assign data_sram_en    = de_mem_en;
assign data_sram_wen   = exe_mem_wen;
assign data_sram_addr  = exe_mem_waddr;
assign data_sram_wdata = exe_mem_wdata;

endmodule //memory_stage
