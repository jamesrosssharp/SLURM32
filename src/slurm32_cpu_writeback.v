/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 writeback stage
 *
 */

module slurm32_cpu_writeback #(parameter REGISTER_BITS = 8, BITS = 32, ADDRESS_BITS = 32)
(
	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 4 */
	input [BITS - 1:0] aluOut,
	input [BITS - 1:0] memory_in, 

	/* write back register select and data */
	output reg [REGISTER_BITS - 1:0] reg_wr_sel,
	output reg [BITS - 1:0] reg_out,

	input [ADDRESS_BITS - 1: 0] pc_stage4,
	input [3:0] memory_mask_delayed,

	input nop_stage4,	/* instruction in pipeline slot 4 is NOP'd out */

	input load_interrupt_return_address,

	/* conditional instruction passed in stage2 */
	input cond_pass

);

`include "slurm32_cpu_decode_functions.v"

always @(*)
begin
	reg_wr_sel = 8'd0;	// We can write anything we want to r0, as it always reads back as 32'd0.
	reg_out = aluOut;

	/* We are in interrupt state - there will be no write back of this instruction */
	if (load_interrupt_return_address)
	begin
		reg_wr_sel = INTERRUPT_LINK_REGISTER;
		reg_out = pc_stage4;
	end
	else if (! nop_stage4) begin
		casex (instruction)
			INSTRUCTION_CASEX_ALUOP_SINGLE_REG : begin /* alu op reg */
				reg_wr_sel 	= reg_src2_from_ins(instruction);
				reg_out 	= aluOut; 	
			end
			INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
				reg_wr_sel 	= reg_dest_from_ins(instruction);
				reg_out		= aluOut; 	
			end
			INSTRUCTION_CASEX_BRANCH: begin /* branch */
				if (is_branch_link_from_ins(instruction) == 1'b1) begin
					reg_wr_sel   = LINK_REGISTER; /* link register */
					reg_out	= {pc_stage4[ADDRESS_BITS - 1 : 2] + 30'd1, 2'b00};	// We link to PC + 4, as this is the instruction following the BL we just took
				end
			end
			INSTRUCTION_CASEX_TWO_REG_COND_ALU: begin
				if (cond_pass == 1'b1) begin
					/* write back to "src" register */
					reg_wr_sel = reg_src_from_ins(instruction);
					reg_out = aluOut;	
				end
			end
			/* TODO: Memory accesses here */
			default: ;
		endcase
	end
end

endmodule
