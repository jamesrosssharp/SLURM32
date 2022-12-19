module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

reg [31:0] instruction;
reg Z;
reg C;
reg S;
reg V;

reg [31:0] regA;
reg [31:0] regB;

reg [31:0] imm_reg;

wire load_memory;
wire store_memory;
wire [31:0] load_store_address;
wire [31:0] memory_out;
wire [3:0] memory_mask;

wire [4:0] aluOp;
wire [31:0] aluA;
wire [31:0] aluB;  

wire load_pc;
wire [31:0] new_pc;

wire interrupt_flag_set;
wire interrupt_flag_clear;

wire halt;
wire cond_pass;

slurm32_cpu_execute exec0
(
	CLK,
	RSTb,

	instruction,		/* instruction in pipeline slot 2 */

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
	load_pc,
	new_pc,

	interrupt_flag_set,
	interrupt_flag_clear,

	halt,

	cond_pass

);

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
	instruction <= 32'h21030405; /* add r3, r4, r5 */

	Z <= 1'b0;
	C <= 1'b0;
	S <= 1'b0;
	V <= 1'b0;

	regA <= 32'h01020304;
	regB <= 32'h05060708;

	imm_reg <= 32'd0;

	# 100;
	assert(aluOp == 5'd1) else $fatal;
	assert(aluA == 32'h01020304) else $fatal;
	assert(aluB == 32'h05060708) else $fatal;

	if (aluOp == 5'd1 && aluA == 32'h01020304 && aluB == 32'h05060708)
		pass_fail <= "Pass";
	else
		pass_fail <= "Fail";

	#1000;

end


initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 5000 $finish;
end

endmodule
