`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  lsu_wb

module lsu_wb(

input 					ls_from_idex,
input 				    ls_addr_error_from_idex,
input[4:0] 				load_info_from_idex,
input[4:0] 				rd_index_from_idex ,
input 					rden_from_idex 	,

input					res_from_dtcm,
input[`ZCRV_XLEN-1:0]	data_from_dtcm,

input					res_from_itcm,
input[`ZCRV_XLEN-1:0]	data_from_itcm,

output[4:0] 			rd_index_to_wb , 
output[`ZCRV_XLEN-1:0]	rd_data_to_wb ,
output 					lsu_need_wb_to_wb ,
output					store_success_to_wb ,
output					load_success_to_wb ,

output 					load_misalgn_to_eiu ,  
output 					load_buserr_to_eiu , 
output 					store_misalgn_to_eiu , 
output 					store_buserr_to_eiu 

);
wire store = ls_from_idex & ~rden_from_idex;
wire load  = ls_from_idex & rden_from_idex;


wire[`ZCRV_XLEN-1:0] pre_real_data = load & res_from_dtcm ? data_from_dtcm : 
										load & res_from_itcm ? data_from_itcm : 0;

wire	op_lb , op_lh , op_lw , op_lbu, op_lhu;

assign {op_lb , op_lh , op_lw , op_lbu, op_lhu} = load ? load_info_from_idex : 5'b0;




wire[`ZCRV_XLEN-1:0] real_data_for_lb = {{24{pre_real_data[7]}} ,pre_real_data[7:0]} ;
wire[`ZCRV_XLEN-1:0] real_data_for_lbu ={24'b0 ,pre_real_data[7:0]} ;

wire[`ZCRV_XLEN-1:0] real_data_for_lh = {{16{pre_real_data[15]}} ,pre_real_data[15:0]};
wire[`ZCRV_XLEN-1:0] real_data_for_lhu = {16'b0 ,pre_real_data[15:0]} ;

wire[`ZCRV_XLEN-1:0] real_data_for_lw = pre_real_data ;

wire[`ZCRV_XLEN-1:0] real_data = 32'b0
								|({32{op_lb}} & real_data_for_lb)
								|({32{op_lbu}} & real_data_for_lbu)
								|({32{op_lh}} & real_data_for_lh)
								|({32{op_lhu}} & real_data_for_lhu)
								|({32{op_lw}} & real_data_for_lw) ;
	
assign  store_misalgn_to_eiu = store & ls_addr_error_from_idex;
assign  load_misalgn_to_eiu = load & ls_addr_error_from_idex;
assign  load_buserr_to_eiu = 1'b0;
assign  store_buserr_to_eiu = 1'b0;

wire  lsu_error = store_misalgn_to_eiu | load_misalgn_to_eiu 
					|load_buserr_to_eiu |store_buserr_to_eiu;
								
assign lsu_need_wb_to_wb = ~lsu_error & rden_from_idex & load ; 								
assign rd_data_to_wb = lsu_need_wb_to_wb  ?  real_data  : 0;
assign rd_index_to_wb = lsu_need_wb_to_wb ? rd_index_from_idex : 5'b0 ;
assign store_success_to_wb = ~lsu_error & store & (res_from_dtcm | res_from_itcm);
assign load_success_to_wb = lsu_need_wb_to_wb & (res_from_dtcm | res_from_itcm);
								
													


endmodule