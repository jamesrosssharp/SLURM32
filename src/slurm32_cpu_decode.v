/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 instruction decoder
 *
 */

module cpu_decode #(parameter BITS = 32, ADDRESS_BITS = 32, REGISTER_BITS = 8)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 1 (or 0 for hazard decoder) */

	output [REGISTER_BITS - 1:0] regA_sel, /* register A select */
	output [REGISTER_BITS - 1:0] regB_sel  /* register B select */
);

`include "cpu_decode_functions.v"
`include "cpu_defs.v"

reg [REGISTER_BITS - 1:0] regARdAddr_r;
reg [REGISTER_BITS - 1:0] regBRdAddr_r;
 
assign regA_sel = regARdAddr_r;
assign regB_sel = regBRdAddr_r;
 
always @(*)
begin
	regARdAddr_r = 8'd0;	// Default: read r0 (=0)
	regBRdAddr_r = 8'd0;    // ...

	casex (instruction)
		INSTRUCTION_CASEX_ALUOP_REG_REG:	begin	/* alu op, reg reg */
			regARdAddr_r	= reg_src1_from_ins(instruction);
			regBRdAddr_r	= reg_src2_from_ins(instruction);
		end
		default: ;
	endcase
end



endmodule
