`timescale 1ns/1ps

module register_file_tb;

    reg         clk = 0;
    reg         rst;
    reg         RegWrite;
    reg  [3:0]  Rs, Rt, Rd;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    register_file uut (
        .clk(clk), .rst(rst), .RegWrite(RegWrite),
        .Rs(Rs), .Rt(Rt), .Rd(Rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    always #5 clk = ~clk;   // 10 ns period

    task write_reg(input [3:0] addr, input [31:0] data);
        begin
            @(negedge clk);
            Rd = addr; WriteData = data; RegWrite = 1;
            @(negedge clk);
            RegWrite = 0;
        end
    endtask

    task check(input [3:0] a1, input [3:0] a2,
               input [31:0] exp1, input [31:0] exp2);
        begin
            Rs = a1; Rt = a2; #1;
            if (ReadData1 === exp1 && ReadData2 === exp2)
                $display("PASS  R%0d=%h  R%0d=%h", a1, ReadData1, a2, ReadData2);
            else
                $display("FAIL  R%0d=%h (exp %h)  R%0d=%h (exp %h)",
                         a1, ReadData1, exp1, a2, ReadData2, exp2);
        end
    endtask

    initial begin
        RegWrite = 0; Rs = 0; Rt = 0; Rd = 0; WriteData = 0;

        // 1. reset
        rst = 1; @(negedge clk); rst = 0;
        check(4'd1, 4'd15, 32'h0, 32'h0);

        // 2. normal writes + read from both ports
        write_reg(4'd1,  32'h0000_000A);
        write_reg(4'd2,  32'hFFFF_FFF6);      // -10 two's complement
        write_reg(4'd15, 32'hDEAD_BEEF);
        check(4'd1, 4'd2,  32'h0000_000A, 32'hFFFF_FFF6);
        check(4'd15, 4'd1, 32'hDEAD_BEEF, 32'h0000_000A);

        // 3. write to R0 must be ignored
        write_reg(4'd0, 32'h1234_5678);
        check(4'd0, 4'd0, 32'h0, 32'h0);

        // 4. RegWrite = 0 must not write
        @(negedge clk); Rd = 4'd3; WriteData = 32'h5555_5555; RegWrite = 0;
        @(negedge clk);
        check(4'd3, 4'd0, 32'h0, 32'h0);

        // 5. overwrite existing register
        write_reg(4'd1, 32'h0000_0001);
        check(4'd1, 4'd2, 32'h0000_0001, 32'hFFFF_FFF6);

        $display("Register file test done.");
        $finish;
    end

endmodule