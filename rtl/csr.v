`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  CSR regfile
// RV32IM zicsr zifence

module csr(
input							clk,
input							rst_n,

input 							ext_irq,  //外部中断
input 							time_irq, //计时器中断
input 							soft_irq, //软件中断
input							trap_en,
input							inst_finish,

input[`ZCRV_CSRADDR_SIZE-1:0] 	csr_index,
input							csr_en,
input							csr_wr_en,
input							csr_rd_en,
input[`ZCRV_XLEN-1:0]			csr_wr_data,
input							mret_commit,
input[`ZCRV_ADDR_SIZE-1:0]		mepc_from_eiu,
input[`ZCRV_XLEN-1:0]			mcause_from_eiu,
input[`ZCRV_XLEN-1:0]			mtval_from_eiu,



output[`ZCRV_XLEN-1:0]			csr_rd_data,
output[31:0]					mtvec_r,
output[31:0]					mstatus_r,
output[31:0]					mepc_r,		
output[31:0]					mie_r				

);
wire write_csr = csr_en & csr_wr_en ;
wire read_csr  = csr_en & csr_rd_en ;
wire[1:0] priv_mode = 2'b11 ; //m_mode


//0x300 mstatus MRW 机器模式状态寄存器
wire index_mstatus = (csr_index == 12'h300);
wire mstatus_wr = index_mstatus & write_csr;
wire mstatus_rd = index_mstatus & read_csr;

reg[`ZCRV_XLEN-1:0]	 mstatus_reg ;
wire[`ZCRV_XLEN-1:0] mstatus_next ;

assign mstatus_next[31:13] = 18'b0;
assign mstatus_next[12:11] = priv_mode ;
assign mstatus_next[10:9]  = 2'b00 ;
assign mstatus_next[8] = 1'b0 ;
assign mstatus_next[7] = trap_en ? mstatus_reg[3] : 
							mret_commit ? 1'b1 : 
								mstatus_wr ?  csr_wr_data[7] : mstatus_reg[7]; //mpie

assign mstatus_next[6:4] = 3'b000 ;
assign mstatus_next[3] = trap_en ? 1'b0 : 
							mret_commit ? mstatus_reg[7] : 
								mstatus_wr ?  csr_wr_data[3] : mstatus_reg[3]; //mie
assign mstatus_next[2:0] = 3'b000 ;

assign mstatus_r = mstatus_reg ;



always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mstatus_reg <= 32'b0000_0000_0000_0000_0001_1000_0000_0000 ;
	else if(trap_en | mret_commit | mstatus_wr )
		mstatus_reg <= mstatus_next;

end

//0x301 misa 设计为只读
wire index_misa = (csr_index == 12'h301);
wire misa_rd = index_misa & read_csr;

wire[`ZCRV_XLEN-1:0]	 misa_reg ;

assign misa_reg = { 2'b01 , 4'b0000 , 26'b00_0000_0000_0001_0001_0000_0000};

//0x302 medeleg 没有smode的不存在
//0x303 mideleg 没有smode的不存在

//0x304 mie MRW
wire index_mie = (csr_index == 12'h304);
wire mie_wr = index_mie & write_csr;
wire mie_rd = index_mie & read_csr;

reg[`ZCRV_XLEN-1:0]	 mie_reg ;
wire[`ZCRV_XLEN-1:0] mie_next ;

assign mie_next[11] = mie_wr ? csr_wr_data[11] : mie_reg[11]; //meie 外部中断屏蔽
assign mie_next[7]  = mie_wr ? csr_wr_data[7] :  mie_reg[7];  //mtie 计时器中断屏蔽
assign mie_next[3]  = mie_wr ? csr_wr_data[3] :  mie_reg[3];   //msie 软件中断屏蔽
assign mie_next[31:12]= 20'b0;
assign mie_next[10:8] = 3'b0;
assign mie_next[6:4]  = 3'b0;
assign mie_next[2:0]  = 3'b0;
assign mie_r = mie_reg ;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mie_reg <= 32'b0 ;
		else if(mie_wr )
		mie_reg <= mie_next;

end

//0x344 mip MWR 设计为只读

wire index_mip = (csr_index == 12'h344);
wire mip_rd = index_mip & read_csr;

reg[`ZCRV_XLEN-1:0]	 mip_reg ;
wire[`ZCRV_XLEN-1:0] mip_next ;

assign mip_next[11] = ext_irq; //meip 外部中断等待寄存器
assign mip_next[7]  = time_irq;  //mtip 计时器中断等待寄存器
assign mip_next[3]  = soft_irq;   //msip 软件中断等待寄存器
assign mip_next[31:12]= 20'b0;
assign mip_next[10:8] = 3'b0;
assign mip_next[6:4]  = 3'b0;
assign mip_next[2:0]  = 3'b0;

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mip_reg <= 32'b0 ;
	else 
		mip_reg <= mip_next;

end

//0x305 mtvec MRW 

wire index_mtvec = (csr_index == 12'h305);
wire mtvec_wr = index_mtvec & write_csr ;
wire mtvec_rd = index_mtvec & read_csr;

reg[`ZCRV_XLEN-1:0]	 mtvec_reg ;
wire[`ZCRV_XLEN-1:0] mtvec_next ;

assign mtvec_next = mtvec_wr ? csr_wr_data : mtvec_reg ;  //30bit的base 2bit mode
assign mtvec_r = mtvec_reg;
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mtvec_reg <= 32'b0 ;
	else if(mtvec_wr )
		mtvec_reg <= mtvec_next;

end

//0x306 mcounteren MRW 无smode umode 不存在

//0x310 mstatush 
wire index_mstatush = (csr_index == 12'h310);
wire mstatush_rd = index_mstatush & read_csr;

wire[`ZCRV_XLEN-1:0] mstatush_reg ;

assign mstatush_reg = 32'b0;

//0x340 mscratch MRW

wire index_mscratch = (csr_index == 12'h340);
wire mscratch_wr = index_mscratch & write_csr ;
wire mscratch_rd = index_mscratch & read_csr;


reg[`ZCRV_XLEN-1:0]	 mscratch_reg ;
wire[`ZCRV_XLEN-1:0] mscratch_next ;

assign mscratch_next = mscratch_wr ? csr_wr_data : mscratch_reg ; 

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mscratch_reg <= 32'b0 ;
	else if(mscratch_wr )
		mscratch_reg <= mscratch_next;

end

//0x341 mepc MWR  32bit [1:0] = 0

wire index_mepc = (csr_index == 12'h341);
wire mepc_wr = index_mepc & write_csr ;
wire mepc_rd = index_mepc & read_csr;


reg[`ZCRV_XLEN-1:0]	 mepc_reg ;
wire[`ZCRV_XLEN-1:0] mepc_next ;

assign mepc_next[31:2] = trap_en ? mepc_from_eiu[31:2] : mepc_wr ? csr_wr_data[31:2] : mepc_reg[31:2] ;  
assign mepc_next[1:0]  = 2'b00;
assign mepc_r = mepc_reg;
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mepc_reg <= 32'b0 ;
	else if(mepc_wr | trap_en)
		mepc_reg <= mepc_next;

end

//0x342 mcause 
wire index_mcause = (csr_index == 12'h342);
wire mcause_wr = index_mcause & write_csr ;
wire mcause_rd = index_mcause & read_csr;


reg[`ZCRV_XLEN-1:0]	 mcause_reg ;
wire[`ZCRV_XLEN-1:0] mcause_next ;

assign mcause_next[31]  = trap_en ? mcause_from_eiu[31] : mcause_wr ? csr_wr_data[31] : mcause_reg[31] ;  
assign mcause_next[30:4]= 27'b0;
assign mcause_next[3:0] = trap_en ? mcause_from_eiu[3:0] : mcause_wr ? csr_wr_data[3:0] : mcause_reg[3:0] ;  

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mcause_reg <= 32'b0 ;
	else if(mcause_wr | trap_en)
		mcause_reg <= mcause_next;

end

//0x343 mtval MWR 异常值寄存器
wire index_mtval = (csr_index == 12'h343);
wire mtval_wr = index_mtval & write_csr ;
wire mtval_rd = index_mtval & read_csr;


reg[`ZCRV_XLEN-1:0]	 mtval_reg ;
wire[`ZCRV_XLEN-1:0] mtval_next ;

assign mtval_next  = trap_en ? mtval_from_eiu : mtval_wr ? csr_wr_data : mtval_reg ;  

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mtval_reg <= 32'b0 ;
	else if(mtval_wr | trap_en)
		mtval_reg <= mtval_next;

end

//machine memory protection regfile 不存在


//0x320 mcountinhibit MRW
wire index_mcountinhibit = (csr_index == 12'h320);
wire mcountinhibit_wr = index_mcountinhibit & write_csr ;
wire mcountinhibit_rd = index_mcountinhibit & read_csr;


reg[`ZCRV_XLEN-1:0]	 mcountinhibit_reg ;
wire[`ZCRV_XLEN-1:0] mcountinhibit_next ;

assign mcountinhibit_next[31:3]  = 29'b0 ;
assign mcountinhibit_next[2]  = mcountinhibit_wr ? csr_wr_data[2] : mcountinhibit_reg[2] ;  //ir
assign mcountinhibit_next[1]  = 1'b0 ;
assign mcountinhibit_next[0]  = mcountinhibit_wr ? csr_wr_data[0] : mcountinhibit_reg[0] ;  //cy
   

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
		mcountinhibit_reg <= 32'b0 ;
	else if (mcountinhibit_wr )
		mcountinhibit_reg <= mcountinhibit_next;

end

 
//0xb00 mcycle MRW 0xb80 mcycleh MRW
wire index_mcycle  = (csr_index == 12'hB00);
wire index_mcycleh = (csr_index == 12'hb80);

wire mcycle_wr = index_mcycle & write_csr ;
wire mcycle_rd = index_mcycle & read_csr;

wire mcycleh_wr = index_mcycleh & write_csr ;
wire mcycleh_rd = index_mcycleh & read_csr;



reg[`ZCRV_XLEN-1:0]	 mcycle_reg ;
wire[`ZCRV_XLEN-1:0] mcycle_next ;

reg[`ZCRV_XLEN-1:0]	 mcycleh_reg ;
wire[`ZCRV_XLEN-1:0] mcycleh_next ;


assign {mcycleh_next,mcycle_next} = mcycle_wr ? {mcycleh_reg,csr_wr_data} : mcycleh_wr ?
											 {csr_wr_data , mcycle_reg } : mcountinhibit_reg[0] ? {mcycleh_reg,mcycle_reg} 
														: {mcycleh_reg,mcycle_reg}  + 1'b1 ;

  

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		mcycle_reg <= 32'b0 ;
		mcycleh_reg <= 32'b0 ;
	end
	else 
	begin
		mcycle_reg <= mcycle_next;
		mcycleh_reg <= mcycleh_next;
	end

end

//0xb02 minstret  0xb82 minstreth  指令完成计数器 
wire index_minstret  = (csr_index == 12'hb02);
wire index_minstreth = (csr_index == 12'hb82);

wire minstret_wr = index_minstret & write_csr ;
wire minstret_rd = index_minstret & read_csr;

wire minstreth_wr = index_minstreth & write_csr ;
wire minstreth_rd = index_minstreth & read_csr;



reg[`ZCRV_XLEN-1:0]	 minstret_reg ;
wire[`ZCRV_XLEN-1:0] minstret_next ;

reg[`ZCRV_XLEN-1:0]	 minstreth_reg ;
wire[`ZCRV_XLEN-1:0] minstreth_next ;


assign {minstreth_next,minstret_next} = minstret_wr ?  {minstreth_reg , csr_wr_data} : minstreth_wr ? 
											 {csr_wr_data , minstret_reg } : (inst_finish & (~mcountinhibit_reg[2])) ? {minstreth_reg,minstret_reg}  + 1'b1 
												:{minstreth_reg,minstret_reg} ;

  

always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		minstret_reg <= 32'b0 ;
		minstreth_reg <= 32'b0 ;
	end
	else if(minstret_wr | minstreth_wr | inst_finish)
	begin
		minstret_reg <= minstret_next;
		minstreth_reg <= minstreth_next;
	end

end



//MRO
//0xF11 MRO mvendorid Vendor ID.
//0xF12 MRO marchid Architecture ID.
//0xF13 MRO mimpid Implementation ID.
//0xF14 MRO mhartid Hardware thread ID.

wire index_mvendorid = (csr_index == 12'hF11);
wire index_marchid = (csr_index == 12'hF12);
wire index_mimpid = (csr_index == 12'hF13);
wire index_mhartid = (csr_index == 12'hF14);

wire[`ZCRV_XLEN-1:0] mvendorid_reg = 32'b0;
wire[`ZCRV_XLEN-1:0] marchid_reg   = 32'b0;
wire[`ZCRV_XLEN-1:0] mimpid_reg    =  32'b0;
wire[`ZCRV_XLEN-1:0] mhartid_reg   =  32'b0;

wire mvendorid_rd = read_csr & index_mvendorid;
wire marchid_rd   = read_csr & index_marchid;
wire mimpid_rd    = read_csr & index_mimpid;
wire mhartid_rd   = read_csr & index_mhartid;



//read

assign csr_rd_data = 32'b0
               | ({32{mstatus_rd  }} & mstatus_reg  )
               | ({32{mie_rd      }} & mie_reg      )
               | ({32{mtvec_rd    }} & mtvec_reg    )
               | ({32{mepc_rd     }} & mepc_reg     )
               | ({32{mscratch_rd }} & mscratch_reg )
               | ({32{mcause_rd   }} & mcause_reg   )
               | ({32{mtval_rd    }} & mtval_reg    )
               | ({32{mip_rd      }} & mip_reg      )
               | ({32{misa_rd     }} & misa_reg     )
               | ({32{mvendorid_rd}} & mvendorid_reg)
               | ({32{marchid_rd  }} & marchid_reg  )
               | ({32{mimpid_rd   }} & mimpid_reg   )
               | ({32{mhartid_rd  }} & mhartid_reg  )
               | ({32{mcycle_rd   }} & mcycle_reg   )
               | ({32{mcycleh_rd  }} & mcycleh_reg  )
               | ({32{minstret_rd }} & minstret_reg )
               | ({32{minstreth_rd}} & minstreth_reg)
			   | ({32{mcountinhibit_rd}} & mcountinhibit_reg)
			   | ({32{mstatush_rd}} & mstatush_reg);

endmodule