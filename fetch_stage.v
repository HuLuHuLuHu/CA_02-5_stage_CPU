


module fetch_stage(
    input          clk,
    input          resetn,
    input   [31:0] inst_sram_rdata,
    input   [31:0] inst_sram_addr,
    output reg [31:0] fe_pc,           //fetch_stage pc
    output reg [31:0] fe_inst,         //instr code sent from fetch_stage
    //stall
    input stall
);
	parameter reset_address = 32'hbfc00000;
	//b-type for stall
	parameter BEQ   = 6'b000100;
	parameter BNE   = 6'b000101;
	parameter JR    = 6'b001000;
	
	always @(posedge clk) begin
		if(resetn == 0) begin
			fe_pc <= reset_address;
			fe_inst <= 32'b0;
		end
		else if(stall == 1) begin
			fe_pc <= fe_pc;
			fe_inst <= fe_inst;
		end
		else  begin
			fe_pc <= inst_sram_addr;
			fe_inst <= inst_sram_rdata;
		end
	end

endmodule //fetch_stage
