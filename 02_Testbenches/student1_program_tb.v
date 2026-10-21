`timescale 1ns/1ps
module student1_program_tb;
    reg clk = 0, rst = 1;
    wire [31:0] debug_PC, debug_IR, debug_ALUOut, debug_MDR, debug_WriteData, debug_MemAddress, debug_MemWriteData;
    wire [4:0] debug_state; wire debug_RegWrite, debug_MemWrite; wire [3:0] debug_WriteReg;
    top_processor dut(.clk(clk), .rst(rst), .debug_PC(debug_PC), .debug_IR(debug_IR), .debug_ALUOut(debug_ALUOut),
        .debug_MDR(debug_MDR), .debug_state(debug_state), .debug_RegWrite(debug_RegWrite), .debug_MemWrite(debug_MemWrite),
        .debug_WriteReg(debug_WriteReg), .debug_WriteData(debug_WriteData), .debug_MemAddress(debug_MemAddress), .debug_MemWriteData(debug_MemWriteData));
    always #5 clk = ~clk;
    integer i, errors = 0;
    reg [31:0] exp [0:13];
    task check(input integer r, input [31:0] e); begin
        if (dut.rf.regs[r] !== e) begin $display("FAIL R%0d = %h (exp %h)", r, dut.rf.regs[r], e); errors = errors + 1; end
        else $display("PASS R%0d = %h", r, dut.rf.regs[r]);
    end endtask
    initial begin
        #1; for (i = 0; i < 256; i = i + 1) dut.imem.memory[i] = 32'b0;
        $readmemh("test_student1.hex", dut.imem.memory);
        repeat (2) @(posedge clk); @(negedge clk); rst = 0;
        repeat (80) @(posedge clk);
        check(1,32'h5); check(2,32'hFFFFFFFD); check(3,32'h0); check(4,32'h8); check(5,32'h0); check(6,32'hD);
        check(7,32'h7); check(8,32'hFFFFFFFA); check(9,32'h2); check(10,32'h14); check(11,32'h2); check(12,32'hFD); check(13,32'h3FFFF);
        if (errors == 0) $display("STUDENT1 PROGRAM: PASS"); else $display("STUDENT1 PROGRAM: FAIL (%0d)", errors);
        $finish;
    end
endmodule
