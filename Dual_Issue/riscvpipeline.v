// Procesador RISC-V Dual-Issue In-Order (E2).
// Mantiene los puertos de E1 para no tocar top.v:
//   PC = PCF, Instr/Instr1 = par leido por el Dual Fetch (PC y PC+4),
//   MemWrite/ALUResult/WriteData/ReadData = puerto de memoria de datos (unico)
module riscvpipeline(input         clk, reset,
                     output [31:0] PC,
                     input  [31:0] Instr, Instr1,
                     output        MemWrite,
                     output [31:0] ALUResult, WriteData,
                     input  [31:0] ReadData);

  // ---- Decode ----
  wire [31:0] InstrD0, InstrD1;
  wire        ValidD0, ValidD1;
  wire [1:0]  ImmSrcD0, ImmSrcD1;
  wire [4:0]  Rs1D0, Rs2D0, RdD0, Rs1D1, Rs2D1;
  wire        RegWriteD0, IsMemD0, IsMemD1, IsCtrlD0, IsCtrlD1;
  wire        UsesRs1D0, UsesRs2D0, UsesRs1D1, UsesRs2D1;

  // ---- Emision ----
  wire        Issue0, Issue1;
  wire [1:0]  Consumed;
  wire        RawPair, MemConflict, CtrlConflict;
  wire        LoadUse0, LoadUse1;

  // ---- Execute ----
  wire [1:0]  PCSrcE0, PCSrcE1;
  wire        ALUSrcE0, ALUSrcE1, ZeroE0, ZeroE1, LoadE0, LoadE1;
  wire [2:0]  ALUControlE0, ALUControlE1;
  wire [4:0]  Rs1E0, Rs2E0, RdE0, Rs1E1, Rs2E1, RdE1;

  // ---- Memory / Writeback ----
  wire        MemSelM1, RegWriteM0, RegWriteM1, RegWriteW0, RegWriteW1;
  wire [1:0]  ResultSrcW0, ResultSrcW1;
  wire [4:0]  RdM0, RdM1, RdW0, RdW1;

  // ---- Hazard unit ----
  wire        FlushD, FlushE, FlushM1;
  wire [2:0]  ForwardA0, ForwardB0, ForwardA1, ForwardB1;

  // ---- Depuracion / metricas ----
  wire [31:0] InstrE0, InstrE1, InstrM0, InstrM1, InstrW0, InstrW1, PCW0, PCW1;
  wire        ValidW0, ValidW1;

  controller c(
    .clk(clk),
    .reset(reset),
    .opD0(InstrD0[6:0]),
    .opD1(InstrD1[6:0]),
    .funct3D0(InstrD0[14:12]),
    .funct3D1(InstrD1[14:12]),
    .funct7b5D0(InstrD0[30]),
    .funct7b5D1(InstrD1[30]),
    .ImmSrcD0(ImmSrcD0),
    .ImmSrcD1(ImmSrcD1),
    .RegWriteD0(RegWriteD0),
    .IsMemD0(IsMemD0),
    .IsMemD1(IsMemD1),
    .IsCtrlD0(IsCtrlD0),
    .IsCtrlD1(IsCtrlD1),
    .UsesRs1D0(UsesRs1D0),
    .UsesRs2D0(UsesRs2D0),
    .UsesRs1D1(UsesRs1D1),
    .UsesRs2D1(UsesRs2D1),
    .Issue0(Issue0),
    .Issue1(Issue1),
    .FlushE(FlushE),
    .FlushM1(FlushM1),
    .ZeroE0(ZeroE0),
    .ZeroE1(ZeroE1),
    .PCSrcE0(PCSrcE0),
    .PCSrcE1(PCSrcE1),
    .ALUSrcE0(ALUSrcE0),
    .ALUSrcE1(ALUSrcE1),
    .ALUControlE0(ALUControlE0),
    .ALUControlE1(ALUControlE1),
    .LoadE0(LoadE0),
    .LoadE1(LoadE1),
    .MemWriteM(MemWrite),
    .MemSelM1(MemSelM1),
    .RegWriteM0(RegWriteM0),
    .RegWriteM1(RegWriteM1),
    .RegWriteW0(RegWriteW0),
    .RegWriteW1(RegWriteW1),
    .ResultSrcW0(ResultSrcW0),
    .ResultSrcW1(ResultSrcW1)
  );

  datapath dp(
    .clk(clk),
    .reset(reset),
    .PCF(PC),
    .InstrF(Instr),
    .InstrF1(Instr1),
    .InstrD0(InstrD0),
    .InstrD1(InstrD1),
    .ValidD0(ValidD0),
    .ValidD1(ValidD1),
    .ImmSrcD0(ImmSrcD0),
    .ImmSrcD1(ImmSrcD1),
    .Rs1D0(Rs1D0),
    .Rs2D0(Rs2D0),
    .RdD0(RdD0),
    .Rs1D1(Rs1D1),
    .Rs2D1(Rs2D1),
    .Consumed(Consumed),
    .Issue0(Issue0),
    .Issue1(Issue1),
    .PCSrcE0(PCSrcE0),
    .PCSrcE1(PCSrcE1),
    .ALUSrcE0(ALUSrcE0),
    .ALUSrcE1(ALUSrcE1),
    .ALUControlE0(ALUControlE0),
    .ALUControlE1(ALUControlE1),
    .ZeroE0(ZeroE0),
    .ZeroE1(ZeroE1),
    .Rs1E0(Rs1E0),
    .Rs2E0(Rs2E0),
    .RdE0(RdE0),
    .Rs1E1(Rs1E1),
    .Rs2E1(Rs2E1),
    .RdE1(RdE1),
    .MemSelM1(MemSelM1),
    .ALUResultM(ALUResult),
    .WriteDataM(WriteData),
    .ReadDataM(ReadData),
    .RdM0(RdM0),
    .RdM1(RdM1),
    .RegWriteW0(RegWriteW0),
    .RegWriteW1(RegWriteW1),
    .ResultSrcW0(ResultSrcW0),
    .ResultSrcW1(ResultSrcW1),
    .RdW0(RdW0),
    .RdW1(RdW1),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .FlushM1(FlushM1),
    .ForwardA0(ForwardA0),
    .ForwardB0(ForwardB0),
    .ForwardA1(ForwardA1),
    .ForwardB1(ForwardB1),
    .InstrE0(InstrE0),
    .InstrE1(InstrE1),
    .InstrM0(InstrM0),
    .InstrM1(InstrM1),
    .InstrW0(InstrW0),
    .InstrW1(InstrW1),
    .ValidW0(ValidW0),
    .ValidW1(ValidW1),
    .PCW0(PCW0),
    .PCW1(PCW1)
  );

  issueunit iu(
    .Valid0(ValidD0),
    .Valid1(ValidD1),
    .RdD0(RdD0),
    .Rs1D1(Rs1D1),
    .Rs2D1(Rs2D1),
    .RegWriteD0(RegWriteD0),
    .UsesRs1D1(UsesRs1D1),
    .UsesRs2D1(UsesRs2D1),
    .IsMemD0(IsMemD0),
    .IsMemD1(IsMemD1),
    .IsCtrlD0(IsCtrlD0),
    .IsCtrlD1(IsCtrlD1),
    .LoadUse0(LoadUse0),
    .LoadUse1(LoadUse1),
    .Issue0(Issue0),
    .Issue1(Issue1),
    .Consumed(Consumed),
    .RawPair(RawPair),
    .MemConflict(MemConflict),
    .CtrlConflict(CtrlConflict)
  );

  hazardunit hu(
    .Rs1D0(Rs1D0),
    .Rs2D0(Rs2D0),
    .Rs1D1(Rs1D1),
    .Rs2D1(Rs2D1),
    .UsesRs1D0(UsesRs1D0),
    .UsesRs2D0(UsesRs2D0),
    .UsesRs1D1(UsesRs1D1),
    .UsesRs2D1(UsesRs2D1),
    .Rs1E0(Rs1E0),
    .Rs2E0(Rs2E0),
    .Rs1E1(Rs1E1),
    .Rs2E1(Rs2E1),
    .RdE0(RdE0),
    .RdE1(RdE1),
    .LoadE0(LoadE0),
    .LoadE1(LoadE1),
    .PCSrcE0(PCSrcE0),
    .PCSrcE1(PCSrcE1),
    .RdM0(RdM0),
    .RdM1(RdM1),
    .RegWriteM0(RegWriteM0),
    .RegWriteM1(RegWriteM1),
    .RdW0(RdW0),
    .RdW1(RdW1),
    .RegWriteW0(RegWriteW0),
    .RegWriteW1(RegWriteW1),
    .LoadUse0(LoadUse0),
    .LoadUse1(LoadUse1),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .FlushM1(FlushM1),
    .ForwardA0(ForwardA0),
    .ForwardB0(ForwardB0),
    .ForwardA1(ForwardA1),
    .ForwardB1(ForwardB1)
  );
endmodule
