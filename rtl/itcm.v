`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  itcm sim
// RV32IM zicsr zifence

`timescale 1 ps/ 1 ps
module itcm #(parameter DW = 32 ,
parameter AW = 32,
parameter MW = 4096,
parameter RDW = 13
)(
input					clk,
input					rst_n,

input[AW-1:0] 			pc_from_ifu,
input					ifureq_to_itcm,
output[DW-1:0]			inst_to_ifu,
output					itcm_ready_to_ifu,

input					store_from_lsu,
input					load_from_lsu,
input					req_from_lsu,
input[AW-1:0]			addr_from_lsu,
input[DW-1:0]			store_result_from_lsu,	
input[3:0]				store_mask_from_lsu,

output					res_to_lsu,
output[DW-1:0]	data_to_lsu

);


reg[DW/4-1:0] mem_r[0:MW*4-1];


reg[DW-1:0] inst_to_ifu_r;
reg itcm_ready_to_ifu_r;

	
always @(posedge clk or negedge rst_n) 
    begin
	if(!rst_n)
		begin
		inst_to_ifu_r <= 0;
		itcm_ready_to_ifu_r <= 1'b0;
		end 
	else if (ifureq_to_itcm) 
		begin
            inst_to_ifu_r <= {mem_r[pc_from_ifu[RDW:0]+3],mem_r[pc_from_ifu[RDW:0]+2],mem_r[pc_from_ifu[RDW:0]+1] ,mem_r[pc_from_ifu[RDW:0]] };
			itcm_ready_to_ifu_r <= 1'b1;
			end
		else begin
		
			inst_to_ifu_r <= 0;
			itcm_ready_to_ifu_r <= 1'b0;
        end
end
assign inst_to_ifu = inst_to_ifu_r;
assign itcm_ready_to_ifu = itcm_ready_to_ifu_r;

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
integer i,j;
reg [7:0] itcm_mem [0:MW*4-1];
initial
begin
$readmemh("D:/my module/zc riscv/1.verilog", itcm_mem);

//for(i=0;i<MW;i=i+1)
//begin
//	mem_r[i] <= 0 ;
//end

#1;
for (j=0;j<MW*4;j=j+1) 
begin
   mem_r[j][00+7:00] = itcm_mem[j+0];
   //mem_r[j][08+7:08] = itcm_mem[j*4+1];
  // mem_r[j][16+7:16] = itcm_mem[j*4+2];
  // mem_r[j][24+7:24] = itcm_mem[j*4+3];
end
/*
mem_r[0] = 32'b 0111_1111_1100_0000_0000_0000_1001_0011; // li  x1, dtcm 
mem_r[1] = 32'h 0000a023; //       sw      x0,0(x1) 0000 0000 0000 0000 1010 0000 0010 0011‬
mem_r[2] = 32'h 0000a103; // loop: lw      x2,0(x1)  
mem_r[3] = 32'h 00110113; //       addi    x2,x2,1
mem_r[4] = 32'h 0020a023; //       sw      x2,0(x1)
mem_r[5] = 32'h ff5ff06f; //       j   <loop> 1111 1111 0101 1111 1111 0000 0110 1111‬‬

mem_r[0] = 32'b1010010_11010_01110_000_00001_0110111 ; //lui x1
mem_r[1] = 32'b1111010_10101_01010_000_00011_0110111 ; //lui x3
mem_r[2] = 32'b1010010_11010_01110_000_00101_0110111 ; //lui x5
mem_r[3] = 32'b1010010_11010_01110_000_00111_0110111 ; //lui x7
mem_r[4] = 32'b1010010_11010_01110_000_01001_0110111 ; //lui x9
mem_r[5] = 32'b1010010_11010_01110_000_01011_0110111 ; //lui x11

mem_r[0] = 32'b1010010_11010_01110_000_00010_0010111 ; //auipc x2
mem_r[1] = 32'b1010010_11010_01110_000_00100_0010111 ; //auipc x4
mem_r[2] = 32'b1111010_10101_01010_000_00110_0010111 ; //auipc x6
mem_r[3] = 32'b1010010_11010_01110_000_01000_0010111 ; //auipc x8
mem_r[4] = 32'b1010010_11010_01110_000_01010_0010111 ; //auipc x10
mem_r[5] = 32'b1010010_11010_01110_000_01100_0010111 ; //auipc x12

mem_r[0] = 32'b 0111_1111_1100_0000_0000_0000_1001_0011; // li  x1, dtcm 
mem_r[1] = 32'h 0000a023; //       sw      x0,0(x1) 0000 0000 0000 0000 1010 0000 0010 0011‬
mem_r[2] = 32'h 0000a103; // loop: lw      x2,0(x1)  
mem_r[3] = 32'h 00110113; //       addi    x2,x2,1
mem_r[4] = 32'h 0020a023; //       sw      x2,0(x1)
mem_r[5] = 32'b 1000000_00000_00000_000_01100_0110111 ; //lui x12
mem_r[6] = 32'b 0000000_01000_01100_000_11111_1100111 ; //     

//bxx test
mem_r[0] = 32'b0000000_00001_00000_000_00010_0010011; // addi  x0 x2
mem_r[1] = 32'b0111111_00010_00000_000_11111_0010011; // addi  x2 x32
mem_r[2] = 32'b0000000_10000_00000_000_00110_0010011; // addi  x0 x6
mem_r[3] = 32'b1111111_11111_00110_000_00110_0010011 ; //addi x6 x6  -1
mem_r[4] = 32'b0000000_00010_00110_110_01000_1100011 ; //bltu x2 x6  imm(0000000001000)
mem_r[5] = 32'b1111111_00010_00110_111_11001_1100011 ; //bgeu x2 x6  imm(1111111111000)
mem_r[6] = 32'b1111111_11111_11000_000_00110_0110111 ; //lui x6 
mem_r[7] = 32'b1111111_11111_11000_000_00100_0110111 ; //lui x4 
mem_r[8] = 32'b0000000_00100_00110_100_10000_1100011 ; //blt x4 x6  imm(0000000010000)

//store load
mem_r[0] = 32'b0111111_00111_00000_000_10000_0010011; // addi  x0 x16
mem_r[1] = 32'b0111111_00000_00000_000_11111_0010011; // addi  x0 x32
mem_r[2] = 32'b0111111_11111_11111_000_10000_0010011; // addi  x32 x16
mem_r[3] = 32'b0000000_10000_11111_000_10100_0100011 ; //Sb x16,20+(x32)
mem_r[4] = 32'b0000000_10100_11111_000_10001_0000011 ; //lb 16+(x32) , x17
mem_r[5] = 32'b0000000_10100_11111_001_10010_0000011 ; //lh 16+(x32) , x18
mem_r[6] = 32'b0000000_10100_11111_010_10011_0000011 ; //lw 16+(x32) , x19
mem_r[7] = 32'b0000000_10100_11111_100_10100_0000011 ; //lbu 16+(x32) , x20
mem_r[8] = 32'b0000000_10100_11111_101_10101_0000011 ; //lhu 16+(x32) , x21


mem_r[0] = 32'b0111111_00111_00000_000_10000_0010011;  // addi  x0 imm x16
mem_r[1] = 32'b0111111_00000_00000_000_00001_0010011;  // addi  x0 imm x1
mem_r[2] = 32'b1111111_11111_00001_010_10010_0010011;  // SLTI  x1 imm x18
mem_r[3] = 32'b1000000_00000_00001_011_10011_0010011 ; // SLTIU  x1 imm x19
mem_r[4] = 32'b0111110_10100_10000_100_10100_0010011 ; // XORI  x16 imm x20
mem_r[5] = 32'b0111010_10100_10000_110_10101_0010011 ; // ORI  x16 imm x21
mem_r[6] = 32'b1000100_10100_10000_111_10110_0010011 ; // ANDI  x16 imm x22
mem_r[7] = 32'b0000000_00111_00001_000_10111_0010011 ; // SLLI  x1 imm x23
mem_r[8] = 32'b0000000_00101_00001_101_11000_0010011 ; // SRLI  x1 imm x24
mem_r[9] = 32'b0100000_01010_00001_101_11000_0010011 ; // SRAI  x1 imm x25


mem_r[0] = 32'b1110010_11010_01110_000_00001_0110111 ; //lui x1 
mem_r[1] = 32'b0111110_11110_00010_000_00010_0110111 ; //lui x2 
mem_r[2] = 32'b0000000_00010_00001_000_10000_0110011;  // add  
mem_r[3] = 32'b0100000_00010_00001_000_10001_0110011;  // sub 
mem_r[4] = 32'b0000000_00010_00001_010_10010_0110011;  // SLT  
mem_r[5] = 32'b0000000_00010_00001_011_10011_0110011 ; // SLTU  
mem_r[6] = 32'b0000000_00010_00001_100_10100_0110011 ; // XOR  
mem_r[7] = 32'b0000000_00010_00001_110_10101_0110011 ; // OR  
mem_r[8] = 32'b0000000_00010_00001_111_10110_0110011 ; // AND 
mem_r[9] = 32'b0000000_00111_00000_000_00010_0010011;  // addi 
mem_r[10] = 32'b0000000_00010_00001_001_10111_0110011 ; // SLL  
mem_r[11] = 32'b0000000_00010_00001_101_11000_0110011 ; // SRL  
mem_r[12] = 32'b0100000_00010_00001_101_11000_0110011 ; // SRA  

mem_r[0] = 32'b1110010_11010_01110_000_00001_0110111 ; //lui x1 
mem_r[1] = 32'b0111110_11110_00010_000_00010_0110111 ; //lui x2 
mem_r[2] = 32'b0000000_00010_00001_000_10000_0110011;  // add  
mem_r[3] = 32'b0100000_00010_00001_000_10001_0110011;  // sub 
mem_r[4] = 32'b0000000_00010_00001_010_10010_0110011;  // SLT  
mem_r[5] = 32'b0000000_00010_00001_011_10011_0110011 ; // SLTU  
mem_r[6] = 32'b0000000_00010_00001_100_10100_0110011 ; // XOR  
mem_r[7] = 32'b0000000_00010_00001_110_10101_0110011 ; // OR  
mem_r[8] = 32'b0000000_00000_00000_000_00010_0001111;  // fence 
mem_r[9] = 32'b0000000_00111_00000_000_00010_0010011;  // addi 
mem_r[10] = 32'b0000000_00010_00001_001_10111_0110011 ; // SLL  
mem_r[11] = 32'b0000000_00010_00001_101_11000_0110011 ; // SRL  
mem_r[12] = 32'b0100000_00010_00001_101_11000_0110011 ; // SRA  

mem_r[0] = 32'b1000000_00000_00000_000_00001_0110111 ; //lui x1 
mem_r[1] = 32'b0111110_11110_00010_000_00010_0110111 ; //lui x2 
mem_r[2] = 32'b0000000_11101_00001_000_00001_0010011;  // addi  
mem_r[3] = 32'b0100000_00010_00001_000_10001_0110011;  // sub 
mem_r[4] = 32'b0000000_00010_00001_010_10010_0110011;  // SLT  
mem_r[5] = 32'b0011000_00101_00001_001_11111_1110011 ; // CSRRW
mem_r[6] = 32'b0011000_00000_01000_101_11111_1110011 ; // CSRRWI  
mem_r[7] = 32'b0011000_00000_01000_111_11110_1110011 ; // CSRRCI  
mem_r[8] = 32'b0000000_00000_00000_000_00000_1110011;  // ECALL
mem_r[9] = 32'b0000000_00111_00000_000_00010_0010011;  // addi 
mem_r[10] = 32'b0000000_00010_00001_001_10111_0110011 ; // SLL  
mem_r[11] = 32'b0011000_00000_00000_110_11100_1110011 ; // CSRRSI   
mem_r[12] = 32'b0100000_00010_00001_101_11000_0110011 ; // SRA

mem_r[23] = 32'b0011000_00000_00000_110_11101_1110011 ; // CSRRSI  
mem_r[24] = 32'b0011000_00010_00000_000_00000_1110011;  //mret
mem_r[30] = 32'b0000000_00000_00000_000_00000_1110011;  // ECALL



mem_r[0] = 32'b1000000_00000_00000_000_00001_0110111 ; //lui x1 
mem_r[1] = 32'b1111110_11110_00010_000_00010_0110111 ; //lui x2 
mem_r[2] = 32'b0000000_11101_00000_000_00001_0010011 ;  // addi 
mem_r[3] = 32'b0000001_00001_00010_000_10000_0110011 ;  // mul 
mem_r[4] = 32'b0000001_00001_00010_011_10001_0110011 ;  // mulhu
mem_r[5] = 32'b0000001_00001_00010_000_10010_0110011 ;  // mul 
mem_r[6] = 32'b0000001_00001_00010_010_10011_0110011 ;  // mulhsu
mem_r[7] = 32'b0000011_11101_00001_000_00010_0010011 ; // addi
*/




end                                            
          


assign res_to_lsu =res_to_lsu_load | res_to_lsu_store;



endmodule


