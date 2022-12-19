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

function is_branch_link_from_ins;
input [15:0] ins;
	is_branch_link_from_ins = (ins[27:24] == COND_L) ? 1'b1 : 1'b0;
endfunction

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

function is_ret_or_iret;
input [31:0] ins;
		is_ret_or_iret = ins[0];	// 1 = iret, 0 = ret
endfunction

function uses_flags_for_branch;
input [31:0] ins;
begin
	case(ins[27:24])
		COND_A,  COND_L:
			uses_flags_for_branch = 1'b0;
		default:
			uses_flags_for_branch = 1'b1;
	endcase
end
endfunction

function [4:0] single_reg_alu_op_from_ins;
input [31:0] ins;
begin
	single_reg_alu_op_from_ins = {1'b1, ins[11:8]}; 
end
endfunction

function eval_cond;
input [3:0] cond;
input Z_in;
input S_in;
input C_in;
input V_in;
begin
	case(cond)
		COND_EQ :		/* 0x0 - BZ, BEQ branch if ZERO */
			if (Z_in == 1'b1) eval_cond = 1'b1;
			else eval_cond = 1'b0;
	
		COND_NE :		/* 0x1 - BNZ, BNE branch if not ZERO */
			if (Z_in == 1'b0) eval_cond = 1'b1;
			else eval_cond = 1'b0;
	
		COND_S:		/* 0x2 - BS, branch if SIGN */
			if (S_in == 1'b1) eval_cond = 1'b1;
			else eval_cond = 1'b0;
	
		COND_NS:		/* 0x3 - BNS, branch if not SIGN */
			if (S_in == 1'b0) eval_cond = 1'b1;
			else eval_cond = 1'b0;
	
		COND_C:		/* 0x4 - BC, BLTU branch if CARRY */
			if (C_in == 1'b1) eval_cond = 1'b1;
			else eval_cond = 1'b0;
	
		COND_NC:		/* 0x5 - BNC, BGEU, branch if not CARRY */
			if (C_in == 1'b0) eval_cond = 1'b1;
			else eval_cond = 1'b0;
		COND_V:		/* 0x6 - BV, branch if OVERFLOW */
			if (V_in == 1'b1) eval_cond = 1'b1;
			else eval_cond = 1'b0;
		COND_NV:		/* 0x6 - BNV, branch if not OVERFLOW */
			if (V_in == 1'b0) eval_cond = 1'b1;
			else eval_cond = 1'b0;
		COND_LT:		/* 0x8 - BLT */
			if ((S_in ^ V_in) == 1'b1) eval_cond = 1'b1;
			else eval_cond = 1'b0;
		COND_LE:		/* 0x9 - BLE */
			if ((Z_in == 1'b1) || (S_in ^ V_in)) eval_cond = 1'b1;
			else eval_cond = 1'b0;
 		COND_GT:		/* 0xa - BGT */
			if ((S_in == V_in) && Z_in == 1'b0) eval_cond = 1'b1;
			else eval_cond = 1'b0;	
		COND_GE:		/* 0xb - BGE */
			if (S_in == V_in) eval_cond = 1'b1;
			else eval_cond = 1'b0;	
  		COND_LEU:		/* 0xc - BLEU */
			if (C_in == 1'b1 || Z_in == 1'b1) eval_cond = 1'b1;
			else eval_cond = 1'b0;	
		COND_GTU:		/* 0xd - BGTU */
			if (C_in == 1'b0 && Z_in == 1'b0) eval_cond = 1'b1;
			else eval_cond = 1'b0;	
		COND_A:		/* 0xe - BA, branch always */
			eval_cond = 1'b1;
		COND_L:		/* 0xf - BL, branch link */
			eval_cond = 1'b1; 	
		default:	
  			eval_cond = 1'b0;
	endcase
end
endfunction

function alu_cond_pass_from_ins;
input [31:0] instruction;
input Z;
input S; 
input C; 
input V;
begin
	alu_cond_pass_from_ins = eval_cond(instruction[19:16], Z, S, C, V);
end 
endfunction

function branch_taken_from_ins;
input [31:0] instruction;
input Z;
input S; 
input C; 
input V;
begin
	branch_taken_from_ins = eval_cond(instruction[27:24], Z, S, C, V);
end 
endfunction

function is_interrupt_enable_disable;
input [31:0] ins;
		is_interrupt_enable_disable = ins[0];	// 1 = enabled, 0 = disabled
endfunction


