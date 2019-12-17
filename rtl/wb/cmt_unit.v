`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  commit unit/stage 
// RV32IM zicsr zifence

module cmt_unit (

input						flush_from_flushunit,
input						stall_from_stallunit,

input   					ext_irq,  
input						time_irq,
input						soft_irq, 

input						rd_en_from_idex,
input[`ZCRV_REG_SIZE-1:0]	rd_from_idex,
input[`ZCRV_ADDR_SIZE-1:0]  pc_from_idex,
input[`ZCRV_INSTR_SIZE-1:0] inst_from_idex,
input 						inst_ilegl_from_idex ,
input 						pc_misalgn_from_idex ,
input 						ifetch_buserr_from_idex ,  

input						need_jump_from_idex,
input[`ZCRV_ADDR_SIZE-1:0]  jump_dest_from_idex,
input						bxx_pre_hit_from_idex,
input						op_bxx_from_idex,
input[`ZCRV_XLEN-1:0]       rd_result_from_idex,

input[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_from_mdu ,    										
input						mdu_busy_from_mdu , 
input						mdu_finish_from_mdu ,		
input[`ZCRV_XLEN-1:0] 		mdu_result_from_mdu ,	

input 						ls_from_idexlsu,
input 						ls_addr_error_from_idexlsu,
input[31:0] 				ls_addr_from_idexlsu ,
input[4:0] 					load_info_from_idexlsu,
input[4:0] 					rd_index_from_idexlsu ,
input 						rden_from_idexlsu 	,
input						res_from_dtcm,
input[`ZCRV_XLEN-1:0]		data_from_dtcm,
input						res_from_itcm,
input[`ZCRV_XLEN-1:0]		data_from_itcm,

input[31:0]					mtvec_from_csr,
input[31:0]					mstatus_from_csr,
input[31:0]					mepc_from_csr,	
input[31:0]					mie_from_csr,	

input 						fence_from_idex   ,
input 						fencei_from_idex  ,
input 						ecall_from_idex   ,
input 						ebreak_from_idex  ,
input 						mret_from_idex    ,
input 						wfi_from_idex     ,


output						bxxjump_success_to_bpu ,
output						bxxjump_fail_to_bpu ,
output[`ZCRV_ADDR_SIZE-1:0] fix_pc_to_bpu,
output[`ZCRV_ADDR_SIZE-1:0] real_jump_dest_to_flushunit,
output						prefixflush_to_flushunit,

output						trap_return_to_csr,
output						trap_en_to_csr,
output						eiuflush_to_flushunit,
output[`ZCRV_ADDR_SIZE-1:0] flush_addr_to_flushunit,
output[31:0] 				mepc_to_csr,
output[31:0] 				mtval_to_csr ,
output[31:0] 				mcause_to_csr ,

output[`ZCRV_XLEN-1:0]		rd_data_to_reg ,
output   					rd_en_to_reg ,
output[`ZCRV_REG_SIZE-1:0]	rd_index_to_reg,
output						inst_finish_to_csr

);
//prefix input
wire						need_jump_to_prefix = need_jump_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0]   jump_dest_to_prefix = jump_dest_from_idex;
wire						bxx_pre_hit_to_prefix = bxx_pre_hit_from_idex;
wire						op_bxx_to_prefix = op_bxx_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0]   pc_to_prefix = pc_from_idex;

//prefix output
wire						bxxjump_success_from_prefix ;
wire						bxxjump_fail_from_prefix ;
wire[`ZCRV_ADDR_SIZE-1:0]   fix_pc_from_prefix;
wire[`ZCRV_ADDR_SIZE-1:0]   real_jump_dest_from_prefix;
wire						flush_from_prefix;


predict_fix predict_fix(
.need_jump_from_idex(need_jump_to_prefix), //jalr 或 bxx 需要跳
.op_bxx_from_idex(op_bxx_to_prefix),
.jump_dest_from_idex(jump_dest_to_prefix),
.bxx_pre_hit_from_idex(bxx_pre_hit_to_prefix),
.bxx_pc_from_idex(pc_to_prefix),

.bxxjump_success_to_bpu(bxxjump_success_from_prefix),
.bxxjump_fail_to_bpu(bxxjump_fail_from_prefix) ,
.fix_pc_to_bpu(fix_pc_from_prefix),
.real_jump_dest_to_flushunit(real_jump_dest_from_prefix),
.flush_to_flushunit(flush_from_prefix)
	);


//lsu_wb input
wire 					ls_to_lsuwb = ls_from_idexlsu;
wire 				    ls_addr_error_to_lsuwb = ls_addr_error_from_idexlsu;
wire[4:0] 				load_info_to_lsuwb = load_info_from_idexlsu;
wire[4:0] 				rd_index_to_lsuwb = rd_index_from_idexlsu;
wire 					rden_to_lsuwb = rden_from_idexlsu	;

//lsu_wb output

wire[4:0] 				rd_index_from_lsuwb ;
wire[`ZCRV_XLEN-1:0]	rd_data_from_lsuwb ;
wire 					lsu_need_wb_from_lsuwb ;
wire					store_success_from_lsuwb ;
wire					load_success_from_lsuwb ;

wire 					load_misalgn_from_lsuwb ;  
wire 					load_buserr_from_lsuwb ; 
wire 					store_misalgn_from_lsuwb ; 
wire 					store_buserr_from_lsuwb ;


lsu_wb lsu_wb(

.ls_from_idex(ls_to_lsuwb),
.ls_addr_error_from_idex(ls_addr_error_to_lsuwb),
.load_info_from_idex(load_info_to_lsuwb),
.rd_index_from_idex(rd_index_to_lsuwb) ,
.rden_from_idex(rden_to_lsuwb) 	,

.res_from_dtcm(res_from_dtcm),
.data_from_dtcm(data_from_dtcm),

.res_from_itcm(res_from_itcm),
.data_from_itcm(data_from_itcm),

.rd_index_to_wb(rd_index_from_lsuwb) , 
.rd_data_to_wb(rd_data_from_lsuwb) ,
.lsu_need_wb_to_wb(lsu_need_wb_from_lsuwb) ,
.store_success_to_wb(store_success_from_lsuwb) ,
.load_success_to_wb(load_success_from_lsuwb) ,

.load_misalgn_to_eiu(load_misalgn_from_lsuwb) ,  
.load_buserr_to_eiu(load_buserr_from_lsuwb) , 
.store_misalgn_to_eiu(store_misalgn_from_lsuwb) , 
.store_buserr_to_eiu(store_buserr_from_lsuwb) 

);

//eiu input 
wire[`ZCRV_ADDR_SIZE-1:0]   pc_to_eiu = pc_from_idex;
wire[`ZCRV_INSTR_SIZE-1:0]  inst_to_eiu = inst_from_idex;
wire[`ZCRV_ADDR_SIZE-1:0]   ram_addr_to_eiu = ls_from_idexlsu ? ls_addr_from_idexlsu : 0 ;

wire 						pc_misalgn_to_eiu = pc_misalgn_from_idex;
wire 						ifetch_buserr_to_eiu = ifetch_buserr_from_idex;  
wire 						inst_ilegl_to_eiu = inst_ilegl_from_idex; 
wire						ebreak_to_eiu = ebreak_from_idex;  
wire 						load_misalgn_to_eiu = load_misalgn_from_lsuwb;  
wire 						load_buserr_to_eiu = load_buserr_from_lsuwb; 
wire 						store_misalgn_to_eiu = store_misalgn_from_lsuwb; 
wire 						store_buserr_to_eiu = store_buserr_from_lsuwb; 
wire 						ecall_to_eiu = ecall_from_idex; 

wire 						fence_to_eiu =  fence_from_idex;
wire 						fencei_to_eiu = fencei_from_idex;
wire 						mret_to_eiu =   mret_from_idex;
wire 						wfi_to_eiu =    wfi_from_idex;
wire[31:0]					mtvec_to_eiu = mtvec_from_csr;
wire[31:0]					mstatus_to_eiu = mstatus_from_csr;
wire[31:0]					mepc_to_eiu = mepc_from_csr;	
wire[31:0]					mie_to_eiu = mie_from_csr;	

//eiu output
wire						trap_return_from_eiu;
wire						trap_en_from_eiu;
wire						error_from_eiu;
wire						flush_from_eiu;
wire[`ZCRV_ADDR_SIZE-1:0] 	flush_addr_from_eiu;
wire[31:0] 					mepc_from_eiu;
wire[31:0] 					mtval_from_eiu ;
wire[31:0] 					mcause_from_eiu;



eiu eiu(
.pc_from_idex(pc_to_eiu),
.inst_from_idex(inst_to_eiu),
.ram_addr_from_idex(ram_addr_to_eiu),


.ext_irq(ext_irq),  
.time_irq(time_irq),
.soft_irq(soft_irq), 

.pc_misalgn_from_idex(pc_misalgn_to_eiu) ,
.ifetch_buserr_from_idex(ifetch_buserr_to_eiu) ,  
.inst_ilegl_from_idex(inst_ilegl_to_eiu) , 
.ebreak_from_idex(ebreak_to_eiu) ,  
.load_misalgn_from_lsu(load_misalgn_to_eiu) ,  
.load_buserr_from_lsu(load_buserr_to_eiu) , 
.store_misalgn_from_lsu(store_misalgn_to_eiu) , 
.store_buserr_from_lsu(store_buserr_to_eiu) , 
.ecall_from_idex(ecall_to_eiu) , 

.fence_from_idex(fence_to_eiu)   ,
.fencei_from_idex(fencei_to_eiu)  ,
.mret_from_idex(mret_to_eiu)    ,
.wfi_from_idex(wfi_to_eiu)     ,
.mtvec_from_csr(mtvec_to_eiu),
.mstatus_r(mstatus_to_eiu),
.mepc_r(mepc_to_eiu),	
.mie_r(mie_to_eiu),	

.trap_return_to_csr(trap_return_from_eiu),
.trap_en(trap_en_from_eiu),
.error_to_wb(error_from_eiu),
.flush_to_flushunit(flush_from_eiu),
.flush_addr_to_flushunit(flush_addr_from_eiu),
.mepc_to_csr(mepc_from_eiu),
.mtval_to_csr (mtval_from_eiu),
.mcause_to_csr(mcause_from_eiu) 
);
//wb_unit input
wire						flush_to_wb_unit = flush_from_flushunit;
wire						stall_to_wb_unit = stall_from_stallunit;
wire						error_to_wb_unit = error_from_eiu;
wire						rd_en_to_wb_unit = rd_en_from_idex;
wire[`ZCRV_REG_SIZE-1:0]	rd_to_wb_unit = rd_from_idex;
wire[`ZCRV_XLEN-1:0]        rd_result_to_wb_unit = rd_result_from_idex;


wire[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_to_wb_unit = mdu_now_rd_from_mdu ;   
wire						mdu_busy_to_wb_unit = mdu_busy_from_mdu ; 
wire						mdu_finish_to_wb_unit = mdu_finish_from_mdu ;		
wire[`ZCRV_XLEN-1:0] 		mdu_result_to_wb_unit = mdu_result_from_mdu ;	

wire[4:0] 					rd_index_to_wb_unit = rd_index_from_lsuwb ; 
wire[`ZCRV_XLEN-1:0]		rd_data_to_wb_unit = rd_data_from_lsuwb ;
wire 						lsu_need_wb_to_wb_unit = lsu_need_wb_from_lsuwb;
wire						store_success_to_wb_unit = store_success_from_lsuwb ;

//wb_unit input
wire[`ZCRV_XLEN-1:0]		rd_data_from_wb_unit ;
wire   						rd_en_from_wb_unit  ;
wire[`ZCRV_REG_SIZE-1:0]	rd_index_from_wb_unit ;
wire						inst_finish_from_wb_unit ;

wb_unit wb_unit(

.flush_from_flushunit(flush_to_wb_unit),
.stall_from_stallunit(stall_to_wb_unit),
.error_from_eiu(error_to_wb_unit),
.rd_en_from_idex(rd_en_to_wb_unit),
.rd_from_idex(rd_to_wb_unit),
.rd_result_from_idex(rd_result_to_wb_unit),


.mdu_now_rd_from_mdu(mdu_now_rd_to_wb_unit) ,    	
.mdu_busy_from_mdu(mdu_busy_to_wb_unit) , 
.mdu_finish_from_mdu(mdu_finish_to_wb_unit) ,		
.mdu_result_from_mdu(mdu_result_to_wb_unit) ,	

.rd_index_from_lsu(rd_index_to_wb_unit) , 
.rd_data_from_lsu(rd_data_to_wb_unit) ,
.lsu_need_wb_from_lsu(lsu_need_wb_to_wb_unit) ,
.store_success_from_lsu(store_success_to_wb_unit) ,
.load_success_from_lsuwb(load_success_from_lsuwb),


.rd_data_to_reg(rd_data_from_wb_unit ) ,
.rd_en_to_reg(rd_en_from_wb_unit ) ,
.rd_index_to_reg(rd_index_from_wb_unit ),
.inst_finish_to_csr(inst_finish_from_wb_unit )


);


assign bxxjump_success_to_bpu = bxxjump_success_from_prefix;
assign bxxjump_fail_to_bpu = bxxjump_fail_from_prefix ;
assign fix_pc_to_bpu = fix_pc_from_prefix;
assign real_jump_dest_to_flushunit = real_jump_dest_from_prefix;
assign prefixflush_to_flushunit = flush_from_prefix;

assign trap_return_to_csr = trap_return_from_eiu;
assign trap_en_to_csr = trap_en_from_eiu;
assign eiuflush_to_flushunit = flush_from_eiu;
assign flush_addr_to_flushunit = flush_addr_from_eiu;
assign mepc_to_csr = mepc_from_eiu;
assign mtval_to_csr =  mtval_from_eiu;
assign mcause_to_csr =  mcause_from_eiu;

assign rd_data_to_reg =  rd_data_from_wb_unit;
assign rd_en_to_reg =  rd_en_from_wb_unit;
assign rd_index_to_reg = rd_index_from_wb_unit;
assign inst_finish_to_csr = inst_finish_from_wb_unit;



endmodule