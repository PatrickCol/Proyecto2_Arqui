// Controller pipeline: decodifica en ID y propaga las senales hasta su etapa
//   ID : ImmSrc
//   EX : ALUSrc, ALUControl, Branch, Jump, Jalr (-> PCSrcE), ResultSrc[0] (para el hazard unit)
//   MEM: MemWrite, RegWrite
//   WB : RegWrite, ResultSrc
// PCSrc = {Jalr, Branch & Zero | Jump}, ahora calculado en EX (ZeroE)
module controller(input        clk, reset,
                  // Decode
                  input  [6:0] opD,
                  input  [2:0] funct3D,
                  input        funct7b5D,
                  output [1:0] ImmSrcD,
                  // Execute
                  input        FlushE,
                  input        ZeroE,
                  output [1:0] PCSrcE,
                  output       ALUSrcE,
                  output [2:0] ALUControlE,
                  output [1:0] ResultSrcE,
                  // Memory
                  output       MemWriteM,
                  output       RegWriteM,
                  // Writeback
                  output       RegWriteW,
                  output [1:0] ResultSrcW);

  // ---------- Decode ----------
  wire [1:0] ALUOpD;
  wire [1:0] ResultSrcD;
  wire [2:0] ALUControlD;
  wire       BranchD, JumpD, JalrD, ALUSrcD, RegWriteD, MemWriteD;

  maindec md(
    .op(opD),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .Branch(BranchD),
    .ALUSrc(ALUSrcD),
    .RegWrite(RegWriteD),
    .Jump(JumpD),
    .Jalr(JalrD),
    .ImmSrc(ImmSrcD),
    .ALUOp(ALUOpD)
  );

  aludec ad(
    .opb5(opD[5]),
    .funct3(funct3D),
    .funct7b5(funct7b5D),
    .ALUOp(ALUOpD),
    .ALUControl(ALUControlD)
  );

  // ---------- Registro ID/EX (con flush) ----------
  wire       RegWriteE, MemWriteE, JumpE, BranchE, JalrE;

  floprc #(11) regE(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, JalrD, ALUControlD, ALUSrcD}),
    .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, JalrE, ALUControlE, ALUSrcE})
  );

  // PCSrc se resuelve en Execute
  assign PCSrcE = {JalrE, (BranchE & ZeroE) | JumpE};

  // ---------- Registro EX/MEM ----------
  wire [1:0] ResultSrcM;

  flopr #(4) regM(
    .clk(clk),
    .reset(reset),
    .d({RegWriteE, ResultSrcE, MemWriteE}),
    .q({RegWriteM, ResultSrcM, MemWriteM})
  );

  // ---------- Registro MEM/WB ----------
  flopr #(3) regW(
    .clk(clk),
    .reset(reset),
    .d({RegWriteM, ResultSrcM}),
    .q({RegWriteW, ResultSrcW})
  );
endmodule
