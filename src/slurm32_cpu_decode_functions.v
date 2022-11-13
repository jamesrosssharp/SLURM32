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

function [7:0] reg_src1_from_ins;
input [31:0] ins;
begin
	reg_src1_from_ins = ins[15:8];
end
endfunction

function [7:0] reg_src2_from_ins;
input [31:0] ins;
begin
	reg_src2_from_ins = ins[7:0];
end
endfunction


