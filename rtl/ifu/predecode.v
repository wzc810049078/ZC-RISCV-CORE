`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  The predecode module to decode the instruction to know if it is jump instruction


module predecode(

input[`ZCRV_INSTR_SIZE-1:0]	input_inst,

output    					op_jal,
output						op_bxx,
output						op_jalr,
output[`ZCRV_IMM_SIZE-1:0]	jump_imm,
output						need_imm,
output[`ZCRV_REG_SIZE-1:0]  rs1,rs2,rd

);

wire [6:0]  opcode 		= input_inst[6:0];
wire [4:0]  rv32_rd     = input_inst[11:7];  
wire [2:0]  rv32_func3  = input_inst[14:12]; 
wire [4:0]  rv32_rs1    = input_inst[19:15]; 
wire [4:0]  rv32_rs2    = input_inst[24:20]; 
//wire [6:0]  rv32_func7  = input_inst[31:25]; 
wire [20:0] jal_imm_temp= {input_inst[31],input_inst[19:12],input_inst[20],input_inst[30:21],1'b0};
wire [11:0] jalr_imm_temp= input_inst[31:20];
wire [12:0] bxx_imm_temp= {input_inst[31],input_inst[7],input_inst[30:25],input_inst[11:8],1'b0};

//1101111 JAL

wire rv32i_jal = (opcode == 7'b1101111);
wire[`ZCRV_IMM_SIZE-1:0] jal_imm = {{11{jal_imm_temp[20]}},jal_imm_temp};

//1100111 JALR

wire rv32i_jalr = (opcode == 7'b1100111) & (rv32_func3 == 3'b000);
wire[`ZCRV_IMM_SIZE-1:0] jalr_imm = {{20{jalr_imm_temp[11]}},jalr_imm_temp};

wire rv32i_need_imm_j = rv32i_jal | rv32i_jalr;


//1100011 BEQ BNE BLT BGE BLTU BGEU
wire rv32i_opcode_1100011 = (opcode == 7'b1100011);

wire rv32i_beq = rv32i_opcode_1100011 & (rv32_func3 == 3'b000);
wire rv32i_bne = rv32i_opcode_1100011 & (rv32_func3 == 3'b001);
wire rv32i_blt = rv32i_opcode_1100011 & (rv32_func3 == 3'b100);
wire rv32i_bge = rv32i_opcode_1100011 & (rv32_func3 == 3'b101);
wire rv32i_bltu= rv32i_opcode_1100011 & (rv32_func3 == 3'b110);
wire rv32i_bgeu= rv32i_opcode_1100011 & (rv32_func3 == 3'b111);
wire rv32i_need_imm_b = rv32i_beq|rv32i_bne|rv32i_blt|rv32i_bge|rv32i_bltu|rv32i_bgeu;
wire rv32i_bxx = rv32i_need_imm_b;
wire[`ZCRV_IMM_SIZE-1:0] bxx_imm = {{19{bxx_imm_temp[12]}},bxx_imm_temp};


assign jump_imm = rv32i_jal ? jal_imm : rv32i_jalr ? jalr_imm : rv32i_bxx ? bxx_imm : 0 ;
assign need_imm = rv32i_need_imm_b | rv32i_need_imm_j;
assign op_jal = rv32i_jal;     //need rd
assign op_bxx = rv32i_bxx ;    //need rs1 rs2 rd
assign op_jalr = rv32i_jalr ;  //need rs1 rd
assign rs1 = (rv32i_jalr | rv32i_bxx) ? rv32_rs1 : 5'b0;
assign rs2= rv32i_bxx  ? rv32_rs2 : 5'b0;
assign rd = (rv32i_jalr | rv32i_jal) ?  rv32_rd : 5'b0 ;

endmodule