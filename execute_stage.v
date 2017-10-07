

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


);


alu alu0 
    (
    .ALUop  (de_aluop     ), 
    .A  ( de_alusrc1    ), 
    .B  ( de_alusrc2    ), 
    .Result ( alu_result    ) 
    );
always @(posedge clk) begin
    alu_result_reg <= alu_result;
 //   exe_dramwen <= de_dramwen;
//    exe_dramen <= de_dramen;
    exe_wen <= de_wen;
    exe_regsrc <= de_regsrc;
//    exe_dramwdata <= rt_reg_content;
    exe_is_load <= de_is_load;
end
endmodule //execute_stage
