

module execute_stage(
    input  wire        clk,
    input  wire        resetn,
    output wire        stop,
    input  wire        soft_int,
//data ram 
    input  wire        data_addr_ok,
    input  wire        data_data_ok,
//data used in this stage
    input  wire [3:0]  de_aluop,
    input  wire [31:0] de_alusrc1,
    input  wire [31:0] de_alusrc2,
    input  wire        de_mult_en,
    input  wire        de_div_en,
    input  wire        de_is_signed,
    input  wire [31:0] de_MD_src1,
    input  wire [31:0] de_MD_src2,
    input  wire        de_mem_en, //new
//data from de stage not used in this stage
    input  wire        de_reg_en,
    input  wire        de_mem_read,
    input  wire [4:0]  de_reg_waddr,
    input  wire [2:0]  de_load_type,
    input  wire [31:0] de_load_rt_data,
    input  wire [2:0]  de_store_type,
    input  wire [31:0] de_store_rt_data,
//data to mem stage
    output wire [31:0] alu_result,
    output wire [3:0]  exe_mem_wen,
    output wire [31:0] exe_mem_wdata,
//data to data hazard unit
    output wire        exe_busy,
//data to wb stage 
    output reg         exe_reg_en,
    output reg         exe_mem_read,
    output reg  [4:0]  exe_reg_waddr,
    output reg  [31:0] alu_result_reg,
    output wire        exe_MD_complete,
    output wire [63:0] exe_MD_result,
    output reg  [2:0]  exe_load_type,
    output reg  [31:0] exe_load_rt_data,
//data for execption
    output wire execption,
    output wire [4:0]  CP0_CAUSE_ExcCode,
    output wire [31:0] CP0_EPC,
    output wire [31:0] CP0_BadVaddr,
    output wire CP0_STATUS_BD,
    input  wire [5:0]  de_exec_vector,
    input  wire [31:0] de_pc,
    input  wire  delay_slot,
    input  wire  possible_overflow,
    input  wire  interupt,
    input  wire  CP0_STATUS_EXL
);
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

//signals for execption
//execption vector
// interupt  BadVaddr  Reservation  Overflow   Syscall   Break
//     5        4           3          2          1        0
wire [5:0] exe_exec_vector;
wire Overflow;
wire exec_Overflow;
wire exec_BadLoad;
wire exec_BadStore;
assign exec_Overflow = possible_overflow & Overflow;

assign exec_BadLoad  = (de_load_type  == type_LW  & alu_result[1:0] !== 2'b00) |
                       (de_load_type  == type_LH  & alu_result[0]   !== 1'b0 ) |
                       (de_load_type  == type_LHU & alu_result[0]   !== 1'b0 );

assign exec_BadStore = (de_store_type == type_SW  & alu_result[1:0] !== 2'b00) |
                       (de_store_type == type_SH  & alu_result[0]   !== 1'b0 );

assign exe_exec_vector[5] = interupt;

assign exe_exec_vector[4] = de_exec_vector[4] | exec_BadStore | exec_BadLoad;

assign exe_exec_vector[3] = de_exec_vector[3];

assign exe_exec_vector[2] = exec_Overflow;

assign exe_exec_vector[1] = de_exec_vector[1];

assign exe_exec_vector[0] = de_exec_vector[0];

assign CP0_STATUS_BD        = delay_slot;

assign CP0_BadVaddr         = (de_exec_vector[4])? de_pc : alu_result;

assign execption            = (|exe_exec_vector) & (~CP0_STATUS_EXL) & (~exe_busy);

assign CP0_EPC              = (delay_slot)? de_pc - 32'd4 : 
                              (soft_int)?   de_pc  + 32'd4:
                              de_pc;

assign CP0_CAUSE_ExcCode    = (exe_exec_vector[5]) ? 5'h00:
                              (exe_exec_vector[4]) ? ((exec_BadStore) ? 5'h05 : 5'h04):
                              (exe_exec_vector[3]) ? 5'h0a:
                              (exe_exec_vector[2]) ? 5'h0c:
                              (exe_exec_vector[1]) ? 5'h08:
                              (exe_exec_vector[0]) ? 5'h09:
                             5'b0;

//signals for mult and div
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
    .ALUop    ( de_aluop    ), 
    .A        ( de_alusrc1  ), 
    .B        ( de_alusrc2  ), 
    .Result   ( alu_result  ), 
    .Overflow ( Overflow    )
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
assign exe_mem_wen   = (execption)?  4'b0000:
                        (de_store_type == type_SW) ? 4'b1111 : 
                       (de_store_type == type_SB) ? SB_men_wen  :
                       (de_store_type == type_SH) ? SH_mem_wen  :
                       (de_store_type == type_SWL)? SWL_mem_wen :
                       (de_store_type == type_SWR)? SWR_mem_wen : 4'b0000;

assign exe_mem_wdata = (de_store_type == type_SW) ? de_store_rt_data : 
                       (de_store_type == type_SB) ? SB_mem_wdata     :
                       (de_store_type == type_SH) ? SH_mem_wdata     :
                       (de_store_type == type_SWL)? SWL_mem_wdata    :
                       (de_store_type == type_SWR)? SWR_mem_wdata    : 32'b0;
reg exe_mem_en;

always @(posedge clk) begin
if(~resetn) begin
alu_result_reg   <= 'b0;
exe_reg_en       <= 'b0;
exe_reg_waddr    <= 'b0;
exe_mem_read     <= 'b0;
exe_load_type    <= 'b0;
exe_load_rt_data <= 'b0;
exe_mem_en       <= 'b0;
end
else if(stop) begin
    alu_result_reg   <= alu_result_reg;
    exe_reg_en       <= exe_reg_en;
    exe_reg_waddr    <= exe_reg_waddr;
    exe_mem_read     <= exe_mem_read;
    exe_load_type    <= exe_load_type;
    exe_load_rt_data <= exe_load_rt_data;
    exe_mem_en       <= exe_mem_en;
end
else begin
    alu_result_reg   <= alu_result;
    exe_reg_en       <= de_reg_en &(~execption);
    exe_reg_waddr    <= de_reg_waddr;
    exe_mem_read     <= de_mem_read;
    exe_load_type    <= de_load_type;
    exe_load_rt_data <= de_load_rt_data;
    exe_mem_en       <= de_mem_en&(~execption);
end
end
wire super_dememen;
assign super_dememen = de_mem_en & (~execption);

assign stop = (super_dememen & ~data_addr_ok) | (exe_mem_en & ~data_data_ok);


endmodule //execute_stage
