
SRCDIR=../../../src

SOURCE= $(SRCDIR)/slurm32_cpu_alu.v $(SRCDIR)/mult.v $(SRCDIR)/unsigned_mult.v
 
PROJECT=cpu_alu

all: sim

.PHONY: sim

sim: $(SOURCE) tb.sv 
	iverilog  -g2012 -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.sv $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

sim-no-assert: $(SOURCE) tb.sv 
	iverilog -gno-assertions -g2012 -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.sv $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 



clean: 
	rm $(PROJECT)_design
	rm dump.vcd
