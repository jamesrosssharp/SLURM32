/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 registers
 *
 */

module slurm32_cpu_registers
#(parameter REG_BITS = 8 /* default 2**8 = 256 registers */, parameter BITS = 32 /* default 32 bits */)
(
	input CLK,
	input RSTb,
	input [REG_BITS - 1 : 0] regIn_sel,
	input [REG_BITS - 1 : 0] regOutA_sel,
	input [REG_BITS - 1 : 0] regOutB_sel,	
	output [BITS - 1 : 0] regOutA_data,
	output [BITS - 1 : 0] regOutB_data,
	input  [BITS - 1 : 0] regIn_data,
	input is_executing
);

reg [BITS - 1: 0] outA;
reg [BITS - 1: 0] outB;

assign regOutA_data = outA;
assign regOutB_data = outB;

reg [BITS - 1: 0] regFileA [2**REG_BITS - 1 : 0];
reg [BITS - 1: 0] regFileB [2**REG_BITS - 1 : 0];

always @(posedge CLK)
begin
	regFileA[regIn_sel] <= regIn_data;
	regFileB[regIn_sel] <= regIn_data;

	if (is_executing) begin
		if (regOutA == 4'd0)
			outA <= 16'h0;
		else
			outA <= regFileA[regOutA_sel];

		if (regOutB == 4'd0)
			outB <= 16'h0;	
		else
			outB <= regFileB[regOutB_sel];
	end
end


endmodule
