`include "defines.v"

// Designer   : WANG ZI CHEN
// instruction fetch unit 

module ifu(
input						clk,
input						rst_n,
// from itcm
input						itcm_ready,
input[`ZCRV_INSTR_SIZE-1:0]	itcm_inst,
//from id/ex wb
input[`ZCRV_ADDR_SIZE-1:0]  flush_pc,						
input						pipe_flush, 
input						stall_from_stallunit,
//from fix unit
input						fix_success,
input						fix_fail,
input[`ZCRV_ADDR_SIZE-1:0]  fix_pc,

//to itcm
output[`ZCRV_ADDR_SIZE-1:0] pc_to_itcm,
output                      ifu_to_itcm_req,
//to id/ex
output[`ZCRV_ADDR_SIZE-1:0] pc_present_to_idex,
output[`ZCRV_ADDR_SIZE-1:0] pc_next_to_idex,
output[`ZCRV_INSTR_SIZE-1:0]inst_to_idex,
output						predict_hit,
output 						pc_misalgn_to_idex ,
output 						ifetch_buserr_to_idex ,  
output						jalr_need_rs1_to_idex

);


wire pre_pc_vaild,jalr_need_rs1;
wire[`ZCRV_ADDR_SIZE-1:0] predict_pc;
wire[`ZCRV_IMM_SIZE-1:0]  jump_need_op1;
wire[`ZCRV_IMM_SIZE-1:0]  jump_need_op2;
wire					  jalr_need_rs1x0;
wire[`ZCRV_ADDR_SIZE-1:0] pc_present,pc_next;
wire[`ZCRV_INSTR_SIZE-1:0]inst_present_pre = itcm_ready ? itcm_inst : 0;
wire pc_misalgn_to_idex_t = 0;
wire ifetch_buserr_to_idex_t = ~pc_next[31];
wire[`ZCRV_INSTR_SIZE-1:0]inst_present = pc_misalgn_to_idex_t | ifetch_buserr_to_idex_t ? 0 : inst_present_pre;

reg pc_misalgn_to_idex_r ;
reg ifetch_buserr_to_idex_r ;
reg[`ZCRV_ADDR_SIZE-1:0]  pc_present_r,pc_next_r;
reg[`ZCRV_INSTR_SIZE-1:0] inst_to_idex_r;
reg						  predict_hit_r,jalr_need_rs1_r;


always @(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		pc_present_r <= 0 ;
		pc_next_r    <= 32'b0111_1111_1111_1111_1111_1111_1111_1100 ;
		inst_to_idex_r <= 0;
		predict_hit_r  <= 0;
		jalr_need_rs1_r<= 0;
		pc_misalgn_to_idex_r <= 0;
		ifetch_buserr_to_idex_r <= 0;
		
		end
		else if(pipe_flush)
		begin
		pc_present_r <= 0 ;
		pc_next_r    <= pc_next ;
		inst_to_idex_r <= 0;
		predict_hit_r  <= 0;
		jalr_need_rs1_r<= 0;
		pc_misalgn_to_idex_r <= 0;
		ifetch_buserr_to_idex_r <= 0;
		end
		else if (stall_from_stallunit)
		begin
		pc_present_r <= pc_present_r ;
		pc_next_r    <= pc_next_r ;
		inst_to_idex_r <= inst_to_idex_r;
		predict_hit_r  <= predict_hit_r;
		jalr_need_rs1_r<= jalr_need_rs1_r;
		pc_misalgn_to_idex_r <= pc_misalgn_to_idex_r;
		ifetch_buserr_to_idex_r <= ifetch_buserr_to_idex_r;
		end
		else begin
		pc_present_r <= pc_present ;
		pc_next_r    <= pc_next ;
		inst_to_idex_r <= inst_present;
		predict_hit_r  <= pre_pc_vaild;
		jalr_need_rs1_r <= jalr_need_rs1;
		pc_misalgn_to_idex_r <= pc_misalgn_to_idex_t;
		ifetch_buserr_to_idex_r <= ifetch_buserr_to_idex_t;
		end

end


assign pc_present_to_idex = pc_present_r;
assign pc_next_to_idex = pc_next_r;
assign pc_present = pc_next_r;
assign inst_to_idex = inst_to_idex_r;
assign predict_hit = predict_hit_r;
assign jalr_need_rs1_to_idex = jalr_need_rs1_r;
assign pc_to_itcm = pc_next ;
assign ifu_to_itcm_req = 1'b1 ;
assign pc_misalgn_to_idex = pc_misalgn_to_idex_r;
assign ifetch_buserr_to_idex = ifetch_buserr_to_idex_r ;




bpu bpu(
.clk(clk),
.rst_n(rst_n),


.predict_inst_pc(pc_present),
.predict_inst(itcm_inst),
.fix_pc(fix_pc),
.presuccess(fix_success),
.prefail(fix_fail),


.pre_pc_vaild(pre_pc_vaild),
.jump_need_op1(jump_need_op1),
.jump_need_op2(jump_need_op2),
.jalr_need_rs1x0(jalr_need_rs1x0),
.jalr_need_rs1(jalr_need_rs1)



);


pgu pgu(

.stall_from_stallunit(stall_from_stallunit),
.flush_pc(flush_pc),						
.pipe_flush(pipe_flush), 
.pc_present(pc_present),
.pre_pc_vaild(pre_pc_vaild),
.jump_need_op1(jump_need_op1),
.jump_need_op2(jump_need_op2),
.jalr_need_rs1x0(jalr_need_rs1x0),
.jalr_need_rs1(jalr_need_rs1),
.pc_next(pc_next)

);

endmodule