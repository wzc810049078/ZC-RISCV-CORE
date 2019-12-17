`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  wb_unit

module wb_unit(

input						flush_from_flushunit,
input						stall_from_stallunit,
input						error_from_eiu,
input						rd_en_from_idex,
input[`ZCRV_REG_SIZE-1:0]	rd_from_idex,
input[`ZCRV_XLEN-1:0]       rd_result_from_idex,


input[`ZCRV_REG_SIZE-1:0]	mdu_now_rd_from_mdu ,    											//and wb stage
input						mdu_busy_from_mdu , 
input						mdu_finish_from_mdu ,		
input[`ZCRV_XLEN-1:0] 		mdu_result_from_mdu ,	

input[4:0] 					rd_index_from_lsu , 
input[`ZCRV_XLEN-1:0]		rd_data_from_lsu ,
input 						lsu_need_wb_from_lsu ,
input						store_success_from_lsu ,
input						load_success_from_lsuwb ,


output[`ZCRV_XLEN-1:0]		rd_data_to_reg ,
output   					rd_en_to_reg ,
output[`ZCRV_REG_SIZE-1:0]	rd_index_to_reg,
output						inst_finish_to_csr


);

wire short_pipe_wb = rd_en_from_idex | lsu_need_wb_from_lsu;
wire long_pipe_wb = mdu_finish_from_mdu ;

wire[`ZCRV_XLEN-1:0] short_pipe_rddata = rd_en_from_idex ? rd_result_from_idex :
											lsu_need_wb_from_lsu ? rd_data_from_lsu : 0;
wire[`ZCRV_REG_SIZE-1:0] short_pipe_rdindex = rd_en_from_idex ? rd_from_idex :
											lsu_need_wb_from_lsu ? rd_index_from_lsu : 5'b00000 ;

wire[`ZCRV_XLEN-1:0] long_pipe_rddata = mdu_finish_from_mdu ? mdu_result_from_mdu : 0;
wire[`ZCRV_REG_SIZE-1:0] long_pipe_rdindex = mdu_finish_from_mdu ? mdu_now_rd_from_mdu : 5'b00000 ;

wire[`ZCRV_XLEN-1:0] real_rddata =  long_pipe_wb ? long_pipe_rddata : 
										short_pipe_wb ? short_pipe_rddata :0;
wire[`ZCRV_REG_SIZE-1:0] real_rdindex =  long_pipe_wb ? long_pipe_rdindex :	
											short_pipe_wb ? short_pipe_rdindex : 5'b00000;
wire real_rden = 	~error_from_eiu & (short_pipe_wb | long_pipe_wb) ;


									
assign rd_data_to_reg = real_rden ? real_rddata : 0;
assign rd_en_to_reg = real_rden ;
assign rd_index_to_reg= real_rden ? real_rdindex : 5'b00000;
assign inst_finish_to_csr = (~error_from_eiu & ~flush_from_flushunit 
							& ~stall_from_stallunit ) |	mdu_finish_from_mdu 
							| store_success_from_lsu | load_success_from_lsuwb ;

endmodule