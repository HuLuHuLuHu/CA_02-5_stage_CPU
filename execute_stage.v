

module execute_stage(
    input  wire        clk,
    input  wire        resetn,

//data used in this stage
    input  wire [3:0]  de_aluop,         //reg No. of dest operand, zero if no dest
    input  wire [31:0] de_alusrc1,        //value of source operand 1
    input  wire [31:0] de_alusrc2,        //value of source operand 2
    input  wire [32:0] de_extend_rs,   //new
    input  wire [32:0] de_extend_rt,   //new
//data from de stage 
    input  wire        de_reg_en,
    input  wire        de_mem_read,
    input  wire [5:0]  de_reg_waddr,
    input  wire        de_double_en,  //new
    input  wire        de_mul,        //new
    input  wire        de_div,        //new
//data to mem stage
    output wire [31:0] alu_result,
//data to wb stage 
    output reg         exe_reg_en,
    output reg         exe_mem_read,
    output reg  [5:0]  exe_reg_waddr,
    output reg  [31:0] alu_result_reg,
    output reg         exe_double_en,  //new
    output wire [31:0] exe_HI_wdata,  //new
    output wire [31:0] exe_LO_wdata   //new
);



alu alu0 
    (
    .ALUop  ( de_aluop    ), 
    .A      ( de_alusrc1  ), 
    .B      ( de_alusrc2  ), 
    .Result ( alu_result  ) 
    );

always @(posedge clk) begin
    alu_result_reg <= alu_result;
    exe_reg_en     <= de_reg_en;
    exe_reg_waddr  <= de_reg_waddr;
    exe_mem_read   <= de_mem_read;
    exe_double_en  <= de_double_en;
end

endmodule //execute_stage
