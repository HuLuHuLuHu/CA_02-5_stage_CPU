

module execute_stage(
    input  wire        clk,
    input  wire        resetn,

//data used in this stage
    input  wire [3:0]  de_aluop,
    input  wire [31:0] de_alusrc1,
    input  wire [31:0] de_alusrc2,
    input  wire        de_mult_en,
    input  wire        de_div_en,
    input  wire        de_is_signed,
    input  wire [31:0] de_MD_src1,
    input  wire [31:0] de_MD_src2,
//data from de stage not used in this stage
    input  wire        de_reg_en,
    input  wire        de_mem_read,
    input  wire [5:0]  de_reg_waddr,
//data to mem stage
    output wire [31:0] alu_result,
//data to data hazard unit
    output wire        exe_busy, //new
//data to wb stage 
    output reg         exe_reg_en,
    output reg         exe_mem_read,
    output reg  [5:0]  exe_reg_waddr,
    output reg  [31:0] alu_result_reg,
    output wire        exe_double_en,  //new
    output wire [63:0] exe_MD_result   //new
);

wire mult_busy,div_busy;
wire mult_complete,div_complete;
wire [63:0] mult_result,div_result;

mul mul0
        (
        .clk(clk),
        .enable(de_mult_en),
        .is_signed(de_is_signed),
        .src1(de_MD_src1),
        .src2(de_MD_src2),
        .result(mult_result)
        .busy(mult_busy),
        .complete(mult_complete)
            );

div div0
        (
        .clk(clk),
        .enable(de_div_en),
        .is_signed(de_is_signed),
        .src1(de_MD_src1),
        .src2(de_MD_src2),
        .result(div_result),
        .busy(div_busy),
        .complete(div_complete)
            ); 

alu alu0 
    (
    .ALUop  ( de_aluop    ), 
    .A      ( de_alusrc1  ), 
    .B      ( de_alusrc2  ), 
    .Result ( alu_result  ) 
    );

assign exe_double_en = mult_complete | div_complete;

assign exe_MD_result = (mult_complete)? mult_result:
                       (div_complete )? div_result :
                       64'b0;

always @(posedge clk) begin
    alu_result_reg <= alu_result;
    exe_reg_en     <= de_reg_en;
    exe_reg_waddr  <= de_reg_waddr;
    exe_mem_read   <= de_mem_read;
end



endmodule //execute_stage
