module fetch_stage(
    input             clk,
    input             resetn,
    input 			  stall,
    input             return,
    input             execption,
    input      [31:0] inst_sram_raddr,
    input      [31:0] inst_sram_rdata,
    output reg [31:0] fe_pc,
    output reg [31:0] fe_inst
);
	parameter reset_pc   = 32'hbfc00000;
	parameter reset_inst = 32'h00000000;
	
	always @(posedge clk) 
	begin
		if(~resetn) 
			begin
				fe_pc   <= reset_pc;
				fe_inst <= reset_inst;
			end
        else if(execption | return)
                begin
                    fe_pc   <= reset_pc;
                    fe_inst <= reset_inst;
                end
		else if(stall) 
			begin
				fe_pc   <= fe_pc;
				fe_inst <= fe_inst;
			end

		else  
			begin
				fe_pc   <= inst_sram_raddr;
				fe_inst <= inst_sram_rdata;
			end
	end
endmodule
