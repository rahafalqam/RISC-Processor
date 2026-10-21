module control_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [5:0] opcode,
    input  wire       Zero,

    output reg        RegWrite,
    output reg        MemRead,
    output reg        MemWrite,
    output reg  [1:0] MemToReg,   // 00=ALUOut, 01=MDR, 10=OldPC+1
    output reg        ALUSrc,     // 0=B register, 1=ExtImm
    output reg  [3:0] ALUOp,
    output reg        ExtOp,      // 1=sign extend, 0=zero extend
    output reg  [1:0] PCSrc,      // 00=sequential, 01=branch, 10=J/JAL, 11=JR
    output reg        PCWrite,
    output reg        IRWrite,
    output reg  [1:0] RegDst,     // 00=IR[25:22], 01=R14
    output reg        OldPCWrite,
    output reg        AWrite,
    output reg        BWrite,
    output reg        ALUOutWrite,
    output reg        MDRWrite,
    output reg        LB,

    output wire [4:0] state_debug
);

    // Opcodes from the project instruction table
    localparam [5:0]
        OP_ADD  = 6'd0,
        OP_SUB  = 6'd1,
        OP_AND  = 6'd2,
        OP_OR   = 6'd3,
        OP_XOR  = 6'd4,
        OP_NOR  = 6'd5,
        OP_SLL  = 6'd6,
        OP_SRL  = 6'd7,
        OP_CLR  = 6'd8,
        OP_JR   = 6'd9,
        OP_ADDI = 6'd10,
        OP_ANDI = 6'd11,
        OP_ORI  = 6'd12,
        OP_LW   = 6'd13,
        OP_SW   = 6'd14,
        OP_SWAP = 6'd15,
        OP_BEQ  = 6'd16,
        OP_BNE  = 6'd17,
        OP_J    = 6'd18,
        OP_JAL  = 6'd19,
        OP_LB   = 6'd20;

    // ALU encoding agreed with Partner 1
    localparam [3:0]
        ALU_ADD = 4'b0000,
        ALU_SUB = 4'b0001,
        ALU_AND = 4'b0010,
        ALU_OR  = 4'b0011,
        ALU_XOR = 4'b0100,
        ALU_NOR = 4'b0101,
        ALU_SLL = 4'b0110,
        ALU_SRL = 4'b0111,
        ALU_CLR = 4'b1000;

    localparam [4:0]
        ST_IF          = 5'd0,
        ST_ID          = 5'd1,
        ST_R_EX        = 5'd2,
        ST_R_WB        = 5'd3,
        ST_I_EX        = 5'd4,
        ST_I_WB        = 5'd5,
        ST_ADDR_EX     = 5'd6,
        ST_MEM_READ    = 5'd7,
        ST_MEM_WB      = 5'd8,
        ST_MEM_WRITE   = 5'd9,
        ST_BRANCH      = 5'd10,
        ST_JUMP        = 5'd11,
        ST_JAL         = 5'd12,
        ST_JR          = 5'd13,
        ST_SWAP_READ   = 5'd14,
        ST_SWAP_COMMIT = 5'd15;

    reg [4:0] state, next_state;

    assign state_debug = state;

    // State register
    always @(posedge clk) begin
        if (rst)
            state <= ST_IF;
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = ST_IF;

        case (state)
            ST_IF: begin
                next_state = ST_ID;
            end

            ST_ID: begin
                case (opcode)
                    OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR,
                    OP_NOR, OP_SLL, OP_SRL, OP_CLR:
                        next_state = ST_R_EX;

                    OP_JR:
                        next_state = ST_JR;

                    OP_ADDI, OP_ANDI, OP_ORI:
                        next_state = ST_I_EX;

                    OP_LW, OP_SW, OP_SWAP, OP_LB:
                        next_state = ST_ADDR_EX;

                    OP_BEQ, OP_BNE:
                        next_state = ST_BRANCH;

                    OP_J:
                        next_state = ST_JUMP;

                    OP_JAL:
                        next_state = ST_JAL;

                    default:
                        next_state = ST_IF;
                endcase
            end

            ST_R_EX:
                next_state = ST_R_WB;

            ST_R_WB:
                next_state = ST_IF;

            ST_I_EX:
                next_state = ST_I_WB;

            ST_I_WB:
                next_state = ST_IF;

            ST_ADDR_EX: begin
                case (opcode)
                    OP_LW, OP_LB: next_state = ST_MEM_READ;
                    OP_SW:        next_state = ST_MEM_WRITE;
                    OP_SWAP:      next_state = ST_SWAP_READ;
                    default:      next_state = ST_IF;
                endcase
            end

            ST_MEM_READ:
                next_state = ST_MEM_WB;

            ST_MEM_WB:
                next_state = ST_IF;

            ST_MEM_WRITE:
                next_state = ST_IF;

            ST_BRANCH:
                next_state = ST_IF;

            ST_JUMP:
                next_state = ST_IF;

            ST_JAL:
                next_state = ST_IF;

            ST_JR:
                next_state = ST_IF;

            ST_SWAP_READ:
                next_state = ST_SWAP_COMMIT;

            ST_SWAP_COMMIT:
                next_state = ST_IF;

            default:
                next_state = ST_IF;
        endcase
    end

    // Output/control logic
    always @(*) begin
        // Safe defaults
        RegWrite    = 1'b0;
        MemRead     = 1'b0;
        MemWrite    = 1'b0;
        MemToReg    = 2'b00;
        ALUSrc      = 1'b0;
        ALUOp       = ALU_ADD;
        ExtOp       = 1'b1;
        PCSrc       = 2'b00;
        PCWrite     = 1'b0;
        IRWrite     = 1'b0;
        RegDst      = 2'b00;
        OldPCWrite  = 1'b0;
        AWrite      = 1'b0;
        BWrite      = 1'b0;
        ALUOutWrite = 1'b0;
        MDRWrite    = 1'b0;
        LB           = 1'b0;

        case (state)
            // OldPC <- PC, IR <- IMem[PC], PC <- PC+1
            ST_IF: begin
                OldPCWrite = 1'b1;
                IRWrite    = 1'b1;
                PCWrite    = 1'b1;
                PCSrc      = 2'b00;
            end

            // A <- Reg(Rs), B <- Reg(Rt)
            ST_ID: begin
                AWrite = 1'b1;
                BWrite = 1'b1;
            end

            // R-type ALU execution. ALUOp matches opcode[3:0].
            ST_R_EX: begin
                ALUSrc      = 1'b0;
                ALUOutWrite = 1'b1;
                case (opcode)
                    OP_ADD: ALUOp = ALU_ADD;
                    OP_SUB: ALUOp = ALU_SUB;
                    OP_AND: ALUOp = ALU_AND;
                    OP_OR:  ALUOp = ALU_OR;
                    OP_XOR: ALUOp = ALU_XOR;
                    OP_NOR: ALUOp = ALU_NOR;
                    OP_SLL: ALUOp = ALU_SLL;
                    OP_SRL: ALUOp = ALU_SRL;
                    OP_CLR: ALUOp = ALU_CLR;
                    default: ALUOp = ALU_ADD;
                endcase
            end

            ST_R_WB: begin
                RegWrite = 1'b1;
                RegDst   = 2'b00;
                MemToReg = 2'b00;
            end

            // ADDI / ANDI / ORI
            ST_I_EX: begin
                ALUSrc      = 1'b1;
                ALUOutWrite = 1'b1;

                case (opcode)
                    OP_ADDI: begin
                        ALUOp = ALU_ADD;
                        ExtOp = 1'b1;
                    end
                    OP_ANDI: begin
                        ALUOp = ALU_AND;
                        ExtOp = 1'b0;
                    end
                    OP_ORI: begin
                        ALUOp = ALU_OR;
                        ExtOp = 1'b0;
                    end
                    default: begin
                        ALUOp = ALU_ADD;
                        ExtOp = 1'b1;
                    end
                endcase
            end

            ST_I_WB: begin
                RegWrite = 1'b1;
                RegDst   = 2'b00;
                MemToReg = 2'b00;
            end

            // Effective address = Reg(Rs) + sign_extended Imm
            ST_ADDR_EX: begin
                ALUSrc      = 1'b1;
                ALUOp       = ALU_ADD;
                ExtOp       = 1'b1;
                ALUOutWrite = 1'b1;
            end

            ST_MEM_READ: begin
                MemRead  = 1'b1;
                MDRWrite = 1'b1;
                LB       = (opcode == OP_LB);
            end

            ST_MEM_WB: begin
                RegWrite = 1'b1;
                RegDst   = 2'b00;
                MemToReg = 2'b01;
            end

            ST_MEM_WRITE: begin
                MemWrite = 1'b1;
            end

            // BEQ/BNE compare using SUB and Zero flag
            ST_BRANCH: begin
                ALUSrc  = 1'b0;
                ALUOp   = ALU_SUB;
                ExtOp   = 1'b1;
                PCSrc   = 2'b01;

                if ((opcode == OP_BEQ && Zero) ||
                    (opcode == OP_BNE && !Zero))
                    PCWrite = 1'b1;
            end

            ST_JUMP: begin
                PCSrc   = 2'b10;
                PCWrite = 1'b1;
            end

            // JAL: PC <- target and R14 <- OldPC+1 on same clock edge
            ST_JAL: begin
                PCSrc    = 2'b10;
                PCWrite  = 1'b1;
                RegWrite = 1'b1;
                RegDst   = 2'b01;
                MemToReg = 2'b10;
            end

            ST_JR: begin
                PCSrc   = 2'b11;
                PCWrite = 1'b1;
            end

            // SWAP: first capture old memory word in MDR
            ST_SWAP_READ: begin
                MemRead  = 1'b1;
                MDRWrite = 1'b1;
            end

            // Then write B to memory and old MDR value to Rt
            ST_SWAP_COMMIT: begin
                MemWrite = 1'b1;
                RegWrite = 1'b1;
                RegDst   = 2'b00;
                MemToReg = 2'b01;
            end

            default: begin
                // keep safe defaults
            end
        endcase
    end

endmodule
