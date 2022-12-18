
SRCDIR=../../../src

SOURCE= $(SRCDIR)/slurm32_cpu_writeback.v

 
PROJECT=cpu_writeback

all: sim

.PHONY: sim

sim: $(SOURCE) tb.sv 
	iverilog  -g2012 -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.sv $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
