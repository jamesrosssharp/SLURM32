module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

wire instruction_request;
reg instruction_valid = 1'b0;
wire [31:0] instruction_address;
reg [31:0] instruction_in;

wire [31:0] pipeline_stage_0;
wire [31:0] pipeline_stage_1;
wire [31:0] pipeline_stage_2;
wire [31:0] pipeline_stage_3;
wire [31:0] pipeline_stage_4;

wire [31:0] pc_stage_4;

reg halt_request = 1'b0;
reg interrupt = 1'b0;
reg [3:0] irq = 4'd0;

reg [31:0] load_pc_address;
reg load_pc_request;

reg debugger_halt_request = 1'b0;
reg debugger_load_pc_request = 1'b0;
reg [31:0] debugger_load_pc_address = 32'h00000000;

reg interrupt_flag_clear = 1'b0;
reg interrupt_flag_set = 1'b0;

reg memory_request_successful = 1'b1;

slurm32_cpu_pipeline pip0 (
	CLK,
	RSTb,

	/* Instruction input */
	instruction_request,	/* asserted if the pipeline is fetching instructions */
	instruction_valid,	/* asserted if the instruction requested was fetched from memory. deasserted on e.g. cache miss */
	instruction_address, /* the address to fetch the next instruction from */
	instruction_in,

	/* Pipeline stage output */
	pipeline_stage_0,
	pipeline_stage_1,
	pipeline_stage_2,
	pipeline_stage_3,
	pipeline_stage_4,
 
	pc_stage_4,

	/* Control signals */

	halt_request,		/* Sleep instruction requests CPU halt */

	interrupt,		/* Interrupt request from interrupt controller */
	irq,		/* IRQ from interrupt controller */ 

	load_pc_request,		/* Branch instruction */
	load_pc_address,

	interrupt_flag_clear,
	interrupt_flag_set,

	memory_request_successful,	

	/* Debugger interface */

	debugger_halt_request,	/* Debugger requests CPU halt */
	debugger_load_pc_request, /* Debugger load PC */
	debugger_load_pc_address

);

initial begin	
	#240 instruction_valid <= 1'b1;
 		instruction_in <= 32'h21010203;
	#100 instruction_in <= 32'h21020304;
	#100 instruction_in <= 32'h21030405;	
	#100 instruction_valid <= 1'b0;
	#300 instruction_valid <= 1'b1;
	#100 interrupt_flag_set <= 1'b1;
	#100 interrupt <= 1'b1;
	     interrupt_flag_set <= 1'b0;
	#300 interrupt_flag_clear <= 1'b1;
	#400 interrupt_flag_clear <= 1'b0;
	#500 interrupt <= 1'b0;
	#100 instruction_in <= 32'hc0000000;
		memory_request_successful <= 1'b0;
	#800 interrupt_flag_set <= 1'b1;
	#100 interrupt <= 1'b1;
	     interrupt_flag_set <= 1'b0;
	#300 interrupt_flag_clear <= 1'b1;
	#400 interrupt_flag_clear <= 1'b0;
	
	// Cases to test:
	// 1. Instruction cache miss
	// 2. Instruction cache miss while memory exception
	// 3. Halt while memory exception
	// 4. Interrupt while memory exception
	// 5. Interrupt

end

initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 5000 $finish;
end

endmodule
