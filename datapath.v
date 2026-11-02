// Datapath pipeline de 5 etapas: IF - ID - EX - MEM - WB
// Sufijos: F=Fetch, D=Decode, E=Execute, M=Memory, W=Writeback
// Dual-Issue preliminar (E1): Dual Fetch y Dual Decode de un par de instrucciones.
// Por ahora se emite una instruccion por ciclo: SelD = 0 emite la mas antigua
// del par (slot 0) y SelD = 1 la mas joven (slot 1); recien entonces entra el
// siguiente par. La via 1 completa (Issue Unit, 2a ALU) se agrega en E2.
module datapath(input         clk, reset,
                // Fetch
                output [31:0] PCF,
                input  [31:0] InstrF, InstrF1,
                // Decode
                output [31:0] InstrD,            // instruccion emitida
                output [31:0] InstrD0, InstrD1,  // par en Decode
                output        SelD,              // slot que se emite
                input  [1:0]  ImmSrcD0, ImmSrcD1,
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
  // Dual Fetch: se leen InstrF (PCF) e InstrF1 (PCF+4) y el PC avanza de 8 en 8
  wire [31:0] PCNextF, PCPlus8F, PCTargetE, ALUResultE;

  // El PC solo avanza cuando el par en Decode ya se emitio completo (SelD = 1)
  flopenr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .en(~StallF & SelD),
    .d(PCNextF),
    .q(PCF)
  );

  adder pcadd8(
    .a(PCF),
    .b({WIDTH{1'b0}} + 8),
    .y(PCPlus8F)
  );

  // 00: PC+8 | 01: branch/jal (PCTargetE) | 10: jalr (ALUResultE sin bit 0)
  mux3 #(WIDTH) pcmux(
    .d0(PCPlus8F),
    .d1(PCTargetE),
    .d2({ALUResultE[31:1], 1'b0}),
    .s(PCSrcE),
    .y(PCNextF)
  );

  // ============== Registro IF/ID doble ==============
  // Guarda el par (InstrD0, InstrD1) y su PC base.
  // Flush/reset -> par de NOPs con SelD = 1 (par vacio: el siguiente ciclo ya carga uno nuevo)
  reg [31:0] PCPairD, InstrD0_r, InstrD1_r;
  reg        SelD_r;
  assign InstrD0 = InstrD0_r;
  assign InstrD1 = InstrD1_r;
  assign SelD    = SelD_r;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      InstrD0_r <= NOP;
      InstrD1_r <= NOP;
      PCPairD   <= 32'b0;
      SelD_r    <= 1'b1;
    end else if (FlushD) begin
      InstrD0_r <= NOP;
      InstrD1_r <= NOP;
      PCPairD   <= 32'b0;
      SelD_r    <= 1'b1;
    end else if (~StallD) begin
      if (SelD_r) begin           // par emitido completo: entra el siguiente
        InstrD0_r <= InstrF;
        InstrD1_r <= InstrF1;
        PCPairD   <= PCF;
      end
      SelD_r <= ~SelD_r;
    end
  end

  // Instruccion emitida este ciclo y su PC
  wire [31:0] PCD, PCPlus4D;
  assign InstrD   = SelD ? InstrD1 : InstrD0;
  assign PCD      = PCPairD + {SelD, 2'b00};
  assign PCPlus4D = PCD + 4;

  // ================= DECODE (Dual Decode) =================
  wire [31:0] RD1D0, RD2D0, RD1D1, RD2D1, ImmExtD0, ImmExtD1;
  wire [31:0] RD1D, RD2D, ImmExtD, ResultW;
  wire [4:0]  RdD;

  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD  = InstrD[11:7];

  // La escritura (WB) usa Rd de la etapa W. El regfile debe escribir en negedge clk.
  // Lectura de los operandos de ambas instrucciones del par (4 lecturas)
  regfile rf(
    .clk(clk),
    .we3(RegWriteW),
    .a1(InstrD0[19:15]),
    .a2(InstrD0[24:20]),
    .a3(RdW),
    .wd3(ResultW),
    .rd1(RD1D0),
    .rd2(RD2D0),
    .web3(1'b0),           // escritura de la via 1: se conecta en E2
    .b1(InstrD1[19:15]),
    .b2(InstrD1[24:20]),
    .b3(5'b0),
    .wdb3(32'b0),
    .rdb1(RD1D1),
    .rdb2(RD2D1)
  );

  extend ext0(
    .instr(InstrD0[31:7]),
    .immsrc(ImmSrcD0),
    .immext(ImmExtD0)
  );

  extend ext1(
    .instr(InstrD1[31:7]),
    .immsrc(ImmSrcD1),
    .immext(ImmExtD1)
  );

  // Operandos de la instruccion emitida
  assign RD1D    = SelD ? RD1D1    : RD1D0;
  assign RD2D    = SelD ? RD2D1    : RD2D0;
  assign ImmExtD = SelD ? ImmExtD1 : ImmExtD0;

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