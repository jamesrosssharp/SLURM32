module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end


wire instruction_request;
reg instruction_valid = 1'b0;
wire [29:0] instruction_address;
reg [31:0] instruction_in;
reg [29:0] instruction_address_in;

wire [31:0] pipeline_stage_0;
wire [31:0] pipeline_stage_1;
wire [31:0] pipeline_stage_2;
wire [31:0] pipeline_stage_3;
wire [31:0] pipeline_stage_4;

wire [31:0] pc_stage_4;

wire halt_request;
reg interrupt = 1'b0;
reg [3:0] irq = 4'd0;

reg [31:0] load_pc_address;
reg load_pc_request;

reg debugger_halt_request = 1'b0;
reg debugger_load_pc_request = 1'b0;
reg [31:0] debugger_load_pc_address = 32'h00000000;

wire interrupt_flag_clear;
wire interrupt_flag_set;

reg memory_request_successful = 1'b1;

reg [3:0] memory_mask_delayed = 4'd0;

reg nop_stage4;

reg load_interrupt_return_address;

reg cond_pass;

reg [7:0] hazard_reg1;
reg [7:0] hazard_reg2;
reg [7:0] hazard_reg3;

reg modifies_flags1;
reg modifies_flags2;
reg modifies_flags3;

wire [7:0]  hazard_reg0;
wire modifies_flag0;

wire hazard_1;
wire hazard_2;
wire hazard_3;

wire nop_stage_2;
wire nop_stage_4;

wire Z;
wire C;
wire V;
wire S;

wire Z_out;
wire C_out;
wire V_out;
wire S_out;

wire flags_load;

wire is_mem_request;
wire cond_pass_in;

wire load_return_address;

wire cond_pass_stage4;

wire [23:0] imm_reg;

slurm32_cpu_pipeline pip0 (
	CLK,
	RSTb,

	instruction_request,	
	instruction_valid,	
	instruction_address, 
	instruction_in,
	instruction_address_in,

	pipeline_stage_0,
	pipeline_stage_1,
	pipeline_stage_2,
	pipeline_stage_3,
	pipeline_stage_4,
 
	pc_stage_4,

	nop_stage_2,
	nop_stage_4,

	imm_reg,

	Z,
	C,
	V,
	S,

	Z_out,
	C_out,
	V_out,
	S_out,

	flags_load,

 	hazard_1, /* hazard between instruction in slot0 and slot1 */
        hazard_2, /* hazard between instruction in slot0 and slot2 */
        hazard_3, /* hazard between instruction in slot0 and slot3 */

        hazard_reg0,    /*  import hazard computation, it will move with pipeline in pipeline module */
        modifies_flags0,                                                /*  import flag hazard conditions */

        hazard_reg1,            /* export pipelined hazards */
        hazard_reg2,
        hazard_reg3,
        modifies_flags1,
        modifies_flags2,
        modifies_flags3,
	
	halt_request,

	interrupt,
	irq,

	load_pc_request,	
	load_pc_address,

	interrupt_flag_clear,
	interrupt_flag_set,

	memory_request_successful,
	is_mem_request,
	cond_pass_in,

	load_return_address,

	cond_pass_stage4
);

wire [7:0] regA_sel0;
wire [7:0] regB_sel0;

slurm32_cpu_decode dec0 
(
	CLK,
	RSTb,

	pipeline_stage_0,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel0, /* register A select */
	regB_sel0  /* register B select */
);

wire [7:0] regA_sel1;
wire [7:0] regB_sel1;

slurm32_cpu_decode dec1 
(
	CLK,
	RSTb,

	pipeline_stage_1,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel1, /* register A select */
	regB_sel1  /* register B select */
);

reg [31:0] aluOut;
reg [31:0] memory_in;

wire [7:0] reg_wr_sel;
wire [31:0] reg_out;

slurm32_cpu_writeback wb0
(
	pipeline_stage_4,		/* instruction in pipeline slot 4 */
	aluOut,
	memory_in, 

	/* write back register select and data */
	reg_wr_sel,
	reg_out,

	pc_stage_4,
	memory_mask_delayed,

	nop_stage_4,	/* instruction in pipeline slot 4 is NOP'd out */

	load_return_address,

	/* conditional instruction passed in stage2 */
	cond_pass_stage4
);

slurm32_cpu_hazard haz0
(
        pipeline_stage_0, 

        regA_sel0,          	/* registers that pipeline0 instruction will read from */
        regB_sel0,

        hazard_reg0,    	/*  export hazard computation, it will move with pipeline in pipeline module */
        modifies_flags0,        /*  export flag hazard conditions */

        hazard_reg1,        	/* import pipelined hazards */
        hazard_reg2,
        hazard_reg3,
        modifies_flags1,
        modifies_flags2,
        modifies_flags3,

        hazard_1,
        hazard_2,
        hazard_3
);

wire [31:0] aluA;
wire [31:0] aluB;
wire [4:0] aluOp;

wire [31:0] regA;
wire [31:0] regB;

wire [29:0] load_store_address;
wire [31:0] memory_out;

wire [3:0] memory_mask;

slurm32_cpu_execute exec0
(
	CLK,
	RSTb,

	pipeline_stage_2,		/* instruction in pipeline slot 2 */

	/* flags (for branches) */

	Z,
	C,
	S,
	V,

	/* registers in from decode stage */
	regA,
	regB,

	/* immediate register */
	imm_reg,

	/* memory op */
	load_memory,
	store_memory,
	load_store_address,
	memory_out,
	memory_mask,

	/* alu op */
	aluOp,
	aluA,
	aluB,

	/* load PC for branch / (i)ret, etc */
	load_pc_request,
	load_pc_address,

	interrupt_flag_set,
	interrupt_flag_clear,

	halt_request,

	cond_pass_in

);

slurm32_cpu_alu alu0
(
	CLK,	/* ALU has memory for flags */
	RSTb,

	aluA,
	aluB,
	aluOp,
	aluOut,

	C, /* carry flag */
	Z, /* zero flag */
	S, /* sign flag */
	V,  /* signed overflow flag */

	C_out,
	Z_out,
	S_out,
	V_out,

	load_flags

);

slurm32_cpu_registers reg0
(
	CLK,
	RSTb,
	reg_wr_sel,
	regA_sel1,
	regB_sel1,	
	regA,
	regB,
	reg_out
);

/*	Create an instruction memory for tests 		*/

reg [31:0] memory [127:0];
integer i;

initial begin
	memory[0] = 32'h30010003;		/* mov r1, 3 */
	memory[1] = 32'h30020007;		/* mov r2, 7 */
	memory[2] = 32'h21030102;		/* add r3, r1, r2 */
	for (i = 3; i < 128; i = i + 1)
		memory[i] = 32'h00000000; 
end

always @(posedge CLK)
begin
	instruction_valid <= instruction_request;
	instruction_in <= memory[instruction_address[6:0]];
	instruction_address_in <= instruction_address;
end

/* instruction memory interface */


//initial begin
//        $display("Loading rom.");
//        $readmemh("prog.mem", memory);
//end

/* 		Run some tests on the modules 		*/

reg [127:0] test_name;
reg [63:0] pass_fail = "";

initial begin
	
	#200
	
	/* 1. Pass in add r3, r4, r5 
	 * we should see:
 	 *
 	 *  aluOp -> 5'd1 after 1 cycle
 	 *  aluA -> regA
 	 *  aluB -> regB
 	 */

	pass_fail <= "CHK";
	test_name <= "Test 1";


	# 100;
	//assert(aluOut == 32'd7) else $fatal;

	//if (aluOut == 32'd7 && C == 1'b0 && Z == 1'b0 && V == 1'b0 && S == 1'b0)
	//	pass_fail <= "Pass";
	//else
	//	pass_fail <= "Fail";

	#1000;

end


initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 5000 $finish;
end

endmodule
