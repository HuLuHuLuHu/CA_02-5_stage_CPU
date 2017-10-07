

module decode_stage(
    input  wire        clk,
    input  wire        resetn,
    input  wire [31:0] fe_inst,
//signal for B and J
    output wire        de_is_b,
    output wire        de_is_j,  
    output wire        de_is_jr,
    output wire [3:0]  de_b_type,     
    output wire [15:0] de_b_offset, 
    output wire [25:0] de_j_index,   
//reg
    output wire [4:0]  raddr1,
    output wire [4:0]  raddr2,
    input  wire [31:0] rdata1,
    input  wire [31:0] rdata2,
    //output reg [31:0] rs_reg_content;
    output reg [31:0] rt_reg_content,//FOR SW
    output reg de_is_load,
    //output reg [4:0]  rd;//R-type有时�?要写入rd
    //output reg [4:0]  rt;//Load有时�?要写入rt
//alu
    output reg [3:0] de_aluop,
    output reg [31:0] de_alusrc1,
    output reg [31:0] de_alusrc2,
//dataram
    output reg de_dramen,
    output reg [3:0] de_dramwen,
    //读和写地�?应该在EXE�? 后传
//wb
    //写回地址�?般为rt rd 在上面已经给过了
    output reg de_wen,
    output reg [4:0] de_regsrc

);



//define 
parameter J     = 6'b000010;
parameter JAL   = 6'b000011;
parameter BEQ   = 6'b000100;
parameter BNE   = 6'b000101;
parameter ADDIU = 6'b001001;
parameter ADDI  = 6'b001000;
parameter SLTI  = 6'b001010;
parameter SLTIU = 6'b001011;
parameter LW    = 6'b100011;
parameter SW    = 6'b101011;
parameter LUI   = 6'b001111;

//r-type op define 
parameter ADD   = 6'b100000;
parameter OR    = 6'b100101;
parameter SLT   = 6'b101010;
parameter ADDU  = 6'b100001;
parameter SUB   = 6'b100010;
parameter SLL   = 6'b000000;
parameter JR    = 6'b001000;
parameter AND   = 6'b100100;


//b&j
    //for different type of b
    parameter type_BNE = 4'b0000;
    parameter type_BEQ = 4'b0001;
assign de_is_j = (fe_inst[31:26] == J || fe_inst[31:26] == JAL)? 1:0;
assign de_is_b = (fe_inst[31:26] == BEQ || fe_inst[31:26] == BNE)? 1:0;
assign de_b_type = (fe_inst[31:26] == BEQ)? type_BEQ :
                   (fe_inst[31:26] == BNE)? type_BNE : 
                   4'b0000;
assign de_is_jr = (fe_inst[31:26] == 6'b000000 && fe_inst[5:0] == JR)? 1:0;
assign de_b_offset = fe_inst[15:0];
assign de_j_index = fe_inst[25:0];




//reg
always @(posedge clk) begin
    //rt <= fe_inst[20:16];
    //rd <= fe_inst[15:11];
    //rs_reg_content <= rdata1;
    rt_reg_content <= rdata2;
end

//for alu
parameter alu_AND  = 4'b0000;
parameter alu_OR   = 4'b0001;
parameter alu_ADD  = 4'b0010;
parameter alu_SUB  = 4'b0011;
parameter alu_SLT  = 4'b0100;
parameter alu_SLTU = 4'b0101;
parameter alu_SLL  = 4'b0110;
parameter alu_SLR  = 4'b0111;
parameter alu_SAL  = 4'b1000;
parameter alu_SAR  = 4'b1001;
parameter alu_LUI  = 4'b1010;
wire [3:0] aluop_temp;
wire [31:0] alusrc1_temp;
wire [31:0] alusrc2_temp;
wire [31:0] signed_extend;
wire [31:0] unsigned_extend;
wire [31:0] sa_extend;
assign sa_extend = {27'b0,fe_inst[10:6]};
assign signed_extend = {{16{fe_inst[15]}},fe_inst[15:0]};
assign unsigned_extend = {16'b0,fe_inst[15:0]};
assign aluop_temp = (fe_inst[31:26]==ADDI||fe_inst[31:26]==ADDIU||fe_inst[31:26]==LW||fe_inst[31:26]==SW||
                    fe_inst[31:26]==6'b000000&&fe_inst[5:0]==ADD||fe_inst[31:26]==6'b000000&&fe_inst[5:0]==ADDU)? alu_ADD :
                    (fe_inst[31:26]==6'b000000&&fe_inst[5:0]==SLT||fe_inst[31:26]==SLTI)? alu_SLT :
                    (fe_inst[31:26]==SLTIU)? alu_SLTU :
                    (fe_inst[31:26]==6'b000000&&fe_inst[5:0]==SUB)? alu_SUB :
                    (fe_inst[31:26]==LUI)? alu_LUI :
                    (fe_inst[31:26]==6'b000000&&fe_inst[5:0]==OR)? alu_OR :
                    (fe_inst[31:26]==6'b000000&&fe_inst[5:0]==AND)? alu_AND :
                    (fe_inst[31:26]==6'b000000&&fe_inst[5:0]==SLL)? alu_SLL : 
                     4'b0000;
assign alusrc1_temp = (fe_inst[31:26]==6'b000000&&fe_inst[5:0]==SLL)? sa_extend:
                       rdata1;
assign alusrc2_temp = (fe_inst[31:26]==SLTIU||fe_inst[31:26]==ADDIU||fe_inst[31:26]==LUI)? unsigned_extend :
                      (fe_inst[31:26]==SW||fe_inst[31:26]==LW||fe_inst[31:26]==SLTI||
                      fe_inst[31:26]==ADDI)? signed_extend :
                      (fe_inst[31:26]==6'b000000)? rdata2 :
                      32'b0; 

always @(posedge clk) begin
    de_aluop <= aluop_temp;
    de_alusrc1 <= alusrc1_temp;
    de_alusrc2 <= alusrc2_temp;
end


//reg
assign raddr1 = fe_inst[25:21];
assign raddr2 = fe_inst[20:16];
wire wen_temp;
wire [4:0] regsrc_temp;
wire de_is_load_temp;
assign de_is_load_temp = (fe_inst[31:26]==LW)? 1:0;
assign wen_temp = (fe_inst[31:26]==6'b000000||fe_inst[31:26]==ADDIU||fe_inst[31:26]==ADDI
                   ||fe_inst[31:26]==SLTI||fe_inst[31:26]==SLTIU||fe_inst[31:26]==LW||
                   fe_inst[31:26]==LUI||fe_inst[31:26]==JAL)? 1:0;
assign regsrc_temp = (fe_inst[31:26]==6'b000000)? fe_inst[15:11] :
                     (fe_inst[31:26]==LW||fe_inst[31:26]==ADDIU||fe_inst[31:26]==ADDI||
                      fe_inst[31:26]==SLTI||fe_inst[31:26]==SLTIU||fe_inst[31:26]==LUI)? fe_inst[20:16]:
                     (fe_inst[31:26]==JAL)? 5'b11111:
                     5'b0;
always @(posedge clk) begin
    de_wen <= wen_temp;
    de_regsrc <= regsrc_temp;
    de_is_load <= de_is_load_temp;
end

//dram
wire [3:0] dramwen_temp;
wire dramen_temp;
assign dramen_temp = (fe_inst[31:26]==LW||fe_inst[31:26]==SW)? 1:0;
assign dramwen_temp = (fe_inst[31:26]==SW)? 4'b1111:4'b0;
always @(posedge clk) begin
    de_dramwen <= dramwen_temp;
    de_dramen <= dramen_temp;
end



endmodule //decode_stage
 