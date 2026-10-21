`timescale 1ns/1ps

module imm_extender_tb;

    reg  [17:0] Imm;
    reg         ExtOp;
    wire [31:0] ExtImm;

    imm_extender uut (.Imm(Imm), .ExtOp(ExtOp), .ExtImm(ExtImm));

    task check(input [17:0] imm, input ext, input [31:0] exp, input [63:0] name);
        begin
            Imm = imm; ExtOp = ext; #10;
            if (ExtImm === exp)
                $display("PASS  %0s  Imm=%h ExtOp=%b -> %h", name, imm, ext, ExtImm);
            else
                $display("FAIL  %0s  Imm=%h ExtOp=%b -> %h (exp %h)", name, imm, ext, ExtImm, exp);
        end
    endtask

    initial begin
        // sign extension (ExtOp = 1)
        check(18'h00005,  1, 32'h0000_0005, "SIGN+");   // +5 stays +5
        check(18'h3FFFB,  1, 32'hFFFF_FFFB, "SIGN-");   // -5 in 18-bit -> -5 in 32-bit
        check(18'h20000,  1, 32'hFFFE_0000, "SIGN-");   // most negative 18-bit value
        check(18'h1FFFF,  1, 32'h0001_FFFF, "SIGN+");   // most positive 18-bit value

        // zero extension (ExtOp = 0)
        check(18'h00005,  0, 32'h0000_0005, "ZERO ");
        check(18'h3FFFB,  0, 32'h0003_FFFB, "ZERO ");   // same bits as SIGN- but no fill
        check(18'h20000,  0, 32'h0002_0000, "ZERO ");

        $display("Immediate extender test done.");
        $finish;
    end

endmodule