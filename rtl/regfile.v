`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  regfile

module regfile(

input  clk,
input  rst_n,


input[`ZCRV_REG_SIZE-1:0] 	rs1_index,
input[`ZCRV_REG_SIZE-1:0] 	rs2_index,
input						rs1_en,
input						rs2_en,

input						rd_wr_en,
input[`ZCRV_REG_SIZE-1:0]   rd_index, //from commit stage
input[`ZCRV_XLEN-1:0] 		rd_data,

output[`ZCRV_XLEN-1:0] 		rs1_data,
output[`ZCRV_XLEN-1:0] 		rs2_data

  );

reg[31:0] regfile_r [31:0];

integer i;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		begin
			for (i=0 ; i<32 ; i=i+1)
				begin	
					regfile_r[i] <= 32'b0;
				end
        end
	else if(rd_wr_en & (rd_index != 5'B00000))
		regfile_r[rd_index] <= rd_data ;
end
		

  
  
  
  
assign rs1_data = rs1_en ? regfile_r[rs1_index] : 0;
assign rs2_data = rs2_en ? regfile_r[rs2_index] : 0;
  



endmodule

