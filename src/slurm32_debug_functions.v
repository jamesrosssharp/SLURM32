/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	debug functions
 *
 */

function [63:0] disassemble;
input [31:0] ins;
begin
	casex (ins)
		INSTRUCTION_CASEX_NOP:
			disassemble = "nop"; 
		INSTRUCTION_CASEX_RET_IRET:
			case (ins[0])
				1'b0:
					disassemble = "ret";
				1'b1:			
					disassemble = "iret";		
			endcase
		INSTRUCTION_CASEX_ALUOP_SINGLE_REG:
			case (ins[11:8])
				4'd0: 
					disassemble = "asr";
				4'd1:
					disassemble = "lsr";
				4'd2:
					disassemble = "lsl";
				4'd3:
					disassemble = "rolc";
				4'd4:
					disassemble = "rorc";
				4'd5:
					disassemble = "rol";
				4'd6:
					disassemble = "ror";
				4'd7:
					disassemble = "cc";
				4'd8:
					disassemble = "sc";
				4'd9:
					disassemble = "cz";			
				4'd10:
					disassemble = "sz";
				4'd11:
					disassemble = "cs";
				4'd12:
					disassemble = "ss";
				4'd13:
					disassemble = "stf";
				4'd14:
					disassemble = "rsf";
				4'd15:
					disassemble = "?";
			endcase
		INSTRUCTION_CASEX_INTERRUPT:
			disassemble = "int";
		INSTRUCTION_CASEX_INTERRUPT_EN:
			case (ins[0])
				1'b0:
					disassemble = "cli";
				1'b1:
					disassemble = "sti";
			endcase 
		INSTRUCTION_CASEX_SLEEP:
			disassemble = "sleep";
		INSTRUCTION_CASEX_IMM:
			disassemble = "imm";
		INSTRUCTION_CASEX_ALUOP_REG_REG,
		INSTRUCTION_CASEX_ALUOP_REG_IMM:
			case (ins[27:24])
				4'd0: 
					disassemble = "mov";
				4'd1:
					disassemble = "add";
				4'd2:
					disassemble = "adc";
				4'd3:
					disassemble = "sub";
				4'd4:
					disassemble = "sbb";
				4'd5:
					disassemble = "and";
				4'd6:
					disassemble = "or";
				4'd7:
					disassemble = "xor";
				4'd8:
					disassemble = "mul";
				4'd9:
					disassemble = "mulu";			
				4'd10:
					disassemble = "rrn";
				4'd11:
					disassemble = "rln";
				4'd12:
					disassemble = "cmp";
				4'd13:
					disassemble = "test";
				4'd14:
					disassemble = "umulu";
				4'd15:
					disassemble = "bswap";
			endcase
		INSTRUCTION_CASEX_BRANCH:;
		INSTRUCTION_CASEX_COND_MOV:;
		INSTRUCTION_CASEX_BYTE_HALFWORD_LOAD_STORE:;
		INSTRUCTION_CASEX_TWO_REG_COND_ALU:;
		INSTRUCTION_CASEX_LOAD:;
		INSTRUCTION_CASEX_STORE:;
	endcase
end
endfunction
