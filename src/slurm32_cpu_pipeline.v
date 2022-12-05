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

localparam INS_BITS = 32;
localparam NOP_BITS = 1;
localparam PC_BITS  = 30;
localparam IMM_BITS = 24;
localparam HAZ_REG_BITS = 8;
localparam HAZ_FLAG_BITS = 1;
localparam TOTAL_PIPELINE_SV_BITS = INS_BITS + NOP_BITS + PC_BITS + IMM_BITS + HAZ_REG_BITS + HAZ_FLAG_BITS;


/*
 *	Pipeline stage state vector:
 *
 * 	|    95    | 94 - 87  | 86 - 63 | 62 - 33 | 32 - 1 |  0  |
 *	----------------------------------------------------------
 *	| HAZ FLAG |  HAZ REG |  IMM    |  PC     |  INS   | NOP |
 */

localparam NOP_BIT = 0;
localparam INS_LSB = 1;
localparam INS_MSB = 32;
localparam PC_LSB  = 33;
localparam PC_MSB  = 62;
localparam IMM_LSB = 63;
localparam IMM_MSB = 86;
localparam HAZ_REG_LSB = 87;
localparam HAZ_REG_MSB = 94;
localparam HAZ_FLAG_BIT = 95;

reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip0;	// Fetch
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip1;	// Decode
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip2;	// Execute
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip3;	// Mem req.
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip4;	// Write back
reg [TOTAL_PIPELINE_SV_BITS - 1:0] pip5;	// Final


assign pipeline_stage_0 = pip0[INS_MSB : INS_LSB];
assign pipeline_stage_1 = pip1[INS_MSB : INS_LSB];
assign pipeline_stage_2 = pip2[INS_MSB : INS_LSB];
assign pipeline_stage_3 = pip3[INS_MSB : INS_LSB];
assign pipeline_stage_4 = pip4[INS_MSB : INS_LSB];

assign pc_stage_4 = pip4[PC_MSB : PC_LSB];

reg interrupt_flag_r = 1'b1;

reg [ADDRESS_BITS - 3 : 0] pc_r;
reg [ADDRESS_BITS - 3 : 0] prev_pc_r;

/*
 *	Combinational logic
 *
 */

wire stage4_is_memory = (pip4[INS_MSB:INS_MSB - 4] == 4'h8) || (pip4[INS_MSB:INS_MSB - 4] == 4'hc) || (pip4[INS_MSB:INS_MSB - 4] == 4'hd);
wire mem_exception = stage4_is_memory && !memory_request_successful && !pip4[NOP_BIT]; 


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
localparam st_mem_except1 = 4'd9;
localparam st_mem_except2 = 4'd9;


reg [3:0] state_r;

always @(posedge CLK)
begin
	if (RSTb == 1'b0) begin
		state_r <= st_reset;
	end
	else begin

		case (state_r)
			st_reset: begin
				state_r <= st_execute;
			end
			st_halt: begin

				/*
				 *	We could have a memory exception when entering halt.
				 *	We will ignore this corner case and make sure that we
				 *	are not performing any memory accesses before a halt.
				 *
				 *	Do we need a memory barrier instruction?
				 *
				 */ 

				if (interrupt)
					state_r <= st_execute;
			end
			st_execute: begin
				if (mem_exception)				
					state_r <= st_mem_except1;
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
		
			end
			st_stall1: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else
					state_r <= st_stall2;
			end
			st_stall2: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else
					state_r <= st_stall3;
			end
			st_stall3: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else
					state_r <= st_execute;
			end
			st_ins_stall1: begin	// This is a wait state while PC is rewound to previous value
				if (mem_exception)
					state_r <= st_mem_except1;
				else
					state_r <= st_ins_stall2;
			end
			st_ins_stall2: begin
				if (mem_exception)
					state_r <= st_mem_except1;
				else if (instruction_valid == 1'b1)
					state_r <= st_execute;
			end
			st_mem_except1:	 /* we clear pipeline in this state and get ready to refetch from failing instruction */
				state_r <= st_mem_except2;
			st_mem_except2:
				state_r <= st_execute;
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
			pc_r <= pc_r + 1;
			prev_pc_r <= pc_r;
		end
		st_interrupt:	;
		

		st_stall1, st_stall2, st_stall3, st_ins_stall1:
				pc_r <= prev_pc_r;
		st_ins_stall2:;
		st_mem_except1:;
		st_mem_except2:;
		default:;
	endcase
end

/*
 *
 *	Pipeline stage 0 (fetch)
 *
 */

always @(posedge CLK)
begin

	pip0[INS_MSB : INS_LSB] 	<= instruction_in;
	pip0[PC_MSB : PC_LSB] 		<= pc_r;
	pip0[IMM_MSB : IMM_LSB] 	<= 24'h000000;
	pip0[HAZ_REG_MSB : HAZ_REG_LSB] <= 8'h00;
	pip0[HAZ_FLAG_BIT] 		<= 1'b0;

	// We nop out pip0 in every state except execute
	case (state_r)
		st_reset, st_halt, st_stall1, st_stall2, st_stall3, st_ins_stall1, st_mem_except1, st_mem_except2, st_interrupt, st_ins_stall2:
			pip0[NOP_BIT] <= 1'b1;
		default:
			pip0[NOP_BIT] <= 1'b0;	
	endcase

end

/*
 *
 *	Pipeline stage 1 (decode)
 *
 */

always @(posedge CLK)
begin

	// In every state except st_stall{x} we advance pip1
	case (state_r)
		st_stall1, st_stall2, st_stall3:	;	// Hold instruction in the slot
		default:
			pip1[PC_MSB : INS_LSB] <= pip0[PC_MSB : INS_LSB];
	endcase

	// TODO: Fill in hazard bits and imm register
	pip1[HAZ_FLAG_BIT : IMM_LSB] <= {(IMM_BITS + HAZ_REG_BITS + HAZ_FLAG_BITS){1'b0}};

	// We nop out pip1 in st_reset, st_halt, st_interrupt, st_mem_except1
	case (state_r)
		st_reset, st_halt, st_interrupt, st_mem_except1:
			pip1[NOP_BIT] <= 1'b1;
		default:
			pip1[NOP_BIT] <= pip0[NOP_BIT];
	endcase
end

/*
 *
 *	Pipeline stage 2 (execute)
 *
 */

always @(posedge CLK)
begin

	pip2[HAZ_FLAG_BIT : INS_LSB] <= pip1[HAZ_FLAG_BIT : INS_LSB];

	// Nop out instruction in st_reset, st_halt, st_interrupt, st_mem_except1, st_stall{x}
	case (state_r)
		st_reset, st_halt, st_interrupt, st_mem_except1, st_stall1, st_stall2, st_stall3:
			pip2[NOP_BIT] <= 1'b1;
		default:
			pip2[NOP_BIT] <= pip1[NOP_BIT];
	endcase
end

/*
 *
 *	Pipeline stage 3 (memory request)
 *
 */

always @(posedge CLK)
begin

	pip3[HAZ_FLAG_BIT : INS_LSB] <= pip2[HAZ_FLAG_BIT : INS_LSB];

	// Nop out instruction in st_reset, st_interrupt, st_mem_except1
	case (state_r)
		st_reset, st_interrupt, st_mem_except1:
			pip3[NOP_BIT] <= 1'b1;
		default:
			pip3[NOP_BIT] <= pip2[NOP_BIT];
	endcase
end

/*
 *
 *	Pipeline stage 4 (writeback)
 *
 */

always @(posedge CLK)
begin
	pip4[HAZ_FLAG_BIT : INS_LSB] <= pip3[HAZ_FLAG_BIT : INS_LSB];

	// Nop out instruction in st_reset, st_interrupt, st_mem_except1
	case (state_r)
		st_reset, st_interrupt, st_mem_except1:
			pip4[NOP_BIT] <= 1'b1;
		default:
			pip4[NOP_BIT] <= pip3[NOP_BIT];
	endcase

end

/*
 *
 *	Pipeline stage 5  (final)
 *
 */
always @(posedge CLK)
begin
	pip5 <= pip4;
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
		st_mem_except1:
			ascii_state = "mexcpt1";
		st_mem_except2:
			ascii_state = "mexcpt2";
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
	if (pip0[NOP_BIT])
		ascii_instruction0 = "*nop";
	else
		ascii_instruction0 = disassemble(pip0[INS_MSB:INS_LSB]);

	if (pip1[NOP_BIT])
		ascii_instruction1 = "*nop";
	else
		ascii_instruction1 = disassemble(pip1[INS_MSB:INS_LSB]);

	if (pip2[NOP_BIT])
		ascii_instruction2 = "*nop";
	else
		ascii_instruction2 = disassemble(pip2[INS_MSB:INS_LSB]);
	
	if (pip3[NOP_BIT])
		ascii_instruction3 = "*nop";
	else
		ascii_instruction3 = disassemble(pip3[INS_MSB:INS_LSB]);
		
	if (pip4[NOP_BIT])
		ascii_instruction4 = "*nop";
	else
		ascii_instruction4 = disassemble(pip4[INS_MSB:INS_LSB]);

end

`endif

endmodule
