`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  csr instruction control unit

module csru(

input[5:0]				    csr_inst_info, 
input[`ZCRV_XLEN-1:0] 		dest_csr_data , //目标csr的数值
input[`ZCRV_XLEN-1:0] 		rs1_csr ,
input[`ZCRV_IMM_SIZE-1:0]	uimm_csr ,
input						need_csr,
//input						imm_en,

input[`ZCRV_CSRADDR_SIZE-1:0] op_csr_addr,
input						rd_x0,
input						rs1_x0,


output[`ZCRV_XLEN-1:0] 		csr_write_data,
output 						csr_rd_en,
output 						csr_wr_en


);

/*
wire[5:0] system_info = {
				rv32_csrrw,
				rv32_csrrs,
				rv32_csrrc,
				rv32_csrrwi,
				rv32_csrrsi,
				rv32_csrrci,
};*/

wire uimm_0 = (uimm_csr[4:0] == 5'b0) ;

//cssrw 
wire op_csrrw = csr_inst_info[5] ;

wire[`ZCRV_XLEN-1:0] csrrw_write_data =  rs1_csr  ;

wire	csrrw_wr_en = op_csrrw ;
wire    csrrw_rd_en = ~ rd_x0  ;

//csrrs

wire op_csrrs = csr_inst_info[4] ;

wire[`ZCRV_XLEN-1:0] csrrs_write_data = rs1_csr | dest_csr_data ;

wire	csrrs_wr_en =  ~rs1_x0 ;
wire    csrrs_rd_en = op_csrrs ;

//csrrC

wire op_csrrc = csr_inst_info[3] ;

wire[`ZCRV_XLEN-1:0] csrrc_write_data = (~rs1_csr) & dest_csr_data ;

wire	csrrc_wr_en =  ~rs1_x0 ;
wire    csrrc_rd_en = op_csrrc ;


//cssrwi 
wire op_csrrwi = csr_inst_info[2] ;

wire[`ZCRV_XLEN-1:0] csrrwi_write_data =  uimm_csr  ;

wire	csrrwi_wr_en = op_csrrwi ;
wire    csrrwi_rd_en = ~ rd_x0  ;

//csrrsi

wire op_csrrsi = csr_inst_info[1] ;

wire[`ZCRV_XLEN-1:0] csrrsi_write_data = uimm_csr | dest_csr_data ;

wire	csrrsi_wr_en =  ~uimm_0 ;
wire    csrrsi_rd_en = op_csrrsi ;

//csrrCi

wire op_csrrci = csr_inst_info[0] ;

wire[`ZCRV_XLEN-1:0] csrrci_write_data = (~uimm_csr) & dest_csr_data ;

wire	csrrci_wr_en =  ~uimm_0 ;
wire    csrrci_rd_en = op_csrrci ;



assign csr_rd_en = need_csr ? 1'b0
               |( op_csrrw  & csrrw_rd_en    )
			   |( op_csrrs  & csrrs_rd_en    )
			   |( op_csrrc  & csrrc_rd_en    )
			   |( op_csrrwi & csrrwi_rd_en   )
			   |( op_csrrsi & csrrsi_rd_en   )
			   |( op_csrrci & csrrci_rd_en   ) : 1'b0;
			   
assign csr_wr_en = need_csr ? 1'b0
               |( op_csrrw  & csrrw_wr_en    )
			   |( op_csrrs  & csrrs_wr_en    )
			   |( op_csrrc  & csrrc_wr_en    )
			   |( op_csrrwi & csrrwi_wr_en   )
			   |( op_csrrsi & csrrsi_wr_en   )
			   |( op_csrrci & csrrci_wr_en   ) : 1'b0;		

			   
assign csr_write_data = csr_wr_en ? 1'b0
               |( {32{op_csrrw}}  & csrrw_write_data    )
			   |( {32{op_csrrs}}  & csrrs_write_data    )
			   |( {32{op_csrrc}}  & csrrc_write_data    )
			   |( {32{op_csrrwi}} & csrrwi_write_data   )
			   |( {32{op_csrrsi}} & csrrsi_write_data   )
			   |( {32{op_csrrci}} & csrrci_write_data   ) : 32'b0;				   
			   


endmodule

