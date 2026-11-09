// Hazard Unit Dual-Issue (E2)
//  - Forwarding de los 4 operandos de EX (2 vias x rs1/rs2), con prioridad al mas reciente
//  - Deteccion de load-use: una instruccion del par en Decode usa el destino de un lw que esta en EX
//  - Flush por salto/jump tomado. El resolutor de saltos es uno solo, pero el salto puede estar
//    en cualquiera de las dos vias:
//      * salto tomado en la via 0 -> se anulan IF/ID, ID/EX (ambas vias) y EX/MEM de la via 1
//        (la instruccion mas joven del mismo par)
//      * salto tomado en la via 1 -> se anulan IF/ID e ID/EX; la via 0 es mas antigua y se conserva
module hazardunit(
    // Decode: instrucciones del par y que fuentes usan
    input  [4:0] Rs1D0, Rs2D0, Rs1D1, Rs2D1,
    input        UsesRs1D0, UsesRs2D0, UsesRs1D1, UsesRs2D1,
    // Execute
    input  [4:0] Rs1E0, Rs2E0, Rs1E1, Rs2E1,
    input  [4:0] RdE0, RdE1,
    input        LoadE0, LoadE1,
    input  [1:0] PCSrcE0, PCSrcE1,
    // Memory
    input  [4:0] RdM0, RdM1,
    input        RegWriteM0, RegWriteM1,
    // Writeback
    input  [4:0] RdW0, RdW1,
    input        RegWriteW0, RegWriteW1,
    // Hacia la Issue Unit
    output       LoadUse0, LoadUse1,
    // Flush
    output       FlushD, FlushE, FlushM1,
    // Forwarding
    output [2:0] ForwardA0, ForwardB0, ForwardA1, ForwardB1);

  // ---------------- Forwarding ----------------
  fwdsel fa0(.Rs(Rs1E0), .RdM0(RdM0), .RdM1(RdM1), .RdW0(RdW0), .RdW1(RdW1),
             .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
             .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1), .Forward(ForwardA0));
  fwdsel fb0(.Rs(Rs2E0), .RdM0(RdM0), .RdM1(RdM1), .RdW0(RdW0), .RdW1(RdW1),
             .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
             .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1), .Forward(ForwardB0));
  fwdsel fa1(.Rs(Rs1E1), .RdM0(RdM0), .RdM1(RdM1), .RdW0(RdW0), .RdW1(RdW1),
             .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
             .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1), .Forward(ForwardA1));
  fwdsel fb1(.Rs(Rs2E1), .RdM0(RdM0), .RdM1(RdM1), .RdW0(RdW0), .RdW1(RdW1),
             .RegWriteM0(RegWriteM0), .RegWriteM1(RegWriteM1),
             .RegWriteW0(RegWriteW0), .RegWriteW1(RegWriteW1), .Forward(ForwardB1));

  // ---------------- Load-use ----------------
  // El dato de un lw recien esta disponible al final de MEM: la instruccion que lo usa espera un ciclo.
  wire ldE0 = LoadE0 & (RdE0 != 5'b0);
  wire ldE1 = LoadE1 & (RdE1 != 5'b0);

  assign LoadUse0 = (ldE0 & ((UsesRs1D0 & (Rs1D0 == RdE0)) | (UsesRs2D0 & (Rs2D0 == RdE0))))
                  | (ldE1 & ((UsesRs1D0 & (Rs1D0 == RdE1)) | (UsesRs2D0 & (Rs2D0 == RdE1))));

  assign LoadUse1 = (ldE0 & ((UsesRs1D1 & (Rs1D1 == RdE0)) | (UsesRs2D1 & (Rs2D1 == RdE0))))
                  | (ldE1 & ((UsesRs1D1 & (Rs1D1 == RdE1)) | (UsesRs2D1 & (Rs2D1 == RdE1))));

  // ---------------- Flush por salto tomado ----------------
  wire taken0 = |PCSrcE0;   // incluye jalr (PCSrc = 10)
  wire taken1 = |PCSrcE1;

  assign FlushD  = taken0 | taken1;
  assign FlushE  = taken0 | taken1;
  assign FlushM1 = taken0;  // la via 1 lleva la instruccion mas joven del par del salto
endmodule
