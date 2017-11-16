module CP0_regs(
	input clk,
	input rstn,
//for mfc0 and mtc0
  input         wen,
	input  [4:0]  waddr,
	input  [31:0] wdata,
	input  [4:0]  raddr,
	output [31:0] rdata,
//for execption
  input execption,
  input  [4:0]  CP0_CAUSE_ExcCode,
  input  [31:0] CP0_EPC,
  input  [5:0]  HW_IP,
  input  CP0_STATUS_BD,
  input  CP0_BadVaddr,
  output [31:0] return_addr,
  output CP0_STATUS_EXL,
  output interupt
);
reg [31:0] register [31:0]; 
integer counter;

parameter Count    = 32'd9;
parameter Compare  = 32'd11;
parameter Addr     = 32'd8;
parameter STATUS   = 32'd12;
parameter Cause    = 32'd13;
parameter Exec_pc  = 32'd14;
parameter EXL_MASK = 32'h00000002;


reg  [7:0]  HW_IP_reg;
wire [1:0]  SW_IP;
wire        TI; //timer interupt
//Hardware interupt
assign TI = (register[Count] == register[Compare]);

always @ (posedge clk) begin
  if(~rstn)
    HW_IP_reg <= 6'b0;
  else
    HW_IP_reg <= {TI,HW_IP[4:0]} & register[STATUS][15:10] & {6{register[STATUS][0]};
end

//Software interupt
assign SW_IP = register[Cause][9:8] & register[STATUS][9:8] & {2{register[STATUS][0]};

//make a timer
reg timer;
always @ (posedge clk) begin
    if(~rstn)
       timer <= 1'b0;
    else 
       timer <= timer + 1'b1;
end

always @ (posedge clk)
 begin
        if(~rstn)
             for(counter =0 ; counter<32 ; counter=counter+1)
              	register[counter] <= 0;
         else if (execption) begin
             register[STATUS]    <= register[STATUS] | EXL_MASK | {CP0_STATUS_BD,HW_IP_reg[5],30'b0};
             register[Cause]     <= register[Cause]  | {16'b0,HW_IP_reg,3'b0,CP0_CAUSE_ExcCode,2'b0};
             register[Exec_pc]   <= CP0_EPC;
             register[Addr]      <= CP0_BadVaddr;
         end
         else if (wen) begin
            	register[waddr] <= wdata;
         end
         else
              register[Count] <= register[Count] + timer;
   end 

//output signals
assign rdata         =  register[raddr];

assign return_addr   =  register[Exec_pc];

assign CP0_STATUS_EXL=  register[STATUS][1];

assign interupt      =  (|HW_IP_reg) | (|SW_IP);
endmodule
