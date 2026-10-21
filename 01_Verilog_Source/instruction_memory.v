module instruction_memory(
    input [31:0] address,
    output [31:0] instruction
);

reg [31:0] memory [0:255];

initial begin
    memory[0] = 32'h12345678;
    memory[1] = 32'hAAAAAAAA;
    memory[2] = 32'hFFFFFFFF;
end

assign instruction = memory[address[7:0]];

endmodule