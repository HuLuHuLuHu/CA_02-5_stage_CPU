module HazardUnit(
				input [31:0]    de_rs_data,
				input [31:0]    de_rt_data,
				input 			exe_wen,
				input [4:0] 	exe_regsrc,
				input [31:0] 	exe_wdata,
				input			exe_memread,
				input 			mem_wen,
				input 			mem_regsrc,
				input [31:0]    mem_wdata,
				input [4:0]     forward_rs,
				input [4:0] 	forward_rt,
				output [31:0] 	rs_data,
				output [31:0]   rt_data,
				output 			stall
);

wire exe_forward;
wire mem_forward;

assign exe_forward = (exe_wen & exe_regsrc !== 0 &
					(rs_src == exe_regsrc | rt_src == exe_regsrc));

assign mem_forward = (mem_wen & mem_regsrc !== 0 &
					(rs_src == mem_regsrc | rt_src == mem_regsrc));

assign rs_data = (exe_forward)? exe_wdata:
				 (mem_forward)? mem_wdata:
				 de_rs_data;

assign rt_data = (exe_forward)? exe_wdata:
				 (mem_forward)? mem_wdata:
				 de_rt_data;

assign stall = (exe_memread & exe_regsrc !== 0 &
				(rs_src == exe_regsrc | rt_src == exe_regsrc));

endmodule