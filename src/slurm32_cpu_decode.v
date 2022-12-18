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

always @(*)
begin
	regA_sel = {REGISTER_BITS{1'b0}};	// Default: read r0 (=0)
	regB_sel = {REGISTER_BITS{1'b0}};	// ...

	casex (instruction)
		INSTRUCTION_CASEX_RET_IRET:	begin	/* ret / iret */
			if (is_ret_or_iret(instruction) == 1'b0)
				regA_sel = LINK_REGISTER;
			else 
				regA_sel = INTERRUPT_LINK_REGISTER;
		end
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG: begin /* alu op reg */
			regB_sel	= reg_src2_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALUOP_REG_REG:	begin	/* alu op, reg reg */
			regA_sel	= reg_src_from_ins(instruction);
			regB_sel	= reg_src2_from_ins(instruction);
		end
		INSTRUCTION_CASEX_TWO_REG_COND_ALU:	begin	/* alu op, cond reg reg */
			regARdAddr_r	= reg_dest_from_ins(instruction);
			regBRdAddr_r	= reg_src2_from_ins(instruction);
		end
		INSTRUCTION_CASEX_ALUOP_REG_IMM:	begin	/* alu op, reg imm */
			regARdAddr_r 		= reg_src_from_ins(instruction);
		end
		INSTRUCTION_CASEX_BRANCH:	begin /* branch */
			regARdAddr_r	= reg_branch_ind_from_ins(instruction);
		end
		/* TODO : MEMORY ACCESSS INSTRUCTIONS HERE */


		default: ;
	endcase
end



endmodule
