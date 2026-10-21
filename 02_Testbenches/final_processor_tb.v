`timescale 1ns/1ps

module final_processor_tb;

    reg clk;
    reg rst;

    wire [31:0] debug_PC;
    wire [31:0] debug_IR;
    wire [31:0] debug_ALUOut;
    wire [31:0] debug_MDR;
    wire [4:0]  debug_state;
    wire        debug_RegWrite;
    wire        debug_MemWrite;
    wire [3:0]  debug_WriteReg;
    wire [31:0] debug_WriteData;
    wire [31:0] debug_MemAddress;
    wire [31:0] debug_MemWriteData;

    integer i;
    integer errors;
    integer cycle_count;

    // Set to 1 only when a full cycle-by-cycle console trace is needed.
    // The default final regression keeps this off so the PASS/FAIL evidence
    // is concise and easy to inspect.
    localparam TRACE_ENABLE = 1'b0;

    localparam [4:0] ST_ID     = 5'd1;
    localparam [4:0] ST_BRANCH = 5'd10;

    localparam [5:0] OP_ADD  = 6'd0;
    localparam [5:0] OP_SUB  = 6'd1;
    localparam [5:0] OP_AND  = 6'd2;
    localparam [5:0] OP_OR   = 6'd3;
    localparam [5:0] OP_XOR  = 6'd4;
    localparam [5:0] OP_NOR  = 6'd5;
    localparam [5:0] OP_SLL  = 6'd6;
    localparam [5:0] OP_SRL  = 6'd7;
    localparam [5:0] OP_CLR  = 6'd8;
    localparam [5:0] OP_JR   = 6'd9;
    localparam [5:0] OP_ADDI = 6'd10;
    localparam [5:0] OP_ANDI = 6'd11;
    localparam [5:0] OP_ORI  = 6'd12;
    localparam [5:0] OP_LW   = 6'd13;
    localparam [5:0] OP_SW   = 6'd14;
    localparam [5:0] OP_SWAP = 6'd15;
    localparam [5:0] OP_BEQ  = 6'd16;
    localparam [5:0] OP_BNE  = 6'd17;
    localparam [5:0] OP_J    = 6'd18;
    localparam [5:0] OP_JAL  = 6'd19;
    localparam [5:0] OP_LB   = 6'd20;

    // Coverage gathered from the real integrated execution.
    // opcode_seen[n] is set when an instruction with opcode n reaches ID.
    reg [20:0] opcode_seen;
    reg beq_taken_seen;
    reg beq_not_taken_seen;
    reg bne_taken_seen;
    reg bne_not_taken_seen;

    top_processor dut (
        .clk(clk),
        .rst(rst),
        .debug_PC(debug_PC),
        .debug_IR(debug_IR),
        .debug_ALUOut(debug_ALUOut),
        .debug_MDR(debug_MDR),
        .debug_state(debug_state),
        .debug_RegWrite(debug_RegWrite),
        .debug_MemWrite(debug_MemWrite),
        .debug_WriteReg(debug_WriteReg),
        .debug_WriteData(debug_WriteData),
        .debug_MemAddress(debug_MemAddress),
        .debug_MemWriteData(debug_MemWriteData)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------
    // Instruction encoders
    // -------------------------
    // R-type: [31:26] opcode, [25:22] Rd, [21:18] Rs,
    //         [17:14] Rt, [13:0] unused
    function [31:0] ENC_R;
        input [5:0] op;
        input [3:0] rd;
        input [3:0] rs;
        input [3:0] rt;
        begin
            ENC_R = {op, rd, rs, rt, 14'b0};
        end
    endfunction

    // I-type: [31:26] opcode, [25:22] Rt, [21:18] Rs,
    //         [17:0] immediate
    function [31:0] ENC_I;
        input [5:0] op;
        input [3:0] rt;
        input [3:0] rs;
        input integer imm;
        begin
            ENC_I = {op, rt, rs, imm[17:0]};
        end
    endfunction

    // J-type: [31:26] opcode, [25:0] signed offset
    function [31:0] ENC_J;
        input [5:0] op;
        input integer offset;
        begin
            ENC_J = {op, offset[25:0]};
        end
    endfunction

    // -------------------------
    // Optional cycle trace
    // -------------------------
    task PRINT_STATE_NAME;
        input [4:0] st;
        begin
            case (st)
                5'd0:  $write("IF");
                5'd1:  $write("ID");
                5'd2:  $write("R_EX");
                5'd3:  $write("R_WB");
                5'd4:  $write("I_EX");
                5'd5:  $write("I_WB");
                5'd6:  $write("ADDR_EX");
                5'd7:  $write("MEM_READ");
                5'd8:  $write("MEM_WB");
                5'd9:  $write("MEM_WRITE");
                5'd10: $write("BRANCH");
                5'd11: $write("JUMP");
                5'd12: $write("JAL");
                5'd13: $write("JR");
                5'd14: $write("SWAP_READ");
                5'd15: $write("SWAP_COMMIT");
                default: $write("UNKNOWN");
            endcase
        end
    endtask

    task PRINT_OPCODE_NAME;
        input [5:0] op;
        begin
            case (op)
                OP_ADD:  $write("ADD");
                OP_SUB:  $write("SUB");
                OP_AND:  $write("AND");
                OP_OR:   $write("OR");
                OP_XOR:  $write("XOR");
                OP_NOR:  $write("NOR");
                OP_SLL:  $write("SLL");
                OP_SRL:  $write("SRL");
                OP_CLR:  $write("CLR");
                OP_JR:   $write("JR");
                OP_ADDI: $write("ADDI");
                OP_ANDI: $write("ANDI");
                OP_ORI:  $write("ORI");
                OP_LW:   $write("LW");
                OP_SW:   $write("SW");
                OP_SWAP: $write("SWAP");
                OP_BEQ:  $write("BEQ");
                OP_BNE:  $write("BNE");
                OP_J:    $write("J");
                OP_JAL:  $write("JAL");
                OP_LB:   $write("Lb");
                default: $write("UNDEFINED");
            endcase
        end
    endtask

    task PRINT_CYCLE_TRACE;
        begin
            $display("");
            $display("============================================================");
            $display("MULTI-CYCLE TRACE -- CYCLE %0d -- time=%0t ns", cycle_count, $time);
            $display("============================================================");
            $write("STATE   : ");
            PRINT_STATE_NAME(debug_state);
            $display(" (%0d)", debug_state);
            $write("INSTR   : IR=%h  opcode=%0d (", debug_IR, dut.opcode);
            PRINT_OPCODE_NAME(dut.opcode);
            $display(")");
            $display("FETCH   : PC=%0d  IMem[PC]=%h  OldPC=%0d  selected_nextPC=%0d",
                     debug_PC, dut.instruction, dut.OldPC, dut.selected_nextPC);
            $display("DECODE  : Rs=R%0d  Rt=R%0d  WriteReg=R%0d  ReadData1=%h  ReadData2=%h",
                     dut.rs_addr, dut.rt_addr, debug_WriteReg,
                     dut.ReadData1, dut.ReadData2);
            $display("DATA    : A=%h  B=%h  ExtImm=%h  JumpExt=%h",
                     dut.A, dut.B, dut.ExtImm, dut.JumpExt);
            $display("ALU     : ALU_B=%h  Result=%h  Zero=%b  ALUOut=%h",
                     dut.ALU_B, dut.ALU_Result, dut.Zero, debug_ALUOut);
            $display("MEM     : Address=%0d(%h)  ReadData=%h  WriteData=%h  MDR=%h",
                     debug_MemAddress, debug_MemAddress,
                     dut.MemReadData, debug_MemWriteData, debug_MDR);
            $display("CTRL-1  : RegWrite=%b MemRead=%b MemWrite=%b MemToReg=%b RegDst=%b LB=%b",
                     dut.RegWrite, dut.MemRead, dut.MemWrite,
                     dut.MemToReg, dut.RegDst, dut.LB);
            $display("CTRL-2  : ALUSrc=%b ALUOp=%b ExtOp=%b PCSrc=%b PCWrite=%b",
                     dut.ALUSrc, dut.ALUOp, dut.ExtOp, dut.PCSrc, dut.PCWrite);
            $display("CTRL-3  : IRWrite=%b OldPCWrite=%b AWrite=%b BWrite=%b ALUOutWrite=%b MDRWrite=%b",
                     dut.IRWrite, dut.OldPCWrite, dut.AWrite, dut.BWrite,
                     dut.ALUOutWrite, dut.MDRWrite);
            if (dut.RegWrite)
                $display("PENDING WB : R%0d <= %h", debug_WriteReg, debug_WriteData);
            if (dut.MemWrite)
                $display("PENDING MEM: MEM[%0d] <= %h", debug_MemAddress, debug_MemWriteData);
            if (dut.PCWrite)
                $display("PENDING PC : PC <= %0d (%h)", dut.selected_nextPC, dut.selected_nextPC);
        end
    endtask

    always @(negedge clk) begin
        if (rst)
            cycle_count = 0;
        else begin
            cycle_count = cycle_count + 1;
            if (TRACE_ENABLE)
                PRINT_CYCLE_TRACE;
        end
    end

    // -------------------------
    // Execution coverage + concise event monitor
    // -------------------------
    always @(posedge clk) begin
        if (rst) begin
            opcode_seen          <= 21'b0;
            beq_taken_seen       <= 1'b0;
            beq_not_taken_seen   <= 1'b0;
            bne_taken_seen       <= 1'b0;
            bne_not_taken_seen   <= 1'b0;
        end
        else begin
            if (debug_state == ST_ID && dut.opcode <= OP_LB)
                opcode_seen[dut.opcode] <= 1'b1;

            if (debug_state == ST_BRANCH) begin
                if (dut.opcode == OP_BEQ) begin
                    if (dut.PCWrite)
                        beq_taken_seen <= 1'b1;
                    else
                        beq_not_taken_seen <= 1'b1;
                end
                else if (dut.opcode == OP_BNE) begin
                    if (dut.PCWrite)
                        bne_taken_seen <= 1'b1;
                    else
                        bne_not_taken_seen <= 1'b1;
                end
            end

            if (debug_RegWrite)
                $display("WRITEBACK: R%0d <= %h   PC=%0d state=%0d",
                         debug_WriteReg, debug_WriteData, debug_PC, debug_state);

            if (debug_MemWrite)
                $display("MEMWRITE : MEM[%0d] <= %h   PC=%0d state=%0d",
                         debug_MemAddress, debug_MemWriteData,
                         debug_PC, debug_state);
        end
    end

    // -------------------------
    // Self-checking helpers
    // -------------------------
    task CHECK_REG;
        input integer reg_num;
        input [31:0] expected_value;
        reg [31:0] actual_value;
        begin
            // Directly inspect the instantiated Partner 1 register storage.
            // This includes R0, so the explicit R0-write test is meaningful.
            actual_value = dut.rf.regs[reg_num];
            if (actual_value !== expected_value) begin
                $display("FAIL: R%0d expected %h, got %h",
                         reg_num, expected_value, actual_value);
                errors = errors + 1;
            end
            else
                $display("PASS: R%0d = %h", reg_num, actual_value);
        end
    endtask

    task CHECK_MEM;
        input integer address;
        input [31:0] expected_value;
        begin
            if (dut.dmem.memory[address] !== expected_value) begin
                $display("FAIL: MEM[%0d] expected %h, got %h",
                         address, expected_value, dut.dmem.memory[address]);
                errors = errors + 1;
            end
            else
                $display("PASS: MEM[%0d] = %h", address, dut.dmem.memory[address]);
        end
    endtask

    task CHECK_OPCODE_SEEN;
        input integer op;
        begin
            if (opcode_seen[op] !== 1'b1) begin
                $display("FAIL: opcode %0d was not observed in ID", op);
                errors = errors + 1;
            end
            else begin
                $write("PASS: opcode %0d (", op);
                PRINT_OPCODE_NAME(op[5:0]);
                $display(") executed");
            end
        end
    endtask

    task CHECK_FLAG;
        input flag_value;
        input [8*40-1:0] label;
        begin
            if (flag_value !== 1'b1) begin
                $display("FAIL: coverage flag missing: %0s", label);
                errors = errors + 1;
            end
            else
                $display("PASS: coverage flag: %0s", label);
        end
    endtask

    initial begin
        errors = 0;
        rst = 1'b1;
        cycle_count = 0;
        opcode_seen = 21'b0;
        beq_taken_seen = 1'b0;
        beq_not_taken_seen = 1'b0;
        bne_taken_seen = 1'b0;
        bne_not_taken_seen = 1'b0;

        // Allow module initial blocks to run, then overwrite both memories
        // with the deterministic final integration regression contents.
        #1;

        for (i = 0; i < 256; i = i + 1) begin
            dut.imem.memory[i] = 32'b0;
            dut.dmem.memory[i] = 32'b0;
        end

        // Data preloads used by Lb and SWAP.
        dut.dmem.memory[1] = 32'h00000080;
        dut.dmem.memory[2] = 32'd100;

        // ------------------------------------------------------------
        // Final integration program
        // ------------------------------------------------------------
        // Besides executing all 21 supported opcodes, this program contains
        // discriminating checks for:
        //   * shift amount masking with Rt=33 -> Rt[4:0]=1,
        //   * BEQ/BNE taken and not-taken behavior,
        //   * a negative ADDI immediate and a negative BEQ offset,
        //   * ANDI/ORI zero extension with immediate 18'h20000,
        //   * J/JAL/JR control flow,
        //   * Lb sign extension,
        //   * SWAP two-cycle exchange,
        //   * R0 write protection.
        dut.imem.memory[0]  = ENC_I(OP_ADDI, 4'd1,  4'd0, 5);          // ADDI R1,R0,5
        dut.imem.memory[1]  = ENC_I(OP_ADDI, 4'd2,  4'd0, 7);          // ADDI R2,R0,7
        dut.imem.memory[2]  = ENC_R(OP_ADD,  4'd3,  4'd1, 4'd2);       // ADD R3,R1,R2 = 12
        dut.imem.memory[3]  = ENC_R(OP_SUB,  4'd4,  4'd2, 4'd1);       // SUB R4,R2,R1 = 2
        dut.imem.memory[4]  = ENC_R(OP_AND,  4'd5,  4'd1, 4'd2);       // AND R5,R1,R2 = 5
        dut.imem.memory[5]  = ENC_R(OP_OR,   4'd6,  4'd1, 4'd2);       // OR R6,R1,R2 = 7
        dut.imem.memory[6]  = ENC_R(OP_XOR,  4'd7,  4'd1, 4'd2);       // XOR R7,R1,R2 = 2
        dut.imem.memory[7]  = ENC_R(OP_NOR,  4'd8,  4'd1, 4'd2);       // NOR R8,R1,R2 = FFFFFFF8
        dut.imem.memory[8]  = ENC_I(OP_ADDI, 4'd9,  4'd0, 33);         // shift amount = 33 -> low 5 bits = 1
        dut.imem.memory[9]  = ENC_R(OP_SLL,  4'd10, 4'd1, 4'd9);       // SLL R10,R1,R9 = 10
        dut.imem.memory[10] = ENC_R(OP_SRL,  4'd11, 4'd8, 4'd9);       // SRL R11,R8,R9 = 7FFFFFFC
        dut.imem.memory[11] = ENC_R(OP_CLR,  4'd12, 4'd0, 4'd0);       // CLR R12 = 0
        dut.imem.memory[12] = ENC_I(OP_ANDI, 4'd12, 4'd3, 6);          // ANDI R12,R3,6 = 4
        dut.imem.memory[13] = ENC_I(OP_ORI,  4'd12, 4'd12, 1);         // ORI R12,R12,1 = 5
        dut.imem.memory[14] = ENC_I(OP_SW,   4'd3,  4'd0, 0);          // MEM[0] = 12
        dut.imem.memory[15] = ENC_I(OP_LW,   4'd13, 4'd0, 0);          // R13 = MEM[0] = 12

        dut.imem.memory[16] = ENC_I(OP_BEQ,  4'd13, 4'd3, 2);          // taken -> 18
        dut.imem.memory[17] = ENC_I(OP_SW,   4'd3,  4'd0, 9);          // poison: MEM[9] must remain 0
        dut.imem.memory[18] = ENC_I(OP_BNE,  4'd1,  4'd1, 2);          // not taken
        dut.imem.memory[19] = ENC_I(OP_SW,   4'd3,  4'd0, 4);          // not-taken marker MEM[4]=12
        dut.imem.memory[20] = ENC_I(OP_BNE,  4'd2,  4'd1, 2);          // taken -> 22
        dut.imem.memory[21] = ENC_I(OP_SW,   4'd3,  4'd0, 10);         // poison: MEM[10] must remain 0
        dut.imem.memory[22] = ENC_I(OP_BEQ,  4'd2,  4'd1, 2);          // not taken
        dut.imem.memory[23] = ENC_I(OP_SW,   4'd3,  4'd0, 5);          // not-taken marker MEM[5]=12

        dut.imem.memory[24] = ENC_J(OP_J, 2);                           // J +2 -> 26
        dut.imem.memory[25] = ENC_I(OP_SW, 4'd3, 4'd0, 11);            // poison: MEM[11] must remain 0
        dut.imem.memory[26] = ENC_J(OP_JAL, 6);                         // JAL +6 -> 32, R14=27
        dut.imem.memory[27] = ENC_I(OP_ADDI, 4'd15, 4'd0, 42);         // JR return point
        dut.imem.memory[28] = ENC_I(OP_SW, 4'd12, 4'd0, 3);            // prove subroutine set R12=1
        dut.imem.memory[29] = ENC_J(OP_J, 6);                           // continue -> 35
        dut.imem.memory[30] = 32'b0;                                   // filler
        dut.imem.memory[31] = 32'b0;                                   // filler
        dut.imem.memory[32] = ENC_I(OP_ADDI, 4'd12, 4'd0, 1);          // subroutine body
        dut.imem.memory[33] = ENC_R(OP_JR, 4'd0, 4'd14, 4'd0);         // JR R14 -> 27
        dut.imem.memory[34] = 32'b0;                                   // filler

        dut.imem.memory[35] = ENC_I(OP_LB,   4'd13, 4'd0, 1);          // R13 = signext(MEM[1][7:0])
        dut.imem.memory[36] = ENC_I(OP_SWAP, 4'd3,  4'd0, 2);          // R3 <-> MEM[2]

        // Negative-immediate / negative-offset loop:
        // first pass: R4 becomes 0 and BEQ -1 is taken back to PC=38;
        // second pass: R4 becomes FFFFFFFF and the same BEQ is not taken.
        dut.imem.memory[37] = ENC_I(OP_ADDI, 4'd4, 4'd0, 1);           // R4 = 1
        dut.imem.memory[38] = ENC_I(OP_ADDI, 4'd4, 4'd4, -1);          // R4 = R4 - 1
        dut.imem.memory[39] = ENC_I(OP_BEQ,  4'd4, 4'd0, -1);          // target = 38 when equal
        dut.imem.memory[40] = ENC_I(OP_SW,   4'd4, 4'd0, 6);           // MEM[6] = FFFFFFFF

        // Zero-extension discriminators. If either immediate is sign-extended
        // incorrectly, the stored result differs from 00020000.
        dut.imem.memory[41] = ENC_I(OP_ORI,  4'd12, 4'd0, 18'h20000);  // R12 = 00020000
        dut.imem.memory[42] = ENC_I(OP_SW,   4'd12, 4'd0, 7);          // MEM[7] = 00020000
        dut.imem.memory[43] = ENC_I(OP_ANDI, 4'd12, 4'd4, 18'h20000);  // FFFFFFFF & 00020000
        dut.imem.memory[44] = ENC_I(OP_SW,   4'd12, 4'd0, 8);          // MEM[8] = 00020000

        dut.imem.memory[45] = ENC_I(OP_ADDI, 4'd0, 4'd0, 123);         // attempted write to R0
        dut.imem.memory[46] = ENC_J(OP_J, 0);                           // halt-like self-loop

        // Keep reset active for two rising edges.
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // 42 useful dynamic instructions require about 160 processor cycles;
        // 240 leaves ample margin and then remains in the PC=46 self-loop.
        repeat (240) @(posedge clk);

        $display("\n================ FINAL REGISTER CHECKS ================");
        CHECK_REG(0,  32'h00000000);  // proves attempted R0 write was ignored
        CHECK_REG(1,  32'h00000005);
        CHECK_REG(2,  32'h00000007);
        CHECK_REG(3,  32'h00000064);  // SWAP received old MEM[2] = 100
        CHECK_REG(4,  32'hFFFFFFFF);  // negative ADDI / negative BEQ loop
        CHECK_REG(5,  32'h00000005);
        CHECK_REG(6,  32'h00000007);
        CHECK_REG(7,  32'h00000002);
        CHECK_REG(8,  32'hFFFFFFF8);
        CHECK_REG(9,  32'h00000021);  // 33: shift hardware must use only [4:0]
        CHECK_REG(10, 32'h0000000A);
        CHECK_REG(11, 32'h7FFFFFFC);
        CHECK_REG(12, 32'h00020000);  // final ANDI zero-extension discriminator
        CHECK_REG(13, 32'hFFFFFF80);  // Lb sign extension
        CHECK_REG(14, 32'h0000001B);  // JAL return address = 27
        CHECK_REG(15, 32'h0000002A);  // proves JR return reached PC=27

        $display("\n================ FINAL MEMORY CHECKS ==================");
        CHECK_MEM(0,  32'h0000000C);  // SW/LW
        CHECK_MEM(1,  32'h00000080);  // Lb source word
        CHECK_MEM(2,  32'h0000000C);  // SWAP new memory value
        CHECK_MEM(3,  32'h00000001);  // JAL subroutine result observed after JR return
        CHECK_MEM(4,  32'h0000000C);  // BNE not-taken marker
        CHECK_MEM(5,  32'h0000000C);  // BEQ not-taken marker
        CHECK_MEM(6,  32'hFFFFFFFF);  // negative immediate/offset result
        CHECK_MEM(7,  32'h00020000);  // ORI zero-extension result
        CHECK_MEM(8,  32'h00020000);  // ANDI zero-extension result
        CHECK_MEM(9,  32'h00000000);  // BEQ taken skipped poison store
        CHECK_MEM(10, 32'h00000000);  // BNE taken skipped poison store
        CHECK_MEM(11, 32'h00000000);  // J skipped poison store

        $display("\n================ OPCODE COVERAGE ======================");
        for (i = 0; i <= 20; i = i + 1)
            CHECK_OPCODE_SEEN(i);

        $display("\n================ BRANCH OUTCOME COVERAGE =============");
        CHECK_FLAG(beq_taken_seen,     "BEQ taken");
        CHECK_FLAG(beq_not_taken_seen, "BEQ not taken");
        CHECK_FLAG(bne_taken_seen,     "BNE taken");
        CHECK_FLAG(bne_not_taken_seen, "BNE not taken");

        if (errors == 0)
            $display("\nFINAL PROCESSOR TEST: PASS");
        else
            $display("\nFINAL PROCESSOR TEST: FAIL (%0d errors)", errors);

        $finish;
    end

endmodule
