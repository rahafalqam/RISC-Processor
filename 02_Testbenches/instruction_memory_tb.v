				module instruction_memory_tb();

reg [31:0] address;

wire [31:0] instruction;


instruction_memory dut(
    .address(address),
    .instruction(instruction)
);


initial begin

    address = 0;

    #10;
    $display("Instruction[0] = %h", instruction);


    address = 1;

    #10;
    $display("Instruction[1] = %h", instruction);


    address = 2;

    #10;
    $display("Instruction[2] = %h", instruction);


    $finish;

end


endmodule