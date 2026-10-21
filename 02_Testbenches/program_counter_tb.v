			   module program_counter_tb();

reg clk;
reg rst;
reg PCWrite;
reg [31:0] nextPC;

wire [31:0] PC;


program_counter dut(
    .clk(clk),
    .rst(rst),
    .PCWrite(PCWrite),
    .nextPC(nextPC),
    .PC(PC)
);


always #5 clk = ~clk;


initial begin

    clk = 0;
    rst = 1;
    PCWrite = 0;
    nextPC = 0;


    // Reset
    #10;
    rst = 0;


    // Update PC
    #10;
    nextPC = 32'd10;
    PCWrite = 1;


    #10;
    PCWrite = 0;


    #10;
    $display("PC = %d", PC);


    $finish;

end


endmodule