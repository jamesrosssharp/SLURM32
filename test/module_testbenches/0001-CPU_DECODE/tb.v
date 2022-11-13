module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #50 CLK <= !CLK; // ~ 10MHz

initial begin 
	#150 RSTb = 1'b1;
end

wire [7:0] regA_sel;
wire [7:0] regB_sel;

reg [31:0] instruction = 32'h00000000;

cpu_decode dec0
(
	CLK,
	RSTb,

	instruction,	

	regA_sel, 
	regB_sel  
);



initial begin	
	// Set to ADD r2, r3, r4
	# 200 instruction <=  32'h21020304;
	# 400 instruction <=  32'h10123456; 
end

initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 2000 $finish;
end

endmodule
