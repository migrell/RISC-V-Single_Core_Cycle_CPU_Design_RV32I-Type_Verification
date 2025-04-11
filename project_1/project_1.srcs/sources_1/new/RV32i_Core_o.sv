`include "defines.sv"

module RV32I_Core (
    input  logic        clk,
    input  logic        reset,
    output logic        dataWe,         // RAM 모듈의 we에 연결 필요
    output logic [31:0] instrMemAddr,   // ROM 모듈의 addr에 연결 필요
    input  logic [31:0] instrCode,      // ROM 모듈의 dout에서 입력
    output logic [31:0] dataAddr,       // RAM 모듈의 addr에 연결 필요
    output logic [31:0] dataWData,      // RAM 모듈의 wData에 연결 필요
    input  logic [31:0] dataRData       // RAM 모듈의 rData에서 입력
);

    // 내부 신호 (Control Unit -> Data Path)
    logic isJAL_internal;
    logic        regFileWe;      // 내부에서만 사용, 외부로 연결 불필요
    logic [ 3:0] aluControl;     // 내부에서만 사용, 외부로 연결 불필요
    logic        aluSrcMuxSel;   // 내부에서만 사용, 외부로 연결 불필요
    logic [ 1:0] RFWDSrcMuxSel;  // 내부에서만 사용, 외부로 연결 불필요
    logic        branch;         // 내부에서만 사용, 외부로 연결 불필요
    logic        aluASelect;     // 내부에서만 사용, 외부로 연결 불필요
    logic        LUType;         // 내부에서만 사용, 외부로 연결 불필요
    logic        AUType;         // 내부에서만 사용, 외부로 연결 불필요
    logic        isJALR;         // 내부에서만 사용, 외부로 연결 불필요

    // Control Unit
    ControlUnit U_CU (
        .instrCode(instrCode),
        .regFileWe(regFileWe),
        .aluControl(aluControl),
        .aluSrcMuxSel(aluSrcMuxSel),
        .dataWe(dataWe),
        .RFWDSrcMuxSel(RFWDSrcMuxSel),
        .branch(branch),
        .aluASelect(aluASelect),
        .LUType(LUType),
        .AUType(AUType),
        .isJAL(isJAL_internal),
        .isJALR(isJALR)
    );

    // Data Path - 이제 전체 2비트 신호를 전달
    DataPath U_DP (
        .clk(clk),
        .reset(reset),
        .regFileWe(regFileWe),
        .aluControl(aluControl),
        .aluSrcMuxSel(aluSrcMuxSel),
        .RFWDSrcMuxSel(RFWDSrcMuxSel),  // 전체 2비트 전달 
        .branch(branch),
        .aluASelect(aluASelect),
        .isJALR(isJALR),
        .instrMemAddr(instrMemAddr),
        .instrCode(instrCode),
        .dataAddr(dataAddr),
        .dataWData(dataWData),
        .dataRData(dataRData),
        .RFWDSrcMuxOut()  // 필요 없으면 연결 안함
    );

endmodule