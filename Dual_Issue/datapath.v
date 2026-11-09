// Datapath Dual-Issue In-Order de 5 etapas (E2)
// Sufijos: F=Fetch, D=Decode, E=Execute, M=Memory, W=Writeback; el digito es la via (0 = mas antigua)
//
//  FETCH : se leen dos instrucciones (PCF y PCF+4). El PC avanza 4*Consumed.
//  IF/ID : ventana deslizante de dos instrucciones (slot 0 y slot 1) + bit valid por slot.
//            Consumed = 2 -> entra el par recien leido
//            Consumed = 1 -> el slot 1 pasa a slot 0 y entra InstrF como slot 1
//            Consumed = 0 -> la ventana se congela (stall)
//          Invariante: PCF = PC del slot 0 + 8.
//  DECODE: dos decodificadores, dos extend y Register File de 4 lecturas / 2 escrituras.
//  EXECUTE: dos ALU, dos sumadores de destino, forwarding de 5 fuentes por operando.
//           Un unico resolutor de saltos: el destino y el resultado de la ALU (jalr) se toman
//           de la via que tiene el salto.
//  MEMORY: un solo puerto. Un mux elige la via duena del puerto (MemSelM1).
//  WRITEBACK: un resultmux por via; la via 0 escribe por el puerto 0 y la via 1 por el 2.
module datapath(input         clk, reset,
                // ---- Fetch ----
                output [31:0] PCF,
                input  [31:0] InstrF, InstrF1,
                // ---- Decode ----
                output [31:0] InstrD0, InstrD1,
                output        ValidD0, ValidD1,
                input  [1:0]  ImmSrcD0, ImmSrcD1,
                output [4:0]  Rs1D0, Rs2D0, RdD0, Rs1D1, Rs2D1,
                // ---- Emision y control de la ventana ----
                input  [1:0]  Consumed,
                input         Issue0, Issue1,
                // ---- Execute ----
                input  [1:0]  PCSrcE0, PCSrcE1,
                input         ALUSrcE0, ALUSrcE1,
                input  [2:0]  ALUControlE0, ALUControlE1,
                output        ZeroE0, ZeroE1,
                output [4:0]  Rs1E0, Rs2E0, RdE0, Rs1E1, Rs2E1, RdE1,
                // ---- Memory (puerto unico) ----
                input         MemSelM1,
                output [31:0] ALUResultM, WriteDataM,
                input  [31:0] ReadDataM,
                output [4:0]  RdM0, RdM1,
                // ---- Writeback ----
                input         RegWriteW0, RegWriteW1,
                input  [1:0]  ResultSrcW0, ResultSrcW1,
                output [4:0]  RdW0, RdW1,
                // ---- Hazard unit ----
                input         FlushD, FlushE, FlushM1,
                input  [2:0]  ForwardA0, ForwardB0, ForwardA1, ForwardB1,
                // ---- Depuracion y metricas ----
                output [31:0] InstrE0, InstrE1, InstrM0, InstrM1, InstrW0, InstrW1,
                output        ValidW0, ValidW1,     // instruccion valida que se retira en WB
                output [31:0] PCW0, PCW1);          // PC de la instruccion que se retira

  localparam WIDTH = 32;
  localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

  // ======================= FETCH =======================
  wire [31:0] PCNextF, PCSeqF, PCTargetE, PCTargetE0, PCTargetE1, ALUResultE, ALUResultE0, ALUResultE1;
  wire [1:0]  PCSrcE  = PCSrcE0 | PCSrcE1;   // la via sin salto vale 00
  wire        TakenL1 = |PCSrcE1;            // el salto esta en la via 1

  // PC secuencial = PCF + 4*Consumed (Consumed = 0 deja el PC quieto: stall)
  adder pcadd(
    .a(PCF),
    .b({28'b0, Consumed, 2'b00}),
    .y(PCSeqF)
  );

  // Resolutor unico de saltos: destino y resultado de ALU de la via que tiene el salto
  mux2 #(WIDTH) targetmux(
    .d0(PCTargetE0),
    .d1(PCTargetE1),
    .s(TakenL1),
    .y(PCTargetE)
  );

  mux2 #(WIDTH) jalrmux(
    .d0(ALUResultE0),
    .d1(ALUResultE1),
    .s(TakenL1),
    .y(ALUResultE)
  );

  // 00: secuencial | 01: branch/jal (PCTargetE) | 10: jalr (ALUResultE sin bit 0)
  mux3 #(WIDTH) pcmux(
    .d0(PCSeqF),
    .d1(PCTargetE),
    .d2({ALUResultE[31:1], 1'b0}),
    .s(PCSrcE),
    .y(PCNextF)
  );

  flopr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .d(PCNextF),
    .q(PCF)
  );

  // ================ Registro IF/ID: ventana deslizante ================
  // Reset/flush -> dos NOP invalidos; como un slot invalido cuenta como consumido, el ciclo
  // siguiente carga el par de PCF.
  reg [31:0] InstrD0_r, InstrD1_r, PCD0_r;
  reg        ValidD0_r, ValidD1_r;
  assign InstrD0 = InstrD0_r;
  assign InstrD1 = InstrD1_r;
  assign ValidD0 = ValidD0_r;
  assign ValidD1 = ValidD1_r;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      InstrD0_r <= NOP;  InstrD1_r <= NOP;  PCD0_r <= 32'b0;
      ValidD0_r <= 1'b0; ValidD1_r <= 1'b0;
    end else if (FlushD) begin
      InstrD0_r <= NOP;  InstrD1_r <= NOP;  PCD0_r <= 32'b0;
      ValidD0_r <= 1'b0; ValidD1_r <= 1'b0;
    end else if (Consumed == 2'b10) begin       // salieron (o eran burbuja) los dos slots
      InstrD0_r <= InstrF;  InstrD1_r <= InstrF1;  PCD0_r <= PCF;
      ValidD0_r <= 1'b1;    ValidD1_r <= 1'b1;
    end else if (Consumed == 2'b01) begin       // solo salio el slot 0: el slot 1 se conserva
      InstrD0_r <= InstrD1_r;  InstrD1_r <= InstrF;  PCD0_r <= PCD0_r + 4;
      ValidD0_r <= ValidD1_r;  ValidD1_r <= 1'b1;
    end
  end

  // PC de cada slot y su PC+4
  wire [31:0] PCD0, PCD1, PCPlus4D0, PCPlus4D1;
  assign PCD0      = PCD0_r;
  assign PCD1      = PCD0_r + 4;
  assign PCPlus4D0 = PCD0_r + 4;
  assign PCPlus4D1 = PCD0_r + 8;

  // ======================= DECODE =======================
  wire [31:0] RD1D0, RD2D0, RD1D1, RD2D1, ImmExtD0, ImmExtD1;
  wire [31:0] ResultW0, ResultW1;
  wire [4:0]  RdD1;

  assign Rs1D0 = InstrD0[19:15];
  assign Rs2D0 = InstrD0[24:20];
  assign RdD0  = InstrD0[11:7];
  assign Rs1D1 = InstrD1[19:15];
  assign Rs2D1 = InstrD1[24:20];
  assign RdD1  = InstrD1[11:7];

  // Register File: 4 lecturas (dos por slot) y 2 escrituras (una por via, en negedge).
  // Si las dos vias escriben el mismo registro gana la via 1 (la mas joven).
  regfile rf(
    .clk(clk),
    .we3(RegWriteW0),
    .a1(Rs1D0),
    .a2(Rs2D0),
    .a3(RdW0),
    .wd3(ResultW0),
    .rd1(RD1D0),
    .rd2(RD2D0),
    .web3(RegWriteW1),
    .b1(Rs1D1),
    .b2(Rs2D1),
    .b3(RdW1),
    .wdb3(ResultW1),
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

  // ============== Registros ID/EX (uno por via) ==============
  // Si la via no emite (Issue = 0) o hay flush, el registro se limpia: burbuja (valid = 0)
  wire [31:0] RD1E0, RD2E0, PCE0, ImmExtE0, PCPlus4E0;
  wire [31:0] RD1E1, RD2E1, PCE1, ImmExtE1, PCPlus4E1;
  wire        ValidE0, ValidE1;

  floprc #(208) regE0(
    .clk(clk),
    .reset(reset),
    .clear(FlushE | ~Issue0),
    .d({RD1D0, RD2D0, PCD0, Rs1D0, Rs2D0, RdD0, ImmExtD0, PCPlus4D0, InstrD0, 1'b1}),
    .q({RD1E0, RD2E0, PCE0, Rs1E0, Rs2E0, RdE0, ImmExtE0, PCPlus4E0, InstrE0, ValidE0})
  );

  floprc #(208) regE1(
    .clk(clk),
    .reset(reset),
    .clear(FlushE | ~Issue1),
    .d({RD1D1, RD2D1, PCD1, Rs1D1, Rs2D1, RdD1, ImmExtD1, PCPlus4D1, InstrD1, 1'b1}),
    .q({RD1E1, RD2E1, PCE1, Rs1E1, Rs2E1, RdE1, ImmExtE1, PCPlus4E1, InstrE1, ValidE1})
  );

  // ======================= EXECUTE =======================
  // Forwarding (por operando): 000 registro | 001 ResultW0 | 010 ResultW1 | 011 ALUResultM0 | 100 ALUResultM1
  wire [31:0] SrcAE0, SrcBE0, WriteDataE0, SrcAE1, SrcBE1, WriteDataE1;
  wire [31:0] ALUResultM0, ALUResultM1, WriteDataM0, WriteDataM1;

  // ---- via 0 ----
  mux5 #(WIDTH) srcamux0(
    .d0(RD1E0), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
    .s(ForwardA0), .y(SrcAE0)
  );

  mux5 #(WIDTH) srcbfwdmux0(
    .d0(RD2E0), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
    .s(ForwardB0), .y(WriteDataE0)   // tambien es el dato que guarda un sw
  );

  mux2 #(WIDTH) srcbmux0(
    .d0(WriteDataE0),
    .d1(ImmExtE0),
    .s(ALUSrcE0),
    .y(SrcBE0)
  );

  alu alu0(
    .a(SrcAE0),
    .b(SrcBE0),
    .alucontrol(ALUControlE0),
    .result(ALUResultE0),
    .zero(ZeroE0)
  );

  adder pcaddbranch0(
    .a(PCE0),
    .b(ImmExtE0),
    .y(PCTargetE0)
  );

  // ---- via 1 ----
  mux5 #(WIDTH) srcamux1(
    .d0(RD1E1), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
    .s(ForwardA1), .y(SrcAE1)
  );

  mux5 #(WIDTH) srcbfwdmux1(
    .d0(RD2E1), .d1(ResultW0), .d2(ResultW1), .d3(ALUResultM0), .d4(ALUResultM1),
    .s(ForwardB1), .y(WriteDataE1)
  );

  mux2 #(WIDTH) srcbmux1(
    .d0(WriteDataE1),
    .d1(ImmExtE1),
    .s(ALUSrcE1),
    .y(SrcBE1)
  );

  alu alu1(
    .a(SrcAE1),
    .b(SrcBE1),
    .alucontrol(ALUControlE1),
    .result(ALUResultE1),
    .zero(ZeroE1)
  );

  adder pcaddbranch1(
    .a(PCE1),
    .b(ImmExtE1),
    .y(PCTargetE1)
  );

  // ============== Registros EX/MEM (uno por via) ==============
  // La via 1 se limpia con FlushM1: si el salto esta en la via 0, la instruccion de la via 1
  // (mas joven, del mismo par) no debe llegar a MEM ni a WB.
  wire [31:0] PCPlus4M0, PCPlus4M1;
  wire        ValidM0, ValidM1;

  flopr #(134) regM0(
    .clk(clk),
    .reset(reset),
    .d({ALUResultE0, WriteDataE0, RdE0, PCPlus4E0, InstrE0, ValidE0}),
    .q({ALUResultM0, WriteDataM0, RdM0, PCPlus4M0, InstrM0, ValidM0})
  );

  floprc #(134) regM1(
    .clk(clk),
    .reset(reset),
    .clear(FlushM1),
    .d({ALUResultE1, WriteDataE1, RdE1, PCPlus4E1, InstrE1, ValidE1}),
    .q({ALUResultM1, WriteDataM1, RdM1, PCPlus4M1, InstrM1, ValidM1})
  );

  // ======================= MEMORY =======================
  // Un solo puerto de datos: lo usa la via que tiene el load/store (la Issue Unit garantiza
  // que nunca hay dos en el mismo par). dmem esta fuera del datapath.
  mux2 #(WIDTH) memaddrmux(
    .d0(ALUResultM0),
    .d1(ALUResultM1),
    .s(MemSelM1),
    .y(ALUResultM)
  );

  mux2 #(WIDTH) memdatamux(
    .d0(WriteDataM0),
    .d1(WriteDataM1),
    .s(MemSelM1),
    .y(WriteDataM)
  );

  // ============== Registros MEM/WB (uno por via) ==============
  wire [31:0] ALUResultW0, ReadDataW0, PCPlus4W0, ALUResultW1, ReadDataW1, PCPlus4W1;

  flopr #(134) regW0(
    .clk(clk),
    .reset(reset),
    .d({ALUResultM0, ReadDataM, RdM0, PCPlus4M0, InstrM0, ValidM0}),
    .q({ALUResultW0, ReadDataW0, RdW0, PCPlus4W0, InstrW0, ValidW0})
  );

  flopr #(134) regW1(
    .clk(clk),
    .reset(reset),
    .d({ALUResultM1, ReadDataM, RdM1, PCPlus4M1, InstrM1, ValidM1}),
    .q({ALUResultW1, ReadDataW1, RdW1, PCPlus4W1, InstrW1, ValidW1})
  );

  // ======================= WRITEBACK =======================
  mux3 #(WIDTH) resultmux0(
    .d0(ALUResultW0),
    .d1(ReadDataW0),
    .d2(PCPlus4W0),
    .s(ResultSrcW0),
    .y(ResultW0)
  );

  mux3 #(WIDTH) resultmux1(
    .d0(ALUResultW1),
    .d1(ReadDataW1),
    .d2(PCPlus4W1),
    .s(ResultSrcW1),
    .y(ResultW1)
  );

  // PC de la instruccion que se retira (PC+4 viaja hasta WB)
  assign PCW0 = PCPlus4W0 - 4;
  assign PCW1 = PCPlus4W1 - 4;
endmodule
