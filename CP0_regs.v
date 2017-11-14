module CP0_regs(
	input clk,
	input rstn,
	input wen,
    input execption,
	input [4:0] waddr,
	input [31:0] wdata,
	input [4:0] raddr,
	output [31:0] rdata,

  output [31:0] EPC,
  input  [4:0]  ExcCode,
  input  [31:0] execption_pc
);
reg [31:0] register [31:0]; 
integer count;

parameter SR = 32'd12;
parameter Cause = 32'd13;
parameter Exec_pc = 32'd14;
parameter EXL_MASK = 32'h00000002;

always @ (posedge clk)
 begin
        if(~rstn)
             for(count =0 ; count<32 ; count=count+1)
              	register[count] <= 0;
         else if (execption) begin
             register[SR]    <= register[SR] | EXL_MASK;
             register[Cause] <= register[Cause] | {25'b0,ExcCode,2'b0};
             register[Exec_pc]   <= execption_pc;
         end
         else if (wen) begin
            	register[waddr] <= wdata;
         end
         else;
   end 
assign rdata =  register[raddr];
assign EPC   =  register[Exec_pc];
endmodule
