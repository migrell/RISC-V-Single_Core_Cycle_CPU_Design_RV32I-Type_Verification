`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic [ 1:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        aluASelect,
    output logic        LUType,
    output logic        AUType,
    output logic        isJAL,
    output logic        isJALR
);

    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = { instrCode[30], instrCode[14:12] };

    logic [6:0] signals;
    assign {
        regFileWe,         // [6]
        aluSrcMuxSel,      // [5]
        dataWe,            // [4]
        RFWDSrcMuxSel,     // [3:2]
        branch,            // [1]
        aluASelect         // [0]
    } = signals;

    assign isJAL  = (opcode == `OP_TYPE_J);
    assign isJALR = (opcode == `OP_TYPE_JALR);

    always_comb begin
        signals = 7'b0;
        case (opcode)
            `OP_TYPE_R:    signals = 7'b1_0_0_00_0_0;
            `OP_TYPE_S:    signals = 7'b0_1_1_00_0_0;
            `OP_TYPE_L:    signals = 7'b1_1_0_01_0_0;
            `OP_TYPE_I:    signals = 7'b1_1_0_00_0_0;
            `OP_TYPE_B:    signals = 7'b0_0_0_00_1_0;
            `OP_TYPE_LU:   signals = 7'b1_1_0_00_0_1;
            `OP_TYPE_AU:   signals = 7'b1_1_0_00_0_1;
            `OP_TYPE_J:    signals = 7'b1_0_0_00_1_1; // JAL - branch 활성화
            `OP_TYPE_JALR: signals = 7'b1_0_0_00_1_1; // JALR - branch 활성화
            default:       signals = 7'b0_0_0_00_0_0;
        endcase
    end

    always_comb begin
        case (opcode)
            `OP_TYPE_R:    aluControl = operators;
            `OP_TYPE_S:    aluControl = `ADD;
            `OP_TYPE_L:    aluControl = `ADD;
            `OP_TYPE_LU:   aluControl = `ADD;
            `OP_TYPE_AU:   aluControl = `ADD;
            `OP_TYPE_I:    aluControl = (operators == 4'b1101) ? operators : {1'b0, operators[2:0]};
            `OP_TYPE_B:    aluControl = {1'b0, operators[2:0]};
            `OP_TYPE_J:    aluControl = `JAL;  // JAL 명령어
            `OP_TYPE_JALR: aluControl = `JALR; // JALR 명령어
            default:       aluControl = 4'bxxxx;
        endcase
    end

endmodule