`timescale 1ns / 1ps

module ram (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:9];

    // 초기값 설정
    initial begin
        for (int i = 0; i < 10; i++) begin
            mem[i] = 32'hAAAA0000 + i;  // 쉽게 구분할 수 있는 초기값 설정
        end
    end

    always_ff @( posedge clk ) begin
        if (we) mem[addr[31:2]] <= wData;
    end

    assign rData = mem[addr[31:2]];
endmodule
// `timescale 1ns / 1ps

// module ram (
//     input  logic        clk,
//     input  logic        we,
//     input  logic [31:0] addr,
//     input  logic [31:0] wData,
//     output logic [31:0] rData
// );
//     logic [31:0] mem[0:9];

//     always_ff @( posedge clk ) begin
//         if (we) mem[addr[31:2]] <= wData;
//     end

//     assign rData = mem[addr[31:2]];
// endmodule
