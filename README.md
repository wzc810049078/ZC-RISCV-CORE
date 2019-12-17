ZC RISCV CORE


一个支持rv32imicsrifence指令集的处理器核，支持itcm和dtcm，实现了csr，支持外部中断，软件中断，外部中断信号。

3级流水线：取指，译码/执行，回写。

取指:采用2bit预测器，jal直接跳转，bxx预测跳转，bht由来自写回阶段的预测修正单元维护。

译码/执行:译码和执行指令，访存指令这一阶段直接由lsu_agu发从给itcm或dtcm，乘除法指令由mdu进行执行，乘法采用booth4算法，除法采用srt4算法，最多16个周期          计算出结果，执行过程中，若出现冲突，由停顿单元处理。

写回:将未错误指令结果写至寄存器，eiu单元处理中断和异常和一些系统指令，预测修正单元处理预测的结果，并产生冲刷和冲刷地址由冲刷单元送给整个处理器核。乘除法     指令优先写回。

isa中为由riscv-tests而得到的测试程序，直接读入itcm就能验证了。

邮箱：1808864162@qq.com


A processor core supporting rv32imicsrifence instruction set, supporting ITCM and dtcm, realizing CSR, supporting external interrupt, software interrupt and external interrupt signal.


3 stage pipeline: fetch, decode / execute, write back.


IF: using 2 bit predictor, JAL directly jumps, Bxx predicts jumps, BHT is maintained by prediction correction unit in self write back stage.


Decoding / execution: decoding and executing instructions, memory access instructions are directly sent from LSU AGU to ITCM or dtcm, multiplication and division instructions are executed by MDU, booth4 algorithm is used for multiplication, SRT4 algorithm is used for division, and the results are calculated in 16 cycles at most. In the process of execution, if there is conflict, it is handled by pause unit.


Write back: write the result of error free instruction to the register, EIU unit processes interrupts and exceptions and some system instructions, predicts the predicted result of correction unit, and generates scour and scour address, which is sent to the whole processor core by scour unit. The multiply divide instruction takes precedence over write back.


In ISA, the test program obtained by riscv tests can be verified by directly reading into ITCM.
