`include "defines.v"

// Designer   : WANG ZI CHEN
// pc generate unit
module pgu(


input[`ZCRV_ADDR_SIZE-1:0]  flush_pc,						
input						pipe_flush,
input                       stall_from_stallunit,
input[`ZCRV_ADDR_SIZE-1:0]  pc_present,
input						pre_pc_vaild,
input[`ZCRV_IMM_SIZE-1:0]   jump_need_op1,
input[`ZCRV_IMM_SIZE-1:0]   jump_need_op2,
input						jalr_need_rs1x0,
input						jalr_need_rs1, //rs1 ！= x0 pc不变，等一周期exu计算出pc刷新
 
output[`ZCRV_ADDR_SIZE-1:0]	pc_next

);



assign pc_next = pipe_flush ? flush_pc : 
					stall_from_stallunit ? pc_present   :
						pre_pc_vaild ? ($signed(jump_need_op1) + $signed(jump_need_op2)) :
							jalr_need_rs1 ? pc_present :
								pc_present + 4;
						
endmodule