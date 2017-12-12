module mycpu_top(
    input  wire        clk,
    input  wire        resetn,            //low active

    //inst ram
    output wire        inst_req,
    output wire        inst_wr,
    output wire [1:0]  inst_size,
    output wire [31:0] inst_addr,
    output wire [31:0] inst_wdata,
    input  wire        inst_addr_ok,
    input  wire        inst_data_ok,
    input  wire [31:0] inst_rdata,

    input  wire [15:0] btn_key_r,

    //data ram
    output wire        data_req,
    output wire        data_wr,
    output wire [3:0]  data_size,
    output wire [31:0] data_addr,
    output wire [31:0] data_wdata,
    input  wire        data_addr_ok,
    input  wire        data_data_ok,
    input  wire [31:0] data_rdata,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata

);
//pc caculator
wire [31:0] current_pc;
//fe stage
wire [31:0] fe_pc;
wire [31:0] fe_inst;
//data hazard unit
wire stall;
wire [31:0] de_rs_data,de_rt_data;
wire [31:0] reg_rdata1,reg_rdata2;
wire [4:0]  reg_raddr1,reg_raddr2;
wire [4:0]  de_rs_addr,de_rt_addr;
//CP0
wire [31:0] CP0_rdata;
wire [31:0] return_addr;
wire CP0_STATUS_EXL;
wire interupt;
wire CP0_wen;
wire [4:0] CP0_raddr;
wire [4:0] CP0_waddr;
wire [31:0] CP0_wdata;
//pc
wire        de_is_b,de_is_j,de_is_jr;
wire [3:0]  de_b_type;
wire [15:0] de_b_offset;
wire [25:0] de_j_index;
//exe
wire [3:0]  de_aluop;
wire [31:0] de_alusrc1;
wire [31:0] de_alusrc2;
wire        de_mult_en;
wire        de_div_en;
wire        de_is_signed;
wire [31:0] de_MD_src1;
wire [31:0] de_MD_src2;
wire [2:0]  de_store_type;
wire        de_mem_en;
wire [31:0] de_store_rt_data;
//mem
wire        de_reg_en;
wire        de_mem_read;
wire [4:0]  de_reg_waddr;
wire [2:0]  de_load_type;
wire [31:0] de_load_rt_data;
//exe stage
wire [31:0] alu_result;
wire [3:0]  exe_mem_wen;
wire [31:0] exe_mem_wdata;

wire exe_busy;

wire exe_reg_en;
wire exe_mem_read;
wire [4:0] exe_reg_waddr;
wire [31:0] alu_result_reg;
wire exe_MD_complete;
wire [63:0] exe_MD_result;
wire [2:0]  exe_load_type;
wire [31:0] exe_load_rt_data;
//execption
wire return;
wire [5:0] de_exec_vector;
wire [31:0] de_pc;
wire delay_slot;
wire possible_overflow;
wire execption;
wire [4:0] CP0_CAUSE_ExcCode;
wire [31:0] CP0_EPC;
wire [31:0] CP0_BadVaddr;
wire CP0_STATUS_BD;

//wb stage
wire wb_reg_en;
wire [4:0] wb_reg_waddr;
wire [31:0] wb_reg_wdata;
wire wb_MD_complete;
wire [63:0] wb_MD_result;

wire  inst_MEM;
wire  stop;
wire super_execption;
// inst_sram is now a ROM
assign inst_req = 1'b1;
assign inst_wr = 1'b0;
assign inst_size = 2'b11; //to do
assign inst_wdata = 32'b0;

//PC_calculator
PC_calculator PC_calculator
    (
    .clk            (clk            ), 
    .resetn         (resetn         ), 
    .stall          (stall          ),
    .execption      (execption      ),
    .return         (return         ),
    .inst_MEM       (inst_MEM       ),
    .super_execption (super_execption),
//control signals from de stage
    .is_b           (de_is_b        ), 
    .is_j           (de_is_j        ), 
    .is_jr          (de_is_jr       ), 
    .b_type         (de_b_type      ), 
    .b_offset       (de_b_offset    ), 
    .j_index        (de_j_index     ), 
    .return_addr    (return_addr    ),
//data from de stage (forwarded)
    .de_rs_data     (de_rs_data     ), 
    .de_rt_data     (de_rt_data     ),
//outputs
    .pc        (inst_addr      ),
    .current_pc		(current_pc     ),
    .inst_addr_ok   (inst_addr_ok   ),
    .inst_data_ok   (inst_data_ok),
    .stop           (stop)
    );


//fetch instructions
fetch_stage fetch_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ),
    .stall          (stall          ),
    .execption      (super_execption      ),
    .return         (return         ),
//inputs from inst_ram and pc_caculator
    .inst_rdata     (inst_rdata     ), 
    .inst_addr      (current_pc     ), 
    .inst_data_ok   (inst_data_ok   ),
//data to de stage                            
    .fe_pc          (fe_pc          ), 
    .fe_inst        (fe_inst        ),
    .stop           (stop)
    );
    
    wire soft_int;
CP0_regs CP0_coprocessor
    (
    .clk            (clk            ),
    .rstn           (resetn         ),
    .wen            (CP0_wen        ),
    .waddr          (CP0_waddr      ),
    .wdata          (CP0_wdata      ),
    .raddr          (CP0_raddr      ),
    .rdata          (CP0_rdata      ),
    .execption      (execption     ),
    .return         (return),
    .soft_int       (soft_int),
    .CP0_CAUSE_ExcCode(CP0_CAUSE_ExcCode ),
    .CP0_EPC        (CP0_EPC        ),
    //.HW_IP          (               ),
    .CP0_STATUS_BD  (CP0_STATUS_BD  ),
    .CP0_BadVaddr   (CP0_BadVaddr       ),
    .return_addr    (return_addr    ),
    .CP0_STATUS_EXL (CP0_STATUS_EXL ),
    .interupt       (interupt       ),
    .btn_key_r      (btn_key_r)

    );
//Hazard Unit
data_hazard_unit HazardUnit
    (
    .reg_rs_data    (reg_rdata1     ),
    .reg_rt_data    (reg_rdata2     ),
    .de_rs_addr     (de_rs_addr     ),
    .de_rt_addr     (de_rt_addr     ),

    .exe_reg_en     (de_reg_en      ),
    .exe_reg_waddr  (de_reg_waddr   ),
    .exe_reg_wdata  (alu_result     ),
    .exe_mem_read   (de_mem_read    ),
    .exe_busy       (exe_busy       ),

    .mem_reg_en     (exe_reg_en     ),
    .mem_reg_waddr  (exe_reg_waddr  ),
    .mem_reg_wdata  (wb_reg_wdata   ),

    .de_rs_data     (de_rs_data     ),
    .de_rt_data     (de_rt_data     ),
    .stall          (stall          )
    );
//regfile 
reg_file cpu_regfile
    (
    .clk        (clk            ), 
    .rstn       (resetn         ),

    .raddr1     (reg_raddr1     ), 
    .raddr2     (reg_raddr2     ), 
    .rdata1     (reg_rdata1     ), 
    .rdata2     (reg_rdata2     ), 

    .wen        (wb_reg_en       ), 
    .waddr      (wb_reg_waddr    ), 
    .wdata      (wb_reg_wdata    ) 
    );
//decode
decode_stage de_stage
    (
    .clk            (clk            ),
    .resetn         (resetn         ),
    .stall          (stall          ),
    .inst_addr_ok   (inst_addr_ok),
//data from fe stage              
    .fe_inst        (fe_inst        ), 
    .fe_pc          (fe_pc          ),
//data to regfile
    .fe_rs_addr     (reg_raddr1     ), //from Hazard Unit, which is correct
    .fe_rt_addr     (reg_raddr2     ),
//data from mult and div
    .wb_MD_complete (wb_MD_complete ),
    .wb_MD_result   (wb_MD_result   ),
//data to CP0_regs
    .CP0_wen        (CP0_wen        ),
    .CP0_raddr      (CP0_raddr      ),
    .CP0_waddr      (CP0_waddr      ),
    .CP0_rdata      (CP0_rdata      ),
    .CP0_wdata      (CP0_wdata      ),
//data to and from hazard unit
    .de_rs_addr     (de_rs_addr     ),
    .de_rt_addr     (de_rt_addr     ),
    .de_rs_data     (de_rs_data     ),
    .de_rt_data     (de_rt_data     ),
//data to pc caculator                               
    .de_is_b        (de_is_b        ),
    .de_is_j        (de_is_j        ), 
    .de_is_jr       (de_is_jr       ),
    .de_b_type      (de_b_type      ),                                    
    .de_b_offset    (de_b_offset    ),
    .de_j_index     (de_j_index     ),
//signal for exe stage
    .de_aluop       (de_aluop       ),
    .de_alusrc1     (de_alusrc1     ),                                 
    .de_alusrc2     (de_alusrc2     ),
    .de_mult_en     (de_mult_en     ),
    .de_div_en      (de_div_en      ),
    .de_is_signed   (de_is_signed   ),
    .de_MD_src1     (de_MD_src1     ),
    .de_MD_src2     (de_MD_src2     ),
    .de_store_type  (de_store_type  ),
//signal for meme stage
    .de_mem_en      (de_mem_en      ),
    .de_store_rt_data(de_store_rt_data ), 
//signal for wb stage
    .de_reg_en      (de_reg_en      ),
    .de_mem_read    (de_mem_read    ),
    .de_reg_waddr   (de_reg_waddr   ),
    .de_load_type   (de_load_type   ),
    .de_load_rt_data(de_load_rt_data),
//siganl for execption and return
    .execption      (super_execption     ),
    .return         (return         ),
    .de_exec_vector (de_exec_vector ),
    .de_pc          (de_pc          ),
    .delay_slot     (delay_slot     ),
    .possible_overflow (possible_overflow),
    .stop           (stop           ),
    .inst_MEM       (inst_MEM       )
    );


//exec
execute_stage exe_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ), 
    .soft_int       (soft_int),
//used in this stage                          
    .de_aluop       (de_aluop       ), 
    .de_alusrc1     (de_alusrc1     ), 
    .de_alusrc2     (de_alusrc2     ), 
    .de_mult_en     (de_mult_en     ),
    .de_div_en      (de_div_en      ),
    .de_is_signed   (de_is_signed   ),
    .de_MD_src1     (de_MD_src1     ),
    .de_MD_src2     (de_MD_src2     ),
//data from de stage
    .de_reg_en      (de_reg_en      ),
    .de_mem_read    (de_mem_read    ),
    .de_reg_waddr   (de_reg_waddr   ),
    .de_load_type   (de_load_type   ),
    .de_load_rt_data(de_load_rt_data),
    .de_store_type  (de_store_type  ),
    .de_store_rt_data(de_store_rt_data),
//data to mem stage
    .alu_result     (alu_result     ),
    .exe_mem_wen    (exe_mem_wen    ),
    .exe_mem_wdata  (exe_mem_wdata  ),
//data to hazard unit
    .exe_busy       (exe_busy       ),
//data to wbstage
    .exe_reg_en     (exe_reg_en     ),
    .exe_mem_read   (exe_mem_read   ),
    .exe_reg_waddr  (exe_reg_waddr  ),
    .alu_result_reg (alu_result_reg ),
    .exe_MD_complete(exe_MD_complete ),
    .exe_MD_result  (exe_MD_result  ),
    .exe_load_type  (exe_load_type  ),
    .exe_load_rt_data(exe_load_rt_data),
//data for execption
    .execption        (execption        ),
    .CP0_CAUSE_ExcCode(CP0_CAUSE_ExcCode),
    .CP0_EPC          (CP0_EPC          ),
    .CP0_BadVaddr     (CP0_BadVaddr     ),
    .CP0_STATUS_BD    (CP0_STATUS_BD    ),
    .de_exec_vector   (de_exec_vector   ),
    .de_pc            (de_pc            ),
    .delay_slot       (delay_slot       ),
    .possible_overflow(possible_overflow),
    .interupt         (interupt         ),
    .CP0_STATUS_EXL   (CP0_STATUS_EXL   ),
    .stop             (stop),
    .data_data_ok     (data_data_ok),
    .data_addr_ok     (data_addr_ok),
    .de_mem_en        (de_mem_en)
    );


//mem
memory_stage mem_stage
    (
    .clk                (clk            ), 
    .resetn             (resetn         ),
    .execption          (execption      ),
//data from de stage and exe stage
    .de_mem_en          (de_mem_en      ),                       
    .exe_mem_wen        (exe_mem_wen    ),
    .exe_mem_addr       (alu_result     ), 
    .exe_mem_wdata      (exe_mem_wdata  ),
    .data_req(data_req),
    .data_wr(data_wr),
    .data_size(data_size),
    .data_addr(data_addr),
    .data_wdata (data_wdata) 

    );

//wb
writeback_stage wb_stage
    (
    .clk            (clk             ), 
    .resetn         (resetn          ),
    .stop           (stop            ),
//data from exe stage and mem stage
    .exe_reg_en     (exe_reg_en     ),
    .exe_reg_waddr  (exe_reg_waddr  ),
    .exe_mem_read   (exe_mem_read   ),
    .alu_result_reg (alu_result_reg ),
    .mem_rdata      (data_rdata     ),
    .exe_MD_complete(exe_MD_complete ),
    .exe_MD_result  (exe_MD_result  ),
    .exe_load_type  (exe_load_type  ),
    .exe_load_rt_data(exe_load_rt_data),
//data to regfile
    .wb_reg_en      (wb_reg_en      ),
    .wb_reg_waddr   (wb_reg_waddr   ),
    .wb_reg_wdata   (wb_reg_wdata   ),
    .wb_MD_complete (wb_MD_complete  ),
    .wb_MD_result   (wb_MD_result   )
    );


//debug signals
reg [31:0] des_pc;
reg [31:0] exe_pc;
always @ (posedge clk)
begin
	des_pc <= fe_pc;
	exe_pc <= de_pc;
end
assign debug_wb_pc = exe_pc;
assign debug_wb_rf_wdata = wb_reg_wdata;
assign debug_wb_rf_wnum = wb_reg_waddr;
assign debug_wb_rf_wen = (wb_reg_en)? 4'b1111:4'b0000;




endmodule //mycpu_top
