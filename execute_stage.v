

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
    input  wire [4:0]  de_reg_waddr,
    input  wire [2:0]  de_load_type, //new
    input  wire [31:0] de_load_rt_data,  //new
    input  wire [2:0]  de_store_type,   //new
    input  wire [31:0] de_store_rt_data, //new
//data to mem stage
    output wire [31:0] alu_result,
    output wire [3:0]  exe_mem_wen, //new
    output wire [31:0] exe_mem_wdata, //new
//data to data hazard unit
    output wire        exe_busy,
//data to wb stage 
    output reg         exe_reg_en,
    output reg         exe_mem_read,
    output reg  [4:0]  exe_reg_waddr,
    output reg  [31:0] alu_result_reg,
    output wire        exe_MD_complete,
    output wire [63:0] exe_MD_result,
    output reg  [2:0]  exe_load_type,  //new
    output reg  [31:0] exe_load_rt_data  //new

);
//define store-type
parameter type_SW     = 3'b000;
parameter type_SB     = 3'b001;
parameter type_SH     = 3'b010;
parameter type_SWL    = 3'b011;
parameter type_SWR    = 3'b100;

wire mult_busy,div_busy;
wire mult_complete,div_complete;
wire [31:0] quotient,remainder;
wire [63:0] mult_result,div_result;

mul mul0
        (
        .clk(clk),
        .resetn(resetn),
        .mul_en(de_mult_en),
        .mul_signed(de_is_signed),
        .x(de_MD_src1),
        .y(de_MD_src2),
        .result(mult_result),
        .mul_busy(mult_busy),
        .mul_complete(mult_complete)
            );

div div0
        (
        .clk(clk),
        .resetn(resetn),
        .div_en(de_div_en),
        .div_signed(de_is_signed),
        .dividend(de_MD_src1),
        .divisor(de_MD_src2),
        .quotient(quotient),
        .remainder(remainder),
        .div_busy(div_busy),
        .div_complete(div_complete)
            ); 

alu alu0 
    (
    .ALUop  ( de_aluop    ), 
    .A      ( de_alusrc1  ), 
    .B      ( de_alusrc2  ), 
    .Result ( alu_result  ) 
    );
assign exe_busy      = mult_busy | div_busy;

assign div_result    = {remainder,quotient};

assign exe_MD_complete = mult_complete | div_complete;

assign exe_MD_result = (mult_complete)? mult_result:
                       (div_complete )? div_result :
                       64'b0;
wire [3:0] SB_men_wen;
wire [3:0] SH_mem_wen;
wire [3:0] SWL_mem_wen;
wire [3:0] SWR_mem_wen;
wire [31:0] SB_mem_wdata;
wire [31:0] SH_mem_wdata;
wire [31:0] SWL_mem_wdata;
wire [31:0] SWR_mem_wdata;

assign SB_men_wen    = (alu_result[1:0] == 2'b00)? 4'b0001:
                       (alu_result[1:0] == 2'b01)? 4'b0010:
                       (alu_result[1:0] == 2'b10)? 4'b0100:
                       (alu_result[1:0] == 2'b11)? 4'b1000: 4'b0000;

assign SH_mem_wen    = (alu_result[1:0] == 2'b00)? 4'b0011:
                       (alu_result[1:0] == 2'b10)? 4'b1100:4'b0000;

assign SWL_mem_wen   = (alu_result[1:0] == 2'b00)? 4'b0001:
                       (alu_result[1:0] == 2'b01)? 4'b0011:
                       (alu_result[1:0] == 2'b10)? 4'b0111:
                       (alu_result[1:0] == 2'b11)? 4'b1111: 4'b0000;

assign SWR_mem_wen   = (alu_result[1:0] == 2'b00)? 4'b1111:
                       (alu_result[1:0] == 2'b01)? 4'b1110:
                       (alu_result[1:0] == 2'b10)? 4'b1100:
                       (alu_result[1:0] == 2'b11)? 4'b1000: 4'b0000;

assign SB_mem_wdata  = (alu_result[1:0] == 2'b00)? de_store_rt_data:
                       (alu_result[1:0] == 2'b01)? de_store_rt_data << 8:
                       (alu_result[1:0] == 2'b10)? de_store_rt_data << 16:
                       (alu_result[1:0] == 2'b11)? de_store_rt_data << 24: 32'b0;

assign SH_mem_wdata  = (alu_result[1:0] == 2'b00)? de_store_rt_data:
                       (alu_result[1:0] == 2'b10)? de_store_rt_data << 16: 32'b0;

assign SWL_mem_wdata = (alu_result[1:0] == 2'b00)? {24'b0,de_store_rt_data[31:24]}:
                       (alu_result[1:0] == 2'b01)? {16'b0,de_store_rt_data[31:16]}:
                       (alu_result[1:0] == 2'b10)? {8'b0 ,de_store_rt_data[31:8 ]}:
                       (alu_result[1:0] == 2'b11)? de_store_rt_data : 32'b0;

assign SWR_mem_wdata = (alu_result[1:0] == 2'b00)? de_store_rt_data :
                       (alu_result[1:0] == 2'b01)? {de_store_rt_data[23:0],8'b0}:
                       (alu_result[1:0] == 2'b10)? {de_store_rt_data[15:0],16'b0}:
                       (alu_result[1:0] == 2'b11)? {de_store_rt_data[7:0],24'b0}: 32'b0;

//data and control signals
assign exe_mem_wen   = (de_store_type == type_SW) ? 4'b1111 : 
                       (de_store_type == type_SB) ? SB_men_wen  :
                       (de_store_type == type_SH) ? SH_mem_wen  :
                       (de_store_type == type_SWL)? SWL_mem_wen :
                       (de_store_type == type_SWR)? SWR_mem_wen : 4'b0000;

assign exe_mem_wdata = (de_store_type == type_SW) ? de_store_rt_data : 
                       (de_store_type == type_SB) ? SB_mem_wdata     :
                       (de_store_type == type_SH) ? SH_mem_wdata     :
                       (de_store_type == type_SWL)? SWL_mem_wdata    :
                       (de_store_type == type_SWR)? SWR_mem_wdata    : 32'b0;

always @(posedge clk) begin
    alu_result_reg <= alu_result;
    exe_reg_en     <= de_reg_en ;
    exe_reg_waddr  <= de_reg_waddr;
    exe_mem_read   <= de_mem_read;
    exe_load_type  <= de_load_type;
    exe_load_rt_data <= de_load_rt_data;
end



endmodule //execute_stage
