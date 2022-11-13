/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 instruction decoder
 *
 */

localparam NOP_INSTRUCTION 		= {BITS{1'b0}};
localparam LINK_REGISTER   		= 8'd31;
localparam INTERRUPT_LINK_REGISTER   	= 8'd31;
localparam R0 				= {REGISTER_BITS{1'b0}};

localparam INSTRUCTION_CASEX_NOP			= NOP_INSTRUCTION;
localparam INSTRUCTION_CASEX_RET_IRET			= 32'h01xxxxxx;
localparam INSTRUCTION_CASEX_ALUOP_SINGLE_REG		= 32'h04xxxxxx;
localparam INSTRUCTION_CASEX_INTERRUPT			= 32'h05xxxxxx;
localparam INSTRUCTION_CASEX_INTERRUPT_EN		= 32'h06xxxxxx;
localparam INSTRUCTION_CASEX_SLEEP			= 32'h07xxxxxx;
localparam INSTRUCTION_CASEX_IMM			= 32'h1xxxxxxx;
localparam INSTRUCTION_CASEX_ALUOP_REG_REG		= 32'h2xxxxxxx;
localparam INSTRUCTION_CASEX_ALUOP_REG_IMM		= 32'h3xxxxxxx;
localparam INSTRUCTION_CASEX_BRANCH			= 32'h4xxxxxxx;
localparam INSTRUCTION_CASEX_COND_MOV			= 32'h5xxxxxxx;
localparam INSTRUCTION_CASEX_BYTE_HALFWORD_LOAD_STORE	= 32'h8xxxxxxx;
localparam INSTRUCTION_CASEX_TWO_REG_COND_ALU		= 32'h9xxxxxxx;
localparam INSTRUCTION_CASEX_LOAD			= 32'hcxxxxxxx;
localparam INSTRUCTION_CASEX_STORE			= 32'hdxxxxxxx;

