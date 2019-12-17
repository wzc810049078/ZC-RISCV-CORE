`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  中断/异常处理单元

module eiu(
input[`ZCRV_ADDR_SIZE-1:0]  pc_from_idex,
input[`ZCRV_INSTR_SIZE-1:0] inst_from_idex,
input[`ZCRV_ADDR_SIZE-1:0]  ram_addr_from_idex,


input 						ext_irq,  
input 						time_irq,
input 						soft_irq, 

input 						pc_misalgn_from_idex ,
input 						ifetch_buserr_from_idex ,  
input 						inst_ilegl_from_idex , 
input 						ebreak_from_idex ,  
input 						load_misalgn_from_lsu ,  
input 						load_buserr_from_lsu , 
input 						store_misalgn_from_lsu , 
input 						store_buserr_from_lsu , 
input 						ecall_from_idex , 

input 						fence_from_idex   ,
input 						fencei_from_idex  ,
input 						mret_from_idex    ,
input 						wfi_from_idex     ,
input[31:0]					mtvec_from_csr,
input[31:0]					mstatus_r,
input[31:0]					mepc_r,	
input[31:0]					mie_r,	

output						trap_return_to_csr,
output						trap_en,
output						error_to_wb,
output						flush_to_flushunit,
output[`ZCRV_ADDR_SIZE-1:0] flush_addr_to_flushunit,
output[31:0] 				mepc_to_csr,
output[31:0] 				mtval_to_csr ,
output[31:0] 				mcause_to_csr 


	





);

//fence fencei 冲刷流水线实现
wire fence_flush = fence_from_idex|fencei_from_idex ;
wire[31:0] fence_flush_pc = pc_from_idex + 32'd4;

//wfi 
//NOP
//中断
wire mie = mstatus_r[3] ; //全局中断使能 和异常无关
wire mpie = mstatus_r[7] ;
wire ext_irq_en = mie_r[11] ;
wire time_irq_en = mie_r[7];
wire sft_irq_en = mie_r[3] ;

//mret指令 退出异常
wire trap_return =  mret_from_idex ;
wire trap_return_flush = trap_return;
wire[31:0] trap_return_pc = trap_return_flush ? mepc_r : 0;
assign trap_return_to_csr = trap_return;


						


wire irq_req_pre = (ext_irq & ext_irq_en | time_irq & time_irq_en | soft_irq& sft_irq_en);
wire irq_req =  irq_req_pre & mie ;

//wire irq_flush = irq_req ;
//wire irq_pc = trap_pc ;


//异常
wire pc_misalgn = pc_misalgn_from_idex ; 
wire ifetch_buserr = ifetch_buserr_from_idex ;  
wire inst_ilegl = inst_ilegl_from_idex ; 
wire breakpoint = ebreak_from_idex ;  
wire load_misalgn = load_misalgn_from_lsu ;  
wire load_buserr = load_buserr_from_lsu ; 
wire store_misalgn = store_misalgn_from_lsu ; 
wire store_buserr = store_buserr_from_lsu ; 
wire envorimentcall = ecall_from_idex ; 

wire excp_req_pre = pc_misalgn|ifetch_buserr|inst_ilegl
					|breakpoint|load_misalgn|load_buserr
					|store_misalgn|store_buserr|envorimentcall;
					
assign error_to_wb = excp_req_pre;					
wire excp_req =  excp_req_pre  ;

//wire excp_flush = excp_req ;
//wire excp_pc = trap_pc ;

assign trap_en = excp_req | irq_req;


//异常返回地址写入	
wire excp_without_ecall_ebreak =pc_misalgn|ifetch_buserr|inst_ilegl
					|load_misalgn|load_buserr|store_misalgn|store_buserr;	
wire[31:0] mepc_to_csr_t =  excp_without_ecall_ebreak ? pc_from_idex : 
								 envorimentcall | breakpoint  ? pc_from_idex + 4 :
								 irq_req ? pc_from_idex + 4 : 0 ;
assign mepc_to_csr = trap_en ? mepc_to_csr_t : 0 ;
//异常信息写入
wire lsu_error = load_misalgn|load_buserr|store_misalgn|store_buserr;
wire ifetch_error = pc_misalgn|ifetch_buserr;

wire[31:0] mtval_to_csr_t = lsu_error | breakpoint ? ram_addr_from_idex :
						ifetch_error ? pc_from_idex :
						inst_ilegl ? inst_from_idex : 0;
						
assign mtval_to_csr = trap_en ? mtval_to_csr_t : 0 ;
						

					

//中断原因
wire[31:0] irq_cause ;
assign irq_cause[31] = 1'b1;
assign irq_cause[30:4] = 27'b0;
assign irq_cause[3:0] = soft_irq ? 4'd3 : time_irq ? 4'd7 : ext_irq ? 4'd11:4'b0;

//异常原因

wire[31:0] excp_cause ;
assign excp_cause[31:5] = 27'b0;
assign excp_cause[4:0] = pc_misalgn ? 5'd0 
					     : ifetch_buserr ? 5'd1
						 : inst_ilegl ? 5'd2
						 : breakpoint ? 5'd3 
						 : load_misalgn ? 5'd4
						 : load_buserr ? 5'd5 
						 : store_misalgn ? 5'd6
						 : store_buserr  ? 5'd7
						 : envorimentcall ? 5'd11 :5'b01111;
						 
wire[31:0] trap_cause = excp_req ? excp_cause : irq_cause ;

assign mcause_to_csr = trap_en ? trap_cause : 0;


//异常发生时，跳转地址
wire mtvec_mode = mtvec_from_csr[0]  ;
wire[31:0] trap_pc =  ~mtvec_mode ?  {mtvec_from_csr[31:2] , 2'b00} : 
						{mtvec_from_csr[31:2] , 2'b00} + {trap_cause[29:0] , 2'b00} ;

		

//flush产生		
assign flush_to_flushunit = fence_flush|trap_return_flush|trap_en ;
assign flush_addr_to_flushunit = trap_en ? trap_pc : 
									fence_flush ? fence_flush_pc :
										trap_return_flush ? trap_return_pc : 0;
										
endmodule


									