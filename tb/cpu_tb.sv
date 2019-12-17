
`timescale 1 ps/ 1 ps
module cpu_top_vlg_tst();

reg clk;
reg ext_irq;
reg rst_n;
reg soft_irq;
reg time_irq;

wire[31:0] x3 = i1.i1.regfile.regfile_r[3];
wire[31:0] x26 = i1.i1.regfile.regfile_r[26];
wire[31:0] x27 = i1.i1.regfile.regfile_r[27];
wire[31:0] x10 = i1.i1.regfile.regfile_r[10];

wire[31:0] inst = i1.itcm.inst_to_ifu;
wire[31:0] inst_addr = i1.itcm.pc_from_ifu;
// wires                                               

// assign statements (if any)                          
cpu_top i1 (
// port map - connection between master ports and signals/registers   
	.clk(clk),
	.ext_irq(ext_irq),
	.rst_n(rst_n),
	.soft_irq(soft_irq),
	.time_irq(time_irq)
);
integer i ;
initial                                                
begin                                                  
clk = 0;
forever #10 clk = ~clk;                  
end          
initial                                                
begin   
$display("test running...");
rst_n = 1;
ext_irq = 0;
soft_irq = 0;
time_irq = 0;
#1 rst_n = 0;
#1 rst_n = 1;
#8;   
#100;
wait(inst_addr == 32'h8000014c);  
#10;
if (inst_addr == 32'h8000014c) 
begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
            $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
end else begin
            $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("fail testnum = %2d", x3);
end
for (i = 0; i < 32; i=i+1)
  $display("x%2d = 0x%x", i, i1.i1.regfile.regfile_r[i]);
$stop;
end


                                    
endmodule

