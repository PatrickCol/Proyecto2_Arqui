// Controller pipeline: decodifica en ID y propaga las senales hasta su etapa
//   ID : ImmSrc
//   EX : ALUSrc, ALUControl, Branch, Jump, Jalr (-> PCSrcE), ResultSrc[0] (para el hazard unit)
//   MEM: MemWrite, RegWrite
//   WB : RegWrite, ResultSrc
// PCSrc = {Jalr, Branch & Zero | Jump}, ahora calculado en EX (ZeroE)
// Dual Decode: se decodifican las dos instrucciones del par (slot 0 y slot 1)
// y pasa a EX el control de la instruccion emitida (SelD)
module controller(input        clk, reset,
                  // Decode
                  input  [6:0] opD0, opD1,
                  input  [2:0] funct3D0, funct3D1,
                  input        funct7b5D0, funct7b5D1,
                  input        SelD,
                  input        Issue1D,
                  output [1:0] ImmSrcD0, ImmSrcD1,
                  // Execute
                  input        FlushE,
                  input        ZeroE,
                  output [1:0] PCSrcE,
                  output       ALUSrcE,
                  output [2:0] ALUControlE,
                  output [1:0] ResultSrcE,
                  output       ALUSrcE1,
                  output [2:0] ALUControlE1,
                  // Memory
                  output       MemWriteM,
                  output       RegWriteM,
                  // Writeback
                  output       RegWriteW,
                  output [1:0] ResultSrcW);

  // ---------- Decode (slot 0) ----------
  wire [1:0] ALUOpD0;
  wire [1:0] ResultSrcD0;
  wire [2:0] ALUControlD0;
  wire       BranchD0, JumpD0, JalrD0, ALUSrcD0, RegWriteD0, MemWriteD0;

  maindec md0(
    .op(opD0),
    .ResultSrc(ResultSrcD0),
    .MemWrite(MemWriteD0),
    .Branch(BranchD0),
    .ALUSrc(ALUSrcD0),
    .RegWrite(RegWriteD0),
    .Jump(JumpD0),
    .Jalr(JalrD0),
    .ImmSrc(ImmSrcD0),
    .ALUOp(ALUOpD0)
  );

  aludec ad0(
    .opb5(opD0[5]),
    .funct3(funct3D0),
    .funct7b5(funct7b5D0),
    .ALUOp(ALUOpD0),
    .ALUControl(ALUControlD0)
  );

  // ---------- Decode (slot 1) ----------
  wire [1:0] ALUOpD1;
  wire [1:0] ResultSrcD1;
  wire [2:0] ALUControlD1;
  wire       BranchD1, JumpD1, JalrD1, ALUSrcD1, RegWriteD1, MemWriteD1;

  maindec md1(
    .op(opD1),
    .ResultSrc(ResultSrcD1),
    .MemWrite(MemWriteD1),
    .Branch(BranchD1),
    .ALUSrc(ALUSrcD1),
    .RegWrite(RegWriteD1),
    .Jump(JumpD1),
    .Jalr(JalrD1),
    .ImmSrc(ImmSrcD1),
    .ALUOp(ALUOpD1)
  );

  aludec ad1(
    .opb5(opD1[5]),
    .funct3(funct3D1),
    .funct7b5(funct7b5D1),
    .ALUOp(ALUOpD1),
    .ALUControl(ALUControlD1)
  );

  // ---------- Control de la instruccion emitida ----------
  wire [10:0] CtrlD0 = {RegWriteD0, ResultSrcD0, MemWriteD0, JumpD0, BranchD0, JalrD0, ALUControlD0, ALUSrcD0};
  wire [10:0] CtrlD1 = {RegWriteD1, ResultSrcD1, MemWriteD1, JumpD1, BranchD1, JalrD1, ALUControlD1, ALUSrcD1};

  // ---------- Registro ID/EX (con flush) ----------
  wire       RegWriteE, MemWriteE, JumpE, BranchE, JalrE;

  floprc #(11) regE(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(SelD ? CtrlD1 : CtrlD0),
    .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, JalrE, ALUControlE, ALUSrcE})
  );

  // ---------- Registro ID/EX de la via 1 ----------
  // E1: Issue1D = 0, la via 1 solo recibe burbujas; en E2 la Issue Unit la activara
  wire       RegWriteE1, MemWriteE1, JumpE1, BranchE1, JalrE1;
  wire [1:0] ResultSrcE1;

  floprc #(11) regE1(
    .clk(clk),
    .reset(reset),
    .clear(FlushE | ~Issue1D),
    .d(CtrlD1),
    .q({RegWriteE1, ResultSrcE1, MemWriteE1, JumpE1, BranchE1, JalrE1, ALUControlE1, ALUSrcE1})
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
