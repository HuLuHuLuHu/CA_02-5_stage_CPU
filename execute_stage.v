

module execute_stage(
    input  wire        clk,
    input  wire        resetn,

//data used in this stage
    input  wire [3:0]  de_aluop,         //reg No. of dest operand, zero if no dest
    input  wire [31:0] de_alusrc1,        //value of source operand 1
    input  wire [31:0] de_alusrc2,        //value of source operand 2
//data from de stage 
    input  wire        de_reg_en,
    input  wire        de_mem_read,
    input  wire [5:0]  de_reg_waddr,
    input  wire        de_double_en,  //new
    input  wire        de_mul,        //new
    input  wire        de_div,        //new
    input  wire        div_en,
    input  wire        is_signed,
//data to mem stage
    output wire [31:0] alu_result,
//data to wb stage 
    output reg         exe_reg_en,
    output reg         exe_mem_read,
    output reg  [5:0]  exe_reg_waddr,
    output reg  [31:0] alu_result_reg,
    output reg         exe_double_en,  //new
    output wire [31:0] exe_HI_wdata,  //new
    output wire [31:0] exe_LO_wdata, //new
    output wire div_busy,
    output wire div_complete

);
wire is_signed;
wire div_busy,div_complete;
wire [63:0] result;
assign exe_HI_wdata = result[63:32];
assign exe_LO_wdata = result[31: 0];
mul1 mul
        (
        .clk(clk)
        .resetn(resetn)
        .mul_signed(is_signed)
        .x(de_alusrc1),
        .y(de_alusrc2),
        .result(result)
            );

divider div
        (
        .clk(clk),
        .rst(~resetn),
        .dividend(de_alusrc1),
        .divisor(de_alusrc2),
        .div(div_en),
        .div_signed(is_signed),
        .quotient(result[63:32]),
        .remainder(result[31: 0]),
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

always @(posedge clk) begin
    alu_result_reg <= alu_result;
    exe_reg_en     <= de_reg_en;
    exe_reg_waddr  <= de_reg_waddr;
    exe_mem_read   <= de_mem_read;
    exe_double_en  <= de_double_en;
end



endmodule //execute_stage
