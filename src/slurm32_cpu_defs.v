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

localparam IRET_INSTRUCTION		= 32'h01000001;

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

// Conditionals

localparam COND_EQ  = 4'b0000;	/* 0 - Equal */
localparam COND_Z   = 4'b0000;  /* 0 - Zero */
localparam COND_NZ  = 4'b0001;	/* 1 - Not-Zero */
localparam COND_NE  = 4'b0001;	/* 1 - Not-equal */
localparam COND_S   = 4'b0010;	/* 2 - Sign */
localparam COND_NS  = 4'b0011;  /* 3 - Not-sign */
localparam COND_C   = 4'b0100;  /* 4 - Carry set */
localparam COND_LTU = 4'b0100;  /* 4 - Less-than, unsigned */
localparam COND_NC  = 4'b0101;	/* 5 - Carry not set */
localparam COND_GEU = 4'b0101;  /* 5 - Greater-than or equal, unsigned */
localparam COND_V   = 4'b0110;  /* 6 - Signed Overflow */ 
localparam COND_NV  = 4'b0111;  /* 7 - No signed overflow */	
localparam COND_LT  = 4'b1000;  /* 8 - signed less than */
localparam COND_LE  = 4'b1001;  /* 9 - signed less than or equal */	
localparam COND_GT  = 4'b1010;  /* 10 - signed greater than */
localparam COND_GE  = 4'b1011;  /* 11 - signed greater than or equal */
localparam COND_LEU = 4'b1100;  /* 12 - less than or equal unsigned */
localparam COND_GTU = 4'b1101;  /* 13 - greater than unsigned */
localparam COND_A   = 4'b1110;  /* 14 - always pass */
localparam COND_L   = 4'b1111;  /* 15 - link (for branch and link) */	

// ALU Operations

localparam ALU5_MOV  = 5'd0; /* move - pass B (source) through to register file */
localparam ALU5_ADD  = 5'd1; /* add */
localparam ALU5_ADC  = 5'd2; /* adc */	
localparam ALU5_SUB  = 5'd3; /* sub */
localparam ALU5_SBB  = 5'd4; /* sbb */
localparam ALU5_AND  = 5'd5; /* and */
localparam ALU5_OR   = 5'd6; /* or */
localparam ALU5_XOR  = 5'd7; /* xor */	
localparam ALU5_MUL  = 5'd8; /* mul */	
localparam ALU5_MULU = 5'd9; /* mulu */

	// These two are carry over from slurm16 and should probably be replaced with a barrel shifter
localparam ALU5_RRN  = 5'd10; /* rrn */
localparam ALU5_RLN  = 5'd11; /* rln */

localparam ALU5_CMP  = 5'd12; /* cmp */
localparam ALU5_TST  = 5'd13; /* test */
localparam ALU5_UMULU = 5'd14; /* umulu - unsigned multiply upper */

	// This one is a carry over from SLURM16 and could be repurposed 
localparam ALU5_BSWAP = 5'd15;

localparam ALU5_ASR = 5'd16; /* asr */
localparam ALU5_LSR = 5'd17; /* lsr */
localparam ALU5_LSL = 5'd18; /* lsl */
localparam ALU5_ROLC = 5'd19; /* rolc */
localparam ALU5_RORC = 5'd20; /* rorc */
localparam ALU5_ROL  = 5'd21; /* rol */
localparam ALU5_ROR  = 5'd22; /* ror */
localparam ALU5_CC   = 5'd23; /* clear carry */
localparam ALU5_SC   = 5'd24; /* set carry */
localparam ALU5_CZ   = 5'd25; /* clear zero */
localparam ALU5_SZ   = 5'd26; /* set zero */
localparam ALU5_CS   = 5'd27; /* clear sign */
localparam ALU5_SS   = 5'd28; /* set sign */
localparam ALU5_STF  = 5'd29; /* store flags */
localparam ALU5_RSF  = 5'd30; /* restore flags */

