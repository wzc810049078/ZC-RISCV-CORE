`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  stall unit 

module stall_unit(

//from mdu
input						busy_from_mdu,
input						finish_from_mdu,
input[`ZCRV_REG_SIZE-1:0]	rd_from_mdu,


//from other clk id/ex stage

input[`ZCRV_REG_SIZE-1:0]	rs1_from_id,
input[`ZCRV_REG_SIZE-1:0]	rs2_from_id,	
input[`ZCRV_REG_SIZE-1:0]	rd_from_id,	
input 						md_from_id,
input					 	rs1_en_from_id,
input						rs2_en_from_id,	
input					 	rd_en_from_id,

//to stall pipeline
output						pipe_stall


);


wire mdu_rd_eq_id_rs1 = rs1_en_from_id ? (rs1_from_id == rd_from_mdu) : 1'b0;
wire mdu_rd_eq_id_rs2 = rs2_en_from_id ?  (rs2_from_id == rd_from_mdu) : 1'b0; 
wire mdu_rd_eq_id_rd =  rd_en_from_id ? (rd_from_id == rd_from_mdu) : 1'b0;
wire mdu_busy_but_md  = (md_from_id == busy_from_mdu); 
wire mdu_finish_need_stall = finish_from_mdu ;

wire mdu_stall_t = mdu_finish_need_stall | ((mdu_rd_eq_id_rd | mdu_rd_eq_id_rs1 | mdu_rd_eq_id_rs2 | mdu_busy_but_md) & ~mdu_finish_need_stall) ;
wire mdu_stall = mdu_stall_t & busy_from_mdu ;

assign pipe_stall = mdu_stall;

endmodule