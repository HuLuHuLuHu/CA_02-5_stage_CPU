module data_hazard_unit(
				//data read from regfiles
				input [31:0]    reg_rs_data,
				input [31:0]    reg_rt_data,
				//data from if stage
				input [5:0]     de_rs_addr,
				input [5:0] 	de_rt_addr,
				//data from exe stage
				input 			exe_reg_en,
				input [5:0] 	exe_reg_waddr,
				input [31:0] 	exe_reg_wdata,
				input			exe_mem_read,
				input 			exe_busy,
				//data from mem stage
				input 			mem_reg_en,
				input [5:0]		mem_reg_waddr,
				input [31:0]    mem_reg_wdata, 
				//to de stage
				output [31:0] 	de_rs_data,
				output [31:0]   de_rt_data,
				//to all stage
				output 			stall
);

//control signals for forward mux
wire rs_exe_forward;
wire rs_mem_forward;
wire rt_exe_forward;
wire rt_mem_forward;

assign rs_exe_forward = (exe_reg_en & exe_reg_waddr !== 0 & de_rs_addr == exe_reg_waddr );

assign rt_exe_forward = (exe_reg_en & exe_reg_waddr !== 0 & de_rt_addr == exe_reg_waddr);

assign rs_mem_forward = (mem_reg_en & mem_reg_waddr !== 0 & de_rs_addr == mem_reg_waddr );

assign rt_mem_forward = (mem_reg_en & mem_reg_waddr !== 0 & de_rt_addr == mem_reg_waddr);

//select real rs and rt data to de stage			
assign de_rs_data = (rs_exe_forward)? exe_reg_wdata: //exe stage forward data is piror to mem stage
				    (rs_mem_forward)? mem_reg_wdata:
				 	 reg_rs_data;

assign de_rt_data = (rt_exe_forward)? exe_reg_wdata: //exe stage forward data is piror to mem stage
				 	(rt_mem_forward)? mem_reg_wdata:
				 	 reg_rt_data;

//generate stall signal
assign stall = ((exe_mem_read & exe_reg_waddr !== 0 & 
				(de_rs_addr == exe_reg_waddr | de_rt_addr == exe_reg_waddr)) | exe_busy);

endmodule