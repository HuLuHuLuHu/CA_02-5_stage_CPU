module decode_stage(
    input  wire        clk,
    input  wire        resetn,
    input  wire        stall,
//data from fe stage
    input  wire [31:0] fe_inst,
    input  wire [31:0] fe_pc,
//data to regfile
    output wire [4:0]  fe_rs_addr,
    output wire [4:0]  fe_rt_addr,
//data from mult and div
    input  wire wb_MD_complete,
    input  wire [63:0] wb_MD_result,
//data to CP0_regs
    output wire CP0_wen,
    output wire [4:0]  CP0_raddr,
    output wire [4:0]  CP0_waddr,
    input  wire [31:0] CP0_rdata,
    output wire [31:0] CP0_wdata,
//data to and from hazard unit
    output wire [4:0]  de_rs_addr,
    output wire [4:0]  de_rt_addr,
    input  wire [31:0] de_rs_data, //forwarded
    input  wire [31:0] de_rt_data, //forwarded
//signal for pc caculator
    output wire        de_is_b,
    output wire        de_is_j,  
    output wire        de_is_jr,
    output wire [3:0]  de_b_type,     
    output wire [15:0] de_b_offset, 
    output wire [25:0] de_j_index,   
//signal for exe stage
    output reg  [3:0]  de_aluop,
    output reg  [31:0] de_alusrc1,
    output reg  [31:0] de_alusrc2,
    output wire        de_mult_en,
    output wire        de_div_en,
    output wire        de_is_signed,
    output wire [31:0] de_MD_src1,
    output wire [31:0] de_MD_src2,
    output reg  [2:0]  de_store_type,
//signal for mem stage
    output reg         de_mem_en,
    output reg  [31:0] de_store_rt_data,
//signal for wb stage
    output reg         de_reg_en,
    output reg         de_mem_read,
    output reg  [4:0]  de_reg_waddr,
    output reg  [2:0]  de_load_type,
    output reg  [31:0] de_load_rt_data,
//execption signals
    input  wire  execption,
    output wire  return,
    output reg   [5:0]  de_exec_vector, //detect some execptions
    output reg   [31:0] de_pc,
    output reg   delay_slot,
    output reg   possible_overflow
);

wire [5:0] OP;    assign OP         = fe_inst[31:26];
wire [5:0] FUNC;  assign FUNC       = fe_inst[5:0];
//B-type
wire inst_J;        assign inst_J     = (OP == 6'b000010);
wire inst_JAL;      assign inst_JAL   = (OP == 6'b000011);
wire inst_BEQ;      assign inst_BEQ   = (OP == 6'b000100);
wire inst_BNE;      assign inst_BNE   = (OP == 6'b000101);
wire inst_BGTZ;     assign inst_BGTZ  = (OP == 6'b000111);
wire inst_BLEZ;     assign inst_BLEZ  = (OP == 6'b000110);
wire inst_BGEZ;     assign inst_BGEZ  = (OP == 6'b000001 & fe_inst[20:16] == 5'b00001);
wire inst_BLTZ;     assign inst_BLTZ  = (OP == 6'b000001 & fe_inst[20:16] == 5'b00000);
wire inst_BLTZAL;   assign inst_BLTZAL= (OP == 6'b000001 & fe_inst[20:16] == 5'b10000);
wire inst_BGEZAL;   assign inst_BGEZAL= (OP == 6'b000001 & fe_inst[20:16] == 5'b10001);

//I-type
wire inst_ADDIU;    assign inst_ADDIU = (OP == 6'b001001);
wire inst_ADDI;     assign inst_ADDI  = (OP == 6'b001000);
wire inst_SLTI;     assign inst_SLTI  = (OP == 6'b001010);
wire inst_SLTIU;    assign inst_SLTIU = (OP == 6'b001011);
wire inst_LUI;      assign inst_LUI   = (OP == 6'b001111);
wire inst_ANDI;     assign inst_ANDI  = (OP == 6'b001100);
wire inst_ORI;      assign inst_ORI   = (OP == 6'b001101);
wire inst_XORI;     assign inst_XORI  = (OP == 6'b001110);
//Load
wire inst_LW;       assign inst_LW    = (OP == 6'b100011);
wire inst_LB;       assign inst_LB    = (OP == 6'b100000);
wire inst_LBU;      assign inst_LBU   = (OP == 6'b100100);
wire inst_LH;       assign inst_LH    = (OP == 6'b100001);
wire inst_LHU;      assign inst_LHU   = (OP == 6'b100101);
wire inst_LWL;      assign inst_LWL   = (OP == 6'b100010);
wire inst_LWR;      assign inst_LWR   = (OP == 6'b100110);
wire inst_LOAD;     assign inst_LOAD  = (inst_LW|inst_LB|inst_LBU|inst_LH|inst_LHU|inst_LWL|inst_LWR);
//Store
wire inst_SW;       assign inst_SW    = (OP == 6'b101011);
wire inst_SB;       assign inst_SB    = (OP == 6'b101000);
wire inst_SH;       assign inst_SH    = (OP == 6'b101001);
wire inst_SWL;      assign inst_SWL   = (OP == 6'b101010);
wire inst_SWR;      assign inst_SWR   = (OP == 6'b101110);
wire inst_STORE;    assign inst_STORE = (inst_SW|inst_SB|inst_SH|inst_SWL|inst_SWL|inst_SWR);
//R-type inst
wire inst_R;        assign inst_R     = (OP == 6'b000000);
wire inst_ADD;      assign inst_ADD   = (inst_R & FUNC == 6'b100000);
wire inst_OR;       assign inst_OR    = (inst_R & FUNC == 6'b100101);
wire inst_SLT;      assign inst_SLT   = (inst_R & FUNC == 6'b101010);
wire inst_ADDU;     assign inst_ADDU  = (inst_R & FUNC == 6'b100001);
wire inst_SUB;      assign inst_SUB   = (inst_R & FUNC == 6'b100010);
wire inst_SLL;      assign inst_SLL   = (inst_R & FUNC == 6'b000000);
wire inst_JR;       assign inst_JR    = (inst_R & FUNC == 6'b001000);
wire inst_AND;      assign inst_AND   = (inst_R & FUNC == 6'b100100);
wire inst_SLTU;     assign inst_SLTU  = (inst_R & FUNC == 6'b101011);
wire inst_SUBU;     assign inst_SUBU  = (inst_R & FUNC == 6'b100011);
wire inst_NOR;      assign inst_NOR   = (inst_R & FUNC == 6'b100111);
wire inst_XOR;      assign inst_XOR   = (inst_R & FUNC == 6'b100110);
wire inst_SRA;      assign inst_SRA   = (inst_R & FUNC == 6'b000011);
wire inst_SLLV;     assign inst_SLLV  = (inst_R & FUNC == 6'b000100);
wire inst_SRL;      assign inst_SRL   = (inst_R & FUNC == 6'b000010);
wire inst_SRAV;     assign inst_SRAV  = (inst_R & FUNC == 6'b000111);
wire inst_SRLV;     assign inst_SRLV  = (inst_R & FUNC == 6'b000110);
wire inst_JALR;     assign inst_JALR  = (inst_R & FUNC == 6'b001001);
//Mult and Div
wire inst_DIV;      assign inst_DIV   = (inst_R & FUNC == 6'b011010);
wire inst_DIVU;     assign inst_DIVU  = (inst_R & FUNC == 6'b011011);
wire inst_MULT;     assign inst_MULT  = (inst_R & FUNC == 6'b011000);
wire inst_MULTU;    assign inst_MULTU = (inst_R & FUNC == 6'b011001);
//Move
wire inst_MFHI;     assign inst_MFHI  = (inst_R & FUNC == 6'b010000);
wire inst_MFLO;     assign inst_MFLO  = (inst_R & FUNC == 6'b010010);
wire inst_MTHI;     assign inst_MTHI  = (inst_R & FUNC == 6'b010001);
wire inst_MTLO;     assign inst_MTLO  = (inst_R & FUNC == 6'b010011);
wire inst_MTC0;     assign inst_MTC0  = (OP == 6'b010000 & fe_inst[25:21] == 5'b00100 &fe_inst[10:3] == 8'b00000000);
wire inst_MFC0;     assign inst_MFC0  = (OP == 6'b010000 & fe_inst[25:21] == 5'b00000 &fe_inst[10:3] == 8'b00000000);
wire inst_MF;       assign inst_MF    = (inst_MFLO | inst_MFHI | inst_MFC0 );
//exeptions
wire inst_SYSCALL;   assign inst_SYSCALL = (inst_R & FUNC == 6'b001100);
wire inst_ERET;      assign inst_ERET    = (fe_inst == 32'b01000010000000000000000000011000);
wire inst_BREAK;     assign inst_BREAK   = (inst_R & FUNC == 6'b001101);
//a J-type or B-type inst
wire inst_JB;       assign inst_JB    = inst_J   | inst_JAL   |inst_JR    | inst_BEQ  |
                                        inst_BNE | inst_BGTZ  |inst_BLEZ  | inst_BGEZ |
                                        inst_BLTZ| inst_BLTZAL|inst_BGEZAL| inst_JALR;
                                        
wire is_inst;
assign is_inst  =  
inst_J    |inst_JAL     |inst_BEQ   |inst_BNE  |inst_BGTZ |inst_BLEZ |inst_BGEZ |inst_BLTZ |inst_BLTZAL|inst_LB   |
inst_BGEZAL|inst_ADDIU   |inst_ADDI  |inst_SLTI |inst_SLTIU|inst_LUI  |inst_ANDI |inst_ORI  |inst_XORI |inst_LW   |
inst_LBU  |inst_LH      |inst_LHU   |inst_LWL  |inst_LWR  |inst_LOAD |inst_SW   |inst_SB   |inst_SH   |inst_SWL  |
inst_SWR  |inst_STORE   |inst_BREAK |inst_ADD  |inst_OR   |inst_SLT  |inst_ADDU |inst_SUB  |inst_SLL  |inst_JR   |
inst_AND  |inst_SLTU    |inst_SUBU  |inst_NOR  |inst_XOR  |inst_SRA  |inst_SLLV |inst_SRL  |inst_SRAV |inst_SRLV |
inst_JALR |inst_DIV     |inst_DIVU  |inst_MULT |inst_MULTU|inst_MFHI |inst_MFLO |inst_MTHI |inst_MTLO |inst_MTC0 |
inst_MFC0 |inst_SYSCALL |inst_ERET ;
//define b-type
parameter type_BNE    = 4'b0000;
parameter type_BEQ    = 4'b0001;
parameter type_BGEZ   = 4'b0010;
parameter type_BGTZ   = 4'b0011;
parameter type_BLEZ   = 4'b0100;
parameter type_BLTZ   = 4'b0101;
parameter type_BLTZAL = 4'b0110;
parameter type_BGEZAL = 4'b0111;
//define load-type
parameter type_LW     = 3'b000;
parameter type_LB     = 3'b001;
parameter type_LBU    = 3'b010;
parameter type_LH     = 3'b011;
parameter type_LHU    = 3'b100;
parameter type_LWL    = 3'b101;
parameter type_LWR    = 3'b110;
//define store-type
parameter type_SW     = 3'b000;
parameter type_SB     = 3'b001;
parameter type_SH     = 3'b010;
parameter type_SWL    = 3'b011;
parameter type_SWR    = 3'b100;
//define ALU OP
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

//data to regfiles
assign fe_rs_addr = fe_inst[25:21];

assign fe_rt_addr = fe_inst[20:16];

//signals for mult and div inst
reg  [31:0] reg_HI;
reg  [31:0] reg_LO;

always @(posedge clk) begin
  if      (inst_MTHI)  reg_HI <= de_rs_data;
  else if (inst_MTLO)  reg_LO <= de_rs_data;
  else if (wb_MD_complete) {reg_HI,reg_LO} <= wb_MD_result;
  else;
end

//signals for CP0 registers to implement mfc0 and mtc0
assign CP0_wen   = inst_MTC0;

assign CP0_waddr = fe_inst[15:11];

assign CP0_wdata = de_rt_data;

assign CP0_raddr = fe_inst[15:11];

//signals for execption detection and return
assign return = inst_ERET;

//execption vector
// interupt  BadVaddr  Reservation  Overflow   Syscall   Break
//     5        4           3          2          1        0
reg reg_JB;
always @(posedge clk) begin
  de_pc             <= fe_pc;
  reg_JB            <= inst_JB;
  delay_slot        <= reg_JB;
  possible_overflow <= inst_ADDI | inst_ADD |inst_SUB;
  de_exec_vector[5] <= 0;
  de_exec_vector[4] <= ~(fe_pc[1:0] == 2'b00);
  de_exec_vector[3] <= ~is_inst; //what to fill?
  de_exec_vector[2] <= 0;
  de_exec_vector[1] <= inst_SYSCALL;
  de_exec_vector[0] <= inst_BREAK; 
end



//data to hazard unit
assign de_rs_addr = (inst_SLL| inst_SRA | inst_SRL | inst_JAL)    ? 5'd0 : fe_rs_addr;

assign de_rt_addr = (inst_R  | inst_BNE | inst_BEQ | inst_STORE | inst_MTC0) ? fe_rt_addr : 5'd0;

//data for pc caculator
assign de_b_offset= fe_inst[15:0];

assign de_j_index = fe_inst[25:0];

assign de_is_jr   = (inst_JR | inst_JALR) ? 1:0;

assign de_is_j    = (inst_J  | inst_JAL ) ? 1:0;

assign de_is_b    = (inst_BEQ  | inst_BNE  | inst_BGEZ   | inst_BGTZ  |
                     inst_BLEZ | inst_BLTZ | inst_BLTZAL | inst_BGEZAL ) ? 1:0;

assign de_b_type  = (inst_BEQ   ) ? type_BEQ :
                    (inst_BNE   ) ? type_BNE : 
                    (inst_BGEZ  ) ? type_BGEZ:
                    (inst_BGTZ  ) ? type_BGTZ:
                    (inst_BLEZ  ) ? type_BLEZ:
                    (inst_BLTZ  ) ? type_BLTZ:
                    (inst_BLTZAL) ? type_BLTZAL:
                    (inst_BGEZAL) ? type_BGEZAL:
                     4'b0000;

//data for exe stage
wire [31:0] sa_extend;
wire [31:0] signed_extend;
wire [31:0] unsigned_extend;

wire [3:0]  aluop_temp;
wire [31:0] alusrc1_temp;
wire [31:0] alusrc2_temp;

wire [2:0] store_type_temp;

assign de_mult_en      = (inst_MULT | inst_MULTU) & (~execption) ;

assign de_div_en       = (inst_DIV  | inst_DIVU) & (~execption);

assign de_is_signed    = inst_MULT | inst_DIV;

assign de_MD_src1      = de_rs_data;

assign de_MD_src2      = de_rt_data;

assign sa_extend       = {27'b0,fe_inst[10:6]};

assign signed_extend   = {{16{fe_inst[15]}},fe_inst[15:0]};

assign unsigned_extend = {16'b0,fe_inst[15:0]};

assign aluop_temp   = (inst_NOR ) ? alu_NOR :
                      (inst_LUI ) ? alu_LUI :
                      (inst_SLT   | inst_SLTI ) ? alu_SLT :
                      (inst_SLTIU | inst_SLTU ) ? alu_SLTU:
                      (inst_SUB   | inst_SUBU ) ? alu_SUB :
                      (inst_OR    | inst_ORI  ) ? alu_OR  :
                      (inst_AND   | inst_ANDI ) ? alu_AND :
                      (inst_SLL   | inst_SLLV ) ? alu_SLL : 
                      (inst_XOR   | inst_XORI ) ? alu_XOR :
                      (inst_SRA   | inst_SRAV ) ? alu_SRA :
                      (inst_SRL   | inst_SRLV ) ? alu_SRL :
                      (inst_ADDI  | inst_ADDIU | inst_LOAD | inst_STORE  |
                       inst_ADD   | inst_ADDU  | inst_JAL  | inst_BLTZAL | 
                       inst_BGEZAL| inst_JALR  | inst_MF    ) ? alu_ADD : 4'b0000;

assign alusrc1_temp = (inst_MFHI) ? reg_HI :
                      (inst_MFLO) ? reg_LO :
                      (inst_MFC0) ? CP0_rdata :
                      (inst_SLL  | inst_SRA    | inst_SRL   ) ? sa_extend : 
                      (inst_JAL  | inst_BLTZAL | inst_BGEZAL | inst_JALR) ? fe_pc : de_rs_data;

assign alusrc2_temp = (inst_JALR ) ? 32'd8:
                      (inst_R    | inst_DIVU   | inst_DIV    | inst_MULT  | inst_MULTU) ? de_rt_data :
                      (inst_ORI  | inst_XORI   | inst_ANDI  ) ? unsigned_extend :
                      (inst_JAL  | inst_BGEZAL | inst_BLTZAL ) ? 32'd8 :
                      (inst_STORE| inst_LOAD   | inst_SLTI   | inst_ADDI  |
                       inst_SLTIU| inst_ADDIU  | inst_LUI   ) ? signed_extend : 32'b0; 

assign store_type_temp = (inst_SW) ? type_SW:
                         (inst_SB) ? type_SB:
                         (inst_SH) ? type_SH:
                         (inst_SWL)? type_SWL:
                         (inst_SWR)? type_SWR:3'b111;

always @(posedge clk) begin
    de_aluop   <= aluop_temp;
    de_alusrc1 <= alusrc1_temp;
    de_alusrc2 <= alusrc2_temp;
    de_store_type <= store_type_temp;
end


//data for mem stage
wire mem_en_temp;

assign mem_en_temp  = (~stall) & (~execption) & (inst_LOAD  | inst_STORE );

always @(posedge clk) begin
    de_mem_en    <= mem_en_temp; 
    de_store_rt_data <= de_rt_data;
end

//data for wb stage
wire reg_en_temp;
wire mem_read_temp;
wire [5:0] reg_waddr_temp;
wire [2:0] load_type_temp;
wire [31:0]load_rt_data_temp;

assign mem_read_temp  = (inst_LOAD) ? 1 : 0;

assign reg_en_temp    = (~stall) & (~execption)
                        & (inst_R     | inst_ADDIU | inst_ADDI  |
                          inst_SLTI  | inst_SLTIU | inst_LOAD  |
                          inst_LUI   | inst_JAL   | inst_ANDI  |
                          inst_ORI   | inst_XORI  | inst_BGEZAL|
                          inst_BLTZAL| inst_JALR  | inst_MF);

assign reg_waddr_temp = (inst_R    | inst_JALR  | inst_MFHI| inst_MFLO) ? fe_inst[15:11] : //rd
                        (inst_JAL  | inst_BGEZAL| inst_BLTZAL) ? 5'd31:
                        (inst_LOAD | inst_ADDIU | inst_ADDI| inst_SLTI | inst_SLTIU |
                         inst_LUI  | inst_ANDI  | inst_ORI | inst_XORI | inst_MFC0 ) ? fe_rt_addr: 6'b0; //rt

assign load_rt_data_temp = de_rt_data;

assign load_type_temp = (inst_LW) ? type_LW:
                        (inst_LB) ? type_LB:
                        (inst_LBU)? type_LBU:
                        (inst_LH) ? type_LH:
                        (inst_LHU)? type_LHU:
                        (inst_LWL)? type_LWL:
                        (inst_LWR)? type_LWR:3'b111;

always @(posedge clk) begin
    de_reg_en    <= reg_en_temp;
    de_mem_read  <= mem_read_temp;
    de_reg_waddr <= reg_waddr_temp;
    de_load_type <= load_type_temp;
    de_load_rt_data <= load_rt_data_temp;
end


endmodule //decode_stage
 