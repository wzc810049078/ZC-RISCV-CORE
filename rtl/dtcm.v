`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  dtcm sim
// RV32IM zicsr zifence


module dtcm #(parameter DW = 32 ,
parameter AW = 32,
parameter MW = 1024,
parameter RDW = 11
)(
input					clk,
input					rst_n,

input					store_from_lsu,
input					load_from_lsu,
input					req_from_lsu,
input[AW-1:0]			addr_from_lsu,
input[DW-1:0]			store_result_from_lsu,
input[3:0]				store_mask_from_lsu,	

output					res_to_lsu,
output[DW-1:0]			data_to_lsu

);


reg[DW/4-1:0] mem_r[0:MW*4-1];

reg[DW-1:0] data_to_lsu_r;
reg res_to_lsu_load ;
always @(posedge clk or negedge rst_n)
    begin
		if(!rst_n)
			begin
			data_to_lsu_r <= 0 ;
			res_to_lsu_load <= 1'b0;
			end 
		else if (load_from_lsu & req_from_lsu) 
		begin
            data_to_lsu_r <= {mem_r[addr_from_lsu[RDW:0]+3],mem_r[addr_from_lsu[RDW:0]+2],mem_r[addr_from_lsu[RDW:0]+1] ,mem_r[addr_from_lsu[RDW:0]] };
			res_to_lsu_load <= 1'b1;
			end
		else begin
			data_to_lsu_r <= 0 ;
			res_to_lsu_load <= 1'b0;
        end
end
assign data_to_lsu = data_to_lsu_r;

reg res_to_lsu_store ;

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		begin
		res_to_lsu_store <= 1'b0 ;
		end 
		else if (store_from_lsu & req_from_lsu ) 
	begin
    if(store_mask_from_lsu == 4'b0000)
       {mem_r[addr_from_lsu[RDW:0]+3],mem_r[addr_from_lsu[RDW:0]+2],mem_r[addr_from_lsu[RDW:0]+1] ,mem_r[addr_from_lsu[RDW:0]] }<= store_result_from_lsu;
	if(store_mask_from_lsu == 4'b1100)
       {mem_r[addr_from_lsu[RDW:0]+1] ,mem_r[addr_from_lsu[RDW:0]] }<= store_result_from_lsu[15:0];
	if(store_mask_from_lsu == 4'b1110)
       mem_r[addr_from_lsu[RDW:0]]<= store_result_from_lsu[8:0];
		res_to_lsu_store <= 1'b1 ;
	end
	else
	begin
		res_to_lsu_store <= 1'b0 ;
    end
end

integer i;

initial
begin
for(i=0;i<MW*4;i=i+1)
begin
	mem_r[i] <= 0 ;
end
end

assign res_to_lsu =res_to_lsu_load | res_to_lsu_store;
endmodule

