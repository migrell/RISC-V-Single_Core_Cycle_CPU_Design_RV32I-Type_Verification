`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic [ 1:0] RFWDSrcMuxSel,  // 1비트에서 2비트로 수정
    input  logic        branch,
    input  logic        aluASelect,
    input  logic        isJALR,
    output logic [31:0] instrMemAddr,
    input  logic [31:0] instrCode,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData,
    input  logic [31:0] dataRData,
    output logic [31:0] RFWDSrcMuxOut
);

    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCOutData;
    logic btaken, PCSrcMuxSel;
    logic [31:0] immExt, aluSrcMuxOut;
    logic [31:0] PC_Imm_AdderResult, PC_4_AdderResult, PCSrcMuxOut;
    logic [31:0] JALR_Target;

    always_comb begin
        instrMemAddr = PCOutData;
        dataAddr     = aluResult;
        dataWData    = RFData2;
        PCSrcMuxSel  = btaken & branch;
        JALR_Target  = RFData1 + immExt;
    end

    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(RFWDSrcMuxOut),
        .RData1(RFData1),
        .RData2(RFData2)
    );

    logic [31:0] aluAInput;
    always_comb begin
        aluAInput = aluASelect ? PCOutData : RFData1;
    end

    mux_2x1 U_ALUSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (RFData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

    // RFWDSrcMux도 이제 2비트 선택 신호를 처리할 수 있게 수정
    always_comb begin
        case (RFWDSrcMuxSel)
            2'b00:    RFWDSrcMuxOut = aluResult;
            2'b01:    RFWDSrcMuxOut = dataRData;
            default:  RFWDSrcMuxOut = aluResult;
        endcase
    end

    alu U_ALU (
        .aluControl(aluControl),
        .a(aluAInput),
        .b(aluSrcMuxOut),
        .btaken(btaken),
        .result(aluResult)
    );

    extend U_ImmExtend (
        .instrCode(instrCode),
        .immExt(immExt)
    );

    adder U_PC_Imm_Adder (
        .a(immExt),
        .b(PCOutData),
        .y(PC_Imm_AdderResult)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    logic [31:0] branchTarget;
    mux_2x1 U_JALRTargetMux (
        .sel(isJALR),
        .x0(PC_Imm_AdderResult),
        .x1(JALR_Target),
        .y(branchTarget)
    );

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0(PC_4_AdderResult),
        .x1(branchTarget),
        .y(PCSrcMuxOut)
    );

    register U_PC (
        .clk(clk),
        .reset(reset),
        .d(PCSrcMuxOut),
        .q(PCOutData)
    );

endmodule

module alu (
    input  logic [3:0]  aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);
    always_comb begin
        case (aluControl)
            `ADD: begin
                // LUI: a = 0, result = b << 12
                // AUIPC: a = PC, result = PC + (b << 12)
                result = (a == 32'b0) ? (b << 12) : (a + (b << 12));
            end
            `SUB:    result = a - b;
            `SLL:    result = a << b[4:0];
            `SRL:    result = a >> b[4:0];
            `SRA:    result = $signed(a) >>> b[4:0];
            `SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            `XOR:    result = a ^ b;
            `OR:     result = a | b;
            `AND:    result = a & b;
            `JAL:    result = a + 32'd4;  // JAL: rd = PC + 4, a = PC
            `JALR:   result = a + 32'd4;  // JALR: rd = PC + 4, a = PC
            default: result = 32'd0;
        endcase
    end

    always_comb begin : branch_processor
        btaken = 1'b0; // 기본값
        
        case (aluControl)
            `JAL: begin
                btaken = 1'b1; // JAL은 항상 분기 실행
            end
            `JALR: begin
                btaken = 1'b1; // JALR은 항상 분기 실행
            end
            default: begin
                case (aluControl[2:0])
                    `BEQ:  btaken = (a == b);
                    `BNE:  btaken = (a != b);
                    `BLT:  btaken = ($signed(a) < $signed(b));
                    `BGE:  btaken = ($signed(a) >= $signed(b));
                    `BLTU: btaken = (a < b);
                    `BGEU: btaken = (a >= b);
                    default: btaken = 1'b0;
                endcase
            end
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    always_comb begin
        y = a + b;
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RAddr1,
    input  logic [ 4:0] RAddr2,
    input  logic [ 4:0] WAddr,
    input  logic [31:0] WData,
    output logic [31:0] RData1,
    output logic [31:0] RData2
);
    logic [31:0] RegFile[0:2**5-1];
    initial begin
        for (int i = 0; i < 32; i++) begin
            RegFile[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    always_comb begin
        RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
        RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
    end
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        case (sel)
            1'b0:    y = x0;
            1'b1:    y = x1;
            default: y = 32'bx;
        endcase
    end
endmodule

module extend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3  = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S:
                immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_I: begin
                case (func3)
                    3'b001:  immExt = {27'b0, instrCode[24:20]};       // SLLI
                    3'b101:  immExt = {27'b0, instrCode[24:20]};       // SRLI/SRAI
                    3'b011:  immExt = {20'b0, instrCode[31:20]};       // SLTIU
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B: begin
                immExt = {
                    {20{instrCode[31]}},
                    instrCode[7],
                    instrCode[30:25],
                    instrCode[11:8],
                    1'b0
                };
            end
            `OP_TYPE_J: begin
                immExt = {
                    {12{instrCode[31]}},
                    instrCode[19:12],
                    instrCode[20],
                    instrCode[30:21],
                    1'b0
                };
            end
            `OP_TYPE_JALR: begin
                immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            end
            default: immExt = 32'bx;
        endcase
    end
endmodule