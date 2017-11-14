`define DATA_WIDTH 32
`define ADDR_WIDTH 5

module reg_file(
	input clk,
	input rstn,
	input wen,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`DATA_WIDTH - 1:0] wdata,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);

reg [`DATA_WIDTH - 1:0] register [(1<<`ADDR_WIDTH) - 1 :0] ; 
integer count;

always @ (posedge clk)
 begin
        if(~rstn)
             for(count =0 ; count<`DATA_WIDTH ; count=count+1)
              	register[count] <= 0;
         else if (wen) begin
         	if(waddr)
            	register[waddr] <= wdata;
         end
         else;
   end 
assign rdata1 =  register[raddr1];
assign rdata2 =  register[raddr2];
endmodule
