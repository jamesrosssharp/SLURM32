SLURM32 Instruction Set
========================

All instructions are 32 bits wide. Instructions are separated into "classes", with the "class" given by the most significant nibble. 

256 Registers. r31 - r0 used by C compiler.

r0 = always 0
r31 = link register
r30 = interrupt link register
r29 = stack pointer

Class 0: General purpose
------------------------

Class 0 has 7 sub-classes, bits 27 - 24 of the opcode.

0. NOP - No operation

   | 31 - 28 | 27 - 24 | 23 - 0  |
   |---------|---------|---------|
   |   0x0   |  0x0    |    0    |


1. Return instructions

   | 31 - 28 | 27 - 24 | 23 -  1 | 0  |
   |---------|---------|---------|----|
   |   0x0   |  0x1    |    x    | RT |


        RT : 0 = RET (return) (restore PC from link register and branch)
             1 = IRET (interrupt return) (restore PC from interrupt link register and branch)

2. Reserved 

3. Reserved

4. Single register ALU operation

   | 31 - 28 | 27 - 24 | 23 -  12 | 11 - 8 | 7 - 0  |
   |---------|---------|----------|--------|--------|
   |   0x0   |  0x4    |    x     | ALU OP |  REG   |


        ALU OP:
        ALU Op is 5 bits, with MSB set to 1

        16 - asr : arithmetic shift right REG
        17 - lsr : logical shift right REG
        18 - lsl : logical shift left REG
        19 - rolc
        20 - rorc
        21 - rol
        22 - ror
        23 - cc : clear carry
        24 - sc : set carry
        25 - cz : clear zero
        26 - sz : set zero
        27 - cs : clear sign
        28 - ss : set sign
        29 - stf : store flags
        30 - rsf: restore flags
        31 : reserved

5. Interrupt

   | 31 - 28 | 27 - 24 | 23 -  4  | 3 - 0  |
   |---------|---------|----------|--------|
   |   0x0   |  0x5    |    x     |  INT   |

	INT: interrupt vector (0-15)

	Branches to interrupt vector specified by INT, linking to
	interrupt link register, r14.

	Vector table is located at address 0x0000.

	Can be used for software interrupts, but mostly exists so
	it can be inserted into the pipeline on interrupt condition.


6. Set / clear interrupts

   | 31 - 28 | 27 - 24 | 23 -  1  | 0       |
   |---------|---------|----------|---------|
   |   0x0   |  0x6    |    x     |  Flag   |

	Flag: 1 = interrupts enabled, 0 = interrupts disabled

7. Sleep

   | 31 - 28 | 27 - 24 | 23 -  1  | 0       |
   |---------|---------|----------|---------|
   |   0x0   |  0x7    |    x     |  Flag   |

	Halts the CPU. Will wake on interrupt.

Class 1:  Immediate load
------------------------

|31 - 28 | 27 - 24 | 23 - 0 |
|--------|---------|--------|
|  0x1   |   x     | IMM_HI |

    IMM_HI: the upper 24 bits of the immediate register, available to the following instruction
    to construct a 32 bit immediate value for branches and alu operations

Class 2: Register to register ALU operation
-------------------------------------------

|31 - 28 | 27 - 24 | 23 - 16 | 15 - 8 | 7 - 0 |
|--------|---------|---------|--------|-------|
|  0x2   |  ALU OP | DEST    | SRC    | SRC2  |




    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- SRC2
        1 - add : DEST <- SRC + SRC2
        2 - adc : DEST <- SRC + SRC2 + Carry
        3 - sub : DEST <- SRC - SRC2
        4 - sbb : DEST <- SRC - SRC2 - Carry
        5 - and : DEST <- SRC & SRC2
        6 - or  : DEST <- SRC | SRC2
        7 - xor : DEST <- SRC ^ SRC2
    	8 - mul : DEST <- SRC * SRC2 (LO)
        9 - mulu : DEST <- SRC * SRC2 (HI)
        10: - rrn : rotate nibble right
	11: - rln : rotate nibble left
        12: cmp 
        13: test
        14 - umulu : DEST <- (UNSIGNED) SRC * (UNSIGNED) SRC2 (HI) 
        15 - bswap : DEST <- bytes swapped SRC2
 
        DEST: destination
        SRC: first operand (alu A input)
	SRC2: second operand (alu B input) 

Class 3: immediate to register ALU operation
-------------------------------------------

|31 - 28 | 27 - 24 | 23 - 16 | 15 - 8 | 7 - 0  |
|--------|---------|---------|--------|--------|
|  0x3   |  ALU OP | DEST    | SRC    | IMM LO |


    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- IMM
        1 - add : DEST <- SRC + IMM
        2 - adc : DEST <- SRC + IMM + Carry
        3 - sub : DEST <- SRC - IMM
        4 - sbb : DEST <- SRC - IMM - Carry
        5 - and : DEST <- SRC & IMM
        6 - or  : DEST <- SRC | IMM
        7 - xor : DEST <- SRC ^ IMM
        8 - mul : DEST <- SRC * IMM (LO)
        9 - mulu : DEST <- SRC * IMM (HI)
        10 - 11 : reserved
        12 - cmp : compare
        13 - test : bit test
        14 - umulu : DEST <- (UNSIGNED) SRC * (UNSIGNED) IMM (HI)
        15 - reserved
  
    DEST: destination 
    SRC:  operand (alu A input)
    IMM LO : 4 bit immediate which can be combined with the immediate register to produce a 
        16 bit value

Class 4: branch operation
-------------------------------------------

|31 - 28 | 27 - 24 | 23 - 16 | 15 - 8 | 7 - 0  |
|--------|---------|---------|--------|--------|
|  0x4   |  BRNCH  | x       | REG    | IMM LO |

    BRNCH:
        0  - BZ, BEQ branch if zero
        1  - BNZ, BNE branch if not zero
        2  - BS, branch if sign
        3  - BNS, branch if not sign
        4  - BC, BLTU branch if carry or unsigned less than
        5  - BNC, BGEU branch if not carry or unsigned greater than or equal
        6  - BV, branch if overflow     
        7  - BNV, branch if not overflow
        8  - BLT, branch if (signed) less than
        9  - BLE, branch if (signed) less than or equal
        10 - BGT, branch if (signed) greater than
        11 - BGE, branch if (signed) greater than or equal
        12 - BLEU, branch if (unsigned) less than or equal
        13 - BGTU, branch if (unsigned) greater than
        14 - BA, branch always
        15 - BL, branch and link
    REG: index register for register branch
    IMM LO: 8 bit immediate for immediate branch
	PC <- [REG] + IMM

Class 5:
-------- 

Reserved

Class 6:
--------

Reserved
  
Class 7:
--------

Reserved


Class 8: immediate + register byte, half word, upper half word  memory operation
-------------------------------------------------------------------------------------------------

|31 - 28 | 27 | 26 | 25 - 24 | 23 - 16 | 15 - 8 | 7 - 0  |
|--------|----|----|---------|---------|--------|--------|
|  0x8   | x  | LS | SIZE    |  REG    | IDX    | IMM    |

	Provides bytewise and half-word-wise access. Lowest byte of a register is loaded and optionally sign extended. 
	Lowest bit of address
	indicates byte or half-word in memory. Optionally Sign extends to 32 bit on load. Accesses must be aligned (else
	exception).

    LS: 0 = load, 1 = store
    IDX: index register, holds address of memory location
    REG: destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM
    SIZE: 0 -> byte, zero extend on load
	  1 -> half-word, zero extend on load
          2 -> byte, sign extend on load
          3 -> half-word, sign extend on load


Class 9: two register conditional ALU operation
-------------------------------------------------

|31 - 28 | 27 - 24 | 23 - 20 | 19 - 16 | 15 - 8 | 7 - 0 |
|--------|---------|---------|---------|--------|-------|
|  0x9   |  ALU OP | X       |  COND   |  DEST  | SRC2  |

    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- SRC
        1 - add : DEST <- DEST + SRC
        2 - adc : DEST <- DEST + SRC + Carry
        3 - sub : DEST <- DEST - SRC
        4 - sbb : DEST <- DEST - SRC - Carry
        5 - and : DEST <- DEST & SRC
        6 - or  : DEST <- DEST | SRC
        7 - xor : DEST <- DEST ^ SRC
    	8 - mul : DEST <- DEST * SRC (LO)
        9 - mulu : DEST <- DEST * SRC (HI)
        10 - 11 : reserved
        12: cmp 
        13: test
        14 - umulu : DEST <- (UNSIGNED) DEST * (UNSIGNED) SRC (HI) 
        15 - reserved
 
    COND as per branch
    Result is stored / flags changed if COND


Class A / B:  
-------------------------------------------------------
Reserved


Class C: immediate + register memory load
-----------------------------------------------

|31 - 28 | 27 - 24 | 23 - 16 | 15 - 8 | 7 - 0 |
|--------|---------|---------|--------|-------|
|  0xc   |    x    |  REG    | IDX    | IMM   |


    Effective address must be aligned

    IDX: index register, holds address of memory location
    REG: destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM

Class D: immediate + register memory store
-----------------------------------------------

|31 - 28 | 27 - 24 | 23 - 16 | 15 - 8 | 7 - 0 |
|--------|---------|---------|--------|-------|
|  0xd   |    x    |  REG    | IDX    | IMM   |

    Effective address must be aligned

    IDX: index register, holds address of memory location
    REG: source for store
    IMM: immediate address of memory location, effective address = [IDX] + IMM


Classes E/F: 
-------------------
Reserved

