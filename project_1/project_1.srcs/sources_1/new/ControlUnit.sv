`timescale 1ns/1ps

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
    // 모듈 내에 필요한 매크로 정의 직접 포함
    // OPCODE 정의
    localparam OP_TYPE_R    = 7'b0110011;
    localparam OP_TYPE_I    = 7'b0010011;
    localparam OP_TYPE_S    = 7'b0100011;
    localparam OP_TYPE_L    = 7'b0000011;
    localparam OP_TYPE_B    = 7'b1100011;
    localparam OP_TYPE_LU   = 7'b0110111;
    localparam OP_TYPE_AU   = 7'b0010111;
    localparam OP_TYPE_J    = 7'b1101111;  // JAL
    localparam OP_TYPE_JALR = 7'b1100111;  // JALR

    // ALU 연산 코드
    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b1000;
    localparam SLL  = 4'b0001;
    localparam SLT  = 4'b0010;
    localparam SLTU = 4'b0011;
    localparam XOR  = 4'b0100;
    localparam SRL  = 4'b0101;
    localparam SRA  = 4'b1101;
    localparam OR   = 4'b0110;
    localparam AND  = 4'b0111;
    localparam JAL  = 4'b1010;
    localparam JALR = 4'b1011;

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

    assign isJAL  = (opcode == OP_TYPE_J);
    assign isJALR = (opcode == OP_TYPE_JALR);
    assign LUType = (opcode == OP_TYPE_LU);
    assign AUType = (opcode == OP_TYPE_AU);

    always_comb begin
        signals = 7'b0;
        case (opcode)
            OP_TYPE_R:    signals = 7'b1_0_0_00_0_0;
            OP_TYPE_S:    signals = 7'b0_1_1_00_0_0;
            OP_TYPE_L:    signals = 7'b1_1_0_01_0_0;
            OP_TYPE_I:    signals = 7'b1_1_0_00_0_0;
            OP_TYPE_B:    signals = 7'b0_0_0_00_1_0;
            OP_TYPE_LU:   signals = 7'b1_1_0_00_0_1;
            OP_TYPE_AU:   signals = 7'b1_1_0_00_0_1;
            OP_TYPE_J:    signals = 7'b1_0_0_00_1_1; // JAL - branch 활성화
            OP_TYPE_JALR: signals = 7'b1_0_0_00_1_1; // JALR - branch 활성화
            default:      signals = 7'b0_0_0_00_0_0;
        endcase
    end

    always_comb begin
        case (opcode)
            OP_TYPE_R:    aluControl = operators;
            OP_TYPE_S:    aluControl = ADD;
            OP_TYPE_L:    aluControl = ADD;
            OP_TYPE_I:    aluControl = (operators == 4'b1101) ? operators : {1'b0, operators[2:0]};
            OP_TYPE_B:    aluControl = {1'b0, operators[2:0]};
            OP_TYPE_LU:   aluControl = ADD;   // 명시적으로 LUI에 대한 제어 신호 설정
            OP_TYPE_AU:   aluControl = ADD;   // 명시적으로 AUIPC에 대한 제어 신호 설정
            OP_TYPE_J:    aluControl = JAL;   // JAL 명령어
            OP_TYPE_JALR: aluControl = JALR;  // JALR 명령어
            default:      aluControl = 4'bxxxx;
        endcase
    end

endmodule
// `include "defines.sv"

// module ControlUnit (
//     input  logic [31:0] instrCode,
//     output logic        regFileWe,
//     output logic [ 3:0] aluControl,
//     output logic        aluSrcMuxSel,
//     output logic        dataWe,
//     output logic [ 1:0] RFWDSrcMuxSel,
//     output logic        branch,
//     output logic        aluASelect,
//     output logic        LUType,
//     output logic        AUType,
//     output logic        isJAL,
//     output logic        isJALR
// );

//     wire [6:0] opcode = instrCode[6:0];
//     wire [3:0] operators = { instrCode[30], instrCode[14:12] };

//     logic [6:0] signals;
//     assign {
//         regFileWe,         // [6]
//         aluSrcMuxSel,      // [5]
//         dataWe,            // [4]
//         RFWDSrcMuxSel,     // [3:2]
//         branch,            // [1]
//         aluASelect         // [0]
//     } = signals;

//     assign isJAL  = (opcode == `OP_TYPE_J);
//     assign isJALR = (opcode == `OP_TYPE_JALR);

//     always_comb begin
//         signals = 7'b0;
//         case (opcode)
//             `OP_TYPE_R:    signals = 7'b1_0_0_00_0_0;
//             `OP_TYPE_S:    signals = 7'b0_1_1_00_0_0;
//             `OP_TYPE_L:    signals = 7'b1_1_0_01_0_0;
//             `OP_TYPE_I:    signals = 7'b1_1_0_00_0_0;
//             `OP_TYPE_B:    signals = 7'b0_0_0_00_1_0;
//             `OP_TYPE_LU:   signals = 7'b1_1_0_00_0_1;
//             `OP_TYPE_AU:   signals = 7'b1_1_0_00_0_1;
//             `OP_TYPE_J:    signals = 7'b1_0_0_00_1_1; // JAL - branch 활성화
//             `OP_TYPE_JALR: signals = 7'b1_0_0_00_1_1; // JALR - branch 활성화
//             default:       signals = 7'b0_0_0_00_0_0;
//         endcase
//     end

//     always_comb begin
//         case (opcode)
//             `OP_TYPE_R:    aluControl = operators;
//             `OP_TYPE_S:    aluControl = `ADD;
//             `OP_TYPE_L:    aluControl = `ADD;
//             `OP_TYPE_LU:   aluControl = `ADD;
//             `OP_TYPE_AU:   aluControl = `ADD;
//             `OP_TYPE_I:    aluControl = (operators == 4'b1101) ? operators : {1'b0, operators[2:0]};
//             `OP_TYPE_B:    aluControl = {1'b0, operators[2:0]};
//             `OP_TYPE_J:    aluControl = `JAL;  // JAL 명령어
//             `OP_TYPE_JALR: aluControl = `JALR; // JALR 명령어
//             default:       aluControl = 4'bxxxx;
//         endcase
//     end

// endmodule