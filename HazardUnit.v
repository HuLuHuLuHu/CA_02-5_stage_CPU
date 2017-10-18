module HazardUnit(
				input [31:0]    de_rs_data,
				input [31:0]    de_rt_data,
				input 			exe_wen,
				input [4:0] 	exe_regsrc,
				input [31:0] 	exe_wdata,
				input			exe_memread,
				input 			mem_wen,
				input [4:0]		mem_regsrc,
				input [31:0]    mem_wdata,
				input [4:0]     forward_rs,
				input [4:0] 	forward_rt,
				output [31:0] 	rs_data,
				output [31:0]   rt_data,
				output 			stall
);

wire rs_exe_forward;
wire rs_mem_forward;
wire rt_exe_forward;
wire rt_mem_forward;

assign rs_exe_forward = (exe_wen & exe_regsrc !== 0 & forward_rs == exe_regsrc );

assign rt_exe_forward = (exe_wen & exe_regsrc !== 0 &  forward_rt == exe_regsrc);

assign rs_mem_forward = (mem_wen & mem_regsrc !== 0 & forward_rs == mem_regsrc );

assign rt_mem_forward = (mem_wen & mem_regsrc !== 0 &  forward_rt == mem_regsrc);
					
assign rs_data = (rs_exe_forward)? exe_wdata:
				 (rs_mem_forward)? mem_wdata:
				 de_rs_data;

assign rt_data = (rt_exe_forward)? exe_wdata:
				 (rt_mem_forward)? mem_wdata:
				 de_rt_data;

assign stall = (exe_memread & exe_regsrc !== 0 &
				(forward_rs == exe_regsrc | forward_rt == exe_regsrc));

endmodule