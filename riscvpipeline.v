// Procesador RISC-V pipeline (reemplaza a riscvsingle).
// Dual-Issue preliminar: Instr e Instr1 son el par leido por el Dual Fetch.
// Mantiene los mismos nombres de puerto que riscvsingle para tocar poco top.v:
//   PC = PCF, Instr = InstrF, MemWrite = MemWriteM,
//   ALUResult = ALUResultM, WriteData = WriteDataM, ReadData = ReadDataM
module riscvpipeline(input         clk, reset,
                     output [31:0] PC,
                     input  [31:0] Instr, Instr1,
                     output        MemWrite,
                     output [31:0] ALUResult, WriteData,
                     input  [31:0] ReadData);

  wire [31:0] InstrD, InstrD0, InstrD1;
  wire        SelD;
  wire [1:0]  ImmSrcD0, ImmSrcD1, PCSrcE, ResultSrcE, ResultSrcW, ForwardAE, ForwardBE;
  wire [2:0]  ALUControlE;
  wire        ALUSrcE, ZeroE, RegWriteM, RegWriteW;
  wire        StallF, StallD, FlushD, FlushE;
  wire [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

  controller c(
    .clk(clk),
    .reset(reset),
    .opD0(InstrD0[6:0]),
    .opD1(InstrD1[6:0]),
    .funct3D0(InstrD0[14:12]),
    .funct3D1(InstrD1[14:12]),
    .funct7b5D0(InstrD0[30]),
    .funct7b5D1(InstrD1[30]),
    .SelD(SelD),
    .ImmSrcD0(ImmSrcD0),
    .ImmSrcD1(ImmSrcD1),
    .FlushE(FlushE),
    .ZeroE(ZeroE),
    .PCSrcE(PCSrcE),
    .ALUSrcE(ALUSrcE),
    .ALUControlE(ALUControlE),
    .ResultSrcE(ResultSrcE),
    .MemWriteM(MemWrite),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW)
  );

  datapath dp(
    .clk(clk),
    .reset(reset),
    .PCF(PC),
    .InstrF(Instr),
    .InstrF1(Instr1),
    .InstrD(InstrD),
    .InstrD0(InstrD0),
    .InstrD1(InstrD1),
    .SelD(SelD),
    .ImmSrcD0(ImmSrcD0),
    .ImmSrcD1(ImmSrcD1),
    .PCSrcE(PCSrcE),
    .ALUSrcE(ALUSrcE),
    .ALUControlE(ALUControlE),
    .ZeroE(ZeroE),
    .ALUResultM(ALUResult),
    .WriteDataM(WriteData),
    .ReadDataM(ReadData),
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW)
  );

  hazardunit hu(
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW),
    .PCSrcE(PCSrcE),
    .ResultSrcE0(ResultSrcE[0]),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE)
  );
endmodule
