module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

reg [31:0] A;
reg [31:0] B;

reg  [4:0]  aluOp;

reg C_in;
reg Z_in;
reg V_in;
reg S_in;

reg load_flags;

wire [31:0] aluOut;

wire C;
wire Z;
wire S;
wire V;

slurm32_cpu_alu alu0
(
	CLK,	/* ALU has memory for flags */
	RSTb,

	A,
	B,
	aluOp,
	aluOut,

	C, /* carry flag */
	Z, /* zero flag */
	S, /* sign flag */
	V,  /* signed overflow flag */

	C_in,
	Z_in,
	S_in,
	V_in,

	load_flags

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

	A <= 32'd3;
	B <= 32'd4;

	aluOp <= 5'd1;

	C_in <= 1'b0;
	Z_in <= 1'b0;
	V_in <= 1'b0;
	S_in <= 1'b0;

	load_flags <= 1'b0;

	# 100;
	assert(aluOut == 32'd7) else $fatal;
	assert(C == 1'b0) else $fatal;
	assert(Z == 1'b0) else $fatal;
	assert(V == 1'b0) else $fatal;
	assert(S == 1'b0) else $fatal;

	if (aluOut == 32'd7 && C == 1'b0 && Z == 1'b0 && V == 1'b0 && S == 1'b0)
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
