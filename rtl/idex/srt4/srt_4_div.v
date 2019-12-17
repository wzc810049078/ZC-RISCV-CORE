
/*
srt_4_div
选商的radix4算法除法
Designer : Wang Zi Chen
*/

module srt_4_div#(
parameter DW = 32)(
input 				clk,
input 				rst_n,

input				start,

input[DW-1:0]		dividend,
input[DW-1:0] 		divisor,
	
output[DW-1:0]		dividend_r,
output[DW-1:0] 		quotient,
output[DW-1:0] 		reminder,
output				divfinish,
output				diverror

);

wire[DW/2-1:0] 		iterations;
wire[DW+2:0] 	divisor_star;
wire[DW+5:0] 	dividend_star;
wire[DW/2-1:0] 		recovery;

pre_processing u1(

.start(start),

.dividend(dividend),
.divisor(divisor),
	

.iterations(iterations),
.divisor_star(divisor_star),
.dividend_star(dividend_star),
.recovery(recovery)

);

wire[DW+3:0]			w_0_4 = dividend_star[DW+3:0]; 

localparam				idle = 2'b00 , div = 2'b01 , finish = 2'b10 , error = 2'b11 ;
reg[1:0]				state , state_next ;
reg[DW/4:0]	   			counter , counter_next ;
reg[DW+3:0] 		    w_reg,w_temp;
reg[DW+3:0] 		    divisor_reg,divisor_temp;
reg[DW/2-1:0] 			iterations_temp,iterations_reg,recovery_temp,recovery_reg;	

wire[1:0]				state_in = state ;

wire[DW+3:0] divisor_real = divisor_reg ;
wire[DW+3:0] divisor_2_real = divisor_real << 1;
wire[DW+3:0] divisor_neg  = ~divisor_real + 1'b1;
wire[DW+3:0] divisor_2_neg = divisor_neg << 1;

wire dividend_eq_0_t = (dividend == 0);
wire divisor_eq_0_t = (divisor == 0);

wire signed[6:0] dividend_index = w_reg[DW+3:DW-3];
wire[3:0] divisor_index  = divisor_reg[DW:DW-3];
wire[1:0] q_table ;


radix4_table u2(
.dividend_index(dividend_index),
.divisor_index(divisor_index),

.q_table(q_table)

);




wire[DW+3:0] w_next_temp = ({dividend_index[6] , q_table} == 3'b001) ? divisor_neg + w_reg :
								({dividend_index[6] , q_table} == 3'b010) ? w_reg + divisor_2_neg :
									({dividend_index[6] , q_table} == 3'b101) ? w_reg + divisor_real :
										({dividend_index[6] , q_table} == 3'b110) ? w_reg + divisor_2_real :
											(q_table ==2'b00) ?  w_reg : 12'b0 ;

wire[DW+3:0] w_next = w_next_temp << 2 ;

//商生成
wire[2:0]	 q_in   = {dividend_index[6] , q_table} ; 
wire[DW-1:0] q_out_1;

on_the_fly_conversion u3(
.clk(clk),
.rst_n(rst_n),

.q_in(q_in),
.state_in(state_in) ,

.q_out(q_out_1)


);

always @(posedge clk , negedge rst_n )
begin
	if (!rst_n)
	begin
		state <= idle;
		divisor_reg <= 0 ;
		counter <= 0 ;
		w_reg   <= 0 ;
		iterations_reg <= 0;
		recovery_reg <= 0;
	
	end
	else
	begin
		state   <= state_next;
		divisor_reg <= divisor_temp ;
		counter <= counter_next;
		w_reg   <= w_temp ;
		iterations_reg <= iterations_temp;
		recovery_reg <= recovery_temp;


	end
end


always @(*)
begin
	case(state)
		idle : 
		begin
			if (start & ~dividend_eq_0_t & ~divisor_eq_0_t)
			begin
				state_next = div;
				divisor_temp = {divisor_star , 1'b0} ;
				w_temp = w_0_4 ;  //there
				counter_next = 0;
				iterations_temp = iterations;
				recovery_temp = recovery;

			end else 
			if (start & dividend_eq_0_t)
			begin
				state_next = finish;
				divisor_temp = 0  ;
				w_temp = 0  ;
				counter_next = 0;
				iterations_temp = 0;
				recovery_temp = 0;
			end else
			if (start & divisor_eq_0_t)
			begin
				state_next = error;
				divisor_temp = 0  ;
				w_temp = dividend ;
				counter_next = 0;
				iterations_temp = 0;
				recovery_temp = 0;
			end else
			begin
				state_next = idle;
				divisor_temp = 0  ;
				w_temp = 0;
				counter_next = 0;
				iterations_temp = 0;
				recovery_temp = 0;
				
				
			end
		end
		
		div:
		begin
			if(counter != iterations_reg - 1 )
			begin
				state_next = div;
				w_temp = w_next ;
				divisor_temp = divisor_reg ;
				counter_next = counter + 1'b1;
				iterations_temp = iterations_reg;
				recovery_temp = recovery_reg;
				
			end
			else 
				begin
					state_next = finish;
					w_temp = w_next_temp;
					divisor_temp = divisor_reg ;
					counter_next =  0;
					iterations_temp = iterations_reg;
					recovery_temp = recovery_reg;
				end
		    
			end
		
		finish:
		begin
			state_next = idle;
			divisor_temp = 0 ;
			counter_next = 0 ;
			w_temp   = 0 ;
			iterations_temp = 0;
			recovery_temp = 0;
		end
		error:
		begin
			state_next = idle;
			divisor_temp = 0;
			counter_next = 0 ;
			w_temp   = 0;
			iterations_temp = 0;
			recovery_temp = 0;
		end
	endcase
end

wire   w_reg_unsign = (w_reg[DW+3] == 1) ;
wire[DW+3:0]   w_reg_fix = w_reg_unsign ? w_reg + divisor_real : w_reg ;
wire[DW-1:0]   q_out_fix = w_reg_unsign ? q_out_1 - 1 : q_out_1 ;

wire[DW+32:0]   reminder_temp = ({28'b0 , w_reg_fix} << recovery_reg);
assign dividend_r = diverror ? w_reg[31:0] : 0 ;
assign reminder = reminder_temp[DW+32:DW+1];
assign quotient	= q_out_fix;
assign diverror  = (state == error) ;
assign divfinish = (state == finish) ;

endmodule