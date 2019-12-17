`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  lsu/agu

module lsu_agu(
input 						op_s_l,
input[7:0]				    de_inst_info, 


input[`ZCRV_XLEN-1:0] 		rs1_ls,  
input[`ZCRV_XLEN-1:0] 		rs2_ls,

input[`ZCRV_IMM_SIZE-1:0]	imm_ls,

output						load,
output						store,
output[`ZCRV_ADDR_SIZE-1:0]	lsaddr,
output						itcm_req,
output						dtcm_req,
output						addr_error,
output[`ZCRV_XLEN-1:0]		store_result,
output[3:0]					store_mask,
output[4:0]					load_info

);

wire op_lb  = op_s_l & de_inst_info[7];
wire op_lh  = op_s_l & de_inst_info[6];
wire op_lw  = op_s_l & de_inst_info[5];
wire op_lbu = op_s_l & de_inst_info[4];
wire op_lhu = op_s_l & de_inst_info[3];
wire op_sb  = op_s_l & de_inst_info[2];
wire op_sh  = op_s_l & de_inst_info[1];
wire op_sw  = op_s_l & de_inst_info[0];

wire op_store = op_sw | op_sh | op_sb;
wire op_load = op_lw | op_lh | op_lb | op_lbu | op_lhu;
wire[`ZCRV_ADDR_SIZE-1:0] ls_addr = op_s_l ? $signed(rs1_ls) + $signed(imm_ls): 0 ;

assign store_mask = op_sw ? 4'b0000 : op_sh ? 4'b1100 : op_sb ? 4'b1110 : 4'b1111;

//wire[`ZCRV_XLEN-1:0] sb_result	=  {{24{rs2_ls[7]}}, rs2_ls[7:0]} ;
//wire[`ZCRV_XLEN-1:0] sh_result	= {{16{rs2_ls[15]}}, rs2_ls[15:0]};
wire[`ZCRV_XLEN-1:0] sw_result	=  rs2_ls ;

assign store_result = op_store ? sw_result : 0 ;

wire	addr_misaligned = op_s_l & ((op_lh | op_lhu | op_sh) & ls_addr[0]) 
							| ((op_lw | op_sw) & (ls_addr[0]|ls_addr[1]));
												
assign	addr_error = addr_misaligned ;
					
wire	ls_itcm = ~addr_misaligned & (ls_addr[31] == 1'b1)  ;
wire	ls_dtcm = ~addr_misaligned & (ls_addr[31] == 1'b0) ;

assign load = ~addr_misaligned & op_load ;
assign store = ~addr_misaligned & op_store ;
assign lsaddr = ls_addr;
assign itcm_req = ls_itcm & op_s_l;
assign dtcm_req = ls_dtcm & op_s_l;
assign load_info = {op_lb , op_lh , op_lw , op_lbu, op_lhu};
endmodule


