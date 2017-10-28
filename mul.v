`timescale 1ns / 1ps
module mul(
    input  wire        clk,
    input  wire        resetn,
    input  wire        mul_en,
//data from de stage and exe stage
    input  wire mul_signed, 
    input  wire [31:0] x,
    input  wire [31:0] y,
    output reg mul_busy,
    output reg mul_complete,
    output wire [63:0] result
);

parameter START = 2'b00;
parameter WORKING = 2'b01;
parameter FINISH = 2'b10;

reg [1:0] state;
wire [1:0] next_state;
reg [32:0] X_reg,Y_reg;
wire [32:0] X,Y;
wire [65:0] Result;
assign X =  (resetn==0)? 'b0:
            (mul_signed==0)? {1'b0,x} : 
            (x[31] == 0)? {1'b0,x} :
            {1'b1,x};
assign Y =  (resetn==0)? 'b0:
            (mul_signed==0)? {1'b0,y} : 
            (y[31] == 0)? {1'b0,y} :
            {1'b1,y};


mul1 mul1(.CLK(clk),.A(X_reg),.B(Y_reg),.P(Result));

assign next_state = ((state==START)&mul_en)? WORKING :
                    (state==START)?  START:
                    (state==WORKING)? FINISH:
                    (state==FINISH)? START:
                    START;


always @(posedge clk) begin
	if(~resetn) begin
		X_reg <= 0;
		Y_reg <= 0;
		state <= START;
	end

	else if(mul_en) begin
	X_reg <= X;
	Y_reg <= Y;
	state <= next_state;
	end

	else begin
	state <= next_state;
	end

	if(next_state==WORKING)
	mul_busy <= 1;
	else 
	mul_busy <= 0;

	if(next_state==FINISH) begin
	mul_complete <= 1;
	end
	else
	mul_complete <= 0; 

end

assign result = Result[63:0];


endmodule