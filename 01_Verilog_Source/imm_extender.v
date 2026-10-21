module imm_extender (
    input  [17:0] Imm,      // 18-bit immediate from the instruction
    input         ExtOp,    // 1 = sign extend, 0 = zero extend
    output [31:0] ExtImm
);

    assign ExtImm = ExtOp ? {{14{Imm[17]}}, Imm}   // sign: copy bit 17 fourteen times
                          : {14'b0, Imm};          // zero: fill with zeros

endmodule