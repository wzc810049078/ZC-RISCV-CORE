`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  mul/div unit  
//  booth radix 4 miv
//  srt radix 4 div


module mdu(
input 						clk,
input						rst_n,


input						op_m_d, //from decode

input[11:0]				    de_inst_info, //from decode
input[`ZCRV_XLEN-1:0] 		rs1_mdu , //from reg
input[`ZCRV_XLEN-1:0] 		rs2_mdu , //from reg
//input[`ZCRV_REG_SIZE-1:0]	rs1_index,  //from decode
//input[`ZCRV_REG_SIZE-1:0]	rs2_index,  //from decode
input[`ZCRV_REG_SIZE-1:0]	rd_index,     //from decode

//output[`ZCRV_REG_SIZE-1:0]	mdu_now_rs1,  //to stall unit
//output[`ZCRV_REG_SIZE-1:0]	mdu_now_rs2,  //to stall unit
output[`ZCRV_REG_SIZE-1:0]	mdu_now_rd,     //to stall unit t0 check wb stage rdindex 
											//and wb stage
output						mdu_busy,     //to stall unit
output						mdu_finish,		//to wb stage
output[`ZCRV_XLEN-1:0] 		mdu_result 	//to wb stage


);




reg  mdu_now_busy_r ;
wire mul_finish ;
wire div_finish ;
wire mdu_can_start = ~mdu_now_busy_r & op_m_d ;
wire mdu_now_busy_next = mdu_finish ?  1'b0 : mdu_can_start ? 1'b1 : mdu_now_busy_r ;

wire need_mul = op_m_d & de_inst_info[11];
wire need_mulh = op_m_d & de_inst_info[10];
wire need_mulhu = op_m_d & de_inst_info[8];
wire need_mulhsu = op_m_d & de_inst_info[9];

wire need_div = op_m_d & de_inst_info[7];
wire need_divu = op_m_d & de_inst_info[6];
wire need_rem = op_m_d & de_inst_info[5];
wire need_remu = op_m_d & de_inst_info[4];

reg [`ZCRV_REG_SIZE-1:0]  mdu_rd_index_r;
reg [7:0] 				 mdu_info_r ; 
wire[7:0]  				 mdu_info =  mdu_can_start ? de_inst_info[11:4] : mdu_finish ? 7'b0 : mdu_info_r ; 
//wire[`ZCRV_REG_SIZE-1:0] mdu_rs1_index = mdu_can_start ? rs1_index : mdu_finish ? 5'b0 : mdu_rs1_index_r ;  
//wire[`ZCRV_REG_SIZE-1:0] mdu_rs2_index = mdu_can_start ? rs2_index : mdu_finish ? 5'b0 : mdu_rs2_index_r ; 
wire[`ZCRV_REG_SIZE-1:0] mdu_rd_index = mdu_can_start ? rd_index : mdu_finish ? 5'b0 : mdu_rd_index_r; 




//mul  singed rs1 * signed rs2    lower 32 bits to rd
//mulh singed rs1 * signed rs2    higher 32 bits to rd
//mulu 
wire mul_start = (need_mul | need_mulh | need_mulhu | need_mulhsu) & ~mdu_now_busy_r ;
// mul mulhu  mulhsu 需要的数
wire[`ZCRV_XLEN+1:0] rs1_mul_unsigned = mul_start ? {2'b0, rs1_mdu} : 0; 
wire[`ZCRV_XLEN+1:0] rs2_mul_unsigned = mul_start ?  {2'b0 , rs2_mdu} : 0;

// mul mulh mulhsu 需要的数
wire[`ZCRV_XLEN+1:0] rs1_mul_signed = mul_start ? {rs1_mdu[31],rs1_mdu[31] , rs1_mdu} : 0;
wire[`ZCRV_XLEN+1:0] rs2_mul_signed = mul_start ? {rs2_mdu[31], rs2_mdu[31], rs2_mdu} : 0;



wire[`ZCRV_XLEN+1:0] mul_multiplier = (need_mul|need_mulh|need_mulhsu) ? rs1_mul_signed : 
											need_mulhu ?  rs1_mul_unsigned : 0;

wire[`ZCRV_XLEN+1:0] mul_multiplicand = (need_mul|need_mulh) ? rs2_mul_signed : 
											(need_mulhsu|need_mulhu) ?  rs2_mul_unsigned : 0;

wire[2*`ZCRV_XLEN+3:0] mul_result ;

radix_4_booth_mul #(.DW(34)) mulunit(
.clk(clk),
.rst_n(rst_n),

.start(mul_start),
.multiplier(mul_multiplier),
.multiplicand(mul_multiplicand),

.result(mul_result),
.mulfinish(mul_finish)

);		

wire[`ZCRV_XLEN-1:0] mul_result_low = mul_finish ? mul_result[`ZCRV_XLEN-1:0] : 0 ;
wire[`ZCRV_XLEN-1:0] mul_result_high = mul_finish ? mul_result[2*`ZCRV_XLEN-1:`ZCRV_XLEN] : 0 ;
wire[`ZCRV_XLEN-1:0] mul_result_final = mdu_info_r[7] ? mul_result_low : mul_result_high ;		


//div divu rem remu
reg    div_overflow_r ;
wire div_overflow_next = (need_div | need_rem) & ~mdu_now_busy_r ? 
						( rs1_mdu == 32'b1000_0000_0000_0000_0000_0000_0000_0000) & 
							( rs2_mdu == 32'b1111_1111_1111_1111_1111_1111_1111_1111) : 
							    1'b0 ;
wire div_start = (need_div | need_divu | need_rem | need_remu ) & ~mdu_now_busy_r & ~div_overflow_next;

reg rs1_neg_r,rs2_neg_r;
wire rs1_neg = div_start ? (rs1_mdu[31]) : ~div_finish ? rs1_neg_r : 1'b0 ; //rs1为负数
wire rs2_neg = div_start ? (rs2_mdu[31]) : ~div_finish ? rs2_neg_r : 1'b0 ;  //rs2为负数
// divu remu需要的数
wire[`ZCRV_XLEN-1:0] rs1_div_temp = (need_div | need_rem) & rs1_neg ? ~rs1_mdu + 1'b1 : rs1_mdu; 
wire[`ZCRV_XLEN-1:0] rs2_div_remp = (need_div | need_rem) & rs2_neg ? ~rs2_mdu + 1'b1 : rs2_mdu;

wire[`ZCRV_XLEN+1:0] rs1_div_unsigned = div_start ? rs1_div_temp : 0; 
wire[`ZCRV_XLEN+1:0] rs2_div_unsigned = div_start ? rs2_div_remp : 0;


wire[31:0] 		quotient;
wire[31:0] 		reminder;
wire[31:0] 		dividend_r;
wire			div_error,divfinish;
assign			div_finish = div_error | divfinish | div_overflow_r;

srt_4_div#(.DW(32)) divunit(
.clk(clk),
.rst_n(rst_n),

.start(div_start),

.dividend(rs1_div_unsigned),
.divisor(rs2_div_unsigned),
	
.dividend_r(dividend_r),
.quotient(quotient),
.reminder(reminder),
.divfinish(divfinish),
.diverror(div_error)

);

wire need_fix = divfinish & (rs2_neg_r ^ rs1_neg_r) ;
wire[`ZCRV_XLEN-1:0] quotient_fix = mdu_info_r[3] & need_fix ? ~quotient + 1'b1 : quotient ;
wire[`ZCRV_XLEN-1:0] reminder_fix = mdu_info_r[1] & rs1_neg_r & divfinish ? ~reminder + 1'b1 : reminder ;

wire[`ZCRV_XLEN-1:0] div_result_quotient = div_error ? 32'b1111_1111_1111_1111_1111_1111_1111_1111 :
												div_overflow_r ? 32'b1000_0000_0000_0000_0000_0000_0000_0000 :
													divfinish ?  quotient_fix : 0;	
wire[`ZCRV_XLEN-1:0] div_result_reminder = div_error ? dividend_r :
												div_overflow_r ? 0 :
													divfinish ?  reminder_fix : 0;	
													
wire[`ZCRV_XLEN-1:0] div_result_final = (mdu_info_r[3] | mdu_info_r[2]) ? div_result_quotient : 
											(mdu_info_r[1] | mdu_info_r[0]) ? div_result_reminder : 0 ;


always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		mdu_now_busy_r <= 0;
//		mdu_rs1_index_r <= 0;
//		mdu_rs2_index_r <= 0;
		mdu_rd_index_r <= 0;
		mdu_info_r <= 0 ;
		rs1_neg_r <= 0;
		rs2_neg_r <= 0;
		div_overflow_r <= 0;
	end
	else
	begin
		mdu_now_busy_r <= mdu_now_busy_next;
//		mdu_rs1_index_r <= mdu_rs1_index;
//		mdu_rs2_index_r <= mdu_rs2_index;
		mdu_rd_index_r <= mdu_rd_index;
		mdu_info_r <= mdu_info;
		rs1_neg_r <= rs1_neg;
		rs2_neg_r <= rs2_neg;
		div_overflow_r <= div_overflow_next;
	end
end

assign  mdu_busy = mdu_now_busy_r;
//assign	mdu_now_rs1 = mdu_rs1_index_r; //to stall unit
//assign	mdu_now_rs2 = mdu_rs2_index_r; //to stall unit
assign	mdu_now_rd  = mdu_rd_index_r;   //to stall unit t0 check wb stage rdindex 
assign  mdu_finish = mul_finish | div_finish ;
assign  mdu_result = ~mdu_finish ? 0 : mdu_info_r[7]| mdu_info_r[6]|mdu_info_r[5]|mdu_info_r[4] ? mul_result_final : div_result_final ;

endmodule