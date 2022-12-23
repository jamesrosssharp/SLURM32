/*
 *	Execute pipeline stage: execute instruction (alu, branch, load / store)
 *	
 *
 */

module slurm32_cpu_execute #(parameter REGISTER_BITS = 4, BITS = 32, ADDRESS_BITS = 32)
(
	input CLK,
	input RSTb,

	input [BITS - 1:0] instruction,		/* instruction in pipeline slot 2 */

	input instruction_is_nop,

	/* flags (for branches) */

	input Z,
	input C,
	input S,
	input V,

	/* registers in from decode stage */
	input [BITS - 1:0] regA,
	input [BITS - 1:0] regB,

	/* immediate register */
	input [23:0] imm_reg,

	/* memory op */
	output load_memory,
	output store_memory,
	output [ADDRESS_BITS - 3:0] load_store_address, // -- this should probably be an aligned address
	output [BITS - 1:0] memory_out,
	output [3:0] memory_mask,

	/* alu op */
	output reg [4:0] aluOp,
	output reg [BITS - 1:0] aluA,
	output reg [BITS - 1:0] aluB,

	/* load PC for branch / (i)ret, etc */
	output reg load_pc,
	output reg [ADDRESS_BITS - 1:0] new_pc,

	output reg interrupt_flag_set,
	output reg interrupt_flag_clear,

	output reg halt,

	output reg cond_pass = 1'b0

);



`include "slurm32_cpu_decode_functions.v"

reg [4:0] aluOp_next;
reg [BITS - 1:0] aluA_next;
reg [BITS - 1:0] aluB_next;

/* sequential logic */

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		aluOp <= 5'd0;
		aluA <= {BITS{1'b0}};
		aluB <= {BITS{1'b0}};
	end else begin
		aluOp <= aluOp_next;
		aluA <= aluA_next;
		aluB <= aluB_next;
	end
end

/* combinational logic */

/* determine ALU operation */

always @(*)
begin

	cond_pass = 1'b0;
	
	aluA_next = regA;
	aluB_next = regB;
	aluOp_next = 5'd0; /* mov - noop */
	
	if (!instruction_is_nop)
		casex (instruction)
			INSTRUCTION_CASEX_ALUOP_SINGLE_REG:	begin /* alu op, reg */
				aluOp_next 	= single_reg_alu_op_from_ins(instruction);
			end
			INSTRUCTION_CASEX_ALUOP_REG_REG:   begin /* alu op, reg reg */
				aluOp_next 	= alu_op_from_ins(instruction);
			end
			INSTRUCTION_CASEX_ALUOP_REG_IMM:	begin	/* alu op, reg imm */
				aluB_next 	= {imm_reg, instruction[7:0]};
				aluOp_next 	= alu_op_from_ins(instruction);
			end
			INSTRUCTION_CASEX_TWO_REG_COND_ALU:	begin /* 3 reg alu op */
				
				if (alu_cond_pass_from_ins(instruction, Z, S, C, V) == 1'b1) begin
					aluOp_next 	= alu_op_from_ins(instruction);
					cond_pass = 1'b1;
				end
			end
			default: ;
		endcase
end

/* determine branch */

always @(*)
begin
	load_pc = 1'b0;
	new_pc = {ADDRESS_BITS{1'b0}};

	if (!instruction_is_nop)
		casex(instruction)
			INSTRUCTION_CASEX_BRANCH: begin
				if (branch_taken_from_ins(instruction, Z, S, C, V) == 1'b1) begin
						new_pc = regA + imm_reg;
						load_pc = 1'b1;
				end
			end
			INSTRUCTION_CASEX_RET_IRET: begin
				new_pc = regA;
				load_pc = 1'b1;
			end
		endcase
end

/* TODO : Memory access */

assign load_memory = 1'b0;
assign store_memory = 1'b0;
/* determine interrupt flag set / clear */

always @(*)
begin
	interrupt_flag_set = 1'b0;
	interrupt_flag_clear = 1'b0;

	if (! instruction_is_nop)
		casex (instruction) 
			INSTRUCTION_CASEX_INTERRUPT_EN: begin
				if (is_interrupt_enable_disable(instruction) == 1'b0)
					interrupt_flag_clear = 1'b1;
				else 
					interrupt_flag_set = 1'b1;
			end
			INSTRUCTION_CASEX_RET_IRET:	begin	/* iret? */
				if (is_ret_or_iret(instruction) == 1'b1)
					interrupt_flag_set = 1'b1; // set on iret
			end
			INSTRUCTION_CASEX_SLEEP: begin
				interrupt_flag_set = 1'b1;
			end
			INSTRUCTION_CASEX_INTERRUPT: begin
				interrupt_flag_clear = 1'b1;
			end
			default: ;
		endcase
end

/* sleep ? */

always @(*)
begin
	halt = 1'b0;

	if (! instruction_is_nop)
		casex(instruction)
			INSTRUCTION_CASEX_SLEEP: begin
				halt = 1'b1;	
			end
		endcase
end

endmodule
