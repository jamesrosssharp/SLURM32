/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 decode functions
 *
 */

/* verilator lint_off UNUSED */
function [4:0] alu_op_from_ins;
input [31:0] ins;
begin
	alu_op_from_ins = {1'b0, ins[27:24]}; 
end
endfunction


