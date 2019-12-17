`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  predict_fix unit 

module predict_fix(

input						need_jump_from_idex, //jalr 或 bxx 需要跳
input						op_bxx_from_idex,
input[`ZCRV_ADDR_SIZE-1:0] 	jump_dest_from_idex,
input						bxx_pre_hit_from_idex,
input[`ZCRV_ADDR_SIZE-1:0]  bxx_pc_from_idex,

output						bxxjump_success_to_bpu ,
output						bxxjump_fail_to_bpu ,
output[`ZCRV_ADDR_SIZE-1:0] fix_pc_to_bpu,
output[`ZCRV_ADDR_SIZE-1:0] real_jump_dest_to_flushunit,
output						flush_to_flushunit
);

wire need_jump_but_no_pre = ~bxx_pre_hit_from_idex & op_bxx_from_idex & need_jump_from_idex;
wire no_jump_but_pre = bxx_pre_hit_from_idex & op_bxx_from_idex & ~need_jump_from_idex;
wire jalr_jump = need_jump_from_idex & ~op_bxx_from_idex ;


wire bxxjump_success = op_bxx_from_idex & need_jump_from_idex;
wire bxxjump_fail    = op_bxx_from_idex & ~need_jump_from_idex;						
						
wire real_need_jump = jalr_jump | need_jump_but_no_pre ;
				
wire need_flush = 	need_jump_but_no_pre | no_jump_but_pre | jalr_jump;

wire[`ZCRV_ADDR_SIZE-1:0] flush_pc = no_jump_but_pre ? bxx_pc_from_idex : 
										real_need_jump ? jump_dest_from_idex : 0 ;


wire[`ZCRV_ADDR_SIZE-1:0] fix_pc = bxxjump_fail | bxxjump_success ? bxx_pc_from_idex : 0;

assign bxxjump_success_to_bpu = bxxjump_success ;
assign bxxjump_fail_to_bpu = bxxjump_fail;
assign fix_pc_to_bpu = fix_pc;
assign flush_to_flushunit = need_flush ;
assign real_jump_dest_to_flushunit = flush_pc;
endmodule







