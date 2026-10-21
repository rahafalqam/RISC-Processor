module data_memory ( 
    input         clk, 
    input         MemRead,
    input         MemWrite,
    input         LB,

    input  [31:0] address,
    input  [31:0] WriteData,

    output [31:0] ReadData
); 
  
    parameter MEM_DEPTH = 256; 
  
    reg [31:0] memory [0:MEM_DEPTH-1];


    // Synchronous Write
    always @(posedge clk) begin
        if (MemWrite)
            memory[address] <= WriteData;
    end


    // Asynchronous Read
    wire [31:0] word_read = memory[address];


    // LB sign extension
    wire [31:0] lb_extended =
        {{24{word_read[7]}}, word_read[7:0]};


    assign ReadData = LB ? lb_extended : word_read;


endmodule