/*
on_the_fly_conversion
飞速商转换
Designer : Wang Zi Chen
*/

module on_the_fly_conversion(
input clk,
input rst_n,

input[2:0] q_in,
input[1:0] state_in ,

output[31:0] q_out

);

reg[31:0] qm_reg;
reg[31:0] q_reg;

wire q_in_010 = (q_in == 3'b010);
wire q_in_001 = (q_in == 3'b001);
wire q_in_000 = (q_in[1:0] == 2'b00);
wire q_in_101 = (q_in == 3'b101);
wire q_in_110 = (q_in == 3'b110);

wire active = (state_in ==2'b01);

wire[31:0] qm_next = (active & q_in_010 ) ? {q_reg[29:0] , 2'b01 } :
						(active & q_in_001) ? {q_reg[29:0] , 2'b00 } :
							(active & q_in_000) ? {qm_reg[29:0] , 2'b11 } :
								(active & q_in_101 )? {qm_reg[29:0] , 2'b10 } :
									(active & q_in_110) ? {qm_reg[29:0] , 2'b01 } : 32'b0;
wire[31:0] q_next  = (active & q_in_010) ? {q_reg[29:0] , 2'b10 } :
						(active & q_in_001) ? {q_reg[29:0] , 2'b01 } :
							(active & q_in_000) ? {q_reg[29:0] , 2'b00 } :
								(active & q_in_101) ? {qm_reg[29:0] , 2'b11 } :
									(active & q_in_110) ? {qm_reg[29:0] , 2'b10 } : 32'b0;


always @(posedge clk , negedge rst_n )
begin
	if (!rst_n)
	begin
		qm_reg <= 0;
		q_reg <= 0 ;
	
	end
	else
	begin 
		qm_reg <= qm_next;
		q_reg <= q_next ;

	end
end

assign q_out = q_reg ;
endmodule