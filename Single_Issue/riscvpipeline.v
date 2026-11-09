// Procesador RISC-V pipeline (reemplaza a riscvsingle).
// Mantiene los mismos nombres de puerto que riscvsingle para tocar poco top.v:
//   PC = PCF, Instr = InstrF, MemWrite = MemWriteM,
//   ALUResult = ALUResultM, WriteData = WriteDataM, ReadData = ReadDataM
module riscvpipeline(input         clk, reset,
                     output [31:0] PC,
                     input  [31:0] Instr,
                     output        MemWrite,
                     output [31:0] ALUResult, WriteData,
                     input  [31:0] ReadData);

  wire [31:0] InstrD;
  wire [1:0]  ImmSrcD, PCSrcE, ResultSrcE, ResultSrcW, ForwardAE, ForwardBE;
  wire [2:0]  ALUControlE;
  wire        ALUSrcE, ZeroE, RegWriteM, RegWriteW;
  wire        StallF, StallD, FlushD, FlushE;
  wire [4:0]  Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

  controller c(
    .clk(clk),
    .reset(reset),
    .opD(InstrD[6:0]),
    .funct3D(InstrD[14:12]),
    .funct7b5D(InstrD[30]),
    .ImmSrcD(ImmSrcD),
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
    .InstrD(InstrD),
    .ImmSrcD(ImmSrcD),
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
