`timescale 1ns / 1ps


module PC_calculator(
					input clk,
					input resetn,
					input stall,
					input execption,
					input return,
					//control signals from de stage
					input is_b,			 	//this is a branch inst
					input is_j,				//this is a direct jump inst
					input is_jr,			//this is jump to register inst
					input [3:0] b_type, 	//define what type of branch it is
					input [15:0] b_offset,	//the offset of branch inst
					input [25:0] j_index,	//the index of jump inst
					//reg file data from de stage (forwarded)
					input [31:0] de_rs_data,//rs data
					input [31:0] de_rt_data,//rt data
					input [31:0] return_addr,
					//output signals
					output inst_sram_en,
					output [31:0] next_pc,
					output [31:0] current_pc
    );

		
		parameter reset_addr = 32'hbfc00000;
		parameter execption_addr = 32'hbfc00380;
		wire b_taken, inst_BNE, inst_BEQ;
		wire inst_BGEZ,inst_BGTZ,inst_BLEZ,inst_BLTZ;
		wire inst_BLTZAL,inst_BGEZAL;
		wire [31:0] b_addr,j_addr,normal_addr;
		wire [31:0] b_result;
		reg  [31:0] pc_reg;

		//see what type of branch inst it is
		assign inst_BNE    = (b_type == 4'b0000);

		assign inst_BEQ    = (b_type == 4'b0001);

		assign inst_BGEZ   = (b_type == 4'b0010);

		assign inst_BGTZ   = (b_type == 4'b0011);

		assign inst_BLEZ   = (b_type == 4'b0100);

		assign inst_BLTZ   = (b_type == 4'b0101);

		assign inst_BLTZAL = (b_type == 4'b0110);

		assign inst_BGEZAL = (b_type == 4'b0111);

		assign b_result = de_rs_data + ~de_rt_data + 1;

		assign b_taken = (inst_BNE    & b_result !== 0)? 1:
						 (inst_BEQ    & b_result == 0 )? 1:
						 (inst_BGEZ   &  ~de_rs_data[31])? 1:
						 (inst_BGTZ   & de_rs_data !==   32'b0 & ~de_rs_data[31])? 1:
						 (inst_BLEZ   & (de_rs_data ==32'b0 | de_rs_data[31]))? 1:
						 (inst_BLTZ   & de_rs_data[31])? 1:
						 (inst_BLTZAL & de_rs_data[31])? 1:
						 (inst_BGEZAL & ~de_rs_data[31])? 1:
						  0;

		//three possible situation for next PC
		assign b_addr = ({{16{b_offset[15]}},b_offset}<<2) + pc_reg;

		assign j_addr = {pc_reg[31:28],j_index[25:0],2'b00};

		assign normal_addr = pc_reg + 32'd4;
		
		//the MUX to select the next PC
		assign next_pc = (~resetn)? 	   reset_addr:
						 (execption)?      execption_addr:
						 (return)?         return_addr:
		                 (stall  )?		   pc_reg://stall
						 (is_b & b_taken)? b_addr: //B
						 (is_jr)?		   de_rs_data://JR
						 (is_j)?		   j_addr:  //J
						 normal_addr; //+4

		assign inst_sram_en = 1;

		assign current_pc = pc_reg;
		
		always @ (posedge clk) pc_reg <= next_pc;
endmodule
