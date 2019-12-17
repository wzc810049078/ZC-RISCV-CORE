`include "defines.v"

// Designer   : WANG ZI CHEN
//
// Description:
//  cpu_top
// RV32IM zicsr zifence


module cpu_top(
input clk,
input rst_n,
input soft_irq,
input time_irq,
input ext_irq

);


wire [31:0] data_from_dtcm;
wire [31:0] data_from_itcm;
wire [31:0] itcm_inst_from_itcm;
wire itcm_ready_from_itcm;
wire res_from_dtcm;
wire res_from_itcm;
                                             
wire [31:0]  addr_to_dtcm;
wire [31:0]  addr_to_itcm;
wire ifureq_to_itcm;
wire load_to_dtcm;
wire load_to_itcm;
wire [31:0]  pc_to_itcm;
wire req_to_dtcm;
wire req_to_itcm;
wire [31:0]  store_result_to_ram;
wire[4:0] store_mask_to_ram;
wire store_to_dtcm;
wire store_to_itcm;
                   
core_top i1 (  
	.addr_to_dtcm(addr_to_dtcm),
	.addr_to_itcm(addr_to_itcm),
	.clk(clk),
	.data_from_dtcm(data_from_dtcm),
	.data_from_itcm(data_from_itcm),
	.ext_irq(ext_irq),
	.ifureq_to_itcm(ifureq_to_itcm),
	.itcm_inst_from_itcm(itcm_inst_from_itcm),
	.itcm_ready_from_itcm(itcm_ready_from_itcm),
	.load_to_dtcm(load_to_dtcm),
	.load_to_itcm(load_to_itcm),
	.pc_to_itcm(pc_to_itcm),
	.req_to_dtcm(req_to_dtcm),
	.req_to_itcm(req_to_itcm),
	.res_from_dtcm(res_from_dtcm),
	.res_from_itcm(res_from_itcm),
	.rst_n(rst_n),
	.soft_irq(soft_irq),
	.store_result_to_ram(store_result_to_ram),
	.store_mask_to_ram(store_mask_to_ram),
	.store_to_dtcm(store_to_dtcm),
	.store_to_itcm(store_to_itcm),
	.time_irq(time_irq)
);


itcm itcm(
.clk(clk),
.rst_n(rst_n),

.pc_from_ifu(pc_to_itcm),
.ifureq_to_itcm(ifureq_to_itcm),
.inst_to_ifu(itcm_inst_from_itcm),
.itcm_ready_to_ifu(itcm_ready_from_itcm),

.store_from_lsu(store_to_itcm),
.load_from_lsu(load_to_itcm),
.req_from_lsu(req_to_itcm),
.addr_from_lsu(addr_to_itcm),
.store_result_from_lsu(store_result_to_ram),
.store_mask_from_lsu(store_mask_to_ram),	

.res_to_lsu(res_from_itcm),
.data_to_lsu(data_from_itcm)

);
dtcm dtcm(
.clk(clk),
.rst_n(rst_n),


.store_from_lsu(store_to_dtcm),
.load_from_lsu(load_to_dtcm),
.req_from_lsu(req_to_dtcm),
.addr_from_lsu(addr_to_dtcm),
.store_result_from_lsu(store_result_to_ram),
.store_mask_from_lsu(store_mask_to_ram),		

.res_to_lsu(res_from_dtcm),
.data_to_lsu(data_from_dtcm)

);

endmodule