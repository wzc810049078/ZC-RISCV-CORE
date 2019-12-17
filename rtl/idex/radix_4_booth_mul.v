
/*
radix_4_booth_mul
基4booth乘法器 修改bug版
Designer : Wang Zi Chen
*/


module radix_4_booth_mul#(
parameter DW = 34
)(
input clk,
input rst_n,

input				start,
input[DW-1:0] 		multiplier,
input[DW-1:0] 		multiplicand,

output[2*DW-1:0] 	result,
output				mulfinish

);
localparam			idle = 2'b00 , mul = 2'b01 , finish = 2'b10 ;
reg[1:0]			state , state_next ;
reg[4:0]	        counter , counter_next ;
reg[DW:0] 		    multiplier_reg,multiplier_temp;
reg[DW+1:0] 			multiplicand_reg,multiplicand_temp;
reg[DW+1:0] 			p_reg,p_temp;

//wire[DW:0] 		    multiplicand_s_ex = multiplicand_max ? {multiplicand[DW-1] , multiplicand} : {DW+1{1'b0}};
//wire[DW:0] 		    multiplicand_neg_ex = ~multiplicand_s_ex + 1'b1;

 //符号位扩展
wire[DW+1:0]  		multiplicand_1_neg_start 	= ~ {multiplicand[DW-1] ,multiplicand[DW-1] , multiplicand} + 1'b1 ;
wire[DW+1:0]  		multiplicand_2_neg_start 	= multiplicand_1_neg_start << 1 ;
wire[DW+1:0]  		multiplicand_1_neg 	= ~ multiplicand_reg + 1'b1 ;
wire[DW+1:0]  		multiplicand_2_neg 	= multiplicand_1_neg << 1 ;
wire[DW+1:0]  		multiplicand_2	 	= multiplicand_reg << 1 ;
wire				need_1_add		 =  (multiplier_temp[2:0] == 3'b001)|(multiplier_temp[2:0] == 3'b010);
wire				need_2_add		 =  (multiplier_temp[2:0] == 3'b011);
wire				need_1_sub		 =  (multiplier_temp[2:0] == 3'b101)|(multiplier_temp[2:0] == 3'b110);
wire				need_2_sub		 =  (multiplier_temp[2:0] == 3'b100);
wire				add_0			 =  (multiplier_temp[2:0] == 3'b111) | (multiplier_temp[2:0] == 3'b000);

wire[DW+1:0] 			p_temp_1 = need_1_add ? {p_reg[DW+1],p_reg[DW+1],p_reg[DW+1:2]} + multiplicand_reg :
									need_2_add ? {p_reg[DW+1],p_reg[DW+1],p_reg[DW+1:2]} + multiplicand_2 :
									 need_1_sub ? {p_reg[DW+1],p_reg[DW+1],p_reg[DW+1:2]} + multiplicand_1_neg :
									  need_2_sub ? {p_reg[DW+1],p_reg[DW+1],p_reg[DW+1:2]} + multiplicand_2_neg :
									   add_0 ? {p_reg[DW+1],p_reg[DW+1],p_reg[DW+1:2]}: {DW+2{1'b0}};

//wire[DW-1:0] 		p_temp_2 = {p_temp_1[DW-1],p_temp_1[DW-1:1]};


always @(posedge clk , negedge rst_n )
begin
	if (!rst_n)
	begin
		state <= idle;
		multiplier_reg <= {DW+1{1'b0}} ;
		multiplicand_reg <= {DW+2{1'b0}};
		counter <= {5{1'b0}} ;
		p_reg   <= {DW+2{1'b0}} ;

	end
	else
	begin
		state <= state_next;
		multiplier_reg <= multiplier_temp ;
		multiplicand_reg <= multiplicand_temp;
		counter <= counter_next;
		p_reg   <= p_temp ;
	end
end

always @(*)
begin
	case(state)
		idle : 
		begin
			if (start)
			begin
				state_next = mul;
				multiplier_temp = {multiplier , 1'b0 };  // 0000    10100
				multiplicand_temp =   {multiplicand[DW-1],multiplicand[DW-1] , multiplicand} ;
				p_temp = ~(multiplier[0] | multiplier[1])  ? {DW+2{1'b0}} : 
							(multiplier[0] == 1'b1 & multiplier[1] == 1'b0) ? {multiplicand[DW-1],multiplicand[DW-1] , multiplicand} :
								(multiplier[0] ==1'b0 & multiplier[1] == 1'b1) ? multiplicand_2_neg_start :
									(multiplier[0] & multiplier[1]) ? multiplicand_1_neg_start : {DW+2{1'b0}} ;
				counter_next = {5{1'b0}};
			end else
			begin
				state_next = idle;
				multiplier_temp ={DW+1{1'b0}} ;
				multiplicand_temp = {DW+1{1'b0}} ;
				counter_next = {5{1'b0}};
				p_temp = {DW+1{1'b0}};
				
			end
		end
		
		mul:
		begin
			if(counter != DW/2 - 1)
			begin
				
				multiplier_temp =  {p_reg[1], p_reg[0] , multiplier_reg[DW:2]};
				p_temp = p_temp_1 ;
				state_next = mul;
				counter_next = counter + 1'b1;
				multiplicand_temp = multiplicand_reg ;
			end
			else 
				begin
					p_temp = {p_reg[DW+1],p_reg[DW+1],p_reg[DW+1:2]};
					multiplier_temp = {p_reg[1] ,p_reg[0], multiplier_reg[DW:2]};
					state_next = finish ;
					multiplicand_temp = multiplicand_reg ;
					counter_next = {5{1'b0}}  ;
				end
		    
			end
		
		finish:
		begin
			state_next = idle;
			multiplicand_temp = {DW+2{1'b0}} ;
			multiplier_temp = {DW+1{1'b0}} ;
			counter_next = {5{1'b0}};
			p_temp = {DW+2{1'b0}} ;
		end
		default:
		begin
		state_next = idle;
		multiplier_temp =  {(DW+1){1'b0}};  // 01010 
		multiplicand_temp =  {DW+2{1'b0}} ;
		p_temp = {DW+2{1'b0}} ;   //1010
		counter_next = {5{1'b0}};
		end
	endcase
end

assign result = {p_reg[DW-1:0] , multiplier_reg[DW:1]};
assign mulfinish = (state == finish) ;

endmodule