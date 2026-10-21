		module next_pc_logic(
    input  [31:0] OldPC,
    input  [31:0] offset,
    input  [31:0] rs_value,
    input  [1:0] PCSrc,
    output reg [31:0] nextPC
);

always @(*) begin

    case(PCSrc)

        2'b00: begin
            // Normal execution
            nextPC = OldPC + 1;
        end

        2'b01: begin
            // BEQ
            nextPC = OldPC + offset;
        end

        2'b10: begin
            // J / JAL
            nextPC = OldPC + offset;
        end

        2'b11: begin
            // JR
            nextPC = rs_value;
        end

        default:
            nextPC = OldPC + 1;

    endcase

end

endmodule