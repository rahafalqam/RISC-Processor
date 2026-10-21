				module next_pc_logic_tb();

reg [31:0] OldPC;
reg [31:0] offset;
reg [31:0] rs_value;
reg [1:0] PCSrc;

wire [31:0] nextPC;


next_pc_logic dut(
    .OldPC(OldPC),
    .offset(offset),
    .rs_value(rs_value),
    .PCSrc(PCSrc),
    .nextPC(nextPC)
);


initial begin

    OldPC = 32'd100;
    offset = 32'd20;
    rs_value = 32'd500;


    // Normal PC + 1
    PCSrc = 2'b00;
    #10;
    $display("NORMAL PC = %d", nextPC);


    // BEQ
    PCSrc = 2'b01;
    #10;
    $display("BEQ PC = %d", nextPC);


    // J / JAL
    PCSrc = 2'b10;
    #10;
    $display("JUMP PC = %d", nextPC);


    // JR
    PCSrc = 2'b11;
    #10;
    $display("JR PC = %d", nextPC);


    $finish;

end

endmodule