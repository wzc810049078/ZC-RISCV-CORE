`include "defines.v"

// Designer   : WANG ZI CHEN
// branch predict unit

module bpu(
input						clk,rst_n,


input[`ZCRV_ADDR_SIZE-1:0] 	predict_inst_pc,
input[`ZCRV_INSTR_SIZE-1:0] predict_inst,
input[`ZCRV_ADDR_SIZE-1:0]	fix_pc,
input						presuccess,
input						prefail,


output						pre_pc_vaild,
output[`ZCRV_IMM_SIZE-1:0]  jump_need_op1,
output[`ZCRV_IMM_SIZE-1:0]  jump_need_op2,
output						jalr_need_rs1x0,
output						jalr_need_rs1



);
wire 		op_bxx,op_jal,op_jalr;
wire[`ZCRV_IMM_SIZE-1:0] jump_imm;
wire[`ZCRV_REG_SIZE-1:0] rs1;

predecode predecode(
.input_inst(predict_inst),

.op_jal(op_jal),
.op_bxx(op_bxx),
.op_jalr(op_jalr),
.jump_imm(jump_imm),
.need_imm(),
.rs1(rs1),
.rs2(),
.rd()
);


wire[9:0] 	pht_index = predict_inst_pc[11:2];
wire[9:0] 	fix_index = fix_pc[11:2];
assign		jalr_need_rs1x0 = (rs1 == 5'b0_0000) & op_jalr ;
assign		jalr_need_rs1 = op_jalr & ~jalr_need_rs1x0;
wire		pre_hit ;
wire		pre_bxxhit = pre_hit & op_bxx;
wire		pre_vaild = (pre_bxxhit | op_jal | jalr_need_rs1x0);
assign		jump_need_op1 = pre_vaild ? jump_imm : 32'b0;
assign		jump_need_op2 = jalr_need_rs1x0 ? 32'b0 : (pre_bxxhit | op_jal ) ? predict_inst_pc : 32'b0 ;

assign 		pre_pc_vaild = pre_vaild;

pht pht(
.clk(clk),
.rst_n(rst_n),
.pht_index(pht_index),
.op_bxx(op_bxx),
.fix_index(fix_index),
.presuccess(presuccess),
.prefail(prefail),

.pht_prehit(pre_hit)

);

endmodule
