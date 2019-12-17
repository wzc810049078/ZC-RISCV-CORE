/*
pre_processing
整数srt4除法的预处理模块
Designer : Wang Zi Chen
*/

module pre_processing#(
parameter DW = 32,
parameter V  = 2,
parameter K  = 2)
(

input				start,

input[DW-1:0]		dividend,
input[DW-1:0] 		divisor,
	

output[DW/2-1:0] 	iterations,
output[DW+2:0] 		divisor_star,
output[DW+5:0] 		dividend_star,
output[DW/2-1:0] 	recovery

);

reg[DW-1:0]  divisor_temp;
reg[DW+2:0]  dividend_temp;
reg[DW/2-1:0]	 recovery_temp ;
reg[DW/2-1:0]     iterations_temp;



always @(*)
begin
if(start)
begin
	casex(divisor)
	    32'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = divisor;
				dividend_temp = {2'b0 , dividend , 1'b0 };

				iterations_temp = 1;
				recovery_temp   = 32;
			end
				
		32'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[30:0] , 1'b0 };
				dividend_temp = {3'b0 , dividend  };

				iterations_temp = 2;
				recovery_temp   = 31;
			end
		32'b001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[29:0] , 2'b00 };
				dividend_temp = {2'b0 , dividend , 1'b0 };
			
				iterations_temp = 2;
				recovery_temp   = 30;
			end
		32'b0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[28:0] , 3'b000 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 3;
				recovery_temp   = 29;
			end
		32'b0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[27:0] , 4'b0000 };
				dividend_temp = {2'b0 , dividend , 1'b0 };
				
				iterations_temp = 3;
				recovery_temp   = 28;
			end	
		32'b0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[26:0] , 5'b00000};
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 4;
				recovery_temp   = 27;
			end			
		32'b0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[25:0] , 6'b000000 };
				dividend_temp = {2'b0 , dividend , 1'b0 };
				
				iterations_temp = 4;
				recovery_temp   = 26;
			end	
		32'b0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[24:0] , 7'b0000000 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 5;
				recovery_temp   = 25;
			end	
		32'b0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[23:0] , 8'b00000000 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 5;
				recovery_temp   = 24;
			end	
		32'b0000_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[22:0] , 9'b000000000 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 6;
				recovery_temp   = 23;
			end	
		32'b0000_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[21:0] , 10'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 6;
				recovery_temp   = 22;
			end
		32'b0000_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[20:0] , 11'b0};
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 7;
				recovery_temp   = 21;
			end	
		32'b0000_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[19:0] , 12'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 7;
				recovery_temp   = 20;
			end		
		32'b0000_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[18:0] , 13'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 8;
				recovery_temp   = 19;
			end	
		32'b0000_0000_0000_001x_xxxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[17:0] , 14'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 8;
				recovery_temp   = 18;
			end		
		32'b0000_0000_0000_0001_xxxx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[16:0] , 15'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 9;
				recovery_temp   = 17;
			end	
		32'b0000_0000_0000_0000_1xxx_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[15:0] , 16'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 9;
				recovery_temp   = 16;
			end		
		32'b0000_0000_0000_0000_01xx_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[14:0] , 17'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 10;
				recovery_temp   = 15;
			end	
		32'b0000_0000_0000_0000_001x_xxxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[13:0] , 18'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 10;
				recovery_temp   = 14;
			end		
		32'b0000_0000_0000_0000_0001_xxxx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[12:0] , 19'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 11;
				recovery_temp   = 13;
			end	
		32'b0000_0000_0000_0000_0000_1xxx_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[11:0] , 20'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 11;
				recovery_temp   = 12;
			end		
		32'b0000_0000_0000_0000_0000_01xx_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[10:0] , 21'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 12;
				recovery_temp   = 11;
			end	
		32'b0000_0000_0000_0000_0000_001x_xxxx_xxxx  : 
			begin 
				divisor_temp = {divisor[9:0] , 22'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 12;
				recovery_temp   = 10;
			end		
		32'b0000_0000_0000_0000_0000_0001_xxxx_xxxx : 
			begin 
				divisor_temp = {divisor[8:0] , 23'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 13;
				recovery_temp   = 9;
			end	
		32'b0000_0000_0000_0000_0000_0000_1xxx_xxxx  : 
			begin 
				divisor_temp = {divisor[7:0] , 24'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 13;
				recovery_temp   = 8;
			end		
		32'b0000_0000_0000_0000_0000_0000_01xx_xxxx : 
			begin 
				divisor_temp = {divisor[6:0] , 25'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 14;
				recovery_temp   = 7;
			end	
		32'b0000_0000_0000_0000_0000_0000_001x_xxxx  : 
			begin 
				divisor_temp = {divisor[5:0] , 26'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 14;
				recovery_temp   = 6;
			end		
		32'b0000_0000_0000_0000_0000_0000_0001_xxxx : 
			begin 
				divisor_temp = {divisor[4:0] , 27'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 15;
				recovery_temp   = 5;
			end	
		32'b0000_0000_0000_0000_0000_0000_0000_1xxx  : 
			begin 
				divisor_temp = {divisor[3:0] , 28'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 15;
				recovery_temp   = 4;
			end		
		32'b0000_0000_0000_0000_0000_0000_0000_01xx : 
			begin 
				divisor_temp = {divisor[2:0] , 29'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 16;
				recovery_temp   = 3;
			end	
		32'b0000_0000_0000_0000_0000_0000_0000_001x  : 
			begin 
				divisor_temp = {divisor[1:0] , 30'b0 } ;
				dividend_temp = {2'b0 , dividend ,1'b0 };
				
				iterations_temp = 16;
				recovery_temp   = 2;
			end		
		32'b0000_0000_0000_0000_0000_0000_0000_0001 : 
			begin 
				divisor_temp = {divisor[0] , 31'b0 };
				dividend_temp = {3'b0 , dividend  };
				
				iterations_temp = 17;
				recovery_temp   = 1;
			end	
		32'b0000_0000_0000_0000_0000_0000_0000_0000  : 
			begin 
				divisor_temp = 0 ;
				dividend_temp = 0;
				
				iterations_temp = 0;
				recovery_temp   = 0;
			end		
		default:
			begin
				divisor_temp = 0 ;
				dividend_temp = 0;
				
				iterations_temp = 0;
				recovery_temp   = 0;
			end
	endcase
end
else begin
				divisor_temp = 0 ;
				dividend_temp = 0;
				
				iterations_temp = 0;
				recovery_temp   = 0;
end
end

assign dividend_star = {3'b0 , dividend_temp};
assign divisor_star = {3'b0 , divisor_temp};
assign iterations = iterations_temp;
assign recovery   = recovery_temp;

endmodule