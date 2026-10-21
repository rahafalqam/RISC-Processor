  module alu (
    input  [31:0] A,        // Reg(Rs)
    input  [31:0] B,        // Reg(Rt) or extended immediate
    input  [3:0]  ALUOp,
    output reg [31:0] Result,
    output        Zero      // 1 when Result == 0 (used by BEQ)
);

    always @(*) begin
        case (ALUOp)
            4'b0000: Result = A + B;             // ADD
            4'b0001: Result = A - B;             // SUB
            4'b0010: Result = A & B;             // AND
            4'b0011: Result = A | B;             // OR
            4'b0100: Result = A ^ B;             // XOR
            4'b0101: Result = ~(A | B);          // NOR
            4'b0110: Result = A << B[4:0];       // SLL
            4'b0111: Result = A >> B[4:0];       // SRL
            4'b1000: Result = 32'd0;             // CLR
            default: Result = 32'd0;
        endcase
    end

    assign Zero = (Result == 32'd0);

endmodule