

module execute_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [ 3:0] de_aluop,         //reg No. of dest operand, zero if no dest
    input  wire [31:0] de_alusrc1,        //value of source operand 1
    input  wire [31:0] de_alusrc2,        //value of source operand 2


    output wire [31:0] alu_result,
    output reg [31:0] alu_result_reg,
    
    input wire de_is_load,
    input wire de_wen,
    input wire [4:0] de_regsrc,
    output reg exe_wen,
    output reg [4:0] exe_regsrc,
    output reg exe_is_load
    
    input  wire [4:0] forward_exe_rs,
    input  wire [4:0] forward_exe_rt,
    input  wire  forward_wb_wen,
    input  wire [4:0] forward_wb_regsrc;
    input  wire [31:0] forward_wb_data
);

wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire src1_from_mem;
wire src1_from_wb;
wire src2_from_mem;
wire src2_from_wb;
//forwarding in EXE stage
//forwarding control signals
assign src1_from_mem = (exe_wen & exe_regsrc != 0 & 
                        forward_exe_rs == exe_regsrc)? 1:0;

assign src2_from_mem = (exe_wen & exe_regsrc != 0 & 
                        forward_exe_rt == exe_regsrc)? 1:0;

assign src1_from_wb  = (forward_wb_wen & forward_wb_regsrc != 0 &
                        forward_exe_rs != exe_regsrc &
                        forward_exe_rs == forward_wb_regsrc)? 1:0;

assign src2_from_wb  = (forward_wb_wen & forward_wb_regsrc != 0 &
                        forward_exe_rt != exe_regsrc &
                        forward_exe_rt == forward_wb_regsrc)? 1:0;


//mux
assign alu_src1 = (src1_from_mem)? alu_result_reg:
                  (src1_from_wb)?  forward_wb_data:
                  de_alusrc1;
                  
assign alu_src2 = (src2_from_mem)? alu_result_reg:
                  (src2_from_wb)?  forward_wb_data:
                  de_alusrc2;

alu alu0 
    (
    .ALUop  (de_aluop     ), 
    .A  ( alusrc1    ), 
    .B  ( alusrc2    ), 
    .Result ( alu_result    ) 
    );
always @(posedge clk) begin
    alu_result_reg <= alu_result;
    exe_wen <= de_wen;
    exe_regsrc <= de_regsrc;
    exe_is_load <= de_is_load;//for future write back source selection
end

endmodule //execute_stage
