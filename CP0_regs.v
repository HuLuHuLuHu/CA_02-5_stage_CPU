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
  input return,
  input  [4:0]  CP0_CAUSE_ExcCode,
  input  [31:0] CP0_EPC,
  input  [5:0]  HW_IP,
  input  CP0_STATUS_BD,
  input  [31:0] CP0_BadVaddr,
  output [31:0] return_addr,
  output CP0_STATUS_EXL,
  output interupt,
  input wire [15:0]btn_key_r
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


reg  [5:0]  HW_IP_reg;
reg  [1:0]  SW_IP_reg;
wire [1:0]  SW_IP;
wire        TI; //timer interupt
//Hardware interupt
assign TI = (register[Count] == register[Compare]) & (register[Compare]!=='b0);
assign HW_IP[4:1] = 4'b0;
assign HW_IP[0] = btn_key_r[12];
always @ (posedge clk) begin
  if(~rstn)  begin
    HW_IP_reg <= 6'b0;
    SW_IP_reg<= 2'b0;
    end
  else   begin
    HW_IP_reg <= {TI,HW_IP[4:0]} & register[STATUS][15:10] & {6{register[STATUS][0]}};
    SW_IP_reg <= SW_IP;
    end
end

//Software interupt
assign SW_IP = register[Cause][9:8] & register[STATUS][9:8] & {2{register[STATUS][0]}};

//make a timer
reg timer;
always @ (posedge clk) begin
    if(~rstn)
       timer <= 1'b0;
    else 
       timer <= ~timer;
end

always @ (posedge clk)
 begin
        if(~rstn)
             for(counter =0 ; counter<32 ; counter=counter+1)
             begin
              	register[counter] <= 0;
            end
         else if (execption) begin
             register[STATUS]    <= register[STATUS] | EXL_MASK ;
             register[Cause]     <= {CP0_STATUS_BD,HW_IP_reg[5],register[Cause][29:16],HW_IP_reg,register[Cause][9:7],CP0_CAUSE_ExcCode,2'b0};
             register[Exec_pc]   <= CP0_EPC;
             register[Addr]      <= CP0_BadVaddr;
             register[Count] <= register[Count] + timer;
         end
         else if(return)begin
          register[STATUS] <= register[STATUS] & 32'hfffffffd;
         register[Count] <= register[Count] + timer;
         end
         else if (wen) begin
            if(waddr == Cause)
            register[waddr] <= (wdata & 32'b1100_1000_1000_0000_11111111_0_11111_00);
            else
            	register[waddr] <= wdata;
         end
         else begin
              register[Count] <= register[Count] + timer;
       //       register[Cause] <= register[Cause]& 32'h7fffffff;
            end
   end 

//output signals
assign rdata         =  register[raddr];

assign return_addr   =  register[Exec_pc];

assign CP0_STATUS_EXL=  register[STATUS][1];

assign interupt      =  (|HW_IP_reg) | (|SW_IP_reg);
endmodule
