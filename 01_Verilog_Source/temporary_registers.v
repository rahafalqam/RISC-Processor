				 module temporary_registers(
    input clk,
    input rst,

    input IRWrite,
    input AWrite,
    input BWrite,
    input ALUOutWrite,
    input MDRWrite,
    input OldPCWrite,

    input [31:0] instruction,
    input [31:0] regA,
    input [31:0] regB,
    input [31:0] alu_result,
    input [31:0] mem_data,
    input [31:0] PC,

    output reg [31:0] IR,
    output reg [31:0] A,
    output reg [31:0] B,
    output reg [31:0] ALUOut,
    output reg [31:0] MDR,
    output reg [31:0] OldPC
);


always @(posedge clk) begin

    if (rst) begin
        IR     <= 32'b0;
        A      <= 32'b0;
        B      <= 32'b0;
        ALUOut <= 32'b0;
        MDR    <= 32'b0;
        OldPC  <= 32'b0;
    end

    else begin

        if (IRWrite)
            IR <= instruction;

        if (AWrite)
            A <= regA;

        if (BWrite)
            B <= regB;

        if (ALUOutWrite)
            ALUOut <= alu_result;

        if (MDRWrite)
            MDR <= mem_data;

        if (OldPCWrite)
            OldPC <= PC;

    end

end

endmodule