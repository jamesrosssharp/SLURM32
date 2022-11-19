/*
 *	(C) 2022 J. R. Sharp
 *
 * 	See LICENSE for software license details
 *
 *	SLURM32 pipeline
 *
 */

module slurm32_cpu_pipeline #(
	parameter BITS = 32,
	parameter ADDRESS_BITS = 32,
	parameter REGISTER_BITS = 8
) (
	input CLK,
	input RSTb,

	/* Instruction input */
	output reg 	instruction_request,	/* asserted if the pipeline is fetching instructions */
	input 		instruction_valid,	/* asserted if the instruction requested was fetched from memory. deasserted on e.g. cache miss */
	output reg [ADDRESS_BITS - 1 : 0] 	instruction_address, /* the address to fetch the next instruction from */
	input  [BITS - 1 : 0] 	instruction_in,

	/* Pipeline stage output */
	output [BITS - 1 : 0]	pipeline_stage_0,
	output [BITS - 1 : 0]	pipeline_stage_1,
	output [BITS - 1 : 0]	pipeline_stage_2,
	output [BITS - 1 : 0]	pipeline_stage_3,
	output [BITS - 1 : 0]	pipeline_stage_4,
 
	output [ADDRESS_BITS - 1 : 0] pc_stage_4,

	/* Control signals */

	input halt_request,		/* Sleep instruction requests CPU halt */

	input interrupt,		/* Interrupt request from interrupt controller */
	input [3:0] irq,		/* IRQ from interrupt controller */ 

	input load_pc_request,		/* Branch instruction */
	input [ADDRESS_BITS - 1 : 0] load_pc_address,

	input interrupt_flag_clear,
	input interrupt_flag_set,

	input memory_request_successful,	/* Memory request was successful. This means that an instruction in
						   pipeline stage 3 issued a memory request. For a load, this means
						   that memory data is available for writeback. For a store, this means
						   that the data write will be committed on the next cycle */


	/* Debugger interface */

	input debugger_halt_request,	/* Debugger requests CPU halt */
	input debugger_load_pc_request, /* Debugger load PC */
	input [ADDRESS_BITS - 1 : 0] debugger_load_pc_address

);

`include "slurm32_cpu_defs.v"

/* Pipeline state vectors */

reg [BITS - 1 : 0] pipeline_stage0_r;
reg [BITS - 1 : 0] pipeline_stage1_r;
reg [BITS - 1 : 0] pipeline_stage2_r;
reg [BITS - 1 : 0] pipeline_stage3_r;
reg [BITS - 1 : 0] pipeline_stage4_r;

reg [ADDRESS_BITS - 3 : 0] pc_stage0_r;	// PC is only 30 bits wide, as we ignore the lowest two bits and force alignment
reg [ADDRESS_BITS - 3 : 0] pc_stage1_r;
reg [ADDRESS_BITS - 3 : 0] pc_stage2_r;
reg [ADDRESS_BITS - 3 : 0] pc_stage3_r;
reg [ADDRESS_BITS - 3 : 0] pc_stage4_r;

reg interrupt_flag_r = 1'b1;

reg [ADDRESS_BITS - 3 : 0] pc_r;
reg [ADDRESS_BITS - 3 : 0] prev_pc_r;
 

/*
 *	Combinational logic
 *
 */

wire stage4_is_memory = (pipeline_stage4_r[31:28] == 4'h8) || (pipeline_stage4_r[31:28] == 4'hc) || (pipeline_stage4_r[31:28] == 4'hd);
wire mem_exception = stage4_is_memory && !memory_request_successful; 


/*	
 *	Pipeline state machine 		
 *
 *	
 *
 */

localparam st_reset 	= 4'd0;
localparam st_halt 	= 4'd1;
localparam st_execute 	= 4'd2;
localparam st_interrupt = 4'd3;
localparam st_stall1	= 4'd4;
localparam st_stall2    = 4'd5;
localparam st_stall3    = 4'd6;
localparam st_ins_stall1 = 4'd7;
localparam st_ins_stall2 = 4'd8;
localparam st_mem_except = 4'd9;

reg [3:0] state_r;
reg [3:0] return_state_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state_r <= st_reset;
		return_state_r <= st_execute;
	end
	else begin

		case (state_r)
			st_reset: begin
				state_r <= st_execute;
				return_state_r <= st_execute;
			end
			st_halt: begin
				return_state_r <= st_halt;
				if (interrupt)
					state_r <= st_execute;
			end
			st_execute: begin
				return_state_r <= st_execute;
				// Add check here to see if instruction in slot0 is an IMM instruction
				// to keep the pair atomic 
				if (mem_exception)				
					state_r <= st_mem_except;
				else if (interrupt && interrupt_flag_r)
					state_r <= st_interrupt;
				else if (instruction_valid == 1'b0)
					state_r <= st_ins_stall1;
				//else if (some_hazard)
				//	state_r <= st_stall1;
				else if (halt_request || debugger_halt_request)
					state_r <= st_halt; 
			end
			st_interrupt: begin
				return_state_r <= st_interrupt;
		
				if (mem_exception)
					state_r <= st_mem_except;
				else if (interrupt_flag_r == 1'b0)	// Interrupt flag cleared
					state_r <= st_execute;
			end
			st_stall1: begin
				return_state_r <= st_execute;
				if (mem_exception)
					state_r <= st_mem_except;
				else
					state_r <= st_stall2;
			end
			st_stall2: begin
				return_state_r <= st_execute;
				if (mem_exception)
					state_r <= st_mem_except;
				else
					state_r <= st_stall3;
			end
			st_stall3: begin
				return_state_r <= st_execute;
				if (mem_exception)
					state_r <= st_mem_except;
				else
					state_r <= st_execute;
			end
			st_ins_stall1: begin	// This is a wait state while PC is rewound to previous value

				if (mem_exception)
					state_r <= st_mem_except;
				else
					state_r <= st_ins_stall2;
				return_state_r <= st_execute;

			end
			st_ins_stall2: begin
				return_state_r <= st_execute;
				
				if (mem_exception)
					state_r <= st_mem_except;
				else if (instruction_valid == 1'b1)
					state_r <= st_execute;
			end
			st_mem_except:	 /* we clear pipeline in this state and get ready to refetch from failing instruction */
				state_r <= return_state_r;
			default:
				state_r <= st_reset;			

		endcase

	end	

end


/*
 *
 *	PC
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pc_r <= {(ADDRESS_BITS - 3){1'b0}};
			prev_pc_r <= {(ADDRESS_BITS - 3){1'b0}};
		end
		st_halt:	;
		st_execute: begin
			if (mem_exception) begin
				pc_r <= pc_stage4_r;
				prev_pc_r <= pc_stage4_r;
			end else begin
				pc_r <= pc_r + 1;
				prev_pc_r <= pc_r;
			end
		end
		st_interrupt:	
			if (mem_exception) begin
				pc_r <= pc_stage4_r;
				prev_pc_r <= pc_stage4_r;	
			end
		st_stall1, st_stall2, st_stall3, st_ins_stall1:
			if (mem_exception) begin
				pc_r <= pc_stage4_r;
				prev_pc_r <= pc_stage4_r;
			end else
				pc_r <= prev_pc_r;
		st_ins_stall2:;
		st_mem_except:;
		default:;
	endcase
end

/*
 *
 *	Pipeline stage 0
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pipeline_stage0_r <= NOP_INSTRUCTION;
			pc_stage0_r <= {ADDRESS_BITS{1'b0}};
		end
		st_halt:;
		st_ins_stall2, st_execute: begin
			if (instruction_valid)
				pipeline_stage0_r <= instruction_in; 
			else
				pipeline_stage0_r <= NOP_INSTRUCTION;
			pc_stage0_r <= pc_r;
		end
		st_interrupt:
			// Emit interrupt instruction
			pipeline_stage0_r <= {28'h0500000, irq};  
		st_stall1, st_stall2, st_stall3, st_ins_stall1, st_mem_except:
			pipeline_stage0_r <= NOP_INSTRUCTION;
			
		default:	;
	endcase

end

/*
 *
 *	Pipeline stage 1
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pipeline_stage1_r <= NOP_INSTRUCTION;	
			pc_stage1_r <= {ADDRESS_BITS{1'b0}};
		end
		st_ins_stall2, st_ins_stall1, st_interrupt, st_execute: begin
			pipeline_stage1_r <= pipeline_stage0_r;
			pc_stage1_r <= pc_stage0_r;
		end
		st_halt, st_stall1, st_stall2, st_stall3: ;
		st_mem_except:
			pipeline_stage1_r <= NOP_INSTRUCTION;
		default:;
	endcase
end

/*
 *
 *	Pipeline stage 2
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pipeline_stage2_r <= NOP_INSTRUCTION;
			pc_stage2_r <= {ADDRESS_BITS{1'b0}};
		end
		st_ins_stall2, st_ins_stall1, st_interrupt, st_execute: begin
			pipeline_stage2_r <= pipeline_stage1_r;
			pc_stage2_r <= pc_stage1_r;
		end
		st_stall1, st_stall2, st_stall3: begin
			pipeline_stage2_r <= NOP_INSTRUCTION;
			pc_stage2_r <= pc_stage1_r;
		end
		st_halt:;
		st_mem_except:
			pipeline_stage2_r <= NOP_INSTRUCTION;
		default:;
	endcase
end

/*
 *
 *	Pipeline stage 3
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pipeline_stage3_r <= NOP_INSTRUCTION;
			pc_stage3_r <= {ADDRESS_BITS{1'b0}};
		end
		st_stall1, st_stall2, st_stall3, st_ins_stall2, st_ins_stall1, st_interrupt, st_execute: begin
			pipeline_stage3_r <= pipeline_stage2_r;
			pc_stage3_r <= pc_stage2_r;
		end
		st_halt:;
		st_mem_except:
			pipeline_stage3_r <= NOP_INSTRUCTION;
		default:;
	endcase
end

/*
 *
 *	Pipeline stage 4
 *
 */

always @(posedge CLK)
begin
	case (state_r)
		st_reset: begin
			pipeline_stage4_r <= NOP_INSTRUCTION;
			pc_stage4_r <= {ADDRESS_BITS{1'b0}};
		end
		st_stall1, st_stall2, st_stall3, st_ins_stall2, st_ins_stall1, st_interrupt, st_execute: begin
			pipeline_stage4_r <= pipeline_stage3_r;
			pc_stage4_r <= pc_stage3_r;
		end
		st_halt:;
		st_mem_except:
			pipeline_stage4_r <= NOP_INSTRUCTION;
		default:;
	endcase
end

/* interrupt flag */

always @(posedge CLK)
begin
	if (RSTb == 1'b0)
		interrupt_flag_r <= 1'b0;
	else if (interrupt_flag_set == 1'b1)
		interrupt_flag_r <= 1'b1;
	else if (interrupt_flag_clear == 1'b1)
		interrupt_flag_r <= 1'b0;
end

/* 
 *
 * Debug decoding of states
 *
 */

`ifdef SIM

reg [63:0] ascii_state;

always @(*)
begin
	case (state_r)
		st_reset:
			ascii_state = "reset";
		st_halt:
			ascii_state = "halt";
		st_execute:
			ascii_state = "exec";
		st_interrupt:
			ascii_state = "intrp";
		st_stall1:
			ascii_state = "stall1";
		st_stall2:
			ascii_state = "stall2";
		st_stall3: 
			ascii_state = "stall3";
		st_ins_stall1: 
			ascii_state = "istall1";
		st_ins_stall2:
			ascii_state = "istall2";
		st_mem_except:
			ascii_state = "memexcpt";
	endcase
end


`include "slurm32_debug_functions.v"

reg [63:0] ascii_instruction0;
reg [63:0] ascii_instruction1;
reg [63:0] ascii_instruction2;
reg [63:0] ascii_instruction3;
reg [63:0] ascii_instruction4;

always @(*)
begin
	ascii_instruction0 = disassemble(pipeline_stage0_r);
	ascii_instruction1 = disassemble(pipeline_stage1_r);
	ascii_instruction2 = disassemble(pipeline_stage2_r);
	ascii_instruction3 = disassemble(pipeline_stage3_r);
	ascii_instruction4 = disassemble(pipeline_stage4_r);
end

`endif

endmodule
