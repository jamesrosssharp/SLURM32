
SRCDIR=../../../src

SOURCE= $(SRCDIR)/slurm32_cpu_decode.v

 
PROJECT=cpu_decode

all: sim

.PHONY: sim

sim: $(SOURCE) tb.v 
	iverilog -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
