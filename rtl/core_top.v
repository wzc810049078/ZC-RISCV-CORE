`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  if >>> idex >>> wb
// RV32IM zicsr zifence

module core_top (
	input clk,    // Clock
	input rst_n,  // Asynchronous reset active low

	//中断信号
	input   					ext_irq,  
	input						time_irq,
	input						soft_irq, 

	//ifu 取指令
	input						itcm_ready_from_itcm,
	input[`ZCRV_INSTR_SIZE-1:0]	itcm_inst_from_itcm,
	output[`ZCRV_ADDR_SIZE-1:0] pc_to_itcm,
	output						ifureq_to_itcm,

	//lsu读数据取数据
	input						res_from_dtcm,
	input[`ZCRV_XLEN-1:0]		data_from_dtcm,
	input						res_from_itcm,
	input[`ZCRV_XLEN-1:0]		data_from_itcm,

	output						store_to_dtcm,
	output						load_to_dtcm,
	output						req_to_dtcm,
	output[`ZCRV_ADDR_SIZE-1:0]	addr_to_dtcm,
	output						store_to_itcm,
	output						load_to_itcm,
	output						req_to_itcm,
	output[`ZCRV_ADDR_SIZE-1:0]	addr_to_itcm,
	output[`ZCRV_XLEN-1:0]		store_result_to_ram	,
	output[3:0]					store_mask_to_ram
);
wire[`ZCRV_ADDR_SIZE-1:0] flush_pc_from_flushunit;
wire stall_from_stallunit;
wire flush_from_flushunit;


wire[`ZCRV_XLEN-1:0] 		rs1_data_from_reg;
wire[`ZCRV_XLEN-1:0] 		rs2_data_from_reg;

wire[31:0] dest_csr_data_from_csr;
wire[31:0] mtvec_from_csr;
wire[31:0] mstatus_from_csr;
wire[31:0] mepc_from_csr;		
wire[31:0] mie_from_csr;	

wire[31:0] 				rddata_to_rs2_from_forwardunit;
wire[31:0] 				rddata_to_rs1_from_forwardunit;
wire					rd_to_rs1_from_forwardunit;
wire					rd_to_rs2_from_forwardunit;

wire						bxxjump_success_from_cmt ;
wire						bxxjump_fail_from_cmt ;
wire[`ZCRV_ADDR_SIZE-1:0] 	fix_pc_from_cmt;

//ifu 
wire[`ZCRV_ADDR_SIZE-1:0] flush_pc_to_ifu = flush_pc_from_flushunit ;
wire flush_to_ifu = flush_from_flushunit;
wire stall_to_ifu = stall_from_stallunit;

wire[`ZCRV_ADDR_SIZE-1:0]   pc_present_from_ifu;
wire[`ZCRV_ADDR_SIZE-1:0]   pc_next_from_ifu;
wire[`ZCRV_INSTR_SIZE-1:0]  inst_from_ifu;
wire						predict_hit_from_ifu;
wire 						pc_misalgn_from_ifu ;
wire 						ifetch_buserr_from_ifu;
wire						jalr_need_rs1_from_ifu;



ifu ifu(
.clk(clk),
.rst_n(rst_n),
// from itcm
.itcm_ready(itcm_ready_from_itcm),
.itcm_inst(itcm_inst_from_itcm),
//from id/ex wb
.flush_pc(flush_pc_to_ifu),						
.pipe_flush(flush_to_ifu), 
.stall_from_stallunit(stall_to_ifu),
//from fix unit
.fix_success(bxxjump_success_from_cmt),
.fix_fail(bxxjump_fail_from_cmt),
.fix_pc(fix_pc_from_cmt),

//to itcm
.pc_to_itcm(pc_to_itcm),
.ifu_to_itcm_req(ifureq_to_itcm),

//to id/ex
.pc_present_to_idex(pc_present_from_ifu),
.pc_next_to_idex(pc_next_from_ifu),
.inst_to_idex(inst_from_ifu),
.predict_hit(predict_hit_from_ifu),
.pc_misalgn_to_idex(pc_misalgn_from_ifu) ,
.ifetch_buserr_to_idex(ifetch_buserr_from_ifu) ,  
.jalr_need_rs1_to_idex(jalr_need_rs1_from_ifu)

);

//idex
wire[`ZCRV_ADDR_SIZE-1:0]   pc_to_idex = pc_present_from_ifu;
wire[`ZCRV_INSTR_SIZE-1:0]	inst_to_idex = inst_from_ifu;
wire						jalr_need_rs1_to_idex = jalr_need_rs1_from_ifu;
wire						predict_hit_to_idex = predict_hit_from_ifu;
wire 						pc_misalgn_to_idex = pc_misalgn_from_ifu;
wire 						ifetch_buserr_to_idex = ifetch_buserr_from_ifu; 
wire[`ZCRV_XLEN-1:0]		rs1_data_to_idex = rs1_data_from_reg ;
wire[`ZCRV_XLEN-1:0]		rs2_data_to_idex = rs2_data_from_reg ;
wire[`ZCRV_XLEN-1:0] 		dest_csr_data_to_idex = dest_csr_data_from_csr;
wire						stall_to_idex = stall_from_stallunit;
wire					   	flush_to_idex = flush_from_flushunit;
wire[31:0] 					rddata_to_rs2_to_idex = rddata_to_rs2_from_forwardunit;
wire[31:0] 					rddata_to_rs1_to_idex = rddata_to_rs1_from_forwardunit;
wire					   	rd_to_rs1_to_idex = rd_to_rs1_from_forwardunit;
wire					   	rd_to_rs2_to_idex = rd_to_rs2_from_forwardunit;

//idex output
wire[`ZCRV_CSRADDR_SIZE-1:0]csr_index_from_idex;
wire						csr_en_from_idex;
wire						csr_wr_en_from_idex;
wire						csr_rd_en_from_idex;
wire[`ZCRV_XLEN-1:0]		csr_wr_data_from_idex; 
wire						rd_en_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	rd_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0] 	pc_from_idex;
wire[`ZCRV_INSTR_SIZE-1:0]	inst_from_idex;
wire 						inst_ilegl_from_idex ;
wire 						pc_misalgn_from_idex ;
wire 						ifetch_buserr_from_idex ;  

wire						need_jump_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0] 	jump_dest_from_idex;
wire						bxx_pre_hit_from_idex;
wire						op_bxx_from_idex;
wire[`ZCRV_XLEN-1:0]      	rd_result_from_idex;

wire[`ZCRV_REG_SIZE-1:0]	rs1_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	rs2_from_idex;
wire						rs1_en_from_idex;
wire						rs2_en_from_idex;

wire[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_from_mdu ;
wire						mdu_busy_from_mdu ; 
wire						mdu_finish_from_mdu ;		
wire[`ZCRV_XLEN-1:0] 		mdu_result_from_mdu ;	

wire 						ls_from_idexlsu;
wire 						ls_addr_error_from_idexlsu;
wire[31:0] 					ls_addr_from_idexlsu ;
wire[4:0] 					load_info_from_idexlsu;
wire[4:0] 					rd_index_from_idexlsu ;
wire 						rden_from_idexlsu 	;

wire 						fence_from_idex   ;
wire 						fencei_from_idex  ;
wire 						ecall_from_idex   ;
wire 						ebreak_from_idex  ;
wire 						mret_from_idex    ;
wire 						wfi_from_idex     ;

wire[`ZCRV_REG_SIZE-1:0]  	forwardrs1_from_idex ;
wire[`ZCRV_REG_SIZE-1:0]  	forwardrs2_from_idex ;
wire					 	forwardrs1_en_from_idex;
wire						forwardrs2_en_from_idex;	

wire[`ZCRV_REG_SIZE-1:0]	stallrs1_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	stallrs2_from_idex;	
wire[`ZCRV_REG_SIZE-1:0]	stallrd_from_idex;	
wire 						md_from_idex;
wire					 	stallrs1_en_from_idex;
wire						stallrs2_en_from_idex;	
wire					 	stallrd_en_from_idex;

idex_unit idex_unit (
.clk(clk),
.rst_n(rst_n),

.pc_from_if(pc_to_idex),
.inst_from_if(inst_to_idex),
.jalr_need_rs1_from_if(jalr_need_rs1_to_idex),
.predict_hit_from_if(predict_hit_to_idex),
.pc_misalgn_from_if(pc_misalgn_to_idex) ,
.ifetch_buserr_from_if(ifetch_buserr_to_idex) , 

.rs1_data_from_reg(rs1_data_to_idex) ,
.rs2_data_from_reg(rs2_data_to_idex) ,
.dest_csr_data_from_csr(dest_csr_data_to_idex),

.stall_from_stallunit(stall_to_idex),
.flush_from_flushunit(flush_to_idex),

.rddata_to_rs2_from_forwardunit(rddata_to_rs2_to_idex),
.rddata_to_rs1_from_forwardunit(rddata_to_rs1_to_idex),
.rd_to_rs1_from_forwardunit(rd_to_rs1_to_idex),
.rd_to_rs2_from_forwardunit(rd_to_rs2_to_idex),

.csr_index_to_csr(csr_index_from_idex),
.csr_en_to_csr(csr_en_from_idex),
.csr_wr_en_to_csr(csr_wr_en_from_idex),
.csr_rd_en_to_csr(csr_rd_en_from_idex),
.csr_wr_data_to_csr(csr_wr_data_from_idex),
.rd_en_to_wb(rd_en_from_idex),
.rd_to_wb(rd_from_idex),
.pc_to_wb(pc_from_idex),
.inst_to_wb(inst_from_idex),
.inst_ilegl_to_wb(inst_ilegl_from_idex) ,
.pc_misalgn_to_wb(pc_misalgn_from_idex) ,
.ifetch_buserr_to_wb(ifetch_buserr_from_idex) ,  

.need_jump_to_wb(need_jump_from_idex),
.jump_dest_to_wb(jump_dest_from_idex),
.bxx_pre_hit_to_wb(bxx_pre_hit_from_idex),
.op_bxx_to_wb(op_bxx_from_idex),
.rd_result_to_wb(rd_result_from_idex),

.rs1_to_reg(rs1_from_idex),
.rs2_to_reg(rs2_from_idex),
.rs1_en_to_reg(rs1_en_from_idex),
.rs2_en_to_reg(rs2_en_from_idex),

.store_to_dtcm(store_to_dtcm),
.load_to_dtcm(load_to_dtcm),
.req_to_dtcm(req_to_dtcm),
.addr_to_dtcm(addr_to_dtcm),

.store_mask_to_ram(store_mask_to_ram),
.store_to_itcm(store_to_itcm),
.load_to_itcm(load_to_itcm),
.req_to_itcm(req_to_itcm),
.addr_to_itcm(addr_to_itcm),

.mdu_now_rd_to_stallwb(mdu_now_rd_from_mdu) , 
.mdu_busy_to_stallwb(mdu_busy_from_mdu) , 
.mdu_finish_to_stallwb(mdu_finish_from_mdu) ,		
.mdu_result_to_stallwb(mdu_result_from_mdu) ,	

.ls_to_wblsu(ls_from_idexlsu),
.ls_addr_error_to_wblsu(ls_addr_error_from_idexlsu),
.ls_addr_to_lsuwb(ls_addr_from_idexlsu) ,
.load_info_to_wblsu(load_info_from_idexlsu),
.store_result_to_ram(store_result_to_ram),
.rd_index_to_wblsu(rd_index_from_idexlsu) ,
.rden_to_wblsu(rden_from_idexlsu) 	,

.fence_to_wb(fence_from_idex)   ,
.fencei_to_wb(fencei_from_idex)  ,
.ecall_to_wb(ecall_from_idex)   ,
.ebreak_to_wb(ebreak_from_idex)  ,
.mret_to_wb(mret_from_idex)    ,
.wfi_to_wb(wfi_from_idex)    ,

.rs1_to_forward_unit(forwardrs1_from_idex),
.rs2_to_forward_unit(forwardrs2_from_idex) ,
.rs1_en_to_forward_unit(forwardrs1_en_from_idex),
.rs2_en_to_forward_unit(forwardrs2_en_from_idex),	

.rs1_to_stallunit(stallrs1_from_idex),
.rs2_to_stallunit(stallrs2_from_idex),	
.rd_to_stallunit(stallrd_from_idex),	
.md_to_stallunit(md_from_idex),
.rs1_en_to_stallunit(stallrs1_en_from_idex),
.rs2_en_to_stallunit(stallrs2_en_from_idex),	
.rd_en_to_stallunit(stallrd_en_from_idex)

);

//commit unit input
wire						flush_to_cmt = flush_from_flushunit;
wire						stall_to_cmt = stall_from_stallunit;

wire						rd_en_to_cmt = rd_en_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	rd_to_cmt = rd_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0]  	pc_to_cmt = pc_from_idex;
wire[`ZCRV_INSTR_SIZE-1:0] 	inst_to_cmt = inst_from_idex;
wire 						inst_ilegl_to_cmt = inst_ilegl_from_idex ;
wire 						pc_misalgn_to_cmt = pc_misalgn_from_idex ;
wire 						ifetch_buserr_to_cmt = ifetch_buserr_from_idex ;  

wire						need_jump_to_cmt = need_jump_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0]  	jump_dest_to_cmt = jump_dest_from_idex;
wire						bxx_pre_hit_to_cmt = bxx_pre_hit_from_idex;
wire						op_bxx_to_cmt = op_bxx_from_idex;
wire[`ZCRV_XLEN-1:0]     	rd_result_to_cmt = rd_result_from_idex;

wire[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_to_cmt = mdu_now_rd_from_mdu;    										
wire						mdu_busy_to_cmt = mdu_busy_from_mdu; 
wire						mdu_finish_to_cmt  = mdu_finish_from_mdu;		
wire[`ZCRV_XLEN-1:0] 		mdu_result_to_cmt  = mdu_result_from_mdu;	

wire 						ls_to_cmt = ls_from_idexlsu;
wire 						ls_addr_error_to_cmt = ls_addr_error_from_idexlsu;
wire[31:0] 					ls_addr_to_cmt  = ls_addr_from_idexlsu;
wire[4:0] 					load_info_to_cmt = load_info_from_idexlsu;
wire[4:0] 					rd_index_to_cmt = rd_index_from_idexlsu;
wire 						rden_to_cmt = rden_from_idexlsu 	;


wire[31:0]					mtvec_to_cmt = mtvec_from_csr;
wire[31:0]					mstatus_to_cmt = mstatus_from_csr;
wire[31:0]					mepc_to_cmt = mepc_from_csr;	
wire[31:0]					mie_to_cmt = mie_from_csr;	

wire 						fence_to_cmt = fence_from_idex   ;
wire 						fencei_to_cmt = fencei_from_idex ;
wire 						ecall_to_cmt = ecall_from_idex  ;
wire 						ebreak_to_cmt = ebreak_from_idex ;
wire 						mret_to_cmt =  mret_from_idex  ;
wire 						wfi_to_cmt = wfi_from_idex    ;

// output

wire[`ZCRV_ADDR_SIZE-1:0] 	real_jump_dest_from_cmt;
wire						prefixflush_from_cmt;

wire						trap_return_from_cmt;
wire						trap_en_from_cmt;
wire						eiuflush_from_cmt;
wire[`ZCRV_ADDR_SIZE-1:0] 	flush_addr_from_cmt;
wire[31:0] 					mepc_from_cmt;
wire[31:0] 					mtval_from_cmt ;
wire[31:0] 					mcause_from_cmt ;

wire[`ZCRV_XLEN-1:0]		rd_data_from_cmt ;
wire   					 	rd_en_from_cmt ;
wire[`ZCRV_REG_SIZE-1:0]	rd_index_from_cmt;
wire						inst_finish_from_cmt;

cmt_unit cmt_unit (

.flush_from_flushunit(flush_to_cmt),
.stall_from_stallunit(stall_to_cmt),

.ext_irq(ext_irq),  
.time_irq(time_irq),
.soft_irq(soft_irq), 

.rd_en_from_idex(rd_en_to_cmt),
.rd_from_idex(rd_to_cmt),
.pc_from_idex(pc_to_cmt),
.inst_from_idex(inst_to_cmt),
.inst_ilegl_from_idex(inst_ilegl_to_cmt),
.pc_misalgn_from_idex(pc_misalgn_to_cmt),
.ifetch_buserr_from_idex(ifetch_buserr_to_cmt),  

.need_jump_from_idex(need_jump_to_cmt),
.jump_dest_from_idex(jump_dest_to_cmt),
.bxx_pre_hit_from_idex(bxx_pre_hit_to_cmt),
.op_bxx_from_idex(op_bxx_to_cmt),
.rd_result_from_idex(rd_result_to_cmt),

.mdu_now_rd_from_mdu(mdu_now_rd_to_cmt),    										
.mdu_busy_from_mdu(mdu_busy_to_cmt), 
.mdu_finish_from_mdu(mdu_finish_to_cmt),		
.mdu_result_from_mdu(mdu_result_to_cmt),	

.ls_from_idexlsu(ls_to_cmt),
.ls_addr_error_from_idexlsu(ls_addr_error_to_cmt),
.ls_addr_from_idexlsu(ls_addr_to_cmt),
.load_info_from_idexlsu(load_info_to_cmt),
.rd_index_from_idexlsu(rd_index_to_cmt),
.rden_from_idexlsu(rden_to_cmt),
.res_from_dtcm(res_from_dtcm),
.data_from_dtcm(data_from_dtcm),
.res_from_itcm(res_from_itcm),
.data_from_itcm(data_from_itcm),

.mtvec_from_csr(mtvec_to_cmt),
.mstatus_from_csr(mstatus_to_cmt),
.mepc_from_csr(mepc_to_cmt),	
.mie_from_csr(mie_to_cmt),	

.fence_from_idex(fence_to_cmt),
.fencei_from_idex(fencei_to_cmt),
.ecall_from_idex(ecall_to_cmt),
.ebreak_from_idex(ebreak_to_cmt),
.mret_from_idex(mret_to_cmt),
.wfi_from_idex(wfi_to_cmt),

.bxxjump_success_to_bpu (bxxjump_success_from_cmt),
.bxxjump_fail_to_bpu (bxxjump_fail_from_cmt),
.fix_pc_to_bpu(fix_pc_from_cmt),
.real_jump_dest_to_flushunit(real_jump_dest_from_cmt),
.prefixflush_to_flushunit(prefixflush_from_cmt),

.trap_return_to_csr(trap_return_from_cmt),
.trap_en_to_csr(trap_en_from_cmt),
.eiuflush_to_flushunit(eiuflush_from_cmt),
.flush_addr_to_flushunit(flush_addr_from_cmt),
.mepc_to_csr(mepc_from_cmt),
.mtval_to_csr(mtval_from_cmt),
.mcause_to_csr(mcause_from_cmt),

.rd_data_to_reg(rd_data_from_cmt),
.rd_en_to_reg(rd_en_from_cmt),
.rd_index_to_reg(rd_index_from_cmt),
.inst_finish_to_csr(inst_finish_from_cmt)

);


// regfile
wire[`ZCRV_REG_SIZE-1:0] 	rs1_index_to_reg = rs1_from_idex;
wire[`ZCRV_REG_SIZE-1:0] 	rs2_index_to_reg = rs2_from_idex;
wire						rs1_en_to_reg = rs1_en_from_idex;
wire						rs2_en_to_reg = rs2_en_from_idex;
wire						rd_wr_en_to_reg = rd_en_from_cmt;
wire[`ZCRV_REG_SIZE-1:0]   rd_index_to_reg = rd_index_from_cmt;
wire[`ZCRV_XLEN-1:0] 		rd_data_to_reg = rd_data_from_cmt;



regfile regfile(

.clk(clk),
.rst_n(rst_n),


.rs1_index(rs1_index_to_reg),
.rs2_index(rs2_index_to_reg),
.rs1_en(rs1_en_to_reg),
.rs2_en(rs2_en_to_reg),

.rd_wr_en(rd_wr_en_to_reg),
.rd_index(rd_index_to_reg), 
.rd_data(rd_data_to_reg),

.rs1_data(rs1_data_from_reg),
.rs2_data(rs2_data_from_reg)

  );


//csr
wire							trap_en_to_csr = trap_en_from_cmt;
wire							inst_finish_to_csr = inst_finish_from_cmt;

wire[`ZCRV_CSRADDR_SIZE-1:0] 	csr_index_to_csr = csr_index_from_idex;
wire							csr_en_to_csr = csr_en_from_idex;
wire							csr_wr_en_to_csr = csr_wr_en_from_idex;
wire							csr_rd_en_to_csr = csr_rd_en_from_idex;
wire[`ZCRV_XLEN-1:0]			csr_wr_data_to_csr = csr_wr_data_from_idex;
wire							mret_commit_to_csr = trap_return_from_cmt;
wire[`ZCRV_ADDR_SIZE-1:0]		mepc_from_eiu_to_csr = mepc_from_cmt;
wire[`ZCRV_XLEN-1:0]			mcause_from_eiu_to_csr = mcause_from_cmt;
wire[`ZCRV_XLEN-1:0]			mtval_from_eiu_to_csr = mtval_from_cmt;




csr csr(
.clk(clk),
.rst_n(rst_n),

.ext_irq(ext_irq),  //外部中断
.time_irq(time_irq), //计时器中断
.soft_irq(soft_irq), //软件中断
.trap_en(trap_en_to_csr),
.inst_finish(inst_finish_to_csr),

.csr_index(csr_index_to_csr),
.csr_en(csr_en_to_csr),
.csr_wr_en(csr_wr_en_to_csr),
.csr_rd_en(csr_rd_en_to_csr),
.csr_wr_data(csr_wr_data_to_csr),
.mret_commit(mret_commit_to_csr),
.mepc_from_eiu(mepc_from_eiu_to_csr),
.mcause_from_eiu(mcause_from_eiu_to_csr),
.mtval_from_eiu(mtval_from_eiu_to_csr),



.csr_rd_data(dest_csr_data_from_csr),
.mtvec_r(mtvec_from_csr),
.mstatus_r(mstatus_from_csr),
.mepc_r(mepc_from_csr),		
.mie_r(mie_from_csr)				

);

//flush
wire						prefix_flush_to_flushunit = prefixflush_from_cmt;
wire[`ZCRV_ADDR_SIZE-1:0] 	prefix_jump_to_flushunit = real_jump_dest_from_cmt;
wire						eiuflush_to_flushunit = eiuflush_from_cmt;
wire[`ZCRV_ADDR_SIZE-1:0]   eiuflush_addr_to_flushunit = flush_addr_from_cmt;




flush_unit flush_unit(
.flush_from_predict_fix(prefix_flush_to_flushunit),
.pcfix_from_predict_fix(prefix_jump_to_flushunit),
.flush_from_eiu(eiuflush_to_flushunit),
.flush_addr_from_eiu(eiuflush_addr_to_flushunit),

.flush_pc_to_pipeline(flush_pc_from_flushunit),
.flush_to_pipeline(flush_from_flushunit)

);

//stall
//from mdu
wire						busy_to_stallunit = mdu_busy_from_mdu;
wire						finish_to_stallunit = mdu_finish_from_mdu;
wire[`ZCRV_REG_SIZE-1:0]	mdurd_to_stallunit = mdu_now_rd_from_mdu;


//from other clk id;

wire[`ZCRV_REG_SIZE-1:0]	idexrs1_to_stallunit = stallrs1_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	idexrs2_to_stallunit = stallrs2_from_idex;	
wire[`ZCRV_REG_SIZE-1:0]	idexrd_to_stallunit = stallrd_from_idex;
wire 						md_to_stallunit = md_from_idex;
wire					 	rs1_en_to_stallunit = stallrs1_en_from_idex;
wire						rs2_en_to_stallunit = stallrs2_en_from_idex;	
wire					 	rd_en_to_stallunit = stallrd_en_from_idex;


stall_unit stall_unit(

//from mdu
.busy_from_mdu(busy_to_stallunit),
.finish_from_mdu(finish_to_stallunit),
.rd_from_mdu(mdurd_to_stallunit),


//from other clk id/ex stage

.rs1_from_id(idexrs1_to_stallunit),
.rs2_from_id(idexrs2_to_stallunit),	
.rd_from_id(idexrd_to_stallunit),	
.md_from_id(md_to_stallunit),
.rs1_en_from_id(rs1_en_to_stallunit),
.rs2_en_from_id(rs2_en_to_stallunit),	
.rd_en_from_id(rd_en_to_stallunit),

//to stall pipeline
.pipe_stall(stall_from_stallunit)


);

//forward
wire[31:0]					cmt_rddata_to_forwardunit = rd_data_from_cmt;
wire[`ZCRV_REG_SIZE-1:0]	cmt_rd_to_forwardunit = rd_index_from_cmt;
wire						cmt_rd_en_to_forwardunit = rd_en_from_cmt;

wire[`ZCRV_REG_SIZE-1:0]	idex_rs1_to_forwardunit = forwardrs1_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	idex_rs2_to_forwardunit = forwardrs2_from_idex;
wire					 	idex_rs1_en_to_forwardunit = forwardrs1_en_from_idex;
wire						idex_rs2_en_to_forwardunit = forwardrs2_en_from_idex;	



forward_unit forward_unit(

.rddata_from_wb(cmt_rddata_to_forwardunit),
.rd_from_wb(cmt_rd_to_forwardunit),
.rd_en_from_wb(cmt_rd_en_to_forwardunit),

.rs1_from_id(idex_rs1_to_forwardunit),
.rs2_from_id(idex_rs2_to_forwardunit),
.rs1_en_from_id(idex_rs1_en_to_forwardunit),
.rs2_en_from_id(idex_rs2_en_to_forwardunit),	
	


.rddata_to_rs2_to_id(rddata_to_rs2_from_forwardunit),
.rddata_to_rs1_to_id(rddata_to_rs1_from_forwardunit),
.rd_to_rs1_to_id(rd_to_rs1_from_forwardunit),
.rd_to_rs2_to_id(rd_to_rs2_from_forwardunit)

);
endmodule