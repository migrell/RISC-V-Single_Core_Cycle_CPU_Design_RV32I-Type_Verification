`include "defines.sv"

module MCU (
    input logic clk,
    input logic reset
);

    // 데이터 경로 신호
    logic [31:0] instrMemAddr;
    logic [31:0] instrCode;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    // 제어 신호들 - Core 내부에서만 사용되므로 연결할 필요 없음
    logic        regFileWe;
    logic [ 3:0] aluControl;
    logic        aluSrcMuxSel;
    logic        dataWe;
    logic [ 1:0] RFWDSrcMuxSel;
    logic        branch;
    logic        aluASelect;
    logic        LUType;
    logic        AUType;
    logic        isJALR;

    // RV32I_Core 모듈 직접 연결
    RV32I_Core Core (
        .clk(clk),
        .reset(reset),
        // 제어 신호들은 Core 내부에서만 사용되므로 open으로 두기
        .dataWe(dataWe),  // RAM의 we 신호에 필요
        // 데이터 경로 신호들
        .instrMemAddr(instrMemAddr),
        .instrCode(instrCode),
        .dataAddr(dataAddr),
        .dataWData(dataWData),
        .dataRData(dataRData)
    );

    // 명령어 메모리 연결 - 수정: addr 포트의 비트 수를 맞춤 (10비트)
    rom U_rom (
        .addr(instrMemAddr[11:2]),  // 10비트만 연결 (rom 모듈의 addr는 9:0으로 10비트)
        .dout(instrCode)
    );

    // 데이터 메모리 연결
    ram U_ram (
        .clk(clk),
        .we(dataWe),
        .addr(dataAddr),  // 32비트 전체 연결
        .wData(dataWData),
        .rData(dataRData)
    );
endmodule