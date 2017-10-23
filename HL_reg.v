`timescale 10ns / 1ns

module HL_reg(
	input clk,
	input rstn,
	input waddr,
	input raddr,
	input wen,
	input [31:0] wdata,
	output [31:0] rdata,
);

	reg [31:0] register [1:0]; 

always @ (posedge clk) begin 
        if(~rstn) begin
        register[0] <= 32'b0;
        register[1] <= 32'b0;
        end else if(wen) begin
             register[waddr] <= wdata;
        end
   end 
  

assign rdata =  register[raddr];
endmodule
