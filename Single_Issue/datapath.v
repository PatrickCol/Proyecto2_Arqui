// Datapath pipeline de 5 etapas: IF - ID - EX - MEM - WB
// Sufijos: F=Fetch, D=Decode, E=Execute, M=Memory, W=Writeback
module datapath(input         clk, reset,
                // Fetch
                output [31:0] PCF,
                input  [31:0] InstrF,
                // Decode
                output [31:0] InstrD,
                input  [1:0]  ImmSrcD,
                // Execute
                input  [1:0]  PCSrcE,
                input         ALUSrcE,
                input  [2:0]  ALUControlE,
                output        ZeroE,
                // Memory
                output [31:0] ALUResultM, WriteDataM,
                input  [31:0] ReadDataM,
                // Writeback
                input         RegWriteW,
                input  [1:0]  ResultSrcW,
                // Hazard unit
                input         StallF, StallD, FlushD, FlushE,
                input  [1:0]  ForwardAE, ForwardBE,
                output [4:0]  Rs1D, Rs2D,
                output [4:0]  Rs1E, Rs2E, RdE,
                output [4:0]  RdM, RdW,
                // Depuracion: instruccion presente en cada etapa (InstrF e InstrD ya existen)
                output [31:0] InstrE, InstrM, InstrW);

  localparam WIDTH = 32;
  localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

  // ================= FETCH =================
  wire [31:0] PCNextF, PCPlus4F, PCTargetE, ALUResultE;

  flopenr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .en(~StallF),
    .d(PCNextF),
    .q(PCF)
  );

  adder pcadd4(
    .a(PCF),
    .b({WIDTH{1'b0}} + 4),
    .y(PCPlus4F)
  );

  // 00: PC+4 | 01: branch/jal (PCTargetE) | 10: jalr (ALUResultE sin bit 0)
  mux3 #(WIDTH) pcmux(
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .d2({ALUResultE[31:1], 1'b0}),
    .s(PCSrcE),
    .y(PCNextF)
  );

  // ============== Registro IF/ID ==============
  // Flush -> se inserta un NOP real (asi el controller nunca decodifica 0x00000000)
  reg [31:0] PCD, PCPlus4D, InstrD_r;
  assign InstrD = InstrD_r;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      InstrD_r <= NOP;
      PCD      <= 32'b0;
      PCPlus4D <= 32'b0;
    end else if (FlushD) begin
      InstrD_r <= NOP;
      PCD      <= 32'b0;
      PCPlus4D <= 32'b0;
    end else if (~StallD) begin
      InstrD_r <= InstrF;
      PCD      <= PCF;
      PCPlus4D <= PCPlus4F;
    end
  end

  // ================= DECODE =================
  wire [31:0] RD1D, RD2D, ImmExtD, ResultW;
  wire [4:0]  RdD;

  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD  = InstrD[11:7];

  // La escritura (WB) usa Rd de la etapa W. El regfile debe escribir en negedge clk.
  regfile rf(
    .clk(clk),
    .we3(RegWriteW),
    .a1(Rs1D),
    .a2(Rs2D),
    .a3(RdW),
    .wd3(ResultW),
    .rd1(RD1D),
    .rd2(RD2D)
  );
             
  extend ext(
    .instr(InstrD[31:7]),
    .immsrc(ImmSrcD),
    .immext(ImmExtD)
  );

  // ============== Registro ID/EX ==============
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;

  floprc #(207) regE(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d({RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D, InstrD}),
    .q({RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E, InstrE})
  );

  // ================= EXECUTE =================
  wire [31:0] SrcAE, SrcBE, WriteDataE;

  // Forwarding: 00 = registro, 01 = ResultW (WB), 10 = ALUResultM (MEM)
  mux3 #(WIDTH) srcamux(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardAE),
    .y(SrcAE)
  );

  mux3 #(WIDTH) srcbfwdmux(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardBE),
    .y(WriteDataE)   // tambien es el dato que se guarda en sw
  );

  mux2 #(WIDTH) srcbmux(
    .d0(WriteDataE),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(SrcBE)
  );

  alu alu(
    .a(SrcAE),
    .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE),
    .zero(ZeroE)
  );

  adder pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );

  // ============== Registro EX/MEM ==============
  wire [31:0] PCPlus4M;

  flopr #(133) regM(
    .clk(clk),
    .reset(reset),
    .d({ALUResultE, WriteDataE, RdE, PCPlus4E, InstrE}),
    .q({ALUResultM, WriteDataM, RdM, PCPlus4M, InstrM})
  );

  // ================= MEMORY =================
  // dmem esta fuera del datapath (ALUResultM, WriteDataM, ReadDataM)

  // ============== Registro MEM/WB ==============
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;

  flopr #(133) regW(
    .clk(clk),
    .reset(reset),
    .d({ALUResultM, ReadDataM, RdM, PCPlus4M, InstrM}),
    .q({ALUResultW, ReadDataW, RdW, PCPlus4W, InstrW})
  );

  // ================= WRITEBACK =================
  mux3 #(WIDTH) resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  );
endmodule