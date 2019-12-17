`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  id/ex stage top 

module idex_unit (
input clk,
input rst_n,

input[`ZCRV_ADDR_SIZE-1:0]  pc_from_if,
input[`ZCRV_INSTR_SIZE-1:0]	inst_from_if,
input						jalr_need_rs1_from_if,
input						predict_hit_from_if,
input 						pc_misalgn_from_if ,
input 						ifetch_buserr_from_if , 

input[`ZCRV_XLEN-1:0]		rs1_data_from_reg ,
input[`ZCRV_XLEN-1:0]		rs2_data_from_reg ,
input[`ZCRV_XLEN-1:0] 		dest_csr_data_from_csr,

input						stall_from_stallunit,
input					   	flush_from_flushunit,

input[31:0] 				rddata_to_rs2_from_forwardunit,
input[31:0] 				rddata_to_rs1_from_forwardunit,
input					   	rd_to_rs1_from_forwardunit,
input					   	rd_to_rs2_from_forwardunit,

output						rd_en_to_wb,
output[`ZCRV_REG_SIZE-1:0]	rd_to_wb,
output[`ZCRV_ADDR_SIZE-1:0] pc_to_wb,
output[`ZCRV_INSTR_SIZE-1:0]inst_to_wb,
output 						inst_ilegl_to_wb ,
output 						pc_misalgn_to_wb ,
output 						ifetch_buserr_to_wb ,
output[`ZCRV_CSRADDR_SIZE-1:0] 	csr_index_to_csr, 
output							csr_en_to_csr,
output							csr_wr_en_to_csr,
output							csr_rd_en_to_csr,
output[`ZCRV_XLEN-1:0]			csr_wr_data_to_csr, 

output						need_jump_to_wb,
output[`ZCRV_ADDR_SIZE-1:0] jump_dest_to_wb,
output						bxx_pre_hit_to_wb,
output						op_bxx_to_wb,
output[`ZCRV_XLEN-1:0]      rd_result_to_wb,

output[`ZCRV_REG_SIZE-1:0]	rs1_to_reg,
output[`ZCRV_REG_SIZE-1:0]	rs2_to_reg,
output						rs1_en_to_reg,
output						rs2_en_to_reg,

output						store_to_dtcm,
output						load_to_dtcm,
output						req_to_dtcm,
output[`ZCRV_ADDR_SIZE-1:0]	addr_to_dtcm,

output						store_to_itcm,
output						load_to_itcm,
output						req_to_itcm,
output[`ZCRV_ADDR_SIZE-1:0]	addr_to_itcm,

output[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_to_stallwb ,    											//and wb stage
output						mdu_busy_to_stallwb , 
output						mdu_finish_to_stallwb ,		
output[`ZCRV_XLEN-1:0] 		mdu_result_to_stallwb ,	

output 						ls_to_wblsu,
output 						ls_addr_error_to_wblsu,
output[31:0] 				ls_addr_to_lsuwb ,
output[4:0] 				load_info_to_wblsu,
output[`ZCRV_XLEN-1:0]  	store_result_to_ram,
output[3:0]					store_mask_to_ram,
output[4:0] 				rd_index_to_wblsu ,
output 						rden_to_wblsu 	,

output 						fence_to_wb   ,
output 						fencei_to_wb  ,
output 						ecall_to_wb   ,
output 						ebreak_to_wb  ,
output 						mret_to_wb    ,
output 						wfi_to_wb     ,

output[`ZCRV_REG_SIZE-1:0]  rs1_to_forward_unit ,
output[`ZCRV_REG_SIZE-1:0]  rs2_to_forward_unit ,
output					 	rs1_en_to_forward_unit,
output						rs2_en_to_forward_unit,	

output[`ZCRV_REG_SIZE-1:0]	rs1_to_stallunit,
output[`ZCRV_REG_SIZE-1:0]	rs2_to_stallunit,	
output[`ZCRV_REG_SIZE-1:0]	rd_to_stallunit,	
output 						md_to_stallunit,
output					 	rs1_en_to_stallunit,
output						rs2_en_to_stallunit,	
output					 	rd_en_to_stallunit

);

wire[`ZCRV_ADDR_SIZE-1:0] pc_to_decode = pc_from_if ;
wire[`ZCRV_INSTR_SIZE-1:0] inst_to_decode = inst_from_if;
wire jalr_need_rs1_to_decode = jalr_need_rs1_from_if ;
wire predict_hit_to_decode = predict_hit_from_if ;

//decode output
wire[11:0]					de_inst_info_from_decode; 
wire                      	inst_ilegl_from_decode;
wire[`ZCRV_REG_SIZE-1:0]	rs1_from_decode;
wire[`ZCRV_REG_SIZE-1:0]	rs2_from_decode;
wire						rs1_en_from_decode;
wire						rs2_en_from_decode;
wire						rd_en_from_decode;
wire[`ZCRV_REG_SIZE-1:0]	rd_from_decode;

wire						imm_en_from_decode;
wire[`ZCRV_IMM_SIZE-1:0]	imm_from_decode;
wire    					op_alu_from_decode;
wire    					op_system_from_decode; 
wire    					op_jump_from_decode;
wire    					op_fence_from_decode;
wire    					op_s_l_from_decode;
wire						op_m_d_from_decode;
wire 						bxx_pre_hit_from_decode;
wire[`ZCRV_CSRADDR_SIZE-1:0] op_csr_addr_from_decode;
wire[11:0] 				    op_fence_info_from_decode;
wire						jalr_need_rs1_to_ex_from_decode; // jalr需要除了x0之外的rs1
wire[4:0]					csri_uimm_from_decode;
wire						op_bxx_from_decode;

decode decode(
.input_pc(pc_to_decode), //当前的指令地址
.input_inst(inst_to_decode),//指令码
.jalr_need_rs1_from_if(jalr_need_rs1_to_decode),//if阶段jalr预测失败，需要rs1的值
.predict_hit(predict_hit_to_decode),//if阶段是否预测跳转

.de_inst_info(de_inst_info_from_decode), //具体指令的信息
.inst_ilegl(inst_ilegl_from_decode), //指令非法
.rs1(rs1_from_decode), //寄存器rs1索引
.rs2(rs2_from_decode),
.rs1_en(rs1_en_from_decode),//rs1使能
.rs2_en(rs2_en_from_decode),
.rd_en(rd_en_from_decode),
.rd(rd_from_decode),//目的寄存器
.imm_en(imm_en_from_decode),//是否需要立即数
.imm(imm_from_decode),
.op_alu(op_alu_from_decode),//alu类
.op_system(op_system_from_decode), //系统类
.op_jump(op_jump_from_decode),//跳转类
.op_fence(op_fence_from_decode),//fence类
.op_s_l(op_s_l_from_decode), //存储类
.op_m_d(op_m_d_from_decode), //乘除法
.bxx_pre_hit(bxx_pre_hit_from_decode),//bxx跳转并且if预测跳
.op_csr_addr(op_csr_addr_from_decode),//csr指令地址
.jalr_need_rs1_to_ex(jalr_need_rs1_to_ex_from_decode),//jalr预测未跳，需要rs1
.csri_uimm(csri_uimm_from_decode),//csr的立即数
.op_bxx(op_bxx_from_decode) //指令为bxx跳转

);

wire rs1_x0  = (rs1_from_decode == 5'b0);
wire rs2_x0  = (rs2_from_decode == 5'b0);
wire fence   = op_fence_from_decode  &  de_inst_info_from_decode[11] ;
wire fencei  = op_fence_from_decode  &  de_inst_info_from_decode[10] ;
wire ecall   = op_system_from_decode & de_inst_info_from_decode[4];
wire ebreak  = op_system_from_decode & de_inst_info_from_decode[5];
wire mret    = op_system_from_decode & de_inst_info_from_decode[3]; 
wire wfi     = op_system_from_decode & de_inst_info_from_decode[2]; 


wire[`ZCRV_XLEN-1:0] 		real_rs1data = rd_to_rs1_from_forwardunit ? rddata_to_rs1_from_forwardunit : rs1_data_from_reg ;
wire[`ZCRV_XLEN-1:0] 		real_rs2data = rd_to_rs2_from_forwardunit ? rddata_to_rs2_from_forwardunit : rs2_data_from_reg ;
wire[`ZCRV_ADDR_SIZE-1:0]	pc_to_exu = pc_from_if; 
wire[11:0]				    de_inst_info_to_exu = de_inst_info_from_decode; 
wire[`ZCRV_XLEN-1:0]		rs1_data_to_exu = (op_alu_from_decode | op_jump_from_decode | op_system_from_decode)? real_rs1data : 0;
wire[`ZCRV_REG_SIZE-1:0]	rs1_index_to_exu = rs1_from_decode;
wire[`ZCRV_XLEN-1:0]		rs2_data_to_exu = (op_alu_from_decode | op_jump_from_decode | op_system_from_decode)? real_rs2data : 0;
wire[`ZCRV_REG_SIZE-1:0]	rd_index_to_exu = rd_from_decode;
wire						rs1_en_to_exu = rs1_en_from_decode;
wire						rs2_en_to_exu = rs2_en_from_decode;
wire						rd_en_to_exu = rd_en_from_decode;
wire						imm_en_to_exu = imm_en_from_decode;
wire[`ZCRV_IMM_SIZE-1:0]	imm_to_exu = imm_from_decode;
wire    					op_alu_to_exu = op_alu_from_decode;
wire    					op_system_to_exu = op_system_from_decode; 
wire    					op_jump_to_exu = op_jump_from_decode;
wire						op_bxx_to_exu = op_bxx_from_decode;
wire[`ZCRV_CSRADDR_SIZE-1:0] op_csr_addr_to_exu = op_csr_addr_from_decode;
wire						 jalr_need_rs1_from_id_to_exu = jalr_need_rs1_to_ex_from_decode;
wire[4:0]					 csri_uimm_to_exu = csri_uimm_from_decode;
wire[`ZCRV_XLEN-1:0] 		 dest_csr_data_to_exu = dest_csr_data_from_csr;

wire[`ZCRV_CSRADDR_SIZE-1:0] 	csr_index_from_exu;


wire[`ZCRV_XLEN-1:0] 		    exu_result_from_exu;
wire[`ZCRV_ADDR_SIZE-1:0] 	    jump_dest_from_exu;
wire							jump_whether_or_not_from_exu;


exu exu(

.input_pc(pc_to_exu), //pc_present_to_idex
.de_inst_info(de_inst_info_to_exu), 
.rs1_data(rs1_data_to_exu),
.rs1(rs1_index_to_exu),
.rs2_data(rs2_data_to_exu),
.rd(rd_index_to_exu),
.rs1_en(rs1_en_to_exu),
.rs2_en(rs2_en_to_exu),
.rd_en(rd_en_to_exu),
.imm_en(imm_en_to_exu),
.imm(imm_to_exu),
.op_alu(op_alu_to_exu),
.op_system(op_system_to_exu), // ecall ebreak wfi csr mret
.op_jump(op_jump_to_exu),
.op_bxx(op_bxx_to_exu),
//csr
.op_csr_addr(op_csr_addr_to_exu),
.jalr_need_rs1_from_id(jalr_need_rs1_from_id_to_exu),
.csri_uimm(csri_uimm_to_exu),
.dest_csr_data (dest_csr_data_to_exu),
//to csr unit
.csr_index(csr_index_from_exu),
.csr_en(csr_en_to_csr),
.csr_wr_en(csr_wr_en_to_csr),
.csr_rd_en(csr_rd_en_to_csr),
.csr_wr_data(csr_wr_data_to_csr),
//to next stage  predict_fix 
.write_back_rd(exu_result_from_exu),
.jump_dest(jump_dest_from_exu),
.jump_whether_or_not(jump_whether_or_not_from_exu)

);


wire 						op_s_l_to_lsu = op_s_l_from_decode;
wire[7:0]				    de_inst_info_to_lsu = de_inst_info_from_decode[11:4];
wire[`ZCRV_XLEN-1:0] 		rs1_ls_to_lsu = op_s_l_from_decode ? real_rs1data : 0 ;
wire[`ZCRV_XLEN-1:0] 		rs2_ls_to_lsu = op_s_l_from_decode ? real_rs2data : 0 ;
wire[`ZCRV_IMM_SIZE-1:0]	imm_ls_to_lsu = imm_from_decode;

wire						load_from_lsu;
wire						store_from_lsu;
wire[`ZCRV_ADDR_SIZE-1:0]	lsaddr_from_lsu;
wire[`ZCRV_XLEN-1:0]		store_result_from_lsu;
wire[3:0]					store_mask_from_lsu;
wire						itcm_req_from_lsu;
wire						dtcm_req_from_lsu;
wire[4:0]					load_info_from_lsu;
wire						addr_error_from_lsu;

lsu_agu lsu1(
.op_s_l(op_s_l_to_lsu),
.de_inst_info(de_inst_info_to_lsu), 
.rs1_ls(rs1_ls_to_lsu),  
.rs2_ls(rs2_ls_to_lsu),
.imm_ls(imm_ls_to_lsu),

.load(load_from_lsu),
.store(store_from_lsu),
.lsaddr(lsaddr_from_lsu),
.store_result(store_result_from_lsu),
.store_mask(store_mask_from_lsu),
.itcm_req(itcm_req_from_lsu),
.dtcm_req(dtcm_req_from_lsu),
.load_info(load_info_from_lsu),
.addr_error(addr_error_from_lsu)

);

wire						op_m_d_to_mdu = op_m_d_from_decode;//from decode
wire[11:0]				    de_inst_info_to_mdu = de_inst_info_from_decode; //from decode
wire[`ZCRV_XLEN-1:0] 		rs1_mdu_to_mdu = op_m_d_to_mdu ? real_rs1data : 0 ; //from reg
wire[`ZCRV_XLEN-1:0] 		rs2_mdu_to_mdu = op_m_d_to_mdu ? real_rs2data : 0; //from reg
wire[`ZCRV_REG_SIZE-1:0]	rd_index_to_mdu = op_m_d_to_mdu ? rd_from_decode : 5'b00000;    //from decode

wire[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_from_mdu ;    											//and wb stage
wire						mdu_busy_from_mdu ; 
wire						mdu_finish_from_mdu ;		
wire[`ZCRV_XLEN-1:0] 		mdu_result_from_mdu ;	

mdu mdu(
.clk(clk),
.rst_n(rst_n),

.op_m_d(op_m_d_to_mdu), //from decode
.de_inst_info(de_inst_info_to_mdu), //from decode
.rs1_mdu(rs1_mdu_to_mdu) , //from reg
.rs2_mdu(rs2_mdu_to_mdu) , //from reg
.rd_index(rd_index_to_mdu),     //from decode

.mdu_now_rd(mdu_now_rd_from_mdu),     //to stall unit t0 check wb stage rdindex 											//and wb stage
.mdu_busy(mdu_busy_from_mdu),     //to stall unit
.mdu_finish(mdu_finish_from_mdu),		//to wb stage
.mdu_result(mdu_result_from_mdu) 	//to wb stage

);

reg						 rd_en_to_wb_r;
reg[`ZCRV_REG_SIZE-1:0]	 rd_to_wb_r;
reg[`ZCRV_ADDR_SIZE-1:0] pc_to_wb_r;
reg[`ZCRV_INSTR_SIZE-1:0]inst_to_wb_r;
reg						 op_bxx_r;

reg						 need_jump_to_wb_r;
reg[`ZCRV_ADDR_SIZE-1:0] jump_dest_to_wb_r;
reg						 bxx_pre_hit_to_wb_r;
reg[`ZCRV_XLEN-1:0]      rd_result_to_wb_r;
reg						inst_ilegl_to_wb_r;
reg 					pc_misalgn_to_wb_r ;
reg 					ifetch_buserr_to_wb_r ;  

wire					  rd_en_to_wb_t = ~(op_m_d_from_decode|op_s_l_from_decode) ? rd_en_from_decode : 1'b0;
wire[`ZCRV_REG_SIZE-1:0]  rd_to_wb_t = ~(op_m_d_from_decode|op_s_l_from_decode) ? rd_from_decode : 5'b00000;
wire[`ZCRV_ADDR_SIZE-1:0] pc_to_wb_t = pc_from_if;
wire[`ZCRV_INSTR_SIZE-1:0]inst_to_wb_t = inst_from_if;
wire					  op_bxx_t = op_bxx_from_decode;
wire					  inst_ilegl_to_wb_t = inst_ilegl_from_decode;
wire 					  pc_misalgn_to_wb_t =  pc_misalgn_from_if;
wire 					  ifetch_buserr_to_wb_t = ifetch_buserr_from_if ;  

wire					  need_jump_to_wb_t = jump_whether_or_not_from_exu;
wire[`ZCRV_ADDR_SIZE-1:0] jump_dest_to_wb_t = jump_dest_from_exu;
wire					  bxx_pre_hit_to_wb_t = bxx_pre_hit_from_decode;
wire[`ZCRV_XLEN-1:0]      rd_result_to_wb_t = ~(op_m_d_from_decode|op_s_l_from_decode) ? exu_result_from_exu : 0;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n ) begin
		rd_en_to_wb_r 		<= 0 ;
		rd_to_wb_r    		<= 0 ;
		pc_to_wb_r 			<= 0;
		inst_to_wb_r     	<= 0;
		need_jump_to_wb_r	<= 0;
		jump_dest_to_wb_r 	<= 0 ;
		bxx_pre_hit_to_wb_r <= 0 ;
		rd_result_to_wb_r 	<= 0;
		op_bxx_r			<= 0;
		inst_ilegl_to_wb_r  <= 0 ;
		pc_misalgn_to_wb_r  <= 0;
		ifetch_buserr_to_wb_r <= 0;  
		end
		else if(flush_from_flushunit)
		begin
		rd_en_to_wb_r 		<= 0 ;
		rd_to_wb_r    		<= 0 ;
		pc_to_wb_r 			<= 0;
		inst_to_wb_r     	<= 0;
		need_jump_to_wb_r	<= 0;
		jump_dest_to_wb_r 	<= 0 ;
		bxx_pre_hit_to_wb_r <= 0 ;
		rd_result_to_wb_r 	<= 0;
		op_bxx_r			<= 0;
		inst_ilegl_to_wb_r  <= 0 ;
		pc_misalgn_to_wb_r  <= 0;
		ifetch_buserr_to_wb_r <= 0;  		
		end
		else if (stall_from_stallunit)
		begin
		rd_en_to_wb_r 		<= rd_en_to_wb_r ;
		rd_to_wb_r    		<= rd_to_wb_r ;
		pc_to_wb_r 			<= pc_to_wb_r;
		inst_to_wb_r     	<= inst_to_wb_r;
		need_jump_to_wb_r	<= need_jump_to_wb_r;
		jump_dest_to_wb_r 	<= jump_dest_to_wb_r ;
		bxx_pre_hit_to_wb_r <= bxx_pre_hit_to_wb_r ;
		rd_result_to_wb_r 	<= rd_result_to_wb_r;
		op_bxx_r			<= op_bxx_r;
		inst_ilegl_to_wb_r  <= inst_ilegl_to_wb_r ;
		pc_misalgn_to_wb_r  <= pc_misalgn_to_wb_r;
		ifetch_buserr_to_wb_r <= ifetch_buserr_to_wb_r;  		
		end
		else begin
		rd_en_to_wb_r 		<= rd_en_to_wb_t ;
		rd_to_wb_r    		<= rd_to_wb_t ;
		pc_to_wb_r 			<= pc_to_wb_t;
		inst_to_wb_r     	<= inst_to_wb_t;
		need_jump_to_wb_r	<= need_jump_to_wb_t;
		jump_dest_to_wb_r 	<= jump_dest_to_wb_t ;
		bxx_pre_hit_to_wb_r <= bxx_pre_hit_to_wb_t ;
		rd_result_to_wb_r 	<= rd_result_to_wb_t;
		op_bxx_r			<= op_bxx_t;
		inst_ilegl_to_wb_r  <= inst_ilegl_to_wb_t ;	
		pc_misalgn_to_wb_r  <= pc_misalgn_to_wb_t;
		ifetch_buserr_to_wb_r <= ifetch_buserr_to_wb_t;
		end
		
end

wire ls_to_wblsu_t = load_from_lsu | store_from_lsu ;
wire ls_addr_error_to_wblsu_t = addr_error_from_lsu;
wire[31:0] ls_addr_to_lsuwb_t = lsaddr_from_lsu ;
wire[4:0] load_info_to_wblsu_t = load_info_from_lsu;
wire[4:0] rd_index_to_wblsu_t = op_s_l_from_decode ? rd_from_decode : 5'b00000;
wire rden_to_wblsu_t = op_s_l_from_decode ? rd_en_from_decode : 1'b0;

reg ls_to_wblsu_r  ;
reg ls_addr_error_to_wblsu_r ;
reg[31:0] ls_addr_to_lsuwb_r ;
reg[4:0] load_info_to_wblsu_r ;
reg[4:0] rd_index_to_wblsu_r;
reg rden_to_wblsu_r ;

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n ) begin
		ls_to_wblsu_r 				<= 0 ;
		ls_addr_error_to_wblsu_r    <= 0 ;
		load_info_to_wblsu_r 		<= 0;
		rd_index_to_wblsu_r 		<= 0;
		rden_to_wblsu_r 			<= 0;
		ls_addr_to_lsuwb_r          <= 0 ;
		end 
		else if(flush_from_flushunit)
		begin
		ls_to_wblsu_r 				<= 0 ;
		ls_addr_error_to_wblsu_r    <= 0 ;
		load_info_to_wblsu_r 		<= 0;
		rd_index_to_wblsu_r 		<= 0;
		rden_to_wblsu_r 			<= 0;
		ls_addr_to_lsuwb_r          <= 0 ;
		end
		else if (stall_from_stallunit)
		begin
		ls_to_wblsu_r 				<= ls_to_wblsu_r ;
		ls_addr_error_to_wblsu_r    <= ls_addr_error_to_wblsu_r ;
		load_info_to_wblsu_r 		<= load_info_to_wblsu_r;
		rd_index_to_wblsu_r 		<= rd_index_to_wblsu_r;
		rden_to_wblsu_r 			<= rden_to_wblsu_r;
		ls_addr_to_lsuwb_r          <= ls_addr_to_lsuwb_r ;
		end
		else begin
		ls_to_wblsu_r 				<= ls_to_wblsu_t ;
		ls_addr_error_to_wblsu_r    <= ls_addr_error_to_wblsu_t ;
		load_info_to_wblsu_r 		<= load_info_to_wblsu_t;
		rd_index_to_wblsu_r 		<= rd_index_to_wblsu_t;
		rden_to_wblsu_r 			<= rden_to_wblsu_t;
		ls_addr_to_lsuwb_r          <= ls_addr_to_lsuwb_t ;
		end
end

assign	mdu_now_rd_to_stallwb = mdu_now_rd_from_mdu ;    											//and wb stage
assign	mdu_busy_to_stallwb  = mdu_busy_from_mdu ; 
assign	mdu_finish_to_stallwb = mdu_finish_from_mdu ;		
assign	mdu_result_to_stallwb = mdu_result_from_mdu ;	


assign ls_to_wblsu = ls_to_wblsu_r  ;
assign ls_addr_error_to_wblsu = ls_addr_error_to_wblsu_r ;
assign ls_addr_to_lsuwb = ls_addr_to_lsuwb_r;
assign load_info_to_wblsu = load_info_to_wblsu_r ;
assign rd_index_to_wblsu = rd_index_to_wblsu_r;
assign rden_to_wblsu 	= rden_to_wblsu_r;

assign csr_index_to_csr = csr_index_from_exu;
assign rd_en_to_wb = rd_en_to_wb_r;
assign rd_to_wb = rd_to_wb_r;
assign pc_to_wb = pc_to_wb_r;
assign inst_to_wb = inst_to_wb_r;
assign inst_ilegl_to_wb  = inst_ilegl_to_wb_r ;	
assign pc_misalgn_to_wb  = pc_misalgn_to_wb_r;
assign ifetch_buserr_to_wb = ifetch_buserr_to_wb_r;

assign need_jump_to_wb = need_jump_to_wb_r;
assign jump_dest_to_wb = jump_dest_to_wb_r;
assign bxx_pre_hit_to_wb = bxx_pre_hit_to_wb_r;
assign op_bxx_to_wb = op_bxx_r ;
assign rd_result_to_wb = rd_result_to_wb_r;

assign	rs1_to_reg = rs1_from_decode;
assign	rs2_to_reg = rs2_from_decode;
assign	rs1_en_to_reg = rs1_en_from_decode;
assign	rs2_en_to_reg = rs2_en_from_decode;

assign	store_result_to_ram = ~stall_from_stallunit ? store_result_from_lsu : 0;
assign	store_mask_to_ram = ~stall_from_stallunit ? store_mask_from_lsu : 0;
assign	store_to_dtcm = ~stall_from_stallunit & dtcm_req_from_lsu & store_from_lsu;
assign	load_to_dtcm = ~stall_from_stallunit & dtcm_req_from_lsu & load_from_lsu;
assign	req_to_dtcm = ~stall_from_stallunit & dtcm_req_from_lsu;
assign	addr_to_dtcm = dtcm_req_from_lsu &~stall_from_stallunit ? lsaddr_from_lsu : 0;

assign	store_to_itcm = ~stall_from_stallunit &  itcm_req_from_lsu & store_from_lsu;
assign	load_to_itcm = ~stall_from_stallunit & itcm_req_from_lsu & load_from_lsu;
assign	req_to_itcm = ~stall_from_stallunit & itcm_req_from_lsu;
assign	addr_to_itcm = ~stall_from_stallunit & itcm_req_from_lsu ? lsaddr_from_lsu : 0;

reg fence_r  ;
reg fencei_r ;
reg ecall_r  ;
reg ebreak_r ;
reg mret_r   ; 
reg wfi_r    ; 

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n ) begin
		fence_r 	<= 0 ;
		fencei_r    <= 0 ;
		ecall_r 	<= 0;
		ebreak_r 	<= 0 ;
		mret_r    	<= 0 ;
		wfi_r 		<= 0;
		end
		else if(flush_from_flushunit)
		begin
		fence_r 	<= 0 ;
		fencei_r    <= 0 ;
		ecall_r 	<= 0;
		ebreak_r 	<= 0 ;
		mret_r    	<= 0 ;
		wfi_r 		<= 0;
		end
		else if(stall_from_stallunit)
		begin
		fence_r 	<= fence_r ;
		fencei_r    <= fencei_r ;
		ecall_r 	<= ecall_r;
		ebreak_r 	<= ebreak_r ;
		mret_r      <= mret_r ;
		wfi_r       <= wfi_r;
		end
		else begin
		fence_r 	<= fence ;
		fencei_r    <= fencei ;
		ecall_r 	<= ecall;
		ebreak_r 	<= ebreak ;
		mret_r      <= mret ;
		wfi_r       <= wfi;
		end
end

assign	fence_to_wb = fence_r ;
assign	fencei_to_wb = fencei_r;
assign	ecall_to_wb = ecall_r ;
assign	ebreak_to_wb = ebreak_r;
assign	mret_to_wb =  mret_r ;
assign	wfi_to_wb =  wfi_r  ;


assign  rs1_to_forward_unit = rs1_from_decode ;
assign  rs2_to_forward_unit = rs2_from_decode;
assign	rs1_en_to_forward_unit = rs1_en_from_decode & ~rs1_x0;
assign	rs2_en_to_forward_unit = rs2_en_from_decode & ~rs2_x0;	

assign	rs1_to_stallunit = rs1_from_decode;
assign	rs2_to_stallunit = rs2_from_decode;	
assign	rs1_en_to_stallunit = rs1_en_from_decode ;
assign	rs2_en_to_stallunit = rs2_en_from_decode ;	
assign	rd_to_stallunit = rd_from_decode;
assign	rd_en_to_stallunit = rd_en_from_decode;	
assign	md_to_stallunit = op_m_d_from_decode;
endmodule