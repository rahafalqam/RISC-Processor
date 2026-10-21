`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] A, B;
    reg  [3:0]  ALUOp;
    wire [31:0] Result;
    wire        Zero;

    alu uut (.A(A), .B(B), .ALUOp(ALUOp), .Result(Result), .Zero(Zero));

    task check(input [3:0] op, input [31:0] a, input [31:0] b,
               input [31:0] exp, input [63:0] name);
        begin
            ALUOp = op; A = a; B = b; #10;
            if (Result === exp && Zero === (exp == 32'd0))
                $display("PASS  %0s  A=%h B=%h -> %h  Zero=%b", name, a, b, Result, Zero);
            else
                $display("FAIL  %0s  A=%h B=%h -> %h (exp %h)  Zero=%b (exp %b)",
                         name, a, b, Result, exp, Zero, (exp == 32'd0));
        end
    endtask

    initial begin
        // ADD
        check(4'b0000, 32'd5,          32'd7,          32'd12,         "ADD ");
        check(4'b0000, 32'd10,         32'hFFFF_FFF6,  32'd0,          "ADD ");  // 10 + (-10) = 0, Zero=1
        // SUB
        check(4'b0001, 32'd7,          32'd5,          32'd2,          "SUB ");
        check(4'b0001, 32'd5,          32'd7,          32'hFFFF_FFFE,  "SUB ");  // 5 - 7 = -2
        check(4'b0001, 32'd9,          32'd9,          32'd0,          "SUB ");  // equal -> Zero=1 (BEQ)
        // logic
        check(4'b0010, 32'hFF00_FF00,  32'h0FF0_0FF0,  32'h0F00_0F00,  "AND ");
        check(4'b0011, 32'hFF00_FF00,  32'h0FF0_0FF0,  32'hFFF0_FFF0,  "OR  ");
        check(4'b0100, 32'hFF00_FF00,  32'h0FF0_0FF0,  32'hF0F0_F0F0,  "XOR ");
        check(4'b0101, 32'hFF00_FF00,  32'h0FF0_0FF0,  32'h000F_000F,  "NOR ");
        // shifts
        check(4'b0110, 32'd1,          32'd4,          32'd16,         "SLL ");
        check(4'b0111, 32'h8000_0000,  32'd31,         32'd1,          "SRL ");
        check(4'b0110, 32'd1,          32'd33,         32'd2,          "SLL ");  // 33 -> uses [4:0] = 1
        check(4'b0111, 32'hFFFF_FFFF,  32'd4,          32'h0FFF_FFFF,  "SRL ");  // logical, fills with 0
        // CLR
        check(4'b1000, 32'hDEAD_BEEF,  32'hFFFF_FFFF,  32'd0,          "CLR ");

        $display("ALU test done.");
        $finish;
    end

endmodule