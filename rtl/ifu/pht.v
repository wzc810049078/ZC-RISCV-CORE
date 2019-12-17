`include "defines.v"

// Designer   : WANG ZI CHEN
// This module is 2 bit prediction history table

module pht(

input						clk,
input						rst_n,
input[9:0]					pht_index,  //分支预测表索引
input 						op_bxx,
input[9:0]					fix_index,
input						presuccess,
input						prefail,

output						pht_prehit

);

wire[1:0]  fix_rdata,pre_rdata;
reg[1:0]   fix_wdata;
wire	   fix_we = presuccess | prefail ;
wire       fix_re = presuccess | prefail ;
assign     pht_prehit = ((pre_rdata == 2'b11) | (pre_rdata == 2'b10)) & op_bxx;

always @(*)
begin	
	case({presuccess,prefail,fix_rdata})
		4'b1000: fix_wdata = fix_rdata + 2'b01;
		4'b1001: fix_wdata = fix_rdata + 2'b10;
		4'b1010: fix_wdata = fix_rdata + 2'b01;
		4'b1011: fix_wdata = fix_rdata ;
		4'b0100: fix_wdata = fix_rdata ;
		4'b0101: fix_wdata = fix_rdata - 2'b01;
		4'b0110: fix_wdata = fix_rdata - 2'b10;
		4'b0111: fix_wdata = fix_rdata - 2'b01;
		default: fix_wdata = fix_rdata;
	endcase
end




trinalport_ram  pht0
     (
      .clk(clk),
	  .rst_n(rst_n),
      .addra(pht_index),
      .rdataa(pre_rdata),
	  .rea(op_bxx),
      .addrb(fix_index),
      .rdatab(fix_rdata),
	  .reb(fix_re),
      .addrc(fix_index),
      .wdatac(fix_wdata),
      .wec(fix_we)
      );
   

  







endmodule


