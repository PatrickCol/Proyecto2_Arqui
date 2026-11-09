// Issue Unit (E2): decide cuantas instrucciones del par en Decode salen este ciclo
//   Issue0 : sale la instruccion mas antigua (slot 0)  -> via 0
//   Issue1 : sale tambien la mas joven (slot 1)        -> via 1
// La emision es en orden: el slot 1 nunca sale sin el slot 0. Si solo sale el slot 0, el
// slot 1 se conserva (la ventana de IF/ID se desliza, ver Consumed) y se reagrupa con la
// siguiente instruccion.
//
// El slot 1 NO se empareja con el slot 0 si:
//   - depende por RAW del destino del slot 0 (RawPair)
//   - ambos acceden a la memoria: un solo puerto (MemConflict)
//   - ambos son salto/jump: un solo resolutor de branches (CtrlConflict)
//   - depende de un lw que esta en EX (LoadUse1)
// El slot 0 espera si depende de un lw que esta en EX (LoadUse0).
//
// Consumed = cuantas posiciones de la ventana avanzan (0, 1 o 2). Un slot invalido (burbuja)
// cuenta como consumido, asi la ventana se recarga sola despues de un reset o de un flush.
module issueunit(
    input        Valid0, Valid1,
    input  [4:0] RdD0, Rs1D1, Rs2D1,
    input        RegWriteD0,
    input        UsesRs1D1, UsesRs2D1,
    input        IsMemD0, IsMemD1,
    input        IsCtrlD0, IsCtrlD1,
    input        LoadUse0, LoadUse1,
    output       Issue0, Issue1,
    output [1:0] Consumed,
    // Motivos de no emparejar (para waveforms y estadisticas)
    output       RawPair, MemConflict, CtrlConflict);

  assign RawPair = RegWriteD0 & (RdD0 != 5'b0) &
                   ((UsesRs1D1 & (Rs1D1 == RdD0)) | (UsesRs2D1 & (Rs2D1 == RdD0)));
  assign MemConflict  = IsMemD0  & IsMemD1;
  assign CtrlConflict = IsCtrlD0 & IsCtrlD1;

  assign Issue0 = Valid0 & ~LoadUse0;
  assign Issue1 = Issue0 & Valid1 & ~LoadUse1 & ~RawPair & ~MemConflict & ~CtrlConflict;

  wire consumed0 = Issue0 | ~Valid0;
  wire consumed1 = Issue1 | ~Valid1;

  assign Consumed = consumed0 ? (consumed1 ? 2'b10 : 2'b01) : 2'b00;
endmodule
