


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
    input  wire [31:0] data_sram_rdata 


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

wire [31:0] next_pc;
wire [31:0] fe_pc;
wire [31:0] fe_inst;
wire [31:0] alu_result;
wire [31:0] alu_result_reg;
wire exe_is_load;
wire [4:0] exe_regsrc;
wire exe_wen;
wire [31:0] reg_rdata1,reg_rdata2,reg_wdata;
wire [4:0] reg_raddr1,reg_raddr2,reg_waddr;
wire reg_wen;

// inst_sram is now a ROM
assign inst_sram_wen   = 4'b0;
assign inst_sram_wdata = 32'b0;


//PC_calculator 调用


PC_calculator PC_calculator
    (
    .resetn         (resetn         ), 
    .clk            (clk          ), 

    .is_b    (de_is_b    ), 
    .is_j    (de_is_j    ), 
    .is_jr     (de_is_jr     ), 
    .b_type    (de_b_type    ), 
    .b_offset   (de_b_offset   ), 
    .j_index    (de_j_index    ), 
    .rdata1   (reg_rdata1), 
    .rdata2   (reg_rdata2),
    .inst_sram_addr (inst_sram_addr ), 
    .inst_sram_en (inst_sram_en),
    .next_pc         (next_pc  )  
    );


//取指?


fetch_stage fetch_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ),
    .inst_sram_rdata(inst_sram_rdata), 
    .inst_sram_addr (inst_sram_addr),                               
    .fe_pc          (fe_pc          ), 
    .fe_inst        (fe_inst        )  
    );


//译码?


decode_stage de_stage
    (
    .clk            (clk            ),
    .resetn         (resetn         ),                          
    .fe_inst        (fe_inst        ),                                  
    .de_is_b  (de_is_b),
    .de_is_j  (de_is_j  ), 
    .de_is_jr   (de_is_jr   ),
    .de_b_type   (de_b_type   ),                                    
    .de_b_offset    (de_b_offset    ),
    .de_j_index    (de_j_index    ),//
    .raddr1   (reg_raddr1),
    .raddr2   (reg_raddr2),
    .rdata1     (reg_rdata1     ),
    .rdata2   (reg_rdata2   ),
    .rt_reg_content   (rt_reg_content ),
    .de_aluop   (de_aluop    ),
    .de_alusrc1   (de_alusrc1   ),                                 
    .de_alusrc2     (de_alusrc2      ),
    .de_dramen      (de_dramen      ),
    .de_dramwen      (de_dramwen       ), 
    .de_wen       (de_wen       ), 
    .de_regsrc    (de_regsrc    ),
    .de_is_load (de_is_load)

    );


//执行?

execute_stage exe_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ), 
                                    
    .de_aluop      (de_aluop      ), 
    .de_alusrc1       (de_alusrc1       ), 
    .de_alusrc2       (de_alusrc2       ), 
    .alu_result    (alu_result  ), 
    .alu_result_reg     (alu_result_reg     ), 
    .de_is_load       (de_is_load       ), 
    .de_wen      (de_wen      ), 
    .de_regsrc   (de_regsrc   ),
    .exe_wen  (exe_wen  ),
    .exe_regsrc (exe_regsrc ),
    .exe_is_load (exe_is_load)
    );


//访存?
memory_stage mem_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ),
                                    
    .alu_result    (alu_result     ), 
    .rt_reg_content     (rt_reg_content      ),
    .de_dramen      (de_dramen      ),
                                    
    .de_dramwen    (de_dramwen),
                                    
    .data_sram_addr     (data_sram_addr     ),
    .data_sram_wdata       (data_sram_wdata      ),
    .data_sram_wen      (data_sram_wen      ),
    .data_sram_en  (data_sram_en)

    );

wire wb_wen;
wire [4:0] wb_regsrc;
wire [31:0] wb_regwdata;
//写回?
writeback_stage wb_stage
    (
    .clk            (clk            ), 
    .resetn         (resetn         ),
                                    
    .exe_wen    (exe_wen     ), 
    .exe_regsrc       (exe_regsrc       ), 
    .exe_is_load      (exe_is_load      ),
    .dram_rdata   (data_sram_rdata),
    .alu_result_reg  (alu_result_reg),                           
    .wb_wen      (wb_wen      ),
    .wb_regsrc   (wb_regsrc    ), 
    .wb_regwdata    (wb_regwdata    ) 
    );
assign reg_wen = wb_wen; assign reg_waddr = wb_regsrc;
 assign reg_wdata = wb_regwdata;

//regfile 调用

reg_file cpu_regfile
    (
    .clk    (clk            ), 

    .raddr1    (reg_raddr1   ), 
    .rdata1    (reg_rdata1   ), 

    .raddr2    (reg_raddr2   ), 
    .rdata2    (reg_rdata2   ), 

    .wen    (reg_wen      ), 
    .waddr    (reg_waddr    ), 
    .wdata    (reg_wdata    )  
    );


endmodule //mycpu_top
