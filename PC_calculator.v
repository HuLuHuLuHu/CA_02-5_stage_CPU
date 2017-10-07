`timescale 1ns / 1ps


module PC_calculator(
					//input signals
					input clk,
					input resetn,
					input is_b,//是Branch
					input is_j,//是JUMP
					input is_jr,//
					input [3:0] b_type,//哪一种B
					input [15:0] b_offset,
					input [25:0] j_index,
					input [31:0] rdata1,//for jr and b
					input [31:0] rdata2,//for b
					//output signals
					output 	   [31:0] next_pc,//计算出的下一个PC（组合逻辑）
					output reg [31:0] inst_sram_addr,
					output inst_sram_en//始终置1
    );
		parameter type_BNE = 4'b0000;
		parameter type_BEQ = 4'b0001;
		//wait for new type of B.



		wire b_taken;//用于计算各种不同的B是否TAKEN
		wire [31:0] b_result;
		assign b_result = rs_reg_content + ~rt_reg_content +1;
		assign b_taken = (b_type==type_BNE && b_result != 0)? 1:
						 (b_type==type_BEQ && b_result == 0)? 1:
						 0;


		//下地址计算
		wire [31:0] b_address,j_address,nomal_address;
		parameter reset_address = 32'hbfc00000;
		assign b_address = ({{16{b_offset[15]}},b_offset}<<2) + inst_sram_addr;
		assign j_address = {inst_sram_addr[31:28],j_index,2'b00};
		assign nomal_address = inst_sram_addr + 32'd4;
		
		//下地址选择
		assign next_pc = (resetn==1)? reset_address: //如果reset
						 (is_b && b_taken)? b_address: //B
						 (is_jr)?		rs_reg_content://JR
						 (is_j)?		j_address:  //J
						 nomal_address; //+4

		assign inst_sram_en = 1;
		always @ (posedge clk)
		inst_sram_addr <= next_pc;

endmodule
