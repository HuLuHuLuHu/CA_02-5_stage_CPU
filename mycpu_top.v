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
    input  wire [31:0] data_sram_rdata, //this is for wb stage 

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
//regfile
wire [31:0] reg_rdata1,reg_rdata2;
//de stage
wire [5:0]  reg_raddr1,reg_raddr2;
wire [5:0]  de_rs_addr,de_rt_addr;
wire        de_is_b,de_is_j,de_is_jr;
wire [3:0]  de_b_type;
wire [15:0] de_b_offset;
wire [25:0] de_j_index;
wire [3:0]  de_aluop;
wire [31:0] de_alusrc1;
wire [31:0] de_alusrc2;
wire        de_mem_en;
wire [3:0]  de_mem_wen;
wire [31:0] de_mem_wdata;
wire        de_reg_en;
wire        de_mem_read;
wire [5:0]  de_reg_waddr;
//exe stage
wire [31:0] alu_result;
wire exe_reg_en;
wire exe_mem_read;
wire [5:0] exe_reg_waddr;
wire [31:0] alu_result_reg;
//in mem stage, this is no special output signals
//wb stage
wire wb_reg_en;
wire [5:0] wb_reg_waddr;
wire [31:0] wb_reg_wdata;

// inst_sram is now a ROM
assign inst_sram_wen   = 4'b0;
assign inst_sram_wdata = 32'b0;


//PC_calculator
PC_calculator PC_calculator
    (
    .clk            (clk            ), 
    .resetn         (resetn         ), 
    .stall          (stall          ),
//control signals from de stage
    .is_b           (de_is_b        ), 
    .is_j           (de_is_j        ), 
    .is_jr          (de_is_jr       ), 
    .b_type         (de_b_type      ), 
    .b_offset       (de_b_offset    ), 
    .j_index        (de_j_index     ), 
//data from de stage (forwarded)
    .de_rs_data     (de_rs_data     ), 
    .de_rt_data     (de_rt_data     ),
//outputs
    .inst_sram_en   (inst_sram_en   ),
    .next_pc        (inst_sram_addr ),
    .current_pc		(current_pc     )
    );


//fetch instructions
fetch_stage fetch_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ),
    .stall          (stall          ),
//inputs from inst_ram and pc_caculator
    .inst_sram_rdata(inst_sram_rdata), 
    .inst_sram_raddr (current_pc     ), 
//data to de stage                            
    .fe_pc          (fe_pc          ), 
    .fe_inst        (fe_inst        )
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
    .exe_reg_wdata      (alu_result     ),
    .exe_mem_read   (de_mem_read    ),
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
//data from fe stage              
    .fe_inst        (fe_inst        ), 
    .fe_pc          (fe_pc          ),
//data to regfile
    .fe_rs_addr     (reg_raddr1     ), //from Hazard Unit, which is correct
    .fe_rt_addr     (reg_raddr2     ),
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
//signal for meme stage
    .de_mem_en      (de_mem_en      ),
    .de_mem_wen     (de_mem_wen     ), 
    .de_mem_wdata   (de_mem_wdata   ), 
//signal for wb stage
    .de_reg_en      (de_reg_en      ),
    .de_mem_read    (de_mem_read    ),
    .de_reg_waddr   (de_reg_waddr   )
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
//data from de stage
    .de_reg_en      (de_reg_en      ),
    .de_mem_read    (de_mem_read    ),
    .de_reg_waddr   (de_reg_waddr   ),
//data to mem stage
    .alu_result     (alu_result     ),
//data to wbstage
    .exe_reg_en     (exe_reg_en     ),
    .exe_mem_read   (exe_mem_read   ),
    .exe_reg_waddr  (exe_reg_waddr  ),
    .alu_result_reg (alu_result_reg )
    );


//mem
memory_stage mem_stage
    (
    .clk                (clk            ), 
    .resetn             (resetn         ),
//data from de stage and exe stage
    .de_mem_en          (de_mem_en      ),                       
    .de_mem_wen         (de_mem_wen     ),
    .exe_mem_waddr      (alu_result     ), 
    .de_mem_wdata       (de_mem_wdata    ),
    
//outputs, there is no registers in this stage 
    .data_sram_en       (data_sram_en   ),
    .data_sram_wen      (data_sram_wen  ),
    .data_sram_addr     (data_sram_addr ),
    .data_sram_wdata    (data_sram_wdata)
    );

//wb
writeback_stage wb_stage
    (
    .clk            (clk             ), 
    .resetn         (resetn          ),
//data from exe stage and mem stage
    .exe_reg_en     (exe_reg_en     ),
    .exe_reg_waddr  (exe_reg_waddr  ),
    .exe_mem_read   (exe_mem_read   ),
    .alu_result_reg (alu_result_reg ),
    .mem_rdata      (data_sram_rdata),
//data to regfile
    .wb_reg_en      (wb_reg_en      ),
    .wb_reg_waddr   (wb_reg_waddr   ),
    .wb_reg_wdata   (wb_reg_wdata   )
    );


//debug signals
reg [31:0] de_pc;
reg [31:0] exe_pc;
always @ (posedge clk)
begin
	de_pc <= fe_pc;
	exe_pc <= de_pc;
end
assign debug_wb_pc = exe_pc;
assign debug_wb_rf_wdata = wb_reg_wdata;
assign debug_wb_rf_wnum = wb_reg_waddr[4:0];
assign debug_wb_rf_wen = (wb_reg_en & ~wb_reg_waddr[5])? 4'b1111:4'b0000;




endmodule //mycpu_top
