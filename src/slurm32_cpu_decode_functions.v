/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 decode functions
 *
 */

`include "slurm32_cpu_defs.v"

/* verilator lint_off UNUSED */
function [4:0] alu_op_from_ins;
input [31:0] ins;
begin
	alu_op_from_ins = {1'b0, ins[27:24]}; 
end
endfunction

function [7:0] reg_src_from_ins;
input [31:0] ins;
begin
	reg_src_from_ins = ins[15:8];
end
endfunction

function [7:0] reg_src2_from_ins;
input [31:0] ins;
begin
	reg_src2_from_ins = ins[7:0];
end
endfunction

function [7:0] reg_dest_from_ins;
input [31:0] ins;
begin
	reg_dest_from_ins = ins[23:16];
end
endfunction

function [7:0] reg_branch_ind_from_ins;
input [31:0] ins;
begin
	reg_branch_ind_from_ins = ins[15:8];
end
endfunction


