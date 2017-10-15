module decode_stage(
    input  wire        clk,
    input  wire        resetn,
    input  wire [31:0] fe_inst,
    input  wire [31:0] current_pc,
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
    output reg [31:0] rt_reg_content,//FOR SW
    output reg de_is_load,
//alu
    output reg [3:0] de_aluop,
    output reg [31:0] de_alusrc1,
    output reg [31:0] de_alusrc2,
//dataram
    output reg de_dramen,
    output reg [3:0] de_dramwen,
//wb
    output reg de_wen,
    output reg [4:0] de_regsrc

);



//define inst
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
parameter ANDI  = 6'b001100;
parameter ORI   = 6'b001101;
parameter XORI  = 6'b001110;

//define r-type func
parameter IS_R  = 6'b000000;
parameter ADD   = 6'b100000;
parameter OR    = 6'b100101;
parameter SLT   = 6'b101010;
parameter ADDU  = 6'b100001;
parameter SUB   = 6'b100010;
parameter SLL   = 6'b000000;
parameter JR    = 6'b001000;
parameter AND   = 6'b100100;
parameter SLTU  = 6'b101011;
parameter SUBU  = 6'b100011;
parameter NOR   = 6'b100111;
parameter XOR   = 6'b100110;
parameter SRA   = 6'b000011;
parameter SLLV  = 6'b000100;
parameter SRA   = 6'b000011;
parameter SRL   = 6'b000010;
parameter SRAV  = 6'b000111;
parameter SRLV  = 6'b000110;



wire [5:0] OP;
wire [5:0] FUNC;
assign OP = fe_inst[31:26];
assign FUNC = fe_inst[5:0];

//b&j
    //for different type of b
    parameter type_BNE = 4'b0000;
    parameter type_BEQ = 4'b0001;
assign de_is_j = (OP == J | OP == JAL)? 1:0;
assign de_is_b = (OP == BEQ | OP == BNE)? 1:0;
assign de_b_type = (OP == BEQ)? type_BEQ :
                   (OP == BNE)? type_BNE : 
                   4'b0000;
assign de_is_jr = (OP == IS_R & FUNC == JR)? 1:0;
assign de_b_offset = fe_inst[15:0];
assign de_j_index = fe_inst[25:0];




//for SW and
always @(posedge clk) begin
    rt_reg_content <= rdata2;
end

//alu sources and control signals
parameter alu_AND  = 4'b0000;
parameter alu_OR   = 4'b0001;
parameter alu_ADD  = 4'b0010;
parameter alu_SUB  = 4'b0011;
parameter alu_SLT  = 4'b0100;
parameter alu_SLTU = 4'b0101;
parameter alu_SLL  = 4'b0110;
parameter alu_SRL  = 4'b0111;
parameter alu_SAL  = 4'b1000;
parameter alu_SRA  = 4'b1001;
parameter alu_LUI  = 4'b1010;
parameter alu_XOR  = 4'b1011;
parameter alu_NOR  = 4'b1100;

wire [3:0] aluop_temp;
wire [31:0] alusrc1_temp;
wire [31:0] alusrc2_temp;
wire [31:0] signed_extend;
wire [31:0] unsigned_extend;
wire [31:0] sa_extend;
assign sa_extend = {27'b0,fe_inst[10:6]};
assign signed_extend = {{16{fe_inst[15]}},fe_inst[15:0]};
assign unsigned_extend =  {{16{fe_inst[15]}},fe_inst[15:0]};
assign aluop_temp = (OP==ADDI|OP==ADDIU|
                     OP==LW|OP==SW|
                     OP==IS_R&FUNC==ADD|
                     OP==IS_R&FUNC==ADDU|
                     OP==JAL)? alu_ADD :
                    (OP==IS_R&FUNC==SLT|OP==SLTI)? alu_SLT :
                    (OP==SLTIU|OP==IS_R&FUNC==SLTU)? alu_SLTU :
                    (OP==IS_R&FUNC==SUB|OP==IS_R&FUNC==SUBU)? alu_SUB :
                    (OP==LUI)? alu_LUI :
                    (OP==IS_R&FUNC==OR|OP==ORI)? alu_OR :
                    (OP==IS_R&FUNC==AND|OP==ANDI)? alu_AND :
                    (OP==IS_R&FUNC==SLL|OP==IS_R&FUNC==SLLV)? alu_SLL : 
                    (OP==IS_R&FUNC==XOR|OP==XORI)? alu_XOR :
                    (OP==IS_R&FUNC==NOR)? alu_NOR :
                    (OP==IS_R&FUNC==SRA|OP==IS_R&FUNC==SRAV)? alu_SRA :
                    (OP==IS_R&FUNC==SRL|OP==IS_R&FUNC==SRLV)? alu_SRL :
                     4'b0000;
assign alusrc1_temp = (OP==IS_R&FUNC==SLL|OP==IS_R&FUNC==SRA|
                       OP==IS_R&FUNC==SRL)? sa_extend :
                      (OP==JAL)? current_pc :
                       rdata1;
assign alusrc2_temp = (OP==SLTIU|OP==ADDIU|OP==LUI)? unsigned_extend :
                      (OP==SW|OP==LW|OP==SLTI|OP==ADDI|OP==ANDI|
                       OP==ORI|OP==XORI)? signed_extend :
                      (OP==IS_R)? rdata2 :
                      (OP==JAL)? 32'd8 :
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
assign de_is_load_temp = (OP==LW)? 1:0;
assign wen_temp = (OP==IS_R|OP==ADDIU|OP==ADDI
                   |OP==SLTI|OP==SLTIU|OP==LW|
                   OP==LUI|OP==JAL|OP==ANDI|OP==ORI|OP==XORI)? 1:0;
assign regsrc_temp = (OP==IS_R)? fe_inst[15:11] : //rd
                     (OP==LW|OP==ADDIU|OP==ADDI|OP==SLTI|OP==SLTIU
                     |OP==LUI|OP==ANDI|OP==ORI|OP==XORI)? fe_inst[20:16]: //rt
                     (OP==JAL)? 5'b11111:
                     5'b0;
always @(posedge clk) begin
    de_wen <= wen_temp;
    de_regsrc <= regsrc_temp;
    de_is_load <= de_is_load_temp;
end

//dram
wire [3:0] dramwen_temp;
wire dramen_temp;
assign dramen_temp = (OP==LW|OP==SW)? 1:0;
assign dramwen_temp = (OP==SW)? 4'b1111:4'b0;
always @(posedge clk) begin
    de_dramwen <= dramwen_temp;
    de_dramen <= dramen_temp;
end



endmodule //decode_stage
 