`timescale 1ns / 1ps

module rom (
    input  logic [9:0]  addr,
    output logic [31:0] dout
);
    logic [31:0] rom[0:31];

    initial begin
        // R-Type 명령어 (OP_TYPE_R)
        rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1
        rom[2] = 32'b0000000_00001_00010_001_00110_0110011; // sll x6, x2, x1
        rom[3] = 32'b0000000_00001_00010_010_00111_0110011; // slt x7, x2, x1
        rom[4] = 32'b0000000_00001_00010_011_01000_0110011; // sltu x8, x2, x1
        rom[5] = 32'b0000000_00001_00010_100_01001_0110011; // xor x9, x2, x1
        rom[6] = 32'b0000000_00001_00010_101_01010_0110011; // srl x10, x2, x1
        rom[7] = 32'b0100000_00001_00010_101_01011_0110011; // sra x11, x2, x1
        rom[8] = 32'b0000000_00001_00010_110_01100_0110011; // or x12, x2, x1
        rom[9] = 32'b0000000_00001_00010_111_01101_0110011; // and x13, x2, x1
        
        // 먼저 STORE 명령어를 실행하여 메모리에 값을 저장
        rom[10] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0)
        rom[11] = 32'b0000000_00001_00000_010_00100_0100011; // sw x1, 4(x0)
        
        // 그 다음 LOAD 명령어 실행 (이제 메모리에 값이 있음)
        rom[12] = 32'b000000001000_00000_010_00011_0000011; // lw x3, 8(x0) - x2 값 로드
        rom[13] = 32'b000000000100_00000_010_01110_0000011; // lw x14, 4(x0) - x1 값 로드
        
        // I-Type 명령어 (OP_TYPE_I)
        rom[14] = 32'b000000000001_00000_000_00001_0010011; // addi x1, x0, 1
        rom[15] = 32'b000000000010_00001_001_00110_0010011; // slli x6, x1, 2
        rom[16] = 32'b000000000010_00001_101_01010_0010011; // srli x10, x1, 2
        rom[17] = 32'b010000000010_00001_101_01011_0010011; // srai x11, x1, 2
        
        // B-Type 명령어 (OP_TYPE_B) - 분기 명령어
        rom[18] = 32'b0000000_00010_00010_000_01100_1100011; // beq x2, x2, 12 (같으면 PC+12로 점프)
        rom[19] = 32'b0000000_00010_00011_001_01100_1100011; // bne x3, x2, 12 (다르면 PC+12로 점프)
        
        // U-Type (LU-type: LUI) 명령어 (OP_TYPE_LU)
        rom[20] = 32'b000000000000000000010_00111_0110111;   // lui x7, 0x2 → x7 = 0x2000
        
        // U-Type (AU-type: AUIPC) 명령어 (OP_TYPE_AU)
        rom[21] = 32'b000000000000000000011_01000_0010111;   // auipc x8, 0x3 → x8 = PC + 0x3000
        
        // JAL 명령어 (OP_TYPE_J)
        rom[22] = 32'b00000000010000000000_00001_1101111;    // jal x1, 4 (PC+4에 점프, x1=PC+4)
        
        // JALR 명령어 (OP_TYPE_JALR)
        rom[23] = 32'b000000000100_00001_000_00010_1100111;  // jalr x2, 4(x1) (x1+4로 점프, x2=PC+4)
        
        // 테스트 시퀀스 - 다양한 명령어 조합
        rom[24] = 32'h000002b7; // LUI x5, 0x0
        rom[25] = 32'h0042a283; // LW x5, 4(x5)
        rom[26] = 32'h0052a023; // SW x5, 0(x5)
        rom[27] = 32'h004000ef; // JAL x1, 4 (PC+4 jump)
        rom[28] = 32'h00008067; // JALR x0, 0(x1)
        rom[29] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        rom[30] = 32'h00000013; // NOP
        rom[31] = 32'h00000013; // NOP
    end

    // 수정된 부분: 주소 매핑 로직 
    always_comb begin
        // 유효한 주소 범위 확인 (10비트 주소 중 하위 5비트만 사용)
        if (addr < 32) begin
            dout = rom[addr[4:0]];
        end else begin
            dout = 32'h00000013; // NOP 명령어 반환 (유효하지 않은 주소)
        end
    end
endmodule

// `timescale 1ns / 1ps

// module rom (
//     input  logic [9:0]  addr,
//     output logic [31:0] dout
// );
//     logic [31:0] rom[0:31];

//     initial begin
//         // R-Type 명령어 (OP_TYPE_R)
//         rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1
//         rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1
//         rom[2] = 32'b0000000_00001_00010_001_00110_0110011; // sll x6, x2, x1
//         rom[3] = 32'b0000000_00001_00010_010_00111_0110011; // slt x7, x2, x1
//         rom[4] = 32'b0000000_00001_00010_011_01000_0110011; // sltu x8, x2, x1
//         rom[5] = 32'b0000000_00001_00010_100_01001_0110011; // xor x9, x2, x1
//         rom[6] = 32'b0000000_00001_00010_101_01010_0110011; // srl x10, x2, x1
//         rom[7] = 32'b0100000_00001_00010_101_01011_0110011; // sra x11, x2, x1
//         rom[8] = 32'b0000000_00001_00010_110_01100_0110011; // or x12, x2, x1
//         rom[9] = 32'b0000000_00001_00010_111_01101_0110011; // and x13, x2, x1
        
//         // I-Type 명령어 (OP_TYPE_I)
//         rom[10] = 32'b000000000001_00000_000_00001_0010011; // addi x1, x0, 1
//         rom[11] = 32'b000000000010_00001_001_00110_0010011; // slli x6, x1, 2
//         rom[12] = 32'b000000000010_00001_101_01010_0010011; // srli x10, x1, 2
//         rom[13] = 32'b010000000010_00001_101_01011_0010011; // srai x11, x1, 2
        
//         // L-Type 명령어 (OP_TYPE_L)
//         rom[14] = 32'b000000001000_00000_010_00011_0000011; // lw x3, 8(x0)
        
//         // S-Type 명령어 (OP_TYPE_S)
//         rom[15] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0)
        
//         // B-Type 명령어 (OP_TYPE_B) - 분기 명령어
//         rom[16] = 32'b0000000_00010_00010_000_01100_1100011; // beq x2, x2, 12 (같으면 PC+12로 점프)
//         rom[17] = 32'b0000000_00010_00011_001_01100_1100011; // bne x3, x2, 12 (다르면 PC+12로 점프)
//         rom[18] = 32'b0000000_00010_00011_100_01100_1100011; // blt x3, x2, 12 (작으면 PC+12로 점프)
//         rom[19] = 32'b0000000_00010_00011_101_01100_1100011; // bge x3, x2, 12 (크거나 같으면 PC+12로 점프)
//         rom[20] = 32'b0000000_00010_00011_110_01100_1100011; // bltu x3, x2, 12 (unsigned 작으면 PC+12로 점프)
//         rom[21] = 32'b0000000_00010_00011_111_01100_1100011; // bgeu x3, x2, 12 (unsigned 크거나 같으면 PC+12로 점프)
        
//         // U-Type (LU-type: LUI) 명령어 (OP_TYPE_LU)
//         rom[22] = 32'b000000000000000000010_00111_0110111;   // lui x7, 0x2 → x7 = 0x2000
        
//         // U-Type (AU-type: AUIPC) 명령어 (OP_TYPE_AU)
//         rom[23] = 32'b000000000000000000011_01000_0010111;   // auipc x8, 0x3 → x8 = PC + 0x3000
        
//         // JAL 명령어 (OP_TYPE_J)
//         rom[24] = 32'b00000000010000000000_00001_1101111;    // jal x1, 4 (PC+4에 점프, x1=PC+4)
        
//         // JALR 명령어 (OP_TYPE_JALR)
//         rom[25] = 32'b000000000100_00001_000_00010_1100111;  // jalr x2, 4(x1) (x1+4로 점프, x2=PC+4)
        
//         // 테스트 시퀀스 - 다양한 명령어 조합
//         rom[26] = 32'h000002b7; // LUI x5, 0x0
//         rom[27] = 32'h0042a283; // LW x5, 4(x5)
//         rom[28] = 32'h0052a023; // SW x5, 0(x5)
//         rom[29] = 32'h004000ef; // JAL x1, 4 (PC+4 jump)
//         rom[30] = 32'h00008067; // JALR x0, 0(x1)
//         rom[31] = 32'h00000013; // NOP (ADDI x0, x0, 0)
//     end

//     // 수정된 부분: 주소 매핑 로직 
//     always_comb begin
//         // 유효한 주소 범위 확인 (10비트 주소 중 하위 5비트만 사용)
//         if (addr < 32) begin
//             dout = rom[addr[4:0]];
//         end else begin
//             dout = 32'h00000013; // NOP 명령어 반환 (유효하지 않은 주소)
//         end
//     end
// endmodule



// `timescale 1ns / 1ps

// module rom (
//     input  logic [9:0]  addr,
//     output logic [31:0] dout
// );
//     logic [31:0] rom[0:31];

//     initial begin
//         // R-Type 명령어 (OP_TYPE_R)
//         rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1
//         rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1
//         rom[2] = 32'b0000000_00001_00010_001_00110_0110011; // sll x6, x2, x1
//         rom[3] = 32'b0000000_00001_00010_010_00111_0110011; // slt x7, x2, x1
//         rom[4] = 32'b0000000_00001_00010_011_01000_0110011; // sltu x8, x2, x1
//         rom[5] = 32'b0000000_00001_00010_100_01001_0110011; // xor x9, x2, x1
//         rom[6] = 32'b0000000_00001_00010_101_01010_0110011; // srl x10, x2, x1
//         rom[7] = 32'b0100000_00001_00010_101_01011_0110011; // sra x11, x2, x1
//         rom[8] = 32'b0000000_00001_00010_110_01100_0110011; // or x12, x2, x1
//         rom[9] = 32'b0000000_00001_00010_111_01101_0110011; // and x13, x2, x1
        
//         // I-Type 명령어 (OP_TYPE_I)
//         rom[10] = 32'b000000000001_00000_000_00001_0010011; // addi x1, x0, 1
//         rom[11] = 32'b000000000010_00001_001_00110_0010011; // slli x6, x1, 2
//         rom[12] = 32'b000000000010_00001_101_01010_0010011; // srli x10, x1, 2
//         rom[13] = 32'b010000000010_00001_101_01011_0010011; // srai x11, x1, 2
        
//         // L-Type 명령어 (OP_TYPE_L)
//         rom[14] = 32'b000000001000_00000_010_00011_0000011; // lw x3, 8(x0)
        
//         // S-Type 명령어 (OP_TYPE_S)
//         rom[15] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0)
        
//         // B-Type 명령어 (OP_TYPE_B) - 분기 명령어
//         rom[16] = 32'b0000000_00010_00010_000_01100_1100011; // beq x2, x2, 12 (같으면 PC+12로 점프)
//         rom[17] = 32'b0000000_00010_00011_001_01100_1100011; // bne x3, x2, 12 (다르면 PC+12로 점프)
//         rom[18] = 32'b0000000_00010_00011_100_01100_1100011; // blt x3, x2, 12 (작으면 PC+12로 점프)
//         rom[19] = 32'b0000000_00010_00011_101_01100_1100011; // bge x3, x2, 12 (크거나 같으면 PC+12로 점프)
//         rom[20] = 32'b0000000_00010_00011_110_01100_1100011; // bltu x3, x2, 12 (unsigned 작으면 PC+12로 점프)
//         rom[21] = 32'b0000000_00010_00011_111_01100_1100011; // bgeu x3, x2, 12 (unsigned 크거나 같으면 PC+12로 점프)
        
//         // U-Type (LU-type: LUI) 명령어 (OP_TYPE_LU)
//         rom[22] = 32'b000000000000000000010_00111_0110111;   // lui x7, 0x2 → x7 = 0x2000
        
//         // U-Type (AU-type: AUIPC) 명령어 (OP_TYPE_AU)
//         rom[23] = 32'b000000000000000000011_01000_0010111;   // auipc x8, 0x3 → x8 = PC + 0x3000
        
//         // JAL 명령어 (OP_TYPE_J)
//         rom[24] = 32'b00000000010000000000_00001_1101111;    // jal x1, 4 (PC+4에 점프, x1=PC+4)
        
//         // JALR 명령어 (OP_TYPE_JALR)
//         rom[25] = 32'b000000000100_00001_000_00010_1100111;  // jalr x2, 4(x1) (x1+4로 점프, x2=PC+4)
        
//         // 테스트 시퀀스 - 다양한 명령어 조합
//         rom[26] = 32'h000002b7; // LUI x5, 0x0
//         rom[27] = 32'h0042a283; // LW x5, 4(x5)
//         rom[28] = 32'h0052a023; // SW x5, 0(x5)
//         rom[29] = 32'h004000ef; // JAL x1, 4 (PC+4 jump)
//         rom[30] = 32'h00008067; // JALR x0, 0(x1)
//         rom[31] = 32'h00000013; // NOP (ADDI x0, x0, 0)
//     end

//     assign dout = rom[addr[4:0]]; // 하위 5비트만 사용 (32개 주소)
// endmodule
// module rom (
//     input  logic [9:0]  addr,
//     output logic [31:0] dout
// );

//     always_comb begin
//         case (addr)
//             // 기본 명령어들 테스트
//             10'd0:  dout = 32'h000002b7; // LUI x5, 0x0
//             10'd1:  dout = 32'h0042a283; // LW x5, 4(x5)
//             10'd2:  dout = 32'h0052a023; // SW x5, 0(x5)
            
//             // JAL 테스트: x1 = PC+4, PC <- PC+imm
//             10'd3:  dout = 32'h004000ef; // JAL x1, 4 (PC+4 jump)
            
//             // JALR 테스트: x2 = PC+4, PC <- (x1+imm)&~1
//             10'd4:  dout = 32'h00008067; // JALR x0, 0(x1)
            
//             // 점프 이후의 명령 확인용
//             10'd5:  dout = 32'h00000013; // NOP (ADDI x0, x0, 0)
//             10'd6:  dout = 32'h00000013; // NOP
//             10'd7:  dout = 32'h00000013; // NOP

//             default: dout = 32'h00000013; // 기본 NOP
//         endcase
//     end

// endmodule
