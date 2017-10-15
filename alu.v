
`define DATA_WIDTH 32
`timescale 10ns / 1ns

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [3:0] ALUop,
	output reg Overflow,
	output reg CarryOut,
	output reg Zero,
	output reg [`DATA_WIDTH - 1:0] Result
);
parameter AND  = 4'b0000;
parameter OR   = 4'b0001;
parameter ADD  = 4'b0010;
parameter SUB  = 4'b0011;
parameter SLT  = 4'b0100;
parameter SLTU = 4'b0101;
parameter SLL  = 4'b0110;
parameter SRL  = 4'b0111;
parameter SAL  = 4'b1000;
parameter SRA  = 4'b1001;
parameter LUI  = 4'b1010;
parameter XOR  = 4'b1011;
parameter NOR  = 4'b1100;

reg carryout_low;
reg [`DATA_WIDTH - 2:0] result_low;


always @(A or B or ALUop)
begin
case (ALUop)
    AND:
    begin
    Result = A & B;
      Zero = (Result == 0) ? 1 :  0;
      Overflow = 0;
      CarryOut = 0;
    end
 
    OR:
    begin
      Result = A | B;
      Zero = (Result == 0) ? 1 :  0;  
      Overflow = 0;
      CarryOut = 0;
    end
   
    ADD:
    begin
    {CarryOut,Result }= A + B;
     {carryout_low,result_low} = A[`DATA_WIDTH - 2:0] +B[`DATA_WIDTH - 2:0] ;
      Zero = (Result == 0) ? 1 :  0;
    Overflow = CarryOut ^ carryout_low;
    end

    SUB:
    begin
  {CarryOut, Result} = A + ~B +1;
   {carryout_low,result_low} = A[`DATA_WIDTH - 2:0] +~B[`DATA_WIDTH - 2:0]+1 ;
    Overflow = CarryOut ^ carryout_low;
    Zero = (Result == 0) ? 1 :  0;
    end
   
    SLT:
    begin
    {CarryOut, Result} = A + ~B +1;
     {carryout_low,result_low} = A[`DATA_WIDTH - 2:0] +~B[`DATA_WIDTH - 2:0]+1 ;
     Overflow = CarryOut ^ carryout_low;
    Result [0] = Overflow ^ Result[`DATA_WIDTH-1];
    Result [`DATA_WIDTH-1:1] = 0; 
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end
    
    SLTU:
    begin
    Result = (A<B)? 1 : 0;
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end
    
    SLL:
    begin
    Result = B<<A[4:0];
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end

    SRL:
    begin
    Result = B>>A[4:0];
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end

    SAL:
    begin
    Result = B<<A;
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end

    SRA:
    begin
    Result = B>>>A;
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end

    LUI:
    begin
    Result = {B[15:0],16'd0};
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    end

    XOR:
    begin
    Result = A ^ B;
    Zero = (Result==0)? 1:0;
    CarryOut = 0;
    Overflow = 0;
    end

    NOR:
    begin
    Result = A ^ ~B;
    Zero = (Result==0)? 1:0;
    CarryOut = 0;
    Overflow = 0;
    end

    default:
    begin
    Zero = 0;
    CarryOut = 0;
    Overflow = 0;
    Result = 0;
    end
endcase     
end

endmodule
