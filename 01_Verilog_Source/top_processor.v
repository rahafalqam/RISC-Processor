module top_processor (
    input  wire        clk,
    input  wire        rst,

    // Simulation/debug outputs. They do not change the datapath behavior.
    output wire [31:0] debug_PC,
    output wire [31:0] debug_IR,
    output wire [31:0] debug_ALUOut,
    output wire [31:0] debug_MDR,
    output wire [4:0]  debug_state,
    output wire        debug_RegWrite,
    output wire        debug_MemWrite,
    output wire [3:0]  debug_WriteReg,
    output wire [31:0] debug_WriteData,
    output wire [31:0] debug_MemAddress,
    output wire [31:0] debug_MemWriteData
);

    // -------------------------
    // Control signals
    // -------------------------
    wire       RegWrite;
    wire       MemRead;
    wire       MemWrite;
    wire [1:0] MemToReg;
    wire       ALUSrc;
    wire [3:0] ALUOp;
    wire       ExtOp;
    wire [1:0] PCSrc;
    wire       PCWrite;
    wire       IRWrite;
    wire [1:0] RegDst;
    wire       OldPCWrite;
    wire       AWrite;
    wire       BWrite;
    wire       ALUOutWrite;
    wire       MDRWrite;
    wire       LB;

    // -------------------------
    // Datapath wires/registers
    // -------------------------
    wire [31:0] PC;
    wire [31:0] instruction;

    wire [31:0] IR;
    wire [31:0] A;
    wire [31:0] B;
    wire [31:0] ALUOut;
    wire [31:0] MDR;
    wire [31:0] OldPC;

    wire [5:0] opcode;
    assign opcode = IR[31:26];

    // Register addresses according to the project's instruction formats.
    // Rs is always [21:18]. R-type Rt is [17:14], I-type Rt is [25:22].
    wire [3:0] rs_addr;
    wire [3:0] rt_addr;
    assign rs_addr = IR[21:18];
    assign rt_addr = (opcode <= 6'd9) ? IR[17:14] : IR[25:22];

    wire [31:0] ReadData1;
    wire [31:0] ReadData2;

    wire [3:0] write_reg;
    assign write_reg = (RegDst == 2'b01) ? 4'd14 : IR[25:22];

    wire [31:0] write_data;
    assign write_data = (MemToReg == 2'b01) ? MDR :
                        (MemToReg == 2'b10) ? (OldPC + 32'd1) :
                                              ALUOut;

    // Immediate extension for 18-bit I-type immediate
    wire [31:0] ExtImm;

    // Separate 26-bit signed extension for J/JAL offset
    wire [31:0] JumpExt;
    assign JumpExt = {{6{IR[25]}}, IR[25:0]};

    // ALU datapath
    wire [31:0] ALU_B;
    wire [31:0] ALU_Result;
    wire        Zero;
    assign ALU_B = ALUSrc ? ExtImm : B;

    // Data memory
    wire [31:0] MemReadData;

    // Next-PC logic from Partner 2 is used for branch, J/JAL and JR.
    // For sequential execution, we deliberately use current PC+1 here.
    // This avoids the OldPC+1 issue in the original next_pc_logic case 00.
    wire [31:0] pc_offset;
    wire [31:0] partner_nextPC;
    wire [31:0] selected_nextPC;

    assign pc_offset = (PCSrc == 2'b10) ? JumpExt : ExtImm;
    assign selected_nextPC = (PCSrc == 2'b00) ? (PC + 32'd1) : partner_nextPC;

    // -------------------------
    // Control Unit - Partner 3
    // -------------------------
    control_unit cu (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .Zero(Zero),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemToReg(MemToReg),
        .ALUSrc(ALUSrc),
        .ALUOp(ALUOp),
        .ExtOp(ExtOp),
        .PCSrc(PCSrc),
        .PCWrite(PCWrite),
        .IRWrite(IRWrite),
        .RegDst(RegDst),
        .OldPCWrite(OldPCWrite),
        .AWrite(AWrite),
        .BWrite(BWrite),
        .ALUOutWrite(ALUOutWrite),
        .MDRWrite(MDRWrite),
        .LB(LB),
        .state_debug(debug_state)
    );

    // -------------------------
    // Partner 2 modules
    // -------------------------
    program_counter pc_unit (
        .clk(clk),
        .rst(rst),
        .PCWrite(PCWrite),
        .nextPC(selected_nextPC),
        .PC(PC)
    );

    instruction_memory imem (
        .address(PC),
        .instruction(instruction)
    );

    temporary_registers temps (
        .clk(clk),
        .rst(rst),
        .IRWrite(IRWrite),
        .AWrite(AWrite),
        .BWrite(BWrite),
        .ALUOutWrite(ALUOutWrite),
        .MDRWrite(MDRWrite),
        .OldPCWrite(OldPCWrite),
        .instruction(instruction),
        .regA(ReadData1),
        .regB(ReadData2),
        .alu_result(ALU_Result),
        .mem_data(MemReadData),
        .PC(PC),
        .IR(IR),
        .A(A),
        .B(B),
        .ALUOut(ALUOut),
        .MDR(MDR),
        .OldPC(OldPC)
    );

    data_memory dmem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .LB(LB),
        .address(ALUOut),
        .WriteData(B),
        .ReadData(MemReadData)
    );

    next_pc_logic npc (
        .OldPC(OldPC),
        .offset(pc_offset),
        .rs_value(A),
        .PCSrc(PCSrc),
        .nextPC(partner_nextPC)
    );

    // -------------------------
    // Partner 1 modules
    // -------------------------
    register_file rf (
        .clk(clk),
        .rst(rst),
        .RegWrite(RegWrite),
        .Rs(rs_addr),
        .Rt(rt_addr),
        .Rd(write_reg),
        .WriteData(write_data),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    imm_extender imm_ext (
        .Imm(IR[17:0]),
        .ExtOp(ExtOp),
        .ExtImm(ExtImm)
    );

    alu alu_unit (
        .A(A),
        .B(ALU_B),
        .ALUOp(ALUOp),
        .Result(ALU_Result),
        .Zero(Zero)
    );

    // -------------------------
    // Debug assignments
    // -------------------------
    assign debug_PC           = PC;
    assign debug_IR           = IR;
    assign debug_ALUOut       = ALUOut;
    assign debug_MDR          = MDR;
    assign debug_RegWrite     = RegWrite;
    assign debug_MemWrite     = MemWrite;
    assign debug_WriteReg     = write_reg;
    assign debug_WriteData    = write_data;
    assign debug_MemAddress   = ALUOut;
    assign debug_MemWriteData = B;

endmodule
