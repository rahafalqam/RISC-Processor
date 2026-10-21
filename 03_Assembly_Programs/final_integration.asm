; ENCS4370 Project 2 - Final multi-cycle integration regression
; Instruction format and offsets match the implemented word-addressed ISA.
; Addresses at left are word PCs.

00: ADDI R1,R0,5
01: ADDI R2,R0,7
02: ADD R3,R1,R2
03: SUB R4,R2,R1
04: AND R5,R1,R2
05: OR R6,R1,R2
06: XOR R7,R1,R2
07: NOR R8,R1,R2
08: ADDI R9,R0,33
09: SLL R10,R1,R9
10: SRL R11,R8,R9
11: CLR R12
12: ANDI R12,R3,6
13: ORI R12,R12,1
14: SW R3,0(R0)
15: LW R13,0(R0)
16: BEQ R13,R3,+2
17: SW R3,9(R0) ; poison, must skip
18: BNE R1,R1,+2 ; not taken
19: SW R3,4(R0) ; not-taken marker
20: BNE R2,R1,+2
21: SW R3,10(R0) ; poison, must skip
22: BEQ R2,R1,+2 ; not taken
23: SW R3,5(R0) ; not-taken marker
24: J +2
25: SW R3,11(R0) ; poison, must skip
26: JAL +6 ; target 32, R14=27
27: ADDI R15,R0,42 ; return point
28: SW R12,3(R0) ; subroutine-result marker
29: J +6 ; continue to 35
30: ADD R0,R0,R0 ; filler/no architectural effect
31: ADD R0,R0,R0 ; filler/no architectural effect
32: ADDI R12,R0,1 ; subroutine
33: JR R14
34: ADD R0,R0,R0 ; filler/no architectural effect
35: Lb R13,1(R0)
36: SWAP R3,2(R0)
37: ADDI R4,R0,1
38: ADDI R4,R4,-1
39: BEQ R4,R0,-1 ; taken once then not taken
40: SW R4,6(R0)
41: ORI R12,R0,0x20000
42: SW R12,7(R0)
43: ANDI R12,R4,0x20000
44: SW R12,8(R0)
45: ADDI R0,R0,123
46: J 0 ; halt-like self-loop
