`timescale 1ns / 1ps

module tb_top ();
    logic clk;
    logic reset;
    int instr_count;

    // Clock: 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        instr_count = 0;
        #100 reset = 0;
    end

    MCU DUT (
        .clk(clk),
        .reset(reset)
    );

    initial begin
        #10000 $finish;
    end

    initial begin
        $dumpfile("tb_waveform.vcd");
        $dumpvars(0, tb_top);
    end

    task force_pc_to_address;
        input [31:0] address;
        begin
            @(posedge clk);
            force DUT.Core.U_DP.U_PC.q = address;
            @(posedge clk);
            release DUT.Core.U_DP.U_PC.q;
        end
    endtask

    function string get_instr_type(input logic [31:0] instr);
        logic [6:0] opcode;
        opcode = instr[6:0];
        case (opcode)
            7'b0110011: return "R-TYPE";
            7'b0010011: return "I-TYPE";
            7'b0000011: return "L-TYPE";
            7'b0100011: return "S-TYPE";
            7'b1100011: return "B-TYPE";
            7'b1101111: return "JAL";
            7'b1100111: return "JALR";
            7'b0110111: return "LUI";
            7'b0010111: return "AUIPC";
            default:    return "UNKNOWN";
        endcase
    endfunction

    // 실행 시퀀스
    initial begin
        @(negedge reset);
        #100;

        $display("\n===== TEST START =====");

        // 각 명령어 강제 실행 후 다음 주소로 이동
        force_pc_to_address(32'h00000058); $display("\n----- LUI TEST -----");
        #100; force_pc_to_address(32'h0000005C); $display("\n----- AUIPC TEST -----");
        #100; force_pc_to_address(32'h00000060); $display("\n----- JAL TEST -----");
        #100; force_pc_to_address(32'h00000064); $display("\n----- JALR TEST -----");
        #100; force_pc_to_address(32'h00000000); $display("\n----- R-TYPE TEST -----");
        #100; force_pc_to_address(32'h00000028); $display("\n----- I-TYPE TEST -----");
        #100; force_pc_to_address(32'h00000038); $display("\n----- L-TYPE TEST -----");
        #100; force_pc_to_address(32'h0000003C); $display("\n----- S-TYPE TEST -----");
        #100; force_pc_to_address(32'h00000040); $display("\n----- B-TYPE TEST -----");
        #100; force_pc_to_address(32'h00000068); $display("\n----- SEQ TEST -----");

        $display("\n===== TEST FINISHED =====");
    end

    // 출력 로직 (기존 유지 + 타입별 분석)
    initial begin
        @(negedge reset);
        #1;
        forever begin
            @(posedge clk);
            if (^DUT.instrCode !== 1'bx) begin
                string type_str = get_instr_type(DUT.instrCode);
                logic [31:0] pc = DUT.instrMemAddr;
                logic [31:0] instr = DUT.instrCode;
                logic [31:0] x1 = DUT.Core.U_DP.U_RegFile.RegFile[1];
                logic [31:0] x2 = DUT.Core.U_DP.U_RegFile.RegFile[2];
                logic [31:0] x7 = DUT.Core.U_DP.U_RegFile.RegFile[7];
                logic [31:0] x8 = DUT.Core.U_DP.U_RegFile.RegFile[8];

                logic [31:0] imm_u = {instr[31:12], 12'b0};
                logic [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
                logic [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
                logic [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                logic [31:0] imm_jal = {
                    {11{instr[31]}}, instr[31], instr[19:12],
                    instr[20], instr[30:21], 1'b0
                };
                logic [31:0] imm_jalr = {{20{instr[31]}}, instr[31:20]};

                instr_count++;

                $display("\n[Time %0t ns] #%0d Opcode %s", $time, instr_count, type_str);
                $display("PC:     %h", pc);
                $display("Instr:  %h", instr);
                $display("x1: %h | x2: %h | x3: %h | x4: %h", DUT.Core.U_DP.U_RegFile.RegFile[1], DUT.Core.U_DP.U_RegFile.RegFile[2], DUT.Core.U_DP.U_RegFile.RegFile[3], DUT.Core.U_DP.U_RegFile.RegFile[4]);
                $display("x5: %h | x6: %h | x7: %h | x8: %h", DUT.Core.U_DP.U_RegFile.RegFile[5], DUT.Core.U_DP.U_RegFile.RegFile[6], DUT.Core.U_DP.U_RegFile.RegFile[7], DUT.Core.U_DP.U_RegFile.RegFile[8]);
                $display("RAM[0]: %h | RAM[1]: %h", DUT.U_ram.mem[0], DUT.U_ram.mem[1]);

                $display("Control: regFileWe=%b, aluSrcMuxSel=%b, dataWe=%b, branch=%b, isJAL=%b, isJALR=%b",
                    DUT.Core.regFileWe, DUT.Core.aluSrcMuxSel, DUT.Core.dataWe,
                    DUT.Core.branch, DUT.Core.isJAL_internal, DUT.Core.isJALR);

                case (type_str)
                    "LUI":    $display(">> [LUI] x%0d ← imm<<12 = %h", instr[11:7], imm_u);
                    "AUIPC":  $display(">> [AUIPC] x%0d ← PC+imm<<12 = %h", instr[11:7], pc + imm_u);
                    "JAL": begin
                        $display(">> [JAL] x%0d ← PC+4 = %h", instr[11:7], pc + 4);
                        $display("         Jump to %h", pc + imm_jal);
                    end
                    "JALR": begin
                        $display(">> [JALR] x%0d ← PC+4 = %h", instr[11:7], pc + 4);
                        $display("         Jump to x%0d + imm = %h", instr[19:15], DUT.Core.U_DP.U_RegFile.RegFile[instr[19:15]] + imm_jalr);
                    end
                    default: ; // 기타 분석 생략 가능
                endcase

                $display("──────────────────────────────────────────────");
            end
        end
    end
endmodule //


// `timescale 1ns / 1ps

// module tb_top ();
//     logic clk;
//     logic reset;
    
//     // 클럭 생성: 100MHz (더 빠른 시뮬레이션을 위해 주파수 증가)
//     initial begin
//         clk = 0;
//         forever #5 clk = ~clk;  // 10ns 주기 (100MHz)
//     end
    
//     // 리셋 신호 생성
//     initial begin
//         reset = 1;
//         #100 reset = 0;
//     end
    
//     // DUT 인스턴스
//     MCU DUT (
//         .clk  (clk),
//         .reset(reset)
//     );
    
//     // 시뮬레이션 종료
//     initial begin
//         #10000 $finish;
//     end
    
//     // 파형 저장
//     initial begin
//         $dumpfile("tb_waveform.vcd");
//         $dumpvars(0, tb_top);
//     end
    
//     // 명령어 해석 함수
//     function string get_instr_type(input logic [31:0] instr);
//         logic [6:0] opcode;
//         opcode = instr[6:0];
//         case (opcode)
//             7'b0110011: return "R-TYPE";
//             7'b0010011: return "I-TYPE";
//             7'b0000011: return "L-TYPE";
//             7'b0100011: return "S-TYPE";
//             7'b1100011: return "B-TYPE";
//             7'b1101111: return "JAL";
//             7'b1100111: return "JALR";
//             7'b0110111: return "LUI";
//             7'b0010111: return "AUIPC";
//             default:    return "UNKNOWN";
//         endcase
//     endfunction
    
//     // 출력 로직 (reset 이후, instr 유효 시 실행)
//     initial begin
//         @(negedge reset);
//         #1;
//         forever begin
//             @(posedge clk);
//             if (^DUT.instrCode !== 1'bx) begin
//                 string type_str;
//                 logic [31:0] pc;
//                 logic [31:0] instr;
//                 logic [31:0] x1;
//                 logic [31:0] x2;
//                 logic [31:0] x7;
//                 logic [31:0] x8;
//                 logic [31:0] imm_u;
//                 logic [31:0] imm_jal;
//                 logic [31:0] imm_jalr;
                
//                 type_str = get_instr_type(DUT.instrCode);
//                 pc      = DUT.instrMemAddr;
//                 instr   = DUT.instrCode;
//                 x1 = DUT.Core.U_DP.U_RegFile.RegFile[1];
//                 x2 = DUT.Core.U_DP.U_RegFile.RegFile[2];
//                 x7 = DUT.Core.U_DP.U_RegFile.RegFile[7];
//                 x8 = DUT.Core.U_DP.U_RegFile.RegFile[8];
//                 imm_u = {instr[31:12], 12'b0};
//                 imm_jal = {
//                     {11{instr[31]}}, instr[31], instr[19:12],
//                     instr[20], instr[30:21], 1'b0
//                 };
//                 imm_jalr = {{20{instr[31]}}, instr[31:20]};
                
//                 $display("\n[Time %0t ns] Opcode %s", $time, type_str);
//                 $display("PC:     %h", DUT.instrMemAddr);
//                 $display("Instr:  %h", DUT.instrCode);
//                 $display("x1: %h | x2: %h | x3: %h | x4: %h",
//                           DUT.Core.U_DP.U_RegFile.RegFile[1],
//                           DUT.Core.U_DP.U_RegFile.RegFile[2],
//                           DUT.Core.U_DP.U_RegFile.RegFile[3],
//                           DUT.Core.U_DP.U_RegFile.RegFile[4]);
//                 $display("x5: %h | x6: %h | x7: %h | x8: %h",
//                           DUT.Core.U_DP.U_RegFile.RegFile[5],
//                           DUT.Core.U_DP.U_RegFile.RegFile[6],
//                           DUT.Core.U_DP.U_RegFile.RegFile[7],
//                           DUT.Core.U_DP.U_RegFile.RegFile[8]);
//                 $display("RAM[0]: %h | RAM[1]: %h",
//                           DUT.U_ram.mem[0],
//                           DUT.U_ram.mem[1]);
                
//                 // 추가: 로직 분석 메시지 (항상 출력하도록 수정)
//                 $display(">>LUI AUIPC JAL JALR<<:");
//                 if (type_str == "LUI")
//                     $display("   [LUI] x7 should be imm<<12 = %h", imm_u);
//                 else if (type_str == "AUIPC")
//                     $display("   [AUIPC] x8 should be PC + imm<<12 = %h", pc + imm_u);
//                 else if (type_str == "JAL")
//                     $display("   [JAL] x1 should be PC+4 = %h, Target = PC + imm = %h", pc + 4, pc + imm_jal);
//                 else if (type_str == "JALR")
//                     $display("   [JALR] x2 should be PC+4 = %h, Target = x1 + imm = %h", pc + 4, x1 + imm_jalr);
//                 else
//                     $display("   [%s] PC=%h", type_str, pc);
                
//                 $display("──────────────────────────────────────────────");
//             end
//         end
//     end
// endmodule


// `timescale 1ns / 1ps

// module tb_top ();
//     logic clk;
//     logic reset;
    
//     // 클럭 생성: 10MHz
//     initial begin
//         clk = 0;
//         forever #50 clk = ~clk;
//     end
    
//     // 리셋 신호 생성
//     initial begin
//         reset = 1;
//         #100 reset = 0;
//     end
    
//     // DUT 인스턴스
//     MCU DUT (
//         .clk  (clk),
//         .reset(reset)
//     );
    
//     // 시뮬레이션 종료
//     initial begin
//         #10000 $finish;
//     end
    
//     // 파형 저장
//     initial begin
//         $dumpfile("tb_waveform.vcd");
//         $dumpvars(0, tb_top);
//     end
    
//     // 명령어 해석 함수
//     function string get_instr_type(input logic [31:0] instr);
//         logic [6:0] opcode;
//         opcode = instr[6:0];
//         case (opcode)
//             7'b0110011: return "R-TYPE";
//             7'b0010011: return "I-TYPE";
//             7'b0000011: return "L-TYPE";
//             7'b0100011: return "S-TYPE";
//             7'b1100011: return "B-TYPE";
//             7'b1101111: return "JAL";
//             7'b1100111: return "JALR";
//             7'b0110111: return "LUI";
//             7'b0010111: return "AUIPC";
//             default:    return "UNKNOWN";
//         endcase
//     endfunction
    
//     // 출력 로직 (reset 이후, instr 유효 시 실행)
//     initial begin
//         @(negedge reset);
//         #1;
//         forever begin
//             @(posedge clk);
//             if (^DUT.instrCode !== 1'bx) begin
//                 string type_str;
//                 logic [31:0] pc;
//                 logic [31:0] instr;
//                 logic [31:0] x1;
//                 logic [31:0] x2;
//                 logic [31:0] x7;
//                 logic [31:0] x8;
//                 logic [31:0] imm_u;
//                 logic [31:0] imm_jal;
//                 logic [31:0] imm_jalr;
                
//                 type_str = get_instr_type(DUT.instrCode);
//                 pc      = DUT.instrMemAddr;
//                 instr   = DUT.instrCode;
//                 x1 = DUT.Core.U_DP.U_RegFile.RegFile[1];
//                 x2 = DUT.Core.U_DP.U_RegFile.RegFile[2];
//                 x7 = DUT.Core.U_DP.U_RegFile.RegFile[7];
//                 x8 = DUT.Core.U_DP.U_RegFile.RegFile[8];
//                 imm_u = {instr[31:12], 12'b0};
//                 imm_jal = {
//                     {11{instr[31]}}, instr[31], instr[19:12],
//                     instr[20], instr[30:21], 1'b0
//                 };
//                 imm_jalr = {{20{instr[31]}}, instr[31:20]};
                
//                 $display("\n[Time %0t ns] Opcode %s", $time, type_str);
//                 $display("PC:     %h", DUT.instrMemAddr);
//                 $display("Instr:  %h", DUT.instrCode);
//                 $display("x1: %h | x2: %h | x3: %h | x4: %h",
//                           DUT.Core.U_DP.U_RegFile.RegFile[1],
//                           DUT.Core.U_DP.U_RegFile.RegFile[2],
//                           DUT.Core.U_DP.U_RegFile.RegFile[3],
//                           DUT.Core.U_DP.U_RegFile.RegFile[4]);
//                 $display("x5: %h | x6: %h | x7: %h | x8: %h",
//                           DUT.Core.U_DP.U_RegFile.RegFile[5],
//                           DUT.Core.U_DP.U_RegFile.RegFile[6],
//                           DUT.Core.U_DP.U_RegFile.RegFile[7],
//                           DUT.Core.U_DP.U_RegFile.RegFile[8]);
//                 $display("RAM[0]: %h | RAM[1]: %h",
//                           DUT.U_ram.mem[0],
//                           DUT.U_ram.mem[1]);
                
//                 // 추가: 로직 분석 메시지
//                 if (type_str == "LUI")
//                     $display(">> [LUI] x7 should be imm<<12 = %h", imm_u);
//                 if (type_str == "AUIPC")
//                     $display(">> [AUIPC] x8 should be PC + imm<<12 = %h", pc + imm_u);
//                 if (type_str == "JAL")
//                     $display(">> [JAL] x1 should be PC+4 = %h, Target = PC + imm = %h", pc + 4, pc + imm_jal);
//                 if (type_str == "JALR")
//                     $display(">> [JALR] x2 should be PC+4 = %h, Target = x1 + imm = %h", pc + 4, x1 + imm_jalr);
                
//                 $display("──────────────────────────────────────────────");
//             end
//         end
//     end
// endmodule


// `timescale 1ns / 1ps

// module tb_top ();
//     logic clk;
//     logic reset;
    
//     // 클럭 생성: 100MHz → 10MHz (느리게 관찰 가능)
//     initial begin
//         clk = 0;
//         forever #50 clk = ~clk; // ← 주기: 100ns (10MHz)
//     end
    
//     // 리셋 신호 생성
//     initial begin
//         reset = 1;
//         #100 reset = 0; // 더 안정적인 초기화
//     end
    
//     // DUT 인스턴스
//     MCU DUT (
//         .clk  (clk),
//         .reset(reset)
//     );
    
//     // 시뮬레이션 종료
//     initial begin
//         #10000 $finish; // 느려진 클럭 기준 충분한 시간 확보
//     end
    
//     // 파형 저장
//     initial begin
//         $dumpfile("tb_waveform.vcd");
//         $dumpvars(0, tb_top);
//     end
    
//     // 명령어 해석 함수 (define 없이 직접 처리)
//     function string get_instr_type(input logic [31:0] instr);
//         logic [6:0] opcode;
//         opcode = instr[6:0];
//         case (opcode)
//             7'b0110011: return "R-TYPE";
//             7'b0010011: return "I-TYPE";
//             7'b0000011: return "L-TYPE";
//             7'b0100011: return "S-TYPE";
//             7'b1100011: return "B-TYPE";
//             7'b1101111: return "JAL";
//             7'b1100111: return "JALR";
//             7'b0110111: return "LUI";
//             7'b0010111: return "AUIPC";
//             default:    return "UNKNOWN";
//         endcase
//     endfunction
    
//     // 모니터링 시작 (reset 이후, instr 유효 시)
//     initial begin
//         @(negedge reset);
//         #1;
//         forever begin
//             @(posedge clk);
//             if (^DUT.instrCode !== 1'bx) begin
//                 $display("\n[Time %0t ns] Opcode %s", $time, get_instr_type(DUT.instrCode));
//                 $display("PC:     %h", DUT.instrMemAddr);
//                 $display("Instr:  %h", DUT.instrCode);
//                 $display("x1: %h | x2: %h | x3: %h | x4: %h",
//                           DUT.Core.U_DP.U_RegFile.RegFile[1],
//                          DUT.Core.U_DP.U_RegFile.RegFile[2],
//                          DUT.Core.U_DP.U_RegFile.RegFile[3],
//                          DUT.Core.U_DP.U_RegFile.RegFile[4]);
//                 $display("x5: %h | x6: %h | x7: %h | x8: %h",
//                           DUT.Core.U_DP.U_RegFile.RegFile[5],
//                          DUT.Core.U_DP.U_RegFile.RegFile[6],
//                          DUT.Core.U_DP.U_RegFile.RegFile[7],
//                          DUT.Core.U_DP.U_RegFile.RegFile[8]);
//                 $display("RAM[0]: %h | RAM[1]: %h",
//                           DUT.U_ram.mem[0],
//                          DUT.U_ram.mem[1]);
//                 $display("──────────────────────────────────────────────");
//             end
//         end
//     end
// endmodule



// `timescale 1ns / 1ps

// module tb_RV32I ();

//     logic clk;
//     logic reset;

//     MCU dut (.*);

//     always #5 clk = ~clk;

//     initial begin
//         clk = 0; reset = 1;
//         #10 reset = 0;
//         #100 $finish;
//     end
// endmodule
