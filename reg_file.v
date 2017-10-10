`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement 4 4-bit registers
    `define DATA_WIDTH 4
	`define ADDR_WIDTH 2
`else
    `define DATA_WIDTH 32
	`define ADDR_WIDTH 5
`endif

`timescale 10ns / 1ns

module reg_file(
	input clk,
	input rstn,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);

	// TODO: insert your code
	reg [`DATA_WIDTH - 1:0] register [(1<<`ADDR_WIDTH) - 1 :0] ; 
integer count;

always @ (posedge clk)
 begin 

        if(rstn==0)
             for(count =0 ; count<`DATA_WIDTH ; count=count+1)
              register[count] <= 0;
         else if (wen)
         begin
         if(waddr)
             register[waddr] <= wdata;
         end
   end 
  

assign rdata1 =  register[raddr1];
assign rdata2 = register[raddr2];
endmodule
