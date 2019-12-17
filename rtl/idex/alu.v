`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  unit to calculate alu op

module alu(

input[11:0]				    de_inst_info, 
input[`ZCRV_XLEN-1:0] 		rs1_alu ,
input[`ZCRV_XLEN-1:0] 		rs2_alu ,
input[`ZCRV_IMM_SIZE-1:0]	imm_alu ,
input						need_alu,
input						imm_en,
input[`ZCRV_ADDR_SIZE-1:0]	input_pc, //pc_present_to_idex

output[`ZCRV_XLEN-1:0] 		alu_result
);
/*
wire[11:0] alu_info = {
				{rv32i_add | rv32i_addi},
				rv32i_sub,
				{rv32i_sll | rv32i_slli},
				{rv32i_sltu | rv32i_sltiu},
				{rv32i_xor | rv32i_xori},
				{rv32i_or | rv32i_ori},
				{rv32i_and | rv32i_andi},
				{rv32i_slt | rv32i_slti},
				{rv32i_srl | rv32i_srli},
				{rv32i_sra | rv32i_srai},
				rv32i_lui,
				rv32i_auipc
};*/

//add/addi
wire op_add = de_inst_info[11] & ~imm_en ;
wire op_addi= de_inst_info[11] & imm_en ;

wire signed[`ZCRV_XLEN-1:0] add_result = op_add ? ($signed(rs1_alu) +  $signed(rs2_alu)) :
										op_addi ? ($signed(rs1_alu) +  $signed(imm_alu)) : 32'b0 ;
										
//sub
wire op_sub = de_inst_info[10] ;
wire signed[`ZCRV_XLEN-1:0] sub_result = op_sub ? ($signed(rs1_alu) -  $signed(rs2_alu)) : 32'b0 ;

//sll slli

wire op_sll = de_inst_info[9] & ~imm_en ;
wire op_slli= de_inst_info[9] & imm_en ;

wire[4:0] shamt = need_alu&imm_en ? imm_alu[4:0] : need_alu ? rs2_alu[4:0] : 5'b00000;

wire[`ZCRV_XLEN-1:0] sll_result = (op_sll | op_slli)? rs1_alu << shamt : 32'b0 ;

//sltu sltiu

wire op_sltu = de_inst_info[8] & ~imm_en ;
wire op_sltiu= de_inst_info[8] & imm_en ;

wire rs1_lt_rs2_su  = (rs1_alu < rs2_alu);
wire rs1_lt_rs2_siu = (rs1_alu < imm_alu);

wire[`ZCRV_XLEN-1:0] sltu_result = op_sltu ? {31'b0,rs1_lt_rs2_su} : op_sltiu ? {31'b0,rs1_lt_rs2_siu} : 32'b0 ;

//xor xori
wire op_xor = de_inst_info[7] & ~imm_en ;
wire op_xori= de_inst_info[7] & imm_en ;

wire[`ZCRV_XLEN-1:0] xor_result = op_xor ? (rs1_alu ^ rs2_alu) : op_xori ? (rs1_alu ^ imm_alu) : 32'b0 ;

//or ori
wire op_or = de_inst_info[6] & ~imm_en ;
wire op_ori= de_inst_info[6] & imm_en ;

wire[`ZCRV_XLEN-1:0] or_result = op_or ? (rs1_alu | rs2_alu) : op_ori ? (rs1_alu | imm_alu) : 32'b0 ;

//and andi
wire op_and = de_inst_info[5] & ~imm_en ;
wire op_andi= de_inst_info[5] & imm_en ;

wire[`ZCRV_XLEN-1:0] and_result = op_and ? (rs1_alu & rs2_alu) : op_andi ? (rs1_alu & imm_alu) : 32'b0 ;

//slt slti
wire op_slt = de_inst_info[4] & ~imm_en ;
wire op_slti= de_inst_info[4] & imm_en ;

wire rs1_lt_rs2_s  = ($signed(rs1_alu) < $signed(rs2_alu));
wire rs1_lt_rs2_si = ($signed(rs1_alu) < $signed(imm_alu));

wire[`ZCRV_XLEN-1:0] slt_result = op_slt ? {31'b0,rs1_lt_rs2_s} : op_slti ? {31'b0,rs1_lt_rs2_si} : 32'b0 ;

//srl srli

wire op_srl = de_inst_info[3] & ~imm_en ;
wire op_srli= de_inst_info[3] & imm_en ;


wire[`ZCRV_XLEN-1:0] srl_result = (op_srl | op_srli)? rs1_alu >> shamt : 32'b0 ;

//sra srai

wire op_sra = de_inst_info[2] & ~imm_en ;
wire op_srai= de_inst_info[2] & imm_en ;

wire[`ZCRV_XLEN-1:0]  sra_result_temp = ($signed(rs1_alu)) >>> shamt ;
wire[`ZCRV_XLEN-1:0] sra_result = (op_sra | op_srai)? sra_result_temp : 32'b0 ;

// lui

wire op_lui = de_inst_info[1] & imm_en ;

wire[`ZCRV_XLEN-1:0] lui_result = op_lui ? imm_alu : 32'b0 ;

//auipc
wire op_auipc = de_inst_info[0] & imm_en ;

wire[`ZCRV_XLEN-1:0] auipc_result = op_auipc ? imm_alu + input_pc : 32'b0 ;

//fininsh
assign alu_result = 32'b0
               |({32{ op_add  | op_addi  }} & add_result    )
			   |({32{  op_sub  }} & sub_result ) 
               |({32{ op_sll  | op_slli  }}  & sll_result   )
			   |({32{ op_sltu | op_sltiu }}  & sltu_result  )
			   |({32{ op_xor  | op_xori  }}  & xor_result   )
			   |({32{ op_or   | op_ori   }}  & or_result    )
			   |({32{ op_and  | op_andi   }}  & and_result   )
			   |({32{ op_slt  | op_slti  }}  & slt_result   )
			   |({32{ op_srl  | op_srli  }}  & srl_result   )
			   |({32{ op_sra  | op_srai  }}  & sra_result   )
			   |({32{       op_lui       }}  & lui_result   )
			   |({32{      op_auipc      }}  & auipc_result );


endmodule










 
