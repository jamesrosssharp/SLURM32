module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

wire [7:0] regA_sel;
wire [7:0] regB_sel;

reg [31:0] instruction;

slurm32_cpu_decode dec0 
(
	CLK,
	RSTb,

	instruction,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	regA_sel, /* register A select */
	regB_sel  /* register B select */
);

reg [127:0] test_name;
reg [63:0] pass_fail = "";

initial begin
	
	/* 1. Pass in add r3, r4, r5 
	 * we should see:
 	 *
 	 *  - regA -> r4
 	 *  - regB -> r5
 	 *
 	 */

	pass_fail <= "CHK";
	test_name <= "Test 1";
	instruction <= 32'h21030405; /* add r3, r4, r5 */
	assert(regA_sel == 8'h04);
	assert(regB_sel == 8'h05);	
	# 100;
	if (regA_sel == 8'h04 && regB_sel == 8'h05)
		pass_fail <= "Pass";

	#1000;

	/* 2. Pass in asr r3 
	 * We should see:
	 * 	- regA -> r0
	 *	- regB -> r3
	 *	
	 */

	pass_fail <= "CHK";
	test_name <= "Test 2";
	instruction <= 32'h04000003; /* asr r3 */
	assert(regA_sel == 8'h00);
	assert(regB_sel == 8'h03);	
	# 100;
	if (regA_sel == 8'h00 && regB_sel == 8'h03)
		pass_fail <= "Pass";

	#1000;

	/* 2. Pass in ba [r7, 0x10] 
	 * We should see:
	 * 	- regA -> r7
	 *	- regB -> r0
	 *	
	 */

	pass_fail <= "CHK";
	test_name <= "Test 3";
	instruction <= 32'h4e000710; /* ba [r7, 0x10] */
	assert(regA_sel == 8'h07);
	assert(regB_sel == 8'h00);	
	# 100;
	if (regA_sel == 8'h07 && regB_sel == 8'h00)
		pass_fail <= "Pass";

	#1000;



end


initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 5000 $finish;
end

endmodule
