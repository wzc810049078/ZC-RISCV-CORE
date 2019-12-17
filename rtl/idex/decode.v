`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  The decode module to decode the instruction details
// RV32IM zicsr zifence

module decode(


input[`ZCRV_ADDR_SIZE-1:0]	input_pc, //pc_present_to_idex
input[`ZCRV_INSTR_SIZE-1:0]	input_inst,
input						jalr_need_rs1_from_if,
input						predict_hit,

output[11:0]				de_inst_info, 
output                      inst_ilegl,

//to regfile 
output[`ZCRV_REG_SIZE-1:0]	rs1,  //
output[`ZCRV_REG_SIZE-1:0]	rs2,
output						rs1_en,
output						rs2_en,

//to ex/mdu
output						rd_en,
output[`ZCRV_REG_SIZE-1:0]	rd,

output						imm_en,
output[`ZCRV_IMM_SIZE-1:0]	imm,
output    					op_alu,
output    					op_system, // ecall ebreak wfi csr mret
output    					op_jump,
output    					op_fence,
output    					op_s_l,
output						op_m_d,
output 						bxx_pre_hit,
output[`ZCRV_CSRADDR_SIZE-1:0] op_csr_addr,
output						jalr_need_rs1_to_ex, // jalr需要除了x0之外的rs1
output[4:0]					csri_uimm,
output						op_bxx

);

wire [6:0]  opcode      = input_inst[6:0];
wire [4:0]  rv32_rd     = input_inst[11:7];  
wire [2:0]  rv32_func3  = input_inst[14:12]; 
wire [4:0]  rv32_rs1    = input_inst[19:15]; 
wire [4:0]  rv32_rs2    = input_inst[24:20]; 
wire [6:0]  rv32_func7  = input_inst[31:25]; 

//opcode=0110111 LUI

wire rv32i_lui = (opcode == 7'b0110111);

//0010111 AUIPC

wire rv32i_auipc = (opcode == 7'b0010111);


//1101111 JAL

wire rv32i_jal = (opcode == 7'b1101111);


//1100111 JALR

wire rv32i_jalr = (opcode == 7'b1100111);

//1100011 BEQ BNE BLT BGE BLTU BGEU
wire rv32_opcode_1100011 = (opcode == 7'b1100011);

wire rv32i_beq = rv32_opcode_1100011 & (rv32_func3 == 3'b000);
wire rv32i_bne = rv32_opcode_1100011 & (rv32_func3 == 3'b001);
wire rv32i_blt = rv32_opcode_1100011 & (rv32_func3 == 3'b100);
wire rv32i_bge = rv32_opcode_1100011 & (rv32_func3 == 3'b101);
wire rv32i_bltu= rv32_opcode_1100011 & (rv32_func3 == 3'b110);
wire rv32i_bgeu= rv32_opcode_1100011 & (rv32_func3 == 3'b111);
wire rv32i_bxx = rv32i_beq|rv32i_bne|rv32i_blt|rv32i_bge|rv32i_bltu|rv32i_bgeu ;
assign op_bxx = rv32i_bxx;
assign bxx_pre_hit = rv32i_bxx & predict_hit ; //bxx预测命中，这一流水线级要判断对了吗


//0000011 lb lh lw lbu lhu
wire rv32_opcode_0000011 = (opcode == 7'b0000011);
wire rv32i_lb = rv32_opcode_0000011 & (rv32_func3 == 3'b000);
wire rv32i_lh = rv32_opcode_0000011 & (rv32_func3 == 3'b001);
wire rv32i_lw = rv32_opcode_0000011 & (rv32_func3 == 3'b010);
wire rv32i_lbu = rv32_opcode_0000011 & (rv32_func3 == 3'b100);
wire rv32i_lhu = rv32_opcode_0000011 & (rv32_func3 == 3'b101);
wire rv32i_load = rv32i_lb|rv32i_lh|rv32i_lw|rv32i_lbu|rv32i_lhu;

//0100011 sb sh sw
wire rv32_opcode_0100011 = (opcode == 7'b0100011);
wire rv32i_sb = rv32_opcode_0100011 & (rv32_func3 ==3'b000);
wire rv32i_sh = rv32_opcode_0100011 & (rv32_func3 == 3'b001);
wire rv32i_sw = rv32_opcode_0100011 & (rv32_func3 ==3'b010);
wire rv32i_store = rv32i_sb | rv32i_sh | rv32i_sw;




//0010011 addi slti sltiu xori ori andi slli srli srai
wire rv32_opcode_0010011 = (opcode == 7'b0010011);
wire rv32i_addi = rv32_opcode_0010011 & (rv32_func3 == 3'b000);
wire rv32i_slti = rv32_opcode_0010011 & (rv32_func3 == 3'b010);
wire rv32i_sltiu = rv32_opcode_0010011 & (rv32_func3 == 3'b011);
wire rv32i_xori = rv32_opcode_0010011 & (rv32_func3 == 3'b100);
wire rv32i_ori = rv32_opcode_0010011 & (rv32_func3 == 3'b110);
wire rv32i_andi = rv32_opcode_0010011 & (rv32_func3 == 3'b111);
wire rv32i_slli = rv32_opcode_0010011 & (rv32_func3 == 3'b001) & (rv32_func7 == 7'b0000000);
wire rv32i_srli = rv32_opcode_0010011 & (rv32_func3 == 3'b101) & (rv32_func7 == 7'b0000000);
wire rv32i_srai = rv32_opcode_0010011 & (rv32_func3 == 3'b101) & (rv32_func7 == 7'b0100000);
wire rv32i_alui = rv32i_addi|rv32i_slti|rv32i_sltiu|rv32i_xori|rv32i_ori|rv32i_andi|rv32i_slli|rv32i_srli|rv32i_srai;

//0110011 add sub sll slt sltu xor srl sra or and
wire rv32_opcode_0110011 = (opcode == 7'b0110011)&(rv32_func7 != 7'b0000001 );

wire rv32i_add = rv32_opcode_0110011 & (rv32_func3 == 3'b000) & (rv32_func7 == 7'b0000000);
wire rv32i_sub = rv32_opcode_0110011 & (rv32_func3 == 3'b000) & (rv32_func7 == 7'b0100000);
wire rv32i_sll = rv32_opcode_0110011 & (rv32_func3 == 3'b001) & (rv32_func7 == 7'b0000000);
wire rv32i_sltu = rv32_opcode_0110011 & (rv32_func3 == 3'b011) & (rv32_func7 == 7'b0000000);
wire rv32i_xor = rv32_opcode_0110011 & (rv32_func3 == 3'b100) & (rv32_func7 == 7'b0000000);
wire rv32i_srl = rv32_opcode_0110011 & (rv32_func3 == 3'b101)& (rv32_func7 == 7'b0000000);
wire rv32i_sra = rv32_opcode_0110011 & (rv32_func3 == 3'b101)& (rv32_func7 == 7'b0100000);
wire rv32i_or = rv32_opcode_0110011 & (rv32_func3 == 3'b110) & (rv32_func7 == 7'b0000000);
wire rv32i_and = rv32_opcode_0110011 & (rv32_func3 == 3'b111) & (rv32_func7 == 7'b0000000);
wire rv32i_slt = rv32_opcode_0110011 & (rv32_func3 == 3'b010) & (rv32_func7 == 7'b0000000);
wire rv32i_alu = rv32i_add|rv32i_sub|rv32i_sll|rv32i_sltu|rv32i_xor|rv32i_srl|rv32i_sra|rv32i_or|rv32i_and|rv32i_slt;

//0001111 FENCE 
wire rv32_opcode_0001111 = (opcode == 7'b0001111);
wire rv32i_fence = rv32_opcode_0001111 & (rv32_func3 == 3'b000);
wire rv32_fencei = rv32_opcode_0001111 & (rv32_func3 == 3'b001);

//1110011 ecall ebreak csrrw csrrs csrrc csrrwi csrrsi csrrci 
wire rv32_opcode_1110011 = (opcode == 7'b1110011);

wire rv32_ecall = rv32_opcode_1110011 & (rv32_func3 == 3'b000) & (input_inst[31:20] == 12'b0000_0000_0000)&(rv32_rd == 5'b00000)&(rv32_rs1 == 5'b00000);
wire rv32_ebreak = rv32_opcode_1110011 & (rv32_func3 == 3'b000) & (input_inst[31:20] == 12'b0000_0000_0001)&(rv32_rd == 5'b00000)&(rv32_rs1 == 5'b00000);
wire rv32_csrrw = rv32_opcode_1110011 & (rv32_func3 == 3'b001);
wire rv32_csrrs = rv32_opcode_1110011 & (rv32_func3 == 3'b010);
wire rv32_csrrc = rv32_opcode_1110011 & (rv32_func3 == 3'b011);
wire rv32_csrrwi = rv32_opcode_1110011 & (rv32_func3 == 3'b101);
wire rv32_csrrsi = rv32_opcode_1110011 & (rv32_func3 == 3'b110);
wire rv32_csrrci = rv32_opcode_1110011 & (rv32_func3 == 3'b111);
wire rv32_mret = rv32_opcode_1110011 & (rv32_func3 == 3'b000) & (input_inst[31:20] == 12'b0011_0000_0010)&(rv32_rd == 5'b00000)&(rv32_rs1 == 5'b00000);
wire rv32_wfi = rv32_opcode_1110011 & (rv32_func3 == 3'b000) & (input_inst[31:20] == 12'b0001_0000_0101)&(rv32_rd == 5'b00000)&(rv32_rs1 == 5'b00000);
wire rv32_system = rv32_mret|rv32_wfi|rv32_ecall|rv32_ebreak|rv32_csrrw|rv32_csrrs|rv32_csrrc|rv32_csrrwi|rv32_csrrsi|rv32_csrrci;
wire rv32_csr = rv32_csrrw|rv32_csrrs|rv32_csrrc;
wire rv32_csri = rv32_csrrwi|rv32_csrrsi|rv32_csrrci;
//0110011 mul mulh mulhsu mulhu div divu rem remu
wire rv32_opcode_0110011_md = (opcode == 7'b0110011)&(rv32_func7 == 7'b0000001 );
wire rv32m_mul = rv32_opcode_0110011_md & (rv32_func3 == 3'b000);
wire rv32m_mulh = rv32_opcode_0110011_md & (rv32_func3 == 3'b001);
wire rv32m_mulhsu = rv32_opcode_0110011_md & (rv32_func3 == 3'b010);
wire rv32m_mulhu = rv32_opcode_0110011_md & (rv32_func3 == 3'b011);
wire rv32m_div = rv32_opcode_0110011_md & (rv32_func3 == 3'b100);
wire rv32m_divu = rv32_opcode_0110011_md & (rv32_func3 == 3'b101);
wire rv32m_rem = rv32_opcode_0110011_md & (rv32_func3 == 3'b110);
wire rv32m_remu = rv32_opcode_0110011_md & (rv32_func3 == 3'b111);
wire rv32m_mul_div =rv32m_mul|rv32m_mulh|rv32m_mulhsu|rv32m_mulhu|rv32m_div|rv32m_divu|rv32m_rem|rv32m_remu ;
//imm_need
wire rv32_need_imm_u = rv32i_lui|rv32i_auipc; //u_type imm
wire rv32_need_imm_i = rv32i_jalr|rv32i_load|rv32i_alui|rv32_fencei;

wire rv32_need_imm_s = rv32i_store;

wire rv32_need_imm_b = rv32i_bxx;
wire rv32_need_imm_j = rv32i_jal ;

//imm_gen
wire rv32_need_imm = rv32_need_imm_i | rv32_need_imm_b | rv32_need_imm_s | rv32_need_imm_j | rv32_need_imm_u | rv32_csri;

wire[31:0]  i_imm = {{20{input_inst[31]}} , input_inst[31:20]};

wire[31:0]  s_imm = {{20{input_inst[31]}} , input_inst[31:25] , input_inst[11:7]};

wire[31:0]  b_imm = {{19{input_inst[31]}} , input_inst[31] , input_inst[7] , input_inst[30:25] , input_inst[11:8] , 1'b0 };

wire[31:0]  u_imm = {input_inst[31:12],12'b0};

wire[31:0]  j_imm = {{11{input_inst[31]}} , input_inst[31] , input_inst[19:12] , input_inst[20] , input_inst[30:21] , 1'b0};
 
assign csri_uimm = rv32_csri ? rv32_rs1 : 5'b00000 ;
//rs1
wire rv32_need_rs1 = (rv32i_jalr & jalr_need_rs1_from_if == 1'b1) | rv32i_bxx | rv32i_load | rv32i_store | rv32i_alui | rv32i_alu | rv32_opcode_0001111 | rv32_csr | rv32m_mul_div ;
assign rs1_en = rv32_need_rs1;
assign rs1 = rv32_need_rs1 ? rv32_rs1 : 5'b0;  //csrrwi csrrrsi csrrci 的rs1是uimm。


//rs2
wire rv32_need_rs2 =  rv32i_alu | rv32i_bxx | rv32i_store  | rv32m_mul_div ;
assign rs2_en = rv32_need_rs2;
assign rs2 = rv32_need_rs2 ? rv32_rs2 : 5'b0;

//rd
wire rv32_need_rd = rv32i_lui | rv32i_auipc | rv32i_jal | rv32i_jalr | rv32i_load |  rv32i_alui | rv32i_alu | rv32_opcode_0001111 | rv32_csr | rv32_csri | rv32m_mul_div ;
assign rd_en = rv32_need_rd;
assign rd = rv32_need_rd ? rv32_rd : 5'b0;


assign imm_en = rv32_need_imm;
assign imm = rv32_need_imm_i ? i_imm : 
			 rv32_need_imm_b ? b_imm :
			 rv32_need_imm_s ? s_imm :
			 rv32_need_imm_j ? j_imm :
			 rv32_need_imm_u ? u_imm : 32'b0;
			 
assign op_alu = rv32i_alu | rv32i_alui | rv32i_lui | rv32i_auipc;
assign op_s_l = rv32i_store | rv32i_load;
assign op_jump = rv32i_bxx | rv32i_jal | rv32i_jalr;
assign op_system = rv32_system ;
assign op_fence = rv32_opcode_0001111;
assign op_m_d = rv32m_mul_div;



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
};

wire[11:0] sl_info = {
				rv32i_lb,
				rv32i_lh,
				rv32i_lw,
				rv32i_lbu,
				rv32i_lhu,
				rv32i_sb,
				rv32i_sh,
				rv32i_sw,
				4'b0
				
};

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
};

wire[11:0] system_info = {
				rv32_csrrw,
				rv32_csrrs,
				rv32_csrrc,
				rv32_csrrwi,
				rv32_csrrsi,
				rv32_csrrci,
				rv32_ebreak,
				rv32_ecall,
				rv32_mret,
				rv32_wfi,
				2'b0
				
};

wire[11:0] fence_info = {
				rv32i_fence,
				rv32_fencei,
				10'b0
};

wire[11:0] m_d_info = {
				rv32m_mul,
				rv32m_mulh,
				rv32m_mulhsu,
				rv32m_mulhu,
				rv32m_div,
				rv32m_divu,
				rv32m_rem,
				rv32m_remu,
				4'b0
				
};

assign op_csr_addr = (rv32_csr | rv32_csri) ? input_inst[31:20] : 12'b0; 
	 
assign de_inst_info = op_alu ? alu_info : 
					  op_s_l ? sl_info :
					  op_jump ? jump_info :
					  op_system ? system_info :
					  op_fence ? fence_info : 
					  op_m_d ? m_d_info : 12'b0;
					  
// all 0 all 1 error
wire inst_all_1 = (input_inst[`ZCRV_INSTR_SIZE-1:0] == 32'b1111_1111_1111_1111_1111_1111_1111_1111);

assign inst_ilegl = inst_all_1;

assign jalr_need_rs1_to_ex = jalr_need_rs1_from_if ;

endmodule