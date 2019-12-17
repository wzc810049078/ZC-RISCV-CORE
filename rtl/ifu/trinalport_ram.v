module trinalport_ram#(
parameter ADDRLEN = 10,
parameter DATALEN = 2,
parameter DEPTH = 1024
				 )
   (
    input		     		rst_n,
	//port a
    input  		     		clk,
    input[ADDRLEN-1:0] 		addra,
    output reg[DATALEN-1:0] rdataa,
	input					rea,
	//port b
    input[ADDRLEN-1:0] 		addrb,
    output reg[DATALEN-1:0] rdatab,
	input					reb,
	//port c
    input[ADDRLEN-1:0] 		addrc,
    input[DATALEN-1:0] 		wdatac,
	input 		     		wec
    );

   reg[DATALEN-1:0] mem [0:DEPTH-1];
   integer i;
   reg[ADDRLEN-1:0] addra_r,addrb_r;
   
always @ (*) 
	begin
		if(rea)
		rdataa <= mem[addra];
		else
		rdataa <= 2'b00;
		
		if(reb)
		rdatab <= mem[addrb];
		else
		rdatab <= 2'b00;
	end
 
always @ (negedge clk or negedge rst_n) 
	begin
		if (!rst_n)
			begin
				for(i=0;i<1024;i=i+1)
				mem[i] <= {DATALEN{1'b0}};
			end 
		else if (wec)
			mem[addrc] <= wdatac ;
			
	end
endmodule