; test_student1.asm  -  R-type + ADDI/ANDI/ORI
ADDI R1,  R0, 5          ; R1  = 5
ADDI R2,  R0, -3         ; R2  = -3  (FFFFFFFD)   sign-extend test
ADD  R3,  R1, R2         ; R3  = 2
SUB  R4,  R1, R2         ; R4  = 8
AND  R5,  R1, R4         ; R5  = 5 & 8  = 0
OR   R6,  R1, R4         ; R6  = 5 | 8  = 13 (D)
XOR  R7,  R1, R3         ; R7  = 5 ^ 2  = 7
NOR  R8,  R0, R1         ; R8  = ~(0|5) = FFFFFFFA
ADDI R9,  R0, 2          ; R9  = 2   (shift amount)
SLL  R10, R1, R9         ; R10 = 5 << 2 = 20 (14)
SRL  R11, R4, R9         ; R11 = 8 >> 2 = 2
ANDI R12, R2, 0xFF       ; R12 = FFFFFFFD & FF = FD   zero-extend test
ORI  R13, R0, 0x3FFFF    ; R13 = 0003FFFF            zero-extend, not sign
CLR  R3                  ; R3  = 0