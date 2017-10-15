`timescale 1ns / 1ps


module PC_calculator(
					//input signals
					input clk,
					input resetn,
					input is_b,//is a branch inst
					input is_j,//is a jump inst
					input is_jr,//is jump to register inst
					input [3:0] b_type,//define what type of branch it is
					input [15:0] b_offset,
					input [25:0] j_index,
					input [31:0] rdata1,//rs data
					input [31:0] rdata2,//rt data
					
					//output signals
					output 	   [31:0] next_pc,
					output     [31:0] current_pc,
					output inst_sram_en,//now it is always 1
					//stall
					input stall
    );

		//define the type of branch inst
		parameter type_BNE = 4'b0000;
		parameter type_BEQ = 4'b0001;
		wire b_taken;//b is taken or not
		wire [31:0] b_result;//the result of b-type inst
		assign b_result = rdata1 + ~rdata2 +1;
		assign b_taken = (b_type==type_BNE & b_result !== 0)? 1:
						 (b_type==type_BEQ & b_result == 0)? 1:
						 0;

		//three possible situation for next PC
		wire [31:0] b_address,j_address,normal_address;
		reg [31:0] inst_sram_addr;
		parameter reset_address = 32'hbfc00000;
		assign b_address = ({{16{b_offset[15]}},b_offset}<<2) + inst_sram_addr;
		assign j_address = {inst_sram_addr[31:28],j_index,2'b00};
		assign normal_address = inst_sram_addr + 32'd4;
		
		//the MUX to select the next PC
		assign next_pc = (resetn==0)? reset_address:
						 (is_b & b_taken)? b_address: //B
						 (is_jr)?		rdata1://JR
						 (is_j)?		j_address:  //J
						 (stall)?		inst_sram_addr: //stall
						 normal_address; //+4

		assign inst_sram_en = 1;
		always @ (posedge clk)
			inst_sram_addr <= next_pc;
		assign  current_pc = inst_sram_addr;

endmodule
