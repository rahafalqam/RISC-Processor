			  module program_counter(
    input clk,
    input rst,
    input PCWrite,
    input [31:0] nextPC,
    output reg [31:0] PC
);

always @(posedge clk) begin

    if (rst)
        PC <= 32'b0;

    else if (PCWrite)
        PC <= nextPC;

end

endmodule