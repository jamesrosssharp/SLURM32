module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

reg [31:0] instruction;
reg [31:0] aluOut;
reg [31:0] memory_in;

reg [31:0] pc_stage4;
reg [3:0] memory_mask_delayed = 4'd0;

reg nop_stage4;

reg load_interrupt_return_address;

reg cond_pass;

wire [7:0] reg_wr_sel;
wire [31:0] reg_out;



slurm32_cpu_writeback wb0
(
	instruction,		/* instruction in pipeline slot 4 */
	aluOut,
	memory_in, 

	/* write back register select and data */
	reg_wr_sel,
	reg_out,

	pc_stage4,
	memory_mask_delayed,

	nop_stage4,	/* instruction in pipeline slot 4 is NOP'd out */

	load_interrupt_return_address,

	/* conditional instruction passed in stage2 */
	cond_pass
);

reg [127:0] test_name;
reg [63:0] pass_fail = "";

initial begin
	
	/* 1. Pass in add r3, r4, r5 
	 * we should see:
 	 *
 	 * reg_wr_sel -> r3
 	 * reg_out -> alu out (32'haa55aa55
	 *
 	 */

	pass_fail <= "CHK";
	test_name <= "Test 1";
	instruction <= 32'h21030405; /* add r3, r4, r5 */
	
	aluOut <= 32'haa55aa55;
	memory_in <= 32'hdeadbeef;

	pc_stage4 <= 32'h00000100;
	memory_mask_delayed = 4'd0;

	nop_stage4 <= 1'b0;
	load_interrupt_return_address <= 1'b0;
	cond_pass <= 1'b0;

	# 100;
	assert(reg_wr_sel == 8'h03) else $fatal;
	assert(reg_out == 32'haa55aa55) else $fatal;	
	
	if (reg_wr_sel == 8'h03 && reg_out == 32'haa55aa55)
		pass_fail <= "Pass";
	else
		pass_fail <= "Fail";

	#1000;

	/* 2. Pass in add r3, r4, r5 but NOP'd out
	 * we should see:
 	 *
 	 * reg_wr_sel -> r0
 	 * reg_out -> alu out (32'haa55aa55
	 *
 	 */

	pass_fail <= "CHK";
	test_name <= "Test 2";
	instruction <= 32'h21030405; /* add r3, r4, r5 */
	
	aluOut <= 32'haa55aa55;
	memory_in <= 32'hdeadbeef;

	pc_stage4 <= 32'h00000100;
	memory_mask_delayed = 4'd0;

	nop_stage4 <= 1'b1; // NOP'd out
	load_interrupt_return_address <= 1'b0;
	cond_pass <= 1'b0;

	# 100;
	assert(reg_wr_sel == 8'h00) else $fatal;
	assert(reg_out == 32'haa55aa55) else $fatal;	
	
	if (reg_wr_sel == 8'h00 && reg_out == 32'haa55aa55)
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
