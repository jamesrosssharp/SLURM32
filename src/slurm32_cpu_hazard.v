/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 hazard detection
 *
 */

module slurm32_cpu_hazard #(parameter BITS = 32, REGISTER_BITS = 8)
(
        input [BITS - 1:0] instruction, /* p0 pipeline slot instruction*/

        input [REGISTER_BITS - 1:0] regA_sel0,          /* registers that pipeline0 instruction will read from */
        input [REGISTER_BITS - 1:0] regB_sel0,

        output reg[REGISTER_BITS - 1:0] hazard_reg0 = {REGISTER_BITS{1'b0}},    /*  export hazard computation, it will move with pipeline in pipeline module */
        output reg modifies_flags0 = 1'b0,                     /*  export flag hazard conditions */

        input [REGISTER_BITS - 1:0] hazard_reg1,        /* import pipelined hazards */
        input [REGISTER_BITS - 1:0] hazard_reg2,
        input [REGISTER_BITS - 1:0] hazard_reg3,
        input modifies_flags1,
        input modifies_flags2,
        input modifies_flags3,

        output reg hazard_1,
        output reg hazard_2,
        output reg hazard_3
);

`include "slurm32_cpu_decode_functions.v"

// Determine hazard registers to propagate from p0

always @(*)
begin

        hazard_reg0 = {REGISTER_BITS{1'b0}};

        /* verilator lint_off CASEX */
        casex (instruction)
                INSTRUCTION_CASEX_ALUOP_SINGLE_REG : begin /* alu op reg */
                        hazard_reg0   = reg_src_from_ins(instruction); // source is destination in this case
                end
                INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM: begin /* alu op */
                        case (alu_op_from_ins(instruction))
                                ALU5_CMP, ALU5_TST: ;	/* these do not modify the register, so no hazard */
                                default:
                                        hazard_reg0   = reg_dest_from_ins(instruction);
                        endcase
                end
                INSTRUCTION_CASEX_BRANCH: begin /* branch */
                        if (is_branch_link_from_ins(instruction) == 1'b1) begin
                                hazard_reg0   = LINK_REGISTER; /* link register */
                        end
                end
                INSTRUCTION_CASEX_TWO_REG_COND_ALU: begin
			/* two reg cond alu uses src and src2 registers, and writes back to src */
                        hazard_reg0   = reg_src_from_ins(instruction);
                end
		default: ;
        endcase
end

// Determine flag hazards to propagate

always @(*)
begin

	modifies_flags0 = 1'b0;

	casex (instruction)
		/* TODO: Finer grained determination of hazards here - mov shouldn't cause a hazard */
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG,
		INSTRUCTION_CASEX_ALUOP_REG_REG, INSTRUCTION_CASEX_ALUOP_REG_IMM,
		INSTRUCTION_CASEX_TWO_REG_COND_ALU : begin /* alu op */
			modifies_flags0 = 1'b1;
		end
		default: ;
	endcase
end

// Compute if a hazard occurs

always @(*)
begin
	hazard_1 = 1'b0;
	hazard_2 = 1'b0;
	hazard_3 = 1'b0;

	/* register hazards */
	if (regA_sel0 != R0) begin
		if (regA_sel0 == hazard_reg1)
			hazard_1 = 1'b1;
		if (regA_sel0 == hazard_reg2)
			hazard_2 = 1'b1;
		if (regA_sel0 == hazard_reg3)
			hazard_3 = 1'b1;
	end

	if (regB_sel0 != R0) begin
		if (regB_sel0 == hazard_reg1)
			hazard_1 = 1'b1;
		if (regB_sel0 == hazard_reg2)
			hazard_2 = 1'b1;
		if (regB_sel0 == hazard_reg3)
			hazard_3 = 1'b1;
	end

	/* Flag hazard */
	casex(instruction)
		INSTRUCTION_CASEX_BRANCH: begin /* branch */
			if (uses_flags_for_branch(instruction)) begin
				if (modifies_flags1) hazard_1 = 1'b1;
				if (modifies_flags2) hazard_2 = 1'b1;
				if (modifies_flags3) hazard_3 = 1'b1;
			end
		end
		INSTRUCTION_CASEX_TWO_REG_COND_ALU: begin
			if (modifies_flags1) hazard_1 = 1'b1;
			if (modifies_flags2) hazard_2 = 1'b1;
			if (modifies_flags3) hazard_3 = 1'b1;
		end
		default: ;
	endcase
end

endmodule
