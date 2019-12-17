`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  exu


module exu(

input[`ZCRV_ADDR_SIZE-1:0]	input_pc, //pc_present_to_idex

//from decode
input[11:0]				    de_inst_info, 
input[`ZCRV_XLEN-1:0]		rs1_data,
input[`ZCRV_REG_SIZE-1:0]	rs1,
input[`ZCRV_XLEN-1:0]		rs2_data,
input[`ZCRV_REG_SIZE-1:0]	rd,
input						rs1_en,
input						rs2_en,
input						rd_en,
input						imm_en,
input[`ZCRV_IMM_SIZE-1:0]	imm,
input    					op_alu,
input    					op_system, // ecall ebreak wfi csr mret
input    					op_jump,
input						op_bxx,
//input						bxx_predict, 给predict fix unit




//csr
input[`ZCRV_CSRADDR_SIZE-1:0] op_csr_addr,
input						  jalr_need_rs1_from_id,
input[4:0]					  csri_uimm,
input[`ZCRV_XLEN-1:0] 		  dest_csr_data ,



//to csr unit
output[`ZCRV_CSRADDR_SIZE-1:0] 	csr_index,
output							csr_en,
output							csr_wr_en,
output							csr_rd_en,
output[`ZCRV_XLEN-1:0]			csr_wr_data,

//to next stage  predict_fix 
output[`ZCRV_XLEN-1:0] 		    write_back_rd,
output[`ZCRV_ADDR_SIZE-1:0] 	jump_dest,
output							jump_whether_or_not



);

wire need_alu = op_alu ;  //bxx需要比对值的大小
wire need_jump = op_jump ;
wire need_csru_csr = op_system & (|de_inst_info[11:9]);
wire need_csru_csri = op_system & (|de_inst_info[8:6]);
wire need_csru = need_csru_csr|need_csru_csri;



wire[`ZCRV_XLEN-1:0]	 rs1_to_alu =  (need_alu & rs1_en)  ?  rs1_data : 32'b0 ;
wire[`ZCRV_XLEN-1:0]	 rs2_to_alu =  (need_alu & rs2_en)  ?  rs2_data : 32'b0 ;
wire[`ZCRV_IMM_SIZE-1:0] imm_to_alu =  (need_alu & imm_en)  ?  imm : 32'b0 ;


wire[`ZCRV_XLEN-1:0]	 rs1_to_jump =  (need_jump & rs1_en)  ?  rs1_data : 32'b0 ;
wire[`ZCRV_XLEN-1:0]	 rs2_to_jump =  (need_jump & rs2_en)  ?  rs2_data : 32'b0 ;
wire[`ZCRV_IMM_SIZE-1:0] imm_to_jump =  (need_jump & imm_en)  ?  imm : 32'b0 ;


wire					 rd_x0 = (rd == 5'b00000);
wire					 rs1_x0 = (rs1 == 5'b00000);
wire[`ZCRV_XLEN-1:0]	 rs1_to_csru = (need_csru_csr & rs1_en)  ?  rs1_data : 32'b0 ;
wire[`ZCRV_CSRADDR_SIZE-1:0] csraddr_to_csru =  need_csru   ?  op_csr_addr : 12'b0 ;
wire[`ZCRV_IMM_SIZE-1:0] uimm_to_csru =  need_csru_csri   ? {27'b0 , csri_uimm}  : 32'b0 ;


//alu
wire[`ZCRV_XLEN-1:0] 		alu_result;
alu alu(

.de_inst_info(de_inst_info), 
.rs1_alu(rs1_to_alu) ,
.rs2_alu(rs2_to_alu) ,
.imm_alu(imm_to_alu) ,
.need_alu(need_alu),
.imm_en(imm_en),
.input_pc(input_pc), //pc_present_to_idex

.alu_result(alu_result)
);

//csru
csru csru(
.csr_inst_info(de_inst_info[11:6]), 
.dest_csr_data(dest_csr_data), //目标csr的数值
.rs1_csr(rs1_to_csru),
.uimm_csr(uimm_to_csru),
.need_csr(need_csru),

.op_csr_addr(csraddr_to_csru),
.rd_x0(rd_x0),
.rs1_x0(rs1_x0),


.csr_write_data(csr_wr_data),
.csr_rd_en(csr_rd_en),
.csr_wr_en(csr_wr_en)


);

//jumpunit
wire[`ZCRV_XLEN-1:0] 	jump_write_result;
jump_unit jpu(

.jump_inst_info(de_inst_info[11:4]), 
.rs1_jump(rs1_to_jump) ,
.rs2_jump(rs2_to_jump) ,
.imm_jump (imm_to_jump),
.imm_en(imm_en),
.need_jump(need_jump),
.op_bxx(op_bxx),


.jalr_need_rs1_from_id(jalr_need_rs1_from_id),
.input_pc(input_pc), //pc_present_to_idex

.jump_write_result(jump_write_result),
.jump_dest(jump_dest),
.jump_whether_or_not(jump_whether_or_not)

);



assign csr_en = csr_rd_en | csr_wr_en;
assign csr_index = op_csr_addr;
assign write_back_rd = op_alu ? alu_result : (op_jump & rd_en) ? jump_write_result : (need_csru&csr_rd_en) ? dest_csr_data : 32'b0 ;



endmodule
