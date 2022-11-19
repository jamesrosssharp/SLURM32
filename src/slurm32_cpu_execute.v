/*
 *	Execute pipeline stage: execute instruction (alu, branch, load / store)
 *	
 *
 */

module cpu_execute #(parameter REGISTER_BITS = 4, BITS = 16, ADDRESS_BITS = 16)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 2 */

	input is_executing,

	/* flags (for branches) */

	input Z,
	input C,
	input S,
	input V,

	input [BITS - 1:0] regA,
	input [BITS - 1:0] regB,

	/* immediate register */
	input [BITS - 1:0] imm_reg,

	/* memory op */

	/* alu op */
	output [4:0] aluOp,
	output [BITS - 1:0] aluA,
	output [BITS - 1:0] aluB,

	/* load PC for branch / (i)ret, etc */
	output load_pc,
	output [ADDRESS_BITS - 1:0] new_pc,

	output interrupt_flag_set,
	output interrupt_flag_clear,

	output halt

);




endmodule
