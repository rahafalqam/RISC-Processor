module register_file (
    input         clk,
    input         rst,
    input         RegWrite,
    input  [3:0]  Rs,          // read port 1 address
    input  [3:0]  Rt,          // read port 2 address
    input  [3:0]  Rd,          // write address
    input  [31:0] WriteData,
    output [31:0] ReadData1,   // Reg(Rs)
    output [31:0] ReadData2    // Reg(Rt)
);

    reg [31:0] regs [0:15];
    integer i;

    // asynchronous read, R0 always reads as zero
    assign ReadData1 = (Rs == 4'd0) ? 32'd0 : regs[Rs];
    assign ReadData2 = (Rt == 4'd0) ? 32'd0 : regs[Rt];

    // synchronous write, writes to R0 are ignored
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 32'd0;
        end
        else if (RegWrite && Rd != 4'd0)
            regs[Rd] <= WriteData;
    end

endmodule