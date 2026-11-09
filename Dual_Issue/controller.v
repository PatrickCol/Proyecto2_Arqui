// Controller Dual-Issue (E2)
//   - Decodifica las DOS instrucciones del par en ID (maindec + aludec por slot)
//   - Cada via lleva su propio registro de control ID/EX -> EX/MEM -> MEM/WB
//   - El registro ID/EX de cada via se limpia con FlushE o si esa via no emite (Issue = 0)
//   - El registro EX/MEM de la via 1 tiene clear propio (FlushM1): anula la instruccion mas
//     joven del par cuando el salto esta en la via 0
//   - PCSrc se calcula por via en EX: {Jalr, (Branch & Zero) | Jump}. Solo una via puede tener
//     un salto (la Issue Unit lo garantiza), asi que el resolutor es uno solo.
//   - Entrega a la Issue Unit y a la Hazard Unit los datos de decodificacion del par.
module controller(input        clk, reset,
                  // ---- Decode (par) ----
                  input  [6:0] opD0, opD1,
                  input  [2:0] funct3D0, funct3D1,
                  input        funct7b5D0, funct7b5D1,
                  output [1:0] ImmSrcD0, ImmSrcD1,
                  output       RegWriteD0,
                  output       IsMemD0, IsMemD1,
                  output       IsCtrlD0, IsCtrlD1,
                  output       UsesRs1D0, UsesRs2D0, UsesRs1D1, UsesRs2D1,
                  // ---- Emision y flush ----
                  input        Issue0, Issue1,
                  input        FlushE, FlushM1,
                  // ---- Execute via 0 / via 1 ----
                  input        ZeroE0, ZeroE1,
                  output [1:0] PCSrcE0, PCSrcE1,
                  output       ALUSrcE0, ALUSrcE1,
                  output [2:0] ALUControlE0, ALUControlE1,
                  output       LoadE0, LoadE1,
                  // ---- Memory ----
                  output       MemWriteM,      // algun store en MEM
                  output       MemSelM1,       // la via 1 es duena del puerto de memoria
                  output       RegWriteM0, RegWriteM1,
                  // ---- Writeback ----
                  output       RegWriteW0, RegWriteW1,
                  output [1:0] ResultSrcW0, ResultSrcW1);

  // =============== DECODE SLOT 0 ===============
  wire [1:0] ALUOpD0, ResultSrcD0;
  wire [2:0] ALUControlD0;
  wire       BranchD0, JumpD0, JalrD0, ALUSrcD0, MemWriteD0;

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

  // =============== DECODE SLOT 1 ===============
  wire [1:0] ALUOpD1, ResultSrcD1;
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

  // =============== Datos para Issue Unit / Hazard Unit ===============
  assign IsMemD0  = MemWriteD0 | (ResultSrcD0 == 2'b01);      // load o store
  assign IsMemD1  = MemWriteD1 | (ResultSrcD1 == 2'b01);
  assign IsCtrlD0 = BranchD0 | JumpD0 | JalrD0;               // branch, jal o jalr
  assign IsCtrlD1 = BranchD1 | JumpD1 | JalrD1;

  // Que registros fuente usa cada instruccion (evita dependencias falsas, p. ej. addi no usa rs2)
  assign UsesRs1D0 = (opD0 != 7'b1101111);                    // todas menos jal
  assign UsesRs1D1 = (opD1 != 7'b1101111);
  assign UsesRs2D0 = (opD0 == 7'b0110011) | (opD0 == 7'b0100011) | (opD0 == 7'b1100011); // R, sw, beq
  assign UsesRs2D1 = (opD1 == 7'b0110011) | (opD1 == 7'b0100011) | (opD1 == 7'b1100011);

  // =============== ID/EX (un registro por via) ===============
  wire [10:0] CtrlD0 = {RegWriteD0, ResultSrcD0, MemWriteD0, JumpD0, BranchD0, JalrD0, ALUControlD0, ALUSrcD0};
  wire [10:0] CtrlD1 = {RegWriteD1, ResultSrcD1, MemWriteD1, JumpD1, BranchD1, JalrD1, ALUControlD1, ALUSrcD1};

  wire       RegWriteE0, MemWriteE0, JumpE0, BranchE0, JalrE0;
  wire [1:0] ResultSrcE0;
  wire       RegWriteE1, MemWriteE1, JumpE1, BranchE1, JalrE1;
  wire [1:0] ResultSrcE1;

  floprc #(11) regE0(
    .clk(clk),
    .reset(reset),
    .clear(FlushE | ~Issue0),
    .d(CtrlD0),
    .q({RegWriteE0, ResultSrcE0, MemWriteE0, JumpE0, BranchE0, JalrE0, ALUControlE0, ALUSrcE0})
  );

  floprc #(11) regE1(
    .clk(clk),
    .reset(reset),
    .clear(FlushE | ~Issue1),
    .d(CtrlD1),
    .q({RegWriteE1, ResultSrcE1, MemWriteE1, JumpE1, BranchE1, JalrE1, ALUControlE1, ALUSrcE1})
  );

  // Resolutor de saltos (en EX): una senal PCSrc por via; la via sin salto aporta 00
  assign PCSrcE0 = {JalrE0, (BranchE0 & ZeroE0) | JumpE0};
  assign PCSrcE1 = {JalrE1, (BranchE1 & ZeroE1) | JumpE1};

  // lw en EX (ResultSrc = 01), para la deteccion de load-use
  assign LoadE0 = (ResultSrcE0 == 2'b01);
  assign LoadE1 = (ResultSrcE1 == 2'b01);

  // =============== EX/MEM ===============
  wire [1:0] ResultSrcM0, ResultSrcM1;
  wire       MemWriteM0, MemWriteM1;

  flopr #(4) regM0(
    .clk(clk),
    .reset(reset),
    .d({RegWriteE0, ResultSrcE0, MemWriteE0}),
    .q({RegWriteM0, ResultSrcM0, MemWriteM0})
  );

  floprc #(4) regM1(
    .clk(clk),
    .reset(reset),
    .clear(FlushM1),
    .d({RegWriteE1, ResultSrcE1, MemWriteE1}),
    .q({RegWriteM1, ResultSrcM1, MemWriteM1})
  );

  // Puerto de memoria unico: store/load de la via 1 -> la via 1 lo usa; en otro caso, la via 0
  assign MemWriteM = MemWriteM0 | MemWriteM1;
  assign MemSelM1  = MemWriteM1 | (ResultSrcM1 == 2'b01);

  // =============== MEM/WB ===============
  flopr #(3) regW0(
    .clk(clk),
    .reset(reset),
    .d({RegWriteM0, ResultSrcM0}),
    .q({RegWriteW0, ResultSrcW0})
  );

  flopr #(3) regW1(
    .clk(clk),
    .reset(reset),
    .d({RegWriteM1, ResultSrcM1}),
    .q({RegWriteW1, ResultSrcW1})
  );
endmodule
