`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  jal/jalr bxx instruction control unit

module jump_unit(

input[7:0]				    jump_inst_info, 
input[`ZCRV_XLEN-1:0] 		rs1_jump ,
input[`ZCRV_XLEN-1:0] 		rs2_jump ,
input[`ZCRV_IMM_SIZE-1:0]	imm_jump ,
input						imm_en,
input						need_jump,
input						op_bxx,

input						jalr_need_rs1_from_id,
input[`ZCRV_ADDR_SIZE-1:0]	input_pc, //pc_present_to_idex

output[`ZCRV_XLEN-1:0] 		jump_write_result,
output[`ZCRV_ADDR_SIZE-1:0] jump_dest,
output						jump_whether_or_not

);
/*
wire[11:0] jump_info = {
				rv32i_beq, 
				rv32i_bne ,
				rv32i_blt ,
				rv32i_bge ,
				rv32i_bltu,
				rv32i_bgeu,
				rv32i_jal,
				rv32i_jalr,
				4'b0
};*/





//jal 在ifstage已经无条件跳转了，在只需要计算要存入rd的值

wire	op_jal = jump_inst_info[1] ;
wire[`ZCRV_XLEN-1:0] jal_jalr_result = input_pc + 32'h4;


//jalr

wire	op_jalr = jump_inst_info[0] ;

//beq

wire op_beq = jump_inst_info[7] ;


wire beq_jump = (rs1_jump == rs2_jump);

//bne

wire op_bne = jump_inst_info[6] ;


wire bne_jump = (rs1_jump != rs2_jump);


//blt

wire op_blt = jump_inst_info[5] ;


wire blt_jump = ($signed(rs1_jump) < $signed(rs2_jump));


//bge

wire op_bge = jump_inst_info[4] ;


wire bge_jump = ($signed(rs1_jump) >= $signed(rs2_jump));

//bltu

wire op_bltu = jump_inst_info[3] ;


wire bltu_jump = (rs1_jump < rs2_jump);


//bgeu

wire op_bgeu = jump_inst_info[2] ;


wire bgeu_jump = (rs1_jump >= rs2_jump);

//


wire[`ZCRV_ADDR_SIZE:0] bxx_dest_temp  = (~ op_jal) ? $signed({1'b0,input_pc}) + $signed({imm_jump[31],imm_jump}) : 0;
wire[`ZCRV_ADDR_SIZE:0] jalr_dest_temp = (~ op_jal) ? $signed({1'b0,rs1_jump}) + $signed({imm_jump[31],imm_jump}) : 0;
wire[`ZCRV_ADDR_SIZE-1:0] jump_dest_temp = (op_jalr ) ? jalr_dest_temp[31:0] : op_bxx ? bxx_dest_temp[31:0] : 0 ;

assign jump_whether_or_not =  need_jump  ? (op_bgeu & bgeu_jump) | (op_bge & bge_jump) |(op_bltu & bltu_jump) 
							|(op_blt & blt_jump) |(op_bne & bne_jump) |(op_beq & beq_jump) 
							| (op_jalr & jalr_need_rs1_from_id ) : 1'b0 ;
							
assign jump_dest =  jump_whether_or_not ? jump_dest_temp : 32'b0 ;

assign jump_write_result = ((op_jal | op_jalr) & need_jump) ? jal_jalr_result : 32'b0 ;

endmodule
			   