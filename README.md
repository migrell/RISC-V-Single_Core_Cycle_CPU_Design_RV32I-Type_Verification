 1. RISC-V 기본 구조 및 설계 배경
Project1의 수행목표는 RISC-V architecture 중에 하나인 RV32I Type 요소들을 기반으로 Single Core Cycle CPU를 설계하고, ROM에 원하는 데이터 값을 저장한 후 시뮬레이션을 통해 ROM에 저장한 RV32I의 Type data의 출력값을 검증하는 것이다. 

RISC-V는 UC 버클리에서 개발한 오픈소스 ISA(명령어 집합 구조)로서, 단순성과 확장성, 파이프라이닝에 최적화된 모듈화의 구조를 가지고 있다. 

Project1의 설계과정에서는 기본 정수 연산 기반의 RV32I Type을 검증하였으며 

향후 M(곱셈), F(부동소수점), C(압축 명령어) 등의 확장가능성을 열어두고 설계하였다           또한 Peripheral 연결의 확장성을 고려하여 설계하였고 Multi Core Cycle CPU로의 확장용의성에 초점을 맞추고 설계하였다.

2. 개발 환경 & 시뮬레이션 시나리오 설계
개발 환경은 Vivado와 SystemVerilog 언어를 사용하였다. Vivado는 Xilinx FPGA 설계에 최적화된 통합 개발 환경으로서 시뮬레이션 검증이 상대적으로 쉽다는 장점을 가지고 있었고 본 프로젝트에서는 그점을 활용하여 개발환경을 조성하였다. 

구체적인 시뮬레이션 시나리오 설계는 Clk을 100MHz로 생성한후에 Reset 과정이후 ROM에 입력한 데이터가 여러 RV32I Type의 원하는 ROM Data를 Read/Write를 하며 Simulation 환경에서 원하는 데이터 값을 얻을 수 있는지에 초점을 맞추고 설계하였다.

이를 위해 RV32I Type의 명령어를 force_pc_to_address라는 task를 통해 특정 주소의 명령어를 강제로 실행하며, 해당 명령어 실행 결과를 ROM, RAM, 레지스터 파일의 상태를 기준으로 확인하였다.

또한, 모든 시뮬레이션은 100ns 단위로 진행되었으며, 
명령어 타입별로 Testbench Scenario를 작성하고 Testbench에 각 시간별로 체크포인트를 설정하여 완벽한 검증 절차를 수립하고자 하였다.


3. 주요 모듈 설계 및 통합 과정 
전체 시스템은 5개의 핵심모듈인 ROM, RAM, Control Unit, DataPath, ALU로 구성된다.

ROM은 RV32I Type 명령어를 저장하는 기능을 수행하며 
직접 입력한 이진코드를 통해 ROM에 데이터값을 저장하고, 실제 명령어 실행과정을 시뮬레이션 하는데의 데이터 저장 통로로서의 핵심적인 역할을 한다.

RAM은 Load & Store 명령어의 결과를 확인하기 위한 공간으로 사용하였다.

Control Unit은 RV32I Type opcode와 func의 Field를 해석하여, 각 RV32I Type에 맞는 제어 신호를 생성하는 역할을 하게 설계하였으며, RegWrite, ALUSrc, Branch, Jal와 같은 RV32I Type의 다수의 내부 컨트롤 신호를 출력하게 설계하였다.

DataPath는 RegisterFile, immediate , ALU, PC의 Data transmission을 위한 제어 신호를 연결하여 원하는 데이터 값을 출력할 수 있게 Mux와 Adder를 통해 연산흐름을 조절하도록 설계하였다.

ALU는 {func7[5], func3}의 조합으로 각 RV32I Type의 ALUControl 값을 설정하였으며 이를 통해 정확하게 ADD, SUB, AND, OR, SLT 등의 기본 정수 연산을 처리하도록 설계하였다.

마지막으로 설계된 모듈을 Core로 묶음으로서 효율적인 유지보수를 목표로 하였으며 
향후 Peripheral 연결과 Multi Core Cycle CPU로의 확장가능성을 넓히고 용의하게 설계하였다.

4. RV32I Type 명령어 처리 및 Verification 
 RV32I Type별로 정교하게 설계한 ROM 데이터를 TestBench Scenario Code를 작성하였으며 모든 RV32I Type의 명령어를 Verification 하였다.

R-Type에서는 RFDataR1과 RFDataR2의 정수 연산 결과를 Verification 하였다.
I-Type에서는 AluResult = RFData1 + ImmExt & RegFileWe = 1의 값이 신뢰할 수 있는 값인지 Verification 하였다.
L-Type에서는 Memory에서 Dataload 연산을 수행할 시에, Address calculate & Dataload 연산이 신뢰성이 있는지 Verification 하였다.
S-Type에서는 dataAddr = RFData1 + imm 연산이 정확하게 수행되는지 Memory[x8] = RF2 & dataWe =1인지 Verification 하였다.
B-Type에서는 ALU에서의 Branch 조건 판단이 정확히 이루어지는지 그리고 Branch 조건을 만족했을시에 PC가 원하는 값으로 이동하는지 Verification 하였다.
LU-Type & AU-Type(Load Upper imm & Add Upper Imm to PC)에서는 각각 rd = imm < 12 & rd = PC + (imm<<12) 연산의 정확성을 Verification 하였다.
마지막으로 J-Type & JL-Type(Jump And Link & Jump And Link Reg)에서는 rd = PC+4 , PC+= imm & rd = PC+4 , PC = rs1 + imm 연산의 정확성을 Verification 하였다.


5. 주요 모듈간의 상호작용 

본 프로젝트에서 설계한 RISC-V Single Core Cycle CPU의 주요 모듈간 상호작용은 매우 중요한 의미를 갖는다. 


우선 ROM과 Control Unit 간 상호작용에서는 ROM에 저장된 RV32I Type 명령어가 Control Unit으로 전달되어 해석되며, Control Unit은 명령어 opcode와 func field를 분석하여 제어 신호를 생성한다. 
이렇게 생성된 제어 신호는 ALU, DataPath 등 다른 모듈들의 동작을 결정하는 핵심 요소가 된다.

 

Control Unit과 DataPath 간 상호작용에서는 Control Unit에서 생성된 제어 신호에 따라 DataPath의 데이터 흐름 방향이 결정되며, RegWrite, ALUSrc, Branch 등의 제어 신호가 DataPath의 동작에 직접적인 영향을 미친다. 
특히 Branch, Jal, Jalr와 같은 분기 명령은 PC 값 변경에 중요한 역할을 담당한다.


ALU와 DataPath 간 상호작용에서는 DataPath로부터 전달받은 데이터를 ALU에서 연산 처리하고, 그 결과를 다시 DataPath로 전달하여 Register 또는 Memory에 저장한다. 
ALU의 연산 결과는 조건부 분기 명령의 실행 여부를 결정하는 데 중요한 역할을 한다. 



RAM과 DataPath 간 상호작용에서는 Load & Store 명령어 실행 시 DataPath가 주소 값을 RAM에 전달하고, RAM은 해당 주소의 데이터를 읽거나 쓰는 작업을 수행한다. 
이렇게 처리된 데이터는 DataPath를 통해 Register로 전달된다. 


마지막으로 클럭 신호와 전체 시스템 간 상호작용에서는 100MHz Clk Singal에 따라 모든 모듈이 동기화되어 동작하며, 각 Clk Cycle마다 fetch, decode, execute, memory access, write back의 명령어가 순차적으로 수행된다. 


이는 100ns의 타이밍 제약 조건 내에서 모든 모듈의 동작이 완료되도록 설계되었다.


6. RISC-V Single Core Cycle CPU Design의 개선점

현재 구현된 RISC-V Single Core Cycle CPU Design에서 몇 가지 중요한 개선점을 도출하였다. 
먼저 파이프라인 구조 도입을 통해 현재의 Single Cycle 방식에서 벗어나 성능을 향상시킬 수 있다. 

현재 설계는 한 사이클에 하나의 명령어만 처리 가능하지만, 파이프라인 구조를 도입하면 여러 명령어를 병렬적으로 처리하여 성능을 크게 향상시킬 수 있다. IF, ID, EX, MEM, WB 단계를 파이프라인화 함으로써 처리량(throughput)을 크게 증가시킬 수 있을 것이다. 


또한 캐시 메모리 구현을 통해 메모리 접근 지연 시간을 감소시킬 수 있다. L1, L2 캐시를 구현하고 데이터 지역성(locality)을 활용하여 메모리 접근을 최적화할 수 있으며, 캐시 일관성(coherence) 프로토콜 구현을 통해 데이터 무결성을 보장할 수 있다.


분기 예측(Branch Prediction) 기능 추가도 중요한 개선점이다. 현재 설계에서는 분기 명령어 실행 시 제어 흐름 변경으로 인한 지연이 발생하지만, 정적/동적 분기 예측 알고리즘 도입을 통해 파이프라인 버블을 최소화할 수 있다. 



Branch Target Buffer(BTB) 구현으로 분기 대상 주소에 빠르게 접근하는 것도 가능하다.
 

명령어 최적화 및 확장 측면에서는 RV32I 기본 명령어 세트 외에 RV32M(곱셈/나눗셈) 명령어 추가 구현, SIMD(Single Instruction Multiple Data) 병렬 처리 명령어 지원, 그리고 사용자 정의 명령어 확장 기능 구현 등이 가능하다. 




마지막으로 전력 관리 기능 향상을 위해 클럭 게이팅(Clock Gating)을 통한 동적 전력 소모 감소, 사용하지 않는 모듈의 전원 차단 기능 구현, 그리고 작업 부하에 따른 동적 전압/주파수 조절(DVFS) 기법 도입 등을 고려할 수 있다.


7. RISC-V Single Core Cycle CPU Design의 확장가능성


본 프로젝트에서 설계한 RISC-V CPU는 다양한 확장가능성을 가지고 있다. 


우선 멀티코어 시스템으로의 확장이 가능하다. 

현재의 Single Core 설계를 기반으로 Multi Core 시스템으로 확장할 수 있으며, 
이를 위해 코어 간 통신을 위한 인터커넥트 및 캐시 일관성 프로토콜 구현, 그리고 공유 메모리 구조 및 메시지 패싱 방식의 통신 구현 등이 필요하다.

또한 특수 목적 가속기 통합도 가능하다. 

암호화, 신호 처리, AI 연산 등을 위한 특수 목적 하드웨어 가속기를 설계하고, CPU와 가속기 간의 효율적인 인터페이스를 설계하며, 가속기 제어를 위한 명령어 세트 확장 등을 구현할 수 있다.


외부 주변장치(Peripehrial) 인터페이스 확장도 중요한 확장 방향이다. 

UART, SPI, I2C 등 다양한 통신 프로토콜 인터페이스를 구현하고, 메모리 맵 입출력(MMIO) 방식의 주변장치 제어를 구현하며, 인터럽트 컨트롤러 설계를 통한 비동기적 이벤트 처리 등을 고려할 수 있다. 

실시간 운영체제(RTOS) 지원을 위해서는 인터럽트 처리 메커니즘 개선, 특권 모드(Privileged Mode) 구현을 통한 시스템 보안 강화, 그리고 메모리 보호 유닛(MPU) 구현을 통한 프로세스 격리 등이 필요하다.


마지막으로 디버깅 및 모니터링 기능 확장을 위해 
JTAG 인터페이스를 통한 온칩 디버깅 기능 구현, 성능 카운터 및 모니터링 레지스터 추가, 그리고 런타임 오류 감지 및 복구 메커니즘 구현 등을 고려할 수 있다.


본 프로젝트에서 구현한 RISC-V Single Core Cycle CPU는 
위와 같은 개선 및 확장을 통해 다양한 응용 분야에 활용될 수 있으며, 특히 IoT 장치, 임베디드 시스템, 에지 컴퓨팅 분야에서의 활용 가능성이 높다. 
향후 설계연구 과정에서는 위에서 제시한 개선점과 확장성을 바탕으로 
더욱 효율적이고 확장 가능한 RISC-V 기반 프로세서를 개발할 예정이다.

