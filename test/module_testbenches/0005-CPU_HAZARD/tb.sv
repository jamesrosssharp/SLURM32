module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

reg  [31:0] instruction;
reg  [7:0]  regA_sel0;
reg  [7:0]  regB_sel0;

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

slurm32_cpu_hazard haz0
(
        instruction, 

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

reg [127:0] test_name;
reg [63:0] pass_fail = "";

initial begin
	
	/* 1. Pass in add r3, r4, r5 
 	 * with hazard_reg1 = r4
	 * we should see:
 	 *
 	 */

	pass_fail <= "CHK";
	test_name <= "Test 1";
	instruction <= 32'h21030405; /* add r3, r4, r5 */

	regA_sel0 <= 8'd4;
	regB_sel0 <= 8'd5;

	hazard_reg1 <= 8'd4;
	hazard_reg2 <= 8'd0;
	hazard_reg3 <= 8'd0;

	modifies_flags1 <= 1'b0;
	modifies_flags2 <= 1'b0;
	modifies_flags3 <= 1'b0;

	# 100;
	assert(hazard_1 == 1'b1) else $fatal;
	assert(hazard_2 == 1'b0) else $fatal;	
	assert(hazard_3 == 1'b0) else $fatal;	

	if (hazard_1 == 1'b1 && hazard_2 == 1'b0 && hazard_3 == 1'b0)
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
