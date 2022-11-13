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

	output reg [REGISTER_BITS - 1:0] regA_sel, /* register A select */
	output reg [REGISTER_BITS - 1:0] regB_sel  /* register B select */
);

`include "slurm32_cpu_decode_functions.v"
`include "slurm32_cpu_defs.v"

always @(*)
begin
	regA_sel = 8'd0;	// Default: read r0 (=0)
	regB_sel = 8'd0;    // ...

	casex (instruction)
		INSTRUCTION_CASEX_ALUOP_REG_REG:	begin	/* alu op, reg reg */
			regA_sel	= reg_src1_from_ins(instruction);
			regB_sel	= reg_src2_from_ins(instruction);
		end
		default: ;
	endcase
end



endmodule
