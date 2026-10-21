module data_memory_tb;

    reg clk;
    reg MemRead, MemWrite, LB;

    reg [31:0] address;
    reg [31:0] WriteData;

    wire [31:0] ReadData;


    data_memory dut (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .LB(LB),
        .address(address),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );


    // clk: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;


    initial begin

        MemRead = 0;
        MemWrite = 0;
        LB = 0;

        address = 0;
        WriteData = 0;


        // =========================
        // SW: Write word
        // =========================

        @(negedge clk);

        address = 4;
        WriteData = 32'hAABBCCDD;
        MemWrite = 1;

        @(posedge clk);

        @(negedge clk);

        MemWrite = 0;


        // =========================
        // LW: Read word
        // =========================

        MemRead = 1;
        address = 4;
        LB = 0;

        #5;

        $display("LW ReadData = %h", ReadData);


        MemRead = 0;



        // =========================
        // LB: Negative byte
        // DD -> FFFFFFDD
        // =========================

        LB = 1;

        #5;

        $display("LB Negative ReadData = %h", ReadData);



        // =========================
        // SW another value
        // =========================

        @(negedge clk);

        LB = 0;
        MemWrite = 1;

        address = 8;
        WriteData = 32'h1122337F;


        @(posedge clk);

        @(negedge clk);

        MemWrite = 0;



        // =========================
        // LB: Positive byte
        // 7F -> 0000007F
        // =========================

        MemRead = 1;
        LB = 1;
        address = 8;

        #5;

        $display("LB Positive ReadData = %h", ReadData);



        // =========================
        // Check no write when MemWrite=0
        // =========================

        @(negedge clk);

        LB = 0;
        MemWrite = 0;

        address = 4;
        WriteData = 32'hFFFFFFFF;


        @(posedge clk);

        @(negedge clk);

        MemRead = 1;
        address = 4;

        #5;

        $display("No Write ReadData = %h", ReadData);



        $finish;

    end


endmodule