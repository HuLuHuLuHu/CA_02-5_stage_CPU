


module mycpu_top(
    input  wire        clk,
    input  wire        resetn,            //low active

    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata

);
wire de_is_b,de_is_j,de_is_jr;
wire [3:0] de_b_type;
wire [15:0] de_b_offset;
wire [25:0] de_j_index;
wire [3:0] de_aluop;
wire [31:0] de_alusrc1;
wire [31:0] de_alusrc2;
wire [31:0] rt_reg_content;
wire de_dramen;
wire [3:0] de_dramwen;
wire de_wen;
wire [4:0] de_regsrc;
wire de_is_load;

wire [31:0] current_pc;
wire [31:0] fe_pc;
wire [31:0] fe_inst;
wire [31:0] alu_result;
wire [31:0] alu_result_reg;
wire exe_is_load;
wire [4:0] exe_regsrc;
wire exe_wen;
wire [31:0] reg_rdata1,reg_rdata2,reg_wdata;
wire [4:0] reg_raddr1,reg_raddr2,reg_waddr;
wire        reg_wen;
wire wb_wen;
wire [4:0] wb_regsrc;
wire [31:0] wb_regwdata;
wire [4:0] forward_rs;
wire [4:0] forward_rt;
wire [31:0] rs_data;
wire [31:0] rt_data;
wire stall;
// inst_sram is now a ROM
assign inst_sram_wen   = 4'b0;
assign inst_sram_wdata = 32'b0;


//PC_calculator
PC_calculator PC_calculator
    (
    .resetn         (resetn         ), 
    .clk            (clk            ), 
    //control signals from control block
    .is_b           (de_is_b        ), 
    .is_j           (de_is_j        ), 
    .is_jr          (de_is_jr       ), 
    .b_type         (de_b_type      ), 
    .b_offset       (de_b_offset    ), 
    .j_index        (de_j_index     ), 
    //data from reg_flie
    .rdata1         (reg_rdata1     ), 
    .rdata2         (reg_rdata2     ),
    //outputs
    .inst_sram_en   (inst_sram_en   ),
    .next_pc        (inst_sram_addr ),
    .current_pc		(current_pc     ),
    //stall
    .stall          (stall)
    );


//fetch instructions
fetch_stage fetch_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ),
    //inputs from inst_sram and pc_reg
    .inst_sram_rdata(inst_sram_rdata), 
    .inst_sram_addr (current_pc     ), 
    //outputs                              
    .fe_pc          (fe_pc          ), 
    .fe_inst        (fe_inst        ),
    //stall
    .stall          (stall)
    );

//Hazard Unit
HazardUnit HazardUnit
    (
    .de_rs_data(reg_rdata1),
    .de_rt_data(reg_rdata2),
    .exe_wen(de_wen),
    .exe_regsrc(de_regsrc),
    .exe_wdata(alu_result),
    .exe_memread(de_is_load),
    .mem_wen(wb_wen),
    .mem_regsrc(wb_regsrc),
    .mem_wdata(wb_regwdata),
    .forward_rs(forward_rs),
    .forward_rt(forward_rt),
    .rs_data(rs_data),
    .rt_data(rt_data),
    .stall(stall)
    );
//decode
decode_stage de_stage
    (
    .clk            (clk            ),
    .resetn         (resetn         ),
    //inputs                       
    .fe_inst        (fe_inst        ), 
    .current_pc     (fe_pc          ),
    .rdata1         (rs_data        ), //from Hazard Unit, which is correct
    .rdata2         (rt_data        ),
    //outputs                                 
    .de_is_b        (de_is_b        ),
    .de_is_j        (de_is_j        ), 
    .de_is_jr       (de_is_jr       ),
    .de_b_type      (de_b_type      ),                                    
    .de_b_offset    (de_b_offset    ),
    .de_j_index     (de_j_index     ),
    .raddr1         (reg_raddr1     ),
    .raddr2         (reg_raddr2     ),
    .rt_reg_content (rt_reg_content ),
    .de_aluop       (de_aluop       ),
    .de_alusrc1     (de_alusrc1     ),                                 
    .de_alusrc2     (de_alusrc2     ),
    .de_dramen      (de_dramen      ),
    .de_dramwen     (de_dramwen     ), 
    .de_wen         (de_wen         ), 
    .de_regsrc      (de_regsrc      ),
    .de_is_load     (de_is_load     ),

    //stall
    .stall          (stall),
    .forward_rs     (forward_rs),
    .forward_rt     (forward_rt)
    );


//exec
execute_stage exe_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ), 
    //used in this stage                          
    .de_aluop       (de_aluop       ), 
    .de_alusrc1     (de_alusrc1     ), 
    .de_alusrc2     (de_alusrc2     ), 
    .alu_result     (alu_result     ), 
    //just pass to next stage
    .de_wen         (de_wen         ), 
    .de_regsrc      (de_regsrc      ),
    .de_is_load     (de_is_load     ), 
    //outputs
    .exe_wen        (exe_wen        ),
    .exe_regsrc     (exe_regsrc     ),
    .exe_is_load    (exe_is_load    ),
    .alu_result_reg (alu_result_reg )
    );


//mem
memory_stage mem_stage
    (
    .clk                (clk            ), 
    .resetn             (resetn         ),
    //inputs                         
    .alu_result         (alu_result     ), 
    .rt_reg_content     (rt_reg_content ),
    .de_dramen          (de_dramen      ),                       
    .de_dramwen         (de_dramwen     ),
    //outputs, there is no registers in this stage           
    .data_sram_addr     (data_sram_addr ),
    .data_sram_wdata    (data_sram_wdata),
    .data_sram_wen      (data_sram_wen  ),
    .data_sram_en       (data_sram_en   )
    );

//wb
writeback_stage wb_stage
    (
    .clk            (clk             ), 
    .resetn         (resetn          ),
    //inputs                          
    .exe_wen        (exe_wen         ), 
    .exe_regsrc     (exe_regsrc      ), 
    .exe_is_load    (exe_is_load     ),
    .dram_rdata     (data_sram_rdata ),
    .alu_result_reg (alu_result_reg  ), 
    //outputs, no registers as well                      
    .wb_wen         (wb_wen          ),
    .wb_regsrc      (wb_regsrc       ), 
    .wb_regwdata    (wb_regwdata     )
    );

reg [31:0] de_pc;
reg [31:0] exe_pc;
always @ (posedge clk)
begin
	de_pc <= fe_pc;
	exe_pc <= de_pc;
end
assign reg_wen   = wb_wen; 
assign reg_waddr = wb_regsrc;
assign reg_wdata = wb_regwdata;
assign debug_wb_pc = exe_pc;
assign debug_wb_rf_wdata = wb_regwdata;
assign debug_wb_rf_wnum = wb_regsrc;
assign debug_wb_rf_wen = (wb_wen==1)? 4'b1111:4'b0000;

//regfile 调用

reg_file cpu_regfile
    (
    .clk    (clk            ), 
    .rstn   (resetn),
    .raddr1    (reg_raddr1   ), 
    .rdata1    (reg_rdata1   ), 

    .raddr2    (reg_raddr2   ), 
    .rdata2    (reg_rdata2   ), 

    .wen    (reg_wen      ), 
    .waddr    (reg_waddr    ), 
    .wdata    (reg_wdata    )  
    );


endmodule //mycpu_top
