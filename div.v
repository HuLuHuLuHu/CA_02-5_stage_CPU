module div(
	input  wire        clk,
	input  wire        resetn,
	input  wire [31:0] dividend,
	input  wire [31:0] divisor,
	input  wire        div_en,
	input  wire        div_signed,
	output reg         div_busy,
	output reg         div_complete,
	output wire [31:0] quotient,
	output wire [31:0] remainder
	);
parameter START   = 2'b00;
parameter WORKING = 2'b10;
parameter FINISH  = 2'b11;
parameter PREPARE = 2'b01;

wire [31:0] remainder_reg;
wire [4:0] next_count;
reg  [6:0] count;
wire [1:0] next_state;
reg  [1:0] state;
reg  [31:0] dividend_reg,divisor_reg;
reg [31:0] quotient_reg;
reg  div_signed_reg;
reg  [63:0]extend_dividend;
wire [31:0] dividend_abs,divisor_abs;
wire  busy_temp,complete_temp;
wire [32:0] sub_result;
wire quotient_1;

assign sub_result = extend_dividend[63:31] + (~{1'b0,divisor_abs} + 1);
assign quotient_1 = (sub_result[32]==0)? 1 : 0;

assign dividend_abs = (div_signed_reg & dividend_reg[31]) ? (~dividend_reg+1):
					   dividend_reg;
assign divisor_abs  = (div_signed_reg & divisor_reg[31]) ? (~divisor_reg + 1):
					   divisor_reg;

assign next_count = (state == START)? 6'b0 :
					(state == WORKING)? (count + 1) :
					6'b0;
assign next_state = ((state == START) & (div_en == 1))? PREPARE:
					(state == PREPARE)? WORKING: 
					((state == WORKING) & (count < 6'd31))? WORKING:
					(state == WORKING) ?  FINISH:
					(state == FINISH)? START:
					START;
assign busy_temp = (next_state == WORKING|next_state==PREPARE|next_state==FINISH|div_en)? 1 : 0;
assign complete_temp = (next_state == FINISH)? 1 : 0;

assign 	 remainder_reg = extend_dividend[63:32];
assign quotient =   (state != FINISH)? 'd0 :
                    ((div_signed_reg & dividend_reg[31]& ~divisor_reg[31])| (div_signed_reg & ~dividend_reg[31] & divisor_reg[31]))? {~quotient_reg + 1}:
					quotient_reg;
					
assign remainder =  (state != FINISH)? 'd0 :
                    (div_signed_reg & dividend_reg[31])? {~remainder_reg + 1} :
				   remainder_reg;


always @(posedge clk) begin
	if(~resetn) begin
		count <= 'b0;
		state <= START;
		div_busy <= 0;
		dividend_reg<=0;
		divisor_reg<=0;
		div_complete <= 0;
		quotient_reg <= 0;
	end
else if(div_en)  begin
	   count <= 0;
        state <= next_state;
		divisor_reg <= divisor;
		dividend_reg <= dividend;
		div_signed_reg <= div_signed;
		div_busy <= busy_temp;
		div_complete <= complete_temp;
	end
else if (state == PREPARE) begin
		extend_dividend <= {32'b0,dividend_abs};
		state <= next_state;
end
else if(state == WORKING) begin
	count <= next_count;
	state <= next_state;
	div_busy <= busy_temp;
	div_complete <= complete_temp;
	quotient_reg[31-count] <= quotient_1;
	if(sub_result[32]==0)
	extend_dividend  = {sub_result,extend_dividend[30:0]}<<1;
	else
	extend_dividend  <= extend_dividend<<1;
	end
else begin
    count <=0;
    state <=0;
		div_busy <= 0;
    div_complete <= 0;
    quotient_reg <= 0;
    end
end
endmodule
