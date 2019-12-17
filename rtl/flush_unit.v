`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  flush unit 

module flush_unit(
input 						flush_from_predict_fix,
input[`ZCRV_ADDR_SIZE-1:0] 	pcfix_from_predict_fix,
input						flush_from_eiu,
input[`ZCRV_ADDR_SIZE-1:0]  flush_addr_from_eiu,

output[`ZCRV_ADDR_SIZE-1:0] flush_pc_to_pipeline,
output					   	flush_to_pipeline

);

assign flush_to_pipeline = flush_from_predict_fix|flush_from_eiu;
assign flush_pc_to_pipeline =  flush_from_eiu ? flush_addr_from_eiu :
										flush_from_predict_fix ? pcfix_from_predict_fix :0;
endmodule
