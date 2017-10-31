`define DATA_WIDTH 32
`define ADDR_WIDTH 6

`timescale 10ns / 1ns

module reg_file(
	input clk,
	input rstn,
	input wen,
	input double_en,	//new
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`DATA_WIDTH - 1:0] wdata,
	input [63:0] double_wdata,	//new
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
	
	
);

	// TODO: insert your code
	reg [`DATA_WIDTH - 1:0] register [(1<<`ADDR_WIDTH) - 1 :0] ; 
integer count;

always @ (posedge clk)
 begin
        register[0] <= 32'b0;
        if(0)
             for(count =1 ; count<`DATA_WIDTH ; count=count+1)
              	register[count] <= 0;
         else if (double_en) begin
         	 register[32] <= double_wdata[31:0];
         	 register[33] <= double_wdata[63:32];
         end
         else if (wen) begin
         	if(waddr)
            	register[waddr] <= wdata;
         end
         else;
   end 
  

assign rdata1 =  register[raddr1];
assign rdata2 =  register[raddr2];
endmodule
