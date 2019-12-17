`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  forward_unit 

module forward_unit(

input[31:0]					rddata_from_wb,
input[`ZCRV_REG_SIZE-1:0]	rd_from_wb,
input						rd_en_from_wb,

input[`ZCRV_REG_SIZE-1:0]	rs1_from_id,
input[`ZCRV_REG_SIZE-1:0]	rs2_from_id,
input					 	rs1_en_from_id,
input						rs2_en_from_id,	
	


output[31:0] 				rddata_to_rs2_to_id,
output[31:0] 				rddata_to_rs1_to_id,
output					   	rd_to_rs1_to_id,
output					   	rd_to_rs2_to_id

);
wire rs1_eq_rd = (rs1_en_from_id & rd_en_from_wb) ? (rs1_from_id == rd_from_wb) : 1'b0 ; 
wire rs2_eq_rd = (rs2_en_from_id & rd_en_from_wb) ? (rs2_from_id == rd_from_wb) : 1'b0 ; 

assign rddata_to_rs1_to_id =  rs1_eq_rd ? rddata_from_wb : 0;
assign rddata_to_rs2_to_id =  rs2_eq_rd ? rddata_from_wb : 0;
assign rd_to_rs1_to_id = rs1_eq_rd ;
assign rd_to_rs2_to_id = rs2_eq_rd ;

endmodule