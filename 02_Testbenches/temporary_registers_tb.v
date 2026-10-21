					 module temporary_registers_tb();

reg clk;
reg rst;

reg IRWrite;
reg AWrite;
reg BWrite;
reg ALUOutWrite;
reg MDRWrite;
reg OldPCWrite;

reg [31:0] instruction;
reg [31:0] regA;
reg [31:0] regB;
reg [31:0] alu_result;
reg [31:0] mem_data;
reg [31:0] PC;


wire [31:0] IR;
wire [31:0] A;
wire [31:0] B;
wire [31:0] ALUOut;
wire [31:0] MDR;
wire [31:0] OldPC;


temporary_registers dut(
    .clk(clk),
    .rst(rst),

    .IRWrite(IRWrite),
    .AWrite(AWrite),
    .BWrite(BWrite),
    .ALUOutWrite(ALUOutWrite),
    .MDRWrite(MDRWrite),
    .OldPCWrite(OldPCWrite),

    .instruction(instruction),
    .regA(regA),
    .regB(regB),
    .alu_result(alu_result),
    .mem_data(mem_data),
    .PC(PC),

    .IR(IR),
    .A(A),
    .B(B),
    .ALUOut(ALUOut),
    .MDR(MDR),
    .OldPC(OldPC)
);


// Clock
always #5 clk = ~clk;


initial begin

    clk = 0;
    rst = 1;

    IRWrite = 0;
    AWrite = 0;
    BWrite = 0;
    ALUOutWrite = 0;
    MDRWrite = 0;
    OldPCWrite = 0;

    instruction = 0;
    regA = 0;
    regB = 0;
    alu_result = 0;
    mem_data = 0;
    PC = 0;


    // Reset
    #10;
    rst = 0;


    // Test IR
    instruction = 32'h12345678;
    IRWrite = 1;

    #10;
    IRWrite = 0;


    // Test A and B
    regA = 32'hAAAA0000;
    regB = 32'hBBBB0000;

    AWrite = 1;
    BWrite = 1;

    #10;

    AWrite = 0;
    BWrite = 0;


    // Test ALUOut
    alu_result = 32'h55555555;
    ALUOutWrite = 1;

    #10;

    ALUOutWrite = 0;


    // Test MDR
    mem_data = 32'hFFFFFFFF;
    MDRWrite = 1;

    #10;

    MDRWrite = 0;


    // Test OldPC
    PC = 32'd100;
    OldPCWrite = 1;

    #10;

    OldPCWrite = 0;


    // Display results
    #5;

    $display("IR     = %h", IR);
    $display("A      = %h", A);
    $display("B      = %h", B);
    $display("ALUOut = %h", ALUOut);
    $display("MDR    = %h", MDR);
    $display("OldPC  = %d", OldPC);


    $finish;

end


endmodule